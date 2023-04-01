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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "./EIP712Allowlisting.sol";
import "./Phaseable.sol";
import "./Phaseable.sol";
import "./Nameable.sol";
import { Phase, PhaseNotActiveYet, PhaseExhausted, WalletMintsFilled } from "./SetPhaseable.sol";

abstract contract Allowable is EIP712Allowlisting, DefaultOperatorFilterer {  
    
    constructor(string memory name, string memory symbol) Nameable(name,symbol) {
        setSigningAddress(msg.sender);
        setDomainSeparator(name, "V4");
        initializePhases();
    }

    function initializePhases() internal virtual;

    function canMint(uint64 phase, uint256 quantity) internal override virtual returns(bool) {
        uint64 activePhase = activePhase();
        if (phase > activePhase) {
            revert PhaseNotActiveYet();
        }
        uint256 requestedSupply = totalSupply()+quantity;
        Phase memory requestedPhase = findPhase(phase);
        if (requestedSupply > requestedPhase.highestSupply) {
            revert PhaseExhausted();
        }
       
        uint256 requestedMints = quantity+numMints(msg.sender,phase);
        if (requestedPhase.maxPerWallet > 0 && requestedMints > requestedPhase.maxPerWallet) {
            revert WalletMintsFilled(requestedMints);
        }
        return true;
    }
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }      
}

/**
 * Ordo Signum Machina - 2023
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./Ownable.sol";
import "./Nameable.sol";
import { TokenNonOwner } from "./SetOwnerEnumerable.sol";
import { UnpackedOwnerEnumerable } from "./UnpackedOwnerEnumerable.sol";
import { SetApprovable, ApprovableData, TokenNonExistent } from "./SetApprovable.sol";

abstract contract Approvable is UnpackedOwnerEnumerable {  
    using SetApprovable for ApprovableData; 
    ApprovableData approvable;

    

    function _checkTokenOwner(uint256 tokenId) internal view virtual {
        if (ownerOf(tokenId) != msg.sender) {
            revert TokenNonOwner(msg.sender, tokenId);
        }
    }    
 
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return approvable.isApprovedForAll(owner,operator);
    }  

    function approve(address to, uint256 tokenId) public virtual override {  
        _checkTokenOwner(tokenId);      
        approvable.approveForToken(to, tokenId);
        emit Approval(ownerOf(tokenId), to, tokenId);        
    }  

    function setApprovalForAll(address operator, bool approved) public virtual override {   
        approved ? approvable.approveForContract(operator): approvable.revokeApprovalForContract(operator, msg.sender);
    }       

    function validateApprovedOrOwner(address spender, uint256 tokenId) internal view {        
        if (!(spender == ownerOf(tokenId) || isApprovedForAll(ownerOf(tokenId), spender) || approvable.getApproved(tokenId) == spender)) {
            revert TokenNonOwner(spender, tokenId);
        }
    }  

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        requireMinted(tokenId);
        return approvable.tokens[tokenId].approval;
    }       

    function revokeTokenApproval(uint256 tokenId) internal {
        approvable.revokeTokenApproval(tokenId);
    }

    function revokeApprovals(address holder) internal {
        approvable.revokeApprovals(holder,tokensOwnedBy(holder));                    
    }


    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function requireMinted(uint256 tokenId) internal view virtual {
        if (!exists(tokenId)) {
            revert TokenNonExistent(tokenId);
        }
    }       
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import { SetAssignable, AssignableData, NotTokenOwner, NotAssigned } from "./SetAssignable.sol";
import { UnpackedOwnerEnumerable } from "./UnpackedOwnerEnumerable.sol";
import "./Phaseable.sol";


abstract contract Assignable is Phaseable {  
    using SetAssignable for AssignableData;
    AssignableData assignables;
    
    function assignColdStorage(uint256 tokenId) external {        
        if (msg.sender != ownerOf(tokenId)) {
            revert NotTokenOwner();
        }
        assignables.addAssignment(msg.sender,tokenId);
    }
    
    function revokeColdStorage(uint256 tokenId) external {        
        if (assignables.findAssignment(msg.sender) != tokenId) {
            revert NotAssigned(msg.sender);
        }
        assignables.removeAssignment(msg.sender);
    }   
    
    function revokeAssignments(uint256 tokenId) external {        
        if (msg.sender != ownerOf(tokenId)) {
            revert NotTokenOwner();
        }
        assignables.revokeAll(tokenId);
    }    
    
    function findAssignments(uint256 tokenId) external view returns (address[] memory){        
        return assignables.findAssignees(tokenId);
    }        

    function balanceOf(address seekingContract, address owner) external view returns (uint256) {        
        uint256 guardianBalance = balanceOf(owner);
        if (guardianBalance > 0) {
            uint256[] memory guardians = tokensOwnedBy(owner);
            return assignables.iterateGuardiansBalance(guardians, seekingContract, 0);
        }
        return 0;
    }     
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./EIP712Listable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";



bytes32 constant BAG_MINT_TYPE =
    keccak256("Minter(string genesisBagAddress)");

bytes32 constant FREE_MINT_TYPE =
    keccak256("Minter(string genesisStakedAddress)");    

struct Minter {
    address wallet;
    uint256 tokenSum;
}

struct Public {
    address wallet;
    uint256 tokenSum;
}

abstract contract EIP712Allowlisting is EIP712Listable {
    using ECDSA for bytes32;
    using Strings for uint256;
    using Strings for uint160;
    using Strings for address;

    uint256[] empty;
         
    error RecoveredKeyInvalid(address recovered, address signingKey);
    bytes32 constant ALLOW_MINT_TYPE = keccak256("Minter(address wallet,uint256 tokenSum)");
    function verifyAllow(bytes calldata signature, uint256[] memory tokenIds, address recip) public view returns (bool) {
        uint256 sum = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            sum += tokenIds[i];
        }
        bytes32 hash = keccak256(abi.encodePacked(
            "\x19\x01", 
            DOM_SEP, 
            keccak256(abi.encode(ALLOW_MINT_TYPE,Minter(recip,sum)))
        ));
        address signer = hash.recover(signature);
        if(signer != sigKey) revert RecoveredKeyInvalid(signer,sigKey);   
        return true;     
    }

    bytes32 constant OPEN_MINT_TYPE = keccak256("Public(address wallet,uint256 tokenSum)");
    function verifyOpen(bytes calldata signature, uint256[] memory tokenIds, address recip) public view returns (bool) {
        uint256 sum = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            sum += tokenIds[i];
        }
        bytes32 hash = keccak256(abi.encodePacked(
            "\x19\x01", 
            DOM_SEP, 
            keccak256(abi.encode(OPEN_MINT_TYPE,Public(recip,sum)))
        ));
        address signer = hash.recover(signature);
        if(signer != sigKey) revert RecoveredKeyInvalid(signer,sigKey);       
        return true;      
    }        
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "./Assignable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

abstract contract EIP712Listable is Assignable {
    using ECDSA for bytes32;

    address internal sigKey = address(0);

    bytes32 internal DOM_SEP;    

    uint256 chainid = 420;

    function setDomainSeparator(string memory _name, string memory _version) internal {
        DOM_SEP = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(_name)),
                keccak256(bytes(_version)),
                chainid,
                address(this)
            )
        );
    }

    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(DOM_SEP, structHash);
    }    

    function getSigningAddress() public view returns (address) {
        return sigKey;
    }

    function setSigningAddress(address _sigKey) public onlyOwner {
        sigKey = _sigKey;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == owner();
    }
  
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "./Approvable.sol";
import { SetLockable, LockableStatus,  LockableData, WalletLockedByOwner } from "./SetLockable.sol";
abstract contract Lockable is Approvable {    
    using SetLockable for LockableData; 
    LockableData lockable;

    bool soulBound = false;

    function custodianOf(uint256 id)
        public
        view
        returns (address)
    {             
        return lockable.findCustodian(ownerOf(id));
    }     

    function lockWallet(uint256 id) public {           
        revokeApprovals(ownerOf(id));
        lockable.lockWallet(ownerOf(id));
    }

    function unlockWallet(uint256 id) public {              
        lockable.unlockWallet(ownerOf(id));
    }    

    function _forceUnlock(uint256 id) internal {  
        lockable.forceUnlock(ownerOf(id));
    }    

    function setCustodian(uint256 id, address custodianAddress) public {       
        lockable.setCustodian(custodianAddress,ownerOf(id));
    }

    function isLocked(uint256 id) public view returns (bool) {     
        if (enumerationExists(id)) {
            return lockable.lockableStatus[ownerOf(id)].isLocked;
        }
        return false;
    } 

    function lockedSince(uint256 id) public view returns (uint256) {     
        return lockable.lockableStatus[ownerOf(id)].lockedAt;
    }     

    function validateLock(uint256 tokenId) internal view {
        if (isLocked(tokenId)) {
            revert WalletLockedByOwner();
        }
    }

    function soulBind() internal {
        soulBound = true;
    }
    
    function releaseSoul() internal {
        soulBound = false;
    }    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./Lockable.sol";
import { LockableStatus,InvalidTransferRecipient,ContractIsNot721Receiver } from "./SetLockable.sol";



abstract contract LockableTransferrable is Lockable {  
    using Address for address;

    function approve(address to, uint256 tokenId) public virtual override {  
        validateLock(tokenId);
        super.approve(to,tokenId);      
    }  

    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (tokensOwnedBy(msg.sender).length > 0) {
            validateLock(tokensOwnedBy(msg.sender)[0]);
        }
        super.setApprovalForAll(operator,approved);     
    }        

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {        
        validateApprovedOrOwner(msg.sender, tokenId);
        validateLock(tokenId);
        _transfer(from,to,tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
                
        if(to == address(0)) {
            revert InvalidTransferRecipient();
        }

        revokeTokenApproval(tokenId);   

        if (enumerationExists(tokenId)) {
            swapOwner(from,to,tokenId);
        }        

        completeTransfer(from,to,tokenId);    
    }   

    
    function completeTransfer(
        address from,
        address to,
        uint256 tokenId) internal {
        emit Transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }    

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        validateApprovedOrOwner(msg.sender, tokenId);
        validateLock(tokenId);
        _safeTransfer(from, to, tokenId, data);
    }     

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        if (!_checkOnERC721Received(from, to, tokenId, data)) {
            revert ContractIsNot721Receiver();
        }        
        _transfer(from, to, tokenId);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert InvalidTransferRecipient();
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }    

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";


abstract contract Nameable is IERC721Metadata {   
    string named;
    string symbolic;

    constructor(string memory _name, string memory _symbol) {
        named = _name;
        symbolic = _symbol;
    }

    function name() public virtual override view returns (string memory) {
        return named;
    }  

    function symbol() public virtual override view returns (string memory) {
        return symbolic;
    }          
      
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

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
abstract contract Ownable {
    address private _owner;

    error CallerIsNotOwner(address caller);
    error OwnerCannotBeZeroAddress();

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
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
        if (owner() != msg.sender) {
            revert CallerIsNotOwner(msg.sender);
        }
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
        if(newOwner == address(0)) {
            revert OwnerCannotBeZeroAddress();
        }
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
pragma solidity ^0.8.18;
import "./Allowable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./Nameable.sol";
import { SetMetadataRenderable, RenderableData, Color } from "./SetMetadataRenderable.sol";
import { InvalidToken } from "./UnpackedMintable.sol";

error Unphased();
error InvalidPayment(uint256);
error InvalidDate(uint256 date);
error TextIsTooLong();
error InvalidColor();

/// @title Ownion
/// @author @OsmOnomous https://osm.tools
contract Ownion is Allowable {    
    using Strings for uint256;
    using Strings for uint128;
    using SetMetadataRenderable for RenderableData;
    RenderableData renderings;
    // minting phases
    uint64 constant ALLOW_PHASE = 0;
    uint64 constant OPEN_PHASE = 1;

    // supply and allowances
    uint64 constant MAX_SUPPLY = 1001;

    // allowed phase
    uint64 constant ALLOW_PER = MAX_SUPPLY;
    uint64 constant ALLOW_SUPPLY = MAX_SUPPLY;
    uint64 constant ALLOW_PRICE = 0; 

    uint64 constant OPEN_PER = MAX_SUPPLY;
    uint64 constant OPEN_SUPPLY = MAX_SUPPLY;
    uint64 constant OPEN_PRICE = 10 ether; 
    
    bytes constant defaultText = "Ownion";
    uint constant DAY_IN_SECONDS = 86400;

    uint256 modifyPrice = 1 ether;

    uint128 min_year = 1900;
    uint128 royalty_basis = 1000;
    address payable TREASURY = payable(0x01fDCE143227494860F50974bE940ef47F3754cf);
    address payable OSM_TREASURY = payable(0x5aE09f46967A92f3cF976e98f82B6FDd00784815);

    Color defaultColor = Color(262,75,59); 
    Color defaultTextColor = Color(262,100,100);      
    
   /**
     * Initialization
     */
        
    /// @notice contract is initialized as soul bound, no transfers or approvals allowed
    constructor() Allowable("Ownion","OWN") {        
        initializePhases();        
    }

    /// @notice initialization of minting phases
    function initializePhases() internal virtual override {
        Phase[] storage phases = getPhases();

        // Phase struct
        // name, maxPerWallet (0 indicates no limit), maxMint, price
        phases.push(Phase(ALLOW_PHASE, ALLOW_PER, ALLOW_SUPPLY, ALLOW_PRICE));
        phases.push(Phase(OPEN_PHASE, OPEN_PER, OPEN_SUPPLY, OPEN_PRICE));
        
        initialize(phases,MAX_SUPPLY);        
    }

    

    /**
     * Minting & Burning
     */      

    /// @notice minting ALLOW_PHASE, requires trusted signature, maximum quantity 1 per wallet       
    /// @param tokenIds uint256[] dates to mint    
    /// @param signature bytes trusted signature 
    function allowlistMint(uint256[] memory tokenIds, bytes calldata signature) external {   
        validates(tokenIds);          
        verifyAllow(signature,tokenIds,msg.sender);
        phasedMint(ALLOW_PHASE, tokenIds);
        addMints(msg.sender,ALLOW_PHASE,tokenIds.length);
    }

    
    /// @notice minting OPEN_PHASE, requires trusted signature and mint fee of 1 matic, no maximum quantity per wallet    
    /// @param tokenIds uint256[] dates to mint    
    /// @param signature bytes trusted signature 
    function openMint(uint256[] memory tokenIds, bytes calldata signature) external payable {  
        validates(tokenIds);     
        verifyOpen(signature,tokenIds,msg.sender);
        phasedMint(OPEN_PHASE, tokenIds);
        if (msg.value < (.01 ether * tokenIds.length)) {
            revert InvalidPayment(msg.value);
        }
        addMints(msg.sender,OPEN_PHASE,tokenIds.length);
    }      

    /// @notice burn function
    /// @param tokenId uint256 token id to burn
    function burn(uint256 tokenId) external {
        validateApprovedOrOwner(msg.sender, tokenId);
        
        validateLock(tokenId);   

        _transfer(msg.sender,address(0),tokenId);

        if (enumerationExists(tokenId)) {
            enumerateBurn(msg.sender,tokenId);
            selfDestruct(tokenId);
        }
    }



    /**
     * Owner Utility and Managment of TREASURY 
     */      

    /// @notice withdraw funds to treasury
    function withdrawFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        OSM_TREASURY.transfer(balance / 100 * 5);
        TREASURY.transfer(balance / 100 * 95);
    } 

    /// @notice set treasury wallet address
    function assignFundRecipient(address treasury) external onlyOwner {
        TREASURY = payable(treasury);
    }         

    /// @notice establishes the cost of a mint for the specified phase
    /// @param phase uint256 the phase to set the mint price for
    /// @param price uint64 price of mint during phase
    function setMintPrice(uint256 phase, uint256 price) external onlyOwner {
        Phase memory existing = findPhase(phase);
        existing.cost = price;
        updatePhase(phase, existing);
    }

    /// @notice determines the price for a minting phase
    /// @param phase uint256 the phase to get the mint price for
    function getMintPrice(uint256 phase) external view returns (uint256) {
        Phase memory existing = findPhase(phase);
        return existing.cost;
    }    

    /// @notice establishes the cost to modify your nft
    /// @param price uint64 price of modifications
    function setModifyPrice(uint64 price) external onlyOwner {
        modifyPrice = price;
    }

    /// @notice determines the modify price
    function getModifyPrice() external view returns (uint256) {
        return modifyPrice;
    }  

    /// @notice establishes the minimum year that can be minted
    /// @param price uint256 minimum year for minting
    function setModifyPrice(uint256 price) external onlyOwner {
        modifyPrice = price;
    }   

    /// @notice gets the royalty basis points
    function getRoyaltyBasis() external view returns (uint256) {
        return modifyPrice;
    }  

    /// @notice establishes the minimum year that can be minted
    /// @param _royalty_basis uint128 basis points for royalty payments
    function setRoyaltyBasis(uint128 _royalty_basis) external onlyOwner {
        royalty_basis = _royalty_basis;
    }           

    /**
     * Validation
     */  

    /// @notice date validation: cannot be more recent than 7 days
    /// @param tokenIds uint256[] dates to mint  
    function validates(uint256[] memory tokenIds) internal view {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 remainder = tokenIds[i] % 10000;
            uint256 year = tokenIds[i] / 10000;
            uint256 month = remainder / 100;
            uint256 dates = remainder % 100;              
            if (block.timestamp > renderings.toTimestamp(uint16(year),uint8(month),uint8(dates))) {
                if (year < min_year) revert InvalidDate(year);   
            }
            else if (renderings.toTimestamp(uint16(year),uint8(month),uint8(dates))-block.timestamp > DAY_IN_SECONDS * 7) revert InvalidDate(tokenIds[i]);   
        }        
    }       

    /**
     * Metadata
     */      

    /// @notice base 64 encode token metadata data URI
    /// @param tokenId uint256 tokenId to encode
    function encodedTokenURI(uint256 tokenId) internal view returns (string memory) { 
        
        Color memory color = renderings.colorMapping[tokenId].exists ? 
        renderings.colorMapping[tokenId].color : 
        defaultColor;

        Color memory textColor = renderings.textColorMapping[tokenId].exists ? 
        renderings.textColorMapping[tokenId].color : 
        defaultTextColor;        
        
        bytes memory text = renderings.textMapping[tokenId].exists ? 
        renderings.textMapping[tokenId].text : 
        defaultText;

        bytes memory date = renderings.dateMapping[tokenId].exists ? 
        renderings.dateMapping[tokenId].date : 
        abi.encodePacked(
            renderings.substring(abi.encodePacked(tokenId.toString()),0,4),
            '-',
            renderings.substring(abi.encodePacked(tokenId.toString()),4,6),
            '-',
            renderings.substring(abi.encodePacked(tokenId.toString()),6,8));

        
        //bytes memory date, bytes memory text, Color memory background, Color memory backdrop
        bytes memory dataURI = abi.encodePacked(
            '{',
                '"name": "Ownion @ ', tokenId.toString(),
                '","description": "',string(renderings.getDescription()),'"', 
                ',"image":"',string(renderings.getImage(date, text, color, textColor)),'"', // background, textcolor
                ',"external_url":"https://ownion.com"',
                ',"attributes":', string(renderings.getAttributes(date, text, color, textColor)),
            '}'
        );

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(dataURI)
            )
        );
    }     

    /// @notice ERC721 tokenURI
    /// @param tokenId uint256 tokenId to encode    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {   
        if (!exists(tokenId)) {
            revert InvalidToken(tokenId);
        }
        return encodedTokenURI(tokenId);
    }      

    /// @notice ERC721 contractURI 
    function contractURI() public view returns (string memory) {   
        return renderings.encodedContractURI(defaultColor, defaultTextColor, royalty_basis, address(this));
    }           

    /**
     * Holder modifications
     */          

    // /// @notice set text for metadata and SVG
    // /// @param tokenId uint256 tokenId to set text for
    // /// @param text string to add to token
    // function setText(uint256 tokenId, string memory text) public payable {
    //     validateApprovedOrOwner(msg.sender,tokenId);
    //     if (msg.value < modifyPrice) {
    //         revert InvalidPayment(msg.value);
    //     }        
    //     bytes memory bitten = abi.encodePacked(text);
    //     if (bitten.length > 11) {
    //         revert TextIsTooLong();
    //     }
    //     renderings.setText(tokenId, bitten);
    // }
    

    /// @notice set background color for metadata and SVG
    /// @param tokenId uint256 tokenId to set text for
    /// @param hue uint64 HSL hue 0-360
    /// @param sat uint64 HSL saturation 0-100
    /// @param light uint64 HSL light 0-100 
    function setColor(uint256 tokenId, uint64 hue, uint64 sat, uint64 light) public payable {
        validateApprovedOrOwner(msg.sender,tokenId);
        if (msg.value < modifyPrice) {
            revert InvalidPayment(msg.value);
        }                
        if (hue > 360 || sat > 100 || light > 100 ) {
            revert InvalidColor();
        }
        renderings.setColor(tokenId, Color(hue,sat,light));
    }   

    /// @notice set text color for metadata and SVG
    /// @param tokenId uint256 tokenId to set text for
    /// @param hue uint64 HSL hue 0-360
    /// @param sat uint64 HSL saturation 0-100
    /// @param light uint64 HSL light 0-100     
    function setTextColor(uint256 tokenId, uint64 hue, uint64 sat, uint64 light) public payable {
        validateApprovedOrOwner(msg.sender,tokenId);
        if (msg.value < modifyPrice) {
            revert InvalidPayment(msg.value);
        }                
        if (hue > 360 || sat > 100 || light > 100 ) {
            revert InvalidColor();
        }
        renderings.setTextColor(tokenId, Color(hue,sat,light));
    }    

}

/**
 * Ordo Signum Machina - 2023
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import { SetPhaseable, PhaseableData, MintIsNotAllowedRightNow, ExceedsMaxSupply, Phase } from "./SetPhaseable.sol";
import { UnpackedOwnerEnumerable } from "./UnpackedOwnerEnumerable.sol";
import "./UnpackedMintable.sol";


abstract contract Phaseable is UnpackedMintable {  
    using SetPhaseable for PhaseableData;
    PhaseableData phaseables;    
    
    function canMint(uint64 phase, uint256 quantity) internal virtual returns(bool);

    function initialize(Phase[] storage phases, uint256 maxSupply) internal {
        phaseables.initialize(phases,maxSupply);
    }

    function phasedMint(uint64 phase, uint256[] memory tokenIds) internal {
        if (!canMint(phase, tokenIds.length)) {
            revert MintIsNotAllowedRightNow();
        }        
        if (phaseables.getMaxSupply() > 0) {
            if (totalSupply()+tokenIds.length > phaseables.getMaxSupply()) {
                revert ExceedsMaxSupply();
            }            
        }        
        _batchMint(msg.sender,tokenIds);        
    }

    function airdrop(address recipient, uint256[] memory tokenIds) public onlyOwner {     
        if (phaseables.getMaxSupply() > 0) {   
            if (totalSupply()+tokenIds.length > phaseables.getMaxSupply()) {
                revert ExceedsMaxSupply();
            }
        }
        _batchMint(recipient,tokenIds);
    }

    function activePhase() internal view returns (uint64) {
        return phaseables.getActivePhase();
    }

    function nextPhase() public onlyOwner {
        phaseables.startNextPhase();
    }

    function previousPhase() public onlyOwner {
        phaseables.revertPhase();
    }    

    function getPhases() internal view returns (Phase[] storage) {
        return phaseables.getPhases();
    }

    function findPhase(uint256 phaseId) internal view returns (Phase memory) {
        return phaseables.findPhase(phaseId);
    }

    function updatePhase(uint256 phaseId, Phase memory phase) internal {
        Phase[] storage existing = phaseables.getPhases();
        existing[phaseId] = phase;
    }    

    function getMaxSupply() internal view returns (uint256) {
        return phaseables.getMaxSupply();
    }  

    function setMaxSupply(uint256 newMax) internal {
        phaseables.setMaxSupply(newMax);
    }    

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

struct ApprovableData { 

    mapping(address => uint256) contractApprovals;
    mapping(address => address[]) approvedForAll;
    mapping(address => mapping(address => uint256)) approvedForAllIndex;

    mapping(uint256 => uint256) tokenApprovals;
    mapping(uint256 => TokenApproval[]) approvedForToken;
    mapping(uint256 => mapping(address => uint256)) approvedForTokenIndex;

    mapping(uint256 => TokenApproval) tokens;

    bool exists;
}    

struct TokenApproval {
    address approval;
    bool exists;
}

error AlreadyApproved(address operator, uint256 tokenId);
error AlreadyApprovedContract(address operator);
error AlreadyRevoked(address operator, uint256 tokenId);
error AlreadyRevokedContract(address operator);
error TokenNonExistent(uint256 tokenId);


library SetApprovable {     

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);    

    function isApprovedForAll(ApprovableData storage self, address owner, address operator) public view returns (bool) {        
        return self.approvedForAll[owner].length > self.approvedForAllIndex[owner][operator] ? 
            (self.approvedForAll[owner][self.approvedForAllIndex[owner][operator]] != address(0)) :
            false;
    }   

    function revokeApprovals(ApprovableData storage self, address owner, uint256[] memory ownedTokens) public {            
        
        for (uint256 i = 0; i < ownedTokens.length; i++) {
            revokeTokenApproval(self,ownedTokens[i]);
        }
        
        address[] memory contractApprovals = self.approvedForAll[owner];
        for (uint256 i = 0; i < contractApprovals.length; i++) {
            address approved = contractApprovals[i];    
            revokeApprovalForContract(self, approved, owner);             
        }
    }   

    function revokeTokenApproval(ApprovableData storage self, uint256 token) public {            
        TokenApproval[] memory approvals = self.approvedForToken[token];
        for (uint256 j = 0; j < approvals.length; j++) {
            revokeApprovalForToken(self, approvals[j].approval, token);
        }         
    }       

    function getApproved(ApprovableData storage self, uint256 tokenId) public view returns (address) {
        return self.approvedForToken[tokenId].length > 0 ? self.approvedForToken[tokenId][0].approval : address(0);
    }     

    function approveForToken(ApprovableData storage self, address operator, uint256 tokenId) public {
        uint256 index = self.approvedForTokenIndex[tokenId][operator];
        if (index < self.approvedForToken[tokenId].length) {
            if (self.approvedForToken[tokenId][index].exists) {
                revert AlreadyApproved(operator, tokenId);
            }            
        }
   
        self.approvedForToken[tokenId].push(TokenApproval(operator,true));
        self.approvedForTokenIndex[tokenId][operator] = self.approvedForToken[tokenId].length-1;
        self.tokenApprovals[tokenId]++;
        
        emit Approval(msg.sender, operator, tokenId); 
    } 

    function revokeApprovalForToken(ApprovableData storage self, address revoked, uint256 tokenId) public {
        uint256 index = self.approvedForTokenIndex[tokenId][revoked];
        if (!self.approvedForToken[tokenId][index].exists) {
            revert AlreadyRevoked(revoked,tokenId);
        }
        
        // When the token to delete is not the last token, the swap operation is unnecessary
        if (index != self.approvedForToken[tokenId].length - 1) {
            TokenApproval storage tmp = self.approvedForToken[tokenId][self.approvedForToken[tokenId].length - 1];
            self.approvedForToken[tokenId][self.approvedForToken[tokenId].length - 1] = self.approvedForToken[tokenId][index];
            self.approvedForToken[tokenId][index] = tmp;
            self.approvedForTokenIndex[tokenId][tmp.approval] = index;            
        }

        // This also deletes the contents at the last position of the array
        delete self.approvedForTokenIndex[tokenId][revoked];
        self.approvedForToken[tokenId].pop();

        self.tokenApprovals[tokenId]--;
    }

    function approveForContract(ApprovableData storage self, address operator) public {
        uint256 index = self.approvedForAllIndex[msg.sender][operator];
        if (self.approvedForAll[msg.sender].length > index) {
            if (self.approvedForAll[msg.sender][index] != address(0)) {
                revert AlreadyApprovedContract(self.approvedForAll[msg.sender][index]);
            }
        }
   
        self.approvedForAll[msg.sender].push(operator);
        self.approvedForAllIndex[msg.sender][operator] = self.approvedForAll[msg.sender].length-1;
        self.contractApprovals[msg.sender]++;

        emit ApprovalForAll(msg.sender, operator, true); 
    } 

    function revokeApprovalForContract(ApprovableData storage self, address revoked, address owner) public {
        uint256 index = self.approvedForAllIndex[owner][revoked];
        address revokee = self.approvedForAll[owner][index];
        if (revokee != revoked) {
            revert AlreadyRevokedContract(revoked);
        }
        
        // When the token to delete is not the last token, the swap operation is unnecessary
        if (index != self.approvedForAll[owner].length - 1) {
            address tmp = self.approvedForAll[owner][self.approvedForAll[owner].length - 1];
            self.approvedForAll[owner][self.approvedForAll[owner].length - 1] = self.approvedForAll[owner][index];
            self.approvedForAll[owner][index] = tmp;
            self.approvedForAllIndex[owner][tmp] = index;            
        }
        // This also deletes the contents at the last position of the array
        delete self.approvedForAllIndex[owner][revoked];
        self.approvedForAll[owner].pop();

        self.contractApprovals[owner]--;

        emit ApprovalForAll(owner, revoked, false); 
    }    

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

struct AssignableData { 
    mapping(uint256 => address[]) assignments;

    mapping(address => mapping(uint256 => uint256)) assignmentIndex; 

    mapping(address => uint256) assigned;
}    

error AlreadyAssigned(uint256 tokenId);
error NotAssigned(address to);
error NotTokenOwner();

interface Supportable {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function balanceOf(address owner, uint256 tokenId) external view returns (uint256);
}

library SetAssignable {

    function findAssignees(AssignableData storage self, uint256 tokenId) public view returns (address[] memory) {
        return self.assignments[tokenId];
    }

    function revokeAll(AssignableData storage self, uint256 tokenId) public {        
        for (uint256 iterator = 0; iterator < self.assignments[tokenId].length; iterator++) {
            address target = self.assignments[tokenId][iterator];
            delete self.assignmentIndex[target][tokenId];
            delete self.assigned[target];
        }
        while ( self.assignments[tokenId].length > 0) {
            self.assignments[tokenId].pop();
        }        
    }

    function iterateGuardiansBalance(AssignableData storage self, uint256[] memory guardians, address seeking, uint256 tokenId) public view returns (uint256)  {
        uint256 balance = 0;
        for (uint256 iterator = 0; iterator < guardians.length; iterator++) {
            uint256 guardian = guardians[iterator];
            balance += iterateAssignmentsBalance(self,guardian,seeking,tokenId);
        }
        return balance;
    }

    function iterateAssignmentsBalance(AssignableData storage self, uint256 guardian, address seeking, uint256 tokenId) public view returns (uint256)  {
        uint256 balance = 0;
        for (uint256 iterator = 0; iterator < self.assignments[guardian].length; iterator++) {
            address assignment =self.assignments[guardian][iterator];
            Supportable supporting = Supportable(seeking);
            if (supporting.supportsInterface(type(IERC721).interfaceId)) {
                balance += supporting.balanceOf(assignment); 
            }            
            if (supporting.supportsInterface(type(IERC1155).interfaceId)) {
                balance += supporting.balanceOf(assignment, tokenId); 
            }               
        }       
        return balance; 
    } 

    function addAssignment(AssignableData storage self, address to, uint256 tokenId) public {
        uint256 assigned = findAssignment(self, to);
        if (assigned > 0) {
            revert AlreadyAssigned(assigned);
        }
        
        self.assignments[tokenId].push(to);     
        uint256 length = self.assignments[tokenId].length;
        self.assignmentIndex[to][tokenId] = length-1;
        self.assigned[to] = tokenId;
    }    

    function removeAssignment(AssignableData storage self, address to) public {
        uint256 assigned = findAssignment(self, to);
        if (assigned > 0) {
            uint256 existingAddressIndex = self.assignmentIndex[to][assigned];
            uint256 lastAssignmentIndex = self.assignments[assigned].length-1;
            
            if (existingAddressIndex != lastAssignmentIndex) {
                address lastAssignment = self.assignments[assigned][lastAssignmentIndex];
                self.assignments[assigned][existingAddressIndex] = lastAssignment; 
                self.assignmentIndex[lastAssignment][assigned] = existingAddressIndex;
            }
            delete self.assignmentIndex[to][assigned];
            self.assignments[assigned].pop();
        } else {
            revert NotAssigned(to);
        }
    }

    function findAssignment(AssignableData storage self, address to) public view returns (uint256) {
        return self.assigned[to];
    }     
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { InvalidOwner } from "./SetOwnerEnumerable.sol";
struct LockableData { 

    mapping(address => uint256) lockableStatusIndex; 

    mapping(address => LockableStatus) lockableStatus;  
} 




struct LockableStatus {
    bool isLocked;
    uint256 lockedAt;
    address custodian;
    uint256 balance;
    address[] approvedAll;
    bool exists;
}

uint64 constant MAX_INT = 2**64 - 1;

error OnlyCustodianCanLock();

error OnlyOwnerCanSetCustodian();

error WalletLockedByOwner();

error InvalidTransferRecipient();

error NotApprovedOrOwner();

error ContractIsNot721Receiver();

library SetLockable {           

    function lockWallet(LockableData storage self, address holder) public {
        LockableStatus storage status = self.lockableStatus[holder];    
        if (msg.sender != status.custodian) {
            revert OnlyCustodianCanLock();
        }       
        status.isLocked = true;
        status.lockedAt = block.timestamp;
    }

    function unlockWallet(LockableData storage self, address holder) public {        
        LockableStatus storage status = self.lockableStatus[holder];
        if (msg.sender != status.custodian) {
            revert OnlyCustodianCanLock();
        }                   
        
        status.isLocked = false;
        status.lockedAt = MAX_INT;
    }

    function setCustodian(LockableData storage self, address custodianAddress,  address holder) public {
        if (msg.sender != holder) {
            revert OnlyOwnerCanSetCustodian();
        }    
        LockableStatus storage status = self.lockableStatus[holder];
        status.custodian = custodianAddress;
    }

    function findCustodian(LockableData storage self, address wallet) public view returns (address) {
        return self.lockableStatus[wallet].custodian;
    }

    function forceUnlock(LockableData storage self, address owner) public {        
        LockableStatus storage status = self.lockableStatus[owner];
        status.isLocked = false;
        status.lockedAt = MAX_INT;
    }
            
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

bytes constant description = abi.encodePacked(unicode"Ownions: ownable dates for web3 🗓️");

struct RenderableData {
    mapping(uint256 tokenId => ColorMapping) colorMapping;
    mapping(uint256 tokenId => ColorMapping) textColorMapping;
    mapping(uint256 tokenId => TextMapping) textMapping;
    mapping(uint256 tokenId => DateMapping) dateMapping;
}

struct ColorMapping {
    Color color;
    bool exists;
}

struct TextMapping {
    bytes text;
    bool exists;
}

struct DateMapping {
    bytes date;
    bool exists;
}

struct Color {
    uint64 hue;
    uint64 sat;
    uint64 light;
}

library SetMetadataRenderable {
    using Strings for uint256;
    using Strings for uint128;
    using Strings for uint64;    

    // CSS for SVG    
//     bytes constant childStyle1 = ' g > text:nth-child(1) { animation-delay: 0s; }';
//     bytes constant childStyle2 = ' g > text:nth-child(2) { animation-delay: 4s; }';
//     bytes constant keyFrames = '@keyframes opac { 0% { opacity: 0; } 5% { opacity: 0; } 10% { opacity: 1; } 55% { opacity: 1; } 67% { opacity: 0; } 100% { opacity: 0; } }';
    

    

    // SVG tags
    bytes constant STYLE='style';
    bytes constant DEFS='defs';
    bytes constant G='g';
    bytes constant TEXT='text';
    bytes constant RECT = 'rect';
    bytes constant SVG='svg';
//     bytes constant FILTER='filter';
//     bytes constant BLUR = "feGaussianBlur";
//     bytes constant MATRIX = "feColorMatrix";
//     bytes constant COMPOSITE = "feComposite";
    bytes constant TEXT_ATT = ' x="0" y="16" ';
//     bytes constant MATRIX_ATT = abi.encodePacked(' in="blur" mode="matrix" values="1 0 0 0 0  0 1 0 0 0  0 0 1 0 0  0 0 0 20 -5" result="goo" ');
    function gTextStyle(Color memory fill) public pure returns (bytes memory) {
        return abi.encodePacked(
            ' text { text-anchor: middle; font-size: 50px; font-family: Courier New, sans-serif; fill: ',
            colorToHSL(fill),'; }'
        );
    }

    function svgStyle() public pure returns (bytes memory) {
        return abi.encodePacked(' svg { margin: auto; }'); //background-color: ',colorToHSL(backdrop),';
    }

    // END CSS
    
    bytes constant svgAtt = 'xmlns="http://www.w3.org/2000/svg" viewBox="-256 -256 512 512" height="100%" width="100%"';

    function tag(string memory tagName, string memory att, bool open, bool empty) public pure returns (bytes memory) {
        return open ? abi.encodePacked('<',tagName,' ',att, empty ? '/>' : '>') : abi.encodePacked('</',tagName,'>');
    }

    function getDescription(RenderableData storage) public pure returns (bytes memory) {
        return description;
    }
    function buildAttribute(RenderableData storage, bytes memory name, bytes memory value) public pure returns (bytes memory) {
        return abi.encodePacked('{"trait_type": "',string(name),'", "value": "',string(value),'"}');
    }
    function getAttributes(RenderableData storage self, bytes memory date, bytes memory text, Color memory color, Color memory textColor) public pure returns (bytes memory) {
        return abi.encodePacked('[',
        string(buildAttribute(self,"date",date)),',',
        string(buildAttribute(self,"text",text)),',',
        string(buildAttribute(self,"color",colorToHSL(color))),',',
        string(buildAttribute(self,"text color",colorToHSL(textColor))),']');        
    }    
    function colorToHSL(Color memory color) internal pure returns (bytes memory) {
        
        return abi.encodePacked(
                'hsl(',
                color.hue.toString(),
                ',',
                color.sat.toString(),
                '%,',
                color.light.toString(),
                '%)'
            );
    }    

    function getImage(RenderableData storage, bytes memory date, bytes memory text, Color memory background, Color memory textColor) 
    public pure returns (bytes memory)  {        
        string memory backgroundColor = string(colorToHSL(background));
        return abi.encodePacked(
                "data:image/svg+xml;base64,",
                Base64.encode(
                    abi.encodePacked(
                        tag(string(SVG),string(svgAtt),true,false),
                        tag(string(STYLE),"",true,false),
                        string(svgStyle()),
                        string(gTextStyle(textColor)),
                        // string(childStyle1),
                        // string(childStyle2),
                        // string(keyFrames),
                        tag(string(STYLE),"",false,false),
                        // tag(string(FILTER),' id="goo" ',true,false),
                        // tag(string(BLUR),' in="SourceGraphic" stdDeviation="1" result="blur" ',true,false),
                        // tag(string(BLUR),'',false,false),
                        // tag(string(MATRIX),string(MATRIX_ATT),true,false),
                        // tag(string(MATRIX),'',false,false),
                        // tag(string(COMPOSITE),' in="SourceGraphic" in2="goo" operator="atop" ',true,false),
                        // tag(string(COMPOSITE),'',false,false),                
                        // tag(string(FILTER),"",false,false),
                        tag(string(DEFS),"",true,false),
                        tag(string(DEFS),"",false,false),
                        string(buildRect(512,512,256,256, backgroundColor)),
                        // tag(string(G),' filter="url(#goo)" ',true,false),
                        tag(string(TEXT),string(TEXT_ATT),true,false),
                        string(date),
                        tag(string(TEXT),"",false,false),
                        // tag(string(TEXT),string(TEXT_ATT),true,false),
                        // string(text),
                        // tag(string(TEXT),"",false,false),
                        // tag(string(G),'',false,false),
                        tag(string(SVG),"",false,false)
                    )
                )
            );
    }

    function buildRect(uint256 height, uint256 width, uint256 x, uint256 y, string memory fill) internal pure returns (bytes memory) {
        //<rect height="512" width="512" x="0" y="0" fill="url(#comp1)" />
        bytes memory rectAtt = abi.encodePacked(
                    ' height="',
                    height.toString(),
                    '" width="',
                    width.toString(),
                    '" x="-',
                    x.toString(),
                    '" y="-',
                    y.toString(),
                    '" fill="',
                    fill,
                    '" '
                );
        return tag(string(RECT),string(rectAtt),true,true);        
    }    

    function harmonize(RenderableData storage, Color memory color) public pure returns(Color[3] memory) {                
        Color[3] memory colors;
        colors[0] = color;
        uint256 index = 1;
        for(uint64 i = 150; i <= 210; i += 60) {
            uint64 nexthue = (color.hue + i) % 360;
            colors[index] = Color(nexthue,color.sat,100-color.light);
            index++;
        }
        return colors;
    }     

    function setColor(RenderableData storage self, uint256 tokenId, Color memory color) public {
        self.colorMapping[tokenId] = ColorMapping(color,true);
    }
    function setTextColor(RenderableData storage self, uint256 tokenId, Color memory color) public {
        self.textColorMapping[tokenId] = ColorMapping(color,true);
    }    
    function setText(RenderableData storage self, uint256 tokenId, bytes memory text) public {
        self.textMapping[tokenId] = TextMapping(text,true);
    }    
    function setDate(RenderableData storage self, uint256 tokenId, bytes memory date) public {
        self.dateMapping[tokenId] = DateMapping(date,true);
    }    

    function substring(RenderableData storage,bytes memory str, uint startIndex, uint endIndex) public pure returns (bytes memory ) {
        bytes memory result = new bytes(endIndex-startIndex);
        for(uint i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = str[i];
        }
        return result;
    }    

    function encodedContractURI(RenderableData storage self, Color memory color, Color memory textColor, uint128 royalty_basis, address recipient) public pure returns (string memory) { 
        bytes memory dataURI = abi.encodePacked(
            '{',
                '"name": "Ownions"',
                ',"description": "',string(getDescription(self)),'"', 
                ',"image":"',string(getImage(self,"2023-03-30", "Ownions", color, textColor)),'"', // background, textcolor
                ',"external_link":"https://ownion.com"',
                ',"seller_fee_basis_points":', royalty_basis.toString(), 
                ',"fee_recipient":"', Strings.toHexString(uint160(recipient), 20),'"'
            '}'
        );

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(dataURI)
            )
        );
    }    

    struct _DateTime {
            uint16 year;
            uint8 month;
            uint8 day;
            uint8 hour;
            uint8 minute;
            uint8 second;
            uint8 weekday;
    }

    uint constant DAY_IN_SECONDS = 86400;
    uint constant YEAR_IN_SECONDS = 31536000;
    uint constant LEAP_YEAR_IN_SECONDS = 31622400;

    uint constant HOUR_IN_SECONDS = 3600;
    uint constant MINUTE_IN_SECONDS = 60;

    uint16 constant ORIGIN_YEAR = 1970;

    function isLeapYear(uint16 year) public pure returns (bool) {
            if (year % 4 != 0) {
                    return false;
            }
            if (year % 100 != 0) {
                    return true;
            }
            if (year % 400 != 0) {
                    return false;
            }
            return true;
    }

    function leapYearsBefore(uint year) public pure returns (uint) {
            year -= 1;
            return year / 4 - year / 100 + year / 400;
    }

    function getDaysInMonth(uint8 month, uint16 year) public pure returns (uint8) {
            if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
                    return 31;
            }
            else if (month == 4 || month == 6 || month == 9 || month == 11) {
                    return 30;
            }
            else if (isLeapYear(year)) {
                    return 29;
            }
            else {
                    return 28;
            }
    }

    function parseTimestamp(uint timestamp) internal pure returns (_DateTime memory dt) {
            uint secondsAccountedFor = 0;
            uint buf;
            uint8 i;

            // Year
            dt.year = getYear(timestamp);
            buf = leapYearsBefore(dt.year) - leapYearsBefore(ORIGIN_YEAR);

            secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
            secondsAccountedFor += YEAR_IN_SECONDS * (dt.year - ORIGIN_YEAR - buf);

            // Month
            uint secondsInMonth;
            for (i = 1; i <= 12; i++) {
                    secondsInMonth = DAY_IN_SECONDS * getDaysInMonth(i, dt.year);
                    if (secondsInMonth + secondsAccountedFor > timestamp) {
                            dt.month = i;
                            break;
                    }
                    secondsAccountedFor += secondsInMonth;
            }

            // Day
            for (i = 1; i <= getDaysInMonth(dt.month, dt.year); i++) {
                    if (DAY_IN_SECONDS + secondsAccountedFor > timestamp) {
                            dt.day = i;
                            break;
                    }
                    secondsAccountedFor += DAY_IN_SECONDS;
            }

            // Hour
            dt.hour = getHour(timestamp);

            // Minute
            dt.minute = getMinute(timestamp);

            // Second
            dt.second = getSecond(timestamp);

            // Day of week.
            dt.weekday = getWeekday(timestamp);
    }

    function getYear(uint timestamp) public pure returns (uint16) {
            uint secondsAccountedFor = 0;
            uint16 year;
            uint numLeapYears;

            // Year
            year = uint16(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
            numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

            secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
            secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - numLeapYears);

            while (secondsAccountedFor > timestamp) {
                    if (isLeapYear(uint16(year - 1))) {
                            secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
                    }
                    else {
                            secondsAccountedFor -= YEAR_IN_SECONDS;
                    }
                    year -= 1;
            }
            return year;
    }

    function getMonth(uint timestamp) public pure returns (uint8) {
            return parseTimestamp(timestamp).month;
    }

    function getDay(uint timestamp) public pure returns (uint8) {
            return parseTimestamp(timestamp).day;
    }

    function getHour(uint timestamp) public pure returns (uint8) {
            return uint8((timestamp / 60 / 60) % 24);
    }

    function getMinute(uint timestamp) public pure returns (uint8) {
            return uint8((timestamp / 60) % 60);
    }

    function getSecond(uint timestamp) public pure returns (uint8) {
            return uint8(timestamp % 60);
    }

    function getWeekday(uint timestamp) public pure returns (uint8) {
            return uint8((timestamp / DAY_IN_SECONDS + 4) % 7);
    }

    function toTimestamp(RenderableData storage,uint16 year, uint8 month, uint8 day) public pure returns (uint timestamp) {
            return toTimestamp(year, month, day, 0, 0, 0);
    }

    function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour) public pure returns (uint timestamp) {
            return toTimestamp(year, month, day, hour, 0, 0);
    }

    function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute) public pure returns (uint timestamp) {
            return toTimestamp(year, month, day, hour, minute, 0);
    }

    function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute, uint8 second) public pure returns (uint timestamp) {
            uint16 i;

            // Year
            for (i = ORIGIN_YEAR; i < year; i++) {
                    if (isLeapYear(i)) {
                            timestamp += LEAP_YEAR_IN_SECONDS;
                    }
                    else {
                            timestamp += YEAR_IN_SECONDS;
                    }
            }

            // Month
            uint8[12] memory monthDayCounts;
            monthDayCounts[0] = 31;
            if (isLeapYear(year)) {
                    monthDayCounts[1] = 29;
            }
            else {
                    monthDayCounts[1] = 28;
            }
            monthDayCounts[2] = 31;
            monthDayCounts[3] = 30;
            monthDayCounts[4] = 31;
            monthDayCounts[5] = 30;
            monthDayCounts[6] = 31;
            monthDayCounts[7] = 31;
            monthDayCounts[8] = 30;
            monthDayCounts[9] = 31;
            monthDayCounts[10] = 30;
            monthDayCounts[11] = 31;

            for (i = 1; i < month; i++) {
                    timestamp += DAY_IN_SECONDS * monthDayCounts[i - 1];
            }

            // Day
            timestamp += DAY_IN_SECONDS * (day - 1);

            // Hour
            timestamp += HOUR_IN_SECONDS * (hour);

            // Minute
            timestamp += MINUTE_IN_SECONDS * (minute);

            // Second
            timestamp += second;

            return timestamp;
    }       

    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

struct OwnerEnumerableData { 
    mapping(uint256 => TokenOwnership) tokens;

    mapping(address => bool) ownerEnumerated;
    
    mapping(address => uint256[]) ownedTokens;

    mapping(address => mapping(uint256 => uint256)) ownedTokensIndex; 

    mapping(address => uint256[]) burnedTokens;

    mapping(address => mapping(uint256 => uint256)) burnedTokensIndex; 

    mapping(address => mapping(uint64 => uint256)) minted; 

    mapping(uint256 => uint256) mintNumbers; 
} 



struct TokenOwnership {
    address ownedBy;
    bool exists;
}

error TokenNonOwner(address requester, uint256 tokenId); 
error InvalidOwner();

library SetOwnerEnumerable {
    function addMints(OwnerEnumerableData storage self, address to, uint64 phase, uint256 quantity) public {     
        self.minted[to][phase] = self.minted[to][phase] + quantity;
    }
    function numMints(OwnerEnumerableData storage self, address to, uint64 phase) public view returns (uint256) {     
        return self.minted[to][phase];
    }
    
    function addTokenToOwnedArray(
        OwnerEnumerableData storage,
        uint256[] storage owned, 
        mapping(uint256 => uint256) storage ownedIndex, 
        mapping(uint256 => TokenOwnership) storage tokens, 
        mapping(address => bool) storage enumerated,
        address to,
        uint256 token,
        uint256 index) public {
        TokenOwnership memory owner = TokenOwnership(to,true);   
          
        uint256 owned_size = owned.length; 
        uint256 ptr;
        assembly { 

            sstore(owned.slot, add(sload(owned.slot), 1)) 

            ptr := mload(0x40)

            mstore(ptr, token)

            let pos := add(ptr, 0x20)

            mstore(pos, ownedIndex.slot)
            let slot := keccak256(ptr, 0x40)      
            sstore(slot, owned_size)      
        
            mstore(ptr, to)
            mstore(pos, enumerated.slot)
            slot := keccak256(ptr, 0x40)      
            sstore(slot, 1)            
        }
        tokens[token] = owner;
        owned[owned_size] = token;
    }

   
    function mintTokenToEnumeration(OwnerEnumerableData storage self, address to, uint256 tokenId, uint256 existingSupply) public {     
        addTokenToOwnedArray(
            self,
            self.ownedTokens[to], 
            self.ownedTokensIndex[to], 
            self.tokens, 
            self.ownerEnumerated,
            to,
            tokenId,
            existingSupply);
    }  

    function addTokenToEnumeration(OwnerEnumerableData storage self, address to, uint256 tokenId) public {     
        self.ownedTokens[to].push(tokenId);                
        self.ownedTokensIndex[to][tokenId] = self.ownedTokens[to].length-1;
        self.tokens[tokenId] = TokenOwnership(to,true);
        self.ownerEnumerated[to] = true;
    }  
    

    function addBurnToEnumeration(OwnerEnumerableData storage self, address to, uint256 tokenId) public {       
        self.burnedTokens[to].push(tokenId);        
        uint256 length = self.burnedTokens[to].length;
        self.burnedTokensIndex[to][tokenId] = length-1;        
    }    

    function removeTokenFromEnumeration(OwnerEnumerableData storage self, address to, uint256 tokenId) public {

        uint256 length = self.ownedTokens[to].length;
        if (self.ownedTokensIndex[to][tokenId] > 0) {
            if (self.ownedTokensIndex[to][tokenId] != length - 1) {
                uint256 lastTokenId = self.ownedTokens[to][length - 1];
                self.ownedTokens[to][self.ownedTokensIndex[to][tokenId]] = lastTokenId; 
                self.ownedTokensIndex[to][lastTokenId] = self.ownedTokensIndex[to][tokenId];
            }
        }

        delete self.ownedTokensIndex[to][tokenId];
        if (self.ownedTokens[to].length > 0) {
            self.ownedTokens[to].pop();
        }
    }    

    function isOwnerEnumerated(OwnerEnumerableData storage self, address wallet) public view returns (bool) {        
        return self.ownerEnumerated[wallet];
    }  
    
    function findTokensOwned(OwnerEnumerableData storage self, address wallet) public view returns (uint256[] storage) {        
        return self.ownedTokens[wallet];
    }  

    function tokenIndex(OwnerEnumerableData storage self, address wallet, uint256 index) public view returns (uint256) {
        return self.ownedTokens[wallet][index];
    }    

    function ownerOf(OwnerEnumerableData storage self, uint256 tokenId) public view returns (address) {
        address owner = self.tokens[tokenId].ownedBy;
        if (owner == address(0)) {
            revert TokenNonOwner(owner,tokenId);
        }
        return owner;
    }      
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

struct PhaseableData { 
    Phase[] phases;
    uint64 activePhase;
    uint256 maxSupply;
}    

struct Phase {
    uint64 name;
    uint64 maxPerWallet;
    uint64 highestSupply;
    uint256 cost;
}

error MintIsNotAllowedRightNow();
error ExceedsMaxSupply();
error PhaseNotActiveYet();
error PhaseExhausted();
error WalletMintsFilled(uint256 requested);

library SetPhaseable {
    function initialize(PhaseableData storage self, Phase[] storage phases, uint256 maxSupply) public {
        self.phases = phases;
        self.activePhase = 0;
        self.maxSupply = maxSupply;
    }
    function getMaxSupply(PhaseableData storage self) public view returns (uint256) {
        return self.maxSupply;
    }
    function setMaxSupply(PhaseableData storage self, uint256 newMax) public {
        self.maxSupply = newMax;
    }
    function getPhases(PhaseableData storage self) public view returns (Phase[] storage) {
        return self.phases;
    }
    function getActivePhase(PhaseableData storage self) public view returns (uint64) {
        return self.activePhase;
    }
    function findPhase(PhaseableData storage self, uint256 phaseId) public view returns (Phase memory) {
        return self.phases[phaseId];
    }
    function startNextPhase(PhaseableData storage self) public {
        self.activePhase += 1;
    }
    function revertPhase(PhaseableData storage self) public {
        self.activePhase -= 1;
    }
    function addPhase(PhaseableData storage self,Phase calldata nextPhase) public {
        self.phases.push(nextPhase);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "./LockableTransferrable.sol";
import { TokenOwnership } from "./SetOwnerEnumerable.sol";
error InvalidRecipient(address zero);
error TokenAlreadyMinted(uint256 tokenId);
error InvalidToken(uint256 tokenId);
error MintIsNotLive();

abstract contract UnpackedMintable is LockableTransferrable {  

    bool isLive;
    uint256 tokenCount;

    function setMintLive(bool _isLive) public onlyOwner {
        isLive = _isLive;
    } 

    function balanceOf(address holder) public view returns (uint256) {             
        if (isOwnerEnumerated(holder)) {
            return enumeratedBalanceOf(holder);
        } 
        return 0;
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        if (!isLive) {
            revert MintIsNotLive();
        }
        if (to == address(0)) {
            revert InvalidRecipient(to);
        }
        if (exists(tokenId)) {
            revert TokenAlreadyMinted(tokenId);
        }

        tokenCount +=1;

        enumerateMint(to, tokenId, tokenCount);

        
        completeTransfer(address(0),to,tokenId);
    } 

    function _batchMint(address to, uint256[] memory tokenIds) internal virtual {
        if (!isLive) {
            revert MintIsNotLive();
        }
        if (to == address(0)) {
            revert InvalidRecipient(to);
        }


        for (uint256 i = 0; i < tokenIds.length; i++) {

            tokenCount++;
            if (exists(tokenIds[i])) {
                revert TokenAlreadyMinted(tokenIds[i]);
            }          
            
            enumerateMint(to, tokenIds[i], tokenCount);                

            completeTransfer(address(0),to,tokenIds[i]);
        }

        tokenCount +=tokenIds.length;

        // enumerateTokens(to, tokenIds);        

    }             

    function totalSupply() public view returns (uint256) {
        return tokenCount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import { SetOwnerEnumerable, OwnerEnumerableData, TokenNonOwner, InvalidOwner, TokenOwnership } from "./SetOwnerEnumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./Ownable.sol";
import "./Nameable.sol";


abstract contract UnpackedOwnerEnumerable is Ownable, Context, ERC165, IERC721, Nameable {  
    using SetOwnerEnumerable for OwnerEnumerableData;
    OwnerEnumerableData enumerable;      

    function addMints(address to, uint64 phase, uint256 quantity) internal {
        enumerable.addMints(to,phase,quantity);
    }    
    function numMints(address to, uint64 phase) public view returns (uint256) {
        return enumerable.numMints(to,phase);
    }    
    function ownerOf(uint256 tokenId) public view returns (address) {
        return enumerable.ownerOf(tokenId);
    }    

    function isOwnerEnumerated(address holder) public view returns (bool) {
        return enumerable.isOwnerEnumerated(holder);
    }        

    function tokensOwnedBy(address holder) public view returns (uint256[] memory) {
        uint256[] memory empty;        
        if (enumerable.isOwnerEnumerated(holder)) {
            return enumerable.findTokensOwned(holder);
        } 
        return empty;
    }

    function enumeratedBalanceOf(address owner) public view virtual returns (uint256) {
        validateNonZeroAddress(owner);
        return enumerable.ownedTokens[owner].length;
    }   

    function validateNonZeroAddress(address owner) internal pure {
        if(owner == address(0)) {
            revert InvalidOwner();
        }
    }
    
    function enumerateToken(address to, uint256 tokenId) internal {
        enumerable.addTokenToEnumeration(to, tokenId);
    }
    function enumerateMint(address to, uint256 tokenId, uint256 index) internal {
        enumerable.mintTokenToEnumeration(to, tokenId, index);
    }


    function enumerateBurn(address from, uint256 tokenId) internal {
        enumerable.addBurnToEnumeration(from, tokenId);
        enumerable.removeTokenFromEnumeration(from, tokenId);
    }

    function swapOwner(address from, address to, uint256 tokenId) internal {
        enumerable.removeTokenFromEnumeration(from, tokenId);
        enumerable.addTokenToEnumeration(to, tokenId);
    }
    
    function enumerationExists(uint256 tokenId) internal view virtual returns (bool) {
        return enumerable.tokens[tokenId].exists;
    }    

    function selfDestruct(uint256 tokenId) internal {
        delete enumerable.tokens[tokenId];
    }    

    function exists(uint256 tokenId) internal view virtual returns (bool) {
        
        if (enumerationExists(tokenId)) {
            return enumerable.tokens[tokenId].exists;
        }
        return false;
    }       
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {OperatorFilterer} from "./OperatorFilterer.sol";
import {CANONICAL_CORI_SUBSCRIPTION} from "./lib/Constants.sol";
/**
 * @title  DefaultOperatorFilterer
 * @notice Inherits from OperatorFilterer and automatically subscribes to the default OpenSea subscription.
 * @dev    Please note that if your token contract does not provide an owner with EIP-173, it must provide
 *         administration methods on the contract itself to interact with the registry otherwise the subscription
 *         will be locked to the options set during construction.
 */

abstract contract DefaultOperatorFilterer is OperatorFilterer {
    /// @dev The constructor that is called when the contract is being deployed.
    constructor() OperatorFilterer(CANONICAL_CORI_SUBSCRIPTION, true) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IOperatorFilterRegistry {
    /**
     * @notice Returns true if operator is not filtered for a given token, either by address or codeHash. Also returns
     *         true if supplied registrant address is not registered.
     */
    function isOperatorAllowed(address registrant, address operator) external view returns (bool);

    /**
     * @notice Registers an address with the registry. May be called by address itself or by EIP-173 owner.
     */
    function register(address registrant) external;

    /**
     * @notice Registers an address with the registry and "subscribes" to another address's filtered operators and codeHashes.
     */
    function registerAndSubscribe(address registrant, address subscription) external;

    /**
     * @notice Registers an address with the registry and copies the filtered operators and codeHashes from another
     *         address without subscribing.
     */
    function registerAndCopyEntries(address registrant, address registrantToCopy) external;

    /**
     * @notice Unregisters an address with the registry and removes its subscription. May be called by address itself or by EIP-173 owner.
     *         Note that this does not remove any filtered addresses or codeHashes.
     *         Also note that any subscriptions to this registrant will still be active and follow the existing filtered addresses and codehashes.
     */
    function unregister(address addr) external;

    /**
     * @notice Update an operator address for a registered address - when filtered is true, the operator is filtered.
     */
    function updateOperator(address registrant, address operator, bool filtered) external;

    /**
     * @notice Update multiple operators for a registered address - when filtered is true, the operators will be filtered. Reverts on duplicates.
     */
    function updateOperators(address registrant, address[] calldata operators, bool filtered) external;

    /**
     * @notice Update a codeHash for a registered address - when filtered is true, the codeHash is filtered.
     */
    function updateCodeHash(address registrant, bytes32 codehash, bool filtered) external;

    /**
     * @notice Update multiple codeHashes for a registered address - when filtered is true, the codeHashes will be filtered. Reverts on duplicates.
     */
    function updateCodeHashes(address registrant, bytes32[] calldata codeHashes, bool filtered) external;

    /**
     * @notice Subscribe an address to another registrant's filtered operators and codeHashes. Will remove previous
     *         subscription if present.
     *         Note that accounts with subscriptions may go on to subscribe to other accounts - in this case,
     *         subscriptions will not be forwarded. Instead the former subscription's existing entries will still be
     *         used.
     */
    function subscribe(address registrant, address registrantToSubscribe) external;

    /**
     * @notice Unsubscribe an address from its current subscribed registrant, and optionally copy its filtered operators and codeHashes.
     */
    function unsubscribe(address registrant, bool copyExistingEntries) external;

    /**
     * @notice Get the subscription address of a given registrant, if any.
     */
    function subscriptionOf(address addr) external returns (address registrant);

    /**
     * @notice Get the set of addresses subscribed to a given registrant.
     *         Note that order is not guaranteed as updates are made.
     */
    function subscribers(address registrant) external returns (address[] memory);

    /**
     * @notice Get the subscriber at a given index in the set of addresses subscribed to a given registrant.
     *         Note that order is not guaranteed as updates are made.
     */
    function subscriberAt(address registrant, uint256 index) external returns (address);

    /**
     * @notice Copy filtered operators and codeHashes from a different registrantToCopy to addr.
     */
    function copyEntriesOf(address registrant, address registrantToCopy) external;

    /**
     * @notice Returns true if operator is filtered by a given address or its subscription.
     */
    function isOperatorFiltered(address registrant, address operator) external returns (bool);

    /**
     * @notice Returns true if the hash of an address's code is filtered by a given address or its subscription.
     */
    function isCodeHashOfFiltered(address registrant, address operatorWithCode) external returns (bool);

    /**
     * @notice Returns true if a codeHash is filtered by a given address or its subscription.
     */
    function isCodeHashFiltered(address registrant, bytes32 codeHash) external returns (bool);

    /**
     * @notice Returns a list of filtered operators for a given address or its subscription.
     */
    function filteredOperators(address addr) external returns (address[] memory);

    /**
     * @notice Returns the set of filtered codeHashes for a given address or its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredCodeHashes(address addr) external returns (bytes32[] memory);

    /**
     * @notice Returns the filtered operator at the given index of the set of filtered operators for a given address or
     *         its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredOperatorAt(address registrant, uint256 index) external returns (address);

    /**
     * @notice Returns the filtered codeHash at the given index of the list of filtered codeHashes for a given address or
     *         its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredCodeHashAt(address registrant, uint256 index) external returns (bytes32);

    /**
     * @notice Returns true if an address has registered
     */
    function isRegistered(address addr) external returns (bool);

    /**
     * @dev Convenience method to compute the code hash of an arbitrary contract
     */
    function codeHashOf(address addr) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

address constant CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS = 0x000000000000AAeB6D7670E522A718067333cd4E;
address constant CANONICAL_CORI_SUBSCRIPTION = 0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IOperatorFilterRegistry} from "./IOperatorFilterRegistry.sol";
import {CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS} from "./lib/Constants.sol";
/**
 * @title  OperatorFilterer
 * @notice Abstract contract whose constructor automatically registers and optionally subscribes to or copies another
 *         registrant's entries in the OperatorFilterRegistry.
 * @dev    This smart contract is meant to be inherited by token contracts so they can use the following:
 *         - `onlyAllowedOperator` modifier for `transferFrom` and `safeTransferFrom` methods.
 *         - `onlyAllowedOperatorApproval` modifier for `approve` and `setApprovalForAll` methods.
 *         Please note that if your token contract does not provide an owner with EIP-173, it must provide
 *         administration methods on the contract itself to interact with the registry otherwise the subscription
 *         will be locked to the options set during construction.
 */

abstract contract OperatorFilterer {
    /// @dev Emitted when an operator is not allowed.
    error OperatorNotAllowed(address operator);

    IOperatorFilterRegistry public constant OPERATOR_FILTER_REGISTRY =
        IOperatorFilterRegistry(CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS);

    /// @dev The constructor that is called when the contract is being deployed.
    constructor(address subscriptionOrRegistrantToCopy, bool subscribe) {
        // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
        // will not revert, but the contract will need to be registered with the registry once it is deployed in
        // order for the modifier to filter addresses.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            if (subscribe) {
                OPERATOR_FILTER_REGISTRY.registerAndSubscribe(address(this), subscriptionOrRegistrantToCopy);
            } else {
                if (subscriptionOrRegistrantToCopy != address(0)) {
                    OPERATOR_FILTER_REGISTRY.registerAndCopyEntries(address(this), subscriptionOrRegistrantToCopy);
                } else {
                    OPERATOR_FILTER_REGISTRY.register(address(this));
                }
            }
        }
    }

    /**
     * @dev A helper function to check if an operator is allowed.
     */
    modifier onlyAllowedOperator(address from) virtual {
        // Allow spending tokens from addresses with balance
        // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
        // from an EOA.
        if (from != msg.sender) {
            _checkFilterOperator(msg.sender);
        }
        _;
    }

    /**
     * @dev A helper function to check if an operator approval is allowed.
     */
    modifier onlyAllowedOperatorApproval(address operator) virtual {
        _checkFilterOperator(operator);
        _;
    }

    /**
     * @dev A helper function to check if an operator is allowed.
     */
    function _checkFilterOperator(address operator) internal view virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            // under normal circumstances, this function will revert rather than return false, but inheriting contracts
            // may specify their own OperatorFilterRegistry implementations, which may behave differently
            if (!OPERATOR_FILTER_REGISTRY.isOperatorAllowed(address(this), operator)) {
                revert OperatorNotAllowed(operator);
            }
        }
    }
}