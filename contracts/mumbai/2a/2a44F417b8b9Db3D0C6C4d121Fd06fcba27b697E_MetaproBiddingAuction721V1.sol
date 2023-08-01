// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Counters {
    struct Counter {
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
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Define the struct in the SharedStruct contract
contract Referral {
    struct ReferralFees {
        // @dev: Level 1 referral fee - integer value - example: 1000 -> 10%
        uint256 level1ReferrerFee;
        // @dev: Level 1 referral fee - integer value - example: 1000 -> 10%
        uint256 level2ReferrerFee;
        // @dev: Level 1 referral fee - integer value - example: 1000 -> 10%
        uint256 level3ReferrerFee;
    }
}

//  referral
interface MetaproReferral {
    function saveReferralDeposit(
        address _referrer,
        address _contractAddress,
        uint256 _auctionId,
        uint256 _tokenId,
        address _depositer,
        uint256 _level,
        uint256 _provision
    ) external;

    function setReferral(address _referred, address _referrer) external;

    function getReferral(address _referred) external view returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Define the struct in the SharedStruct contract
contract Royalty {
    struct RoyaltyTeamMember {
        address member;
        // @dev: royalty fee - integer value - example: 1000 -> 10%
        uint256 royaltyFee;
    }

    struct RoyaltyTeamConfiguration {
        uint256 teamId;
        uint256 tokenId;
        address teamOwner;
    }
}

//  royalty
interface MetaproRoyalty {
    function getTeamMembers(uint256 _tokenId, address _tokenContractAddress)
        external
        view
        returns (Royalty.RoyaltyTeamMember[] memory);

    function getTeam(uint256 _tokenId, address _tokenContractAddress)
        external
        view
        returns (Royalty.RoyaltyTeamConfiguration memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./libraries/Counter.sol";
import "@openzeppelin/contracts/utils/Address.sol";
// import "hardhat/console.sol";
import "./libraries/Royalty.sol";
import "./libraries/Referral.sol";

contract MetaproBiddingAuction721V1 is Ownable, ReentrancyGuard, ERC721Holder {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    struct AuctionConfiguration {
        // @dev: nft token id
        uint256 tokenId;
        // @dev: Token quantity in Auction
        uint256 tokenQuantity;
        // @dev: floor price per 1 nft token - value in busd
        uint256 tokenFloorPrice;
        // @dev: Max bid in Auction in token quantity
        uint256 maxBidTokenQuantity;
        // @dev: Auction starting block
        uint256 startBlock;
        // @dev: Auction ending block
        uint256 endBlock;
        // @dev: Auction operator
        address operator;
        // @dev: Auction validity - value in boolean
        bool valid;
        // @dev: Auction id
        uint256 auctionId;
    }

    struct AuctionBid {
        // @dev: Auction bidder address
        address bidder;
        // @dev: AuctionBid token quantity
        uint256 tokenQuantity;
        // @dev: AuctionBid value - value in busd
        uint256 pricePerToken;
        // @dev: AuctionBid block number
        uint256 bidBlockNumber;
        // @dev: AuctionBid accepted value - above floorPrice is accepted by default
        bool accepted;
        // @dev: AuctionBid validity - value in boolean
        bool valid;
    }

    struct TokenAuction {
        uint256 tokenId;
        address tokenContractAddress;
        bool active;
    }

    mapping(uint256 => AuctionConfiguration) private auctions;

    mapping(uint256 => AuctionBid[]) private auctionsBids;

    mapping(address => uint256[]) private walletAuctionIds;

    uint256[] private createdAuctionIds;

    // @dev: dictionary with auction bids amount for withdraw/giveBack purposes
    mapping(uint256 => uint256) public auctionBalance;

    // @dev: dictionary with auctionId => operatorWithdrawed
    mapping(uint256 => bool) private operatorWithdrawn;

    // @dev: dictionary with ins token contract address auctionId -> auctionTokenContractAddress ERC721
    mapping(uint256 => address) public auctionTokenContractAddress;

    // @dev: dictionary with insId => Referral.ReferralFees
    mapping(uint256 => Referral.ReferralFees) public auctionReferralFees;

    // @dev: dictionary with auctionId => Royalty.RoyaltyTeamMember[]
    mapping(uint256 => Royalty.RoyaltyTeamMember[])
        public auctionRoyaltyTeamMembers;

    // uint256 with a break between auction endBlock and a block from which finalization by the bidder is enabled
    uint256 public finalizationBlockDelay = 5760; // 5760 / 4 = 24h

    // Contracts
    IERC20 public busd;
    MetaproReferral public metaproReferral;
    MetaproRoyalty public metaproRoyalty;

    //Contract addresses
    address private busdAddress;
    address private referralAddress;
    address private royaltyAddress;
    address public tressuryAddress;

    uint256 public treasuryFee = 500; // 500 = 5%

    Counters.Counter private currentAuctionId = Counters.Counter(1);

    event AuctionBidAccepted(uint256 indexed auctionId, address indexed bidder);
    event AuctionFinalizedByParticipant(
        uint256 indexed auctionId,
        address indexed participant
    );

    event OperatorWithdraw(
        uint256 _auctionId,
        address _target,
        uint256 _earnings,
        uint256 _tokenAmount
    );

    modifier finalizeEnabled(uint256 _auctionId) {
        AuctionConfiguration memory auction = auctions[_auctionId];
        // Check if auction already exists and is valid
        require(
            auction.auctionId != 0 && auction.valid,
            "MetaproAuction721: Auction does not exist and can not be finalized"
        );
        // Check if current block is higher than endBlock + 24h in blocks
        require(
            block.number > auction.endBlock + finalizationBlockDelay ||
                block.number < auction.startBlock,
            "MetaproAuction721: Auction can not be finalized"
        );
        _;
    }

    constructor(
        address _busdAddress,
        address _tressuryAddress,
        address _referralAddress,
        address _royaltyAddress
    ) {
        busd = IERC20(_busdAddress);
        tressuryAddress = _tressuryAddress;
        metaproReferral = MetaproReferral(_referralAddress);
        referralAddress = _referralAddress;
        metaproRoyalty = MetaproRoyalty(_royaltyAddress);
        royaltyAddress = _royaltyAddress;
    }

    function createAuction(
        uint256 _tokenId,
        address _tokenContractAddress,
        uint256 _tokenQuantity,
        uint256 _maxBidTokenQuantity,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _tokenFloorPrice,
        uint256 _level1ReferralFee,
        uint256 _level2ReferralFee,
        uint256 _level3ReferralFee,
        bytes memory _data
    ) public nonReentrant {
        require(
            _data.length == 0 || (_data.length == 1 && _data[0] == 0x00),
            "MetaproBuyNow721: data must be empty or equal to 0x00"
        );
        // Check if provided tokenContractAddress is valid
        require(
            Address.isContract(_tokenContractAddress),
            "MetaproAuction721: Invalid ERC721 contract address"
        );
        // Check if provided referrals fees are valid
        require(
            _level1ReferralFee.add(_level2ReferralFee).add(
                _level3ReferralFee
            ) <= 1500,
            "MetaproAuction721: the sum of referral fees can not be greater than 15%"
        );
        // Check if provided tokenId is valid
        require(
            _tokenId > 0,
            "MetaproAuction721: invalid tokenId, value must be positive number"
        );
        // Check is balance of a given ERC721 token is valid
        require(
            IERC721(_tokenContractAddress).ownerOf(_tokenId) == msg.sender,
            "MetaproAuction721: insufficient ERC721 balance"
        );
        require(
            _tokenFloorPrice > 0,
            "MetaproAuction721: pricePerToken must be greater than 0"
        );

        require(
            _startBlock >= block.number,
            "MetaproAuction721: Auction start block must be in the future"
        );
        require(
            _endBlock > _startBlock,
            "MetaproAuction721: Auction end block must be after auction start block"
        );

        require(
            _tokenQuantity == 1,
            "MetaproAuction721: Auction token quantity must be 1"
        );

        require(
            _maxBidTokenQuantity == 1,
            "MetaproAuction721: Auction max bid token quantity must be 1"
        );

        //Transfer auction NFTs to this contract
        IERC721(_tokenContractAddress).safeTransferFrom(
            msg.sender,
            address(this),
            _tokenId
        );

        auctionTokenContractAddress[
            currentAuctionId.current()
        ] = _tokenContractAddress;

        saveAuctionReferralFees(
            _level1ReferralFee,
            _level2ReferralFee,
            _level3ReferralFee
        );

        saveAuctionRoyaltyFees(currentAuctionId.current(), _tokenId);
        auctions[currentAuctionId.current()] = AuctionConfiguration({
            tokenId: _tokenId,
            // Default value for ERC721 token quantity is 1
            tokenQuantity: 1,
            tokenFloorPrice: _tokenFloorPrice,
            // Default value for ERC721 token quantity is 1
            maxBidTokenQuantity: 1,
            startBlock: _startBlock,
            endBlock: _endBlock,
            operator: msg.sender,
            valid: true,
            auctionId: currentAuctionId.current()
        });
        createdAuctionIds.push(currentAuctionId.current());
        walletAuctionIds[msg.sender].push(currentAuctionId.current());
        currentAuctionId.increment();
    }

    // Function that saves auction referral fees
    function saveAuctionReferralFees(
        uint256 _level1ReferralFee,
        uint256 _level2ReferralFee,
        uint256 _level3ReferralFee
    ) private {
        Referral.ReferralFees memory feesConfig = Referral.ReferralFees(
            _level1ReferralFee,
            _level2ReferralFee,
            _level3ReferralFee
        );
        auctionReferralFees[currentAuctionId.current()] = feesConfig;
    }

    // Function that saves auction royalty fees
    function saveAuctionRoyaltyFees(
        uint256 _auctionId,
        uint256 _tokenId
    ) private {
        Royalty.RoyaltyTeamMember[] memory teamMembers = metaproRoyalty
            .getTeamMembers(_tokenId, auctionTokenContractAddress[_auctionId]);

        Royalty.RoyaltyTeamMember[]
            storage royaltyAuctionFees = auctionRoyaltyTeamMembers[_auctionId];

        for (uint256 i = 0; i < teamMembers.length; ++i) {
            royaltyAuctionFees.push(teamMembers[i]);
        }
    }

    // Function fro getting current auction Id
    function getCurrentAuctionId() public view returns (uint256) {
        // Get current auction id substracted by 1
        return currentAuctionId.current().sub(1);
    }

    // Function to get auction by id
    function getAuctionById(
        uint256 _auctionId
    ) public view returns (AuctionConfiguration memory) {
        require(
            _auctionId > 0,
            "MetaproAuction721: AuctionId must be positive value"
        );
        return auctions[_auctionId];
    }

    function getAuctionBidsById(
        uint256 _auctionId
    ) public view returns (AuctionBid[] memory) {
        require(
            _auctionId > 0,
            "MetaproAuction721: AuctionId must be positive value"
        );
        uint256 correctArraySize = 0;
        for (uint256 i = 0; i < auctionsBids[_auctionId].length; i++) {
            if (auctionsBids[_auctionId][i].bidder != address(0)) {
                correctArraySize += 1;
            }
        }

        AuctionBid[] memory auctionBids = new AuctionBid[](correctArraySize);
        uint256 correctIndex = 0;
        for (uint256 i = 0; i < auctionsBids[_auctionId].length; i++) {
            if (auctionsBids[_auctionId][i].bidder != address(0)) {
                auctionBids[correctIndex] = auctionsBids[_auctionId][i];
                correctIndex++;
            }
        }

        return auctionBids;
    }

    // Function for getting Auction[] by tokenId
    function getTokenAuctions(
        uint256 _tokenId
    ) public view returns (AuctionConfiguration[] memory) {
        uint256 correctArraySize = 0;

        for (uint256 i = 0; i <= getCurrentAuctionId(); i++) {
            if (auctions[i].tokenId == _tokenId) {
                correctArraySize += 1;
            }
        }

        AuctionConfiguration[]
            memory tokenAuctions = new AuctionConfiguration[](correctArraySize);

        uint256 correctIndex = 0;
        for (uint256 i = 0; i <= getCurrentAuctionId(); i++) {
            if (auctions[i].tokenId == _tokenId) {
                tokenAuctions[correctIndex] = auctions[i];
                correctIndex++;
            }
        }

        return tokenAuctions;
    }

    function getAuctionTokens() public view returns (TokenAuction[] memory) {
        uint256 correctArraySize = 0;

        for (uint256 i = 0; i <= getCurrentAuctionId(); i++) {
            if (auctions[i].valid) {
                correctArraySize += 1;
            }
        }

        TokenAuction[] memory auctionsTokenIds = new TokenAuction[](
            correctArraySize
        );

        uint256 correctIndex = 0;
        for (uint256 i = 0; i <= getCurrentAuctionId(); i++) {
            AuctionConfiguration memory auction = auctions[i];
            if (auctions[i].valid) {
                auctionsTokenIds[correctIndex].tokenId = auction.tokenId;
                auctionsTokenIds[correctIndex]
                    .tokenContractAddress = auctionTokenContractAddress[
                    auction.auctionId
                ];
                auctionsTokenIds[correctIndex].active =
                    auction.endBlock > block.number &&
                    auction.startBlock < block.number;
                correctIndex++;
            }
        }

        return auctionsTokenIds;
    }

    // Get all available auctions
    function getAllAuctions()
        public
        view
        returns (AuctionConfiguration[] memory)
    {
        AuctionConfiguration[] memory allAuctions = new AuctionConfiguration[](
            createdAuctionIds.length
        );

        for (uint256 i = 0; i < createdAuctionIds.length; i++) {
            allAuctions[i] = auctions[createdAuctionIds[i]];
        }

        return allAuctions;
    }

    // Get auctions's heighest bid
    function getAuctionHeighestBid(
        uint256 _auctionId
    ) public view returns (AuctionBid memory) {
        // Check if auction for given id exists
        require(
            auctions[_auctionId].valid,
            "MetaproAuction721: Auction for given id does not exists"
        );
        AuctionBid[] memory auctionBids = getAuctionBidsById(_auctionId);
        // Check if auction has bids
        require(
            auctionBids.length > 0,
            "MetaproAuction721: Auction for given id does not have any bids"
        );
        AuctionBid memory heighestBid;
        for (uint256 i = 0; i < auctionBids.length; i++) {
            if (auctionBids[i].valid) {
                if (heighestBid.pricePerToken == 0) {
                    heighestBid = auctionBids[i];
                } else if (
                    auctionBids[i].pricePerToken > heighestBid.pricePerToken
                ) {
                    heighestBid = auctionBids[i];
                }
            }
        }

        return heighestBid;
    }

    function placeBid(
        uint256 _auctionId,
        uint256 _pricePerToken,
        uint256 _tokenQuantity,
        address _referrer
    ) public {
        AuctionConfiguration storage auctionConfig = auctions[_auctionId];

        // Check if auction is exists
        require(
            auctionConfig.auctionId > 0,
            "MetaproAuction721: Auction for given auctionId does not exists"
        );

        // Check if msg.sender is not auction operator
        require(
            auctionConfig.operator != msg.sender,
            "MetaproAuction721: Auction operator cannot bid for given auctionId"
        );

        // Check if auction is not ended that means auction end block is lower than current block
        require(
            auctionConfig.endBlock > block.number &&
                auctionConfig.startBlock < block.number,
            "MetaproAuction721: To place a bid auction must be active"
        );

        require(
            auctionConfig.valid && !operatorWithdrawn[_auctionId],
            "MetaproAuction721: Auction for given auctionId is finished"
        );
        require(
            _tokenQuantity == 1,
            "MetaproAuction721: Bid token quantity must be 1"
        );

        bool alreadyBidded = false;

        for (uint256 i = 0; i < auctionsBids[_auctionId].length; i++) {
            // Check if wallet address already bidded for given auctionId
            if (
                auctionsBids[_auctionId][i].bidder == msg.sender &&
                auctionsBids[_auctionId][i].valid
            ) {
                // Check if bid is heigher than previous bid
                require(
                    _pricePerToken >= auctionsBids[_auctionId][i].pricePerToken,
                    "MetaproAuction721: Bid price per token must be higher than in previous bid"
                );
                // Balance to be filled after bid increase
                uint256 missingBalance = _pricePerToken.sub(
                    auctionsBids[_auctionId][i].pricePerToken
                );
                busd.transferFrom(msg.sender, address(this), missingBalance);

                auctionBalance[_auctionId] += missingBalance;
                auctionsBids[_auctionId][i].accepted =
                    _pricePerToken >= auctionConfig.tokenFloorPrice;
                auctionsBids[_auctionId][i].pricePerToken = _pricePerToken;
                alreadyBidded = true;
            }
        }

        if (!alreadyBidded) {
            AuctionBid memory bidConfiguration = AuctionBid({
                bidder: msg.sender,
                tokenQuantity: 1,
                pricePerToken: _pricePerToken,
                accepted: _pricePerToken >= auctionConfig.tokenFloorPrice,
                bidBlockNumber: block.number,
                valid: true
            });
            // Send busd tokens to the contract address from bidder wallet address
            busd.transferFrom(msg.sender, address(this), _pricePerToken);
            auctionBalance[_auctionId] += _pricePerToken;
            auctionsBids[_auctionId].push(bidConfiguration);
        }
        metaproReferral.setReferral(msg.sender, _referrer);
        addAuctionIdToWallet(msg.sender, _auctionId);
    }

    // Add auctionId to walletAuctionIds when auctionId is not already added
    function addAuctionIdToWallet(address _wallet, uint256 _auctionId) private {
        bool auctionIdExists = false;
        for (uint256 i = 0; i < walletAuctionIds[_wallet].length; i++) {
            if (walletAuctionIds[_wallet][i] == _auctionId) {
                auctionIdExists = true;
            }
        }
        if (!auctionIdExists) {
            walletAuctionIds[_wallet].push(_auctionId);
        }
    }

    function getWalletBidAcceptedTokenQuantity(
        uint256 _auctionId,
        address _bidder
    ) public view returns (uint256) {
        uint256 disposedTokenQuantity = 0;
        uint256 bidderAcceptedTokenQuantity = 0;
        if (getAuctionBidsById(_auctionId).length == 0) {
            return bidderAcceptedTokenQuantity;
        }
        AuctionBid[]
            memory sortedBids = sortByPricePerTokenAndBlockNumberDescending(
                getAuctionBidsById(_auctionId)
            );
        uint256 index = 0;
        do {
            AuctionBid memory singleBid = sortedBids[index];
            // Check if pricePerToken is higher or equal with auction floor price
            // We need to auto pass bids above floor price
            if (singleBid.accepted) {
                if (singleBid.bidder == _bidder && disposedTokenQuantity == 0) {
                    bidderAcceptedTokenQuantity = 1;
                }
                disposedTokenQuantity = 1;
            }
            index++;
            // Check if bid value is higher than
        } while (index <= sortedBids.length - 1 || disposedTokenQuantity < 1);

        return bidderAcceptedTokenQuantity;
    }

    // Get auction bids required to sold token quantity
    function getRequiredToBeSoldTokenQuantity(
        uint256 _auctionId
    ) public view returns (uint256 requiredToSold) {
        uint256 requiredToSoldTokenQuantity = 0;
        if (getAuctionBidsById(_auctionId).length == 0) {
            return requiredToSoldTokenQuantity;
        }
        AuctionBid[]
            memory sortedBids = sortByPricePerTokenAndBlockNumberDescending(
                getAuctionBidsById(_auctionId)
            );
        uint256 index = 0;

        do {
            AuctionBid memory singleBid = sortedBids[index];
            if (singleBid.accepted) {
                requiredToSoldTokenQuantity = 1;
            }
            index++;
        } while (index <= sortedBids.length - 1);

        return requiredToSoldTokenQuantity;
    }

    // Get walletAuctionIds when the vakue in map is greater than 0
    function getWalletAuctionIds(
        address _wallet
    ) public view returns (uint256[] memory) {
        // Count how many auctionIds are is greater tahn 0
        uint256 count = 0;
        for (uint256 i = 0; i < walletAuctionIds[_wallet].length; i++) {
            if (walletAuctionIds[_wallet][i] > 0) {
                count++;
            }
        }
        uint256[] memory walletAuctionIdsMap = walletAuctionIds[_wallet];
        uint256[] memory walletAuctionIdsMapFiltered = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < walletAuctionIdsMap.length; i++) {
            if (walletAuctionIdsMap[i] > 0) {
                walletAuctionIdsMapFiltered[index] = walletAuctionIdsMap[i];
                index++;
            }
        }
        return walletAuctionIdsMapFiltered;
    }

    function getBatchAuctions(
        uint256[] memory _auctionIds
    ) public view returns (AuctionConfiguration[] memory) {
        AuctionConfiguration[]
            memory auctionsConfigurations = new AuctionConfiguration[](
                _auctionIds.length
            );

        for (uint256 i = 0; i < _auctionIds.length; i++) {
            // Require tokenId to be higher than 0
            require(
                auctions[_auctionIds[i]].tokenId > 0,
                "MetaproAuction721: Auction for given auctionId does not exist"
            );
            auctionsConfigurations[i] = auctions[_auctionIds[i]];
        }

        return auctionsConfigurations;
    }

    function removeBid(uint256 _auctionId) public {
        AuctionBid[] storage auctionBids = auctionsBids[_auctionId];
        uint256[] storage walletAuctionIdsMap = walletAuctionIds[msg.sender];

        bool hasActiveBiddsInAuction = false;
        for (uint256 index = 0; index < auctionBids.length; index++) {
            if (
                auctionBids[index].bidder == msg.sender &&
                auctionBids[index].valid
            ) {
                hasActiveBiddsInAuction = true;
                uint256 bidValue = auctionBids[index].pricePerToken;
                // Send back the bid value from contract to bidder
                busd.transfer(auctionBids[index].bidder, bidValue);
                auctionBalance[_auctionId] -= bidValue;
                delete auctionBids[index];
            }
        }
        require(
            hasActiveBiddsInAuction &&
                auctions[_auctionId].endBlock > block.number,
            "MetaproAuction721: Wallet has no active bid in auction or auction is ended"
        );
        for (uint256 index = 0; index < walletAuctionIdsMap.length; index++) {
            if (walletAuctionIdsMap[index] == _auctionId) {
                delete walletAuctionIdsMap[index];
            }
        }
    }

    function sortByPricePerTokenAndBlockNumberDescending(
        AuctionBid[] memory bids
    ) private pure returns (AuctionBid[] memory) {
        quickSortByPriceAndBlockDescending(bids, int(0), int(bids.length - 1));
        return bids;
    }

    function quickSortByPriceAndBlockDescending(
        AuctionBid[] memory bids,
        int left,
        int right
    ) private pure {
        if (left < right) {
            int pivotIndex = int(partition(bids, uint(left), uint(right)));
            if (pivotIndex > left) {
                quickSortByPriceAndBlockDescending(bids, left, pivotIndex - 1);
            }
            if (pivotIndex < right) {
                quickSortByPriceAndBlockDescending(bids, pivotIndex + 1, right);
            }
        }
    }

    function partition(
        AuctionBid[] memory bids,
        uint left,
        uint right
    ) private pure returns (uint) {
        uint pivotIndex = left;
        uint pivotPrice = bids[pivotIndex].pricePerToken;
        uint pivotBlock = bids[pivotIndex].bidBlockNumber;
        int i = int(left + 1);
        int j = int(right);

        while (i <= j) {
            while (
                i <= j &&
                (bids[uint(i)].pricePerToken > pivotPrice ||
                    (bids[uint(i)].pricePerToken == pivotPrice &&
                        bids[uint(i)].bidBlockNumber < pivotBlock))
            ) {
                i++;
            }

            while (
                j >= i &&
                (bids[uint(j)].pricePerToken < pivotPrice ||
                    (bids[uint(j)].pricePerToken == pivotPrice &&
                        bids[uint(j)].bidBlockNumber > pivotBlock))
            ) {
                j--;
            }

            if (i < j) {
                (bids[uint(i)], bids[uint(j)]) = (bids[uint(j)], bids[uint(i)]);
                i++;
                j--;
            }
        }

        uint newPivotIndex = uint(i - 1);
        (bids[left], bids[newPivotIndex]) = (bids[newPivotIndex], bids[left]);
        return newPivotIndex;
    }

    // Accept bid that is lower than floor price but first check how many tokens are required to be sold (pricePerToken is higher than floor price)
    function acceptBid(
        uint256 _auctionId,
        address _bidder
    ) public nonReentrant {
        AuctionConfiguration memory auction = auctions[_auctionId];
        // Check if function sender is operator on the auction
        require(
            auctions[_auctionId].operator == msg.sender,
            "MetaproAuction721: Only operator can accept bids"
        );

        // Check if auction is valid
        require(
            auction.valid &&
                auction.endBlock.add(finalizationBlockDelay) > block.number,
            "MetaproAuction721: Auction does not exist or is ended and can not be accepted"
        );

        // Find bidder bid in auction bids and get its value
        AuctionBid[] storage auctionBids = auctionsBids[_auctionId];
        AuctionBid memory bidderBid;
        for (uint256 index = 0; index < auctionBids.length; index++) {
            if (auctionBids[index].bidder == _bidder) {
                bidderBid = auctionBids[index];
            }
        }
        // Check if bid has truthy valid parameter that means that bid does not exist
        require(
            bidderBid.valid,
            "MetaproAuction721: Bid does not exist and can not be accepted"
        );
        // Check if bid value is lower than floor price
        require(
            bidderBid.pricePerToken < auction.tokenFloorPrice,
            "MetaproAuction721: Bid value is higher than floor price and is accepted automatically"
        );
        // Check if bid is not accepted
        require(
            !bidderBid.accepted,
            "MetaproAuction721: Bid is already accepted and can not be accepted again"
        );
        // Check how many tokens are required to be sold (bid values are higher than floor price) using requiredToSoldTokenQuantity function
        uint256 requiredToSoldTokenQuantity = getRequiredToBeSoldTokenQuantity(
            _auctionId
        );

        // Check if requiredToSoldTokenQuantity is lower than bid that is about to be accepted
        require(
            requiredToSoldTokenQuantity == 0,
            "MetaproAuction721: Bid is not accepted because there is another accepted bid"
        );
        // Find valid auction bid and change accepted value to true
        for (uint256 index = 0; index < auctionBids.length; index++) {
            if (
                auctionBids[index].bidder == _bidder && auctionBids[index].valid
            ) {
                auctionBids[index].accepted = true;
            }
        }

        // Emit event that auction is accepted
        emit AuctionBidAccepted(_auctionId, _bidder);
    }

    function closeAuction(uint256 _auctionId, bytes memory _data) public {
        // Get auction configuration by auctionId
        AuctionConfiguration memory auction = auctions[_auctionId];
        // Check if auction is valid
        require(
            auction.auctionId != 0,
            "MetaproAuction721: Auction does not exist and can not be closed"
        );
        // Check if auction has truthy valid parameter
        require(auction.valid, "MetaproAuction721: Auction is already closed");
        // Get auction fees configuration by auctionId
        Referral.ReferralFees memory _auctionFees = auctionReferralFees[
            _auctionId
        ];
        // Get auction bids by auctionID
        AuctionBid[] memory _auctionBids = auctionsBids[_auctionId];
        // Check if msg.sender is auction operator and if is fire finalizeAuctionByOperator function
        if (auction.operator == msg.sender) {
            finalizeAuctionByOperator(
                _auctionId,
                _auctionFees,
                _auctionBids,
                _data
            );
        } else {
            // If msg.sender is not auction operator fire finalizeAuctionByParticipant function
            finalizeAuctionByParticipant(_auctionId);
        }
    }

    // Finalize auction by participant by auctionId
    function finalizeAuctionByParticipant(
        uint256 _auctionId
    ) private finalizeEnabled(_auctionId) nonReentrant {
        // Get memory auction by auctionId
        AuctionConfiguration memory auction = auctions[_auctionId];
        // Get AuctionBid for the msg.sender
        AuctionBid[] storage auctionBids = auctionsBids[_auctionId];
        // Find ms.sender bid in auctionBids
        AuctionBid memory walletBid;
        for (uint256 index = 0; index < auctionBids.length; index++) {
            if (auctionBids[index].bidder == msg.sender) {
                walletBid = auctionBids[index];
            }
        }
        // Check if walletBid exists
        require(
            walletBid.valid,
            "MetaproAuction721: Auction can not be finalized by participant that does not have any active bids"
        );

        // Count how many tokens are required to be sold for msg.sender with function getWalletBidAcceptedTokenQuantity
        uint256 walletBidAcceptedTokenQuantity = getWalletBidAcceptedTokenQuantity(
                _auctionId,
                msg.sender
            );

        // When walletBid is accepted send tokens to walletBid bidder
        if (walletBidAcceptedTokenQuantity > 0) {
            // Get auction token contract IERC721 address from mapping auctionTokenContractAddress
            IERC721 auctionTokenContract = IERC721(
                auctionTokenContractAddress[_auctionId]
            );
            // Send tokens to walletBid bidder
            auctionTokenContract.safeTransferFrom(
                address(this),
                msg.sender,
                auction.tokenId
            );
            sendFeesToReferrers(
                auction,
                auctionReferralFees[auction.auctionId],
                walletBid.pricePerToken,
                msg.sender
            );
        } else {
            // When walletBid is not accepted send busd tokens back to bidder
            busd.transfer(msg.sender, walletBid.pricePerToken);
        }

        // Unvalidate wallet bids
        for (uint256 index = 0; index < auctionBids.length; index++) {
            if (
                auctionBids[index].bidder == msg.sender &&
                auctionBids[index].valid
            ) {
                auctionBids[index].valid = false;
            }
        }

        // Emit event that auction is finalized by participant
        emit AuctionFinalizedByParticipant(_auctionId, msg.sender);
    }

    function isFinalizedByOperator(
        uint256 _auctionId
    ) public view returns (bool) {
        // Check if auction by auctionId is valid
        require(
            auctions[_auctionId].valid,
            "MetaproAuction721: Auction does not exist"
        );
        return operatorWithdrawn[_auctionId];
    }

    // Finalize auction by operator by auctionId
    function finalizeAuctionByOperator(
        uint256 _auctionId,
        Referral.ReferralFees memory _auctionFeesConfiguration,
        AuctionBid[] memory _auctionBids,
        bytes memory _data
    ) private finalizeEnabled(_auctionId) nonReentrant {
        // Get memory auction by auctionId
        AuctionConfiguration storage _auction = auctions[_auctionId];
        require(
            _data.length == 0 || (_data.length == 1 && _data[0] == 0x00),
            "MetaproBuyNow721: data must be empty or equal to 0x00"
        );
        // Check if msg.sender is auction operator
        require(
            _auction.operator == msg.sender,
            "MetaproAuction721: Only operator can finalize auction"
        );
        // Check is auction is already withdrawn by operator
        require(
            !isFinalizedByOperator(_auctionId),
            "MetaproAuction721: Auction is already withdrawn by operator"
        );

        uint256 tokensLocked = _auctionBids.length > 0
            ? getRequiredToBeSoldTokenQuantity(_auctionId)
            : 0;
        uint256 totalApprovedBidsValue = 0;
        uint256 busdAmountFromBids = 0;
        for (uint256 i = 0; i < _auctionBids.length; i++) {
            AuctionBid memory singleWalletBid = _auctionBids[i];
            if (
                singleWalletBid.bidder != msg.sender &&
                singleWalletBid.bidder != address(0)
            ) {
                uint256 walletBidAcceptedTokenQuantity = getWalletBidAcceptedTokenQuantity(
                        _auctionId,
                        singleWalletBid.bidder
                    );
                // Calculate referral fees from deposits
                if (walletBidAcceptedTokenQuantity > 0) {
                    uint256 refFee = calculateReferralFee(
                        _auctionFeesConfiguration,
                        singleWalletBid.pricePerToken,
                        singleWalletBid.bidder
                    );
                    busdAmountFromBids +=
                        singleWalletBid.pricePerToken -
                        refFee;
                    totalApprovedBidsValue += singleWalletBid.pricePerToken;
                }
            }
        }

        // Calculate treasury fee
        uint256 treasuryFeeAmount = totalApprovedBidsValue.mul(treasuryFee).div(
            10000
        );

        // Send fee to the treasury address
        busd.transfer(tressuryAddress, treasuryFeeAmount);

        // Send fee to the royalty team
        uint256 royaltyFee = sendFeesToRoyaltyTeamMembers(
            _auction,
            totalApprovedBidsValue
        );

        uint256 operatorTokens = _auction.tokenQuantity - tokensLocked;

        // Give back operator tokens when is something left
        if (operatorTokens > 0) {
            IERC721(auctionTokenContractAddress[_auction.auctionId])
                .safeTransferFrom(
                    address(this),
                    _auction.operator,
                    _auction.tokenId
                );
        }

        uint256 operatorEarnings = sendEarningsToOperator(
            _auction,
            busdAmountFromBids - royaltyFee - treasuryFeeAmount
        );

        // Subtract ins balance by sent operator earnings with
        auctionBalance[_auction.auctionId] = 0;
        operatorWithdrawn[_auction.auctionId] = true;
        if (block.number < _auction.startBlock) {
            _auction.valid = false;
        }

        emit OperatorWithdraw(
            _auction.auctionId,
            msg.sender,
            operatorEarnings,
            operatorTokens
        );
    }

    function sendEarningsToOperator(
        AuctionConfiguration memory _auction,
        uint256 _bidsAmountWithFees
    ) private returns (uint256) {
        busd.transfer(_auction.operator, _bidsAmountWithFees);
        return _bidsAmountWithFees;
    }

    function depositOnReferrer(
        uint256 _auctionId,
        address _referrer,
        address _depositer,
        uint256 _amount,
        uint256 _referralFee,
        uint256 _tokenId,
        uint256 _level
    ) private returns (uint256) {
        uint256 referralFeeAmount = _amount.mul(_referralFee).div(10000);

        busd.transfer(_referrer, referralFeeAmount);

        metaproReferral.saveReferralDeposit(
            _referrer,
            address(this),
            _auctionId,
            _tokenId,
            _depositer,
            _level,
            referralFeeAmount
        );
        return referralFeeAmount;
    }

    function sendFeesToReferrers(
        AuctionConfiguration memory _auctionConfiguration,
        Referral.ReferralFees memory _auctionFeesConfiguration,
        uint256 _amount,
        address _depositer
    ) private returns (uint256) {
        uint256 fee = 0;
        address level1Referrer = metaproReferral.getReferral(_depositer);
        if (level1Referrer != address(0)) {
            // Level 1
            if (_auctionFeesConfiguration.level1ReferrerFee > 0) {
                uint256 level1Fee = depositOnReferrer(
                    _auctionConfiguration.auctionId,
                    level1Referrer,
                    _depositer,
                    _amount,
                    _auctionFeesConfiguration.level1ReferrerFee,
                    _auctionConfiguration.tokenId,
                    1
                );

                fee += level1Fee;
            }
            // Level 2
            address level2Referrer = metaproReferral.getReferral(
                level1Referrer
            );
            if (level2Referrer != address(0)) {
                if (_auctionFeesConfiguration.level2ReferrerFee > 0) {
                    uint256 level2Fee = depositOnReferrer(
                        _auctionConfiguration.auctionId,
                        level2Referrer,
                        _depositer,
                        _amount,
                        _auctionFeesConfiguration.level2ReferrerFee,
                        _auctionConfiguration.tokenId,
                        2
                    );

                    fee += level2Fee;
                }

                // Level 3
                address level3Referrer = metaproReferral.getReferral(
                    level2Referrer
                );
                if (level3Referrer != address(0)) {
                    if (_auctionFeesConfiguration.level3ReferrerFee > 0) {
                        uint256 level3Fee = depositOnReferrer(
                            _auctionConfiguration.auctionId,
                            level3Referrer,
                            _depositer,
                            _amount,
                            _auctionFeesConfiguration.level3ReferrerFee,
                            _auctionConfiguration.tokenId,
                            3
                        );
                        fee += level3Fee;
                    }
                }
            }
        }
        return fee;
    }

    function calculateReferralFee(
        Referral.ReferralFees memory _auctionFeesConfiguration,
        uint256 _amount,
        address _depositer
    ) private view returns (uint256) {
        uint256 fee = 0;
        address level1Referrer = metaproReferral.getReferral(_depositer);
        if (level1Referrer != address(0)) {
            // Level 1
            if (_auctionFeesConfiguration.level1ReferrerFee > 0) {
                fee += _amount
                    .mul(_auctionFeesConfiguration.level1ReferrerFee)
                    .div(10000);
            }
            // Level 2
            address level2Referrer = metaproReferral.getReferral(
                level1Referrer
            );
            if (level2Referrer != address(0)) {
                if (_auctionFeesConfiguration.level2ReferrerFee > 0) {
                    fee += _amount
                        .mul(_auctionFeesConfiguration.level2ReferrerFee)
                        .div(10000);
                }

                // Level 3
                address level3Referrer = metaproReferral.getReferral(
                    level2Referrer
                );
                if (level3Referrer != address(0)) {
                    if (_auctionFeesConfiguration.level3ReferrerFee > 0) {
                        fee += _amount
                            .mul(_auctionFeesConfiguration.level3ReferrerFee)
                            .div(10000);
                    }
                }
            }
        }
        return fee;
    }

    function sendFeesToRoyaltyTeamMembers(
        AuctionConfiguration memory _auctionConfiguration,
        uint256 _amount
    ) private returns (uint256) {
        uint256 fee = 0;
        Royalty.RoyaltyTeamMember[]
            storage royaltyTeamMembers = auctionRoyaltyTeamMembers[
                _auctionConfiguration.auctionId
            ];

        for (uint256 i = 0; i < royaltyTeamMembers.length; i++) {
            Royalty.RoyaltyTeamMember memory member = royaltyTeamMembers[i];
            uint256 royaltyFee = _amount.mul(member.royaltyFee).div(10000);
            busd.transfer(member.member, royaltyFee);
            fee += royaltyFee;
        }

        return fee;
    }

    //Function to set finalizationBlockDelay only by owner
    function setFinalizationBlockDelay(
        uint256 _finalizationBlockDelay
    ) public onlyOwner {
        finalizationBlockDelay = _finalizationBlockDelay;
    }

    function setTreasuryFee(uint256 _fee) external onlyOwner {
        require(_fee < 2500, "INS: Fee can't be greater than 2,5%; 2500");
        treasuryFee = _fee;
    }

    function setAddresses(
        address _busdAddress,
        address _treasuryAddress,
        address _referralAddress,
        address _royaltyAddress
    ) external onlyOwner {
        busd = IERC20(_busdAddress);
        tressuryAddress = _treasuryAddress;
        referralAddress = _referralAddress;
        metaproReferral = MetaproReferral(_referralAddress);
        royaltyAddress = _royaltyAddress;
        metaproRoyalty = MetaproRoyalty(_royaltyAddress);
    }
}