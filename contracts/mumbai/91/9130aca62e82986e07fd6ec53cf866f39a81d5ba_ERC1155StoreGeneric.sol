// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract EIP712Upgradeable is Initializable {
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
    function __EIP712_init(string memory name, string memory version) internal initializer {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal initializer {
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
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

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
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165CheckerUpgradeable {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165Upgradeable).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
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
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
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

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
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
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165Upgradeable.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
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
        require(account != address(0), "ERC1155: balance query for the zero address");
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
            "ERC1155: caller is not owner nor approved"
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
            "ERC1155: transfer caller is not owner nor approved"
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

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

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

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
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

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
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

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
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
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
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
    function _beforeTokenTransfer(
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
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
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
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
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
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/utils/ERC1155Receiver.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Metadata.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

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
pragma solidity ^0.8.4;

/// @title Paper Key Manager
/// @author Winston Yeo
/// @notice PaperKeyManager makes it easy for developers to restrict certain functions to Paper.
/// @dev Developers are in charge of registering the contract with the initial Paper key. Paper will then help you  automatically rotate and update your key in line with good security hygiene
interface IPaperKeyManager {
    /// @notice Registers a Paper Key to a contract
    /// @dev Registers the @param _paperKey with the caller of the function
    /// @param _paperKey The Paper key that is associated with the checkout. You should be able to find this in the response of the checkout API or on the checkout dashbaord.
    /// @return bool indicating if the @param _paperKey was successfully registered with the calling address
    function register(address _paperKey) external returns (bool);

    /// @notice Verifies if the given @param _data is from Paper and have not been used before
    /// @dev Called as the first line in your function or extracted in a modifier. Refer to the Documentation for more usage details.
    /// @param _hash The bytes32 encoding of the data passed into your function
    /// @param _nonce a random set of bytes Paper passes your function which you forward. This helps ensure that the @param _hash has not been used before.
    /// @param _signature used to verify that Paper was the one who sent the @param _hash
    /// @return bool indicating if the @param _hash was successfully verified
    function verify(
        bytes32 _hash,
        bytes32 _nonce,
        bytes calldata _signature
    ) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ISaleBonuses.sol";
import "../interfaces/ISwapManager.sol";
import "../interfaces/IOracleManager.sol";
import "../interfaces/ITrustedMintable.sol";
import "../interfaces/IERC1155StoreGeneric.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@paperxyz/contracts/keyManager/IPaperKeyManager.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";

error SG__ZeroValue();
error SG__ZeroAddress();
error SG__ZeroSaleCap();
error SG__SaleInactive();
error SG__ZeroUnitSize();
error SG__RefundFailed();
error SG__TransferFailed();
error SG__ZeroUserSaleCap();
error SG__WithdrawalFailed();
error SG__NotGov(address _user);
error SG__InvalidSaleParameters();
error SG__PurchaseExceedsTotalMax();
error SG__PurchaseExceedsPlayerMax();
error SG__NotERC1155(address _token);
error SG__TokenNotSet(uint256 _tokenId);
error SG__ValueTooLarge(uint256 _amount);
error SG__InvalidERC1155PaymentTokenId();
error SG__NonExistentSale(uint256 _saleId);
error SG__PaperCurrencyTokenAddressNotSet();
error SG__ERC155PaymentDifferentArrayLength();
error SG__NotBeneficiary(address _walletAddress);
error SG__CurrencyNotWhitelisted(address _currency);
error SG__TokenNotEligibleForRebate(address _token);
error SG__DiscountTooLarge(uint256 _amount, uint256 _target);
error SG__SenderDoesNotOwnToken(address _token, uint256 _tokenId);
error SG__InsufficientEthValue(uint256 _amountSent, uint256 _price);
error SG__CombinedDiscountTooLarge(
    uint256 _saleId,
    uint256 _price,
    uint256 _bulkDsc,
    uint256 _ownershipDsc
);


/**
 * @title ERC1155 Store Generic
 * @author Jourdan
 * @notice This is a reusable token sale contract for PlanetIX
 */
contract ERC1155StoreGeneric is
    IERC1155StoreGeneric,
    ERC1155Receiver,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    EIP712Upgradeable
{
    /*------------------- STATE VARIABLES -------------------*/

    uint256 public s_saleId;
    address public s_moderator;
    address public s_tokenDonor;
    address public s_paperCurrency;

    Beneficiaries s_beneficiaries;
    uint256 private s_adminEthPayout; // disabled
    mapping(address => uint256) private s_adminTokenPayout; // disabled
    mapping(address => uint256) private s_beneficiaryBalances;
    mapping(address => mapping(address => uint256)) private s_beneficiaryTokenBalances;

    mapping(uint256 => Sale) public s_sales;
    mapping(uint256 => uint256) public s_sold;
    mapping(uint256 => bool) public s_saleStatus;
    mapping(uint256 => mapping(address => uint256)) public s_perPlayerSold;
    mapping(uint256 => mapping(address => bool)) public s_whitelistedCurrencies;

    mapping(uint256 => uint256[]) public s_bulkDiscountBreakpoints;
    mapping(uint256 => uint256[]) public s_bulkDiscountBasisPoints;
    mapping(uint256 => OwnershipDiscount[]) public s_ownershipDiscounts;

    mapping(address => bool) public s_isBeneficiary;
    mapping(address => bool) public s_trustedAddresses;
    uint256 public constant MAXIMUM_BASIS_POINTS = 10_000;

    IOracleManager public s_oracle;
    ISwapManager public s_swapManager;
    ISaleBonuses public s_saleBonuses;
    IPaperKeyManager public paperKeyManager;

    bool public publicSale;
    address private s_signer;
    bytes32 private constant BUY_MESSAGE =
        keccak256("BuyMessage(uint256 id,address sender,uint256 nonce)");
    mapping(address => mapping(uint256 => uint256)) public nonces;
    mapping(uint256 => bool) public preSale;

    mapping(uint256 => address) s_ERC1155PaymentTokenAddress;
    mapping(uint256 => mapping(uint256 => uint256)) public s_ERC1155tokenPaymentPrices;

    /*------------------- MODIFIERS -------------------*/

    modifier onlyGov() virtual {
        if (msg.sender != owner() && msg.sender != s_moderator) revert SG__NotGov(msg.sender);
        _;
    }

    modifier onlyBeneficiary() {
        if (!s_isBeneficiary[msg.sender]) revert SG__NotBeneficiary(msg.sender);
        _;
    }

    modifier onlyPaper(
        bytes32 _hash,
        bytes32 _nonce,
        bytes calldata _signature
    ) {
        bool success = paperKeyManager.verify(_hash, _nonce, _signature);
        require(success, "Failed to verify signature");
        _;
    }

    modifier onlyPresale(uint256 _id) {
        require(preSale[_id], "Sale not currently in presale status");
        _;
    }

    modifier onlyPublicSale(uint256 _id) {
        require(!preSale[_id], "Sale not currently in public sale status");
        _;
    }

    /*------------------- INITIALIZER -------------------*/

    function initialize() public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __EIP712_init("Generic__Store", "1");
    }

    /*------------------- ADMIN - ONLY FUNCTIONS -------------------*/

    /// @inheritdoc IERC1155StoreGeneric
    function createSale(
        address _token,
        uint256 _tokenId,
        uint256 _unitSize,
        uint256 _totalUnitSupply,
        uint256 _unitPrice,
        uint256 _unitsPerUser,
        address _defaultCurrency,
        bool _profitState,
        bool _adminSupplied
    ) public override onlyGov returns (uint256 _saleId) {
        // if (!ERC165CheckerUpgradeable.supportsInterface(_token, type(ITrustedMintable).interfaceId)) revert SG__NotERC1155(_token);
        if (_unitSize == 0) revert SG__ZeroUnitSize();
        if (_totalUnitSupply == 0) revert SG__ZeroSaleCap();
        if (_unitsPerUser == 0) revert SG__ZeroUserSaleCap();
        // if (bytes(ERC1155(_token).uri(_tokenId)).length == 0) revert SG__TokenNotSet(_tokenId);

        unchecked {
            _saleId = ++s_saleId;
        }

        s_sales[s_saleId] = Sale({
            token: _token,
            tokenId: _tokenId,
            unitSize: _unitSize,
            totalUnitSupply: _totalUnitSupply,
            unitPrice: _unitPrice,
            unitsPerUser: _unitsPerUser,
            defaultCurrency: _defaultCurrency,
            profitState: _profitState,
            paused: true,
            adminSupplied: _adminSupplied
        });

        s_whitelistedCurrencies[s_saleId][_defaultCurrency] = true;

        if (_adminSupplied) {
            IERC1155Upgradeable(_token).safeTransferFrom(
                s_tokenDonor,
                address(this),
                _tokenId,
                _totalUnitSupply * _unitSize,
                ""
            );
        }

        emit SaleCreated(
            _token,
            _tokenId,
            _unitSize,
            _totalUnitSupply,
            _unitPrice,
            _unitsPerUser,
            _defaultCurrency,
            _profitState,
            _adminSupplied
        );
    }

    /// @inheritdoc IERC1155StoreGeneric
    function modifySale(
        uint256 _saleId,
        uint256 _unitSize,
        uint256 _totalUnitSupply,
        uint256 _unitPrice,
        uint256 _unitsPerUser,
        address _defaultCurrency,
        bool _profitState
    ) external onlyGov {
        if (s_sales[_saleId].tokenId == 0) revert SG__NonExistentSale(_saleId);
        if (_unitSize == 0) revert SG__ZeroUnitSize();
        if (_totalUnitSupply == 0) revert SG__ZeroSaleCap();
        if (_unitsPerUser == 0) revert SG__ZeroUserSaleCap();

        uint256 totalTokensBefore = s_sales[_saleId].unitSize *
            (s_sales[_saleId].totalUnitSupply - s_sold[_saleId]);
        uint256 totalTokensAfter = _unitSize * _totalUnitSupply;

        s_sales[_saleId].unitSize = _unitSize;
        s_sales[_saleId].totalUnitSupply = _totalUnitSupply;
        s_sales[_saleId].unitPrice = _unitPrice;
        s_sales[_saleId].unitsPerUser = _unitsPerUser;
        s_sales[_saleId].defaultCurrency = _defaultCurrency;
        s_sales[_saleId].profitState = _profitState;

        if (s_sales[_saleId].adminSupplied) {
            if (totalTokensAfter > totalTokensBefore) {
                IERC1155Upgradeable(s_sales[_saleId].token).safeTransferFrom(
                    s_tokenDonor,
                    address(this),
                    s_sales[_saleId].tokenId,
                    (totalTokensAfter - totalTokensBefore),
                    ""
                );
            }
            if (totalTokensAfter < totalTokensBefore) {
                IERC1155Upgradeable(s_sales[_saleId].token).safeTransferFrom(
                    address(this),
                    s_tokenDonor,
                    s_sales[_saleId].tokenId,
                    (totalTokensBefore - totalTokensAfter),
                    ""
                );
            }
        }

        emit SaleModified(
            _saleId,
            _unitSize,
            _totalUnitSupply,
            _unitPrice,
            _unitsPerUser,
            _defaultCurrency,
            _profitState
        );
    }

    /// @inheritdoc IERC1155StoreGeneric
    function deleteSale(uint256 _saleId) external onlyGov {
        if (s_sales[_saleId].tokenId == 0) revert SG__NonExistentSale(_saleId);

        bool adminSupplied = s_sales[_saleId].adminSupplied;
        address token = s_sales[_saleId].token;
        uint256 tokenId = s_sales[_saleId].tokenId;
        uint256 tokensRemaining = s_sales[_saleId].unitSize *
            (s_sales[_saleId].totalUnitSupply - s_sold[_saleId]);

        delete s_sales[_saleId];
        delete s_sold[_saleId];
        if (s_ownershipDiscounts[_saleId].length > 0) {
            delete s_ownershipDiscounts[_saleId];
        }
        if (s_bulkDiscountBasisPoints[_saleId].length > 0) {
            delete s_bulkDiscountBasisPoints[_saleId];
            delete s_bulkDiscountBreakpoints[_saleId];
        }

        if (adminSupplied) {
            IERC1155Upgradeable(token).safeTransferFrom(
                address(this),
                s_tokenDonor,
                tokenId,
                tokensRemaining,
                ""
            );
        }

        emit SaleDeleted(_saleId);
    }

    /// @inheritdoc IERC1155StoreGeneric
    function setSaleState(uint256 _saleId, bool _paused) external onlyGov {
        if (s_sales[_saleId].tokenId == 0) revert SG__NonExistentSale(_saleId);
        s_sales[_saleId].paused = _paused;

        emit SaleStateSet(_saleId, _paused);
    }

    /// @inheritdoc IERC1155StoreGeneric
    function setERC1155PaymentPrices(
        uint256 _saleId,
        address _ERC1155PaymentAddress,
        uint256[] calldata _erc1155PaymentTokenIds,
        uint256[] calldata _erc1155PaymentPrices
    ) public override onlyGov {
        if (_erc1155PaymentTokenIds.length != _erc1155PaymentPrices.length) revert SG__ERC155PaymentDifferentArrayLength();

        s_whitelistedCurrencies[_saleId][_ERC1155PaymentAddress] = true;

        s_ERC1155PaymentTokenAddress[_saleId] = _ERC1155PaymentAddress;

        for(uint i=0; i<_erc1155PaymentTokenIds.length; i++) {
            s_ERC1155tokenPaymentPrices[_saleId][ _erc1155PaymentTokenIds[i] ] = _erc1155PaymentPrices[i];
        } 

        emit SetERC1155PaymentPrices(_saleId, _erc1155PaymentTokenIds, _erc1155PaymentPrices);
    } 

    /// @inheritdoc IERC1155StoreGeneric
    function whitelistCurrencies(uint256 _saleId, address[] calldata _currencyAddresses)
        external
        onlyGov
    {
        for (uint256 i; i < _currencyAddresses.length; i++) {
            s_whitelistedCurrencies[_saleId][_currencyAddresses[i]] = true;
        }

        emit CurrenciesWhitelisted(_saleId, _currencyAddresses);
    }

    /// @inheritdoc IERC1155StoreGeneric
    function withdraw(address _walletAddress, address _currency) external nonReentrant onlyGov {
        if (_currency == address(0)) {
            (bool success, ) = payable(_walletAddress).call{value: address(this).balance}("");
            if (!success) revert SG__WithdrawalFailed();
        } else {
            uint256 amount = IERC20(_currency).balanceOf(address(this));
            bool success = IERC20(_currency).transfer(_walletAddress, amount);
            if (!success) revert SG__WithdrawalFailed();
        }

        emit Withdrawal(_walletAddress, _currency);
    }

    /// @inheritdoc IERC1155StoreGeneric
    function withdrawERC1155token(
        address _walletAddress, 
        address _tokenAddress, 
        uint256 _tokenId
    ) external nonReentrant onlyGov {
        uint256 balance = IERC1155(_tokenAddress).balanceOf(address(this), _tokenId);
        IERC1155(_tokenAddress).safeTransferFrom(address(this), _walletAddress, _tokenId, balance, "");
    }

    function beneficiaryWithdraw(address _currency) external nonReentrant onlyBeneficiary {
        if (_currency == address(0)) {
            if (s_beneficiaryBalances[msg.sender] == 0) revert SG__ZeroValue();
            uint256 amount = s_beneficiaryBalances[msg.sender];
            s_beneficiaryBalances[msg.sender] = 0;
            (bool success, ) = payable(msg.sender).call{value: amount}("");
            if (!success) revert SG__WithdrawalFailed();
        } else {
            if (s_beneficiaryTokenBalances[msg.sender][_currency] == 0) revert SG__ZeroValue();
            uint256 amount = s_beneficiaryTokenBalances[msg.sender][_currency];
            s_beneficiaryTokenBalances[msg.sender][_currency] = 0;
            IERC20(_currency).approve(address(this), amount);
            bool success = IERC20(_currency).transferFrom(address(this), msg.sender, amount);
            if (!success) revert SG__WithdrawalFailed();
        }

        emit Withdrawal(msg.sender, _currency);
    }

    function setPaperCurrency(address _paperCurrency) external onlyGov {
        if (_paperCurrency == address(0)) revert SG__ZeroAddress();
        s_paperCurrency = _paperCurrency;

        emit PaperCurrencySet(_paperCurrency);
    }

    function setSaleBonuses(address _saleBonuses) external onlyGov {
        if (_saleBonuses == address(0)) revert SG__ZeroAddress();
        s_saleBonuses = ISaleBonuses(_saleBonuses);

        emit SaleBonusSet(_saleBonuses);
    }

    function setPaperKeyManager(IPaperKeyManager _paperKey) external onlyOwner {
        paperKeyManager = _paperKey;
    }

    function registerPaperKey(address _paperKey) external onlyOwner {
        require(paperKeyManager.register(_paperKey), "Error registering key");
    }

    function toggleState(uint256 _saleId) external onlyGov {
        preSale[_saleId] = !preSale[_saleId];
    }

    function setSigner(address _signer) external onlyOwner {
        require(_signer != address(0), "ADDRESS_ZERO");
        s_signer = _signer;
    }

    /*------------------- EXTERNAL FUNCTIONS -------------------*/

    /// @inheritdoc IERC1155StoreGeneric
    function buyTokens(
        address buyer,
        address tokenAddressRebate,
        uint256 tokenIdRebate,
        uint256 numPurchases,
        uint256 saleId,
        address _currency,
        bool _optInBonuses,
        bool _optInCategories
    ) external payable onlyPublicSale(saleId) {
        BuyTokenInputs memory saleInputs = BuyTokenInputs({
            buyer: buyer,
            tokenAddress: tokenAddressRebate,
            tokenId: tokenIdRebate,
            numPurchases: numPurchases,
            saleId: saleId,
            isERC1155Payment: false,
            erc1155PaymentTokenId: 0
        });

       _buyTokens(saleInputs, _currency, _optInBonuses, _optInCategories);
    }

    function buyTokensWithERC1155(
        address buyer,
        address tokenAddressRebate,
        uint256 tokenIdRebate,
        uint256 numPurchases,
        uint256 saleId,
        address _currency,
        bool _optInBonuses,
        bool _optInCategories,
        uint256 _erc1155PatmentTokenId
    ) external onlyPublicSale(saleId) {
        BuyTokenInputs memory saleInputs = BuyTokenInputs({
            buyer: buyer,
            tokenAddress: tokenAddressRebate,
            tokenId: tokenIdRebate,
            numPurchases: numPurchases,
            saleId: saleId,
            isERC1155Payment: true,
            erc1155PaymentTokenId: _erc1155PatmentTokenId
        });

        _buyTokens(saleInputs, _currency, _optInBonuses, _optInCategories);
    }

    function buyTokensWithSignature(
        address buyer,
        address tokenAddressRebate,
        uint256 tokenIdRebate,
        uint256 numPurchases,
        uint256 saleId,
        address _currency,
        bool _optInBonuses,
        bool _optInCategories,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable onlyPresale(saleId) {
        BuyTokenInputs memory saleInputs = BuyTokenInputs({
            buyer: buyer,
            tokenAddress: tokenAddressRebate,
            tokenId: tokenIdRebate,
            numPurchases: numPurchases,
            saleId: saleId,
            isERC1155Payment: false,
            erc1155PaymentTokenId: 0
        });

        uint256 nonce = nonces[msg.sender][saleInputs.saleId]++;

        bytes32 structHash = keccak256(
            abi.encode(BUY_MESSAGE, saleInputs.saleId, msg.sender, nonce)
        );
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = ECDSAUpgradeable.recover(hash, v, r, s);
        require(signer == s_signer, "INVALID__SIGNATURE");

        _buyTokens(saleInputs, _currency, _optInBonuses, _optInCategories);
    }

    function onPaper(
        address buyer,
        address tokenAddressRebate,
        uint256 tokenIdRebate,
        uint256 numPurchases,
        uint256 saleId
    ) external onlyPublicSale(saleId) {
        BuyTokenInputs memory saleInputs = BuyTokenInputs({
            buyer: buyer,
            tokenAddress: tokenAddressRebate,
            tokenId: tokenIdRebate,
            numPurchases: numPurchases,
            saleId: saleId,
            isERC1155Payment: false,
            erc1155PaymentTokenId: 0
        });
        if (s_paperCurrency == address(0)) revert SG__PaperCurrencyTokenAddressNotSet();
        _buyTokens(saleInputs, s_paperCurrency, false, false);
    }

    function tokenClaimable(
        address _buyer,
        address _tokenAddressRebate,
        uint256 _tokenIdRebate,
        uint256 _numPurchases,
        uint256 _saleId
    ) external view returns (string memory) {
        uint256 discountAmount;
        uint256 tokenType;
        Sale memory info = s_sales[_saleId];

        if (s_sales[_saleId].paused == true) return "SALE_INACTIVE";

        if (_tokenAddressRebate != address(0)) {
            OwnershipDiscount[] memory discounts = s_ownershipDiscounts[_saleId];
            for (uint256 i; i < discounts.length; ++i) {
                if (
                    discounts[i].tokenAddress == _tokenAddressRebate &&
                    (discounts[i].tokenType == TokenType.ERC721 ||
                        (discounts[i].tokenType == TokenType.ERC1155 &&
                            discounts[i].tokenId == _tokenIdRebate))
                ) {
                    discountAmount = discounts[i].basisPoints;
                    tokenType = uint256(discounts[i].tokenType);
                }
            }
            if (discountAmount > 0) {
                if (tokenType == 0) {
                    if (IERC721Upgradeable(_tokenAddressRebate).ownerOf(_tokenIdRebate) != _buyer) {
                        return "ERC721_NOT_OWNED";
                    }
                }
                if (tokenType == 1) {
                    if (
                        IERC1155Upgradeable(_tokenAddressRebate).balanceOf(
                            _buyer,
                            _tokenIdRebate
                        ) == 0
                    ) {
                        return "ERC1155_NOT_OWNED";
                    }
                }
            } else {
                return "DISCOUNT_NONEXISTENT";
            }
        }

        if (s_perPlayerSold[_saleId][_buyer] + _numPurchases > info.unitsPerUser) {
            return "BUYER_LIMIT_EXCEEDED";
        }
        if (s_sold[_saleId] + _numPurchases > info.totalUnitSupply) {
            return "TOTAL_LIMIT_EXCEEDED";
        }
        return "";
    }

    /*------------------- INTERNAL FUNCTIONS -------------------*/

    function _buyTokens(
        BuyTokenInputs memory saleInputs,
        address _currency,
        bool _optInBonuses,
        bool _optInCategories
    ) internal {
        if (s_sales[saleInputs.saleId].tokenId == 0) revert SG__NonExistentSale(saleInputs.saleId);
        if (s_sales[saleInputs.saleId].paused == true) revert SG__SaleInactive();
        if (s_whitelistedCurrencies[saleInputs.saleId][_currency] == false)
            revert SG__CurrencyNotWhitelisted(_currency);
        if (
            s_perPlayerSold[saleInputs.saleId][saleInputs.buyer] + saleInputs.numPurchases >
            s_sales[saleInputs.saleId].unitsPerUser
        ) revert SG__PurchaseExceedsPlayerMax();
        if (
            s_sold[saleInputs.saleId] + saleInputs.numPurchases >
            s_sales[saleInputs.saleId].totalUnitSupply
        ) revert SG__PurchaseExceedsTotalMax();

        unchecked {
            s_perPlayerSold[saleInputs.saleId][saleInputs.buyer] += saleInputs.numPurchases;
            s_sold[saleInputs.saleId] += saleInputs.numPurchases;
        }

        Sale memory sale = s_sales[saleInputs.saleId];

        if (saleInputs.isERC1155Payment) {
            uint256 price = 
                saleInputs.numPurchases * s_ERC1155tokenPaymentPrices[saleInputs.saleId][saleInputs.erc1155PaymentTokenId];

            if (price == 0) revert SG__InvalidERC1155PaymentTokenId();

            _erc1155Payment(
                msg.sender, 
                s_ERC1155PaymentTokenAddress[saleInputs.saleId],
                saleInputs.erc1155PaymentTokenId, 
                price
            );
        } else {
            uint256 balance = _applyBulkDiscount(saleInputs.saleId, saleInputs.numPurchases);
            if (saleInputs.tokenAddress != address(0))
                balance = _applyOwnershipDiscount(
                    saleInputs.saleId,
                    balance,
                    saleInputs.tokenAddress,
                    saleInputs.tokenId,
                    saleInputs.buyer
                );

            if (_currency == address(0)) {
                _ethPayment(msg.sender, sale.defaultCurrency, _currency, balance);
            } else {
                _erc20Payment(msg.sender, sale.defaultCurrency, _currency, balance, sale.profitState);
            }
        }

        if (_optInBonuses) {
            s_saleBonuses.claimBonusReward(
                saleInputs.saleId,
                uint32(saleInputs.numPurchases),
                _optInCategories,
                saleInputs.buyer
            );
        }

        if (!sale.adminSupplied) {
            ITrustedMintable(sale.token).trustedMint(
                saleInputs.buyer,
                sale.tokenId,
                sale.unitSize * saleInputs.numPurchases
            );
        } else {
            IERC1155Upgradeable(sale.token).safeTransferFrom(
                address(this),
                saleInputs.buyer,
                sale.tokenId,
                sale.unitSize * saleInputs.numPurchases,
                ""
            );
        }

        emit TokenBought(
            saleInputs.saleId,
            saleInputs.numPurchases,
            saleInputs.tokenId,
            saleInputs.tokenAddress,
            _currency,
            _optInBonuses,
            _optInCategories,
            saleInputs.buyer
        );
    }

    function _applyBulkDiscount(uint256 _saleId, uint256 _numPurchases)
        internal
        view
        returns (uint256 _finalPrice)
    {
        uint256 mod = MAXIMUM_BASIS_POINTS;
        uint256[] memory breakpoints = s_bulkDiscountBreakpoints[_saleId];
        uint256[] memory discounts = s_bulkDiscountBasisPoints[_saleId];
        for (uint256 i; i < breakpoints.length; i++) {
            if (_numPurchases >= breakpoints[i]) {
                mod -= discounts[i];
            }
        }
        _finalPrice = (mod * s_sales[_saleId].unitPrice * _numPurchases) / MAXIMUM_BASIS_POINTS;
    }

    function _applyOwnershipDiscount(
        uint256 _saleId,
        uint256 _balance,
        address _tokenAddress,
        uint256 _tokenId,
        address _buyer
    ) internal view returns (uint256 _finalPrice) {
        uint256 discountBps;
        uint256 tokenType;
        OwnershipDiscount[] memory discounts = s_ownershipDiscounts[_saleId];

        for (uint256 i; i < discounts.length; ++i) {
            if (
                discounts[i].tokenAddress == _tokenAddress &&
                (discounts[i].tokenType == TokenType.ERC721 ||
                    (discounts[i].tokenType == TokenType.ERC1155 &&
                        discounts[i].tokenId == _tokenId))
            ) {
                discountBps = discounts[i].basisPoints;
                tokenType = uint256(discounts[i].tokenType);
            }
        }
        if (discountBps > 0) {
            bool applyRebate;
            if (tokenType == 0) {
                if (IERC721Upgradeable(_tokenAddress).balanceOf(_buyer) > 0) {
                    applyRebate = true;
                } else {
                    revert SG__SenderDoesNotOwnToken(_tokenAddress, 0);
                }
            }
            if (tokenType == 1) {
                if (IERC1155Upgradeable(_tokenAddress).balanceOf(_buyer, _tokenId) > 0) {
                    applyRebate = true;
                } else {
                    revert SG__SenderDoesNotOwnToken(_tokenAddress, _tokenId);
                }
            }
            if (applyRebate) _finalPrice = _calculateDiscountedPrice(discountBps, _balance);
        } else {
            revert SG__TokenNotEligibleForRebate(_tokenAddress);
        }
    }

    function _ethPayment(
        address _recipient,
        address _defaultCurrency,
        address _currency,
        uint256 _balance
    ) internal {
        uint256 ethPrice;
        if (_currency == _defaultCurrency) {
            ethPrice = _balance;
        } else {
            ethPrice = s_oracle.getAmountOut(_defaultCurrency, _currency, _balance);
        }
        if (ethPrice > msg.value) {
            revert SG__InsufficientEthValue(msg.value, ethPrice);
        } else {
            Beneficiaries memory beneficiaries = s_beneficiaries;
            uint256 beneficiariesSize = beneficiaries.feeBps.length;
            for (uint256 i; i < beneficiariesSize; ++i) {
                uint256 amount = (beneficiaries.feeBps[i] * ethPrice) / MAXIMUM_BASIS_POINTS;
                s_beneficiaryBalances[beneficiaries.beneficiary[i]] += amount;
            }

            if (msg.value - ethPrice > 0) {
                (bool callSuccess, ) = payable(_recipient).call{value: msg.value - ethPrice}("");
                if (!callSuccess) revert SG__RefundFailed();
            }
        }
    }

    function _erc20Payment(
        address _recipient,
        address _defaultCurrency,
        address _currency,
        uint256 _balance,
        bool _profitState
    ) internal {
        uint256 erc20Price;
        if (_currency == _defaultCurrency) {
            erc20Price = _balance;
        } else {
            erc20Price = s_oracle.getAmountOut(_defaultCurrency, _currency, _balance);
        }
        if (!IERC20(_currency).transferFrom(_recipient, address(this), erc20Price))
            revert SG__TransferFailed();
        if (!_profitState && (_currency != _defaultCurrency)) {
            IERC20(_currency).approve(address(s_swapManager), erc20Price);
            s_swapManager.swap(_currency, _defaultCurrency, erc20Price, address(this));
            _distributeBeneficiaryTokens(_defaultCurrency, _balance);
        } else {
            _distributeBeneficiaryTokens(_currency, erc20Price);
        }
    }

    function _erc1155Payment(
        address _recipient,
        address _paymentTokenAddress,
        uint256 _paymentTokenId,
        uint256 _balance
    ) internal {
        IERC1155(_paymentTokenAddress).safeTransferFrom(_recipient, address(this), _paymentTokenId, _balance, "");
    }

    function _calculateDiscountedPrice(uint256 _bps, uint256 _salePrice)
        public
        pure
        returns (uint256)
    {
        return ((MAXIMUM_BASIS_POINTS - _bps) * _salePrice) / MAXIMUM_BASIS_POINTS;
    }

    function _distributeBeneficiaryTokens(address _currency, uint256 _price) internal {
        Beneficiaries memory beneficiaries = s_beneficiaries;
        uint256 beneficiariesSize = beneficiaries.feeBps.length;
        for (uint256 i; i < beneficiariesSize; ++i) {
            uint256 amount = (beneficiaries.feeBps[i] * _price) / MAXIMUM_BASIS_POINTS;
            s_beneficiaryTokenBalances[beneficiaries.beneficiary[i]][_currency] += amount;
        }
    }

    /// @inheritdoc IERC1155StoreGeneric
    function setFeeWalletsAndPercentages(
        address[] calldata _walletAddresses,
        uint256[] calldata _feeBps
    ) external onlyGov {
        uint256 sum;
        for (uint256 i; i < _feeBps.length; ++i) {
            sum += _feeBps[i];
            s_isBeneficiary[_walletAddresses[i]] = true;
        }
        if (sum > 10000) revert SG__ValueTooLarge(sum);
        s_beneficiaries = Beneficiaries(_feeBps, _walletAddresses);
    }

    /// @inheritdoc IERC1155StoreGeneric
    function setSwapManager(address _swapManager) external onlyGov {
        s_swapManager = ISwapManager(_swapManager);
    }

    /// @inheritdoc IERC1155StoreGeneric
    function setOracleManager(address _oracleManager) external onlyGov {
        s_oracle = IOracleManager(_oracleManager);
    }

    /// @inheritdoc IERC1155StoreGeneric
    function setModerator(address _moderatorAddress) external onlyGov {
        if (_moderatorAddress == address(0)) revert SG__ZeroAddress();
        s_moderator = _moderatorAddress;
    }

    function setDonor(address _donor) external onlyGov {
        if (_donor == address(0)) revert SG__ZeroAddress();
        s_tokenDonor = _donor;
    }

    function getBeneficiaries() external view returns (IERC1155StoreGeneric.Beneficiaries memory) {
        return s_beneficiaries;
    }

    function getSaleInfo(uint256 _id) external view returns (IERC1155StoreGeneric.Sale memory) {
        return s_sales[_id];
    }

    function getOwnershipDiscounts(uint256 _saleId) public view returns(OwnershipDiscount[] memory) { 
        return s_ownershipDiscounts[_saleId];
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external view override returns (bytes4) {
        require(from != address(0), "GENERIC STORE: Address Zero");
        require(operator == address(this), "GENERIC STORE: Invalid Operator");

        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external view override returns (bytes4) {
        require(from != address(0), "GENERIC STORE: Address Zero");
        require(operator == address(this), "GENERIC STORE: Invalid Operator");

        return
            bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ISaleBonuses {
    error SB__ZeroWeight();
    error SB__ZeroAmount();
    error SB__InvalidCategoryId(uint256 _categoryId);
    error SB__NotConditionalProvider(address _address);
    error SB__NotERC721or1155(address _tokenAddress);
    error SB__ArraysNotSameLength();
    error SB__NotOracle();
    error SB__ZeroAddress();
    error SB__MaxDrawsExceeded(uint256 _amount);
    error SB__Unauthorized(address _sender);

    /**
     * @notice Event emitted when a category has its eligibility updated
     * @param _tokenId The token id which the category belongs to
     * @param _categoryId The id of the category
     * @param _provider The address of the eligibility provider
     */
    event CategoryEligibilitySet(
        address _addr,
        uint256 _tokenId,
        uint256 _categoryId,
        address _provider
    );
    /**
     * @notice Event emitted when a category is created
     * @param _id The token id a category has been created for
     * @param _categoryId The id of the new category
     */
    event CategoryCreated(address _addr, uint256 _id, uint256 _categoryId);
    /**
     * @notice Event emitted when a category is deleted
     * @param _id The token id a category has been deleted for
     * @param _categoryId The id of the deleted category
     */
    event CategoryDeleted(address _addr, uint256 _id, uint256 _categoryId);
    /**
     * @notice Event emitted when a categories content amounts are updated
     * @param _id The token id of the token
     * @param _categoryId The category Id of a token
     * @param _amounts Array containing the amounts
     * @param _weights Array containing the weights, corresponding by index.
     */
    event ContentAmountsUpdated(
        address _addr,
        uint256 _id,
        uint256 _categoryId,
        uint256[] _amounts,
        uint256[] _weights
    );
    /**
     * @notice Event emitted when the contents of a category are updated
     * @param _id The token id of the token
     * @param _contentCategory The category Id of a token
     * @param _tokens Array of addresses to the content tokens.
     * @param _ids Tokens ids of contents. Will be ignored if the token is an ERC721
     * @param _amounts Array containing the amounts of each tokens
     * @param _weights Array containing the weights, corresponding by index.
     */
    event ContentsUpdated(
        address _addr,
        uint256 _id,
        uint256 _contentCategory,
        address[] _tokens,
        uint256[] _ids,
        uint256[] _amounts,
        uint256[] _weights
    );

    /**
     * @notice Event emitted when the user gains a reward from opening a pack.
     * @param _token Address of the reward token
     * @param _tokenId The token id of the token
     * @param _amount amount of the token being rewarded
     */
    event RewardGranted(address _token, uint256 _tokenId, uint256 _amount);

    struct ContentCategory {
        uint256 id;
        uint256 contentAmountsTotalWeight;
        uint256 contentsTotalWeight;
        uint256[] contentAmounts;
        uint256[] contentAmountsWeights;
        uint256[] tokenAmounts;
        uint256[] tokenWeights;
        address[] tokens;
        uint256[] tokenIds;
    }

    struct ContentInputs {
        address[] _tokens;
        uint256[] _ids;
        uint256[] _amounts;
        uint256[] _weights;
    }

    struct RequestInputs {
        address user;
        uint256 saleId;
        uint256 openings;
        uint256 randWordsCount;
        uint256[] excludedIds;
        address addr;
    }

    /**
     * @notice Used to create a content category
     * @param _id The token id to create a category for
     * @return _categoryId The new ID of the content category
     *
     * Throws SB__NotGov on non gov call
     *
     * Emits CategoryCreated
     */
    function createContentCategory(address _addr, uint256 _id)
        external
        returns (uint256 _categoryId);

    /**
     * @notice Deletes a content category
     * @param _id The token id
     * @param _contentCategory The content category ID
     *
     * Throws SB__NotGov on non gov call
     * Throws SB__InvalidCategoryId on invalid category ID
     *
     * Emits CategoryDeleted
     */
    function deleteContentCategory(
        address _addr,
        uint256 _id,
        uint256 _contentCategory
    ) external;

    /**
     * @notice Used to get the content categories for a token
     * @param _id The token id
     * @return _categories Array of ContentCategory structs corresponding to the given id
     */
    function getContentCategories(address _addr, uint256 _id)
        external
        view
        returns (ContentCategory[] memory _categories);

    /**
     * @notice Used to edit the content amounts for a content category
     * @param _id The token id of the token
     * @param _contentCategory The category Id of a token
     * @param _amounts Array containing the amounts
     * @param _weights Array containing the weights, corresponding by index.
     *
     * Throws SB__NotGov on non gov call.
     * Throws SB__ZeroWeight on any weight being zero
     * @dev Does not throw anything on zero amounts
     * Throws SB__InvalidCategoryId on invalid category ID
     * Throws SB__ArraysNotSameLength on arrays not being same length
     *
     * Emits ContentAmountsUpdated
     */
    function setContentAmounts(
        address _addr,
        uint256 _id,
        uint256 _contentCategory,
        uint256[] memory _amounts,
        uint256[] memory _weights
    ) external;

    /**
     * @notice Used to edit the contents for a content category
     * @dev _tokens needs to be erc1155 or erc 721 implementing ITrustedMintable
     * @param _id The token id of the token
     * @param _contentCategory The category Id of a token
     *
     * Throws SB__NotGov on non gov call.
     * Throws SB__ZeroWeight on any weight being zero
     * Throws SB__ZeroAmount on any amount being zero
     * Throws SB__InvalidCategoryId on invalid category ID
     * Throws SB__NotERC721or1155 on any address not being an erc1155 or erc721 token
     * Throws SB__ArraysNotSameLength on arrays not being same length
     *
     * Emits ContentsUpdated
     */
    function setContents(
        address _addr,
        uint256 _id,
        uint256 _contentCategory,
        ContentInputs memory contents
    ) external;

    function claimBonusReward(
        uint256 _id,
        uint32 _amount,
        bool _optInConditionals,
        address _recipient
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IERC1155StoreGeneric {
    /**
     * @notice Struct for a token sale
     * @param _token The token being sold
     * @param _tokenId The token id being sold
     * @param _unitSize Number of tokens being sold as a single unit
     * @param _totalUnitSupply Total number of units being offered
     * @param _unitPrice Price of a single unit
     * @param _unitsPerUser Max amount of units allowed for a single user
     * @param _defaultCurrency Default currency (contract address)
     * @param _profitState Whether all sale profits should be instantly exchanged
        for the default currency or stored as is (false to exchange, true otherwise)
     * @param _paused Sale state
     * @param _adminSupplied Whether or not the tokens for the sale will be admin-supplied
     * @param _isERC1155Payment Whether the sale should be paid with erc1155 token
     * @param _erc1155PaymentTokenId erc1155 token with which payment is done in case of erc1155 payment
     */
    struct Sale {
        address token;
        uint256 tokenId;
        uint256 unitSize;
        uint256 totalUnitSupply;
        uint256 unitPrice;
        uint256 unitsPerUser;
        address defaultCurrency;
        bool profitState;
        bool paused;
        bool adminSupplied;
    }

    // Used to classify token types in the ownership rebate struct
    enum TokenType {
        ERC721,
        ERC1155
    }

    /**
     * @notice Used to provide specifics for ownership based discounts
     * @param tokenType The type of token
     * @param tokenAddress The address of the token contract
     * @param tokenId The token id, ignored if ERC721 is provided for the token type
     * @param basisPoints The discount in basis points
     */
    struct OwnershipDiscount {
        TokenType tokenType;
        address tokenAddress;
        uint256 tokenId; // ignored if ERC721
        uint256 basisPoints;
    }

    /// TODO add natspec
    struct Beneficiaries {
        uint256[] feeBps;
        address[] beneficiary;
    }

    struct BuyTokenInputs {
        address buyer;
        address tokenAddress;
        uint256 tokenId;
        uint256 numPurchases;
        uint256 saleId;
        bool isERC1155Payment;
        uint256 erc1155PaymentTokenId;
    }

    event SaleCreated(
        address _token,
        uint256 _tokenId,
        uint256 _unitSize,
        uint256 _totalUnitSupply,
        uint256 _unitPrice,
        uint256 _unitsPerUser,
        address _defaultCurrency,
        bool _profitState,
        bool _adminSupplied
    );

    event SaleModified(
        uint256 _saleId,
        uint256 _unitSize,
        uint256 _totalUnitSupply,
        uint256 _unitPrice,
        uint256 _unitsPerUser,
        address _defaultCurrency,
        bool _profitState
    );

    event SaleDeleted(uint256 _saleId);

    event SaleStateSet(uint256 _saleId, bool _paused);

    event BulkDiscountAdded(uint256 _saleId, uint256 _breakpoint, uint256 _basisPoints);

    event OwnershipDiscountAdded(uint256 _saleId, OwnershipDiscount _info);

    event CurrenciesWhitelisted(uint256 _saleId, address[] _currencyAddresses);

    event Withdrawal(address _walletAddress, address _currency);

    event PaperCurrencySet(address _paperCurrency);

    event SaleBonusSet(address _saleBonuses);

    event TokenBought(
        uint256 _saleId,
        uint256 _numPurchases,
        uint256 _tokenId,
        address _tokenAddress,
        address _currency,
        bool _optInBonuses,
        bool _optInCategories,
        address _buyer
    );

    event SetERC1155PaymentPrices(uint256 _saleId, uint256[] _erc1155TokenIds, uint256[] _erc1155TokenPrices);

    /**
     * @notice Creates a new sale for a particular token.
     * @param _token The token being sold
     * @param _tokenId The token id being sold
     * @param _unitSize Number of tokens being sold as a single unit
     * @param _totalUnitSupply Total number of units being offered
     * @param _unitPrice Price of a single unit
     * @param _unitsPerUser Max amount of units allowed for a single user
     * @param _defaultCurrency Default currency (contract address)
     * @param _profitState Whether all sale profits should be instantly exchanged
        for the default currency or stored as is (false to exchange, true otherwise)
     * @param _adminSupplied Whether or not the tokens for the sale will be admin-supplied
     */
    function createSale(
        address _token,
        uint256 _tokenId,
        uint256 _unitSize,
        uint256 _totalUnitSupply,
        uint256 _unitPrice,
        uint256 _unitsPerUser,
        address _defaultCurrency,
        bool _profitState,
        bool _adminSupplied
    ) external returns (uint256 _saleId);

    /**
     * @notice Sets ERC1155 prices for the given sale
     * @param _saleId Id of the sale to set ERC1155 prices
     * @param _ERC1155PaymentAddress Address of the ERC1155 payment token
     * @param  _erc1155PaymentTokenIds Ids of the ERC1155 tokens which are enabled for the payment
     * @param  _erc1155PaymentPrices Prices of ERC1155 payments for corresponding token ids
     */
    function setERC1155PaymentPrices(
        uint256 _saleId,
        address _ERC1155PaymentAddress,
        uint256[] calldata _erc1155PaymentTokenIds,
        uint256[] calldata _erc1155PaymentPrices
    ) external;

    /**
     * @notice Modifies a pre-existing sale for a token.
     * @param _saleId Id of the sale to alter
     * @param _unitSize Number of tokens being sold as a single unit
     * @param _totalUnitSupply Total number of units being offered
     * @param _unitPrice Price of a single unit
     * @param _unitsPerUser Max amount of units allowed for a single user
     * @param _defaultCurrency Default currency (contract address)
     * @param _profitState Whether all sale profits should be instantly exchanged
        for the default currency or stored as is (false to exchange, true otherwise)
     */
    function modifySale(
        uint256 _saleId,
        uint256 _unitSize,
        uint256 _totalUnitSupply,
        uint256 _unitPrice,
        uint256 _unitsPerUser,
        address _defaultCurrency,
        bool _profitState
    ) external;

    /**
     * @notice Delete a sale
     * @param _saleId The sale ID to delete
     */
    function deleteSale(uint256 _saleId) external;

    /**
     * @notice Start or pause sales
     * @param _saleId The sale ID to set the status for
     * @param _paused The sale status
     */
    function setSaleState(uint256 _saleId, bool _paused) external;

    /**
     * @notice Whitelists currencies to be used in a particular sale
     * @param _saleId The sale id
     * @param _currencyAddresses The addresses payment currencies to whitelist
     */
    function whitelistCurrencies(uint256 _saleId, address[] calldata _currencyAddresses) external;

    /**
     * @notice Empty the treasury into the owners or an arbitrary wallet
     * @param _walletAddress The withdrawal EOA address
     * @param _currency ERC20 currency to withdraw, ZERO address implies MATIC
     */
    function withdraw(address _walletAddress, address _currency) external;

     /**
     * @notice Empty the treasury of ERC1155 into the owners or an arbitrary wallet
     * @param _walletAddress The withdrawal EOA address
     * @param _tokenAddress Address of the ERC1155 token to withdraw
     * @param _tokenId ID of the ERC1155 token to withdraw
     */    
    function withdrawERC1155token(
        address _walletAddress, 
        address _tokenAddress, 
        uint256 _tokenId
    ) external;

    /**
     * @notice Purchase any active sale in any whitelisted currency
     */
    function buyTokens(
        address buyer,
        address tokenAddressRebate,
        uint256 tokenIdRebate,
        uint256 numPurchases,
        uint256 saleId,
        address _currency,
        bool _optInBonuses,
        bool _optInCategories
    ) external payable;

    /**
     * @notice  Set Fee Wallets and fee percentages from sales
     * @param _walletAddresses The withdrawal EOA addresses
     * @param _feeBps Represented as basis points e.g. 500 == 5 pct
     */
    function setFeeWalletsAndPercentages(
        address[] calldata _walletAddresses,
        uint256[] calldata _feeBps
    ) external;

    /**
     * @notice Set a swap manager to manage the means through which tokens are exchanged
     * @param _swapManager SwapManager address
     */
    function setSwapManager(address _swapManager) external;

    /**
     * @notice Set a oracle manager to manage the means through which token prices are fetched
     * @param _oracleManager OracleManager address
     */
    function setOracleManager(address _oracleManager) external;

    /**
     * @notice Set administrator
     * @param _moderatorAddress The addresse of an allowed admin
     */
    function setModerator(address _moderatorAddress) external;

    /**
     * @notice adaptor to allow purchases via Paper.xyz
     * @dev Price is calculated implicitly from _saleId, _numPurchases
     */
    function onPaper(
        address buyer,
        address tokenAddressRebate,
        uint256 tokenIdRebate,
        uint256 numPurchases,
        uint256 saleId
    ) external;

    /**
     * @notice eligibility function to check if the player can purchase a pack based upon
     *          token ownership discounts and purchase quantity
     * @param _buyer the buyers' EOA address
     * @param _tokenAddressRebate The token address for the tokenId claimed to be owned (for rebates)
     * @param _tokenIdRebate The token id, ignored if ERC721 is provided for the token type
     * @param _numPurchases the number of packs to purchase
     * @param _saleId the sale ID of the pack to purchase
     */
    function tokenClaimable(
        address _buyer,
        address _tokenAddressRebate,
        uint256 _tokenIdRebate,
        uint256 _numPurchases,
        uint256 _saleId
    ) external view returns (string memory);

    /**
     * @notice Set the payment currency token for paper
     * @param _paperCurrency The address of the supported paper currency token
     */
    function setPaperCurrency(address _paperCurrency) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
* @title Interface defining a contract that should manage multiple exchange-oracles
*/
interface IOracleManager {
    /**
    * @notice Function used to exchange currencies
    * @param srcToken The currency to be exchanged
    * @param dstToken The currency to be exchanged for
    * @param amountIn The amount of currency to be exchanged
    * @return The resulting amount of dstToken
    */
    function getAmountOut(
        address srcToken,
        address dstToken,
        uint256 amountIn
    ) external returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
* @title Interface defining a swap manager, a contract that can exchange currencies
*/
interface ISwapManager {
    /**
    * @notice Swaps one currency for another
    * @param srcToken The address of the token to be exchanged
    * @param dstToken The address of the token to be exchanged for
    * @param amount the amount of src token to exchange
    * @param destination The recipient of the funds after the exchange
    */
    function swap(
        address srcToken,
        address dstToken,
        uint256 amount,
        address destination
    ) external payable;
}

pragma solidity ^0.8.0;


// @title Watered down version of IAssetManager, to be used for Gravity Grade
interface ITrustedMintable {

    error TM__NotTrusted(address _caller);
    /**
    * @notice Used to mint tokens by trusted contracts
     * @param _to Recipient of newly minted tokens
     * @param _tokenId Id of newly minted tokens. MUST be ignored on ERC-721
     * @param _amount Number of tokens to mint
     *
     * Throws TM_NotTrusted on caller not being trusted
     */
    function trustedMint(
        address _to,
        uint256 _tokenId,
        uint256 _amount
    ) external;

    /**
     * @notice Used to mint tokens by trusted contracts
     * @param _to Recipient of newly minted tokens
     * @param _tokenIds Ids of newly minted tokens MUST be ignored on ERC-721
     * @param _amounts Number of tokens to mint
     *
     * Throws TM_NotTrusted on caller not being trusted
     */
    function trustedBatchMint(
        address _to,
        uint256[] calldata _tokenIds,
        uint256[] calldata _amounts
    ) external;
}