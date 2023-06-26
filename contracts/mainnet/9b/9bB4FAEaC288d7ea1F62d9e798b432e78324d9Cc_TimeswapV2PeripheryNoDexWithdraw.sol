// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @title Library for errors
/// @author Timeswap Labs
/// @dev Common error messages
library Error {
  /// @dev Reverts when input is zero.
  error ZeroInput();

  /// @dev Reverts when output is zero.
  error ZeroOutput();

  /// @dev Reverts when a value cannot be zero.
  error CannotBeZero();

  /// @dev Reverts when a pool already have liquidity.
  /// @param liquidity The liquidity amount that already existed in the pool.
  error AlreadyHaveLiquidity(uint160 liquidity);

  /// @dev Reverts when a pool requires liquidity.
  error RequireLiquidity();

  /// @dev Reverts when a given address is the zero address.
  error ZeroAddress();

  /// @dev Reverts when the maturity given is not withing uint96.
  /// @param maturity The maturity being inquired.
  error IncorrectMaturity(uint256 maturity);

  /// @dev Reverts when an option of given strike and maturity is still inactive.
  /// @param strike The chosen strike.
  /// @param maturity The chosen maturity.
  error InactiveOption(uint256 strike, uint256 maturity);

  /// @dev Reverts when a pool of given strike and maturity is still inactive.
  /// @param strike The chosen strike.
  /// @param maturity The chosen maturity.
  error InactivePool(uint256 strike, uint256 maturity);

  /// @dev Reverts when a liquidity token is inactive.
  error InactiveLiquidityTokenChoice();

  /// @dev Reverts when the square root interest rate is zero.
  /// @param strike The chosen strike.
  /// @param maturity The chosen maturity.
  error ZeroSqrtInterestRate(uint256 strike, uint256 maturity);

  /// @dev Reverts when the maturity is already matured.
  /// @param maturity The maturity.
  /// @param blockTimestamp The current block timestamp.
  error AlreadyMatured(uint256 maturity, uint96 blockTimestamp);

  /// @dev Reverts when the maturity is still active.
  /// @param maturity The maturity.
  /// @param blockTimestamp The current block timestamp.
  error StillActive(uint256 maturity, uint96 blockTimestamp);

  /// @dev Token amount not received.
  /// @param minuend The amount being subtracted.
  /// @param subtrahend The amount subtracting.
  error NotEnoughReceived(uint256 minuend, uint256 subtrahend);

  /// @dev The deadline of a transaction has been reached.
  /// @param deadline The deadline set.
  error DeadlineReached(uint256 deadline);

  /// @dev Reverts when input is zero.
  function zeroInput() internal pure {
    revert ZeroInput();
  }

  /// @dev Reverts when output is zero.
  function zeroOutput() internal pure {
    revert ZeroOutput();
  }

  /// @dev Reverts when a value cannot be zero.
  function cannotBeZero() internal pure {
    revert CannotBeZero();
  }

  /// @dev Reverts when a pool already have liquidity.
  /// @param liquidity The liquidity amount that already existed in the pool.
  function alreadyHaveLiquidity(uint160 liquidity) internal pure {
    revert AlreadyHaveLiquidity(liquidity);
  }

  /// @dev Reverts when a pool requires liquidity.
  function requireLiquidity() internal pure {
    revert RequireLiquidity();
  }

  /// @dev Reverts when a given address is the zero address.
  function zeroAddress() internal pure {
    revert ZeroAddress();
  }

  /// @dev Reverts when the maturity given is not withing uint96.
  /// @param maturity The maturity being inquired.
  function incorrectMaturity(uint256 maturity) internal pure {
    revert IncorrectMaturity(maturity);
  }

  /// @dev Reverts when the maturity is already matured.
  /// @param maturity The maturity.
  /// @param blockTimestamp The current block timestamp.
  function alreadyMatured(uint256 maturity, uint96 blockTimestamp) internal pure {
    revert AlreadyMatured(maturity, blockTimestamp);
  }

  /// @dev Reverts when the maturity is still active.
  /// @param maturity The maturity.
  /// @param blockTimestamp The current block timestamp.
  function stillActive(uint256 maturity, uint96 blockTimestamp) internal pure {
    revert StillActive(maturity, blockTimestamp);
  }

  /// @dev The deadline of a transaction has been reached.
  /// @param deadline The deadline set.
  function deadlineReached(uint256 deadline) internal pure {
    revert DeadlineReached(deadline);
  }

  /// @dev Reverts when an option of given strike and maturity is still inactive.
  /// @param strike The chosen strike.
  function inactiveOptionChoice(uint256 strike, uint256 maturity) internal pure {
    revert InactiveOption(strike, maturity);
  }

  /// @dev Reverts when a pool of given strike and maturity is still inactive.
  /// @param strike The chosen strike.
  /// @param maturity The chosen maturity.
  function inactivePoolChoice(uint256 strike, uint256 maturity) internal pure {
    revert InactivePool(strike, maturity);
  }

  /// @dev Reverts when the square root interest rate is zero.
  /// @param strike The chosen strike.
  /// @param maturity The chosen maturity.
  function zeroSqrtInterestRate(uint256 strike, uint256 maturity) internal pure {
    revert ZeroSqrtInterestRate(strike, maturity);
  }

  /// @dev Reverts when a liquidity token is inactive.
  function inactiveLiquidityTokenChoice() internal pure {
    revert InactiveLiquidityTokenChoice();
  }

  /// @dev Reverts when token amount not received.
  /// @param balance The balance amount being subtracted.
  /// @param balanceTarget The amount target.
  function checkEnough(uint256 balance, uint256 balanceTarget) internal pure {
    if (balance < balanceTarget) revert NotEnoughReceived(balance, balanceTarget);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {Math} from "./Math.sol";

/// @title Library for math utils for uint512
/// @author Timeswap Labs
library FullMath {
  using Math for uint256;

  /// @dev Reverts when modulo by zero.
  error ModuloByZero();

  /// @dev Reverts when add512 overflows over uint512.
  /// @param addendA0 The least significant part of first addend.
  /// @param addendA1 The most significant part of first addend.
  /// @param addendB0 The least significant part of second addend.
  /// @param addendB1 The most significant part of second addend.
  error AddOverflow(uint256 addendA0, uint256 addendA1, uint256 addendB0, uint256 addendB1);

  /// @dev Reverts when sub512 underflows.
  /// @param minuend0 The least significant part of minuend.
  /// @param minuend1 The most significant part of minuend.
  /// @param subtrahend0 The least significant part of subtrahend.
  /// @param subtrahend1 The most significant part of subtrahend.
  error SubUnderflow(uint256 minuend0, uint256 minuend1, uint256 subtrahend0, uint256 subtrahend1);

  /// @dev Reverts when div512To256 overflows over uint256.
  /// @param dividend0 The least significant part of dividend.
  /// @param dividend1 The most significant part of dividend.
  /// @param divisor The divisor.
  error DivOverflow(uint256 dividend0, uint256 dividend1, uint256 divisor);

  /// @dev Reverts when mulDiv overflows over uint256.
  /// @param multiplicand The multiplicand.
  /// @param multiplier The multiplier.
  /// @param divisor The divisor.
  error MulDivOverflow(uint256 multiplicand, uint256 multiplier, uint256 divisor);

  /// @dev Calculates the sum of two uint512 numbers.
  /// @notice Reverts on overflow over uint512.
  /// @param addendA0 The least significant part of addendA.
  /// @param addendA1 The most significant part of addendA.
  /// @param addendB0 The least significant part of addendB.
  /// @param addendB1 The most significant part of addendB.
  /// @return sum0 The least significant part of sum.
  /// @return sum1 The most significant part of sum.
  function add512(
    uint256 addendA0,
    uint256 addendA1,
    uint256 addendB0,
    uint256 addendB1
  ) internal pure returns (uint256 sum0, uint256 sum1) {
    uint256 carry;
    assembly {
      sum0 := add(addendA0, addendB0)
      carry := lt(sum0, addendA0)
      sum1 := add(add(addendA1, addendB1), carry)
    }

    if (carry == 0 ? addendA1 > sum1 : (sum1 == 0 || addendA1 > sum1 - 1))
      revert AddOverflow(addendA0, addendA1, addendB0, addendB1);
  }

  /// @dev Calculates the difference of two uint512 numbers.
  /// @notice Reverts on underflow.
  /// @param minuend0 The least significant part of minuend.
  /// @param minuend1 The most significant part of minuend.
  /// @param subtrahend0 The least significant part of subtrahend.
  /// @param subtrahend1 The most significant part of subtrahend.
  /// @return difference0 The least significant part of difference.
  /// @return difference1 The most significant part of difference.
  function sub512(
    uint256 minuend0,
    uint256 minuend1,
    uint256 subtrahend0,
    uint256 subtrahend1
  ) internal pure returns (uint256 difference0, uint256 difference1) {
    assembly {
      difference0 := sub(minuend0, subtrahend0)
      difference1 := sub(sub(minuend1, subtrahend1), lt(minuend0, subtrahend0))
    }

    if (subtrahend1 > minuend1 || (subtrahend1 == minuend1 && subtrahend0 > minuend0))
      revert SubUnderflow(minuend0, minuend1, subtrahend0, subtrahend1);
  }

  /// @dev Calculate the product of two uint256 numbers that may result to uint512 product.
  /// @notice Can never overflow.
  /// @param multiplicand The multiplicand.
  /// @param multiplier The multiplier.
  /// @return product0 The least significant part of product.
  /// @return product1 The most significant part of product.
  function mul512(uint256 multiplicand, uint256 multiplier) internal pure returns (uint256 product0, uint256 product1) {
    assembly {
      let mm := mulmod(multiplicand, multiplier, not(0))
      product0 := mul(multiplicand, multiplier)
      product1 := sub(sub(mm, product0), lt(mm, product0))
    }
  }

  /// @dev Divide 2 to 256 power by the divisor.
  /// @dev Rounds down the result.
  /// @notice Reverts when divide by zero.
  /// @param divisor The divisor.
  /// @return quotient The quotient.
  function div256(uint256 divisor) private pure returns (uint256 quotient) {
    if (divisor == 0) revert Math.DivideByZero();
    assembly {
      quotient := add(div(sub(0, divisor), divisor), 1)
    }
  }

  /// @dev Compute 2 to 256 power modulo the given value.
  /// @notice Reverts when modulo by zero.
  /// @param value The given value.
  /// @return result The result.
  function mod256(uint256 value) private pure returns (uint256 result) {
    if (value == 0) revert ModuloByZero();
    assembly {
      result := mod(sub(0, value), value)
    }
  }

  /// @dev Divide a uint512 number by uint256 number to return a uint512 number.
  /// @dev Rounds down the result.
  /// @param dividend0 The least significant part of dividend.
  /// @param dividend1 The most significant part of dividend.
  /// @param divisor The divisor.
  /// @param quotient0 The least significant part of quotient.
  /// @param quotient1 The most significant part of quotient.
  function div512(
    uint256 dividend0,
    uint256 dividend1,
    uint256 divisor
  ) private pure returns (uint256 quotient0, uint256 quotient1) {
    if (dividend1 == 0) quotient0 = dividend0.div(divisor, false);
    else {
      uint256 q = div256(divisor);
      uint256 r = mod256(divisor);
      while (dividend1 != 0) {
        (uint256 t0, uint256 t1) = mul512(dividend1, q);
        (quotient0, quotient1) = add512(quotient0, quotient1, t0, t1);
        (t0, t1) = mul512(dividend1, r);
        (dividend0, dividend1) = add512(t0, t1, dividend0, 0);
      }
      (quotient0, quotient1) = add512(quotient0, quotient1, dividend0.div(divisor, false), 0);
    }
  }

  /// @dev Divide a uint512 number by a uint256 number.
  /// @dev Reverts when result is greater than uint256.
  /// @notice Skips div512 if dividend1 is zero.
  /// @param dividend0 The least significant part of dividend.
  /// @param dividend1 The most significant part of dividend.
  /// @param divisor The divisor.
  /// @param roundUp Round up the result when true. Round down if false.
  /// @param quotient The quotient.
  function div512To256(
    uint256 dividend0,
    uint256 dividend1,
    uint256 divisor,
    bool roundUp
  ) internal pure returns (uint256 quotient) {
    uint256 quotient1;
    (quotient, quotient1) = div512(dividend0, dividend1, divisor);

    if (quotient1 != 0) revert DivOverflow(dividend0, dividend1, divisor);

    if (roundUp) {
      (uint256 productA0, uint256 productA1) = mul512(quotient, divisor);
      if (dividend1 > productA1 || dividend0 > productA0) quotient++;
    }
  }

  /// @dev Divide a uint512 number by a uint256 number.
  /// @notice Skips div512 if dividend1 is zero.
  /// @param dividend0 The least significant part of dividend.
  /// @param dividend1 The most significant part of dividend.
  /// @param divisor The divisor.
  /// @param roundUp Round up the result when true. Round down if false.
  /// @param quotient0 The least significant part of quotient.
  /// @param quotient1 The most significant part of quotient.
  function div512(
    uint256 dividend0,
    uint256 dividend1,
    uint256 divisor,
    bool roundUp
  ) internal pure returns (uint256 quotient0, uint256 quotient1) {
    (quotient0, quotient1) = div512(dividend0, dividend1, divisor);

    if (roundUp) {
      (uint256 productA0, uint256 productA1) = mul512(quotient0, divisor);
      productA1 += (quotient1 * divisor);
      if (dividend1 > productA1 || dividend0 > productA0) {
        if (quotient0 == type(uint256).max) {
          quotient0 = 0;
          quotient1++;
        } else quotient0++;
      }
    }
  }

  /// @dev Multiply two uint256 number then divide it by a uint256 number.
  /// @notice Skips mulDiv if product of multiplicand and multiplier is uint256 number.
  /// @dev Reverts when result is greater than uint256.
  /// @param multiplicand The multiplicand.
  /// @param multiplier The multiplier.
  /// @param divisor The divisor.
  /// @param roundUp Round up the result when true. Round down if false.
  /// @return result The result.
  function mulDiv(
    uint256 multiplicand,
    uint256 multiplier,
    uint256 divisor,
    bool roundUp
  ) internal pure returns (uint256 result) {
    (uint256 product0, uint256 product1) = mul512(multiplicand, multiplier);

    // Handle non-overflow cases, 256 by 256 division
    if (product1 == 0) return result = product0.div(divisor, roundUp);

    // Make sure the result is less than 2**256.
    // Also prevents divisor == 0
    if (divisor <= product1) revert MulDivOverflow(multiplicand, multiplier, divisor);

    unchecked {
      ///////////////////////////////////////////////
      // 512 by 256 division.
      ///////////////////////////////////////////////

      // Make division exact by subtracting the remainder from [product1 product0]
      // Compute remainder using mulmod
      uint256 remainder;
      assembly {
        remainder := mulmod(multiplicand, multiplier, divisor)
      }
      // Subtract 256 bit number from 512 bit number
      assembly {
        product1 := sub(product1, gt(remainder, product0))
        product0 := sub(product0, remainder)
      }

      // Factor powers of two out of divisor
      // Compute largest power of two divisor of divisor.
      // Always >= 1.
      uint256 twos;
      twos = (0 - divisor) & divisor;
      // Divide denominator by power of two
      assembly {
        divisor := div(divisor, twos)
      }

      // Divide [product1 product0] by the factors of two
      assembly {
        product0 := div(product0, twos)
      }
      // Shift in bits from product1 into product0. For this we need
      // to flip `twos` such that it is 2**256 / twos.
      // If twos is zero, then it becomes one
      assembly {
        twos := add(div(sub(0, twos), twos), 1)
      }
      product0 |= product1 * twos;

      // Invert divisor mod 2**256
      // Now that divisor is an odd number, it has an inverse
      // modulo 2**256 such that divisor * inv = 1 mod 2**256.
      // Compute the inverse by starting with a seed that is correct
      // correct for four bits. That is, divisor * inv = 1 mod 2**4
      uint256 inv;
      inv = (3 * divisor) ^ 2;

      // Now use Newton-Raphson iteration to improve the precision.
      // Thanks to Hensel's lifting lemma, this also works in modular
      // arithmetic, doubling the correct bits in each step.
      inv *= 2 - divisor * inv; // inverse mod 2**8
      inv *= 2 - divisor * inv; // inverse mod 2**16
      inv *= 2 - divisor * inv; // inverse mod 2**32
      inv *= 2 - divisor * inv; // inverse mod 2**64
      inv *= 2 - divisor * inv; // inverse mod 2**128
      inv *= 2 - divisor * inv; // inverse mod 2**256

      // Because the division is now exact we can divide by multiplying
      // with the modular inverse of divisor. This will give us the
      // correct result modulo 2**256. Since the preconditions guarantee
      // that the outcome is less than 2**256, this is the final result.
      // We don't need to compute the high bits of the result and product1
      // is no longer required.
      result = product0 * inv;
    }

    if (roundUp && mulmod(multiplicand, multiplier, divisor) != 0) result++;
  }

  /// @dev Get the square root of a uint512 number.
  /// @param value0 The least significant of the number.
  /// @param value1 The most significant of the number.
  /// @param roundUp Round up the result when true. Round down if false.
  /// @return result The result.
  function sqrt512(uint256 value0, uint256 value1, bool roundUp) internal pure returns (uint256 result) {
    if (value1 == 0) result = value0.sqrt(roundUp);
    else {
      uint256 estimate = sqrt512Estimate(value0, value1, type(uint256).max);
      result = type(uint256).max;
      while (estimate < result) {
        result = estimate;
        estimate = sqrt512Estimate(value0, value1, estimate);
      }

      if (roundUp) {
        (uint256 product0, uint256 product1) = mul512(result, result);
        if (value1 > product1 || value0 > product0) result++;
      }
    }
  }

  /// @dev An iterative process of getting sqrt512 following Newtonian method.
  /// @param value0 The least significant of the number.
  /// @param value1 The most significant of the number.
  /// @param currentEstimate The current estimate of the iteration.
  /// @param estimate The new estimate of the iteration.
  function sqrt512Estimate(
    uint256 value0,
    uint256 value1,
    uint256 currentEstimate
  ) private pure returns (uint256 estimate) {
    uint256 r0 = div512To256(value0, value1, currentEstimate, false);
    uint256 r1;
    (r0, r1) = add512(r0, 0, currentEstimate, 0);
    estimate = div512To256(r0, r1, 2, false);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @title Library for math related utils
/// @author Timeswap Labs
library Math {
  /// @dev Reverts when divide by zero.
  error DivideByZero();
  error Overflow();

  /// @dev Add two uint256.
  /// @notice May overflow.
  /// @param addend1 The first addend.
  /// @param addend2 The second addend.
  /// @return sum The sum.
  function unsafeAdd(uint256 addend1, uint256 addend2) internal pure returns (uint256 sum) {
    unchecked {
      sum = addend1 + addend2;
    }
  }

  /// @dev Subtract two uint256.
  /// @notice May underflow.
  /// @param minuend The minuend.
  /// @param subtrahend The subtrahend.
  /// @return difference The difference.
  function unsafeSub(uint256 minuend, uint256 subtrahend) internal pure returns (uint256 difference) {
    unchecked {
      difference = minuend - subtrahend;
    }
  }

  /// @dev Multiply two uint256.
  /// @notice May overflow.
  /// @param multiplicand The multiplicand.
  /// @param multiplier The multiplier.
  /// @return product The product.
  function unsafeMul(uint256 multiplicand, uint256 multiplier) internal pure returns (uint256 product) {
    unchecked {
      product = multiplicand * multiplier;
    }
  }

  /// @dev Divide two uint256.
  /// @notice Reverts when divide by zero.
  /// @param dividend The dividend.
  /// @param divisor The divisor.
  //// @param roundUp Round up the result when true. Round down if false.
  /// @return quotient The quotient.
  function div(uint256 dividend, uint256 divisor, bool roundUp) internal pure returns (uint256 quotient) {
    quotient = dividend / divisor;

    if (roundUp && dividend % divisor != 0) quotient++;
  }

  /// @dev Shift right a uint256 number.
  /// @param dividend The dividend.
  /// @param divisorBit The divisor in bits.
  /// @param roundUp True if ceiling the result. False if floor the result.
  /// @return quotient The quotient.
  function shr(uint256 dividend, uint8 divisorBit, bool roundUp) internal pure returns (uint256 quotient) {
    quotient = dividend >> divisorBit;

    if (roundUp && dividend % (1 << divisorBit) != 0) quotient++;
  }

  /// @dev Gets the square root of a value.
  /// @param value The value being square rooted.
  /// @param roundUp Round up the result when true. Round down if false.
  /// @return result The resulting value of the square root.
  function sqrt(uint256 value, bool roundUp) internal pure returns (uint256 result) {
    if (value == type(uint256).max) return result = type(uint128).max;
    if (value == 0) return 0;
    unchecked {
      uint256 estimate = (value + 1) >> 1;
      result = value;
      while (estimate < result) {
        result = estimate;
        estimate = (value / estimate + estimate) >> 1;
      }
    }

    if (roundUp && result * result < value) result++;
  }

  /// @dev Gets the min of two uint256 number.
  /// @param value1 The first value to be compared.
  /// @param value2 The second value to be compared.
  /// @return result The min result.
  function min(uint256 value1, uint256 value2) internal pure returns (uint256 result) {
    return value1 < value2 ? value1 : value2;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {FullMath} from "./FullMath.sol";

/// @title library for converting strike prices.
/// @dev When strike is greater than uint128, the base token is denominated as token0 (which is the smaller address token).
/// @dev When strike is uint128, the base token is denominated as token1 (which is the larger address).
library StrikeConversion {
  /// @dev When zeroToOne, converts a number in multiple of strike.
  /// @dev When oneToZero, converts a number in multiple of 1 / strike.
  /// @param amount The amount to be converted.
  /// @param strike The strike multiple conversion.
  /// @param zeroToOne ZeroToOne if it is true. OneToZero if it is false.
  /// @param roundUp Round up the result when true. Round down if false.
  function convert(uint256 amount, uint256 strike, bool zeroToOne, bool roundUp) internal pure returns (uint256) {
    return
      zeroToOne
        ? FullMath.mulDiv(amount, strike, uint256(1) << 128, roundUp)
        : FullMath.mulDiv(amount, uint256(1) << 128, strike, roundUp);
  }

  /// @dev When toOne, converts a base denomination to token1 denomination.
  /// @dev When toZero, converts a base denomination to token0 denomination.
  /// @param amount The amount ot be converted. Token0 amount when zeroToOne. Token1 amount when oneToZero.
  /// @param strike The strike multiple conversion.
  /// @param toOne ToOne if it is true, ToZero if it is false.
  /// @param roundUp Round up the result when true. Round down if false.
  function turn(uint256 amount, uint256 strike, bool toOne, bool roundUp) internal pure returns (uint256) {
    return
      strike > type(uint128).max
        ? (toOne ? convert(amount, strike, true, roundUp) : amount)
        : (toOne ? amount : convert(amount, strike, false, roundUp));
  }

  /// @dev Combine and add token0Amount and token1Amount into base token amount.
  /// @param amount0 The token0 amount to be combined.
  /// @param amount1 The token1 amount to be combined.
  /// @param strike The strike multiple conversion.
  /// @param roundUp Round up the result when true. Round down if false.
  function combine(uint256 amount0, uint256 amount1, uint256 strike, bool roundUp) internal pure returns (uint256) {
    return
      strike > type(uint128).max
        ? amount0 + convert(amount1, strike, false, roundUp)
        : amount1 + convert(amount0, strike, true, roundUp);
  }

  /// @dev When zeroToOne, given a larger base amount, and token0 amount, get the difference token1 amount.
  /// @dev When oneToZero, given a larger base amount, and toekn1 amount, get the difference token0 amount.
  /// @param base The larger base amount.
  /// @param amount The token0 amount when zeroToOne, the token1 amount when oneToZero.
  /// @param strike The strike multiple conversion.
  /// @param zeroToOne ZeroToOne if it is true. OneToZero if it is false.
  /// @param roundUp Round up the result when true. Round down if false.
  function dif(
    uint256 base,
    uint256 amount,
    uint256 strike,
    bool zeroToOne,
    bool roundUp
  ) internal pure returns (uint256) {
    return
      strike > type(uint128).max
        ? (zeroToOne ? convert(base - amount, strike, true, roundUp) : base - convert(amount, strike, false, !roundUp))
        : (zeroToOne ? base - convert(amount, strike, true, !roundUp) : convert(base - amount, strike, false, roundUp));
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @dev The three type of native token positions.
/// @dev Long0 is denominated as the underlying Token0.
/// @dev Long1 is denominated as the underlying Token1.
/// @dev When strike greater than uint128 then Short is denominated as Token0 (the base token denomination).
/// @dev When strike is uint128 then Short is denominated as Token1 (the base token denomination).
enum TimeswapV2OptionPosition {
  Long0,
  Long1,
  Short
}

/// @title library for position utils
/// @author Timeswap Labs
/// @dev Helper functions for the TimeswapOptionPosition enum.
library PositionLibrary {
  /// @dev Reverts when the given type of position is invalid.
  error InvalidPosition();

  /// @dev Checks that the position input is correct.
  /// @param position The position input.
  function check(TimeswapV2OptionPosition position) internal pure {
    if (uint256(position) >= 3) revert InvalidPosition();
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @dev The different input for the mint transaction.
enum TimeswapV2OptionMint {
  GivenTokensAndLongs,
  GivenShorts
}

/// @dev The different input for the burn transaction.
enum TimeswapV2OptionBurn {
  GivenTokensAndLongs,
  GivenShorts
}

/// @dev The different input for the swap transaction.
enum TimeswapV2OptionSwap {
  GivenToken0AndLong0,
  GivenToken1AndLong1
}

/// @dev The different input for the collect transaction.
enum TimeswapV2OptionCollect {
  GivenShort,
  GivenToken0,
  GivenToken1
}

/// @title library for transaction checks
/// @author Timeswap Labs
/// @dev Helper functions for the all enums in this module.
library TransactionLibrary {
  /// @dev Reverts when the given type of transaction is invalid.
  error InvalidTransaction();

  /// @dev checks that the given input is correct.
  /// @param transaction the mint transaction input.
  function check(TimeswapV2OptionMint transaction) internal pure {
    if (uint256(transaction) >= 2) revert InvalidTransaction();
  }

  /// @dev checks that the given input is correct.
  /// @param transaction the burn transaction input.
  function check(TimeswapV2OptionBurn transaction) internal pure {
    if (uint256(transaction) >= 2) revert InvalidTransaction();
  }

  /// @dev checks that the given input is correct.
  /// @param transaction the swap transaction input.
  function check(TimeswapV2OptionSwap transaction) internal pure {
    if (uint256(transaction) >= 2) revert InvalidTransaction();
  }

  /// @dev checks that the given input is correct.
  /// @param transaction the collect transaction input.
  function check(TimeswapV2OptionCollect transaction) internal pure {
    if (uint256(transaction) >= 3) revert InvalidTransaction();
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {TimeswapV2OptionPosition} from "../enums/Position.sol";
import {TimeswapV2OptionMintParam, TimeswapV2OptionBurnParam, TimeswapV2OptionSwapParam, TimeswapV2OptionCollectParam} from "../structs/Param.sol";
import {StrikeAndMaturity} from "../structs/StrikeAndMaturity.sol";

/// @title An interface for a contract that deploys Timeswap V2 Option pair contracts
/// @notice A Timeswap V2 Option pair facilitates option mechanics between any two assets that strictly conform
/// to the ERC20 specification.
interface ITimeswapV2Option {
  /* ===== EVENT ===== */

  /// @dev Emits when a position is transferred.
  /// @param strike The strike ratio of token1 per token0 of the position.
  /// @param maturity The maturity of the position.
  /// @param from The address of the caller of the transferPosition function.
  /// @param to The address of the recipient of the position.
  /// @param position The type of position transferred. More information in the Position module.
  /// @param amount The amount of balance transferred.
  event TransferPosition(
    uint256 indexed strike,
    uint256 indexed maturity,
    address from,
    address to,
    TimeswapV2OptionPosition position,
    uint256 amount
  );

  /// @dev Emits when a mint transaction is called.
  /// @param strike The strike ratio of token1 per token0 of the option.
  /// @param maturity The maturity of the option.
  /// @param caller The address of the caller of the mint function.
  /// @param long0To The address of the recipient of long token0 position.
  /// @param long1To The address of the recipient of long token1 position.
  /// @param shortTo The address of the recipient of short position.
  /// @param token0AndLong0Amount The amount of token0 deposited and long0 minted.
  /// @param token1AndLong1Amount The amount of token1 deposited and long1 minted.
  /// @param shortAmount The amount of short minted.
  event Mint(
    uint256 indexed strike,
    uint256 indexed maturity,
    address indexed caller,
    address long0To,
    address long1To,
    address shortTo,
    uint256 token0AndLong0Amount,
    uint256 token1AndLong1Amount,
    uint256 shortAmount
  );

  /// @dev Emits when a burn transaction is called.
  /// @param strike The strike ratio of token1 per token0 of the option.
  /// @param maturity The maturity of the option.
  /// @param caller The address of the caller of the mint function.
  /// @param token0To The address of the recipient of token0.
  /// @param token1To The address of the recipient of token1.
  /// @param token0AndLong0Amount The amount of token0 withdrawn and long0 burnt.
  /// @param token1AndLong1Amount The amount of token1 withdrawn and long1 burnt.
  /// @param shortAmount The amount of short burnt.
  event Burn(
    uint256 indexed strike,
    uint256 indexed maturity,
    address indexed caller,
    address token0To,
    address token1To,
    uint256 token0AndLong0Amount,
    uint256 token1AndLong1Amount,
    uint256 shortAmount
  );

  /// @dev Emits when a swap transaction is called.
  /// @param strike The strike ratio of token1 per token0 of the option.
  /// @param maturity The maturity of the option.
  /// @param caller The address of the caller of the mint function.
  /// @param tokenTo The address of the recipient of token0 or token1.
  /// @param longTo The address of the recipient of long token0 or long token1.
  /// @param isLong0toLong1 The direction of the swap. More information in the Transaction module.
  /// @param token0AndLong0Amount If the direction is from long0 to long1, the amount of token0 withdrawn and long0 burnt.
  /// If the direction is from long1 to long0, the amount of token0 deposited and long0 minted.
  /// @param token1AndLong1Amount If the direction is from long0 to long1, the amount of token1 deposited and long1 minted.
  /// If the direction is from long1 to long0, the amount of token1 withdrawn and long1 burnt.
  event Swap(
    uint256 indexed strike,
    uint256 indexed maturity,
    address indexed caller,
    address tokenTo,
    address longTo,
    bool isLong0toLong1,
    uint256 token0AndLong0Amount,
    uint256 token1AndLong1Amount
  );

  /// @dev Emits when a collect transaction is called.
  /// @param strike The strike ratio of token1 per token0 of the option.
  /// @param maturity The maturity of the option.
  /// @param caller The address of the caller of the mint function.
  /// @param token0To The address of the recipient of token0.
  /// @param token1To The address of the recipient of token1.
  /// @param long0AndToken0Amount The amount of token0 withdrawn.
  /// @param long1AndToken1Amount The amount of token1 withdrawn.
  /// @param shortAmount The amount of short burnt.
  event Collect(
    uint256 indexed strike,
    uint256 indexed maturity,
    address indexed caller,
    address token0To,
    address token1To,
    uint256 long0AndToken0Amount,
    uint256 long1AndToken1Amount,
    uint256 shortAmount
  );

  /* ===== VIEW ===== */

  /// @dev Returns the factory address that deployed this contract.
  function optionFactory() external view returns (address);

  /// @dev Returns the first ERC20 token address of the pair.
  function token0() external view returns (address);

  /// @dev Returns the second ERC20 token address of the pair.
  function token1() external view returns (address);

  /// @dev Get the strike and maturity of the option in the option enumeration list.
  /// @param id The chosen index.
  function getByIndex(uint256 id) external view returns (StrikeAndMaturity memory);

  /// @dev Number of options being interacted.
  function numberOfOptions() external view returns (uint256);

  /// @dev Returns the total position of the option.
  /// @param strike The strike ratio of token1 per token0 of the position.
  /// @param maturity The maturity of the position.
  /// @param position The type of position inquired. More information in the Position module.
  /// @return balance The total position.
  function totalPosition(
    uint256 strike,
    uint256 maturity,
    TimeswapV2OptionPosition position
  ) external view returns (uint256 balance);

  /// @dev Returns the position of an owner of the option.
  /// @param strike The strike ratio of token1 per token0 of the position.
  /// @param maturity The maturity of the position.
  /// @param owner The address of the owner of the position.
  /// @param position The type of position inquired. More information in the Position module.
  /// @return balance The user position.
  function positionOf(
    uint256 strike,
    uint256 maturity,
    address owner,
    TimeswapV2OptionPosition position
  ) external view returns (uint256 balance);

  /* ===== UPDATE ===== */

  /// @dev Transfer position to another address.
  /// @param strike The strike ratio of token1 per token0 of the position.
  /// @param maturity The maturity of the position.
  /// @param to The address of the recipient of the position.
  /// @param position The type of position transferred. More information in the Position module.
  /// @param amount The amount of balance transferred.
  function transferPosition(
    uint256 strike,
    uint256 maturity,
    address to,
    TimeswapV2OptionPosition position,
    uint256 amount
  ) external;

  /// @dev Mint position.
  /// Mint long token0 position when token0 is deposited.
  /// Mint long token1 position when token1 is deposited.
  /// @dev Can only be called before the maturity of the pool.
  /// @param param The parameters for the mint function.
  /// @return token0AndLong0Amount The amount of token0 deposited and long0 minted.
  /// @return token1AndLong1Amount The amount of token1 deposited and long1 minted.
  /// @return shortAmount The amount of short minted.
  /// @return data The additional data return.
  function mint(
    TimeswapV2OptionMintParam calldata param
  )
    external
    returns (uint256 token0AndLong0Amount, uint256 token1AndLong1Amount, uint256 shortAmount, bytes memory data);

  /// @dev Burn short position.
  /// Withdraw token0, when long token0 is burnt.
  /// Withdraw token1, when long token1 is burnt.
  /// @dev Can only be called before the maturity of the pool.
  /// @param param The parameters for the burn function.
  /// @return token0AndLong0Amount The amount of token0 withdrawn and long0 burnt.
  /// @return token1AndLong1Amount The amount of token1 withdrawn and long1 burnt.
  /// @return shortAmount The amount of short burnt.
  function burn(
    TimeswapV2OptionBurnParam calldata param
  )
    external
    returns (uint256 token0AndLong0Amount, uint256 token1AndLong1Amount, uint256 shortAmount, bytes memory data);

  /// @dev If the direction is from long token0 to long token1, burn long token0 and mint equivalent long token1,
  /// also deposit token1 and withdraw token0.
  /// If the direction is from long token1 to long token0, burn long token1 and mint equivalent long token0,
  /// also deposit token0 and withdraw token1.
  /// @dev Can only be called before the maturity of the pool.
  /// @param param The parameters for the swap function.
  /// @return token0AndLong0Amount If direction is Long0ToLong1, the amount of token0 withdrawn and long0 burnt.
  /// If direction is Long1ToLong0, the amount of token0 deposited and long0 minted.
  /// @return token1AndLong1Amount If direction is Long0ToLong1, the amount of token1 deposited and long1 minted.
  /// If direction is Long1ToLong0, the amount of token1 withdrawn and long1 burnt.
  /// @return data The additional data return.
  function swap(
    TimeswapV2OptionSwapParam calldata param
  ) external returns (uint256 token0AndLong0Amount, uint256 token1AndLong1Amount, bytes memory data);

  /// @dev Burn short position, withdraw token0 and token1.
  /// @dev Can only be called after the maturity of the pool.
  /// @param param The parameters for the collect function.
  /// @return token0Amount The amount of token0 withdrawn.
  /// @return token1Amount The amount of token1 withdrawn.
  /// @return shortAmount The amount of short burnt.
  function collect(
    TimeswapV2OptionCollectParam calldata param
  ) external returns (uint256 token0Amount, uint256 token1Amount, uint256 shortAmount, bytes memory data);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @title The interface for the contract that deploys Timeswap V2 Option pair contracts
/// @notice The Timeswap V2 Option Factory facilitates creation of Timeswap V2 Options pair.
interface ITimeswapV2OptionFactory {
  /* ===== EVENT ===== */

  /// @dev Emits when a new Timeswap V2 Option contract is created.
  /// @param caller The address of the caller of create function.
  /// @param token0 The first ERC20 token address of the pair.
  /// @param token1 The second ERC20 token address of the pair.
  /// @param optionPair The address of the Timeswap V2 Option contract created.
  event Create(address indexed caller, address indexed token0, address indexed token1, address optionPair);

  /* ===== VIEW ===== */

  /// @dev Returns the address of a Timeswap V2 Option.
  /// @dev Returns a zero address if the Timeswap V2 Option does not exist.
  /// @notice The token0 address must be smaller than token1 address.
  /// @param token0 The first ERC20 token address of the pair.
  /// @param token1 The second ERC20 token address of the pair.
  /// @return optionPair The address of the Timeswap V2 Option contract or a zero address.
  function get(address token0, address token1) external view returns (address optionPair);

  /// @dev Get the address of the option pair in the option pair enumeration list.
  /// @param id The chosen index.
  function getByIndex(uint256 id) external view returns (address optionPair);

  /// @dev The number of option pairs deployed.
  function numberOfPairs() external view returns (uint256);

  /* ===== UPDATE ===== */

  /// @dev Creates a Timeswap V2 Option based on pair parameters.
  /// @dev Cannot create a duplicate Timeswap V2 Option with the same pair parameters.
  /// @notice The token0 address must be smaller than token1 address.
  /// @param token0 The first ERC20 token address of the pair.
  /// @param token1 The second ERC20 token address of the pair.
  /// @param optionPair The address of the Timeswap V2 Option contract created.
  function create(address token0, address token1) external returns (address optionPair);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {Error} from "@timeswap-labs/v2-library/contracts/Error.sol";

import {OptionPairLibrary} from "./OptionPair.sol";

import {ITimeswapV2OptionFactory} from "../interfaces/ITimeswapV2OptionFactory.sol";

/// @title library for option utils
/// @author Timeswap Labs
library OptionFactoryLibrary {
  using OptionPairLibrary for address;

  /// @dev reverts if the factory is the zero address.
  error ZeroFactoryAddress();

  /// @dev check if the factory address is not zero.
  /// @param optionFactory The factory address.
  function checkNotZeroFactory(address optionFactory) internal pure {
    if (optionFactory == address(0)) revert ZeroFactoryAddress();
  }

  /// @dev Helper function to get the option pair address.
  /// @param optionFactory The address of the option factory.
  /// @param token0 The smaller ERC20 address of the pair.
  /// @param token1 The larger ERC20 address of the pair.
  /// @return optionPair The result option pair address.
  function get(address optionFactory, address token0, address token1) internal view returns (address optionPair) {
    optionPair = ITimeswapV2OptionFactory(optionFactory).get(token0, token1);
  }

  /// @dev Helper function to get the option pair address.
  /// @notice reverts when the option pair does not exist.
  /// @param optionFactory The address of the option factory.
  /// @param token0 The smaller ERC20 address of the pair.
  /// @param token1 The larger ERC20 address of the pair.
  /// @return optionPair The result option pair address.
  function getWithCheck(
    address optionFactory,
    address token0,
    address token1
  ) internal view returns (address optionPair) {
    optionPair = get(optionFactory, token0, token1);
    if (optionPair == address(0)) Error.zeroAddress();
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @title library for optionPair utils
/// @author Timeswap Labs
library OptionPairLibrary {
  /// @dev Reverts when option address is zero.
  error ZeroOptionAddress();

  /// @dev Reverts when the pair has incorrect format.
  /// @param token0 The first ERC20 token address of the pair.
  /// @param token1 The second ERC20 token address of the pair.
  error InvalidOptionPair(address token0, address token1);

  /// @dev Reverts when the Timeswap V2 Option already exist.
  /// @param token0 The first ERC20 token address of the pair.
  /// @param token1 The second ERC20 token address of the pair.
  /// @param optionPair The address of the existed Pair contract.
  error OptionPairAlreadyExisted(address token0, address token1, address optionPair);

  /// @dev Checks if option address is not zero.
  /// @param optionPair The option pair address being inquired.
  function checkNotZeroAddress(address optionPair) internal pure {
    if (optionPair == address(0)) revert ZeroOptionAddress();
  }

  /// @dev Check if the pair tokens is in correct format.
  /// @notice Reverts if token0 is greater than or equal token1.
  /// @param token0 The first ERC20 token address of the pair.
  /// @param token1 The second ERC20 token address of the pair.
  function checkCorrectFormat(address token0, address token1) internal pure {
    if (token0 >= token1) revert InvalidOptionPair(token0, token1);
  }

  /// @dev Check if the pair already existed.
  /// @notice Reverts if the pair is not a zero address.
  /// @param token0 The first ERC20 token address of the pair.
  /// @param token1 The second ERC20 token address of the pair.
  /// @param optionPair The address of the existed Pair contract.
  function checkDoesNotExist(address token0, address token1, address optionPair) internal pure {
    if (optionPair != address(0)) revert OptionPairAlreadyExisted(token0, token1, optionPair);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @dev Parameter for the mint callback.
/// @param strike The strike ratio of token1 per token0 of the option.
/// @param maturity The maturity of the option.
/// @param token0AndLong0Amount The token0 amount to be deposited and the long0 amount minted.
/// @param token1AndLong1Amount The token1 amount to be deposited and the long1 amount minted.
/// @param shortAmount The short amount minted.
/// @param data The bytes code data sent to the callback.
struct TimeswapV2OptionMintCallbackParam {
  uint256 strike;
  uint256 maturity;
  uint256 token0AndLong0Amount;
  uint256 token1AndLong1Amount;
  uint256 shortAmount;
  bytes data;
}

/// @dev Parameter for the burn callback.
/// @param strike The strike ratio of token1 per token0 of the option.
/// @param maturity The maturity of the option.
/// @param token0AndLong0Amount The token0 amount to be withdrawn and the long0 amount burnt.
/// @param token1AndLong1Amount The token1 amount to be withdrawn and the long1 amount burnt.
/// @param shortAmount The short amount burnt.
/// @param data The bytes code data sent to the callback.
struct TimeswapV2OptionBurnCallbackParam {
  uint256 strike;
  uint256 maturity;
  uint256 token0AndLong0Amount;
  uint256 token1AndLong1Amount;
  uint256 shortAmount;
  bytes data;
}

/// @dev Parameter for the swap callback.
/// @param strike The strike ratio of token1 per token0 of the option.
/// @param maturity The maturity of the option.
/// @param isLong0ToLong1 True when swapping long0 for long1. False when swapping long1 for long0.
/// @param token0AndLong0Amount If isLong0ToLong1 is true, the amount of long0 burnt and token0 to be withdrawn.
/// If isLong0ToLong1 is false, the amount of long0 minted and token0 to be deposited.
/// @param token1AndLong1Amount If isLong0ToLong1 is true, the amount of long1 withdrawn and token0 to be deposited.
/// If isLong0ToLong1 is false, the amount of long1 burnt and token1 to be withdrawn.
/// @param data The bytes code data sent to the callback.
struct TimeswapV2OptionSwapCallbackParam {
  uint256 strike;
  uint256 maturity;
  bool isLong0ToLong1;
  uint256 token0AndLong0Amount;
  uint256 token1AndLong1Amount;
  bytes data;
}

/// @dev Parameter for the collect callback.
/// @param strike The strike ratio of token1 per token0 of the option.
/// @param maturity The maturity of the option.
/// @param token0Amount The token0 amount to be withdrawn.
/// @param token1Amount The token1 amount to be withdrawn.
/// @param shortAmount The short amount burnt.
/// @param data The bytes code data sent to the callback.
struct TimeswapV2OptionCollectCallbackParam {
  uint256 strike;
  uint256 maturity;
  uint256 token0Amount;
  uint256 token1Amount;
  uint256 shortAmount;
  bytes data;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {Error} from "@timeswap-labs/v2-library/contracts/Error.sol";

import {TimeswapV2OptionMint, TimeswapV2OptionBurn, TimeswapV2OptionSwap, TimeswapV2OptionCollect, TransactionLibrary} from "../enums/Transaction.sol";

/// @dev The parameter to call the mint function.
/// @param strike The strike of the option.
/// @param maturity The maturity of the option.
/// @param long0To The recipient of long0 positions.
/// @param long1To The recipient of long1 positions.
/// @param shortTo The recipient of short positions.
/// @param transaction The type of mint transaction, more information in Transaction module.
/// @param amount0 If transaction is givenTokensAndLongs, the amount of token0 deposited, and amount of long0 position minted.
/// If transaction is givenShorts, the amount of short minted, where the equivalent strike converted amount is long0 positions.
/// @param amount1 If transaction is givenTokensAndLongs, the amount of token1 deposited, and amount of long1 position minted.
/// If transaction is givenShorts, the amount of short minted, where the equivalent strike converted amount is long1 positions.
/// @param data The data to be sent to the function, which will go to the mint callback.
struct TimeswapV2OptionMintParam {
  uint256 strike;
  uint256 maturity;
  address long0To;
  address long1To;
  address shortTo;
  TimeswapV2OptionMint transaction;
  uint256 amount0;
  uint256 amount1;
  bytes data;
}

/// @dev The parameter to call the burn function.
/// @param strike The strike of the option.
/// @param maturity The maturity of the option.
/// @param token0To The recipient of token0 withdrawn.
/// @param token1To The recipient of token1 withdrawn.
/// @param transaction The type of burn transaction, more information in Transaction module.
/// @param amount0 If transaction is givenTokensAndLongs, the amount of token0 withdrawn, and amount of long0 position burnt.
/// If transaction is givenShorts, the amount of short burnt, where the equivalent strike converted amount is long0 positions.
/// @param amount1 If transaction is givenTokensAndLongs, the amount of token1 withdrawn, and amount of long1 position burnt.
/// If transaction is givenShorts, the amount of short burnt, where the equivalent strike converted amount is long1 positions.
/// @param data The data to be sent to the function, which will go to the burn callback.
/// @notice If data length is zero, skips the callback.
struct TimeswapV2OptionBurnParam {
  uint256 strike;
  uint256 maturity;
  address token0To;
  address token1To;
  TimeswapV2OptionBurn transaction;
  uint256 amount0;
  uint256 amount1;
  bytes data;
}

/// @dev The parameter to call the swap function.
/// @param strike The strike of the option.
/// @param maturity The maturity of the option.
/// @param tokenTo The recipient of token0 when isLong0ToLong1 or token1 when isLong1ToLong0.
/// @param longTo The recipient of long1 positions when isLong0ToLong1 or long0 when isLong1ToLong0.
/// @param isLong0ToLong1 Transform long0 positions to long1 positions when true. Transform long1 positions to long0 positions when false.
/// @param transaction The type of swap transaction, more information in Transaction module.
/// @param amount If isLong0ToLong1 and transaction is GivenToken0AndLong0, this is the amount of token0 withdrawn, and the amount of long0 position burnt.
/// If isLong1ToLong0 and transaction is GivenToken0AndLong0, this is the amount of token0 to be deposited, and the amount of long0 position minted.
/// If isLong0ToLong1 and transaction is GivenToken1AndLong1, this is the amount of token1 to be deposited, and the amount of long1 position minted.
/// If isLong1ToLong0 and transaction is GivenToken1AndLong1, this is the amount of token1 withdrawn, and the amount of long1 position burnt.
/// @param data The data to be sent to the function, which will go to the swap callback.
struct TimeswapV2OptionSwapParam {
  uint256 strike;
  uint256 maturity;
  address tokenTo;
  address longTo;
  bool isLong0ToLong1;
  TimeswapV2OptionSwap transaction;
  uint256 amount;
  bytes data;
}

/// @dev The parameter to call the collect function.
/// @param strike The strike of the option.
/// @param maturity The maturity of the option.
/// @param token0To The recipient of token0 withdrawn.
/// @param token1To The recipient of token1 withdrawn.
/// @param transaction The type of collect transaction, more information in Transaction module.
/// @param amount If transaction is GivenShort, the amount of short position burnt.
/// If transaction is GivenToken0, the amount of token0 withdrawn.
/// If transaction is GivenToken1, the amount of token1 withdrawn.
/// @param data The data to be sent to the function, which will go to the collect callback.
/// @notice If data length is zero, skips the callback.
struct TimeswapV2OptionCollectParam {
  uint256 strike;
  uint256 maturity;
  address token0To;
  address token1To;
  TimeswapV2OptionCollect transaction;
  uint256 amount;
  bytes data;
}

library ParamLibrary {
  /// @dev Sanity checks
  /// @param param the parameter for mint transaction.
  /// @param blockTimestamp the current block timestamp.
  function check(TimeswapV2OptionMintParam memory param, uint96 blockTimestamp) internal pure {
    if (param.strike == 0) Error.zeroInput();
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (param.maturity < blockTimestamp) Error.alreadyMatured(param.maturity, blockTimestamp);
    if (param.shortTo == address(0)) Error.zeroAddress();
    if (param.long0To == address(0)) Error.zeroAddress();
    if (param.long1To == address(0)) Error.zeroAddress();
    TransactionLibrary.check(param.transaction);
    if (param.amount0 == 0 && param.amount1 == 0) Error.zeroInput();
  }

  /// @dev Sanity checks
  /// @param param the parameter for burn transaction.
  /// @param blockTimestamp the current block timestamp.
  function check(TimeswapV2OptionBurnParam memory param, uint96 blockTimestamp) internal pure {
    if (param.strike == 0) Error.zeroInput();
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (param.maturity < blockTimestamp) Error.alreadyMatured(param.maturity, blockTimestamp);
    if (param.token0To == address(0)) Error.zeroAddress();
    if (param.token1To == address(0)) Error.zeroAddress();
    TransactionLibrary.check(param.transaction);
    if (param.amount0 == 0 && param.amount1 == 0) Error.zeroInput();
  }

  /// @dev Sanity checks
  /// @param param the parameter for swap transaction.
  /// @param blockTimestamp the current block timestamp.
  function check(TimeswapV2OptionSwapParam memory param, uint96 blockTimestamp) internal pure {
    if (param.strike == 0) Error.zeroInput();
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (param.maturity < blockTimestamp) Error.alreadyMatured(param.maturity, blockTimestamp);
    if (param.tokenTo == address(0)) Error.zeroAddress();
    if (param.longTo == address(0)) Error.zeroAddress();
    TransactionLibrary.check(param.transaction);
    if (param.amount == 0) Error.zeroInput();
  }

  /// @dev Sanity checks
  /// @param param the parameter for collect transaction.
  /// @param blockTimestamp the current block timestamp.
  function check(TimeswapV2OptionCollectParam memory param, uint96 blockTimestamp) internal pure {
    if (param.strike == 0) Error.zeroInput();
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (param.maturity >= blockTimestamp) Error.stillActive(param.maturity, blockTimestamp);
    if (param.token0To == address(0)) Error.zeroAddress();
    if (param.token1To == address(0)) Error.zeroAddress();
    TransactionLibrary.check(param.transaction);
    if (param.amount == 0) Error.zeroInput();
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @dev A data with strike and maturity data.
/// @param strike The strike.
/// @param maturity The maturity.
struct StrikeAndMaturity {
  uint256 strike;
  uint256 maturity;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.8;

import "../interfaces/IMulticall.sol";

/// @title Multicall
/// @notice Enables calling multiple methods in a single call to the contract
abstract contract Multicall is IMulticall {
  /// @inheritdoc IMulticall
  function multicall(bytes[] calldata data) public payable override returns (bytes[] memory results) {
    results = new bytes[](data.length);
    for (uint256 i = 0; i < data.length; i++) {
      (bool success, bytes memory result) = address(this).delegatecall(data[i]);

      if (!success) {
        // Next 5 lines from https://ethereum.stackexchange.com/a/83577
        if (result.length < 68) revert MulticallFailed("Invalid Result");
        assembly {
          result := add(result, 0x04)
        }
        revert MulticallFailed(abi.decode(result, (string)));
      }

      results[i] = result;
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.8;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IWrappedNative} from "../interfaces/external/IWrappedNative.sol";
import {INativeImmutableState} from "../interfaces/INativeImmutableState.sol";
import {INativeWithdraws} from "../interfaces/INativeWithdraws.sol";
import {INativePayments} from "../interfaces/INativePayments.sol";
import {NativeTransfer} from "../libraries/NativeTransfer.sol";

abstract contract NativeImmutableState is INativeImmutableState {
  /// @inheritdoc INativeImmutableState
  address public immutable override wrappedNativeToken;

  constructor(address chosenWrappedNativeToken) {
    wrappedNativeToken = chosenWrappedNativeToken;
  }
}

abstract contract NativeWithdraws is INativeWithdraws, NativeImmutableState {
  error CallerNotWrappedNative(address from);

  error InsufficientWrappedNative(uint256 value);

  receive() external payable {
    if (msg.sender != wrappedNativeToken) revert CallerNotWrappedNative(msg.sender);
  }

  /// @inheritdoc INativeWithdraws
  function unwrapWrappedNatives(uint256 amountMinimum, address recipient) external payable override {
    uint256 balanceWrappedNative = IWrappedNative(wrappedNativeToken).balanceOf(address(this));

    if (balanceWrappedNative < amountMinimum) revert InsufficientWrappedNative(balanceWrappedNative);

    if (balanceWrappedNative != 0) {
      IWrappedNative(wrappedNativeToken).withdraw(balanceWrappedNative);

      NativeTransfer.safeTransferNatives(recipient, balanceWrappedNative);
    }
  }
}

abstract contract NativePayments is INativePayments, NativeImmutableState {
  using SafeERC20 for IERC20;

  /// @inheritdoc INativePayments
  function refundNatives() external payable override {
    if (address(this).balance > 0) NativeTransfer.safeTransferNatives(msg.sender, address(this).balance);
  }

  /// @param token The token to pay
  /// @param payer The entity that must pay
  /// @param recipient The entity that will receive payment
  /// @param value The amount to pay
  function pay(address token, address payer, address recipient, uint256 value) internal {
    if (token == wrappedNativeToken && address(this).balance >= value) {
      // pay with WrappedNative
      IWrappedNative(wrappedNativeToken).deposit{value: value}();

      IERC20(token).safeTransfer(recipient, value);
    } else {
      // pull payment
      IERC20(token).safeTransferFrom(payer, recipient, value);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.8;

import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

abstract contract OnlyOperatorReceiver is IERC1155Receiver {
  function onERC1155Received(
    address operator,
    address,
    uint256,
    uint256,
    bytes memory
  ) external view override returns (bytes4) {
    if (operator != address(this)) return bytes4("");
    else return this.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(
    address,
    address,
    uint256[] memory,
    uint256[] memory,
    bytes memory
  ) external pure override returns (bytes4) {
    return bytes4("");
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Interface for Native token
/// @dev This interface is used to interact with the native token
/// @dev The native token could be ETH for ethereum or BNB for Binance Smart Chain or MATIC for Polygon
interface IWrappedNative is IERC20 {
  /// @notice Deposit native token to get wrapped native token
  function deposit() external payable;

  /// @notice Withdraw wrapped native token to get native token
  function withdraw(uint256) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @title Multicall interface
/// @notice Enables calling multiple methods in a single call to the contract
interface IMulticall {
  /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
  /// @dev The `msg.value` should not be trusted for any method callable from multicall.
  /// @param data The encoded function data for each of the calls to make to this contract
  /// @return results The results from each of the calls passed in via data
  function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);

  error MulticallFailed(string revertString);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @title NativeImmutableState interface
interface INativeImmutableState {
  /// @return Returns the address of Wrapped Native token
  function wrappedNativeToken() external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @title NativePayments interface
/// @notice Functions to ease payments of native tokens
interface INativePayments {
  /// @notice Refunds any Native Token balance held by this contract to the `msg.sender`
  function refundNatives() external payable;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @title NativeWithdraws interface

interface INativeWithdraws {
  /// @notice Unwraps the contract's Wrapped Native token balance and sends it to recipient as Native token.
  /// @dev The amountMinimum parameter prevents malicious contracts from stealing Wrapped Native from users.
  /// @param amountMinimum The minimum amount of Wrapped Native to unwrap
  /// @param recipient The address receiving Native token
  function unwrapWrappedNatives(uint256 amountMinimum, address recipient) external payable;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {ITimeswapV2PeripheryWithdraw} from "@timeswap-labs/v2-periphery/contracts/interfaces/ITimeswapV2PeripheryWithdraw.sol";

import {INativeWithdraws} from "./INativeWithdraws.sol";
import {IMulticall} from "./IMulticall.sol";

import {TimeswapV2PeripheryNoDexWithdrawParam} from "../structs/Param.sol";

/// @title An interface for TS-V2 Periphery No Dex Withdraw.
interface ITimeswapV2PeripheryNoDexWithdraw is ITimeswapV2PeripheryWithdraw, INativeWithdraws, IMulticall {
  event Withdraw(
    address indexed token0,
    address indexed token1,
    uint256 strike,
    uint256 indexed maturity,
    address to,
    uint256 token0Amount,
    uint256 token1Amount,
    uint256 positionAmount
  );

  error MinTokenReached(uint256 tokenAmount, uint256 minTokenAmount);

  /// @dev The withdraw function.
  /// @param param Withdraw param.
  /// @return token0Amount
  /// @return token1Amount
  function withdraw(
    TimeswapV2PeripheryNoDexWithdrawParam calldata param
  ) external returns (uint256 token0Amount, uint256 token1Amount);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

library NativeTransfer {
  error NativeTransferFailed(address to, uint256 value);

  /// @notice Transfers Natives to the recipient address
  /// @dev Reverts if the transfer fails
  /// @param to The destination of the transfer
  /// @param value The value to be transferred
  function safeTransferNatives(address to, uint256 value) internal {
    (bool success, ) = to.call{value: value}(new bytes(0));
    if (!success) {
      revert NativeTransferFailed(to, value);
    }
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

struct TimeswapV2PeripheryNoDexAddLiquidityGivenPrincipalParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address liquidityTo;
  bool isToken0;
  uint256 tokenAmount;
  uint160 minLiquidityAmount;
  uint160 minSqrtInterestRate;
  uint160 maxSqrtInterestRate;
  uint256 deadline;
  bytes erc1155Data;
}

struct TimeswapV2PeripheryNoDexRemoveLiquidityGivenPositionParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address tokenTo;
  bool isToken0;
  uint160 liquidityAmount;
  uint256 excessLong0Amount;
  uint256 excessLong1Amount;
  uint256 excessShortAmount;
  uint256 minToken0Amount;
  uint256 minToken1Amount;
  uint160 minSqrtInterestRate;
  uint160 maxSqrtInterestRate;
  uint256 deadline;
}

struct TimeswapV2PeripheryNoDexCollectParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address to;
  bool isToken0;
  uint256 excessShortAmount;
  uint256 minToken0Amount;
  uint256 minToken1Amount;
  uint256 deadline;
}

struct TimeswapV2PeripheryNoDexLendGivenPrincipalParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address to;
  bool isToken0;
  uint256 tokenAmount;
  uint256 minReturnAmount;
  uint256 deadline;
}

struct TimeswapV2PeripheryNoDexBorrowGivenPrincipalParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address tokenTo;
  address longTo;
  bool isToken0;
  bool isLong0;
  uint256 tokenAmount;
  uint256 maxPositionAmount;
  uint256 deadline;
}

struct TimeswapV2PeripheryNoDexBorrowGivenPositionParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address tokenTo;
  address longTo;
  bool isToken0;
  bool isLong0;
  uint256 positionAmount;
  uint256 minTokenAmount;
  uint256 deadline;
}

struct TimeswapV2PeripheryNoDexCloseBorrowGivenPositionParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address to;
  bool isToken0;
  bool isLong0;
  uint256 positionAmount;
  uint256 maxTokenAmount;
  uint256 deadline;
}

struct TimeswapV2PeripheryNoDexCloseLendGivenPositionParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address to;
  bool isToken0;
  uint256 positionAmount;
  uint256 minToken0Amount;
  uint256 minToken1Amount;
  uint256 deadline;
}

struct TimeswapV2PeripheryNoDexWithdrawParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address to;
  uint256 positionAmount;
  uint256 minToken0Amount;
  uint256 minToken1Amount;
  uint256 deadline;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {Error} from "@timeswap-labs/v2-library/contracts/Error.sol";

import {StrikeConversion} from "@timeswap-labs/v2-library/contracts/StrikeConversion.sol";

import {TimeswapV2OptionPosition} from "@timeswap-labs/v2-option/contracts/enums/Position.sol";

import {ITimeswapV2Token} from "@timeswap-labs/v2-token/contracts/interfaces/ITimeswapV2Token.sol";

import {TimeswapV2TokenPosition} from "@timeswap-labs/v2-token/contracts/structs/Position.sol";

import {TimeswapV2PeripheryWithdraw} from "@timeswap-labs/v2-periphery/contracts/TimeswapV2PeripheryWithdraw.sol";

import {TimeswapV2PeripheryWithdrawParam} from "@timeswap-labs/v2-periphery/contracts/structs/Param.sol";

import {ITimeswapV2PeripheryNoDexWithdraw} from "./interfaces/ITimeswapV2PeripheryNoDexWithdraw.sol";

import {TimeswapV2PeripheryNoDexWithdrawParam} from "./structs/Param.sol";

import {OnlyOperatorReceiver} from "./base/OnlyOperatorReceiver.sol";
import {NativeImmutableState, NativeWithdraws} from "./base/Native.sol";
import {Multicall} from "./base/Multicall.sol";

/// @title Capable of withdrawing position from Timeswap V2 Protocol
/// @author Timeswap Labs
contract TimeswapV2PeripheryNoDexWithdraw is
  TimeswapV2PeripheryWithdraw,
  ITimeswapV2PeripheryNoDexWithdraw,
  OnlyOperatorReceiver,
  NativeImmutableState,
  NativeWithdraws,
  Multicall
{
  using SafeERC20 for IERC20;

  constructor(
    address chosenOptionFactory,
    address chosenTokens,
    address chosenNative
  ) TimeswapV2PeripheryWithdraw(chosenOptionFactory, chosenTokens) NativeImmutableState(chosenNative) {}

  /// @inheritdoc ITimeswapV2PeripheryNoDexWithdraw
  function withdraw(
    TimeswapV2PeripheryNoDexWithdrawParam calldata param
  ) external override returns (uint256 token0Amount, uint256 token1Amount) {
    if (param.deadline < block.timestamp) Error.deadlineReached(param.deadline);

    ITimeswapV2Token(tokens).transferTokenPositionFrom(
      msg.sender,
      address(this),
      TimeswapV2TokenPosition({
        token0: param.token0,
        token1: param.token1,
        strike: param.strike,
        maturity: param.maturity,
        position: TimeswapV2OptionPosition.Short
      }),
      param.positionAmount
    );

    (token0Amount, token1Amount) = withdraw(
      TimeswapV2PeripheryWithdrawParam({
        token0: param.token0,
        token1: param.token1,
        strike: param.strike,
        maturity: param.maturity,
        token0To: param.to,
        token1To: param.to,
        positionAmount: param.positionAmount
      })
    );

    if (token0Amount < param.minToken0Amount) revert MinTokenReached(token0Amount, param.minToken0Amount);
    if (token1Amount < param.minToken1Amount) revert MinTokenReached(token1Amount, param.minToken1Amount);

    emit Withdraw(
      param.token0,
      param.token1,
      param.strike,
      param.maturity,
      param.to,
      token0Amount,
      token1Amount,
      param.positionAmount
    );
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

/// @title An interface for TS-V2 Periphery Withdraw
interface ITimeswapV2PeripheryWithdraw is IERC1155Receiver {
  /// @dev Returns the option factory address.
  /// @return optionFactory The option factory address.
  function optionFactory() external returns (address);

  /// @dev Return the tokens address
  function tokens() external returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {ITimeswapV2OptionFactory} from "@timeswap-labs/v2-option/contracts/interfaces/ITimeswapV2OptionFactory.sol";

import {ITimeswapV2PoolFactory} from "@timeswap-labs/v2-pool/contracts/interfaces/ITimeswapV2PoolFactory.sol";

/// @dev Library to verify that a pool or option exist
library Verify {
  /// @dev Revert with this error when an address other than the options contract call the implemented callback function.
  error CanOnlyBeCalledByOptionContract();

  /// @dev Revert with this error when an address other than the pool contract call the implemented callback function.
  error CanOnlyBeCalledByPoolContract();

  /// @dev Revert with this error when an address other than the tokens contract call the implemented callback function.
  error CanOnlyBeCalledByTokensContract();

  /// @dev Revert with this error when an address other than the liquidity tokens contract call the implemented callback function.
  error CanOnlyBeCalledByLiquidityTokensContract();

  /// @dev Checks that the option given the parameters exist and that the msg.sender is the options contract.
  /// @param optionFactory The address of the Timeswap V2 option factory contract.
  /// @param token0 The address of the smaller sized ERC20 contract.
  /// @param token1 The address of the larger sized ERC20 contract.
  function timeswapV2Option(address optionFactory, address token0, address token1) internal view {
    address optionPair = ITimeswapV2OptionFactory(optionFactory).get(token0, token1);

    if (optionPair != msg.sender) revert CanOnlyBeCalledByOptionContract();
  }

  /// @dev Checks that the pool given the parameters exist and that the msg.sender is the pool contract.
  /// @dev Also returns the address of the optionPair.
  /// @param optionFactory The address of the Timeswap V2 option factory contract.
  /// @param poolFactory The address of the Timeswap V2 pool factory contract.
  /// @param token0 The address of the smaller sized ERC20 contract.
  /// @param token1 The address of the larger sized ERC20 contract.
  /// @return optionPair The address of the option pair contract.
  function timeswapV2Pool(
    address optionFactory,
    address poolFactory,
    address token0,
    address token1
  ) internal view returns (address optionPair) {
    optionPair = ITimeswapV2OptionFactory(optionFactory).get(token0, token1);

    address poolPair = ITimeswapV2PoolFactory(poolFactory).get(optionPair);

    if (poolPair != msg.sender) revert CanOnlyBeCalledByPoolContract();
  }

  /// @dev Checks that the msg.sender is the tokens contract.
  function timeswapV2Token(address tokens) internal view {
    if (tokens != msg.sender) revert CanOnlyBeCalledByTokensContract();
  }

  /// @dev Checks that the msg.sender is the liquidity tokens contract.
  function timeswapV2LiquidityToken(address liquidityTokens) internal view {
    if (liquidityTokens != msg.sender) revert CanOnlyBeCalledByLiquidityTokensContract();
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @dev The parameter for calling the collect protocol fees function.
/// @param token0 The address of the smaller size ERC20 contract.
/// @param token1 The address of the larger size ERC20 contract.
/// @param strike The strike price of the position in UQ128.128.
/// @param maturity The maturity of the position in seconds.
/// @param token0To The receiver of any token0 ERC20 tokens.
/// @param token1To The receiver of any token1 ERC20 tokens.
/// @param excessLong0To The receiver of any excess long0 ERC1155 tokens.
/// @param excessLong1To The receiver of any excess long1 ERC1155 tokens.
/// @param excessShortTo The receiver of any excess short ERC1155 tokens.
/// @param long0Requested The maximum amount of long0 fees.
/// @param long1Requested The maximum amount of long1 fees.
/// @param shortRequested The maximum amount of short fees.
/// @param data The bytes data passed to callback.
struct TimeswapV2PeripheryCollectProtocolFeesParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address token0To;
  address token1To;
  address excessLong0To;
  address excessLong1To;
  address excessShortTo;
  uint256 long0Requested;
  uint256 long1Requested;
  uint256 shortRequested;
  bytes data;
}

/// @dev The parameter for calling the add liquidity function.
/// @param token0 The address of the smaller size ERC20 contract.
/// @param token1 The address of the larger size ERC20 contract.
/// @param strike The strike price of the position in UQ128.128.
/// @param maturity The maturity of the position in seconds.
/// @param liquidityTo The receiver of the liquidity position ERC1155 tokens.
/// @param token0Amount The amount of token0 ERC20 tokens to deposit.
/// @param token1Amount The amount of token1 ERC20 tokens to deposit.
/// @param data The bytes data passed to callback.
/// @param erc1155Data The bytes data passed to the receiver of liquidity position ERC1155 tokens.
struct TimeswapV2PeripheryAddLiquidityGivenPrincipalParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address liquidityTo;
  uint256 token0Amount;
  uint256 token1Amount;
  bytes data;
  bytes erc1155Data;
}

/// @dev The parameter for calling the remove liquidity function.
/// @param token0 The address of the smaller size ERC20 contract.
/// @param token1 The address of the larger size ERC20 contract.
/// @param strike The strike price of the position in UQ128.128.
/// @param maturity The maturity of the position in seconds.
/// @param token0To The receiver of any token0 ERC20 tokens.
/// @param token1To The receiver of any token1 ERC20 tokens.
/// @param liquidityAmount The amount of liquidity ERC1155 tokens to burn.
/// @param excessLong0Amount The amount of long0 ERC1155 tokens to include in matching long and short positions.
/// @param excessLong1Amount The amount of long1 ERC1155 tokens to include in matching long and short positions.
/// @param excessShortAmount The amount of short ERC1155 tokens to include in matching long and short positions.
struct TimeswapV2PeripheryRemoveLiquidityGivenPositionParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address token0To;
  address token1To;
  uint160 liquidityAmount;
  uint256 excessLong0Amount;
  uint256 excessLong1Amount;
  uint256 excessShortAmount;
  bytes data;
}

/// @dev A struct describing how much fees and short returned are withdrawn from the pool.
/// @param long0Fees The number of long0 fees withdrwan from the pool.
/// @param long1Fees The number of long1 fees withdrwan from the pool.
/// @param shortFees The number of short fees withdrwan from the pool.
/// @param shortReturned The number of short returned withdrwan from the pool.
struct FeesAndReturnedDelta {
  uint256 long0Fees;
  uint256 long1Fees;
  uint256 shortFees;
  uint256 shortReturned;
}

/// @dev A struct describing how much long and short position are removed or added.
/// @param isRemoveLong0 True if long0 excess is removed from the user.
/// @param isRemoveLong1 True if long1 excess is removed from the user.
/// @param isRemoveShort True if short excess is removed from the user.
/// @param long0Amount The number of excess long0 is removed or added.
/// @param long1Amount The number of excess long1 is removed or added.
/// @param shortAmount The number of excess short is removed or added.
struct ExcessDelta {
  bool isRemoveLong0;
  bool isRemoveLong1;
  bool isRemoveShort;
  uint256 long0Amount;
  uint256 long1Amount;
  uint256 shortAmount;
}

/// @dev The parameter for calling the collect function.
/// @param token0 The address of the smaller size ERC20 contract.
/// @param token1 The address of the larger size ERC20 contract.
/// @param strike The strike price of the position in UQ128.128.
/// @param maturity The maturity of the position in seconds.
/// @param token0To The receiver of any token0 ERC20 tokens.
/// @param token1To The receiver of any token1 ERC20 tokens.
/// @param excessShortAmount The amount of short ERC1155 tokens to burn.
struct TimeswapV2PeripheryCollectParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address token0To;
  address token1To;
  uint256 excessShortAmount;
}

/// @dev The parameter for calling the lend given principal function.
/// @param token0 The address of the smaller size ERC20 contract.
/// @param token1 The address of the larger size ERC20 contract.
/// @param strike The strike price of the position in UQ128.128.
/// @param maturity The maturity of the position in seconds.
/// @param to The receiver of short position.
/// @param token0Amount The amount of token0 ERC20 tokens to deposit.
/// @param token1Amount The amount of token1 ERC20 tokens to deposit.
/// @param data The bytes data passed to callback.
struct TimeswapV2PeripheryLendGivenPrincipalParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address to;
  uint256 token0Amount;
  uint256 token1Amount;
  bytes data;
}

/// @dev The parameter for calling the close borrow given position function.
/// @param token0 The address of the smaller size ERC20 contract.
/// @param token1 The address of the larger size ERC20 contract.
/// @param strike The strike price of the position in UQ128.128.
/// @param maturity The maturity of the position in seconds.
/// @param to The receiver of the ERC20 tokens.
/// @param isLong0 True if the caller wants to close long0 positions, false if the caller wants to close long1 positions.
/// @param positionAmount The amount of chosen long positions to close.
/// @param data The bytes data passed to callback.
struct TimeswapV2PeripheryCloseBorrowGivenPositionParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address to;
  bool isLong0;
  uint256 positionAmount;
  bytes data;
}

/// @dev The parameter for calling the borrow given principal function.
/// @param token0 The address of the smaller size ERC20 contract.
/// @param token1 The address of the larger size ERC20 contract.
/// @param strike The strike price of the position in UQ128.128.
/// @param maturity The maturity of the position in seconds.
/// @param tokenTo The receiver of the ERC20 tokens.
/// @param longTo The receiver of the long ERC1155 positions.
/// @param isLong0 True if the caller wants to receive long0 positions, false if the caller wants to receive long1 positions.
/// @param token0Amount The amount of token0 ERC20 to borrow.
/// @param token1Amount The amount of token1 ERC20 to borrow.
/// @param data The bytes data passed to callback.
struct TimeswapV2PeripheryBorrowGivenPrincipalParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address tokenTo;
  address longTo;
  bool isLong0;
  uint256 token0Amount;
  uint256 token1Amount;
  bytes data;
}

/// @dev The parameter for calling the borrow given position function.
/// @param token0 The address of the smaller size ERC20 contract.
/// @param token1 The address of the larger size ERC20 contract.
/// @param strike The strike price of the position in UQ128.128.
/// @param maturity The maturity of the position in seconds.
/// @param tokenTo The receiver of the ERC20 tokens.
/// @param longTo The receiver of the long ERC1155 positions.
/// @param isLong0 True if the caller wants to receive long0 positions, false if the caller wants to receive long1 positions.
/// @param positionAmount The amount of long position to receive.
/// @param data The bytes data passed to callback.
struct TimeswapV2PeripheryBorrowGivenPositionParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address tokenTo;
  address longTo;
  bool isLong0;
  uint256 positionAmount;
  bytes data;
}

/// @dev The parameter for calling the close lend given position function.
/// @param token0 The address of the smaller size ERC20 contract.
/// @param token1 The address of the larger size ERC20 contract.
/// @param strike The strike price of the position in UQ128.128.
/// @param maturity The maturity of the position in seconds.
/// @param token0To The receiver of any token0 ERC20 tokens.
/// @param token1To The receiver of any token1 ERC20 tokens.
/// @param positionAmount The amount of long position to receive.
/// @param data The bytes data passed to callback.
struct TimeswapV2PeripheryCloseLendGivenPositionParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address token0To;
  address token1To;
  uint256 positionAmount;
  bytes data;
}

/// @dev The parameter for calling the rebalance function.
/// @param token0 The address of the smaller size ERC20 contract.
/// @param token1 The address of the larger size ERC20 contract.
/// @param strike The strike price of the position in UQ128.128.
/// @param maturity The maturity of the position in seconds.
/// @param tokenTo The receiver of the ERC20 tokens.
/// @param excessShortTo The receiver of any excess short ERC1155 tokens.
/// @param isLong0ToLong1 True if transforming long0 position to long1 position, false if transforming long1 position to long0 position.
/// @param givenLong0 True if the amount is in long0 position, false if the amount is in long1 position.
/// @param tokenAmount The amount of token amount given isLong0ToLong1 and givenLong0.
/// @param data The bytes data passed to callback.
struct TimeswapV2PeripheryRebalanceParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address tokenTo;
  address excessShortTo;
  bool isLong0ToLong1;
  bool givenLong0;
  uint256 tokenAmount;
  bytes data;
}

/// @dev The parameter for calling the redeem function.
/// @param token0 The address of the smaller size ERC20 contract.
/// @param token1 The address of the larger size ERC20 contract.
/// @param strike The strike price of the position in UQ128.128.
/// @param maturity The maturity of the position in seconds.
/// @param token0To The receiver of any token0 ERC20 tokens.
/// @param token1To The receiver of any token1 ERC20 tokens.
/// @param token0AndLong0Amount The amount of token0 to receive and long0 to burn.
/// @param token1AndLong1Amount The amount of token1 to receive and long1 to burn.
struct TimeswapV2PeripheryRedeemParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address token0To;
  address token1To;
  uint256 token0AndLong0Amount;
  uint256 token1AndLong1Amount;
}

/// @dev The parameter for calling the transform function.
/// @param token0 The address of the smaller size ERC20 contract.
/// @param token1 The address of the larger size ERC20 contract.
/// @param strike The strike price of the position in UQ128.128.
/// @param maturity The maturity of the position in seconds.
/// @param tokenTo The receiver of the ERC20 tokens.
/// @param longTo The receiver of the ERC1155 long positions.
/// @param isLong0ToLong1 True if transforming long0 position to long1 position, false if transforming long1 position to long0 position.
/// @param positionAmount The amount of long amount given isLong0ToLong1 and givenLong0.
/// @param data The bytes data passed to callback.
struct TimeswapV2PeripheryTransformParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address tokenTo;
  address longTo;
  bool isLong0ToLong1;
  uint256 positionAmount;
  bytes data;
}

/// @dev The parameter for calling the withdraw function.
/// @param token0 The address of the smaller size ERC20 contract.
/// @param token1 The address of the larger size ERC20 contract.
/// @param strike The strike price of the position in UQ128.128.
/// @param maturity The maturity of the position in seconds.
/// @param token0To The receiver of any token0 ERC20 tokens.
/// @param token1To The receiver of any token1 ERC20 tokens.
/// @param positionAmount The amount of short ERC1155 tokens to burn.
struct TimeswapV2PeripheryWithdrawParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address token0To;
  address token1To;
  uint256 positionAmount;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {ERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";

import {ITimeswapV2OptionFactory} from "@timeswap-labs/v2-option/contracts/interfaces/ITimeswapV2OptionFactory.sol";
import {ITimeswapV2Option} from "@timeswap-labs/v2-option/contracts/interfaces/ITimeswapV2Option.sol";

import {OptionFactoryLibrary} from "@timeswap-labs/v2-option/contracts/libraries/OptionFactory.sol";

import {TimeswapV2OptionMintParam, TimeswapV2OptionCollectParam} from "@timeswap-labs/v2-option/contracts/structs/Param.sol";
import {TimeswapV2OptionMintCallbackParam} from "@timeswap-labs/v2-option/contracts/structs/CallbackParam.sol";

import {TimeswapV2OptionMint, TimeswapV2OptionCollect} from "@timeswap-labs/v2-option/contracts/enums/Transaction.sol";
import {TimeswapV2OptionPosition} from "@timeswap-labs/v2-option/contracts/enums/Position.sol";

import {ITimeswapV2PoolFactory} from "@timeswap-labs/v2-pool/contracts/interfaces/ITimeswapV2PoolFactory.sol";
import {ITimeswapV2Pool} from "@timeswap-labs/v2-pool/contracts/interfaces/ITimeswapV2Pool.sol";

import {ITimeswapV2Token} from "@timeswap-labs/v2-token/contracts/interfaces/ITimeswapV2Token.sol";

import {TimeswapV2TokenBurnParam} from "@timeswap-labs/v2-token/contracts/structs/Param.sol";

import {TimeswapV2PeripheryWithdrawParam} from "./structs/Param.sol";

import {ITimeswapV2PeripheryWithdraw} from "./interfaces/ITimeswapV2PeripheryWithdraw.sol";
import {Verify} from "./libraries/Verify.sol";

/// @title Abstract contract which specifies functions that are required for  withdraw which are to be inherited for a specific DEX/Aggregator implementation
abstract contract TimeswapV2PeripheryWithdraw is ITimeswapV2PeripheryWithdraw, ERC1155Receiver {
  /* ===== MODEL ===== */
  /// @inheritdoc ITimeswapV2PeripheryWithdraw
  address public immutable override optionFactory;
  /// @inheritdoc ITimeswapV2PeripheryWithdraw
  address public immutable override tokens;

  /* ===== INIT ===== */

  constructor(address chosenOptionFactory, address chosenTokens) {
    optionFactory = chosenOptionFactory;
    tokens = chosenTokens;
  }

  /// @notice the abstract implementation for withdraw function
  /// @param param params for  withdraw as mentioned in the TimeswapV2PeripheryWithdrawParam struct
  /// @return token0Amount is the token0Amount recieved
  /// @return token1Amount is the token0Amount recieved
  function withdraw(
    TimeswapV2PeripheryWithdrawParam memory param
  ) internal returns (uint256 token0Amount, uint256 token1Amount) {
    address optionPair = OptionFactoryLibrary.getWithCheck(optionFactory, param.token0, param.token1);

    // Unwrap the short ERC1155
    ITimeswapV2Token(tokens).burn(
      TimeswapV2TokenBurnParam({
        token0: param.token0,
        token1: param.token1,
        strike: param.strike,
        maturity: param.maturity,
        long0To: address(this),
        long1To: address(this),
        shortTo: address(this),
        long0Amount: 0,
        long1Amount: 0,
        shortAmount: param.positionAmount,
        data: bytes("")
      })
    );

    // Burn the unwrapped short to withdraw the underlying ERC20
    (token0Amount, token1Amount, , ) = ITimeswapV2Option(optionPair).collect(
      TimeswapV2OptionCollectParam({
        strike: param.strike,
        maturity: param.maturity,
        token0To: param.token0To,
        token1To: param.token1To,
        transaction: TimeswapV2OptionCollect.GivenShort,
        amount: param.positionAmount,
        data: bytes("")
      })
    );
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @dev The different kind of mint transactions.
enum TimeswapV2PoolMint {
  GivenLiquidity,
  GivenLong,
  GivenShort,
  GivenLarger
}

/// @dev The different kind of burn transactions.
enum TimeswapV2PoolBurn {
  GivenLiquidity,
  GivenLong,
  GivenShort,
  GivenSmaller
}

/// @dev The different kind of deleverage transactions.
enum TimeswapV2PoolDeleverage {
  GivenDeltaSqrtInterestRate,
  GivenLong,
  GivenShort,
  GivenSum
}

/// @dev The different kind of leverage transactions.
enum TimeswapV2PoolLeverage {
  GivenDeltaSqrtInterestRate,
  GivenLong,
  GivenShort,
  GivenSum
}

/// @dev The different kind of rebalance transactions.
enum TimeswapV2PoolRebalance {
  GivenLong0,
  GivenLong1
}

library TransactionLibrary {
  /// @dev Reverts when the given type of transaction is invalid.
  error InvalidTransaction();

  /// @dev Function to revert with the error InvalidTransaction.
  function invalidTransaction() internal pure {
    revert InvalidTransaction();
  }

  /// @dev Sanity checks for the mint parameters.
  function check(TimeswapV2PoolMint transaction) internal pure {
    if (uint256(transaction) >= 4) revert InvalidTransaction();
  }

  /// @dev Sanity checks for the burn parameters.
  function check(TimeswapV2PoolBurn transaction) internal pure {
    if (uint256(transaction) >= 4) revert InvalidTransaction();
  }

  /// @dev Sanity checks for the deleverage parameters.
  function check(TimeswapV2PoolDeleverage transaction) internal pure {
    if (uint256(transaction) >= 4) revert InvalidTransaction();
  }

  /// @dev Sanity checks for the leverage parameters.
  function check(TimeswapV2PoolLeverage transaction) internal pure {
    if (uint256(transaction) >= 4) revert InvalidTransaction();
  }

  /// @dev Sanity checks for the rebalance parameters.
  function check(TimeswapV2PoolRebalance transaction) internal pure {
    if (uint256(transaction) >= 2) revert InvalidTransaction();
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

interface IOwnableTwoSteps {
  /// @dev Emits when the pending owner is chosen.
  /// @param pendingOwner The new pending owner.
  event SetOwner(address pendingOwner);

  /// @dev Emits when the pending owner accepted and become the new owner.
  /// @param owner The new owner.
  event AcceptOwner(address owner);

  /// @dev The address of the current owner.
  /// @return address
  function owner() external view returns (address);

  /// @dev The address of the current pending owner.
  /// @notice The address can be zero which signifies no pending owner.
  /// @return address
  function pendingOwner() external view returns (address);

  /// @dev The owner sets the new pending owner.
  /// @notice Can only be called by the owner.
  /// @param chosenPendingOwner The newly chosen pending owner.
  function setPendingOwner(address chosenPendingOwner) external;

  /// @dev The pending owner accepts being the new owner.
  /// @notice Can only be called by the pending owner.
  function acceptOwner() external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {StrikeAndMaturity} from "@timeswap-labs/v2-option/contracts/structs/StrikeAndMaturity.sol";

import {TimeswapV2PoolCollectProtocolFeesParam, TimeswapV2PoolCollectTransactionFeesAndShortReturnedParam, TimeswapV2PoolMintParam, TimeswapV2PoolBurnParam, TimeswapV2PoolDeleverageParam, TimeswapV2PoolLeverageParam, TimeswapV2PoolRebalanceParam} from "../structs/Param.sol";

/// @title An interface for Timeswap V2 Pool contract.
interface ITimeswapV2Pool {
  /// @dev Emits when liquidity position is transferred.
  /// @param strike The strike of the option and pool.
  /// @param maturity The maturity of the option and pool.
  /// @param from The sender of liquidity position.
  /// @param to The receipeint of liquidity position.
  /// @param liquidityAmount The amount of liquidity position transferred.
  event TransferLiquidity(
    uint256 indexed strike,
    uint256 indexed maturity,
    address from,
    address to,
    uint160 liquidityAmount
  );

  /// @dev Emits when protocol fees are withdrawn by the factory contract owner.
  /// @param strike The strike of the option and pool.
  /// @param maturity The maturity of the option and pool.
  /// @param caller The caller of the collectProtocolFees function.
  /// @param long0To The recipient of long0 position fees.
  /// @param long1To The recipient of long1 position fees.
  /// @param shortTo The recipient of short position fees.
  /// @param long0Amount The amount of long0 position fees withdrawn.
  /// @param long1Amount The amount of long1 position fees withdrawn.
  /// @param shortAmount The amount of short position fees withdrawn.
  event CollectProtocolFees(
    uint256 indexed strike,
    uint256 indexed maturity,
    address indexed caller,
    address long0To,
    address long1To,
    address shortTo,
    uint256 long0Amount,
    uint256 long1Amount,
    uint256 shortAmount
  );

  /// @dev Emits when transaction fees are withdrawn by a liquidity provider.
  /// @param strike The strike of the option and pool.
  /// @param maturity The maturity of the option and pool.
  /// @param caller The caller of the collectTransactionFees function.
  /// @param long0FeesTo The recipient of long0 position fees.
  /// @param long1FeesTo The recipient of long1 position fees.
  /// @param shortFeesTo The recipient of short position fees.
  /// @param shortReturnedTo The recipient of short position returned.
  /// @param long0Fees The amount of long0 position fees withdrawn.
  /// @param long1Fees The amount of long1 position fees withdrawn.
  /// @param shortFees The amount of short position fees withdrawn.
  /// @param shortReturned The amount of short position returned withdrawn.
  event CollectTransactionFeesAndShortReturned(
    uint256 indexed strike,
    uint256 indexed maturity,
    address indexed caller,
    address long0FeesTo,
    address long1FeesTo,
    address shortFeesTo,
    address shortReturnedTo,
    uint256 long0Fees,
    uint256 long1Fees,
    uint256 shortFees,
    uint256 shortReturned
  );

  /// @dev Emits when the mint transaction is called.
  /// @param strike The strike of the option and pool.
  /// @param maturity The maturity of the option and pool.
  /// @param caller The caller of the mint function.
  /// @param to The recipient of liquidity positions.
  /// @param liquidityAmount The amount of liquidity positions minted.
  /// @param long0Amount The amount of long0 positions deposited.
  /// @param long1Amount The amount of long1 positions deposited.
  /// @param shortAmount The amount of short positions deposited.
  event Mint(
    uint256 indexed strike,
    uint256 indexed maturity,
    address indexed caller,
    address to,
    uint160 liquidityAmount,
    uint256 long0Amount,
    uint256 long1Amount,
    uint256 shortAmount
  );

  /// @dev Emits when the burn transaction is called.
  /// @param strike The strike of the option and pool.
  /// @param maturity The maturity of the option and pool.
  /// @param caller The caller of the burn function.
  /// @param long0To The recipient of long0 positions.
  /// @param long1To The recipient of long1 positions.
  /// @param shortTo The recipient of short positions.
  /// @param liquidityAmount The amount of liquidity positions burnt.
  /// @param long0Amount The amount of long0 positions withdrawn.
  /// @param long1Amount The amount of long1 positions withdrawn.
  /// @param shortAmount The amount of short positions withdrawn.
  event Burn(
    uint256 indexed strike,
    uint256 indexed maturity,
    address indexed caller,
    address long0To,
    address long1To,
    address shortTo,
    uint160 liquidityAmount,
    uint256 long0Amount,
    uint256 long1Amount,
    uint256 shortAmount
  );

  /// @dev Emits when deleverage transaction is called.
  /// @param strike The strike of the option and pool.
  /// @param maturity The maturity of the option and pool.
  /// @param caller The caller of the deleverage function.
  /// @param to The recipient of short positions.
  /// @param long0Amount The amount of long0 positions deposited.
  /// @param long1Amount The amount of long1 positions deposited.
  /// @param shortAmount The amount of short positions withdrawn.
  event Deleverage(
    uint256 indexed strike,
    uint256 indexed maturity,
    address indexed caller,
    address to,
    uint256 long0Amount,
    uint256 long1Amount,
    uint256 shortAmount
  );

  /// @dev Emits when leverage transaction is called.
  /// @param strike The strike of the option and pool.
  /// @param maturity The maturity of the option and pool.
  /// @param caller The caller of the leverage function.
  /// @param long0To The recipient of long0 positions.
  /// @param long1To The recipient of long1 positions.
  /// @param long0Amount The amount of long0 positions withdrawn.
  /// @param long1Amount The amount of long1 positions withdrawn.
  /// @param shortAmount The amount of short positions deposited.
  event Leverage(
    uint256 indexed strike,
    uint256 indexed maturity,
    address indexed caller,
    address long0To,
    address long1To,
    uint256 long0Amount,
    uint256 long1Amount,
    uint256 shortAmount
  );

  /// @dev Emits when rebalance transaction is called.
  /// @param strike The strike of the option and pool.
  /// @param maturity The maturity of the option and pool.
  /// @param caller The caller of the rebalance function.
  /// @param to If isLong0ToLong1 then recipient of long0 positions, ekse recipient of long1 positions.
  /// @param isLong0ToLong1 Long0ToLong1 if true. Long1ToLong0 if false.
  /// @param long0Amount If isLong0ToLong1, amount of long0 positions deposited.
  /// If isLong1ToLong0, amount of long0 positions withdrawn.
  /// @param long1Amount If isLong0ToLong1, amount of long1 positions withdrawn.
  /// If isLong1ToLong0, amount of long1 positions deposited.
  event Rebalance(
    uint256 indexed strike,
    uint256 indexed maturity,
    address indexed caller,
    address to,
    bool isLong0ToLong1,
    uint256 long0Amount,
    uint256 long1Amount
  );

  error Quote();

  /* ===== VIEW ===== */

  /// @dev Returns the factory address that deployed this contract.
  function poolFactory() external view returns (address);

  /// @dev Returns the Timeswap V2 Option of the pair.
  function optionPair() external view returns (address);

  /// @dev Returns the transaction fee earned by the liquidity providers.
  function transactionFee() external view returns (uint256);

  /// @dev Returns the protocol fee earned by the protocol.
  function protocolFee() external view returns (uint256);

  /// @dev Get the strike and maturity of the pool in the pool enumeration list.
  /// @param id The chosen index.
  function getByIndex(uint256 id) external view returns (StrikeAndMaturity memory);

  /// @dev Get the number of pools being interacted.
  function numberOfPools() external view returns (uint256);

  /// @dev Returns the total amount of liquidity in the pool.
  /// @param strike The strike price of the pool.
  /// @param maturity The maturity of the pool.
  /// @return liquidityAmount The liquidity amount of the pool.
  function totalLiquidity(uint256 strike, uint256 maturity) external view returns (uint160 liquidityAmount);

  /// @dev Returns the square root of the interest rate of the pool.
  /// @dev the square root of interest rate is z/(x+y) where z is the short amount, x+y is the long0 amount, and y is the long1 amount.
  /// @param strike The strike price of the pool.
  /// @param maturity The maturity of the pool.
  /// @return rate The square root of the interest rate of the pool.
  function sqrtInterestRate(uint256 strike, uint256 maturity) external view returns (uint160 rate);

  /// @dev Returns the amount of liquidity owned by the given address.
  /// @param strike The strike price of the pool.
  /// @param maturity The maturity of the pool.
  /// @param owner The address to query the liquidity of.
  /// @return liquidityAmount The amount of liquidity owned by the given address.
  function liquidityOf(uint256 strike, uint256 maturity, address owner) external view returns (uint160 liquidityAmount);

  /// @dev It calculates the global fee and global short returned growth, which is fee increased per unit of liquidity token.
  /// @param strike The strike price of the pool.
  /// @param maturity The maturity of the pool.
  /// @return long0FeeGrowth The global fee increased per unit of liquidity token for long0.
  /// @return long1FeeGrowth The global fee increased per unit of liquidity token for long1.
  /// @return shortFeeGrowth The global fee increased per unit of liquidity token for short.
  /// @return shortReturnedGrowth The global returned increased per unit of liquidity token for short.
  function feesEarnedAndShortReturnedGrowth(
    uint256 strike,
    uint256 maturity
  )
    external
    view
    returns (uint256 long0FeeGrowth, uint256 long1FeeGrowth, uint256 shortFeeGrowth, uint256 shortReturnedGrowth);

  /// @dev It calculates the global fee and global short returned growth, which is fee increased per unit of liquidity token.
  /// @param strike The strike price of the pool.
  /// @param maturity The maturity of the pool.
  /// @param durationForward The duration of time moved forward.
  /// @return long0FeeGrowth The global fee increased per unit of liquidity token for long0.
  /// @return long1FeeGrowth The global fee increased per unit of liquidity token for long1.
  /// @return shortFeeGrowth The global fee increased per unit of liquidity token for short.
  /// @return shortReturnedGrowth The global returned increased per unit of liquidity token for short.
  function feesEarnedAndShortReturnedGrowth(
    uint256 strike,
    uint256 maturity,
    uint96 durationForward
  )
    external
    view
    returns (uint256 long0FeeGrowth, uint256 long1FeeGrowth, uint256 shortFeeGrowth, uint256 shortReturnedGrowth);

  /// @dev It calculates the fee earned and global short returned growth, which is short returned per unit of liquidity token.
  /// @param strike The strike price of the pool.
  /// @param maturity The maturity of the pool.
  /// @param owner The address to query the fees earned of.
  /// @return long0Fees The amount of long0 fees owned by the given address.
  /// @return long1Fees The amount of long1 fees owned by the given address.
  /// @return shortFees The amount of short fees owned by the given address.
  /// @return shortReturned The amount of short returned owned by the given address.
  function feesEarnedAndShortReturnedOf(
    uint256 strike,
    uint256 maturity,
    address owner
  ) external view returns (uint256 long0Fees, uint256 long1Fees, uint256 shortFees, uint256 shortReturned);

  /// @dev It calculates the fee earned and global short returned growth, which is short returned per unit of liquidity token.
  /// @param strike The strike price of the pool.
  /// @param maturity The maturity of the pool.
  /// @param owner The address to query the fees earned of.
  /// @param durationForward The duration of time moved forward.
  /// @return long0Fees The amount of long0 fees owned by the given address.
  /// @return long1Fees The amount of long1 fees owned by the given address.
  /// @return shortFees The amount of short fees owned by the given address.
  /// @return shortReturned The amount of short returned owned by the given address.
  function feesEarnedAndShortReturnedOf(
    uint256 strike,
    uint256 maturity,
    address owner,
    uint96 durationForward
  ) external view returns (uint256 long0Fees, uint256 long1Fees, uint256 shortFees, uint256 shortReturned);

  /// @param strike The strike price of the pool.
  /// @param maturity The maturity of the pool.
  /// @return long0ProtocolFees The amount of long0 protocol fees owned by the owner of the factory contract.
  /// @return long1ProtocolFees The amount of long1 protocol fees owned by the owner of the factory contract.
  /// @return shortProtocolFees The amount of short protocol fees owned by the owner of the factory contract.
  function protocolFeesEarned(
    uint256 strike,
    uint256 maturity
  ) external view returns (uint256 long0ProtocolFees, uint256 long1ProtocolFees, uint256 shortProtocolFees);

  /// @dev Returns the amount of long0 and long1 in the pool.
  /// @param strike The strike price of the pool.
  /// @param maturity The maturity of the pool.
  /// @return long0Amount The amount of long0 in the pool.
  /// @return long1Amount The amount of long1 in the pool.
  function totalLongBalance(
    uint256 strike,
    uint256 maturity
  ) external view returns (uint256 long0Amount, uint256 long1Amount);

  /// @dev Returns the amount of long0 and long1 adjusted for the protocol and transaction fee.
  /// @param strike The strike price of the pool.
  /// @param maturity The maturity of the pool.
  /// @return long0Amount The amount of long0 in the pool, adjusted for the protocol and transaction fee.
  /// @return long1Amount The amount of long1 in the pool, adjusted for the protocol and transaction fee.
  function totalLongBalanceAdjustFees(
    uint256 strike,
    uint256 maturity
  ) external view returns (uint256 long0Amount, uint256 long1Amount);

  /// @dev Returns the amount of sum of long0 and long1 converted to base denomination in the pool.
  /// @dev Returns the amount of short positions in the pool.
  /// @param strike The strike price of the pool.
  /// @param maturity The maturity of the pool.
  /// @return longAmount The amount of sum of long0 and long1 converted to base denomination in the pool.
  /// @return shortAmount The amount of short in the pool.
  function totalPositions(
    uint256 strike,
    uint256 maturity
  ) external view returns (uint256 longAmount, uint256 shortAmount);

  /* ===== UPDATE ===== */

  /// @dev Transfer liquidity positions to another address.
  /// @notice Does not transfer the transaction fees earned by the sender.
  /// @param strike The strike price of the pool.
  /// @param maturity The maturity of the pool.
  /// @param to The recipient of the liquidity positions.
  /// @param liquidityAmount The amount of liquidity positions transferred
  function transferLiquidity(uint256 strike, uint256 maturity, address to, uint160 liquidityAmount) external;

  /// @dev initializes the pool with the given parameters.
  /// @param strike The strike price of the pool.
  /// @param maturity The maturity of the pool.
  /// @param rate The square root of the interest rate of the pool.
  function initialize(uint256 strike, uint256 maturity, uint160 rate) external;

  /// @dev Collects the protocol fees of the pool.
  /// @dev only protocol owner can call this function.
  /// @dev if the owner enters an amount which is greater than the fee amount they have earned, withdraw only the amount they have.
  /// @param param The parameters of the collectProtocolFees.
  /// @return long0Amount The amount of long0 collected.
  /// @return long1Amount The amount of long1 collected.
  /// @return shortAmount The amount of short collected.
  function collectProtocolFees(
    TimeswapV2PoolCollectProtocolFeesParam calldata param
  ) external returns (uint256 long0Amount, uint256 long1Amount, uint256 shortAmount);

  /// @dev Collects the transaction fees of the pool.
  /// @dev only liquidity provider can call this function.
  /// @dev if the owner enters an amount which is greater than the fee amount they have earned, withdraw only the amount they have.
  /// @param param The parameters of the collectTransactionFee.
  /// @return long0Fees The amount of long0 fees collected.
  /// @return long1Fees The amount of long1 fees collected.
  /// @return shortFees The amount of short fees collected.
  /// @return shortReturned The amount of short returned collected.
  function collectTransactionFeesAndShortReturned(
    TimeswapV2PoolCollectTransactionFeesAndShortReturnedParam calldata param
  ) external returns (uint256 long0Fees, uint256 long1Fees, uint256 shortFees, uint256 shortReturned);

  /// @dev deposit Short and Long tokens and mints Liquidity
  /// @dev can be only called before the maturity.
  /// @param param it is a struct that contains the parameters of the mint function
  /// @return liquidityAmount The amount of liquidity minted.
  /// @return long0Amount The amount of long0 deposited.
  /// @return long1Amount The amount of long1 deposited.
  /// @return shortAmount The amount of short deposited.
  /// @return data the data used for the callbacks.
  function mint(
    TimeswapV2PoolMintParam calldata param
  )
    external
    returns (uint160 liquidityAmount, uint256 long0Amount, uint256 long1Amount, uint256 shortAmount, bytes memory data);

  /// @dev deposit Short and Long tokens and mints Liquidity
  /// @dev can be only called before the maturity.
  /// @notice Will always revert with error Quote after the final callback.
  /// @param param it is a struct that contains the parameters of the mint function.
  /// @param durationForward The duration of time moved forward.
  /// @return liquidityAmount The amount of liquidity minted.
  /// @return long0Amount The amount of long0 deposited.
  /// @return long1Amount The amount of long1 deposited.
  /// @return shortAmount The amount of short deposited.
  /// @return data the data used for the callbacks.
  function mint(
    TimeswapV2PoolMintParam calldata param,
    uint96 durationForward
  )
    external
    returns (uint160 liquidityAmount, uint256 long0Amount, uint256 long1Amount, uint256 shortAmount, bytes memory data);

  /// @dev burn Liquidity and receive Short and Long tokens
  /// @dev can be only called before the maturity.
  /// @dev after the maturity of the pool, the long0 and long1 tokens are zero. And the short tokens are added into the transaction fees.
  /// @dev if the user wants to burn the liquidity after the maturity, they should call the collectTransactionFee function.
  /// @param param it is a struct that contains the parameters of the burn function
  /// @return liquidityAmount The amount of liquidity burned.
  /// @return long0Amount The amount of long0 withdrawn.
  /// @return long1Amount The amount of long1 withdrawn.
  /// @return shortAmount The amount of short withdrawn.
  /// @return data the data used for the callbacks.
  function burn(
    TimeswapV2PoolBurnParam calldata param
  )
    external
    returns (uint160 liquidityAmount, uint256 long0Amount, uint256 long1Amount, uint256 shortAmount, bytes memory data);

  /// @dev burn Liquidity and receive Short and Long tokens
  /// @dev can be only called before the maturity.
  /// @dev after the maturity of the pool, the long0 and long1 tokens are zero. And the short tokens are added into the transaction fees.
  /// @dev if the user wants to burn the liquidity after the maturity, they should call the collectTransactionFee function.
  /// @notice Will always revert with error Quote after the final callback.
  /// @param param it is a struct that contains the parameters of the burn function.
  /// @param durationForward The duration of time moved forward.
  /// @return liquidityAmount The amount of liquidity burned.
  /// @return long0Amount The amount of long0 withdrawn.
  /// @return long1Amount The amount of long1 withdrawn.
  /// @return shortAmount The amount of short withdrawn.
  /// @return data the data used for the callbacks.
  function burn(
    TimeswapV2PoolBurnParam calldata param,
    uint96 durationForward
  )
    external
    returns (uint160 liquidityAmount, uint256 long0Amount, uint256 long1Amount, uint256 shortAmount, bytes memory data);

  /// @dev deposit Long tokens and receive Short tokens
  /// @dev can be only called before the maturity.
  /// @param param it is a struct that contains the parameters of the deleverage function
  /// @return long0Amount The amount of long0 deposited.
  /// @return long1Amount The amount of long1 deposited.
  /// @return shortAmount The amount of short received.
  /// @return data the data used for the callbacks.
  function deleverage(
    TimeswapV2PoolDeleverageParam calldata param
  ) external returns (uint256 long0Amount, uint256 long1Amount, uint256 shortAmount, bytes memory data);

  /// @dev deposit Long tokens and receive Short tokens
  /// @dev can be only called before the maturity.
  /// @notice Will always revert with error Quote after the final callback.
  /// @param param it is a struct that contains the parameters of the deleverage function.
  /// @param durationForward The duration of time moved forward.
  /// @return long0Amount The amount of long0 deposited.
  /// @return long1Amount The amount of long1 deposited.
  /// @return shortAmount The amount of short received.
  /// @return data the data used for the callbacks.
  function deleverage(
    TimeswapV2PoolDeleverageParam calldata param,
    uint96 durationForward
  ) external returns (uint256 long0Amount, uint256 long1Amount, uint256 shortAmount, bytes memory data);

  /// @dev deposit Short tokens and receive Long tokens
  /// @dev can be only called before the maturity.
  /// @param param it is a struct that contains the parameters of the leverage function.
  /// @return long0Amount The amount of long0 received.
  /// @return long1Amount The amount of long1 received.
  /// @return shortAmount The amount of short deposited.
  /// @return data the data used for the callbacks.
  function leverage(
    TimeswapV2PoolLeverageParam calldata param
  ) external returns (uint256 long0Amount, uint256 long1Amount, uint256 shortAmount, bytes memory data);

  /// @dev deposit Short tokens and receive Long tokens
  /// @dev can be only called before the maturity.
  /// @notice Will always revert with error Quote after the final callback.
  /// @param param it is a struct that contains the parameters of the leverage function.
  /// @param durationForward The duration of time moved forward.
  /// @return long0Amount The amount of long0 received.
  /// @return long1Amount The amount of long1 received.
  /// @return shortAmount The amount of short deposited.
  /// @return data the data used for the callbacks.
  function leverage(
    TimeswapV2PoolLeverageParam calldata param,
    uint96 durationForward
  ) external returns (uint256 long0Amount, uint256 long1Amount, uint256 shortAmount, bytes memory data);

  /// @dev Deposit Long0 to receive Long1 or deposit Long1 to receive Long0.
  /// @dev can be only called before the maturity.
  /// @param param it is a struct that contains the parameters of the rebalance function
  /// @return long0Amount The amount of long0 received/deposited.
  /// @return long1Amount The amount of long1 deposited/received.
  /// @return data the data used for the callbacks.
  function rebalance(
    TimeswapV2PoolRebalanceParam calldata param
  ) external returns (uint256 long0Amount, uint256 long1Amount, bytes memory data);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {IOwnableTwoSteps} from "./IOwnableTwoSteps.sol";

/// @title The interface for the contract that deploys Timeswap V2 Pool pair contracts
/// @notice The Timeswap V2 Pool Factory facilitates creation of Timeswap V2 Pool pair.
interface ITimeswapV2PoolFactory is IOwnableTwoSteps {
  /* ===== EVENT ===== */

  /// @dev Emits when a new Timeswap V2 Pool contract is created.
  /// @param caller The address of the caller of create function.
  /// @param option The address of the option contract used by the pool.
  /// @param poolPair The address of the Timeswap V2 Pool contract created.
  event Create(address indexed caller, address indexed option, address indexed poolPair);

  /* ===== VIEW ===== */

  /// @dev Returns the address of the Timeswap V2 Option factory contract utilized by Timeswap V2 Pool factory contract.
  function optionFactory() external view returns (address);

  /// @dev Returns the fixed transaction fee used by all created Timeswap V2 Pool contract.
  function transactionFee() external view returns (uint256);

  /// @dev Returns the fixed protocol fee used by all created Timeswap V2 Pool contract.
  function protocolFee() external view returns (uint256);

  /// @dev Returns the address of a Timeswap V2 Pool.
  /// @dev Returns a zero address if the Timeswap V2 Pool does not exist.
  /// @param option The address of the option contract used by the pool.
  /// @return poolPair The address of the Timeswap V2 Pool contract or a zero address.
  function get(address option) external view returns (address poolPair);

  /// @dev Returns the address of a Timeswap V2 Pool.
  /// @dev Returns a zero address if the Timeswap V2 Pool does not exist.
  /// @param token0 The address of the smaller sized address of ERC20.
  /// @param token1 The address of the larger sized address of ERC20.
  /// @return poolPair The address of the Timeswap V2 Pool contract or a zero address.
  function get(address token0, address token1) external view returns (address poolPair);

  function getByIndex(uint256 id) external view returns (address optionPair);

  function numberOfPairs() external view returns (uint256);

  /* ===== UPDATE ===== */

  /// @dev Creates a Timeswap V2 Pool based on option parameter.
  /// @dev Cannot create a duplicate Timeswap V2 Pool with the same option parameter.
  /// @param token0 The address of the smaller sized address of ERC20.
  /// @param token1 The address of the larger sized address of ERC20.
  /// @param poolPair The address of the Timeswap V2 Pool contract created.
  function create(address token0, address token1) external returns (address poolPair);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {Error} from "@timeswap-labs/v2-library/contracts/Error.sol";

import {TimeswapV2PoolMint, TimeswapV2PoolBurn, TimeswapV2PoolDeleverage, TimeswapV2PoolLeverage, TimeswapV2PoolRebalance, TransactionLibrary} from "../enums/Transaction.sol";

/// @dev The parameter for collectProtocolFees functions.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param long0To The recipient of long0 positions.
/// @param long1To The recipient of long1 positions.
/// @param shortTo The recipient of short positions.
/// @param long0Requested The maximum amount of long0 positions wanted.
/// @param long1Requested The maximum amount of long1 positions wanted.
/// @param shortRequested The maximum amount of short positions wanted.
struct TimeswapV2PoolCollectProtocolFeesParam {
  uint256 strike;
  uint256 maturity;
  address long0To;
  address long1To;
  address shortTo;
  uint256 long0Requested;
  uint256 long1Requested;
  uint256 shortRequested;
}

/// @dev The parameter for collectTransactionFeesAndShortReturned functions.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param long0FeesTo The recipient of long0 fees.
/// @param long1FeesTo The recipient of long1 fees.
/// @param shortFeesTo The recipient of short fees.
/// @param shortReturnedTo The recipient of short returned.
/// @param long0FeesRequested The maximum amount of long0 fees wanted.
/// @param long1FeesRequested The maximum amount of long1 fees wanted.
/// @param shortFeesRequested The maximum amount of short fees wanted.
/// @param shortReturnedRequested The maximum amount of short returned wanted.
struct TimeswapV2PoolCollectTransactionFeesAndShortReturnedParam {
  uint256 strike;
  uint256 maturity;
  address long0FeesTo;
  address long1FeesTo;
  address shortFeesTo;
  address shortReturnedTo;
  uint256 long0FeesRequested;
  uint256 long1FeesRequested;
  uint256 shortFeesRequested;
  uint256 shortReturnedRequested;
}

/// @dev The parameter for mint function.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param to The recipient of liquidity positions.
/// @param transaction The type of mint transaction, more information in Transaction module.
/// @param delta If transaction is GivenLiquidity, the amount of liquidity minted. Note that this value must be uint160.
/// If transaction is GivenLong, the amount of long position in base denomination to be deposited.
/// If transaction is GivenShort, the amount of short position to be deposited.
/// @param data The data to be sent to the function, which will go to the mint choice callback.
struct TimeswapV2PoolMintParam {
  uint256 strike;
  uint256 maturity;
  address to;
  TimeswapV2PoolMint transaction;
  uint256 delta;
  bytes data;
}

/// @dev The parameter for burn function.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param long0To The recipient of long0 positions.
/// @param long1To The recipient of long1 positions.
/// @param shortTo The recipient of short positions.
/// @param transaction The type of burn transaction, more information in Transaction module.
/// @param delta If transaction is GivenLiquidity, the amount of liquidity burnt. Note that this value must be uint160.
/// If transaction is GivenLong, the amount of long position in base denomination to be withdrawn.
/// If transaction is GivenShort, the amount of short position to be withdrawn.
/// @param data The data to be sent to the function, which will go to the burn choice callback.
struct TimeswapV2PoolBurnParam {
  uint256 strike;
  uint256 maturity;
  address long0To;
  address long1To;
  address shortTo;
  TimeswapV2PoolBurn transaction;
  uint256 delta;
  bytes data;
}

/// @dev The parameter for deleverage function.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param to The recipient of short positions.
/// @param transaction The type of deleverage transaction, more information in Transaction module.
/// @param delta If transaction is GivenDeltaSqrtInterestRate, the decrease in square root interest rate.
/// If transaction is GivenLong, the amount of long position in base denomination to be deposited.
/// If transaction is GivenShort, the amount of short position to be withdrawn.
/// If transaction is  GivenSum, the sum amount of long position in base denomination to be deposited, and short position to be withdrawn.
/// @param data The data to be sent to the function, which will go to the deleverage choice callback.
struct TimeswapV2PoolDeleverageParam {
  uint256 strike;
  uint256 maturity;
  address to;
  TimeswapV2PoolDeleverage transaction;
  uint256 delta;
  bytes data;
}

/// @dev The parameter for leverage function.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param long0To The recipient of long0 positions.
/// @param long1To The recipient of long1 positions.
/// @param transaction The type of leverage transaction, more information in Transaction module.
/// @param delta If transaction is GivenDeltaSqrtInterestRate, the increase in square root interest rate.
/// If transaction is GivenLong, the amount of long position in base denomination to be withdrawn.
/// If transaction is GivenShort, the amount of short position to be deposited.
/// If transaction is  GivenSum, the sum amount of long position in base denomination to be withdrawn, and short position to be deposited.
/// @param data The data to be sent to the function, which will go to the leverage choice callback.
struct TimeswapV2PoolLeverageParam {
  uint256 strike;
  uint256 maturity;
  address long0To;
  address long1To;
  TimeswapV2PoolLeverage transaction;
  uint256 delta;
  bytes data;
}

/// @dev The parameter for rebalance function.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param to When Long0ToLong1, the recipient of long1 positions.
/// When Long1ToLong0, the recipient of long0 positions.
/// @param isLong0ToLong1 Long0ToLong1 when true. Long1ToLong0 when false.
/// @param transaction The type of rebalance transaction, more information in Transaction module.
/// @param delta If transaction is GivenLong0 and Long0ToLong1, the amount of long0 positions to be deposited.
/// If transaction is GivenLong0 and Long1ToLong0, the amount of long1 positions to be withdrawn.
/// If transaction is GivenLong1 and Long0ToLong1, the amount of long1 positions to be withdrawn.
/// If transaction is GivenLong1 and Long1ToLong0, the amount of long1 positions to be deposited.
/// @param data The data to be sent to the function, which will go to the rebalance callback.
struct TimeswapV2PoolRebalanceParam {
  uint256 strike;
  uint256 maturity;
  address to;
  bool isLong0ToLong1;
  TimeswapV2PoolRebalance transaction;
  uint256 delta;
  bytes data;
}

library ParamLibrary {
  /// @dev Sanity checks
  /// @param param the parameter for collectProtocolFees transaction.
  function check(TimeswapV2PoolCollectProtocolFeesParam memory param) internal pure {
    if (param.long0To == address(0) || param.long1To == address(0) || param.shortTo == address(0)) Error.zeroAddress();
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if ((param.long0Requested == 0 && param.long1Requested == 0 && param.shortRequested == 0) || param.strike == 0)
      Error.zeroInput();
  }

  /// @dev Sanity checks
  /// @param param the parameter for collectTransactionFeesAndShortReturned transaction.
  function check(TimeswapV2PoolCollectTransactionFeesAndShortReturnedParam memory param) internal pure {
    if (
      param.long0FeesTo == address(0) ||
      param.long1FeesTo == address(0) ||
      param.shortFeesTo == address(0) ||
      param.shortReturnedTo == address(0)
    ) Error.zeroAddress();
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (
      (param.long0FeesRequested == 0 &&
        param.long1FeesRequested == 0 &&
        param.shortFeesRequested == 0 &&
        param.shortReturnedRequested == 0) || param.strike == 0
    ) Error.zeroInput();
  }

  /// @dev Sanity checks
  /// @param param the parameter for mint transaction.
  /// @param blockTimestamp the current block timestamp.
  function check(TimeswapV2PoolMintParam memory param, uint96 blockTimestamp) internal pure {
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (param.maturity < blockTimestamp) Error.alreadyMatured(param.maturity, blockTimestamp);
    if (param.to == address(0)) Error.zeroAddress();
    TransactionLibrary.check(param.transaction);
    if (param.delta == 0 || param.strike == 0) Error.zeroInput();
  }

  /// @dev Sanity checks
  /// @param param the parameter for burn transaction.
  /// @param blockTimestamp the current block timestamp.
  function check(TimeswapV2PoolBurnParam memory param, uint96 blockTimestamp) internal pure {
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (param.maturity < blockTimestamp) Error.alreadyMatured(param.maturity, blockTimestamp);
    if (param.long0To == address(0) || param.long1To == address(0) || param.shortTo == address(0)) Error.zeroAddress();

    TransactionLibrary.check(param.transaction);
    if (param.delta == 0 || param.strike == 0) Error.zeroInput();
  }

  /// @dev Sanity checks
  /// @param param the parameter for deleverage transaction.
  /// @param blockTimestamp the current block timestamp.
  function check(TimeswapV2PoolDeleverageParam memory param, uint96 blockTimestamp) internal pure {
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (param.maturity < blockTimestamp) Error.alreadyMatured(param.maturity, blockTimestamp);
    if (param.to == address(0)) Error.zeroAddress();
    TransactionLibrary.check(param.transaction);
    if (param.delta == 0 || param.strike == 0) Error.zeroInput();
  }

  /// @dev Sanity checks
  /// @param param the parameter for leverage transaction.
  /// @param blockTimestamp the current block timestamp.
  function check(TimeswapV2PoolLeverageParam memory param, uint96 blockTimestamp) internal pure {
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (param.maturity < blockTimestamp) Error.alreadyMatured(param.maturity, blockTimestamp);
    if (param.long0To == address(0) || param.long1To == address(0)) Error.zeroAddress();

    TransactionLibrary.check(param.transaction);
    if (param.delta == 0 || param.strike == 0) Error.zeroInput();
  }

  /// @dev Sanity checks
  /// @param param the parameter for rebalance transaction.
  /// @param blockTimestamp the current block timestamp.
  function check(TimeswapV2PoolRebalanceParam memory param, uint96 blockTimestamp) internal pure {
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (param.maturity < blockTimestamp) Error.alreadyMatured(param.maturity, blockTimestamp);
    if (param.to == address(0)) Error.zeroAddress();
    TransactionLibrary.check(param.transaction);
    if (param.delta == 0 || param.strike == 0) Error.zeroInput();
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import {TimeswapV2TokenPosition} from "../structs/Position.sol";
import {TimeswapV2TokenMintParam, TimeswapV2TokenBurnParam} from "../structs/Param.sol";

/// @title An interface for TS-V2 token system
/// @notice This interface is used to interact with TS-V2 positions
interface ITimeswapV2Token is IERC1155 {
  /// @dev Returns the factory address that deployed this contract.
  function optionFactory() external view returns (address);

  /// @dev Returns the position Balance of the owner
  /// @param owner The owner of the token
  /// @param position type of option position (long0, long1, short)
  function positionOf(address owner, TimeswapV2TokenPosition calldata position) external view returns (uint256 amount);

  /// @dev Transfers position token TimeswapV2Token from `from` to `to`
  /// @param from The address to transfer position token from
  /// @param to The address to transfer position token to
  /// @param position The TimeswapV2Token Position to transfer
  /// @param amount The amount of TimeswapV2Token Position to transfer
  function transferTokenPositionFrom(
    address from,
    address to,
    TimeswapV2TokenPosition calldata position,
    uint256 amount
  ) external;

  /// @dev mints TimeswapV2Token as per postion and amount
  /// @param param The TimeswapV2TokenMintParam
  /// @return data Arbitrary data
  function mint(TimeswapV2TokenMintParam calldata param) external returns (bytes memory data);

  /// @dev burns TimeswapV2Token as per postion and amount
  /// @param param The TimeswapV2TokenBurnParam
  function burn(TimeswapV2TokenBurnParam calldata param) external returns (bytes memory data);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {Error} from "@timeswap-labs/v2-library/contracts/Error.sol";

/// @dev parameter for minting Timeswap V2 Tokens
/// @param token0 The first ERC20 token address of the pair.
/// @param token1 The second ERC20 token address of the pair.
/// @param strike  The strike ratio of token1 per token0 of the option.
/// @param maturity The maturity of the option.
/// @param long0To The address of the recipient of TimeswapV2Token representing long0 position.
/// @param long1To The address of the recipient of TimeswapV2Token representing long1 position.
/// @param shortTo The address of the recipient of TimeswapV2Token representing short position.
/// @param long0Amount The amount of long0 deposited.
/// @param long1Amount The amount of long1 deposited.
/// @param shortAmount The amount of short deposited.
/// @param data Arbitrary data passed to the callback.
struct TimeswapV2TokenMintParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address long0To;
  address long1To;
  address shortTo;
  uint256 long0Amount;
  uint256 long1Amount;
  uint256 shortAmount;
  bytes data;
}

/// @dev parameter for burning Timeswap V2 Tokens
/// @param token0 The first ERC20 token address of the pair.
/// @param token1 The second ERC20 token address of the pair.
/// @param strike  The strike ratio of token1 per token0 of the option.
/// @param maturity The maturity of the option.
/// @param long0To  The address of the recipient of long token0 position.
/// @param long1To The address of the recipient of long token1 position.
/// @param shortTo The address of the recipient of short position.
/// @param long0Amount  The amount of TimeswapV2Token long0  deposited and equivalent long0 position is withdrawn.
/// @param long1Amount The amount of TimeswapV2Token long1 deposited and equivalent long1 position is withdrawn.
/// @param shortAmount The amount of TimeswapV2Token short deposited and equivalent short position is withdrawn,
/// @param data Arbitrary data passed to the callback, initalize as empty if not required.
struct TimeswapV2TokenBurnParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address long0To;
  address long1To;
  address shortTo;
  uint256 long0Amount;
  uint256 long1Amount;
  uint256 shortAmount;
  bytes data;
}

/// @dev parameter for minting Timeswap V2 Liquidity Tokens
/// @param token0 The first ERC20 token address of the pair.
/// @param token1 The second ERC20 token address of the pair.
/// @param strike  The strike ratio of token1 per token0 of the option.
/// @param maturity The maturity of the option.
/// @param to The address of the recipient of TimeswapV2LiquidityToken.
/// @param liquidityAmount The amount of liquidity token deposited.
/// @param data Arbitrary data passed to the callback.
/// @param erc1155Data Arbitrary custojm data passed through erc115 minting.
struct TimeswapV2LiquidityTokenMintParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address to;
  uint160 liquidityAmount;
  bytes data;
  bytes erc1155Data;
}

/// @dev parameter for burning Timeswap V2 Liquidity Tokens
/// @param token0 The first ERC20 token address of the pair.
/// @param token1 The second ERC20 token address of the pair.
/// @param strike  The strike ratio of token1 per token0 of the option.
/// @param maturity The maturity of the option.
/// @param to The address of the recipient of the liquidity token.
/// @param liquidityAmount The amount of liquidity token withdrawn.
/// @param data Arbitrary data passed to the callback, initalize as empty if not required.
struct TimeswapV2LiquidityTokenBurnParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address to;
  uint160 liquidityAmount;
  bytes data;
}

/// @dev parameter for collecting fees and shortReturned from Timeswap V2 Liquidity Tokens
/// @param token0 The first ERC20 token address of the pair.
/// @param token1 The second ERC20 token address of the pair.
/// @param strike  The strike ratio of token1 per token0 of the option.
/// @param maturity The maturity of the option.
/// @param from The address of the owner of the fees and shortReturned;
/// @param long0FeesTo The address of the recipient of the long0 fees.
/// @param long1FeesTo The address of the recipient of the long1 fees.
/// @param shortFeesTo The address of the recipient of the short fees.
/// @param shortReturnedTo The address of the recipient of the short returned.
/// @param long0FeesDesired The maximum amount of long0Fees desired to be withdrawn.
/// @param long1FeesDesired The maximum amount of long1Fees desired to be withdrawn.
/// @param shortFeesDesired The maximum amount of shortFees desired to be withdrawn.
/// @param shortReturnedDesired The maximum amount of shortReturned desired to be withdrawn.
/// @param data Arbitrary data passed to the callback, initalize as empty if not required.
struct TimeswapV2LiquidityTokenCollectParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address from;
  address long0FeesTo;
  address long1FeesTo;
  address shortFeesTo;
  address shortReturnedTo;
  uint256 long0FeesDesired;
  uint256 long1FeesDesired;
  uint256 shortFeesDesired;
  uint256 shortReturnedDesired;
  bytes data;
}

library ParamLibrary {
  /// @dev Sanity checks for token mint.
  function check(TimeswapV2TokenMintParam memory param) internal pure {
    if (param.long0To == address(0) || param.long1To == address(0) || param.shortTo == address(0)) Error.zeroAddress();
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (param.long0Amount == 0 && param.long1Amount == 0 && param.shortAmount == 0) Error.zeroInput();
  }

  /// @dev Sanity checks for token burn.
  function check(TimeswapV2TokenBurnParam memory param) internal pure {
    if (param.long0To == address(0) || param.long1To == address(0) || param.shortTo == address(0)) Error.zeroAddress();
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (param.long0Amount == 0 && param.long1Amount == 0 && param.shortAmount == 0) Error.zeroInput();
  }

  /// @dev Sanity checks for liquidity token mint.
  function check(TimeswapV2LiquidityTokenMintParam memory param) internal pure {
    if (param.to == address(0)) Error.zeroAddress();
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (param.liquidityAmount == 0) Error.zeroInput();
  }

  /// @dev Sanity checks for liquidity token burn.
  function check(TimeswapV2LiquidityTokenBurnParam memory param) internal pure {
    if (param.to == address(0)) Error.zeroAddress();
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (param.liquidityAmount == 0) Error.zeroInput();
  }

  /// @dev Sanity checks for liquidity token collect.
  function check(TimeswapV2LiquidityTokenCollectParam memory param) internal pure {
    if (
      param.from == address(0) ||
      param.long0FeesTo == address(0) ||
      param.long1FeesTo == address(0) ||
      param.shortFeesTo == address(0) ||
      param.shortReturnedTo == address(0)
    ) Error.zeroAddress();
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (
      param.long0FeesDesired == 0 &&
      param.long1FeesDesired == 0 &&
      param.shortFeesDesired == 0 &&
      param.shortReturnedDesired == 0
    ) Error.zeroInput();
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {TimeswapV2OptionPosition} from "@timeswap-labs/v2-option/contracts/enums/Position.sol";

/// @dev Struct for Token
/// @param token0 The first ERC20 token address of the pair.
/// @param token1 The second ERC20 token address of the pair.
/// @param strike  The strike ratio of token1 per token0 of the option.
/// @param maturity The maturity of the option.
/// @param position The position of the option.
struct TimeswapV2TokenPosition {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  TimeswapV2OptionPosition position;
}

/// @dev Struct for Liquidity Token
/// @param token0 The first ERC20 token address of the pair.
/// @param token1 The second ERC20 token address of the pair.
/// @param strike  The strike ratio of token1 per token0 of the option.
/// @param maturity The maturity of the option.
struct TimeswapV2LiquidityTokenPosition {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
}

library PositionLibrary {
  /// @dev return keccak for key management for Token.
  function toKey(TimeswapV2TokenPosition memory timeswapV2TokenPosition) internal pure returns (bytes32) {
    return keccak256(abi.encode(timeswapV2TokenPosition));
  }

  /// @dev return keccak for key management for Liquidity Token.
  function toKey(
    TimeswapV2LiquidityTokenPosition memory timeswapV2LiquidityTokenPosition
  ) internal pure returns (bytes32) {
    return keccak256(abi.encode(timeswapV2LiquidityTokenPosition));
  }
}