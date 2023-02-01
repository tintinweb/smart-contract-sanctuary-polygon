// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "./Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "./StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
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
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
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
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
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
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
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
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
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
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
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

import "./IERC165Upgradeable.sol";
import "./Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "./IERC1155Upgradeable.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "./AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./ContextUpgradeable.sol";
import "./Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "./ContextUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @title IRoyalExtrasToken
 * @author Royal
 *
 * @notice Specifies the callback functions that a token contract must implement in order to
 *  integrate with the redeemable token extras interface specified by IRoyalExtras.
 */
interface IRoyalExtrasToken {

    /**
     * @notice Callback function to be called when a new extra is registered to a set of tokens.
     */
    function onExtraRegistered(
        uint256 extraId,
        address registerer,
        uint256 startCanonicalTokenId,
        uint256 endCanonicalTokenId
    )
        external;

    /**
     * @notice Callback function to be called when an extra is redeemed.
     */
    function onExtraRedeemed(
        uint256 extraId,
        uint256 tokenId,
        address redeemer
    )
        external;

    /**
     * @notice Returns the “canonical” form of a token ID, which does not change even as extras
     *  are redeemed for a token.
     */
    function getCanonicalTokenId(
        uint256 tokenId
    )
        external
        view
        returns (uint256);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @dev Interface for a contract with a callback hook to be called upon LDA transfers.
 */
interface ILdaTransferHook {

    function beforeLdaTransfer(
        address from,
        address to,
        uint128 tierId
    )
        external;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IRoyal1155LDA {

    function tierBalanceOf(
        uint128 tierId,
        address owner
    )
        external
        view
        returns (uint256);

    function getOwnedTokens(
        uint128 tierId,
        address owner
    )
        external
        view
        returns (uint256[] memory);

    function getTierTotalSupply(
        uint128 tierId
    )
        external
        view
        returns (uint256);

    function tierExists(
        uint128 tierId
    )
        external
        view
        returns (bool);

    function mintable(
        uint128 tierId
    )
        external
        view
        returns (bool);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import { OwnableUpgradeable } from "../dependencies/openzeppelin/v4_7_0/OwnableUpgradeable.sol";
import { PausableUpgradeable } from "../dependencies/openzeppelin/v4_7_0/PausableUpgradeable.sol";

import { IRoyal1155LDA } from "./IRoyal1155LDA.sol";
import { IRoyalExtrasToken } from "../extras/IRoyalExtrasToken.sol";
import { ILdaTransferHook } from "../interfaces/ILdaTransferHook.sol";
import { ERC1155PermitUpgradeable } from "../lib/ERC1155PermitUpgradeable.sol";
import { RoyalUtil } from "../shared/RoyalUtil.sol";

/**
 * @title Royal1155LDA
 * @author Royal
 *
 * @notice Implementation of Royal.io LDAs (Limited Digital Assets) as ERC-1155 tokens.
 *
 *  See https://eips.ethereum.org/EIPS/eip-1155
 *
 *  LDA token IDs (“LDA IDs”) are made up of three parts:
 *
 *    1. Tier ID: Denotes the collection that this token belongs to.
 *       For example -- editions typically correspond to a single musical work
 *       (song or album) by an artist, and each edition is typically split into
 *       multiple tiers such as GOLD, PLATINUM, and DIAMOND. Each of these
 *       tiers has a tier ID that is global across Royal LDAs on all chains.
 *
 *    2. Version: Represents the version, which may change with certain significant events such as
 *       the redemption of token extras. Including the version in the LDA ID ensures that
 *       marketplace bids and asks are invalidated when the token version changes.
 *
 *    3. Token ID: Represents the token number within the specific tier. We generally start
 *       at token #1 and count up to the tier max supply, but that is not strictly necessary.
 *
 *  These parts are laid out in the uint256 LDA token ID (the “LDA ID”) as follows:
 *
 *   MSB                                                 LSB
 *    [ tier_id             | version | token_id          ]
 *    [ **** **** **** **** | **      | ** **** **** **** ]
 *    [ 128 bits            | 16 bits | 112 bits          ]
 */
contract Royal1155LDA is
    ERC1155PermitUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    IRoyal1155LDA,
    IRoyalExtrasToken
{
    // -------------------- Events -------------------- //

    // Note: Recommend deprecating/removing this event.
    event NewTier(
        uint128 indexed tierID
    );

    // Note: Intentionally tierId instead of tierID.
    event TierConfigured(
        uint128 indexed tierId,
        uint256 maxSupply
    );

    // Note: Recommend deprecating/removing this event.
    event TierExhausted(
        uint128 indexed tierID
    );

    event SetExtrasContract(
        address extrasContract
    );

    event SetRoyaltiesContract(
        address royaltiesContract
    );

    // -------------------- Storage -------------------- //

    /// @custom:oz-renamed-from _contractMetadataURI
    string internal _CONTRACT_METADATA_URI_;

    /// @dev Mapping (tierId) => max supply for this tier
    /// @custom:oz-renamed-from tierMaxSupply
    mapping(uint128 => uint256) internal _MAX_SUPPLY_;

    /// @dev Mapping (tierId) => current supply for this tier.
    ///   NOTE: See also the comment below _TIER_ENUMERATION_.
    /// @custom:oz-renamed-from _tierCurrentSupply
    mapping(uint128 => uint256) internal _CURRENT_SUPPLY_;

    // MAPPINGS FOR MAINTAINING ISSUANCE_ID => LIST OF ADDRESSES HOLDING TOKENS (with repeats)
    // NOTE: These structures allow to enumerate the ldaId[] corresponding to a tierId. The
    //       addresses must then be looked up from _OWNERS_.

    /// @dev Mapping (ldaId) => owner address
    /// @custom:oz-renamed-from _owners
    mapping(uint256 => address) internal _OWNERS_;

    /// @dev Mapping (tierId) => (index) => (ldaId)
    ///  Tracks the LDA IDs that belong to a given tier.
    /// @custom:oz-renamed-from _ldasForTier
    mapping(uint128 => mapping(uint256 => uint256)) internal _TIER_ENUMERATION_;

    /// @dev (ldaId) => (index)
    ///  Tracks the index of the LDA ID in the _TIER_ENUMERATION_ list.
    /// @custom:oz-renamed-from _ldaIndexesForTier
    mapping(uint256 => uint256) internal _TIER_ENUMERATION_INDEX_;

    /// @dev Mapping (tierId) => (owner address) => (owned count)
    ///  Tracks the number of LDAs owned by a user within a particular tier.
    mapping(uint256 => mapping(address => uint256)) internal _BALANCES_;

    /// @dev Mapping (tierId) => (owner address) => (owned index) => (ldaId)
    ///  Tracks the LDA IDs owned by a user within a particular tier.
    mapping(uint256 => mapping(address => mapping(uint256 => uint256))) internal _OWNED_TOKENS_;

    /// @dev Mapping (ldaId) => (owned index)
    ///  Tracks the index of the LDA ID in the _OWNED_TOKENS_ list.
    mapping(uint256 => uint256) internal _OWNED_TOKENS_INDEX_;

    /// @dev Indicates whether the backfill of `_OWNED_TOKENS_` was completed.
    bool internal _IS_OWNED_TOKENS_BACKFILL_COMPLETE_;

    /// @dev Address of the extras contract.
    address internal _EXTRAS_CONTRACT_;

    /// @dev Address of the royalties contract.
    address internal _ROYALTIES_CONTRACT_;

    /// @dev Storage slot that was used only on the testnet deployment.
    /// @custom:oz-renamed-from _GLOBAL_OPERATOR_
    mapping(address => bool) internal _GLOBAL_OPERATOR__DEPRECATED_;

    // ------------------ Constructor ------------------ //

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // -------------------- Initializers -------------------- //

    function initialize(
        string memory tokenMetadataUri,
        string memory contractMetadataUri
    )
        external
        initializer
    {
        __Context_init_unchained();
        __Pausable_init_unchained();
        __Ownable_init_unchained();
        __ERC1155_init_unchained(tokenMetadataUri);
        _CONTRACT_METADATA_URI_ = contractMetadataUri;
    }

    function initializeV0_5_3()
        external
        reinitializer(2)
    {
        __EIP712_init_unchained("Royal LDAs", "1");
    }

    // -------------------- Owner-Only Functions -------------------- //

    function pause()
        external
        onlyOwner
        whenNotPaused
    {
        _pause();
    }

    function unpause()
        external
        onlyOwner
        whenPaused
    {
        _unpause();
    }

    /**
     * @notice Setter for {_EXTRAS_CONTRACT_} that defines the address for the extras contract.
     */
    function setExtrasContract(
        address newExtrasContract
    )
        external
        onlyOwner
    {
        _EXTRAS_CONTRACT_ = newExtrasContract;
        emit SetExtrasContract(newExtrasContract);
    }

    /**
     * @notice Setter for {_ROYALTIES_CONTRACT_} that defines the address for the extras contract.
     */
    function setRoyaltiesContract(
        address newRoyaltiesContract
    )
        external
        onlyOwner
    {
        _ROYALTIES_CONTRACT_ = newRoyaltiesContract;
        emit SetRoyaltiesContract(newRoyaltiesContract);
    }

    function updateContractMetadataURI(
        string memory contractUri
    )
        external
        onlyOwner
        whenNotPaused
    {
        _CONTRACT_METADATA_URI_ = contractUri;
    }

    function updateTokenURI(
        string calldata tokenUri
    )
        external
        onlyOwner
    {
        _setURI(tokenUri);
    }

    function completeOwnedTokensBackfill()
        external
        onlyOwner
    {
        _IS_OWNED_TOKENS_BACKFILL_COMPLETE_ = true;
    }

    /**
     * @notice Called by the owner to backfill the mapping of owned token counts by user.
     */
    function setOwnedTokens(
        uint128 tierId,
        address[] calldata owners,
        uint256[][] calldata ownedTokens
    )
        external
        onlyOwner
    {
        require(
            !_IS_OWNED_TOKENS_BACKFILL_COMPLETE_,
            "Backfill is complete"
        );
        require(
            owners.length == ownedTokens.length,
            "Params length mismatch"
        );
        for (uint256 i = 0; i < owners.length; i++) {
            address owner = owners[i];
            uint256[] memory ownerOwnedTokens = ownedTokens[i];

            _BALANCES_[tierId][owner] = ownerOwnedTokens.length;

            for (uint256 j = 0; j < ownerOwnedTokens.length; j++) {
                uint256 ldaId = ownerOwnedTokens[j];
                _OWNED_TOKENS_[tierId][owner][j] = ldaId;
                _OWNED_TOKENS_INDEX_[ldaId] = j;
            }
        }
    }

    /**
     * @notice Create a tier of an LDA. In order for an LDA to be minted, it must
     *  belong to a valid tier that has not yet reached its max supply.
     */
    function createTier(
        uint128 tierId,
        uint256 maxSupply
    )
        external
        onlyOwner
        whenNotPaused
    {
        require(
            !this.tierExists(tierId),
            "Tier already exists"
        );
        require(
            tierId != 0 && maxSupply != 0,
            "Invalid tier definition"
        );

        _MAX_SUPPLY_[tierId] = maxSupply;

        // Legacy event.
        emit NewTier(tierId);

        emit TierConfigured(tierId, maxSupply);
    }

    /**
     * @notice Update the max supply of a tier.
     *
     *  The max supply cannot decrease below the current supply.
     */
    function updateTier(
        uint128 tierId,
        uint256 maxSupply
    )
        external
        onlyOwner
        whenNotPaused
    {
        require(
            this.tierExists(tierId),
            "Tier does not exist"
        );
        require(
            maxSupply != 0 && maxSupply >= _CURRENT_SUPPLY_[tierId],
            "Invalid max supply"
        );

        _MAX_SUPPLY_[tierId] = maxSupply;

        emit TierConfigured(tierId, maxSupply);

        if (maxSupply == _CURRENT_SUPPLY_[tierId]) {
            emit TierExhausted(tierId);
        }
    }

    function mintLDAToOwner(
        address recipient,
        uint256 ldaId,
        bytes calldata data
    )
        external
        onlyOwner
        whenNotPaused
    {
        require(
            _OWNERS_[ldaId] == address(0),
            "LDA already minted"
        );
        (uint128 tierId,,) = RoyalUtil.decomposeLDA_ID(ldaId);
        require(
            this.mintable(tierId),
            "Tier not mintable"
        );

        // Update current supply before minting to prevent reentrancy attacks
        _CURRENT_SUPPLY_[tierId] += 1;
        _mint(recipient, ldaId, 1, data);

        // Emit an event when the max supply is reached.
        if (_CURRENT_SUPPLY_[tierId] == _MAX_SUPPLY_[tierId]) {
            emit TierExhausted(tierId);
        }
    }

    /**
     * @notice Bulk mint a list of LDAs from a given tier.
     */
    function bulkMintTierLDAsToOwner(
        address recipient,
        uint256[] calldata ldaIds,
        bytes calldata data
    )
        external
        onlyOwner
        whenNotPaused
    {
        require(
            ldaIds.length >= 1,
            "empty ldaIDs list"
        );

        // Check this tier is mintable
        (uint128 tierId,,) = RoyalUtil.decomposeLDA_ID(ldaIds[0]);
        require(
            this.tierExists(tierId),
            "Tier not mintable"
        );
        require(
            (_CURRENT_SUPPLY_[tierId] + ldaIds.length) <= _MAX_SUPPLY_[tierId],
            "Too many tokens to mint"
        );

        // Check all LDAs are unminted
        for (uint256 i = 0; i < ldaIds.length; i++) {
            require(
                _OWNERS_[ldaIds[i]] == address(0),
                "LDA already minted"
            );
            (uint128 curTierId,,) = RoyalUtil.decomposeLDA_ID(ldaIds[i]);
            require(
                curTierId == tierId,
                "not all tiers are the same"
            );
        }

        // We always just want 1 of each token
        uint256[] memory amounts = new uint256[](ldaIds.length);
        for (uint256 i = 0; i < ldaIds.length; i++) {
            amounts[i] = 1;
        }

        // Update current supply before minting to prevent reentrancy attacks
        _CURRENT_SUPPLY_[tierId] += ldaIds.length;
        // Issue mint
        _mintBatch(recipient, ldaIds, amounts, data);

        // Emit an event when the max supply is reached.
        if (_CURRENT_SUPPLY_[tierId] == _MAX_SUPPLY_[tierId]) {
            emit TierExhausted(tierId);
        }
    }

    // -------------------- Other Access-Controlled Functions -------------------- //

    function onExtraRedeemed(
        uint256 /* extraId */,
        uint256 ldaId,
        address redeemer
    )
        external
        override
    {
        address tokenOwner = _OWNERS_[ldaId];

        require(
            _msgSender() == _EXTRAS_CONTRACT_,
            "redemptions only from extras contract"
        );
        require(
            tokenOwner != address(0),
            "token DNE"
        );
        require(
            (tokenOwner == redeemer) || isApprovedForAll(tokenOwner, redeemer),
            "redemption by approved addresses only"
        );

        // Bump version number in the token ID (a.k.a. LDA ID).
        (uint128 tierId, uint256 version, uint128 tokenId) = RoyalUtil.decomposeLDA_ID(
            ldaId
        );
        uint256 newLdaId = RoyalUtil.composeLDA_ID(tierId, ++version, tokenId);

        // Burn and remint with new incremented version number.
        bytes memory emptyData;
        _burn(tokenOwner, ldaId, 1);
        _mint(tokenOwner, newLdaId, 1, emptyData);
    }

    // -------------------- Other External Functions -------------------- //

    function getExtrasContract()
        external
        view
        returns (address)
    {
        return _EXTRAS_CONTRACT_;
    }

    function getRoyaltiesContract()
        external
        view
        returns (address)
    {
        return _ROYALTIES_CONTRACT_;
    }

    function contractURI()
        external
        view
        returns (string memory)
    {
        return _CONTRACT_METADATA_URI_;
    }

    function getIsOwnedTokensBackfillComplete()
        external
        view
        returns (bool)
    {
        return _IS_OWNED_TOKENS_BACKFILL_COMPLETE_;
    }

    function getTierTotalSupply(
        uint128 tierId
    )
        external
        view
        override
        returns (uint256)
    {
        return _MAX_SUPPLY_[tierId];
    }

    /// @dev Legacy alias for getTierTotalSupply().
    function tierMaxSupply(
        uint128 tierId
    )
        external
        view
        returns (uint256)
    {
        return _MAX_SUPPLY_[tierId];
    }

    /**
     * @notice Has this tier been initialized?
     */
    function tierExists(
        uint128 tierId
    )
        external
        view
        override
        returns (bool)
    {
        return _MAX_SUPPLY_[tierId] != 0;
    }

    /**
     * @notice Check if the tier is currently mintable.
     */
    function mintable(
        uint128 tierId
    )
        external
        view
        override
        returns (bool)
    {
        return _CURRENT_SUPPLY_[tierId] < _MAX_SUPPLY_[tierId];
    }

    /**
     * @notice Has the given LDA been minted?
     */
    function exists(
        uint256 ldaId
    )
        external
        view
        returns (bool)
    {
        return _OWNERS_[ldaId] != address(0);
    }

    /**
     * @notice What address owns the given ldaID?
     */
    function ownerOf(
        uint256 ldaId
    )
        external
        view
        returns (address)
    {
        require(
            _OWNERS_[ldaId] != address(0),
            "LDA DNE"
        );
        return _OWNERS_[ldaId];
    }

    /**
     * @notice Get the number of LDAs owned by a user within a particular tier.
     *
     *  IMPORTANT: Assumes that the max supply of each LDA ID in the tier is 1.
     */
    function tierBalanceOf(
        uint128 tierId,
        address owner
    )
        external
        view
        override
        returns (uint256)
    {
        return _BALANCES_[tierId][owner];
    }

    function tokenOfOwnerByIndex(
        uint128 tierId,
        address owner,
        uint256 index
    )
        external
        view
        returns (uint256)
    {
        require(
            index < _BALANCES_[tierId][owner],
            "Owner index out of bounds"
        );
        return _OWNED_TOKENS_[tierId][owner][index];
    }

    function getOwnedTokens(
        uint128 tierId,
        address owner
    )
        external
        view
        override
        returns (uint256[] memory)
    {
        uint256 balance = _BALANCES_[tierId][owner];
        uint256[] memory ownedTokens = new uint256[](balance);
        for (uint256 i = 0; i < balance; i++) {
            ownedTokens[i] = _OWNED_TOKENS_[tierId][owner][i];
        }
        return ownedTokens;
    }

    /**
     * @notice Compose a raw ldaID from its two composite parts.
     */
    function composeLDA_ID(
        uint128 tierId,
        uint256 version,
        uint128 tokenId
    )
        external
        pure
        returns (
            uint256 ldaID
        )
    {
        return RoyalUtil.composeLDA_ID(tierId, version, tokenId);
    }

    /**
     * @notice Decompose a raw ldaID into its two composite parts.
     */
    function decomposeLDA_ID(
        uint256 ldaId
    )
        external
        pure
        returns (
            uint128 tierID,
            uint256 version,
            uint128 tokenID
        )
    {
        return RoyalUtil.decomposeLDA_ID(ldaId);
    }

    /**
     * @notice Zeros out the token version and returns a Royal LDA ID V1.
     */
    function getCanonicalTokenId(
        uint256 tokenId
    )
        external
        pure
        override
        returns(
            uint256
        )
    {
        return RoyalUtil.getCanonicalTokenId(tokenId);
    }

    function onExtraRegistered(
        uint256 /* extraId */,
        address /* registerer */,
        uint256 /* startCanonicalTokenId */,
        uint256 /* endCanonicalTokenId */
    )
        external
        pure
        override
    {}

    // -------------------- Internal Functions -------------------- //

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal
        virtual
        override
    {
        // Iterate over all LDAs being transferred
        for (uint256 i; i < ids.length; i++) {
            uint256 ldaId = ids[i];

            // Get the tier ID.
            (uint128 tierId, ,) = RoyalUtil.decomposeLDA_ID(ldaId);

            // Call the callback on the Royalties contract.
            //
            // IMPORTANT: This must happen before any bookkeeping like `_OWNED_TOKENS_` is updated.
            if (_ROYALTIES_CONTRACT_ != address(0)) {
                ILdaTransferHook(_ROYALTIES_CONTRACT_).beforeLdaTransfer(from, to, tierId);
            }

            // Self-transfer: skip everything that follows.
            if (from == to) {
                continue;
            }

            // Token leaves a wallet: update balance and remove token from owner enumeration.
            if (from != address(0)) {
                uint256 balance = _BALANCES_[tierId][from];

                // Special case: If backfill is ongoing AND balance is zero, do not update.
                if (_IS_OWNED_TOKENS_BACKFILL_COMPLETE_ || balance != 0) {
                    require(
                        balance != 0,
                        "ERC1155: insufficient balance for transfer"
                    );

                    // Remove from owned tokens list using swap-and-pop method.
                    uint256 lastTokenIndex = balance - 1;
                    uint256 removeTokenIndex = _OWNED_TOKENS_INDEX_[ldaId];

                    if (lastTokenIndex != removeTokenIndex) {
                        uint256 lastTokenId = _OWNED_TOKENS_[tierId][from][lastTokenIndex];
                        _OWNED_TOKENS_[tierId][from][removeTokenIndex] = lastTokenId;
                        _OWNED_TOKENS_INDEX_[lastTokenId] = removeTokenIndex;
                    }

                    delete _OWNED_TOKENS_[tierId][from][lastTokenIndex];
                    delete _OWNED_TOKENS_INDEX_[ldaId]; // NOTE: This deletion is optional.

                    _BALANCES_[tierId][from] = lastTokenIndex;
                }
            }

            // Token enters a wallet: update balance and add token to owner enumeration.
            if (to != address(0)) {
                uint256 oldBalance = _BALANCES_[tierId][to];
                _OWNED_TOKENS_[tierId][to][oldBalance] = ldaId;
                _OWNED_TOKENS_INDEX_[ldaId] = oldBalance;

                _BALANCES_[tierId][to] = oldBalance + 1;
            }

            if (from == address(0)) {
                // This is a mint operation
                // Add this LDA to the `to` address state
                _addTokenToTierTracking(to, ldaId, tierId);

            } else {
                // If this is a transfer to a different address.
                _OWNERS_[ldaId] = to;
            }

            if (to == address(0)) {
                // NOTE: no burn() is currently implemented
                // Remove LDA from being associated with its
                _removeLDAFromTierTracking(from, ldaId, tierId);
            }
        }

        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function _addTokenToTierTracking(
        address to,
        uint256 ldaId,
        uint128 tierId
    )
        internal
    {
        uint256 ldaIndexForThisTier = _CURRENT_SUPPLY_[tierId];
        _TIER_ENUMERATION_[tierId][ldaIndexForThisTier] = ldaId;

        // Track where this ldaId is in the "list"
        _TIER_ENUMERATION_INDEX_[ldaId] = ldaIndexForThisTier;

        _OWNERS_[ldaId] = to;
    }

    /**
     * @dev Inspired by https://github.com/OpenZeppelin/openzeppelin-contracts/blob/6f23efa97056e643cefceedf86fdf1206b6840fb/contracts/token/ERC721/extensions/ERC721Enumerable.sol#L118
     */
    function _removeLDAFromTierTracking(
        address from,
        uint256 ldaId,
        uint128 tierId
    )
        internal
    {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastLdaIndex = _CURRENT_SUPPLY_[tierId] - 1;
        uint256 tokenIndex = _TIER_ENUMERATION_INDEX_[ldaId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastLdaIndex) {
            uint256 lastLdaId = _TIER_ENUMERATION_[tierId][lastLdaIndex];

            _TIER_ENUMERATION_[tierId][tokenIndex] = lastLdaId; // Move the last LDA to the slot of the to-delete LDA
            _TIER_ENUMERATION_INDEX_[lastLdaId] = tokenIndex; // Update the moved LDA's index

        }
        // This also deletes the contents at the last position of the array
        delete _TIER_ENUMERATION_INDEX_[ldaId];
        delete _TIER_ENUMERATION_[tierId][lastLdaIndex];

        _OWNERS_[ldaId] = from;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "../dependencies/openzeppelin/v4_7_0/ECDSAUpgradeable.sol";
import "../dependencies/openzeppelin/v4_7_0/Initializable.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 *
 * @custom:storage-size 52
 */
abstract contract EIP712UpgradeableGapless is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version) internal onlyInitializing {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal onlyInitializing {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { ECDSAUpgradeable } from "../dependencies/openzeppelin/v4_7_0/ECDSAUpgradeable.sol";

import { ERC1155UpgradeableGapless } from "./ERC1155UpgradeableGapless.sol";
import { EIP712UpgradeableGapless } from "./draft-EIP712UpgradeableGapless.sol";

abstract contract __Gap17 {
    uint256[17] private __gap;
}

/**
 * @title ERC1155PermitUpgradeable
 * @author Royal
 *
 * @notice ERC-1155 token with owner-level approvals via EIP-712 signatures.
 *
 * Compare with:
 *   https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v4.7.3/contracts/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol
 *   https://github.com/dievardump/erc721-with-permits/blob/de820e0185b3ae0d53c4cb840e1af4169159352f/contracts/ERC721WithPermit.sol
 */
abstract contract ERC1155PermitUpgradeable is
    ERC1155UpgradeableGapless,
    __Gap17,
    EIP712UpgradeableGapless
{
    // IMPORTANT:
    //   Specific to Royal LDA live contract upgrade:
    //   This contract together with the base contracts have to take up exactly 50 storage slots.
    //
    // Base contracts:
    //   [ 3 slots] ERC1155UpgradeableGapless
    //   [17 slots] __Gap17
    //   [ 2 slots] EIP712UpgradeableGapless
    uint256[8] private __gap;
    mapping(address => uint256) private _nonces;
    uint256[19] private __gap2;

    bytes32 public constant PERMIT_TYPEHASH = keccak256(
        "Permit(address owner,address spender,uint256 nonce,uint256 deadline)"
    );

    function __ERC1155Permit_init(
        string memory name,
        string memory version,
        string memory uri_
    )
        internal
        onlyInitializing
    {
        __EIP712_init_unchained(name, version);
        __ERC1155_init_unchained(uri_);
    }

    function __ERC1155Permit_init_unchained()
        internal
        onlyInitializing
    {}

    /**
     * @notice Callable by anyone to approve `spender` for all tokens using a permit signature.
     *
     * @param  owner      The address on whose behalf the spender may transfer any tokens.
     * @param  spender    Address of the spender.
     * @param  deadline   Deadline for the signature to be valid, in unix seconds.
     * @param  v          Signature component v.
     * @param  r          Signature component r.
     * @param  s          Signature component s.
     */
    function permit(
        address owner,
        address spender,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        public
    {
        require(
            block.timestamp <= deadline,
            "ERC1155Permit: expired deadline"
        );

        bytes32 structHash = keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                owner,
                spender,
                _nonces[owner]++,
                deadline
            )
        );
        bytes32 digest = _hashTypedDataV4(structHash);
        address signer = ECDSAUpgradeable.recover(digest, v, r, s);

        require(
            signer == owner,
            "ERC1155Permit: invalid signature"
        );

        _setApprovalForAll(owner, spender, true);
    }

    /**
     * @notice Cancel permits for a given nonce by incrementing the nonce.
     *
     * @param  owner  The owner to increment the nonce for.
     * @param  nonce  The nonce to be canceled.
     */
    function cancelNonce(
        address owner,
        uint256 nonce
    )
        external
    {
        require(
            _msgSender() == owner,
            "Sender is not the owner"
        );
        require(
            _nonces[owner]++ == nonce,
            "Nonce to cancel is not current"
        );
    }

    function nonces(
        address owner
    )
        external
        view
        returns (uint256)
    {
        return _nonces[owner];
    }

    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR()
        external
        view
        returns (bytes32)
    {
        return _domainSeparatorV4();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "../dependencies/openzeppelin/v4_7_0/IERC1155Upgradeable.sol";
import "../dependencies/openzeppelin/v4_7_0/IERC1155ReceiverUpgradeable.sol";
import "../dependencies/openzeppelin/v4_7_0/IERC1155MetadataURIUpgradeable.sol";
import "../dependencies/openzeppelin/v4_7_0/AddressUpgradeable.sol";
import "../dependencies/openzeppelin/v4_7_0/ContextUpgradeable.sol";
import "../dependencies/openzeppelin/v4_7_0/ERC165Upgradeable.sol";
import "../dependencies/openzeppelin/v4_7_0/Initializable.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155UpgradeableGapless is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC1155Upgradeable, IERC1155MetadataURIUpgradeable {
    using AddressUpgradeable for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    function __ERC1155_init(string memory uri_) internal onlyInitializing {
        __ERC1155_init_unchained(uri_);
    }

    function __ERC1155_init_unchained(string memory uri_) internal onlyInitializing {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @title RoyalUtil
 * @author Royal
 * @notice Supports common operations on LDA IDs.
 *
 * ROYAL LDA ID FORMAT V2 OVERVIEW
 *
 *  The ID of a royal LDA contains 3 pieces of information:
 *
 *    1. Tier ID: Denotes te tier that this token belongs to (e.g. GOLD, PLATINUM, DIAMOND).
 *       A tier ID is globally unique across all Royal drops.
 *
 *    2. Version: Represents the version, which may change with certain significant events such as
 *       the redemption of token extras. Including the version in the LDA ID ensures that
 *       marketplace bids and asks are invalidated when the token version changes.
 *
 *    3. Token ID: Represents the token number within the specific tier. We generally start
 *       at token #1 and count up to the tier max supply, but that is not strictly necessary.
 *
 *
 *  These parts are laid out in the uint256 LDA ID as follows:
 *
 *   MSB                                                 LSB
 *    [ tier_id             | version | token_id          ]
 *    [ **** **** **** **** | **      | ** **** **** **** ]
 *    [ 128 bits            | 16 bits | 112 bits          ]
 */
library RoyalUtil {

    uint256 constant UPPER_ISSUANCE_ID_MASK = uint256(type(uint128).max) << 128;
    uint256 constant LOWER_TOKEN_ID_MASK = type(uint112).max;
    uint256 constant TOKEN_VERSION_MASK =
        uint256(type(uint128).max) ^ LOWER_TOKEN_ID_MASK;

    /**
     * @dev Compose an LDA ID from its composite parts.
     */
    function composeLDA_ID(
        uint128 tierID,
        uint256 version,
        uint128 tokenID
    )
        internal
        pure
        returns (uint256 ldaID)
    {
        require(
            tierID != 0 && tokenID != 0,
            "Invalid ldaID"
        ); // NOTE: TierID and TokenID > 0

        require(
            version <= type(uint16).max,
            "invalid version"
        );

        return (uint256(tierID) << 128) + (version << 112) + uint256(tokenID);
    }

    /**
     * @dev Decompose a raw LDA ID into its composite parts.
     */
    function decomposeLDA_ID(
        uint256 ldaID
    )
        internal
        pure
        returns (
            uint128 tierID,
            uint256 version,
            uint128 tokenID
        )
    {
        tierID = uint128(ldaID >> 128);
        tokenID = uint128(ldaID & LOWER_TOKEN_ID_MASK);
        version = (ldaID & TOKEN_VERSION_MASK) >> 112;
        require(
            tierID != 0 && tokenID != 0,
            "Invalid ldaID"
        ); // NOTE: TierID and TokenID > 0
    }

    /**
     * @notice Returns the “canonical” form of a token ID, which ignores the version part.
     */
    function getCanonicalTokenId(
        uint256 tokenID
    )
        internal
        pure
        returns (uint256)
    {
        return tokenID & (TOKEN_VERSION_MASK ^ type(uint256).max);
    }
}