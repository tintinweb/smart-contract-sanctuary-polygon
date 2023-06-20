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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title KyberSwap v2 factory
/// @notice Deploys KyberSwap v2 pools and manages control over government fees
interface IFactory {
  /// @notice Emitted when a pool is created
  /// @param token0 First pool token by address sort order
  /// @param token1 Second pool token by address sort order
  /// @param swapFeeUnits Fee to be collected upon every swap in the pool, in fee units
  /// @param tickDistance Minimum number of ticks between initialized ticks
  /// @param pool The address of the created pool
  event PoolCreated(
    address indexed token0,
    address indexed token1,
    uint24 indexed swapFeeUnits,
    int24 tickDistance,
    address pool
  );

  /// @notice Emitted when a new fee is enabled for pool creation via the factory
  /// @param swapFeeUnits Fee to be collected upon every swap in the pool, in fee units
  /// @param tickDistance Minimum number of ticks between initialized ticks for pools created with the given fee
  event SwapFeeEnabled(uint24 indexed swapFeeUnits, int24 indexed tickDistance);

  /// @notice Emitted when vesting period changes
  /// @param vestingPeriod The maximum time duration for which LP fees
  /// are proportionally burnt upon LP removals
  event VestingPeriodUpdated(uint32 vestingPeriod);

  /// @notice Emitted when configMaster changes
  /// @param oldConfigMaster configMaster before the update
  /// @param newConfigMaster configMaster after the update
  event ConfigMasterUpdated(address oldConfigMaster, address newConfigMaster);

  /// @notice Emitted when fee configuration changes
  /// @param feeTo Recipient of government fees
  /// @param governmentFeeUnits Fee amount, in fee units,
  /// to be collected out of the fee charged for a pool swap
  event FeeConfigurationUpdated(address feeTo, uint24 governmentFeeUnits);

  /// @notice Emitted when whitelist feature is enabled
  event WhitelistEnabled();

  /// @notice Emitted when whitelist feature is disabled
  event WhitelistDisabled();

  /// @notice Returns the maximum time duration for which LP fees
  /// are proportionally burnt upon LP removals
  function vestingPeriod() external view returns (uint32);

  /// @notice Returns the tick distance for a specified fee.
  /// @dev Once added, cannot be updated or removed.
  /// @param swapFeeUnits Swap fee, in fee units.
  /// @return The tick distance. Returns 0 if fee has not been added.
  function feeAmountTickDistance(uint24 swapFeeUnits) external view returns (int24);

  /// @notice Returns the address which can update the fee configuration
  function configMaster() external view returns (address);

  /// @notice Returns the keccak256 hash of the Pool creation code
  /// This is used for pre-computation of pool addresses
  function poolInitHash() external view returns (bytes32);

  /// @notice Returns the pool oracle contract for twap
  function poolOracle() external view returns (address);

  /// @notice Fetches the recipient of government fees
  /// and current government fee charged in fee units
  function feeConfiguration() external view returns (address _feeTo, uint24 _governmentFeeUnits);

  /// @notice Returns the status of whitelisting feature of NFT managers
  /// If true, anyone can mint liquidity tokens
  /// Otherwise, only whitelisted NFT manager(s) are allowed to mint liquidity tokens
  function whitelistDisabled() external view returns (bool);

  //// @notice Returns all whitelisted NFT managers
  /// If the whitelisting feature is turned on,
  /// only whitelisted NFT manager(s) are allowed to mint liquidity tokens
  function getWhitelistedNFTManagers() external view returns (address[] memory);

  /// @notice Checks if sender is a whitelisted NFT manager
  /// If the whitelisting feature is turned on,
  /// only whitelisted NFT manager(s) are allowed to mint liquidity tokens
  /// @param sender address to be checked
  /// @return true if sender is a whistelisted NFT manager, false otherwise
  function isWhitelistedNFTManager(address sender) external view returns (bool);

  /// @notice Returns the pool address for a given pair of tokens and a swap fee
  /// @dev Token order does not matter
  /// @param tokenA Contract address of either token0 or token1
  /// @param tokenB Contract address of the other token
  /// @param swapFeeUnits Fee to be collected upon every swap in the pool, in fee units
  /// @return pool The pool address. Returns null address if it does not exist
  function getPool(
    address tokenA,
    address tokenB,
    uint24 swapFeeUnits
  ) external view returns (address pool);

  /// @notice Fetch parameters to be used for pool creation
  /// @dev Called by the pool constructor to fetch the parameters of the pool
  /// @return factory The factory address
  /// @return poolOracle The pool oracle for twap
  /// @return token0 First pool token by address sort order
  /// @return token1 Second pool token by address sort order
  /// @return swapFeeUnits Fee to be collected upon every swap in the pool, in fee units
  /// @return tickDistance Minimum number of ticks between initialized ticks
  function parameters()
    external
    view
    returns (
      address factory,
      address poolOracle,
      address token0,
      address token1,
      uint24 swapFeeUnits,
      int24 tickDistance
    );

  /// @notice Creates a pool for the given two tokens and fee
  /// @param tokenA One of the two tokens in the desired pool
  /// @param tokenB The other of the two tokens in the desired pool
  /// @param swapFeeUnits Desired swap fee for the pool, in fee units
  /// @dev Token order does not matter. tickDistance is determined from the fee.
  /// Call will revert under any of these conditions:
  ///     1) pool already exists
  ///     2) invalid swap fee
  ///     3) invalid token arguments
  /// @return pool The address of the newly created pool
  function createPool(
    address tokenA,
    address tokenB,
    uint24 swapFeeUnits
  ) external returns (address pool);

  /// @notice Enables a fee amount with the given tickDistance
  /// @dev Fee amounts may never be removed once enabled
  /// @param swapFeeUnits The fee amount to enable, in fee units
  /// @param tickDistance The distance between ticks to be enforced for all pools created with the given fee amount
  function enableSwapFee(uint24 swapFeeUnits, int24 tickDistance) external;

  /// @notice Updates the address which can update the fee configuration
  /// @dev Must be called by the current configMaster
  function updateConfigMaster(address) external;

  /// @notice Updates the vesting period
  /// @dev Must be called by the current configMaster
  function updateVestingPeriod(uint32) external;

  /// @notice Updates the address receiving government fees and fee quantity
  /// @dev Only configMaster is able to perform the update
  /// @param feeTo Address to receive government fees collected from pools
  /// @param governmentFeeUnits Fee amount, in fee units,
  /// to be collected out of the fee charged for a pool swap
  function updateFeeConfiguration(address feeTo, uint24 governmentFeeUnits) external;

  /// @notice Enables the whitelisting feature
  /// @dev Only configMaster is able to perform the update
  function enableWhitelist() external;

  /// @notice Disables the whitelisting feature
  /// @dev Only configMaster is able to perform the update
  function disableWhitelist() external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IPoolActions} from './pool/IPoolActions.sol';
import {IPoolEvents} from './pool/IPoolEvents.sol';
import {IPoolStorage} from './pool/IPoolStorage.sol';

interface IPool is IPoolActions, IPoolEvents, IPoolStorage {}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IPoolOracle {
  /// @notice Owner withdrew funds in the pool oracle in case some funds are stuck there
  event OwnerWithdrew(
    address indexed owner,
    address indexed token,
    uint256 indexed amount
  );

  /// @notice Emitted by the Pool Oracle for increases to the number of observations that can be stored
  /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
  /// just before a mint/swap/burn.
  /// @param pool The pool address to update
  /// @param observationCardinalityNextOld The previous value of the next observation cardinality
  /// @param observationCardinalityNextNew The updated value of the next observation cardinality
  event IncreaseObservationCardinalityNext(
    address pool,
    uint16 observationCardinalityNextOld,
    uint16 observationCardinalityNextNew
  );

  /// @notice Initalize observation data for the caller.
  function initializeOracle(uint32 time)
    external
    returns (uint16 cardinality, uint16 cardinalityNext);

  /// @notice Write a new oracle entry into the array
  ///   and update the observation index and cardinality
  /// Read the Oralce.write function for more details
  function writeNewEntry(
    uint16 index,
    uint32 blockTimestamp,
    int24 tick,
    uint128 liquidity,
    uint16 cardinality,
    uint16 cardinalityNext
  )
    external
    returns (uint16 indexUpdated, uint16 cardinalityUpdated);

  /// @notice Write a new oracle entry into the array, take the latest observaion data as inputs
  ///   and update the observation index and cardinality
  /// Read the Oralce.write function for more details
  function write(
    uint32 blockTimestamp,
    int24 tick,
    uint128 liquidity
  )
    external
    returns (uint16 indexUpdated, uint16 cardinalityUpdated);

  /// @notice Increase the maximum number of price observations that this pool will store
  /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
  /// the input observationCardinalityNext.
  /// @param pool The pool address to be updated
  /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
  function increaseObservationCardinalityNext(
    address pool,
    uint16 observationCardinalityNext
  )
    external;

  /// @notice Returns the accumulator values as of each time seconds ago from the latest block time in the array of `secondsAgos`
  /// @dev Reverts if `secondsAgos` > oldest observation
  /// @dev It fetches the latest current tick data from the pool
  /// Read the Oracle.observe function for more details
  function observeFromPool(
    address pool,
    uint32[] memory secondsAgos
  )
    external view
    returns (int56[] memory tickCumulatives);

  /// @notice Returns the accumulator values as the time seconds ago from the latest block time of secondsAgo
  /// @dev Reverts if `secondsAgo` > oldest observation
  /// @dev It fetches the latest current tick data from the pool
  /// Read the Oracle.observeSingle function for more details
  function observeSingleFromPool(
    address pool,
    uint32 secondsAgo
  )
    external view
    returns (int56 tickCumulative);

  /// @notice Return the latest pool observation data given the pool address
  function getPoolObservation(address pool)
    external view
    returns (bool initialized, uint16 index, uint16 cardinality, uint16 cardinalityNext);

  /// @notice Returns data about a specific observation index
  /// @param pool The pool address of the observations array to fetch
  /// @param index The element of the observations array to fetch
  /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
  /// ago, rather than at a specific index in the array.
  /// @return blockTimestamp The timestamp of the observation,
  /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
  /// Returns initialized whether the observation has been initialized and the values are safe to use
  function getObservationAt(address pool, uint256 index)
    external view
    returns (
      uint32 blockTimestamp,
      int56 tickCumulative,
      bool initialized
    );
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IBasePositionManagerEvents {
  /// @notice Emitted when a token is minted for a given position
  /// @param tokenId the newly minted tokenId
  /// @param poolId poolId of the token
  /// @param liquidity liquidity minted to the position range
  /// @param amount0 token0 quantity needed to mint the liquidity
  /// @param amount1 token1 quantity needed to mint the liquidity
  event MintPosition(
    uint256 indexed tokenId,
    uint80 indexed poolId,
    uint128 liquidity,
    uint256 amount0,
    uint256 amount1
  );

  /// @notice Emitted when a token is burned
  /// @param tokenId id of the token
  event BurnPosition(uint256 indexed tokenId);

  /// @notice Emitted when add liquidity
  /// @param tokenId id of the token
  /// @param liquidity the increase amount of liquidity
  /// @param amount0 token0 quantity needed to increase liquidity
  /// @param amount1 token1 quantity needed to increase liquidity
  /// @param additionalRTokenOwed additional rToken earned
  event AddLiquidity(
    uint256 indexed tokenId,
    uint128 liquidity,
    uint256 amount0,
    uint256 amount1,
    uint256 additionalRTokenOwed
  );

  /// @notice Emitted when remove liquidity
  /// @param tokenId id of the token
  /// @param liquidity the decease amount of liquidity
  /// @param amount0 token0 quantity returned when remove liquidity
  /// @param amount1 token1 quantity returned when remove liquidity
  /// @param additionalRTokenOwed additional rToken earned
  event RemoveLiquidity(
    uint256 indexed tokenId,
    uint128 liquidity,
    uint256 amount0,
    uint256 amount1,
    uint256 additionalRTokenOwed
  );

  /// @notice Emitted when burn position's RToken
  /// @param tokenId id of the token
  /// @param rTokenBurn amount of position's RToken burnt
  event BurnRToken(uint256 indexed tokenId, uint256 rTokenBurn);

  /// @notice Emitted when sync fee growth
  /// @param tokenId id of the token
  /// @param additionalRTokenOwed additional rToken earned
  event SyncFeeGrowth(uint256 indexed tokenId, uint256 additionalRTokenOwed);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.9;
import "./IBasePositionManager.sol";

interface IAntiSnipAttackPositionManager is IBasePositionManager {
    function mint(
        MintParams calldata params
    )
        external
        payable
        override
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    function addLiquidity(
        IncreaseLiquidityParams calldata params
    )
        external
        payable
        override
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1,
            uint256 additionalRTokenOwed
        );

    function removeLiquidity(
        RemoveLiquidityParams calldata params
    )
        external
        override
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 additionalRTokenOwed
        );

    function syncFeeGrowth(
        uint256 tokenId
    ) external override returns (uint256 additionalRTokenOwed);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

import {IERC721Metadata} from '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import {IRouterTokenHelper} from './IRouterTokenHelper.sol';
import {IBasePositionManagerEvents} from './base_position_manager/IBasePositionManagerEvents.sol';
import {IERC721Permit} from './IERC721Permit.sol';

interface IBasePositionManager is IRouterTokenHelper, IBasePositionManagerEvents {
  struct Position {
    // the nonce for permits
    uint96 nonce;
    // the address that is approved for spending this token
    address operator;
    // the ID of the pool with which this token is connected
    uint80 poolId;
    // the tick range of the position
    int24 tickLower;
    int24 tickUpper;
    // the liquidity of the position
    uint128 liquidity;
    // the current rToken that the position owed
    uint256 rTokenOwed;
    // fee growth per unit of liquidity as of the last update to liquidity
    uint256 feeGrowthInsideLast;
  }

  struct PoolInfo {
    address token0;
    uint24 fee;
    address token1;
  }

  /// @notice Params for the first time adding liquidity, mint new nft to sender
  /// @param token0 the token0 of the pool
  /// @param token1 the token1 of the pool
  ///   - must make sure that token0 < token1
  /// @param fee the pool's fee in fee units
  /// @param tickLower the position's lower tick
  /// @param tickUpper the position's upper tick
  ///   - must make sure tickLower < tickUpper, and both are in tick distance
  /// @param ticksPrevious the nearest tick that has been initialized and lower than or equal to
  ///   the tickLower and tickUpper, use to help insert the tickLower and tickUpper if haven't initialized
  /// @param amount0Desired the desired amount for token0
  /// @param amount1Desired the desired amount for token1
  /// @param amount0Min min amount of token 0 to add
  /// @param amount1Min min amount of token 1 to add
  /// @param recipient the owner of the position
  /// @param deadline time that the transaction will be expired
  struct MintParams {
    address token0;
    address token1;
    uint24 fee;
    int24 tickLower;
    int24 tickUpper;
    int24[2] ticksPrevious;
    uint256 amount0Desired;
    uint256 amount1Desired;
    uint256 amount0Min;
    uint256 amount1Min;
    address recipient;
    uint256 deadline;
  }

  /// @notice Params for adding liquidity to the existing position
  /// @param tokenId id of the position to increase its liquidity
  /// @param ticksPrevious the nearest tick that has been initialized and lower than or equal to
  ///   the tickLower and tickUpper, use to help insert the tickLower and tickUpper if haven't initialized
  ///   only needed if the position has been closed and the owner wants to add more liquidity
  /// @param amount0Desired the desired amount for token0
  /// @param amount1Desired the desired amount for token1
  /// @param amount0Min min amount of token 0 to add
  /// @param amount1Min min amount of token 1 to add
  /// @param deadline time that the transaction will be expired
  struct IncreaseLiquidityParams {
    uint256 tokenId;
    int24[2] ticksPrevious;
    uint256 amount0Desired;
    uint256 amount1Desired;
    uint256 amount0Min;
    uint256 amount1Min;
    uint256 deadline;
  }

  /// @notice Params for remove liquidity from the existing position
  /// @param tokenId id of the position to remove its liquidity
  /// @param amount0Min min amount of token 0 to receive
  /// @param amount1Min min amount of token 1 to receive
  /// @param deadline time that the transaction will be expired
  struct RemoveLiquidityParams {
    uint256 tokenId;
    uint128 liquidity;
    uint256 amount0Min;
    uint256 amount1Min;
    uint256 deadline;
  }

  /// @notice Burn the rTokens to get back token0 + token1 as fees
  /// @param tokenId id of the position to burn r token
  /// @param amount0Min min amount of token 0 to receive
  /// @param amount1Min min amount of token 1 to receive
  /// @param deadline time that the transaction will be expired
  struct BurnRTokenParams {
    uint256 tokenId;
    uint256 amount0Min;
    uint256 amount1Min;
    uint256 deadline;
  }

  /// @notice Creates a new pool if it does not exist, then unlocks if it has not been unlocked
  /// @param token0 the token0 of the pool
  /// @param token1 the token1 of the pool
  /// @param fee the fee for the pool
  /// @param currentSqrtP the initial price of the pool
  /// @return pool returns the pool address
  function createAndUnlockPoolIfNecessary(
    address token0,
    address token1,
    uint24 fee,
    uint160 currentSqrtP
  ) external payable returns (address pool);

  function mint(MintParams calldata params)
    external
    payable
    returns (
      uint256 tokenId,
      uint128 liquidity,
      uint256 amount0,
      uint256 amount1
    );

  function addLiquidity(IncreaseLiquidityParams calldata params)
    external
    payable
    returns (
      uint128 liquidity,
      uint256 amount0,
      uint256 amount1,
      uint256 additionalRTokenOwed
    );

  function removeLiquidity(RemoveLiquidityParams calldata params)
    external
    returns (
      uint256 amount0,
      uint256 amount1,
      uint256 additionalRTokenOwed
    );

  function burnRTokens(BurnRTokenParams calldata params)
    external
    returns (
      uint256 rTokenQty,
      uint256 amount0,
      uint256 amount1
    );

  /**
   * @dev Burn the token by its owner
   * @notice All liquidity should be removed before burning
   */
  function burn(uint256 tokenId) external payable;

  function syncFeeGrowth(uint256 tokenId) external returns (uint256 additionalRTokenOwed);

  function positions(uint256 tokenId)
    external
    view
    returns (Position memory pos, PoolInfo memory info);

  function addressToPoolId(address pool) external view returns (uint80);

  function isRToken(address token) external view returns (bool);

  function nextPoolId() external view returns (uint80);

  function nextTokenId() external view returns (uint256);

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {IERC721Enumerable} from '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';

/// @title ERC721 with permit
/// @notice Extension to ERC721 that includes a permit function for signature based approvals
interface IERC721Permit is IERC721, IERC721Enumerable {
  /// @notice The permit typehash used in the permit signature
  /// @return The typehash for the permit
  function PERMIT_TYPEHASH() external pure returns (bytes32);

  /// @notice The domain separator used in the permit signature
  /// @return The domain seperator used in encoding of permit signature
  function DOMAIN_SEPARATOR() external view returns (bytes32);

  /// @notice Approve of a specific token ID for spending by spender via signature
  /// @param spender The account that is being approved
  /// @param tokenId The ID of the token that is being approved for spending
  /// @param deadline The deadline timestamp by which the call must be mined for the approve to work
  /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
  /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
  /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
  function permit(
    address spender,
    uint256 tokenId,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

interface IRouterTokenHelper {
  /// @notice Unwraps the contract's WETH balance and sends it to recipient as ETH.
  /// @dev The minAmount parameter prevents malicious contracts from stealing WETH from users.
  /// @param minAmount The minimum amount of WETH to unwrap
  /// @param recipient The address receiving ETH
  function unwrapWeth(uint256 minAmount, address recipient) external payable;

  /// @notice Refunds any ETH balance held by this contract to the `msg.sender`
  /// @dev Useful for bundling with mint or increase liquidity that uses ether, or exact output swaps
  /// that use ether for the input amount
  function refundEth() external payable;

  /// @notice Transfers the full amount of a token held by this contract to recipient
  /// @dev The minAmount parameter prevents malicious contracts from stealing the token from users
  /// @param token The contract address of the token which will be transferred to `recipient`
  /// @param minAmount The minimum amount of token required for a transfer
  /// @param recipient The destination address of the token
  function transferAllTokens(
    address token,
    uint256 minAmount,
    address recipient
  ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.9;
pragma abicoder v2;

import {IPoolStorage} from "../pool/IPoolStorage.sol";
import {IBasePositionManager} from "./IBasePositionManager.sol";

interface ITicksFeesReader {
    /// @dev Simplest method that attempts to fetch all initialized ticks
    /// Has the highest probability of running out of gas
    function getAllTicks(
        IPoolStorage pool
    ) external view returns (int24[] memory allTicks);

    /// @dev Fetches all initialized ticks with a specified startTick (searches uptick)
    /// @dev 0 length = Use maximum length
    function getTicksInRange(
        IPoolStorage pool,
        int24 startTick,
        uint32 length
    ) external view returns (int24[] memory allTicks);

    function getNearestInitializedTicks(
        IPoolStorage pool,
        int24 tick
    ) external view returns (int24 previous, int24 next);

    function getTotalRTokensOwedToPosition(
        IBasePositionManager posManager,
        IPoolStorage pool,
        uint256 tokenId
    ) external view returns (uint256 rTokenOwed);

    function getTotalFeesOwedToPosition(
        IBasePositionManager posManager,
        IPoolStorage pool,
        uint256 tokenId
    ) external view returns (uint256 token0Owed, uint256 token1Owed);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IPoolActions {
  /// @notice Sets the initial price for the pool and seeds reinvestment liquidity
  /// @dev Assumes the caller has sent the necessary token amounts
  /// required for initializing reinvestment liquidity prior to calling this function
  /// @param initialSqrtP the initial sqrt price of the pool
  /// @param qty0 token0 quantity sent to and locked permanently in the pool
  /// @param qty1 token1 quantity sent to and locked permanently in the pool
  function unlockPool(uint160 initialSqrtP) external returns (uint256 qty0, uint256 qty1);

  /// @notice Adds liquidity for the specified recipient/tickLower/tickUpper position
  /// @dev Any token0 or token1 owed for the liquidity provision have to be paid for when
  /// the IMintCallback#mintCallback is called to this method's caller
  /// The quantity of token0/token1 to be sent depends on
  /// tickLower, tickUpper, the amount of liquidity, and the current price of the pool.
  /// Also sends reinvestment tokens (fees) to the recipient for any fees collected
  /// while the position is in range
  /// Reinvestment tokens have to be burnt via #burnRTokens in exchange for token0 and token1
  /// @param recipient Address for which the added liquidity is credited to
  /// @param tickLower Recipient position's lower tick
  /// @param tickUpper Recipient position's upper tick
  /// @param ticksPrevious The nearest tick that is initialized and <= the lower & upper ticks
  /// @param qty Liquidity quantity to mint
  /// @param data Data (if any) to be passed through to the callback
  /// @return qty0 token0 quantity sent to the pool in exchange for the minted liquidity
  /// @return qty1 token1 quantity sent to the pool in exchange for the minted liquidity
  /// @return feeGrowthInside position's updated feeGrowthInside value
  function mint(
    address recipient,
    int24 tickLower,
    int24 tickUpper,
    int24[2] calldata ticksPrevious,
    uint128 qty,
    bytes calldata data
  )
    external
    returns (
      uint256 qty0,
      uint256 qty1,
      uint256 feeGrowthInside
    );

  /// @notice Remove liquidity from the caller
  /// Also sends reinvestment tokens (fees) to the caller for any fees collected
  /// while the position is in range
  /// Reinvestment tokens have to be burnt via #burnRTokens in exchange for token0 and token1
  /// @param tickLower Position's lower tick for which to burn liquidity
  /// @param tickUpper Position's upper tick for which to burn liquidity
  /// @param qty Liquidity quantity to burn
  /// @return qty0 token0 quantity sent to the caller
  /// @return qty1 token1 quantity sent to the caller
  /// @return feeGrowthInside position's updated feeGrowthInside value
  function burn(
    int24 tickLower,
    int24 tickUpper,
    uint128 qty
  )
    external
    returns (
      uint256 qty0,
      uint256 qty1,
      uint256 feeGrowthInside
    );

  /// @notice Burns reinvestment tokens in exchange to receive the fees collected in token0 and token1
  /// @param qty Reinvestment token quantity to burn
  /// @param isLogicalBurn true if burning rTokens without returning any token0/token1
  ///         otherwise should transfer token0/token1 to sender
  /// @return qty0 token0 quantity sent to the caller for burnt reinvestment tokens
  /// @return qty1 token1 quantity sent to the caller for burnt reinvestment tokens
  function burnRTokens(uint256 qty, bool isLogicalBurn)
    external
    returns (uint256 qty0, uint256 qty1);

  /// @notice Swap token0 -> token1, or vice versa
  /// @dev This method's caller receives a callback in the form of ISwapCallback#swapCallback
  /// @dev swaps will execute up to limitSqrtP or swapQty is fully used
  /// @param recipient The address to receive the swap output
  /// @param swapQty The swap quantity, which implicitly configures the swap as exact input (>0), or exact output (<0)
  /// @param isToken0 Whether the swapQty is specified in token0 (true) or token1 (false)
  /// @param limitSqrtP the limit of sqrt price after swapping
  /// could be MAX_SQRT_RATIO-1 when swapping 1 -> 0 and MIN_SQRT_RATIO+1 when swapping 0 -> 1 for no limit swap
  /// @param data Any data to be passed through to the callback
  /// @return qty0 Exact token0 qty sent to recipient if < 0. Minimally received quantity if > 0.
  /// @return qty1 Exact token1 qty sent to recipient if < 0. Minimally received quantity if > 0.
  function swap(
    address recipient,
    int256 swapQty,
    bool isToken0,
    uint160 limitSqrtP,
    bytes calldata data
  ) external returns (int256 qty0, int256 qty1);

  /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
  /// @dev The caller of this method receives a callback in the form of IFlashCallback#flashCallback
  /// @dev Fees collected are sent to the feeTo address if it is set in Factory
  /// @param recipient The address which will receive the token0 and token1 quantities
  /// @param qty0 token0 quantity to be loaned to the recipient
  /// @param qty1 token1 quantity to be loaned to the recipient
  /// @param data Any data to be passed through to the callback
  function flash(
    address recipient,
    uint256 qty0,
    uint256 qty1,
    bytes calldata data
  ) external;


  /// @notice sync fee of position
  /// @param tickLower Position's lower tick
  /// @param tickUpper Position's upper tick
  function tweakPosZeroLiq(int24 tickLower, int24 tickUpper)
    external returns(uint256 feeGrowthInsideLast);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IPoolEvents {
  /// @notice Emitted only once per pool when #initialize is first called
  /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
  /// @param sqrtP The initial price of the pool
  /// @param tick The initial tick of the pool
  event Initialize(uint160 sqrtP, int24 tick);

  /// @notice Emitted when liquidity is minted for a given position
  /// @dev transfers reinvestment tokens for any collected fees earned by the position
  /// @param sender address that minted the liquidity
  /// @param owner address of owner of the position
  /// @param tickLower position's lower tick
  /// @param tickUpper position's upper tick
  /// @param qty liquidity minted to the position range
  /// @param qty0 token0 quantity needed to mint the liquidity
  /// @param qty1 token1 quantity needed to mint the liquidity
  event Mint(
    address sender,
    address indexed owner,
    int24 indexed tickLower,
    int24 indexed tickUpper,
    uint128 qty,
    uint256 qty0,
    uint256 qty1
  );

  /// @notice Emitted when a position's liquidity is removed
  /// @dev transfers reinvestment tokens for any collected fees earned by the position
  /// @param owner address of owner of the position
  /// @param tickLower position's lower tick
  /// @param tickUpper position's upper tick
  /// @param qty liquidity removed
  /// @param qty0 token0 quantity withdrawn from removal of liquidity
  /// @param qty1 token1 quantity withdrawn from removal of liquidity
  event Burn(
    address indexed owner,
    int24 indexed tickLower,
    int24 indexed tickUpper,
    uint128 qty,
    uint256 qty0,
    uint256 qty1
  );

  /// @notice Emitted when reinvestment tokens are burnt
  /// @param owner address which burnt the reinvestment tokens
  /// @param qty reinvestment token quantity burnt
  /// @param qty0 token0 quantity sent to owner for burning reinvestment tokens
  /// @param qty1 token1 quantity sent to owner for burning reinvestment tokens
  event BurnRTokens(address indexed owner, uint256 qty, uint256 qty0, uint256 qty1);

  /// @notice Emitted for swaps by the pool between token0 and token1
  /// @param sender Address that initiated the swap call, and that received the callback
  /// @param recipient Address that received the swap output
  /// @param deltaQty0 Change in pool's token0 balance
  /// @param deltaQty1 Change in pool's token1 balance
  /// @param sqrtP Pool's sqrt price after the swap
  /// @param liquidity Pool's liquidity after the swap
  /// @param currentTick Log base 1.0001 of pool's price after the swap
  event Swap(
    address indexed sender,
    address indexed recipient,
    int256 deltaQty0,
    int256 deltaQty1,
    uint160 sqrtP,
    uint128 liquidity,
    int24 currentTick
  );

  /// @notice Emitted by the pool for any flash loans of token0/token1
  /// @param sender The address that initiated the flash loan, and that received the callback
  /// @param recipient The address that received the flash loan quantities
  /// @param qty0 token0 quantity loaned to the recipient
  /// @param qty1 token1 quantity loaned to the recipient
  /// @param paid0 token0 quantity paid for the flash, which can exceed qty0 + fee
  /// @param paid1 token1 quantity paid for the flash, which can exceed qty0 + fee
  event Flash(
    address indexed sender,
    address indexed recipient,
    uint256 qty0,
    uint256 qty1,
    uint256 paid0,
    uint256 paid1
  );
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import {IFactory} from '../IFactory.sol';
import {IPoolOracle} from '../oracle/IPoolOracle.sol';

interface IPoolStorage {
  /// @notice The contract that deployed the pool, which must adhere to the IFactory interface
  /// @return The contract address
  function factory() external view returns (IFactory);

  /// @notice The oracle contract that stores necessary data for price oracle
  /// @return The contract address
  function poolOracle() external view returns (IPoolOracle);

  /// @notice The first of the two tokens of the pool, sorted by address
  /// @return The token contract address
  function token0() external view returns (IERC20);

  /// @notice The second of the two tokens of the pool, sorted by address
  /// @return The token contract address
  function token1() external view returns (IERC20);

  /// @notice The fee to be charged for a swap in basis points
  /// @return The swap fee in basis points
  function swapFeeUnits() external view returns (uint24);

  /// @notice The pool tick distance
  /// @dev Ticks can only be initialized and used at multiples of this value
  /// It remains an int24 to avoid casting even though it is >= 1.
  /// e.g: a tickDistance of 5 means ticks can be initialized every 5th tick, i.e., ..., -10, -5, 0, 5, 10, ...
  /// @return The tick distance
  function tickDistance() external view returns (int24);

  /// @notice Maximum gross liquidity that an initialized tick can have
  /// @dev This is to prevent overflow the pool's active base liquidity (uint128)
  /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
  /// @return The max amount of liquidity per tick
  function maxTickLiquidity() external view returns (uint128);

  /// @notice Look up information about a specific tick in the pool
  /// @param tick The tick to look up
  /// @return liquidityGross total liquidity amount from positions that uses this tick as a lower or upper tick
  /// liquidityNet how much liquidity changes when the pool tick crosses above the tick
  /// feeGrowthOutside the fee growth on the other side of the tick relative to the current tick
  /// secondsPerLiquidityOutside the seconds per unit of liquidity  spent on the other side of the tick relative to the current tick
  function ticks(int24 tick)
    external
    view
    returns (
      uint128 liquidityGross,
      int128 liquidityNet,
      uint256 feeGrowthOutside,
      uint128 secondsPerLiquidityOutside
    );

  /// @notice Returns the previous and next initialized ticks of a specific tick
  /// @dev If specified tick is uninitialized, the returned values are zero.
  /// @param tick The tick to look up
  function initializedTicks(int24 tick) external view returns (int24 previous, int24 next);

  /// @notice Returns the information about a position by the position's key
  /// @return liquidity the liquidity quantity of the position
  /// @return feeGrowthInsideLast fee growth inside the tick range as of the last mint / burn action performed
  function getPositions(
    address owner,
    int24 tickLower,
    int24 tickUpper
  ) external view returns (uint128 liquidity, uint256 feeGrowthInsideLast);

  /// @notice Fetches the pool's prices, ticks and lock status
  /// @return sqrtP sqrt of current price: sqrt(token1/token0)
  /// @return currentTick pool's current tick
  /// @return nearestCurrentTick pool's nearest initialized tick that is <= currentTick
  /// @return locked true if pool is locked, false otherwise
  function getPoolState()
    external
    view
    returns (
      uint160 sqrtP,
      int24 currentTick,
      int24 nearestCurrentTick,
      bool locked
    );

  /// @notice Fetches the pool's liquidity values
  /// @return baseL pool's base liquidity without reinvest liqudity
  /// @return reinvestL the liquidity is reinvested into the pool
  /// @return reinvestLLast last cached value of reinvestL, used for calculating reinvestment token qty
  function getLiquidityState()
    external
    view
    returns (
      uint128 baseL,
      uint128 reinvestL,
      uint128 reinvestLLast
    );

  /// @return feeGrowthGlobal All-time fee growth per unit of liquidity of the pool
  function getFeeGrowthGlobal() external view returns (uint256);

  /// @return secondsPerLiquidityGlobal All-time seconds per unit of liquidity of the pool
  /// @return lastUpdateTime The timestamp in which secondsPerLiquidityGlobal was last updated
  function getSecondsPerLiquidityData()
    external
    view
    returns (uint128 secondsPerLiquidityGlobal, uint32 lastUpdateTime);

  /// @notice Calculates and returns the active time per unit of liquidity until current block.timestamp
  /// @param tickLower The lower tick (of a position)
  /// @param tickUpper The upper tick (of a position)
  /// @return secondsPerLiquidityInside active time (multiplied by 2^96)
  /// between the 2 ticks, per unit of liquidity.
  function getSecondsPerLiquidityInside(int24 tickLower, int24 tickUpper)
    external
    view
    returns (uint128 secondsPerLiquidityInside);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
/// @dev Code has been modified to be compatible with sol 0.8
library FullMath {
  /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
  /// @param a The multiplicand
  /// @param b The multiplier
  /// @param denominator The divisor
  /// @return result The 256-bit result
  /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
  function mulDivFloor(
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
      require(denominator > 0, '0 denom');
      assembly {
        result := div(prod0, denominator)
      }
      return result;
    }

    // Make sure the result is less than 2**256.
    // Also prevents denominator == 0
    require(denominator > prod1, 'denom <= prod1');

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
    uint256 twos = denominator & (~denominator + 1);
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
    unchecked {
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
    }
    return result;
  }

  /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
  /// @param a The multiplicand
  /// @param b The multiplier
  /// @param denominator The divisor
  /// @return result The 256-bit result
  function mulDivCeiling(
    uint256 a,
    uint256 b,
    uint256 denominator
  ) internal pure returns (uint256 result) {
    result = mulDivFloor(a, b, denominator);
    if (mulmod(a, b, denominator) > 0) {
      result++;
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Contains constants needed for math libraries
library MathConstants {
  uint256 internal constant TWO_FEE_UNITS = 200_000;
  uint256 internal constant TWO_POW_96 = 2 ** 96;
  uint128 internal constant MIN_LIQUIDITY = 100;
  uint8 internal constant RES_96 = 96;
  uint24 internal constant FEE_UNITS = 100000;
  // it is strictly less than 5% price movement if jumping MAX_TICK_DISTANCE ticks
  int24 internal constant MAX_TICK_DISTANCE = 480;
  // max number of tick travel when inserting if data changes
  uint256 internal constant MAX_TICK_TRAVEL = 10;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {MathConstants as C} from './MathConstants.sol';
import {TickMath} from './TickMath.sol';
import {FullMath} from './FullMath.sol';
import {SafeCast} from './SafeCast.sol';

/// @title Contains helper functions for calculating
/// token0 and token1 quantites from differences in prices
/// or from burning reinvestment tokens
library QtyDeltaMath {
  using SafeCast for uint256;
  using SafeCast for int128;

  function calcUnlockQtys(uint160 initialSqrtP)
    internal
    pure
    returns (uint256 qty0, uint256 qty1)
  {
    qty0 = FullMath.mulDivCeiling(C.MIN_LIQUIDITY, C.TWO_POW_96, initialSqrtP);
    qty1 = FullMath.mulDivCeiling(C.MIN_LIQUIDITY, initialSqrtP, C.TWO_POW_96);
  }

  /// @notice Gets the qty0 delta between two prices
  /// @dev Calculates liquidity / sqrt(lower) - liquidity / sqrt(upper),
  /// i.e. liquidity * (sqrt(upper) - sqrt(lower)) / (sqrt(upper) * sqrt(lower))
  /// rounds up if adding liquidity, rounds down if removing liquidity
  /// @param lowerSqrtP The lower sqrt price.
  /// @param upperSqrtP The upper sqrt price. Should be >= lowerSqrtP
  /// @param liquidity Liquidity quantity
  /// @param isAddLiquidity true = add liquidity, false = remove liquidity
  /// @return token0 qty required for position with liquidity between the 2 sqrt prices
  function calcRequiredQty0(
    uint160 lowerSqrtP,
    uint160 upperSqrtP,
    uint128 liquidity,
    bool isAddLiquidity
  ) internal pure returns (int256) {
    uint256 numerator1 = uint256(liquidity) << C.RES_96;
    uint256 numerator2;
    unchecked {
      numerator2 = upperSqrtP - lowerSqrtP;
    }
    return
      isAddLiquidity
        ? (divCeiling(FullMath.mulDivCeiling(numerator1, numerator2, upperSqrtP), lowerSqrtP))
          .toInt256()
        : (FullMath.mulDivFloor(numerator1, numerator2, upperSqrtP) / lowerSqrtP).revToInt256();
  }

  /// @notice Gets the token1 delta quantity between two prices
  /// @dev Calculates liquidity * (sqrt(upper) - sqrt(lower))
  /// rounds up if adding liquidity, rounds down if removing liquidity
  /// @param lowerSqrtP The lower sqrt price.
  /// @param upperSqrtP The upper sqrt price. Should be >= lowerSqrtP
  /// @param liquidity Liquidity quantity
  /// @param isAddLiquidity true = add liquidity, false = remove liquidity
  /// @return token1 qty required for position with liquidity between the 2 sqrt prices
  function calcRequiredQty1(
    uint160 lowerSqrtP,
    uint160 upperSqrtP,
    uint128 liquidity,
    bool isAddLiquidity
  ) internal pure returns (int256) {
    unchecked {
      return
        isAddLiquidity
          ? (FullMath.mulDivCeiling(liquidity, upperSqrtP - lowerSqrtP, C.TWO_POW_96)).toInt256()
          : (FullMath.mulDivFloor(liquidity, upperSqrtP - lowerSqrtP, C.TWO_POW_96)).revToInt256();
    }
  }

  /// @notice Calculates the token0 quantity proportion to be sent to the user
  /// for burning reinvestment tokens
  /// @param sqrtP Current pool sqrt price
  /// @param liquidity Difference in reinvestment liquidity due to reinvestment token burn
  /// @return token0 quantity to be sent to the user
  function getQty0FromBurnRTokens(uint160 sqrtP, uint256 liquidity)
    internal
    pure
    returns (uint256)
  {
    return FullMath.mulDivFloor(liquidity, C.TWO_POW_96, sqrtP);
  }

  /// @notice Calculates the token1 quantity proportion to be sent to the user
  /// for burning reinvestment tokens
  /// @param sqrtP Current pool sqrt price
  /// @param liquidity Difference in reinvestment liquidity due to reinvestment token burn
  /// @return token1 quantity to be sent to the user
  function getQty1FromBurnRTokens(uint160 sqrtP, uint256 liquidity)
    internal
    pure
    returns (uint256)
  {
    return FullMath.mulDivFloor(liquidity, sqrtP, C.TWO_POW_96);
  }

  /// @notice Returns ceil(x / y)
  /// @dev division by 0 has unspecified behavior, and must be checked externally
  /// @param x The dividend
  /// @param y The divisor
  /// @return z The quotient, ceil(x / y)
  function divCeiling(uint256 x, uint256 y) internal pure returns (uint256 z) {
    // return x / y + ((x % y == 0) ? 0 : 1);
    require(y > 0);
    assembly {
      z := add(div(x, y), gt(mod(x, y), 0))
    }
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

/// @title Safe casting methods
/// @notice Contains methods for safely casting between types
library SafeCast {
  /// @notice Cast a uint256 to uint32, revert on overflow
  /// @param y The uint256 to be downcasted
  /// @return z The downcasted integer, now type uint32
  function toUint32(uint256 y) internal pure returns (uint32 z) {
    require((z = uint32(y)) == y);
  }

  /// @notice Cast a uint128 to a int128, revert on overflow
  /// @param y The uint256 to be casted
  /// @return z The casted integer, now type int256
  function toInt128(uint128 y) internal pure returns (int128 z) {
    require(y < 2**127);
    z = int128(y);
  }

  /// @notice Cast a uint256 to a uint128, revert on overflow
  /// @param y the uint256 to be downcasted
  /// @return z The downcasted integer, now type uint128
  function toUint128(uint256 y) internal pure returns (uint128 z) {
    require((z = uint128(y)) == y);
  }

  /// @notice Cast a int128 to a uint128 and reverses the sign.
  /// @param y The int128 to be casted
  /// @return z = -y, now type uint128
  function revToUint128(int128 y) internal pure returns (uint128 z) {
    unchecked {
      return type(uint128).max - uint128(y) + 1;
    }
  }

  /// @notice Cast a uint256 to a uint160, revert on overflow
  /// @param y The uint256 to be downcasted
  /// @return z The downcasted integer, now type uint160
  function toUint160(uint256 y) internal pure returns (uint160 z) {
    require((z = uint160(y)) == y);
  }

  /// @notice Cast a uint256 to a int256, revert on overflow
  /// @param y The uint256 to be casted
  /// @return z The casted integer, now type int256
  function toInt256(uint256 y) internal pure returns (int256 z) {
    require(y < 2**255);
    z = int256(y);
  }

  /// @notice Cast a uint256 to a int256 and reverses the sign, revert on overflow
  /// @param y The uint256 to be casted
  /// @return z = -y, now type int256
  function revToInt256(uint256 y) internal pure returns (int256 z) {
    require(y < 2**255);
    z = -int256(y);
  }

  /// @notice Cast a int256 to a uint256 and reverses the sign.
  /// @param y The int256 to be casted
  /// @return z = -y, now type uint256
  function revToUint256(int256 y) internal pure returns (uint256 z) {
    unchecked {
      return type(uint256).max - uint256(y) + 1;
    }
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
  /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
  int24 internal constant MIN_TICK = -887272;
  /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
  int24 internal constant MAX_TICK = -MIN_TICK;

  /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
  uint160 internal constant MIN_SQRT_RATIO = 4295128739;
  /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
  uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

  /// @notice Calculates sqrt(1.0001^tick) * 2^96
  /// @dev Throws if |tick| > max tick
  /// @param tick The input tick for the above formula
  /// @return sqrtP A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
  /// at the given tick
  function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtP) {
    unchecked {
      uint256 absTick = uint256(tick < 0 ? -int256(tick) : int256(tick));
      require(absTick <= uint256(int256(MAX_TICK)), 'T');

      // do bitwise comparison, if i-th bit is turned on,
      // multiply ratio by hardcoded values of sqrt(1.0001^-(2^i)) * 2^128
      // where 0 <= i <= 19
      uint256 ratio = (absTick & 0x1 != 0)
        ? 0xfffcb933bd6fad37aa2d162d1a594001
        : 0x100000000000000000000000000000000;
      if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
      if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
      if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
      if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
      if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
      if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
      if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
      if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
      if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
      if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
      if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
      if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
      if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
      if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
      if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
      if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
      if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
      if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
      if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

      // take reciprocal for positive tick values
      if (tick > 0) ratio = type(uint256).max / ratio;

      // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
      // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
      // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
      sqrtP = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
    }
  }

  /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
  /// @dev Throws in case sqrtP < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
  /// ever return.
  /// @param sqrtP The sqrt ratio for which to compute the tick as a Q64.96
  /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
  function getTickAtSqrtRatio(uint160 sqrtP) internal pure returns (int24 tick) {
    // second inequality must be < because the price can never reach the price at the max tick
    require(sqrtP >= MIN_SQRT_RATIO && sqrtP < MAX_SQRT_RATIO, 'R');
    uint256 ratio = uint256(sqrtP) << 32;

    uint256 r = ratio;
    uint256 msb = 0;

    unchecked {
      assembly {
        let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
        msb := or(msb, f)
        r := shr(f, r)
      }
      assembly {
        let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
        msb := or(msb, f)
        r := shr(f, r)
      }
      assembly {
        let f := shl(5, gt(r, 0xFFFFFFFF))
        msb := or(msb, f)
        r := shr(f, r)
      }
      assembly {
        let f := shl(4, gt(r, 0xFFFF))
        msb := or(msb, f)
        r := shr(f, r)
      }
      assembly {
        let f := shl(3, gt(r, 0xFF))
        msb := or(msb, f)
        r := shr(f, r)
      }
      assembly {
        let f := shl(2, gt(r, 0xF))
        msb := or(msb, f)
        r := shr(f, r)
      }
      assembly {
        let f := shl(1, gt(r, 0x3))
        msb := or(msb, f)
        r := shr(f, r)
      }
      assembly {
        let f := gt(r, 0x1)
        msb := or(msb, f)
      }

      if (msb >= 128) r = ratio >> (msb - 127);
      else r = ratio << (127 - msb);

      int256 log_2 = (int256(msb) - 128) << 64;

      assembly {
        r := shr(127, mul(r, r))
        let f := shr(128, r)
        log_2 := or(log_2, shl(63, f))
        r := shr(f, r)
      }
      assembly {
        r := shr(127, mul(r, r))
        let f := shr(128, r)
        log_2 := or(log_2, shl(62, f))
        r := shr(f, r)
      }
      assembly {
        r := shr(127, mul(r, r))
        let f := shr(128, r)
        log_2 := or(log_2, shl(61, f))
        r := shr(f, r)
      }
      assembly {
        r := shr(127, mul(r, r))
        let f := shr(128, r)
        log_2 := or(log_2, shl(60, f))
        r := shr(f, r)
      }
      assembly {
        r := shr(127, mul(r, r))
        let f := shr(128, r)
        log_2 := or(log_2, shl(59, f))
        r := shr(f, r)
      }
      assembly {
        r := shr(127, mul(r, r))
        let f := shr(128, r)
        log_2 := or(log_2, shl(58, f))
        r := shr(f, r)
      }
      assembly {
        r := shr(127, mul(r, r))
        let f := shr(128, r)
        log_2 := or(log_2, shl(57, f))
        r := shr(f, r)
      }
      assembly {
        r := shr(127, mul(r, r))
        let f := shr(128, r)
        log_2 := or(log_2, shl(56, f))
        r := shr(f, r)
      }
      assembly {
        r := shr(127, mul(r, r))
        let f := shr(128, r)
        log_2 := or(log_2, shl(55, f))
        r := shr(f, r)
      }
      assembly {
        r := shr(127, mul(r, r))
        let f := shr(128, r)
        log_2 := or(log_2, shl(54, f))
        r := shr(f, r)
      }
      assembly {
        r := shr(127, mul(r, r))
        let f := shr(128, r)
        log_2 := or(log_2, shl(53, f))
        r := shr(f, r)
      }
      assembly {
        r := shr(127, mul(r, r))
        let f := shr(128, r)
        log_2 := or(log_2, shl(52, f))
        r := shr(f, r)
      }
      assembly {
        r := shr(127, mul(r, r))
        let f := shr(128, r)
        log_2 := or(log_2, shl(51, f))
        r := shr(f, r)
      }
      assembly {
        r := shr(127, mul(r, r))
        let f := shr(128, r)
        log_2 := or(log_2, shl(50, f))
      }

      int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

      int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
      int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

      tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtP ? tickHi : tickLow;
    }
  }

  function getMaxNumberTicks(int24 _tickDistance) internal pure returns (uint24 numTicks) {
    return uint24(TickMath.MAX_TICK / _tickDistance) * 2;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {MathConstants as C} from '../../libraries/MathConstants.sol';
import {FullMath} from '../../libraries/FullMath.sol';
import {SafeCast} from '../../libraries/SafeCast.sol';

library LiquidityMath {
  using SafeCast for uint256;

  /// @notice Gets liquidity from qty 0 and the price range
  /// qty0 = liquidity * (sqrt(upper) - sqrt(lower)) / (sqrt(upper) * sqrt(lower))
  /// => liquidity = qty0 * (sqrt(upper) * sqrt(lower)) / (sqrt(upper) - sqrt(lower))
  /// @param lowerSqrtP A lower sqrt price
  /// @param upperSqrtP An upper sqrt price
  /// @param qty0 amount of token0
  /// @return liquidity amount of returned liquidity to not exceed the qty0
  function getLiquidityFromQty0(
    uint160 lowerSqrtP,
    uint160 upperSqrtP,
    uint256 qty0
  ) internal pure returns (uint128) {
    uint256 liq = FullMath.mulDivFloor(lowerSqrtP, upperSqrtP, C.TWO_POW_96);
    unchecked {
      return FullMath.mulDivFloor(liq, qty0, upperSqrtP - lowerSqrtP).toUint128();
    }
  }

  /// @notice Gets liquidity from qty 1 and the price range
  /// @dev qty1 = liquidity * (sqrt(upper) - sqrt(lower))
  ///   thus, liquidity = qty1 / (sqrt(upper) - sqrt(lower))
  /// @param lowerSqrtP A lower sqrt price
  /// @param upperSqrtP An upper sqrt price
  /// @param qty1 amount of token1
  /// @return liquidity amount of returned liquidity to not exceed to qty1
  function getLiquidityFromQty1(
    uint160 lowerSqrtP,
    uint160 upperSqrtP,
    uint256 qty1
  ) internal pure returns (uint128) {
    unchecked {
      return FullMath.mulDivFloor(qty1, C.TWO_POW_96, upperSqrtP - lowerSqrtP).toUint128();
    }
  }

  /// @notice Gets liquidity given price range and 2 qties of token0 and token1
  /// @param currentSqrtP current price
  /// @param lowerSqrtP A lower sqrt price
  /// @param upperSqrtP An upper sqrt price
  /// @param qty0 amount of token0 - at most
  /// @param qty1 amount of token1 - at most
  /// @return liquidity amount of returned liquidity to not exceed the given qties
  function getLiquidityFromQties(
    uint160 currentSqrtP,
    uint160 lowerSqrtP,
    uint160 upperSqrtP,
    uint256 qty0,
    uint256 qty1
  ) internal pure returns (uint128) {
    if (currentSqrtP <= lowerSqrtP) {
      return getLiquidityFromQty0(lowerSqrtP, upperSqrtP, qty0);
    }
    if (currentSqrtP >= upperSqrtP) {
      return getLiquidityFromQty1(lowerSqrtP, upperSqrtP, qty1);
    }
    uint128 liq0 = getLiquidityFromQty0(currentSqrtP, upperSqrtP, qty0);
    uint128 liq1 = getLiquidityFromQty1(lowerSqrtP, currentSqrtP, qty1);
    return liq0 < liq1 ? liq0 : liq1;
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "../../../BaseSiloAction.sol";

import "./elastic/interfaces/periphery/IAntiSnipAttackPositionManager.sol";

import {ITicksFeesReader} from "./elastic/interfaces/periphery/ITicksFeesReader.sol";

import {TickMath} from "./elastic/libraries/TickMath.sol";

import {LiquidityMath} from "./elastic/periphery/libraries/LiquidityMath.sol";
import {QtyDeltaMath} from "./elastic/libraries/QtyDeltaMath.sol";

import {IPool} from "./elastic/interfaces/IPool.sol";

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../../../../../DeFi/uniswapv2/interfaces/IUniswapV2Pair.sol";
import "../../../../../DeFi/uniswapv2/interfaces/IUniswapV2Router02.sol";

import {SafeCast} from "./elastic/libraries/SafeCast.sol";

import {IKyberSwapElasticLM} from "./lm/interfaces/IKyberSwapElasticLM.sol";

import {IKSElasticLMHelper} from "./lm/interfaces/IKSElasticLMHelper.sol";

import "../../QuickMai/V3Router/interfaces/ISwapRouter.sol";

// import "hardhat/console.sol";

/*
Note: Used in between two mai vault actions, will take mai, and join mai stable farm
                        Curve Stable Farm Loan IO
                             ______________
                    Mai In->[              ]->Unused amount will be zero
            Reward Token A->[              ]->Reward Token A
            Reward Token B->[              ]->Reward Token B (if applicable)
         Mai out requested->[______________]->Mai out

Note: Top Mai in is Mai going into the farm
Note: Bottom Mai out, is Mai that is requested by the  preceding Mai Vault action

*/

struct ProtocolHelper {
    IUniswapV2Router02 quickRouter;
    IAntiSnipAttackPositionManager positionManager;
    IKyberSwapElasticLM elasticLM;
    IKSElasticLMHelper elasticLMHelper;
    IPool pool;
    IERC20 USDC;
    IERC20 USDT;
    IERC20 MAI;
    IUniswapV2Pair qsLP;
}

contract KyberLpFarm is BaseSiloAction {
    using SafeCast for uint256;
    using SafeCast for int256;

    address private constant KYBER_POSITION_MANAGER =
        0xe222fBE074A436145b255442D919E4E3A6c6a480;

    address private constant TICKER_READER_ADDRESS =
        0x8Fd8Cb948965d9305999D767A02bf79833EADbB3;

    address private constant KS_ELASTIC_LM =
        0x7D5ba536ab244aAA1EA42aB88428847F25E3E676;

    address private constant KS_ELASTIC_LM_HELPER =
        0x35BE3F4fd8239A35a7F120756D4D69e5C5e10870;

    address private constant QS_V2_ROUTER =
        0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;

    address private constant QS_V3_QUOTER =
        0xa15F0D7377B2A0C0c10db057f641beD21028FC89;

    address private constant QS_V3_ROUTER =
        0xf5b509bB0909a69B1c207E495f687a596C168E12;

    address private constant MAI_ADDRESS =
        0xa3Fa99A148fA48D14Ed51d610c367C61876997F1;

    address private constant USDC_ADDRESS =
        0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;

    address private constant USDT_ADDRESS =
        0xc2132D05D31c914a87C6611C10748AEb04B58e8F;

    address private constant QS_V2_USDC_USDT_ADDRESS =
        0x2cF7252e74036d1Da831d11089D326296e64a728;

    address private constant QS_ALGEBRA_USDC_USDT_POOL =
        0x7B925e617aefd7FB3a93Abe3a701135D7a1Ba710;

    address private constant KNC_ADDRESS =
        0x1C954E8fe737F99f68Fa1CCda3e51ebDB291948C;

    address private constant KS_USDC_USDT_POOL =
        0x879664ce5A919727b3Ed4035Cf12F7F740E8dF00;

    uint256 private constant MAX_UINT256 = 2 ** 256 - 1;

    constructor(string memory _name, address _siloFactory) {
        name = _name;
        metaData = "address[5],address[5],uint256";
        factory = _siloFactory;
        usesTakeFee = true;
        feeName = "Kyber Harvests";
    }

    function _act(
        address implementation,
        bytes memory configuration,
        bytes memory inputData
    ) internal returns (uint256[5] memory outputAmounts) {
        ProtocolHelper memory protocol = ProtocolHelper({
            positionManager: IAntiSnipAttackPositionManager(
                KYBER_POSITION_MANAGER
            ),
            elasticLM: IKyberSwapElasticLM(KS_ELASTIC_LM),
            elasticLMHelper: IKSElasticLMHelper(KS_ELASTIC_LM_HELPER),
            quickRouter: IUniswapV2Router02(QS_V2_ROUTER),
            USDC: IERC20(USDC_ADDRESS),
            USDT: IERC20(USDT_ADDRESS),
            MAI: IERC20(MAI_ADDRESS),
            pool: IPool(KS_USDC_USDT_POOL),
            qsLP: IUniswapV2Pair(QS_V2_USDC_USDT_ADDRESS)
        });

        uint256[5] memory inputAmounts = abi.decode(inputData, (uint256[5]));

        uint256 nftId = getStakedNFT(address(this));

        outputAmounts[2] = inputAmounts[2];

        // {
        //     uint256[] memory listNFTs = protocol.elasticLM.getDepositedNFTs(
        //         address(this)
        //     );

        //     if (listNFTs.length > 0) {
        //         nftId = listNFTs[listNFTs.length - 1];
        //     }
        // }

        uint256 pid = getCurrentPid(address(this));

        // console.log(
        //     "pid  :%s   nftId:%s  inputAmounts[0]:%s",
        //     pid,
        //     nftId,
        //     inputAmounts[0]
        // );

        if (pid == 0 && nftId > 0) {
            // current farm pool is ended
            (IBasePositionManager.Position memory pos, ) = protocol
                .positionManager
                .positions(nftId);

            exitFarming(nftId, pid, pos.liquidity, protocol);
            return outputAmounts;
        }

        uint256 positionNFT = getPositionNFT(address(this));

        if (pid > 0 && positionNFT > 0 && nftId == 0) {
            // farm pool is renewed
            (IBasePositionManager.Position memory pos, ) = protocol
                .positionManager
                .positions(positionNFT);
            enterFarming(positionNFT, pid, pos.liquidity, protocol);

            return outputAmounts;
        }

        if (pid == 0) {
            return outputAmounts;
        }

        if (inputAmounts[0] == 0 && inputAmounts[4] == 0 && nftId != 0) {
            (, uint256[] memory rewardPending, ) = protocol
                .elasticLM
                .getUserInfo(nftId, pid);

            if (rewardPending.length > 0 && rewardPending[0] > 0) {
                harvest(nftId, pid, protocol);

                // console.log("rewardPending :%s", rewardPending[0]);

                outputAmounts[1] = _takeFee(
                    implementation,
                    rewardPending[0],
                    KNC_ADDRESS
                );
            }

            // //just harvest rewards
        } else {
            {
                uint256 balance = protocol.MAI.balanceOf(address(this));
                inputAmounts[0] = inputAmounts[0] > balance
                    ? balance
                    : inputAmounts[0];
            }

            if (inputAmounts[0] > 0) {
                (int24 tickLower, int24 tickUpper) = getTickLowerAndUpper(
                    nftId,
                    protocol
                );

                uint256[2] memory amounts;
                {
                    uint256 usdc_swap = inputAmounts[0] / 2;
                    uint256 usdt_swap = inputAmounts[0] - usdc_swap;

                    amounts[0] = _swapTokens(
                        MAI_ADDRESS,
                        USDC_ADDRESS,
                        inputAmounts[0] / 2,
                        QS_V3_ROUTER
                    );

                    amounts[1] = _swapTokens(
                        MAI_ADDRESS,
                        USDT_ADDRESS,
                        usdt_swap,
                        QS_V3_ROUTER
                    );

                    // console.log(
                    //     "amounts[0] :%s amounts[1]:%s",
                    //     amounts[0],
                    //     amounts[1]
                    // );
                }

                if (nftId == 0) {
                    stakeKyberElastic(
                        amounts[0],
                        amounts[1],
                        pid,
                        tickLower,
                        tickUpper,
                        protocol
                    );
                } else {
                    SafeERC20.safeIncreaseAllowance(
                        protocol.USDC,
                        KYBER_POSITION_MANAGER,
                        amounts[0]
                    );

                    SafeERC20.safeIncreaseAllowance(
                        protocol.USDT,
                        KYBER_POSITION_MANAGER,
                        amounts[1]
                    );

                    int24[2] memory ticksPrevious = getPreviousTicks(
                        tickLower,
                        tickUpper
                    ); // [prevLower, prevUpper];

                    (uint128 liquidity, , , ) = protocol
                        .positionManager
                        .addLiquidity(
                            IBasePositionManager.IncreaseLiquidityParams({
                                tokenId: nftId,
                                ticksPrevious: ticksPrevious,
                                amount0Desired: amounts[0],
                                amount1Desired: amounts[1],
                                amount0Min: 0,
                                amount1Min: 0,
                                deadline: block.timestamp + 60
                            })
                        );

                    // console.log("add liquidity: liquidity:%s", liquidity);

                    syncFarm(nftId, pid, liquidity, protocol);
                }
            } else if (inputAmounts[4] > 0) {
                if (nftId != 0) {
                    uint256 knc = IERC20(KNC_ADDRESS).balanceOf(address(this));

                    (IBasePositionManager.Position memory pos, ) = protocol
                        .positionManager
                        .positions(nftId);

                    uint128 removeLiquidity;

                    if (inputAmounts[4] == MAX_UINT256) {
                        //want to remove entire stake
                        removeLiquidity = pos.liquidity;
                    } else {
                        //want to remove some of the stake

                        removeLiquidity = getRemoveLiquidty(
                            inputAmounts[4],
                            nftId,
                            protocol
                        );

                        // console.log(
                        //     "removeLiquidity :%s  inputAmounts[4]:%s",
                        //     removeLiquidity,
                        //     inputAmounts[4]
                        // );

                        removeLiquidity = removeLiquidity > pos.liquidity
                            ? pos.liquidity
                            : removeLiquidity;
                    }
                    bool complete = removeLiquidity == pos.liquidity;

                    if (removeLiquidity > 0) {
                        exitFarming(nftId, pid, pos.liquidity, protocol);

                        knc =
                            IERC20(KNC_ADDRESS).balanceOf(address(this)) -
                            knc;

                        if (knc > 0) {
                            outputAmounts[1] = _takeFee(
                                implementation,
                                knc,
                                KNC_ADDRESS
                            );
                        }

                        // console.log("knc reward:%s complete:%s", knc, complete);

                        (
                            uint256 amount0,
                            uint256 amount1,

                        ) = _removeLiquidityPosition(
                                nftId,
                                removeLiquidity,
                                complete,
                                protocol
                            );

                        // console.log(
                        //     "_removeLiquidityPosition: amount0:%s  amount1:%s",
                        //     amount0,
                        //     amount1
                        // );

                        outputAmounts[4] = convertSingleAsset(amount0, amount1);

                        // console.log(
                        //     "convertSingleAsset total:%s",
                        //     outputAmounts[4]
                        // );

                        if (!complete) {
                            enterFarming(
                                nftId,
                                pid,
                                pos.liquidity - removeLiquidity,
                                protocol
                            );
                        }
                    }
                }
            }
        }
    }

    function getPositionNFT(address silo) private view returns (uint256 nftId) {
        if (IERC721Enumerable(KYBER_POSITION_MANAGER).balanceOf(silo) > 0) {
            nftId = IERC721Enumerable(KYBER_POSITION_MANAGER)
                .tokenOfOwnerByIndex(silo, 0);
        }
    }

    function seekPid(uint256 start) private view returns (uint256 pid) {
        uint256 index;

        address poolAddress;
        uint32 startTime;
        uint32 endTime;
        uint256 poolLength = IKyberSwapElasticLM(KS_ELASTIC_LM).poolLength();
        for (index = start; index < poolLength - 1; ) {
            (poolAddress, startTime, endTime, , , , , ) = IKyberSwapElasticLM(
                KS_ELASTIC_LM
            ).getPoolInfo(index);

            if (
                poolAddress == KS_USDC_USDT_POOL &&
                block.timestamp > startTime &&
                block.timestamp < endTime
            ) {
                return index;
            }

            unchecked {
                index++;
            }
        }
    }

    function getCurrentPid(address silo) private view returns (uint256 pid) {
        // uint256 index;

        uint256 lastPid = ISilo(silo).lastPid();

        // console.log("getCurrentPid lastPid:", lastPid);

        if (lastPid == 0) {
            lastPid = 5;
        }

        pid = seekPid(lastPid);
    }

    function _swapTokens(
        address sellToken,
        address buyToken,
        uint256 tokenInAmount,
        address v3Router
    ) private returns (uint256 tokenOutAmount) {
        if (tokenInAmount == 0) return 0;

        SafeERC20.safeIncreaseAllowance(
            IERC20(sellToken),
            v3Router,
            tokenInAmount
        );

        tokenOutAmount = ISwapRouter(v3Router).exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: sellToken,
                tokenOut: buyToken,
                recipient: address(this),
                deadline: block.timestamp + 60,
                amountIn: tokenInAmount,
                amountOutMinimum: 0,
                limitSqrtPrice: 0
            })
        );
    }

    function stakeKyberElastic(
        uint256 input0,
        uint256 input1,
        uint256 pid,
        int24 tickLower,
        int24 tickUpper,
        ProtocolHelper memory protocol
    )
        private
        returns (
            uint256 nftId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
        SafeERC20.safeIncreaseAllowance(
            protocol.USDC,
            KYBER_POSITION_MANAGER,
            input0
        );

        SafeERC20.safeIncreaseAllowance(
            protocol.USDT,
            KYBER_POSITION_MANAGER,
            input1
        );

        int24[2] memory ticksPrevious = getPreviousTicks(tickLower, tickUpper); // [prevLower, prevUpper];

        // console.log(
        //     "stakeKyberElastic pid:%s input0:%s :input1:%s",
        //     pid,
        //     input0,
        //     input1
        // );

        // console.logInt(int256(tickLower));
        // console.logInt(int256(tickUpper));

        // console.logInt(int256(ticksPrevious[0]));
        // console.logInt(int256(ticksPrevious[1]));

        // try
        //     protocol.positionManager.mint(
        //         IBasePositionManager.MintParams({
        //             token0: USDC_ADDRESS,
        //             token1: USDT_ADDRESS,
        //             fee: 8,
        //             tickLower: tickLower,
        //             tickUpper: tickUpper,
        //             ticksPrevious: ticksPrevious,
        //             amount0Desired: input0,
        //             amount1Desired: input1,
        //             amount0Min: 0,
        //             amount1Min: 0,
        //             recipient: address(this),
        //             deadline: block.timestamp + 60
        //         })
        //     )
        // returns (
        //     uint256 nftId1,
        //     uint128 liquidity1,
        //     uint256 amount01,
        //     uint256 amount11
        // ) {
        //     nftId = nftId1;
        //     liquidity = liquidity1;
        //     amount0 = amount01;
        //     amount1 = amount11;
        // } catch (bytes memory err) {
        //     console.log("mint issue:", string(err));
        //     console.logBytes(err);
        // }

        (nftId, liquidity, amount0, amount1) = protocol.positionManager.mint(
            IBasePositionManager.MintParams({
                token0: USDC_ADDRESS,
                token1: USDT_ADDRESS,
                fee: 8,
                tickLower: tickLower,
                tickUpper: tickUpper,
                ticksPrevious: ticksPrevious,
                amount0Desired: input0,
                amount1Desired: input1,
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),
                deadline: block.timestamp + 60
            })
        );

        // console.log(
        //     "stakeKyberElastic nftId:%s liquidity:%s  amount0:%s",
        //     nftId,
        //     liquidity,
        //     amount0
        // );

        IERC721Enumerable(KYBER_POSITION_MANAGER).setApprovalForAll(
            KS_ELASTIC_LM,
            true
        );

        enterFarming(nftId, pid, liquidity, protocol);
    }

    function getLiquidityParam(
        uint256 nftId,
        uint256 liquidity
    ) private pure returns (uint256[] memory nftIds, uint256[] memory liqs) {
        nftIds = new uint256[](1);
        nftIds[0] = nftId;

        liqs = new uint256[](1);
        liqs[0] = liquidity;
    }

    function exitFarming(
        uint256 nftId,
        uint256 pid,
        uint256 liquidity,
        ProtocolHelper memory protocol
    ) private {
        // uint256[] memory nftIds = new uint256[](1);
        // nftIds[0] = nftId;

        // uint256[] memory liqs = new uint256[](1);
        // liqs[0] = liquidity;

        // console.log(
        //     "exitFarming: nftId:%s  pid:%s  liquidity:%s",
        //     nftId,
        //     pid,
        //     liquidity
        // );

        if (liquidity > 0) {
            (
                uint256[] memory nftIds,
                uint256[] memory liqs
            ) = getLiquidityParam(nftId, liquidity);

            protocol.elasticLM.exit(pid, nftIds, liqs);

            protocol.elasticLM.withdraw(nftIds);
        }
    }

    function harvest(
        uint256 nftId,
        uint256 pid,
        ProtocolHelper memory protocol
    ) private {
        uint256[] memory nftIds = new uint256[](1);
        nftIds[0] = nftId;

        uint256[] memory pids = new uint256[](1);
        pids[0] = pid;

        // (uint256[] memory nftIds, uint256[] memory liqs) = getLiquidityParam(
        //     nftId,
        //     liquidity
        // );

        IKyberSwapElasticLM.HarvestData memory temp = IKyberSwapElasticLM
            .HarvestData({pIds: pids});

        bytes memory data = abi.encode(temp);
        bytes[] memory datas = new bytes[](1);
        datas[0] = data;

        protocol.elasticLM.harvestMultiplePools(nftIds, datas);
    }

    function enterFarming(
        uint256 nftId,
        uint256 pid,
        uint256 liquidity,
        ProtocolHelper memory protocol
    ) private {
        // (IBasePositionManager.Position memory pos, ) = protocol
        //     .positionManager
        //     .positions(nftId);
        // // enterFarming(positionNFT, pid, pos.liquidity, protocol);
        // liquidity = pos.liquidity;

        // uint256[] memory nftIds = new uint256[](1);
        // nftIds[0] = nftId;

        // uint256[] memory liqs = new uint256[](1);
        // liqs[0] = liquidity;

        // console.log("enterFarming nftId:%s liquidity:%s", nftId, liquidity);

        if (liquidity > 0) {
            (
                uint256[] memory nftIds,
                uint256[] memory liqs
            ) = getLiquidityParam(nftId, liquidity);

            protocol.elasticLM.deposit(nftIds);
            protocol.elasticLM.join(pid, nftIds, liqs);
        }
    }

    function syncFarm(
        uint256 nftId,
        uint256 pid,
        uint256 liquidity,
        ProtocolHelper memory protocol
    ) private {
        // uint256[] memory nftIds = new uint256[](1);
        // nftIds[0] = nftId;

        // uint256[] memory liqs = new uint256[](1);
        // liqs[0] = liquidity;

        if (liquidity > 0) {
            (
                uint256[] memory nftIds,
                uint256[] memory liqs
            ) = getLiquidityParam(nftId, liquidity);

            protocol.elasticLM.join(pid, nftIds, liqs);

            // console.log("syncFarm liquidity:%s", liquidity);
        }
    }

    function convertSingleAsset(
        uint256 amount0,
        uint256 amount1
    ) private returns (uint256 output) {
        uint256 balance0 = IERC20(USDC_ADDRESS).balanceOf(address(this));

        // uint256 balance1 = IERC20(USDT_ADDRESS).balanceOf(address(this));

        amount0 = amount0 > balance0 ? balance0 : amount0;

        if (amount0 > 0) {
            output = _swapTokens(
                USDC_ADDRESS,
                MAI_ADDRESS,
                amount0,
                QS_V3_ROUTER
            );

            output += _swapTokens(
                USDT_ADDRESS,
                MAI_ADDRESS,
                amount1,
                QS_V3_ROUTER
            );

            // address[] memory path = new address[](2);
            // path[0] = USDC_ADDRESS;
            // path[1] = USDT_ADDRESS;

            // SafeERC20.safeIncreaseAllowance(
            //     IERC20(USDC_ADDRESS),
            //     QS_V2_ROUTER,
            //     amount0
            // );

            // uint256[] memory amounts = IUniswapV2Router02(QS_V2_ROUTER)
            //     .swapExactTokensForTokens(
            //         amount0,
            //         0,
            //         path,
            //         address(this),
            //         block.timestamp + 60
            //     );

            // output = balance1 + amounts[1];
        }
    }

    function _removeLiquidityPosition(
        uint256 nftId,
        uint128 liquidity,
        bool complete,
        ProtocolHelper memory protocol
    )
        private
        returns (uint256 amount0, uint256 amount1, uint256 additionalRTokenOwed)
    {
        if (nftId != 0) {
            (amount0, amount1, additionalRTokenOwed) = protocol
                .positionManager
                .removeLiquidity(
                    IBasePositionManager.RemoveLiquidityParams({
                        tokenId: nftId,
                        liquidity: liquidity,
                        amount0Min: 0,
                        amount1Min: 0,
                        deadline: block.timestamp + 60
                    })
                );

            protocol.positionManager.transferAllTokens(
                USDC_ADDRESS,
                amount0,
                address(this)
            );

            protocol.positionManager.transferAllTokens(
                USDT_ADDRESS,
                amount1,
                address(this)
            );

            if (complete) {
                (IBasePositionManager.Position memory pos, ) = protocol
                    .positionManager
                    .positions(nftId);

                if (pos.rTokenOwed > 0) {
                    protocol.positionManager.burnRTokens(
                        IBasePositionManager.BurnRTokenParams({
                            tokenId: nftId,
                            amount0Min: 0,
                            amount1Min: 0,
                            deadline: block.timestamp + 60
                        })
                    );
                }

                protocol.positionManager.burn(nftId);
            }
        }
    }

    function getTickLowerAndUpper(
        uint256 nftId,
        ProtocolHelper memory protocol
    ) public view returns (int24 tickLower, int24 tickUpper) {
        if (nftId != 0) {
            (IBasePositionManager.Position memory pos, ) = protocol
                .positionManager
                .positions(nftId);

            return (pos.tickLower, pos.tickUpper);
        }

        (, int24 tick, , ) = protocol.pool.getPoolState();

        int24 fullTick = tick - (tick % protocol.pool.tickDistance());

        // Here we get lower and upper bounds for current price
        tickLower = fullTick - protocol.pool.tickDistance();
        tickUpper = fullTick + protocol.pool.tickDistance();

        tickLower -= 10 * protocol.pool.tickDistance();
        tickUpper += 10 * protocol.pool.tickDistance();
    }

    function enter(
        address implementation,
        bytes memory configuration,
        bytes memory inputData
    ) public override returns (uint256[5] memory outputAmounts) {
        outputAmounts = _act(implementation, configuration, inputData);
    }

    function exit(
        address implementation,
        bytes memory configuration,
        bytes memory outputData
    ) public override returns (uint256[5] memory outputAmounts) {
        outputAmounts = _act(implementation, configuration, outputData);
    }

    function createConfig(
        address[5] memory _inputs,
        address[5] memory _outputs,
        uint256 _trigger
    ) public pure returns (bytes memory configData) {
        configData = abi.encode(_inputs, _outputs, _trigger);
    }

    function showBalances(
        address _silo,
        bytes memory
    ) external view override returns (ActionBalance memory) {
        (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1,
            address token0,
            address token1,
            address pool
        ) = _getFarmUserInfo(_silo);

        return
            ActionBalance({
                collateral: liquidity,
                debt: 0,
                collateralToken: address(pool),
                debtToken: address(0),
                collateralConverted: 0,
                collateralConvertedToken: address(0),
                lpUnderlyingBalances: string(
                    abi.encodePacked(
                        Strings.toString(amount0),
                        ",",
                        Strings.toString(amount1)
                    )
                ),
                lpUnderlyingTokens: string(
                    abi.encodePacked(
                        Strings.toHexString(uint160(token0), 20),
                        ",",
                        Strings.toHexString(uint160(token1), 20)
                    )
                )
            });
    }

    function actionValid(
        bytes memory
    ) external view override returns (bool, bool) {
        IUniswapV2Pair qsLP = IUniswapV2Pair(QS_V2_USDC_USDT_ADDRESS);

        uint256 totalSupply = qsLP.totalSupply();
        (uint112 resA, uint112 resB, ) = qsLP.getReserves();
        return (
            ISiloFactory(getFactory()).actionValid(address(this)),
            totalSupply > 0 && resA > 0 && resB > 0
        ); //second bool overwritten to logically account for the end block
    }

    function checkMaintain(
        bytes memory configuration
    ) public view override returns (bool, uint256) {
        if (ISilo(msg.sender).siloDelay() != 0) {
            //user has chosen a time based upkeep schedule instead of an automatic one
            return (false, 0);
        }
        (uint256 reward, uint256 pid, uint256 nftId) = getFarmReward(
            msg.sender
        );

        if (pid == 0 && nftId > 0) {
            // current farm pool is ended
            return (true, 5);
        }

        uint256 trigger;
        (, , trigger) = abi.decode(
            configuration,
            (address[5], address[5], uint256)
        );

        if (reward >= trigger) {
            return (true, 1);
        }

        uint256 positionNFT = getPositionNFT(msg.sender);

        if (pid > 0 && positionNFT > 0 && nftId == 0) {
            // farm pool is renewed
            return (true, 6);
        }

        return (false, 0);
    }

    function getStakedNFT(address user) internal view returns (uint256 nftId) {
        uint256[] memory listNFTs = IKyberSwapElasticLM(KS_ELASTIC_LM)
            .getDepositedNFTs(user);
        if (listNFTs.length > 0) {
            nftId = listNFTs[listNFTs.length - 1];
        }
    }

    function getFarmReward(
        address user
    ) internal view returns (uint256 reward, uint256 pid, uint256 nftId) {
        nftId = getStakedNFT(user);

        // uint256[] memory listNFTs = IKyberSwapElasticLM(KS_ELASTIC_LM)
        //     .getDepositedNFTs(user);

        if (nftId > 0) {
            // nftId = listNFTs[listNFTs.length - 1];
            pid = getCurrentPid(user);
            (, uint256[] memory rewardPending, ) = IKyberSwapElasticLM(
                KS_ELASTIC_LM
            ).getUserInfo(nftId, pid);
            if (rewardPending.length > 0) {
                reward = rewardPending[0];
            }
        }
    }

    function extraInfo(
        bytes memory
    ) public view override returns (uint256[4] memory info) {
        (uint256 reward, uint256 pid, uint256 nftId) = getFarmReward(
            msg.sender
        );
        info[0] = reward;
        info[1] = pid;
        info[2] = nftId;

        info[3] = MAX_UINT256;
    }

    function checkUpkeep(bytes memory) public view override returns (bool) {
        (uint256 reward, , ) = getFarmReward(msg.sender);

        if (reward == 0) {
            return false;
        }

        return true;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function getPreviousTicks(
        int24 tickLower,
        int24 tickUpper
    ) internal view returns (int24[2] memory ticksPrevious) {
        (int24 prevLower, ) = ITicksFeesReader(TICKER_READER_ADDRESS)
            .getNearestInitializedTicks(IPool(KS_USDC_USDT_POOL), tickLower);
        (int24 prevUpper, ) = ITicksFeesReader(TICKER_READER_ADDRESS)
            .getNearestInitializedTicks(IPool(KS_USDC_USDT_POOL), tickUpper);

        ticksPrevious = [prevLower, prevUpper];
    }

    function calcRequiredQtys(
        uint256 amountB,
        int24 tickLower,
        int24 tickUpper,
        uint160 currentSqrtP
    ) internal pure returns (uint256 token0Unit, uint256 token1Unit) {
        uint160 lowerSqrtP = TickMath.getSqrtRatioAtTick(tickLower);
        uint160 upperSqrtP = TickMath.getSqrtRatioAtTick(tickUpper);

        token1Unit = amountB;

        uint128 liquidity;
        if (currentSqrtP >= upperSqrtP) {
            liquidity = LiquidityMath.getLiquidityFromQty1(
                lowerSqrtP,
                upperSqrtP,
                amountB
            );
        } else {
            liquidity = LiquidityMath.getLiquidityFromQty1(
                lowerSqrtP,
                currentSqrtP,
                amountB
            );
        }

        int256 qty0Int;

        if (currentSqrtP < lowerSqrtP) {
            qty0Int = QtyDeltaMath.calcRequiredQty0(
                lowerSqrtP,
                upperSqrtP,
                liquidity,
                true
            );
        } else {
            qty0Int = QtyDeltaMath.calcRequiredQty0(
                currentSqrtP,
                upperSqrtP,
                liquidity,
                true
            );
        }

        if (qty0Int < 0) {
            token0Unit = qty0Int.revToUint256();
        } else {
            token0Unit = uint256(qty0Int);
        }
    }

    function _getFarmUserInfo(
        address silo
    )
        internal
        view
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1,
            address token0,
            address token1,
            address poolAddress
        )
    {
        uint256 nftId = getStakedNFT(silo);
        // uint256[] memory listNFTs = IKyberSwapElasticLM(KS_ELASTIC_LM)
        //     .getDepositedNFTs(silo);

        // console.log("_getFarmUserInfo   nftId:%s  ", nftId);

        if (nftId > 0) {
            // uint256 nftId = listNFTs[listNFTs.length - 1];
            (
                IBasePositionManager.Position memory pos,
                IBasePositionManager.PoolInfo memory info
            ) = IAntiSnipAttackPositionManager(KYBER_POSITION_MANAGER)
                    .positions(nftId);

            liquidity = pos.liquidity;

            token0 = info.token0;
            token1 = info.token1;

            poolAddress = KS_USDC_USDT_POOL;

            // console.log(
            //     "_getFarmUserInfo   liquidity:%s token0:%s ",
            //     liquidity,
            //     token0
            // );

            (int256 qty0Int, int256 qty1Int) = tweakPositionInfo(
                IPool(poolAddress),
                pos.tickLower,
                pos.tickUpper,
                liquidity
            );

            if (qty0Int < 0) {
                amount0 = qty0Int.revToUint256();
            }

            if (qty1Int < 0) {
                amount1 = qty1Int.revToUint256();
            }
        }
    }

    function tweakPositionInfo(
        IPool pool,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidityDelta
    ) private view returns (int256 qty0, int256 qty1) {
        (uint160 sqrtP, , , ) = pool.getPoolState();
        //  int24 currentTick
        // if (currentTick < tickLower) {
        //     return (
        //         QtyDeltaMath.calcRequiredQty0(
        //             TickMath.getSqrtRatioAtTick(tickLower),
        //             TickMath.getSqrtRatioAtTick(tickUpper),
        //             liquidityDelta,
        //             false
        //         ),
        //         0,
        //         0
        //     );
        // }
        // if (currentTick >= tickUpper) {
        //     return (
        //         0,
        //         QtyDeltaMath.calcRequiredQty1(
        //             TickMath.getSqrtRatioAtTick(tickLower),
        //             TickMath.getSqrtRatioAtTick(tickUpper),
        //             liquidityDelta,
        //             false
        //         ),
        //         0
        //     );
        // } // current tick is inside the passed range

        qty0 = QtyDeltaMath.calcRequiredQty0(
            sqrtP,
            TickMath.getSqrtRatioAtTick(tickUpper),
            liquidityDelta,
            false
        );
        qty1 = QtyDeltaMath.calcRequiredQty1(
            TickMath.getSqrtRatioAtTick(tickLower),
            sqrtP,
            liquidityDelta,
            false
        );
    }

    function getRemoveLiquidty(
        uint256 amount,
        uint256 nftId,
        ProtocolHelper memory protocol
    ) internal view returns (uint128 decreaseLiquidity) {
        (IBasePositionManager.Position memory pos, ) = protocol
            .positionManager
            .positions(nftId);

        uint256 amount0;
        uint256 amount1;

        (int256 qty0Int, int256 qty1Int) = tweakPositionInfo(
            IPool(KS_USDC_USDT_POOL),
            pos.tickLower,
            pos.tickUpper,
            pos.liquidity
        );

        if (qty0Int < 0) {
            amount0 = qty0Int.revToUint256();
        }

        if (qty1Int < 0) {
            amount1 = qty1Int.revToUint256();
        }

        uint256 mai = (amount0 + amount1) * 10 ** 12;

        // console.log("getRemoveLiquidty pos.liquidity:%s", pos.liquidity);

        // console.log(
        //     "getRemoveLiquidty amount0:%s amount1:%s mai:%s",
        //     amount0,
        //     amount1,
        //     mai
        // );

        decreaseLiquidity = uint128((pos.liquidity * amount) / mai);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IKSElasticLMHelper {
    function checkPool(
        address pAddress,
        address nftContract,
        uint256 nftId
    ) external view returns (bool);

    /// @dev use virtual to be overrided to mock data for fuzz tests
    function getActiveTime(
        address pAddr,
        address nftContract,
        uint256 nftId
    ) external view returns (uint128);

    function getSignedFee(
        address nftContract,
        uint256 nftId
    ) external view returns (int256);

    function getSignedFeePool(
        address poolAddress,
        address nftContract,
        uint256 nftId
    ) external view returns (int256);

    function getLiq(
        address nftContract,
        uint256 nftId
    ) external view returns (uint128);

    function getPair(
        address nftContract,
        uint256 nftId
    ) external view returns (address, address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IKyberSwapElasticLMEvents} from "./IKyberSwapElasticLMEvents.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IKyberSwapElasticLM is IKyberSwapElasticLMEvents {
    struct RewardData {
        address rewardToken;
        uint256 rewardUnclaimed;
    }

    struct LMPoolInfo {
        address poolAddress;
        uint32 startTime;
        uint32 endTime;
        uint256 totalSecondsClaimed; // scaled by (1 << 96)
        RewardData[] rewards;
        uint256 feeTarget;
        uint256 numStakes;
    }

    struct PositionInfo {
        address owner;
        uint256 liquidity;
    }

    struct StakeInfo {
        uint128 secondsPerLiquidityLast;
        uint256[] rewardLast;
        uint256[] rewardPending;
        uint256[] rewardHarvested;
        int256 feeFirst;
        uint256 liquidity;
    }

    // input data in harvestMultiplePools function
    struct HarvestData {
        uint256[] pIds;
    }

    // avoid stack too deep error
    struct RewardCalculationData {
        uint128 secondsPerLiquidityNow;
        int256 feeNow;
        uint256 vestingVolume;
        uint256 totalSecondsUnclaimed;
        uint256 secondsPerLiquidity;
        uint256 secondsClaim; // scaled by (1 << 96)
    }

    /**
     * @dev Add new pool to LM
     * @param poolAddr pool address
     * @param startTime start time of liquidity mining
     * @param endTime end time of liquidity mining
     * @param rewardTokens reward token list for pool
     * @param rewardAmounts reward amount of list token
     * @param feeTarget fee target for pool
     *
     */
    function addPool(
        address poolAddr,
        uint32 startTime,
        uint32 endTime,
        address[] calldata rewardTokens,
        uint256[] calldata rewardAmounts,
        uint256 feeTarget
    ) external;

    /**
     * @dev Renew a pool to start another LM program
     * @param pId pool id to update
     * @param startTime start time of liquidity mining
     * @param endTime end time of liquidity mining
     * @param rewardAmounts reward amount of list token
     * @param feeTarget fee target for pool
     *
     */
    function renewPool(
        uint256 pId,
        uint32 startTime,
        uint32 endTime,
        uint256[] calldata rewardAmounts,
        uint256 feeTarget
    ) external;

    /**
     * @dev Deposit NFT
     * @param nftIds list nft id
     *
     */
    function deposit(uint256[] calldata nftIds) external;

    /**
     * @dev Deposit NFTs into the pool and join farms if applicable
     * @param pId pool id to join farm
     * @param nftIds List of NFT ids from BasePositionManager, should match with the pId
     *
     */
    function depositAndJoin(uint256 pId, uint256[] calldata nftIds) external;

    /**
     * @dev Withdraw NFT, must exit all pool before call.
     * @param nftIds list nft id
     *
     */
    function withdraw(uint256[] calldata nftIds) external;

    /**
     * @dev Join pools
     * @param pId pool id to join
     * @param nftIds nfts to join
     * @param liqs list liquidity value to join each nft
     *
     */
    function join(
        uint256 pId,
        uint256[] calldata nftIds,
        uint256[] calldata liqs
    ) external;

    /**
     * @dev Exit from pools
     * @param pId pool ids to exit
     * @param nftIds list nfts id
     * @param liqs list liquidity value to exit from each nft
     *
     */
    function exit(
        uint256 pId,
        uint256[] calldata nftIds,
        uint256[] calldata liqs
    ) external;

    /**
     * @dev Claim rewards for a list of pools for a list of nft positions
     * @param nftIds List of NFT ids to harvest
     * @param datas List of pool ids to harvest for each nftId, encoded into bytes
     */
    function harvestMultiplePools(
        uint256[] calldata nftIds,
        bytes[] calldata datas
    ) external;

    /**
     * @dev remove liquidity from elastic for a list of nft position, also update on farm
     * @param nftId to remove
     * @param liquidity liquidity amount to remove from nft
     * @param amount0Min expected min amount of token0 should receive
     * @param amount1Min expected min amount of token1 should receive
     * @param deadline deadline of this tx
     * @param isReceiveNative should unwrap native or not
     * @param claimFeeAndRewards also claim LP Fee and farm rewards
     */
    function removeLiquidity(
        uint256 nftId,
        uint128 liquidity,
        uint256 amount0Min,
        uint256 amount1Min,
        uint256 deadline,
        bool isReceiveNative,
        bool[2] calldata claimFeeAndRewards
    ) external;

    /**
     * @dev Claim fee from elastic for a list of nft positions
     * @param nftIds List of NFT ids to claim
     * @param amount0Min expected min amount of token0 should receive
     * @param amount1Min expected min amount of token1 should receive
     * @param poolAddress address of Elastic pool of those nfts
     * @param isReceiveNative should unwrap native or not
     * @param deadline deadline of this tx
     */
    function claimFee(
        uint256[] calldata nftIds,
        uint256 amount0Min,
        uint256 amount1Min,
        address poolAddress,
        bool isReceiveNative,
        uint256 deadline
    ) external;

    /**
     * @dev Operator only. Call to withdraw all reward from list pools.
     * @param rewards list reward address erc20 token
     * @param amounts amount to withdraw
     *
     */
    function emergencyWithdrawForOwner(
        address[] calldata rewards,
        uint256[] calldata amounts
    ) external;

    /**
     * @dev Withdraw NFT, can call any time, reward will be reset. Must enable this func by operator
     * @param pIds list pool to withdraw
     *
     */
    function emergencyWithdraw(uint256[] calldata pIds) external;

    /**
     * @dev get list of pool that this nft joined
     * @param nftId to get
     */
    function getJoinedPools(
        uint256 nftId
    ) external view returns (uint256[] memory poolIds);

    /**
     * @dev get list of pool that this nft joined, only in a specific range
     * @param nftId to get
     * @param fromIndex index from
     * @param toIndex index to
     */
    function getJoinedPoolsInRange(
        uint256 nftId,
        uint256 fromIndex,
        uint256 toIndex
    ) external view returns (uint256[] memory poolIds);

    /**
     * @dev get user's info (staked info) of a nft in a pool
     * @param nftId to get
     * @param pId to get
     */
    function getUserInfo(
        uint256 nftId,
        uint256 pId
    )
        external
        view
        returns (
            uint256 liquidity,
            uint256[] memory rewardPending,
            uint256[] memory rewardLast
        );

    /**
     * @dev get pool info
     * @param pId to get
     */
    function getPoolInfo(
        uint256 pId
    )
        external
        view
        returns (
            address poolAddress,
            uint32 startTime,
            uint32 endTime,
            uint256 totalSecondsClaimed,
            uint256 feeTarget,
            uint256 numStakes,
            //index reward => reward data
            address[] memory rewardTokens,
            uint256[] memory rewardUnclaimeds
        );

    /**
     * @dev get list of deposited nfts of an address
     * @param user address of user to get
     */
    function getDepositedNFTs(
        address user
    ) external view returns (uint256[] memory listNFTs);

    function nft() external view returns (IERC721);

    function poolLength() external view returns (uint256);

    function getRewardCalculationData(
        uint256 nftId,
        uint256 pId
    ) external view returns (RewardCalculationData memory data);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IKSElasticLMHelper} from "./IKSElasticLMHelper.sol";

interface IKyberSwapElasticLMEvents {
    event AddPool(
        uint256 indexed pId,
        address poolAddress,
        uint32 startTime,
        uint32 endTime,
        uint256 feeTarget
    );

    event RenewPool(
        uint256 indexed pid,
        uint32 startTime,
        uint32 endTime,
        uint256 feeTarget
    );

    event Deposit(address sender, uint256 indexed nftId);

    event Withdraw(address sender, uint256 indexed nftId);

    event Join(uint256 indexed nftId, uint256 indexed pId, uint256 indexed liq);

    event Exit(
        address to,
        uint256 indexed nftId,
        uint256 indexed pId,
        uint256 indexed liq
    );

    event SyncLiq(
        uint256 indexed nftId,
        uint256 indexed pId,
        uint256 indexed liq
    );

    event Harvest(
        uint256 indexed nftId,
        address to,
        address reward,
        uint256 indexed amount
    );

    event EmergencyEnabled();

    event UpdateSpecialFeatureEnabled(bool enableOrDisable);

    event EmergencyWithdrawForOwner(address reward, uint256 indexed amount);

    event EmergencyWithdraw(address sender, uint256 indexed nftId);

    event LMHelperUpdated(IKSElasticLMHelper helper);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Callback for IAlgebraPoolActions#swap
/// @notice Any contract that calls IAlgebraPoolActions#swap must implement this interface
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IAlgebraSwapCallback {
  /// @notice Called to `msg.sender` after executing a swap via IAlgebraPool#swap.
  /// @dev In the implementation you must pay the pool tokens owed for the swap.
  /// The caller of this method must be checked to be a AlgebraPool deployed by the canonical AlgebraFactory.
  /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
  /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
  /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
  /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
  /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
  /// @param data Any data passed through by the caller via the IAlgebraPoolActions#swap call
  function algebraSwapCallback(
    int256 amount0Delta,
    int256 amount1Delta,
    bytes calldata data
  ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./callback/IAlgebraSwapCallback.sol";

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Algebra
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-periphery
interface ISwapRouter is IAlgebraSwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 limitSqrtPrice;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 limitSqrtPrice;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @dev Unlike standard swaps, handles transferring from user before the actual swap.
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingleSupportingFeeOnTransferTokens(ExactInputSingleParams calldata params)
        external
        returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../interfaces/ISiloFactory.sol";
import "../../interfaces/ISilo.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../interfaces/IAction.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract BaseSiloAction is Ownable {
    bytes public configurationData; //if not set on deployment, then they use the value in the Silo
    string public name;
    string public feeName; //name displayed when showing fee information
    uint256 public constant MAX_TRANSIENT_VARIABLES = 5;
    address public factory;
    uint256 public constant FEE_DECIMALS = 10000;
    string public metaData;
    bool public usesTakeFee;

    /******************************Functions that can be implemented******************************/
    /**
     * @dev what a silo should do when entering a strategy and running this action
     */
    function enter(
        address implementation,
        bytes memory configuration,
        bytes memory inputData
    ) public virtual returns (uint256[5] memory) {}

    /**
     * @dev what a silo should do when exiting a strategy and running this action
     */
    function exit(
        address implementation,
        bytes memory configuration,
        bytes memory outputData
    ) public virtual returns (uint256[5] memory) {}

    function protocolStatistics() external view returns (string memory) {}

    function showBalances(
        address _silo,
        bytes memory _configurationData
    ) external view virtual returns (ActionBalance memory) {}

    function showDust(
        address _silo,
        bytes memory _configurationData
    ) external view virtual returns (address[] memory, uint256[] memory) {}

    /******************************external view functions******************************/
    function showFee(
        address _action
    ) external view returns (string memory nameOfFee, uint256[4] memory fees) {
        nameOfFee = feeName;
        if (usesTakeFee) {
            fees = ISiloFactory(IAction(_action).getFactory()).getFeeInfoNoTier(
                _action
            );
        }
    }

    function actionValid(
        bytes memory
    ) external view virtual returns (bool, bool) {
        return (ISiloFactory(getFactory()).actionValid(address(this)), true); //second bool can be overwritten by individual actions
    }

    /******************************public view functions******************************/
    function getConfig() public view returns (bytes memory) {
        return configurationData;
    }

    function getIsSilo(address _silo) public view returns (bool) {
        return ISiloFactory(factory).isSilo(_silo);
    }

    function getIsSiloManager(
        address _silo,
        address _manager
    ) public view returns (bool) {
        return ISiloFactory(factory).isSiloManager(_silo, _manager);
    }

    function getFactory() public view returns (address) {
        return factory;
    }

    function setFactory(address _siloFactory) public onlyOwner {
        factory = _siloFactory;
    }

    function getDecimals() public pure returns (uint256) {
        return FEE_DECIMALS;
    }

    function getMetaData() public view returns (string memory) {
        return metaData;
    }

    function checkMaintain(
        bytes memory
    ) public view virtual returns (bool, uint256) {
        return (false, 0);
    }

    function validateConfig(bytes memory) public view virtual returns (bool) {
        return true;
    }

    function checkUpkeep(bytes memory) public view virtual returns (bool) {
        return true;
    }

    function extraInfo(
        bytes memory
    ) public view virtual returns (uint256[4] memory info) {}

    function vaultInfo(
        address,
        bytes memory
    )
        public
        view
        virtual
        returns (uint256, uint256, uint256, uint256, uint256)
    {
        return (0, 0, 0, 0, 0);
    }

    /******************************internal view functions******************************/
    function _takeFee(
        address _action,
        uint256 _gains,
        address _token
    ) internal virtual returns (uint256 remaining) {
        if (_gains == 0) {
            return 0;
        }
        (uint256 fee, address recipient) = ISiloFactory(
            IAction(_action).getFactory()
        ).getFeeInfo(_action);
        uint256 feeToTake = (_gains * fee) / IAction(_action).getDecimals();
        if (feeToTake > 0) {
            remaining = _gains - feeToTake;

            (uint256 share, address referrer) = ISilo(address(this))
                .getReferralInfo();

            if (share > 0 && referrer != address(0)) {
                uint256 shareAmount = (feeToTake * share) /
                    IAction(_action).getDecimals();
                if (shareAmount > 0 && feeToTake > shareAmount) {
                    feeToTake = feeToTake - shareAmount;
                    SafeERC20.safeTransfer(
                        IERC20(_token),
                        referrer,
                        shareAmount
                    );
                }
            }
            SafeERC20.safeTransfer(IERC20(_token), recipient, feeToTake);
        } else {
            remaining = _gains;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function HOLDING_ADDRESS() external view returns (address);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);
    function destroy(uint value) external returns(bool);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;

    function handleEarnings() external returns(uint amount);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

struct ActionBalance {
    uint256 collateral;
    uint256 debt;
    address collateralToken;
    address debtToken;
    uint256 collateralConverted;
    address collateralConvertedToken;
    string lpUnderlyingBalances;
    string lpUnderlyingTokens;
}

interface IAction {
    function getConfig() external view returns (bytes memory config);

    function checkMaintain(
        bytes memory configuration
    ) external view returns (bool, uint256);

    function checkUpkeep(
        bytes memory configuration
    ) external view returns (bool);

    function extraInfo(
        bytes memory configuration
    ) external view returns (uint256[4] memory info);

    function validateConfig(
        bytes memory configData
    ) external view returns (bool);

    function getMetaData() external view returns (string memory);

    function getFactory() external view returns (address);

    function getDecimals() external view returns (uint256);

    function showFee(
        address _action
    ) external view returns (string memory actionName, uint256[4] memory fees);

    function showBalances(
        address _silo,
        bytes memory _configurationData
    ) external view returns (ActionBalance memory);

    function showDust(
        address _silo,
        bytes memory _configurationData
    ) external view returns (address[] memory, uint256[] memory);

    function vaultInfo(
        address _silo,
        bytes memory configuration
    ) external view returns (uint256, uint256, uint256, uint256, uint256);

    function actionValid(
        bytes memory _configurationData
    ) external view returns (bool, bool);

    function getIsSilo(address _silo) external view returns (bool);

    function getIsSiloManager(
        address _silo,
        address _manager
    ) external view returns (bool);

    function setFactory(address _siloFactory) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct PriceOracle {
    address oracle;
    uint256 actionPrice;
}

enum Statuses {
    PAUSED,
    DORMANT,
    MANAGED,
    UNWIND
}

interface ISilo {
    function initialize(uint256 siloID, uint256 main, address factory) external;

    function deposit() external;

    function withdraw(uint256 _requestedOut) external;

    function maintain() external;

    function exitSilo(address caller) external;

    function adminCall(address target, bytes memory data) external;

    function setStrategy(
        address[5] memory input,
        bytes[] memory _configurationData,
        address[] memory _implementations
    ) external;

    function getConfig() external view returns (bytes memory config);

    function withdrawToken(address token, address recipient) external;

    function adjustSiloDelay(uint256 _newDelay) external;

    function checkUpkeep(
        bytes calldata checkData
    ) external view returns (bool upkeepNeeded, bytes memory performData);

    function performUpkeep(bytes calldata performData) external;

    function siloDelay() external view returns (uint256);

    function name() external view returns (string memory);

    function lastTimeMaintained() external view returns (uint256);

    function setName(string memory name) external;

    function deposited() external view returns (bool);

    function isNew() external view returns (bool);

    function status() external view returns (Statuses);

    function setStrategyName(string memory _strategyName) external;

    function setStrategyCategory(uint256 _strategyCategory) external;

    function strategyName() external view returns (string memory);

    function tokenMinimum(address token) external view returns (uint256);

    function strategyCategory() external view returns (uint256);

    function main() external view returns (uint256);

    function lastPid() external view returns (uint256);

    function adjustStrategy(
        uint256 _index,
        bytes memory _configurationData,
        address _implementation
    ) external;

    function viewStrategy()
        external
        view
        returns (address[] memory actions, bytes[] memory configData);

    function highRiskAction() external view returns (bool);

    function showActionStackValidity() external view returns (bool, bool);

    function getInputTokens() external view returns (address[5] memory);

    function getStatus() external view returns (Statuses);

    function pause() external;

    function unpause() external;

    function setActive() external;

    function possibleReinvestSilo() external view returns (bool possible);

    function getExtraSiloInfo()
        external
        view
        returns (
            uint256 strategyType,
            uint256 currentBalance,
            uint256 possibleWithdraw,
            uint256 availableBlock,
            uint256 pendingReward,
            uint256 lastPid
        );

    function getReferralInfo()
        external
        view
        returns (uint256 fee, address recipient);

    function setReferralInfo(bytes32 _code) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface ISiloFactory is IERC721Enumerable{
    function tokenMinimum(address _token) external view returns(uint _minimum);
    function balanceOf(address _owner) external view returns(uint);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function managerFactory() external view returns(address);
    function siloMap(uint _id) external view returns(address);
    function tierManager() external view returns(address);
    function ownerOf(uint _id) external view returns(address);
    function siloToId(address silo) external view returns(uint);
    // function createSilo(address recipient) external returns(uint);
    function setActionStack(uint siloID, address[5] memory input, address[] memory _implementations, bytes[] memory _configurationData) external;
    // function withdraw(uint siloID) external;
    function getFeeInfo(address _action) external view returns(uint fee, address recipient);
    function strategyMaxGas() external view returns(uint);
    function strategyName(string memory _name) external view returns(uint);
    
    function getCatalogue(uint _type) external view returns(string[] memory);
    function getStrategyInputs(uint _id) external view returns(address[5] memory inputs);
    function getStrategyActions(uint _id) external view returns(address[] memory actions);
    function getStrategyConfigurationData(uint _id) external view returns(bytes[] memory configurationData);
    function useCustom(address _action) external view returns(bool);
    // function getFeeList(address _action) external view returns(uint[4] memory);
    function feeRecipient(address _action) external view returns(address);
    function defaultFeeList() external view returns(uint[4] memory);
    function defaultRecipient() external view returns(address);
    // function getTier(address _silo) external view returns(uint);

    function getFeeInfoNoTier(address _action) external view returns(uint[4] memory);
    function highRiskActions(address _action) external view returns(bool);
    function actionValid(address _action) external view returns(bool);
    function skipActionValidTeamCheck(address _user) external view returns(bool);
    function skipActionValidLogicCheck(address _user) external view returns(bool);
    function isSilo(address _silo) external view returns(bool);

    function isSiloManager(address _silo,address _manager) external view returns(bool);

    function currentStrategyId() external view returns(uint);
    function minBalance() external view returns(uint);

    function mainActoins(string memory strategyName) external view returns(uint);
    
    function subFactory() external view returns(address);
    function referral() external view returns(address);
}