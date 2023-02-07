// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

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

pragma solidity ^0.8.0;

import "./ECDSA.sol";

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
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

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
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
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
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// EIP-712 is Final as of 2022-08-11. This file is deprecated.

import "./EIP712.sol";

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Forked from Solmate to handle clones.
/// @author Polymarket
/// @author Modified from Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked != 2, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {SafeTransferLib, ERC20} from "solmate/utils/SafeTransferLib.sol";

// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { ERC1155Holder } from "openzeppelin-contracts/token/ERC1155/utils/ERC1155Holder.sol";
import { ReentrancyGuard } from "common/ReentrancyGuard.sol";

abstract contract BaseExchange is ERC1155Holder, ReentrancyGuard { }

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { Auth } from "./mixins/Auth.sol";
import { Fees } from "./mixins/Fees.sol";
import { Assets } from "./mixins/Assets.sol";
import { Hashing } from "./mixins/Hashing.sol";
import { Trading } from "./mixins/Trading.sol";
import { Registry } from "./mixins/Registry.sol";
import { Pausable } from "./mixins/Pausable.sol";
import { Signatures } from "./mixins/Signatures.sol";
import { NonceManager } from "./mixins/NonceManager.sol";
import { AssetOperations } from "./mixins/AssetOperations.sol";

import { BaseExchange } from "./BaseExchange.sol";

import { Order } from "./libraries/OrderStructs.sol";

/// @title CTF Exchange
/// @notice Implements logic for trading CTF assets
/// @author Polymarket
contract CTFExchange is
    BaseExchange,
    Auth,
    Assets,
    Fees,
    Pausable,
    AssetOperations,
    Hashing("Polymarket CTF Exchange", "1"),
    NonceManager,
    Registry,
    Signatures,
    Trading
{
    constructor(address _collateral, address _ctf, address _proxyFactory, address _safeFactory)
        Assets(_collateral, _ctf)
        Signatures(_proxyFactory, _safeFactory)
    { }

    /*//////////////////////////////////////////////////////////////
                        PAUSE
    //////////////////////////////////////////////////////////////*/

    /// @notice Pause trading on the Exchange
    function pauseTrading() external onlyAdmin {
        _pauseTrading();
    }

    /// @notice Unpause trading on the Exchange
    function unpauseTrading() external onlyAdmin {
        _unpauseTrading();
    }

    /*//////////////////////////////////////////////////////////////
                        TRADING
    //////////////////////////////////////////////////////////////*/

    /// @notice Fills an order
    /// @param order        - The order to be filled
    /// @param fillAmount   - The amount to be filled, always in terms of the maker amount
    function fillOrder(Order memory order, uint256 fillAmount) external nonReentrant onlyOperator notPaused {
        _fillOrder(order, fillAmount, msg.sender);
    }

    /// @notice Fills a set of orders
    /// @param orders       - The order to be filled
    /// @param fillAmounts  - The amounts to be filled, always in terms of the maker amount
    function fillOrders(Order[] memory orders, uint256[] memory fillAmounts)
        external
        nonReentrant
        onlyOperator
        notPaused
    {
        _fillOrders(orders, fillAmounts, msg.sender);
    }

    /// @notice Matches a taker order against a list of maker orders
    /// @param takerOrder       - The active order to be matched
    /// @param makerOrders      - The array of maker orders to be matched against the active order
    /// @param takerFillAmount  - The amount to fill on the taker order, always in terms of the maker amount
    /// @param makerFillAmounts - The array of amounts to fill on the maker orders, always in terms of the maker amount
    function matchOrders(
        Order memory takerOrder,
        Order[] memory makerOrders,
        uint256 takerFillAmount,
        uint256[] memory makerFillAmounts
    ) external nonReentrant onlyOperator notPaused {
        _matchOrders(takerOrder, makerOrders, takerFillAmount, makerFillAmounts);
    }

    /*//////////////////////////////////////////////////////////////
                        CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Sets a new Proxy Wallet factory for the Exchange
    /// @param _newProxyFactory - The new Proxy Wallet factory
    function setProxyFactory(address _newProxyFactory) external onlyAdmin {
        _setProxyFactory(_newProxyFactory);
    }

    /// @notice Sets a new safe factory for the Exchange
    /// @param _newSafeFactory  - The new Safe wallet factory
    function setSafeFactory(address _newSafeFactory) external onlyAdmin {
        _setSafeFactory(_newSafeFactory);
    }

    /// @notice Registers a tokenId, its complement and its conditionId for trading on the Exchange
    /// @param token        - The tokenId being registered
    /// @param complement   - The complement of the tokenId
    /// @param conditionId  - The CTF conditionId
    function registerToken(uint256 token, uint256 complement, bytes32 conditionId) external onlyAdmin {
        _registerToken(token, complement, conditionId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

abstract contract IAssetOperations {
    function _getBalance(uint256 tokenId) internal virtual returns (uint256);

    function _transfer(address from, address to, uint256 id, uint256 value) internal virtual;

    function _mint(bytes32 conditionId, uint256 amount) internal virtual;

    function _merge(bytes32 conditionId, uint256 amount) internal virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

abstract contract IAssets {
    function getCollateral() public virtual returns (address);

    function getCtf() public virtual returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

interface IAuthEE {
    error NotAdmin();
    error NotOperator();

    /// @notice Emitted when a new admin is added
    event NewAdmin(address indexed newAdminAddress, address indexed admin);

    /// @notice Emitted when a new operator is added
    event NewOperator(address indexed newOperatorAddress, address indexed admin);

    /// @notice Emitted when an admin is removed
    event RemovedAdmin(address indexed removedAdmin, address indexed admin);

    /// @notice Emitted when an operator is removed
    event RemovedOperator(address indexed removedOperator, address indexed admin);
}

interface IAuth is IAuthEE {
    function isAdmin(address) external view returns (bool);

    function isOperator(address) external view returns (bool);

    function addAdmin(address) external;

    function addOperator(address) external;

    function removeAdmin(address) external;

    function removeOperator(address) external;

    function renounceAdminRole() external;

    function renounceOperatorRole() external;
}

// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { IERC20 } from "openzeppelin-contracts/token/ERC20/IERC20.sol";

/// @title IConditionalTokens
/// @notice Interface for the Gnosis ConditionalTokensFramework: https://github.com/gnosis/conditional-tokens-contracts/blob/master/contracts/ConditionalTokens.sol
interface IConditionalTokens {
    function payoutNumerators(bytes32 conditionId, uint256 index) external view returns (uint256);

    function payoutDenominator(bytes32 conditionId) external view returns (uint256);

    /// @dev This function prepares a condition by initializing a payout vector associated with the condition.
    /// @param oracle The account assigned to report the result for the prepared condition.
    /// @param questionId An identifier for the question to be answered by the oracle.
    /// @param outcomeSlotCount The number of outcome slots which should be used for this condition. Must not exceed 256.
    function prepareCondition(address oracle, bytes32 questionId, uint256 outcomeSlotCount) external;

    /// @dev Called by the oracle for reporting results of conditions. Will set the payout vector for the condition with the ID ``keccak256(abi.encodePacked(oracle, questionId, outcomeSlotCount))``, where oracle is the message sender, questionId is one of the parameters of this function, and outcomeSlotCount is the length of the payouts parameter, which contains the payoutNumerators for each outcome slot of the condition.
    /// @param questionId The question ID the oracle is answering for
    /// @param payouts The oracle's answer
    function reportPayouts(bytes32 questionId, uint256[] calldata payouts) external;

    /// @dev This function splits a position. If splitting from the collateral, this contract will attempt to transfer `amount` collateral from the message sender to itself. Otherwise, this contract will burn `amount` stake held by the message sender in the position being split worth of EIP 1155 tokens. Regardless, if successful, `amount` stake will be minted in the split target positions. If any of the transfers, mints, or burns fail, the transaction will revert. The transaction will also revert if the given partition is trivial, invalid, or refers to more slots than the condition is prepared with.
    /// @param collateralToken The address of the positions' backing collateral token.
    /// @param parentCollectionId The ID of the outcome collections common to the position being split and the split target positions. May be null, in which only the collateral is shared.
    /// @param conditionId The ID of the condition to split on.
    /// @param partition An array of disjoint index sets representing a nontrivial partition of the outcome slots of the given condition. E.g. A|B and C but not A|B and B|C (is not disjoint). Each element's a number which, together with the condition, represents the outcome collection. E.g. 0b110 is A|B, 0b010 is B, etc.
    /// @param amount The amount of collateral or stake to split.
    function splitPosition(
        IERC20 collateralToken,
        bytes32 parentCollectionId,
        bytes32 conditionId,
        uint256[] calldata partition,
        uint256 amount
    ) external;

    /// @dev This function merges CTF tokens into the underlying collateral.
    /// @param collateralToken The address of the positions' backing collateral token.
    /// @param parentCollectionId The ID of the outcome collections common to the position being split and the split target positions. May be null, in which only the collateral is shared.
    /// @param conditionId The ID of the condition to split on.
    /// @param partition An array of disjoint index sets representing a nontrivial partition of the outcome slots of the given condition. E.g. A|B and C but not A|B and B|C (is not disjoint). Each element's a number which, together with the condition, represents the outcome collection. E.g. 0b110 is A|B, 0b010 is B, etc.
    /// @param amount The amount of collateral or stake to split.
    function mergePositions(
        IERC20 collateralToken,
        bytes32 parentCollectionId,
        bytes32 conditionId,
        uint256[] calldata partition,
        uint256 amount
    ) external;

    /// @dev This function redeems a CTF ERC1155 token for the underlying collateral
    /// @param collateralToken The address of the positions' backing collateral token.
    /// @param parentCollectionId The ID of the outcome collections common to the position
    /// @param conditionId The ID of the condition to split on.
    /// @param indexSets Index sets of the outcome collection to combine with the parent outcome collection
    function redeemPositions(
        IERC20 collateralToken,
        bytes32 parentCollectionId,
        bytes32 conditionId,
        uint256[] calldata indexSets
    ) external;

    /// @dev Gets the outcome slot count of a condition.
    /// @param conditionId ID of the condition.
    /// @return Number of outcome slots associated with a condition, or zero if condition has not been prepared yet.
    function getOutcomeSlotCount(bytes32 conditionId) external view returns (uint256);

    /// @dev Constructs a condition ID from an oracle, a question ID, and the outcome slot count for the question.
    /// @param oracle The account assigned to report the result for the prepared condition.
    /// @param questionId An identifier for the question to be answered by the oracle.
    /// @param outcomeSlotCount The number of outcome slots which should be used for this condition. Must not exceed 256.
    function getConditionId(address oracle, bytes32 questionId, uint256 outcomeSlotCount)
        external
        pure
        returns (bytes32);

    /// @dev Constructs an outcome collection ID from a parent collection and an outcome collection.
    /// @param parentCollectionId Collection ID of the parent outcome collection, or bytes32(0) if there's no parent.
    /// @param conditionId Condition ID of the outcome collection to combine with the parent outcome collection.
    /// @param indexSet Index set of the outcome collection to combine with the parent outcome collection.
    function getCollectionId(bytes32 parentCollectionId, bytes32 conditionId, uint256 indexSet)
        external
        view
        returns (bytes32);

    /// @dev Constructs a position ID from a collateral token and an outcome collection. These IDs are used as the ERC-1155 ID for this contract.
    /// @param collateralToken Collateral token which backs the position.
    /// @param collectionId ID of the outcome collection associated with this position.
    function getPositionId(IERC20 collateralToken, bytes32 collectionId) external pure returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

interface IFeesEE {
    error FeeTooHigh();

    /// @notice Emitted when a fee is charged
    event FeeCharged(address indexed receiver, uint256 tokenId, uint256 amount);
}

abstract contract IFees is IFeesEE {
    function getMaxFeeRate() public pure virtual returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { Order } from "../libraries/OrderStructs.sol";

abstract contract IHashing {
    function hashOrder(Order memory order) public view virtual returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

abstract contract INonceManager {
    function incrementNonce() external virtual;

    function isValidNonce(address user, uint256 userNonce) public view virtual returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

interface IPausableEE {
    error Paused();

    event TradingPaused(address indexed pauser);

    event TradingUnpaused(address indexed pauser);
}

abstract contract IPausable is IPausableEE {
    function _pauseTrading() internal virtual;

    function _unpauseTrading() internal virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

interface IRegistryEE {
    error InvalidComplement();
    error InvalidTokenId();
    error AlreadyRegistered();

    /// @notice Emitted when a token is registered
    event TokenRegistered(uint256 indexed token0, uint256 indexed token1, bytes32 indexed conditionId);
}

abstract contract IRegistry is IRegistryEE {
    function getConditionId(uint256 tokenId) public view virtual returns (bytes32);

    function getComplement(uint256 tokenId) public view virtual returns (uint256);

    function validateTokenId(uint256 tokenId) public view virtual;

    function validateComplement(uint256 token0, uint256 token1) public view virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { Order } from "../libraries/OrderStructs.sol";

interface ISignaturesEE {
    error InvalidSignature();
}

abstract contract ISignatures is ISignaturesEE {
    function validateOrderSignature(bytes32 orderHash, Order memory order) public view virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { OrderStatus, Order } from "../libraries/OrderStructs.sol";

interface ITradingEE {
    error NotOwner();
    error NotTaker();
    error OrderFilledOrCancelled();
    error OrderExpired();
    error InvalidNonce();
    error MakingGtRemaining();
    error NotCrossing();
    error TooLittleTokensReceived();
    error MismatchedTokenIds();

    /// @notice Emitted when an order is cancelled
    event OrderCancelled(bytes32 indexed orderHash);

    /// @notice Emitted when an order is filled
    event OrderFilled(
        bytes32 indexed orderHash,
        address indexed maker,
        address indexed taker,
        uint256 makerAssetId,
        uint256 takerAssetId,
        uint256 makerAmountFilled,
        uint256 takerAmountFilled,
        uint256 fee
    );

    /// @notice Emitted when a set of orders is matched
    event OrdersMatched(
        bytes32 indexed takerOrderHash,
        address indexed takerOrderMaker,
        uint256 makerAssetId,
        uint256 takerAssetId,
        uint256 makerAmountFilled,
        uint256 takerAmountFilled
    );
}

interface ITrading is ITradingEE { }

// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { Order, Side } from "../libraries/OrderStructs.sol";

library CalculatorHelper {
    uint256 internal constant ONE = 10 ** 18;

    uint256 internal constant BPS_DIVISOR = 10_000;

    function calculateTakingAmount(uint256 makingAmount, uint256 makerAmount, uint256 takerAmount)
        internal
        pure
        returns (uint256)
    {
        if (makerAmount == 0) return 0;
        return makingAmount * takerAmount / makerAmount;
    }

    /// @notice Calculates the fee for an order
    /// @dev Fees are calculated based on amount of outcome tokens and the order's feeRate
    /// @param feeRateBps       - Fee rate, in basis points
    /// @param outcomeTokens    - The number of outcome tokens
    /// @param makerAmount      - The maker amount of the order
    /// @param takerAmount      - The taker amount of the order
    /// @param side             - The side of the order
    function calculateFee(
        uint256 feeRateBps,
        uint256 outcomeTokens,
        uint256 makerAmount,
        uint256 takerAmount,
        Side side
    ) internal pure returns (uint256 fee) {
        if (feeRateBps > 0) {
            uint256 price = _calculatePrice(makerAmount, takerAmount, side);
            if (price > 0 && price <= ONE) {
                if (side == Side.BUY) {
                    // Fee charged on Token Proceeds:
                    // baseRate * min(price, 1-price) * (outcomeTokens/price)
                    fee = (feeRateBps * min(price, ONE - price) * outcomeTokens) / (price * BPS_DIVISOR);
                } else {
                    // Fee charged on Collateral proceeds:
                    // baseRate * min(price, 1-price) * outcomeTokens
                    fee = feeRateBps * min(price, ONE - price) * outcomeTokens / (BPS_DIVISOR * ONE);
                }
            }
        }
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function calculatePrice(Order memory order) internal pure returns (uint256) {
        return _calculatePrice(order.makerAmount, order.takerAmount, order.side);
    }

    function _calculatePrice(uint256 makerAmount, uint256 takerAmount, Side side) internal pure returns (uint256) {
        if (side == Side.BUY) return takerAmount != 0 ? makerAmount * ONE / takerAmount : 0;
        return makerAmount != 0 ? takerAmount * ONE / makerAmount : 0;
    }

    function isCrossing(Order memory a, Order memory b) internal pure returns (bool) {
        if (a.takerAmount == 0 || b.takerAmount == 0) return true;

        return _isCrossing(calculatePrice(a), calculatePrice(b), a.side, b.side);
    }

    function _isCrossing(uint256 priceA, uint256 priceB, Side sideA, Side sideB) internal pure returns (bool) {
        if (sideA == Side.BUY) {
            if (sideB == Side.BUY) {
                // if a and b are bids
                return priceA + priceB >= ONE;
            }
            // if a is bid and b is ask
            return priceA >= priceB;
        }
        if (sideB == Side.BUY) {
            // if a is ask and b is bid
            return priceB >= priceA;
        }
        // if a and b are asks
        return priceA + priceB <= ONE;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

bytes32 constant ORDER_TYPEHASH = keccak256(
    "Order(uint256 salt,address maker,address signer,address taker,uint256 tokenId,uint256 makerAmount,uint256 takerAmount,uint256 expiration,uint256 nonce,uint256 feeRateBps,uint8 side,uint8 signatureType)"
);

struct Order {
    /// @notice Unique salt to ensure entropy
    uint256 salt;
    /// @notice Maker of the order, i.e the source of funds for the order
    address maker;
    /// @notice Signer of the order
    address signer;
    /// @notice Address of the order taker. The zero address is used to indicate a public order
    address taker;
    /// @notice Token Id of the CTF ERC1155 asset to be bought or sold
    /// If BUY, this is the tokenId of the asset to be bought, i.e the makerAssetId
    /// If SELL, this is the tokenId of the asset to be sold, i.e the takerAssetId
    uint256 tokenId;
    /// @notice Maker amount, i.e the maximum amount of tokens to be sold
    uint256 makerAmount;
    /// @notice Taker amount, i.e the minimum amount of tokens to be received
    uint256 takerAmount;
    /// @notice Timestamp after which the order is expired
    uint256 expiration;
    /// @notice Nonce used for onchain cancellations
    uint256 nonce;
    /// @notice Fee rate, in basis points, charged to the order maker, charged on proceeds
    uint256 feeRateBps;
    /// @notice The side of the order: BUY or SELL
    Side side;
    /// @notice Signature type used by the Order: EOA, POLY_PROXY or POLY_GNOSIS_SAFE
    SignatureType signatureType;
    /// @notice The order signature
    bytes signature;
}

enum SignatureType
// 0: ECDSA EIP712 signatures signed by EOAs
{
    EOA,
    // 1: EIP712 signatures signed by EOAs that own Polymarket Proxy wallets
    POLY_PROXY,
    // 2: EIP712 signatures signed by EOAs that own Polymarket Gnosis safes
    POLY_GNOSIS_SAFE
}

enum Side
// 0: buy
{
    BUY,
    // 1: sell
    SELL
}

enum MatchType
// 0: buy vs sell
{
    COMPLEMENTARY,
    // 1: both buys
    MINT,
    // 2: both sells
    MERGE
}

struct OrderStatus {
    bool isFilledOrCancelled;
    uint256 remaining;
}

// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

/// @notice Helper library to compute polymarket proxy wallet addresses
library PolyProxyLib {
    /// @notice Gets the polymarket proxy address for a signer
    /// @param signer - Address of the signer
    function getProxyWalletAddress(address signer, address implementation, address deployer)
        internal
        pure
        returns (address proxyWallet)
    {
        return _computeCreate2Address(deployer, implementation, keccak256(abi.encodePacked(signer)));
    }

    function _computeCreate2Address(address from, address target, bytes32 salt) internal pure returns (address) {
        bytes32 bytecodeHash = keccak256(_computeCreationCode(from, target));
        bytes32 _data = keccak256(abi.encodePacked(bytes1(0xff), from, salt, bytecodeHash));
        return address(uint160(uint256(_data)));
    }

    function _computeCreationCode(address deployer, address target) internal pure returns (bytes memory clone) {
        bytes memory consData = abi.encodeWithSignature("cloneConstructor(bytes)", new bytes(0));
        bytes memory buffer = new bytes(99);
        assembly {
            mstore(add(buffer, 0x20), 0x3d3d606380380380913d393d73bebebebebebebebebebebebebebebebebebebe)
            mstore(add(buffer, 0x2d), mul(deployer, 0x01000000000000000000000000))
            mstore(add(buffer, 0x41), 0x5af4602a57600080fd5b602d8060366000396000f3363d3d373d3d3d363d73be)
            mstore(add(buffer, 0x60), mul(target, 0x01000000000000000000000000))
            mstore(add(buffer, 116), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
        }
        // clone = bytes.concat(buffer, consData);
        clone = abi.encodePacked(buffer, consData);
        return clone;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

/// @title PolySafeLib
/// @notice Helper library to compute Polymarket gnosis safe addresses
library PolySafeLib {
    bytes private constant proxyCreationCode =
        hex"608060405234801561001057600080fd5b5060405161017138038061017183398101604081905261002f916100b9565b6001600160a01b0381166100945760405162461bcd60e51b815260206004820152602260248201527f496e76616c69642073696e676c65746f6e20616464726573732070726f766964604482015261195960f21b606482015260840160405180910390fd5b600080546001600160a01b0319166001600160a01b03929092169190911790556100e7565b6000602082840312156100ca578081fd5b81516001600160a01b03811681146100e0578182fd5b9392505050565b607c806100f56000396000f3fe6080604052600080546001600160a01b0316813563530ca43760e11b1415602857808252602082f35b3682833781823684845af490503d82833e806041573d82fd5b503d81f3fea264697066735822122015938e3bf2c49f5df5c1b7f9569fa85cc5d6f3074bb258a2dc0c7e299bc9e33664736f6c63430008040033";

    /// @notice Gets the Polymarket Gnosis safe address for a signer
    /// @param signer   - Address of the signer
    /// @param deployer - Address of the deployer contract
    function getSafeAddress(address signer, address implementation, address deployer)
        internal
        pure
        returns (address safe)
    {
        bytes32 bytecodeHash = keccak256(getContractBytecode(implementation));
        bytes32 salt = keccak256(abi.encode(signer));
        safe = _computeCreate2Address(deployer, bytecodeHash, salt);
    }

    function getContractBytecode(address masterCopy) internal pure returns (bytes memory) {
        return abi.encodePacked(proxyCreationCode, abi.encode(masterCopy));
    }

    function _computeCreate2Address(address deployer, bytes32 bytecodeHash, bytes32 salt)
        internal
        pure
        returns (address)
    {
        bytes32 _data = keccak256(abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash));
        return address(uint160(uint256(_data)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { IERC1155 } from "openzeppelin-contracts/token/ERC1155/IERC1155.sol";

import { SafeTransferLib, ERC20 } from "common/libraries/SafeTransferLib.sol";

/// @title TransferHelper
/// @notice Helper method to transfer tokens
library TransferHelper {
    /// @notice Transfers tokens from msg.sender to a recipient
    /// @param token    - The contract address of the token which will be transferred
    /// @param to       - The recipient of the transfer
    /// @param amount   - The amount to be transferred
    function _transferERC20(address token, address to, uint256 amount) internal {
        SafeTransferLib.safeTransfer(ERC20(token), to, amount);
    }

    /// @notice Transfers tokens from the targeted address to the given destination
    /// @param token    - The contract address of the token to be transferred
    /// @param from     - The originating address from which the tokens will be transferred
    /// @param to       - The destination address of the transfer
    /// @param amount   - The amount to be transferred
    function _transferFromERC20(address token, address from, address to, uint256 amount) internal {
        SafeTransferLib.safeTransferFrom(ERC20(token), from, to, amount);
    }

    /// @notice Transfer an ERC1155 token
    /// @param token    - The contract address of the token to be transferred
    /// @param from     - The originating address from which the tokens will be transferred
    /// @param to       - The destination address of the transfer
    /// @param id       - The tokenId of the token to be transferred
    /// @param amount   - The amount to be transferred
    function _transferFromERC1155(address token, address from, address to, uint256 id, uint256 amount) internal {
        IERC1155(token).safeTransferFrom(from, to, id, amount, "");
    }

    /// @notice Transfers a set of ERC1155 tokens
    /// @param token    - The contract address of the token to be transferred
    /// @param from     - The originating address from which the tokens will be transferred
    /// @param to       - The destination address of the transfer
    /// @param ids      - The tokenId of the token to be transferred
    /// @param amounts  - The amount to be transferred
    function _batchTransferFromERC1155(
        address token,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal {
        IERC1155(token).safeBatchTransferFrom(from, to, ids, amounts, "");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { IERC20 } from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import { IERC1155 } from "openzeppelin-contracts/token/ERC1155/IERC1155.sol";

import { IAssets } from "../interfaces/IAssets.sol";
import { IAssetOperations } from "../interfaces/IAssetOperations.sol";
import { IConditionalTokens } from "../interfaces/IConditionalTokens.sol";

import { TransferHelper } from "../libraries/TransferHelper.sol";

/// @title Asset Operations
/// @notice Operations on the CTF and Collateral assets
abstract contract AssetOperations is IAssetOperations, IAssets {
    bytes32 public constant parentCollectionId = bytes32(0);

    function _getBalance(uint256 tokenId) internal override returns (uint256) {
        if (tokenId == 0) return IERC20(getCollateral()).balanceOf(address(this));
        return IERC1155(getCtf()).balanceOf(address(this), tokenId);
    }

    function _transfer(address from, address to, uint256 id, uint256 value) internal override {
        if (id == 0) return _transferCollateral(from, to, value);
        return _transferCTF(from, to, id, value);
    }

    function _transferCollateral(address from, address to, uint256 value) internal {
        address token = getCollateral();
        if (from == address(this)) TransferHelper._transferERC20(token, to, value);
        else TransferHelper._transferFromERC20(token, from, to, value);
    }

    function _transferCTF(address from, address to, uint256 id, uint256 value) internal {
        TransferHelper._transferFromERC1155(getCtf(), from, to, id, value);
    }

    function _mint(bytes32 conditionId, uint256 amount) internal override {
        uint256[] memory partition = new uint256[](2);
        partition[0] = 1;
        partition[1] = 2;
        IConditionalTokens(getCtf()).splitPosition(
            IERC20(getCollateral()), parentCollectionId, conditionId, partition, amount
        );
    }

    function _merge(bytes32 conditionId, uint256 amount) internal override {
        uint256[] memory partition = new uint256[](2);
        partition[0] = 1;
        partition[1] = 2;

        IConditionalTokens(getCtf()).mergePositions(
            IERC20(getCollateral()), parentCollectionId, conditionId, partition, amount
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { IERC20 } from "openzeppelin-contracts/token/ERC20/IERC20.sol";

import { IAssets } from "../interfaces/IAssets.sol";

abstract contract Assets is IAssets {
    address internal immutable collateral;
    address internal immutable ctf;

    constructor(address _collateral, address _ctf) {
        collateral = _collateral;
        ctf = _ctf;
        IERC20(collateral).approve(ctf, type(uint256).max);
    }

    function getCollateral() public view override returns (address) {
        return collateral;
    }

    function getCtf() public view override returns (address) {
        return ctf;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { IAuth } from "../interfaces/IAuth.sol";

/// @title Auth
/// @notice Provides admin and operator roles and access control modifiers
abstract contract Auth is IAuth {
    /// @dev The set of addresses authorized as Admins
    mapping(address => uint256) public admins;

    /// @dev The set of addresses authorized as Operators
    mapping(address => uint256) public operators;

    modifier onlyAdmin() {
        if (admins[msg.sender] != 1) revert NotAdmin();
        _;
    }

    modifier onlyOperator() {
        if (operators[msg.sender] != 1) revert NotOperator();
        _;
    }

    constructor() {
        admins[msg.sender] = 1;
        operators[msg.sender] = 1;
    }

    function isAdmin(address usr) external view returns (bool) {
        return admins[usr] == 1;
    }

    function isOperator(address usr) external view returns (bool) {
        return operators[usr] == 1;
    }

    /// @notice Adds a new admin
    /// Can only be called by a current admin
    /// @param admin_ - The new admin
    function addAdmin(address admin_) external onlyAdmin {
        admins[admin_] = 1;
        emit NewAdmin(admin_, msg.sender);
    }

    /// @notice Adds a new operator
    /// Can only be called by a current admin
    /// @param operator_ - The new operator
    function addOperator(address operator_) external onlyAdmin {
        operators[operator_] = 1;
        emit NewOperator(operator_, msg.sender);
    }

    /// @notice Removes an existing Admin
    /// Can only be called by a current admin
    /// @param admin - The admin to be removed
    function removeAdmin(address admin) external onlyAdmin {
        admins[admin] = 0;
        emit RemovedAdmin(admin, msg.sender);
    }

    /// @notice Removes an existing operator
    /// Can only be called by a current admin
    /// @param operator - The operator to be removed
    function removeOperator(address operator) external onlyAdmin {
        operators[operator] = 0;
        emit RemovedOperator(operator, msg.sender);
    }

    /// @notice Removes the admin role for the caller
    /// Can only be called by an existing admin
    function renounceAdminRole() external onlyAdmin {
        admins[msg.sender] = 0;
        emit RemovedAdmin(msg.sender, msg.sender);
    }

    /// @notice Removes the operator role for the caller
    /// Can only be called by an exiting operator
    function renounceOperatorRole() external onlyOperator {
        operators[msg.sender] = 0;
        emit RemovedOperator(msg.sender, msg.sender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { IFees } from "../interfaces/IFees.sol";

abstract contract Fees is IFees {
    /// @notice Maximum fee rate that can be signed into an Order
    uint256 internal constant MAX_FEE_RATE_BIPS = 1000; // 1000 bips or 10%

    /// @notice Returns the maximum fee rate for an order
    function getMaxFeeRate() public pure override returns (uint256) {
        return MAX_FEE_RATE_BIPS;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { EIP712 } from "openzeppelin-contracts/utils/cryptography/draft-EIP712.sol";

import { IHashing } from "../interfaces/IHashing.sol";

import { Order, ORDER_TYPEHASH } from "../libraries/OrderStructs.sol";

abstract contract Hashing is EIP712, IHashing {
    bytes32 public immutable domainSeparator;

    constructor(string memory name, string memory version) EIP712(name, version) {
        domainSeparator = _domainSeparatorV4();
    }

    /// @notice Computes the hash for an order
    /// @param order - The order to be hashed
    function hashOrder(Order memory order) public view override returns (bytes32) {
        return _hashTypedDataV4(
            keccak256(
                abi.encode(
                    ORDER_TYPEHASH,
                    order.salt,
                    order.maker,
                    order.signer,
                    order.taker,
                    order.tokenId,
                    order.makerAmount,
                    order.takerAmount,
                    order.expiration,
                    order.nonce,
                    order.feeRateBps,
                    order.side,
                    order.signatureType
                )
            )
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { INonceManager } from "../interfaces/INonceManager.sol";

abstract contract NonceManager is INonceManager {
    mapping(address => uint256) public nonces;

    function incrementNonce() external override {
        updateNonce(1);
    }

    function updateNonce(uint256 val) internal {
        nonces[ msg.sender] = nonces[ msg.sender] + val;
    }

    function isValidNonce(address usr, uint256 nonce) public view override returns (bool) {
        return nonces[ usr] == nonce;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { IPausable } from "../interfaces/IPausable.sol";

abstract contract Pausable is IPausable {
    bool public paused = false;

    modifier notPaused() {
        if (paused) revert Paused();
        _;
    }

    function _pauseTrading() internal override {
        paused = true;
        emit TradingPaused(msg.sender);
    }

    function _unpauseTrading() internal override {
        paused = false;
        emit TradingUnpaused(msg.sender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { PolySafeLib } from "../libraries/PolySafeLib.sol";
import { PolyProxyLib } from "../libraries/PolyProxyLib.sol";

interface IPolyProxyFactory {
    function getImplementation() external view returns (address);
}

interface IPolySafeFactory {
    function masterCopy() external view returns (address);
}

abstract contract PolyFactoryHelper {
    /// @notice The Polymarket Proxy Wallet Factory Contract
    address public proxyFactory;
    /// @notice The Polymarket Gnosis Safe Factory Contract
    address public safeFactory;

    event ProxyFactoryUpdated(address indexed oldProxyFactory, address indexed newProxyFactory);

    event SafeFactoryUpdated(address indexed oldSafeFactory, address indexed newSafeFactory);

    constructor(address _proxyFactory, address _safeFactory) {
        proxyFactory = _proxyFactory;
        safeFactory = _safeFactory;
    }

    /// @notice Gets the Proxy factory address
    function getProxyFactory() public view returns (address) {
        return proxyFactory;
    }

    /// @notice Gets the Safe factory address
    function getSafeFactory() public view returns (address) {
        return safeFactory;
    }

    /// @notice Gets the Polymarket Proxy factory implementation address
    function getPolyProxyFactoryImplementation() public view returns (address) {
        return IPolyProxyFactory(proxyFactory).getImplementation();
    }

    /// @notice Gets the Safe factory implementation address
    function getSafeFactoryImplementation() public view returns (address) {
        return IPolySafeFactory(safeFactory).masterCopy();
    }

    /// @notice Gets the Polymarket proxy wallet address for an address
    /// @param _addr    - The address that owns the proxy wallet
    function getPolyProxyWalletAddress(address _addr) public view returns (address) {
        return PolyProxyLib.getProxyWalletAddress(_addr, getPolyProxyFactoryImplementation(), proxyFactory);
    }

    /// @notice Gets the Polymarket Gnosis Safe address for an address
    /// @param _addr    - The address that owns the proxy wallet
    function getSafeAddress(address _addr) public view returns (address) {
        return PolySafeLib.getSafeAddress(_addr, getSafeFactoryImplementation(), safeFactory);
    }

    function _setProxyFactory(address _proxyFactory) internal {
        emit ProxyFactoryUpdated(proxyFactory, _proxyFactory);
        proxyFactory = _proxyFactory;
    }

    function _setSafeFactory(address _safeFactory) internal {
        emit SafeFactoryUpdated(safeFactory, _safeFactory);
        safeFactory = _safeFactory;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { IRegistry } from "../interfaces/IRegistry.sol";

struct OutcomeToken {
    uint256 complement;
    bytes32 conditionId;
}

/// @title Registry
abstract contract Registry is IRegistry {
    mapping(uint256 => OutcomeToken) public registry;

    /// @notice Gets the conditionId from a tokenId
    /// @param token    - The token
    function getConditionId(uint256 token) public view override returns (bytes32) {
        return registry[ token].conditionId;
    }

    /// @notice Gets the complement of a tokenId
    /// @param token    - The token
    function getComplement(uint256 token) public view override returns (uint256) {
        validateTokenId(token);
        return registry[ token].complement;
    }

    /// @notice Validates the complement of a tokenId
    /// @param token        - The tokenId
    /// @param complement   - The complement to be validated
    function validateComplement(uint256 token, uint256 complement) public view override {
        if (getComplement(token) != complement) revert InvalidComplement();
    }
    /// @notice Validates that a tokenId is registered
    /// @param tokenId - The tokenId

    function validateTokenId(uint256 tokenId) public view override {
        if (registry[ tokenId].complement == 0) revert InvalidTokenId();
    }

    function _registerToken(uint256 token0, uint256 token1, bytes32 conditionId) internal {
        if (token0 == token1 || (token0 == 0 || token1 == 0)) revert InvalidTokenId();
        if (registry[ token0].complement != 0 || registry[ token1].complement != 0) revert AlreadyRegistered();

        registry[ token0] = OutcomeToken({complement: token1, conditionId: conditionId});

        registry[ token1] = OutcomeToken({complement: token0, conditionId: conditionId});

        emit TokenRegistered(token0, token1, conditionId);
        emit TokenRegistered(token1, token0, conditionId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import { IERC1271 } from "openzeppelin-contracts/interfaces/IERC1271.sol";
import { ECDSA } from "openzeppelin-contracts/utils/cryptography/ECDSA.sol";

import { SignatureType, Order } from "../libraries/OrderStructs.sol";

import { ISignatures } from "../interfaces/ISignatures.sol";

import { PolyFactoryHelper } from "./PolyFactoryHelper.sol";

/// @title Signatures
/// @notice Maintains logic that defines the various signature types and validates them
abstract contract Signatures is ISignatures, PolyFactoryHelper {
    constructor(address _proxyFactory, address _safeFactory) PolyFactoryHelper(_proxyFactory, _safeFactory) { }

    /// @notice Validates the signature of an order
    /// @param orderHash - The hash of the order
    /// @param order     - The order
    function validateOrderSignature(bytes32 orderHash, Order memory order) public view override {
        if (!isValidSignature(order.signer, order.maker, orderHash, order.signature, order.signatureType)) {
            revert InvalidSignature();
        }
    }

    /// @notice Verifies a signature for signed Order structs
    /// @param signer           - Address of the signer
    /// @param associated       - Address associated with the signer.
    ///                           For signature type EOA, this MUST be the same as the signer address.
    ///                           For signature types POLY_PROXY and POLY_GNOSIS_SAFE, this is the address of the proxy or the safe
    /// @param structHash       - The hash of the struct being verified
    /// @param signature        - The signature to be verified
    /// @param signatureType    - The signature type to be verified
    function isValidSignature(
        address signer,
        address associated,
        bytes32 structHash,
        bytes memory signature,
        SignatureType signatureType
    ) internal view returns (bool) {
        if (signatureType == SignatureType.EOA) {
            return verifyEOASignature(signer, associated, structHash, signature);
        } else if (signatureType == SignatureType.POLY_GNOSIS_SAFE) {
            return verifyPolySafeSignature(signer, associated, structHash, signature);
        } else {
            // POLY_PROXY
            return verifyPolyProxySignature(signer, associated, structHash, signature);
        }
    }

    /// @notice Verifies an EOA ECDSA signature
    /// Verifies that:
    /// 1) the signature is valid
    /// 2) the signer and maker are the same
    /// @param signer      - The address of the signer
    /// @param maker       - The address of the maker
    /// @param structHash  - The hash of the struct being verified
    /// @param signature   - The signature to be verified
    function verifyEOASignature(address signer, address maker, bytes32 structHash, bytes memory signature)
        internal
        pure
        returns (bool)
    {
        return (signer == maker) && verifyECDSASignature(signer, structHash, signature);
    }

    /// @notice Verifies an ECDSA signature
    /// @dev Reverts if the signature length is invalid or the recovered signer is the zero address
    /// @param signer      - Address of the signer
    /// @param structHash  - The hash of the struct being verified
    /// @param signature   - The signature to be verified
    function verifyECDSASignature(address signer, bytes32 structHash, bytes memory signature)
        internal
        pure
        returns (bool)
    {
        return ECDSA.recover(structHash, signature) == signer;
    }

    /// @notice Verifies a signature signed by a Polymarket proxy wallet
    // Verifies that:
    // 1) the ECDSA signature is valid
    // 2) the Proxy wallet is owned by the signer
    /// @param signer       - Address of the signer
    /// @param proxyWallet  - Address of the poly proxy wallet
    /// @param structHash   - Hash of the struct being verified
    /// @param signature    - Signature to be verified
    function verifyPolyProxySignature(address signer, address proxyWallet, bytes32 structHash, bytes memory signature)
        internal
        view
        returns (bool)
    {
        return verifyECDSASignature(signer, structHash, signature) && getPolyProxyWalletAddress(signer) == proxyWallet;
    }

    /// @notice Verifies a signature signed by a Polymarket Gnosis safe
    // Verifies that:
    // 1) the ECDSA signature is valid
    // 2) the Safe is owned by the signer
    /// @param signer      - Address of the signer
    /// @param safeAddress - Address of the safe
    /// @param hash        - Hash of the struct being verified
    /// @param signature   - Signature to be verified
    function verifyPolySafeSignature(address signer, address safeAddress, bytes32 hash, bytes memory signature)
        internal
        view
        returns (bool)
    {
        return verifyECDSASignature(signer, hash, signature) && getSafeAddress(signer) == safeAddress;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { IFees } from "../interfaces/IFees.sol";
import { IHashing } from "../interfaces/IHashing.sol";
import { ITrading } from "../interfaces/ITrading.sol";
import { IRegistry } from "../interfaces/IRegistry.sol";
import { ISignatures } from "../interfaces/ISignatures.sol";
import { INonceManager } from "../interfaces/INonceManager.sol";
import { IAssetOperations } from "../interfaces/IAssetOperations.sol";

import { CalculatorHelper } from "../libraries/CalculatorHelper.sol";
import { Order, Side, MatchType, OrderStatus } from "../libraries/OrderStructs.sol";

/// @title Trading
/// @notice Implements logic for trading CTF assets
abstract contract Trading is IFees, ITrading, IHashing, IRegistry, ISignatures, INonceManager, IAssetOperations {
    /// @notice Mapping of orders to their current status
    mapping(bytes32 => OrderStatus) public orderStatus;

    /// @notice Gets the status of an order
    /// @param orderHash    - The hash of the order
    function getOrderStatus(bytes32 orderHash) public view returns (OrderStatus memory) {
        return orderStatus[ orderHash];
    }

    /// @notice Validates an order
    /// @notice order - The order to be validated
    function validateOrder(Order memory order) public view {
        bytes32 orderHash = hashOrder(order);
        _validateOrder(orderHash, order);
    }

    /// @notice Cancels an order
    /// An order can only be cancelled by its maker, the address which holds funds for the order
    /// @notice order - The order to be cancelled
    function cancelOrder(Order memory order) external {
        _cancelOrder(order);
    }

    /// @notice Cancels a set of orders
    /// @notice orders - The set of orders to be cancelled
    function cancelOrders(Order[] memory orders) external {
        uint256 length = orders.length;
        uint256 i = 0;
        for (; i < length;) {
            _cancelOrder(orders[ i]);
            unchecked {
                ++i;
            }
        }
    }

    function _cancelOrder(Order memory order) internal {
        if (order.maker != msg.sender) revert NotOwner();

        bytes32 orderHash = hashOrder(order);
        OrderStatus storage status = orderStatus[orderHash];
        if (status.isFilledOrCancelled) revert OrderFilledOrCancelled();

        status.isFilledOrCancelled = true;
        emit OrderCancelled(orderHash);
    }

    function _validateOrder(bytes32 orderHash, Order memory order) internal view {
        // Validate order expiration
        if (order.expiration > 0 && order.expiration < block.timestamp) revert OrderExpired();

        // Validate signature
        validateOrderSignature(orderHash, order);

        // Validate fee
        if (order.feeRateBps > getMaxFeeRate()) revert FeeTooHigh();

        // Validate the token to be traded
        validateTokenId(order.tokenId);

        // Validate that the order can be filled
        if (orderStatus[orderHash].isFilledOrCancelled) revert OrderFilledOrCancelled();

        // Validate nonce
        if (!isValidNonce(order.maker, order.nonce)) revert InvalidNonce();
    }

    /// @notice Fills an order against the caller
    /// @param order        - The order to be filled
    /// @param fillAmount   - The amount to be filled, always in terms of the maker amount
    /// @param to           - The address to receive assets from filling the order
    function _fillOrder(Order memory order, uint256 fillAmount, address to) internal {
        uint256 making = fillAmount;
        (uint256 taking, bytes32 orderHash) = _performOrderChecks(order, making);

        uint256 fee = CalculatorHelper.calculateFee(
            order.feeRateBps, order.side == Side.BUY ? taking : making, order.makerAmount, order.takerAmount, order.side
        );

        (uint256 makerAssetId, uint256 takerAssetId) = _deriveAssetIds(order);

        // Transfer order proceeds minus fees from msg.sender to order maker
        _transfer(msg.sender, order.maker, takerAssetId, taking - fee);

        // Transfer makingAmount from order maker to `to`
        _transfer(order.maker, to, makerAssetId, making);

        // NOTE: Fees are "collected" by the Operator implicitly,
        // since the fee is deducted from the assets paid by the Operator

        emit OrderFilled(orderHash, order.maker, msg.sender, makerAssetId, takerAssetId, making, taking, fee);
    }

    /// @notice Fills a set of orders against the caller
    /// @param orders       - The order to be filled
    /// @param fillAmounts  - The amounts to be filled, always in terms of the maker amount
    /// @param to           - The address to receive assets from filling the order
    function _fillOrders(Order[] memory orders, uint256[] memory fillAmounts, address to) internal {
        uint256 length = orders.length;
        uint256 i = 0;
        for (; i < length;) {
            _fillOrder(orders[i], fillAmounts[i], to);
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Matches orders against each other
    /// Matches a taker order against a list of maker orders
    /// @param takerOrder       - The active order to be matched
    /// @param makerOrders      - The array of passive orders to be matched against the active order
    /// @param takerFillAmount  - The amount to fill on the taker order, in terms of the maker amount
    /// @param makerFillAmounts - The array of amounts to fill on the maker orders, in terms of the maker amount
    function _matchOrders(
        Order memory takerOrder,
        Order[] memory makerOrders,
        uint256 takerFillAmount,
        uint256[] memory makerFillAmounts
    ) internal {
        uint256 making = takerFillAmount;

        (uint256 taking, bytes32 orderHash) = _performOrderChecks(takerOrder, making);
        (uint256 makerAssetId, uint256 takerAssetId) = _deriveAssetIds(takerOrder);

        // Transfer takerOrder making amount from taker order to the Exchange
        _transfer(takerOrder.maker, address(this), makerAssetId, making);

        // Fill the maker orders
        _fillMakerOrders(takerOrder, makerOrders, makerFillAmounts);

        taking = _updateTakingWithSurplus(taking, takerAssetId);
        uint256 fee = CalculatorHelper.calculateFee(
            takerOrder.feeRateBps, takerOrder.side == Side.BUY ? taking : making, making, taking, takerOrder.side
        );

        // Execute transfers

        // Transfer order proceeds post fees from the Exchange to the taker order maker
        _transfer(address(this), takerOrder.maker, takerAssetId, taking - fee);

        // Charge the fee to taker order maker, explicitly transferring the fee from the Exchange to the Operator
        _chargeFee(address(this), msg.sender, takerAssetId, fee);

        // Refund any leftover tokens pulled from the taker to the taker order
        uint256 refund = _getBalance(makerAssetId);
        if (refund > 0) _transfer(address(this), takerOrder.maker, makerAssetId, refund);

        emit OrderFilled(
            orderHash, takerOrder.maker, address(this), makerAssetId, takerAssetId, making, taking, fee
        );

        emit OrdersMatched(orderHash, takerOrder.maker, makerAssetId, takerAssetId, making, taking);

        
    }

    function _fillMakerOrders(Order memory takerOrder, Order[] memory makerOrders, uint256[] memory makerFillAmounts)
        internal
    {
        uint256 length = makerOrders.length;
        uint256 i = 0;
        for (; i < length;) {
            _fillMakerOrder(takerOrder, makerOrders[i], makerFillAmounts[i]);
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Fills a Maker order
    /// @param takerOrder   - The taker order
    /// @param makerOrder   - The maker order
    /// @param fillAmount   - The fill amount
    function _fillMakerOrder(Order memory takerOrder, Order memory makerOrder, uint256 fillAmount) internal {
        MatchType matchType = _deriveMatchType(takerOrder, makerOrder);

        // Ensure taker order and maker order match
        _validateTakerAndMaker(takerOrder, makerOrder, matchType);

        uint256 making = fillAmount;
        (uint256 taking, bytes32 orderHash) = _performOrderChecks(makerOrder, making);
        uint256 fee = CalculatorHelper.calculateFee(
            makerOrder.feeRateBps,
            makerOrder.side == Side.BUY ? taking : making,
            makerOrder.makerAmount,
            makerOrder.takerAmount,
            makerOrder.side
        );
        (uint256 makerAssetId, uint256 takerAssetId) = _deriveAssetIds(makerOrder);

        _fillFacingExchange(making, taking, makerOrder.maker, makerAssetId, takerAssetId, matchType, fee);

        emit OrderFilled(
            orderHash, makerOrder.maker, takerOrder.maker, makerAssetId, takerAssetId, making, taking, fee
        );
    }

    /// @notice Performs common order computations and validation
    /// 1) Validates the order taker
    /// 2) Computes the order hash
    /// 3) Validates the order
    /// 4) Computes taking amount
    /// 5) Updates the order status in storage
    /// @param order    - The order being prepared
    /// @param making   - The amount of the order being filled, in terms of maker amount
    function _performOrderChecks(Order memory order, uint256 making)
        internal
        returns (uint256 takingAmount, bytes32 orderHash)
    {
        _validateTaker(order.taker);

        orderHash = hashOrder(order);

        // Validate order
        _validateOrder(orderHash, order);

        // Calculate taking amount
        takingAmount = CalculatorHelper.calculateTakingAmount(making, order.makerAmount, order.takerAmount);

        // Update the order status in storage
        _updateOrderStatus(orderHash, order, making);
    }

    /// @notice Fills a maker order using the Exchange as the counterparty
    /// @param makingAmount - Amount to be filled in terms of maker amount
    /// @param takingAmount - Amount to be filled in terms of taker amount
    /// @param maker        - The order maker
    /// @param makerAssetId - The Token Id of the Asset to be sold
    /// @param takerAssetId - The Token Id of the Asset to be received
    /// @param matchType    - The match type
    /// @param fee          - The fee charged to the Order maker
    function _fillFacingExchange(
        uint256 makingAmount,
        uint256 takingAmount,
        address maker,
        uint256 makerAssetId,
        uint256 takerAssetId,
        MatchType matchType,
        uint256 fee
    ) internal {
        // Transfer makingAmount tokens from order maker to Exchange
        _transfer(maker, address(this), makerAssetId, makingAmount);

        // Executes a match call based on match type
        _executeMatchCall(makingAmount, takingAmount, makerAssetId, takerAssetId, matchType);

        // Ensure match action generated enough tokens to fill the order
        if (_getBalance(takerAssetId) < takingAmount) revert TooLittleTokensReceived();

        // Transfer order proceeds minus fees from the Exchange to the order maker
        _transfer(address(this), maker, takerAssetId, takingAmount - fee);

        // Transfer fees from Exchange to the Operator
        _chargeFee(address(this), msg.sender, takerAssetId, fee);
    }

    function _deriveMatchType(Order memory takerOrder, Order memory makerOrder) internal pure returns (MatchType) {
        if (takerOrder.side == Side.BUY && makerOrder.side == Side.BUY) return MatchType.MINT;
        if (takerOrder.side == Side.SELL && makerOrder.side == Side.SELL) return MatchType.MERGE;
        return MatchType.COMPLEMENTARY;
    }

    function _deriveAssetIds(Order memory order) internal pure returns (uint256 makerAssetId, uint256 takerAssetId) {
        if (order.side == Side.BUY) return (0, order.tokenId);
        return (order.tokenId, 0);
    }

    /// @notice Executes a CTF call to match orders by minting new Outcome tokens
    /// or merging Outcome tokens into collateral.
    /// @param makingAmount - Amount to be filled in terms of maker amount
    /// @param takingAmount - Amount to be filled in terms of taker amount
    /// @param makerAssetId - The Token Id of the Asset to be sold
    /// @param takerAssetId - The Token Id of the Asset to be received
    /// @param matchType    - The match type
    function _executeMatchCall(
        uint256 makingAmount,
        uint256 takingAmount,
        uint256 makerAssetId,
        uint256 takerAssetId,
        MatchType matchType
    ) internal {
        if (matchType == MatchType.COMPLEMENTARY) {
            // Indicates a buy vs sell order
            // no match action needed
            return;
        }
        if (matchType == MatchType.MINT) {
            // Indicates matching 2 buy orders
            // Mint new Outcome tokens using Exchange collateral balance and fill buys
            return _mint(getConditionId(takerAssetId), takingAmount);
        }
        if (matchType == MatchType.MERGE) {
            // Indicates matching 2 sell orders
            // Merge the Exchange Outcome token balance into collateral and fill sells
            return _merge(getConditionId(makerAssetId), makingAmount);
        }
    }

    /// @notice Ensures the taker and maker orders can be matched against each other
    /// @param takerOrder   - The taker order
    /// @param makerOrder   - The maker order
    function _validateTakerAndMaker(Order memory takerOrder, Order memory makerOrder, MatchType matchType)
        internal
        view
    {
        if (!CalculatorHelper.isCrossing(takerOrder, makerOrder)) revert NotCrossing();

        // Ensure orders match
        if (matchType == MatchType.COMPLEMENTARY) {
            if (takerOrder.tokenId != makerOrder.tokenId) revert MismatchedTokenIds();
        } else {
            // both bids or both asks
            validateComplement(takerOrder.tokenId, makerOrder.tokenId);
        }
    }

    function _validateTaker(address taker) internal view {
        if (taker != address(0) && taker != msg.sender) revert NotTaker();
    }

    function _chargeFee(address payer, address receiver, uint256 tokenId, uint256 fee) internal {
        // Charge fee to the payer if any
        if (fee > 0) {
            _transfer(payer, receiver, tokenId, fee);
            emit FeeCharged(receiver, tokenId, fee);
        }
    }

    function _updateOrderStatus(bytes32 orderHash, Order memory order, uint256 makingAmount)
        internal
        returns (uint256 remaining)
    {
        OrderStatus storage status = orderStatus[orderHash];
        // Fetch remaining amount from storage
        remaining = status.remaining;

        // Update remaining if the order is new/has not been filled
        remaining = remaining == 0 ? order.makerAmount : remaining;

        // Throw if the makingAmount(amount to be filled) is greater than the amount available
        if (makingAmount > remaining) revert MakingGtRemaining();

        // Update remaining using the makingAmount
        remaining = remaining - makingAmount;

        // If order is completely filled, update isFilledOrCancelled in storage
        if (remaining == 0) status.isFilledOrCancelled = true;

        // Update remaining in storage
        status.remaining = remaining;
    }

    function _updateTakingWithSurplus(uint256 minimumAmount, uint256 tokenId) internal returns (uint256) {
        uint256 actualAmount = _getBalance(tokenId);
        if (actualAmount < minimumAmount) revert TooLittleTokensReceived();
        return actualAmount;
    }
}