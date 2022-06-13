/**
 *Submitted for verification at polygonscan.com on 2022-06-12
*/

// File: @openzeppelin/[email protected]/token/ERC20/IERC20.sol


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

// File: @openzeppelin/[email protected]/utils/cryptography/MerkleProof.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// File: @openzeppelin/[email protected]/utils/Counters.sol


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

// File: @openzeppelin/[email protected]/utils/Strings.sol


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

// File: @openzeppelin/[email protected]/utils/Address.sol


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

// File: @openzeppelin/[email protected]/token/ERC721/IERC721Receiver.sol


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

// File: @openzeppelin/[email protected]/utils/introspection/IERC165.sol


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

// File: @openzeppelin/[email protected]/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/[email protected]/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/[email protected]/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/[email protected]/token/ERC721/extensions/IERC721Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/[email protected]/utils/Context.sol


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

// File: @openzeppelin/[email protected]/security/Pausable.sol


// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
}

// File: @openzeppelin/[email protected]/token/ERC721/ERC721.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;








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
     * by default, can be overridden in child contracts.
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
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
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

        _afterTokenTransfer(address(0), to, tokenId);
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

        _afterTokenTransfer(owner, address(0), tokenId);
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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
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

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// File: @openzeppelin/[email protected]/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: OwnerPausable.sol


pragma solidity ^0.8.0;



/// @title Owner Pausable
/// @notice Handles logic to pause contracts as the owner
/// @author Hamza Karabag
abstract contract OwnerPausable is Ownable, Pausable {
  function pause() external onlyOwner whenNotPaused {
    _pause();
  }

  function resume() external onlyOwner whenPaused {
    _unpause();
  }
}

// File: Marketplace.sol


pragma solidity ^0.8.10;





struct ERC721Listing {
  bool active;
  uint256 price;
}

struct ERC1155Listing {
  bool active;
  address owner;
  uint256 id;
  uint256 amount;
  uint256 price;
}

/// @title Marketplace
/// @notice List, buy, sell, lend and borrow game assets
/// @author Hamza Karabag
contract Marketplace is OwnerPausable {
  IERC20 public bgem;
  IERC20 public boom;
  IERC721 public hunters;
  IERC1155 public perks;
  IERC1155 public shards;
  IERC1155 public equipments;
  address private studio;

  // Base precision of 10**5 gives us 3 decimals to work with
  uint256 constant BASE_PRECISION = 100_000;

  // All initialized to 0
  uint256 perkCounter;
  uint256 shardCounter;
  uint256 equipmentCounter;
  uint256 studioBalance;
  uint256 studioCommission;
  uint256 boomCut;
  uint256 totalBoomCut;

  // Hunter ID => Listing
  mapping(uint256 => ERC721Listing) public hunterListings;

  // Listing Hash => Listing
  mapping(uint256 => ERC1155Listing) public perkListings;
  mapping(uint256 => ERC1155Listing) public shardListings;
  mapping(uint256 => ERC1155Listing) public equipmentListings;
  // ERC1155 Address => ListedAmount
  mapping(IERC1155 => mapping(address => uint256)) public erc1155ListingAmts;

  // For functions that only studio can call
  modifier onlyStudio() {
    require(msg.sender == studio, "Caller is not studio");
    _;
  }

  //	███████╗██╗   ██╗███████╗███╗   ██╗████████╗███████╗
  //	██╔════╝██║   ██║██╔════╝████╗  ██║╚══██╔══╝██╔════╝
  //	█████╗  ██║   ██║█████╗  ██╔██╗ ██║   ██║   ███████╗
  //	██╔══╝  ╚██╗ ██╔╝██╔══╝  ██║╚██╗██║   ██║   ╚════██║
  //	███████╗ ╚████╔╝ ███████╗██║ ╚████║   ██║   ███████║
  //	╚══════╝  ╚═══╝  ╚══════╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝

  event HunterListed(address lister, uint256 id, uint256 price);
  event HunterPriceChanged(uint256 id, uint256 newPrice);
  event HunterDelisted(uint256 id);
  event HunterBought(uint256 id, uint256 price);

  event PerkListed(uint256 listingHash, address user, uint256 id, uint256 amount, uint256 price);
  event PerkPriceChanged(uint256 listingHash, uint256 newPrice);
  event PerkDelisted(uint256 listingHash);
  event PerkBought(uint256 listingHash, uint256 price);

  event EquipmentListed(uint256 listingHash, address user, uint256 id, uint256 amount, uint256 price);
  event EquipmentPriceChanged(uint256 listingHash, uint256 newPrice);
  event EquipmentDelisted(uint256 listingHash);
  event EquipmentBought(uint256 listingHash, uint256 price);

  event ShardListed(uint256 listingHash, address user, uint256 id, uint256 amount, uint256 price);
  event ShardPriceChanged(uint256 listingHash, uint256 newPrice);
  event ShardDelisted(uint256 listingHash);
  event ShardBought(uint256 listingHash, uint256 price);

  //	 ██████╗███╗   ██╗███████╗████████╗ ██████╗ ██████╗
  //	██╔════╝████╗  ██║██╔════╝╚══██╔══╝██╔═══██╗██╔══██╗
  //	██║     ██╔██╗ ██║███████╗   ██║   ██║   ██║██████╔╝
  //	██║     ██║╚██╗██║╚════██║   ██║   ██║   ██║██╔══██╗
  //	╚██████╗██║ ╚████║███████║   ██║   ╚██████╔╝██║  ██║
  //	 ╚═════╝╚═╝  ╚═══╝╚══════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝

  constructor(
    address initStudio,
    IERC20 initBgem,
    IERC20 initBoom,
    IERC721 initHunters,
    IERC1155 initPerks,
    IERC1155 initShards,
    IERC1155 initEquipments,
    uint256 initCommission,
    uint256 initBoomCut
  ) {
    studio = initStudio;
    bgem = initBgem;
    boom = initBoom;
    hunters = initHunters;
    perks = initPerks;
    shards = initShards;
    equipments = initEquipments;
    studioCommission = initCommission;
    boomCut = initBoomCut;
  }

  //	███████╗███████╗████████╗████████╗███████╗██████╗ ███████╗
  //	██╔════╝██╔════╝╚══██╔══╝╚══██╔══╝██╔════╝██╔══██╗██╔════╝
  //	███████╗█████╗     ██║      ██║   █████╗  ██████╔╝███████╗
  //	╚════██║██╔══╝     ██║      ██║   ██╔══╝  ██╔══██╗╚════██║
  //	███████║███████╗   ██║      ██║   ███████╗██║  ██║███████║
  //	╚══════╝╚══════╝   ╚═╝      ╚═╝   ╚══════╝╚═╝  ╚═╝╚══════╝

  function setStudio(address newStudio) external onlyOwner {
    studio = newStudio;
  }

  function setBgemAddr(IERC20 newAddr) external onlyOwner {
    bgem = newAddr;
  }

  function setBoomAddr(IERC20 newAddr) external onlyOwner {
    boom = newAddr;
  }

  function setHuntersAddr(IERC721 newAddr) external onlyOwner {
    hunters = newAddr;
  }

  function setPerksAddr(IERC1155 newAddr) external onlyOwner {
    perks = newAddr;
  }

  function setShardsAddr(IERC1155 newAddr) external onlyOwner {
    shards = newAddr;
  }

  function setEquipmentsAddr(IERC1155 newAddr) external onlyOwner {
    equipments = newAddr;
  }

  function setCommission(uint256 newCommission) external onlyOwner {
    studioCommission = newCommission;
  }

  function setBoomCut(uint256 newBoomCut) external onlyOwner {
    boomCut = newBoomCut;
  }

  //	██╗     ██╗███████╗████████╗
  //	██║     ██║██╔════╝╚══██╔══╝
  //	██║     ██║███████╗   ██║
  //	██║     ██║╚════██║   ██║
  //	███████╗██║███████║   ██║
  //	╚══════╝╚═╝╚══════╝   ╚═╝

  /// @notice Lists a hunter
  /// @param hunterId ID of the hunter
  /// @param price    Price of the listing
  function listHunter(uint256 hunterId, uint256 price) external whenNotPaused {
    require(!hunterListings[hunterId].active, "Hunter is already on sale");
    require(hunters.ownerOf(hunterId) == msg.sender, "Not owner of the asset");

    hunterListings[hunterId] = ERC721Listing({active: true, price: price});

    emit HunterListed(msg.sender, hunterId, price);
  }

  /// @notice Lists a perk
  /// @param perkId ID of the perk
  /// @param amount Amount of perks
  /// @param price  Price of the listing
  function listPerk(
    uint256 perkId,
    uint256 amount,
    uint256 price
  ) external whenNotPaused {
    uint256 availableBalance = perks.balanceOf(msg.sender, perkId) -
      erc1155ListingAmts[perks][msg.sender];

    require(availableBalance >= amount, "Not enough of asset");

    // Since ERC1155 are fungible we can't store listing info the way we
    // store ERC721 hunters. We'll produce a listing hash using information
    // about the listing. Timestamp and the owner should be enough, but keep
    // in mind that if user were to create the same listing (id and amount) 
    // within the same timestamp would fail as it'd create the same hash.
    uint256 listingHash = uint256(
      keccak256(abi.encodePacked(perkId, amount, tx.origin, block.timestamp))
    );
    require(!perkListings[listingHash].active, "Already on sale");

    perkListings[listingHash] = ERC1155Listing({
      active: true,
      id: perkId,
      owner: msg.sender,
      amount: amount,
      price: price
    });
    erc1155ListingAmts[perks][msg.sender] += amount;

    emit PerkListed(listingHash, msg.sender, perkId, amount, price);
  }

  /// @notice Lists a equipment
  /// @param equipmentId ID of the equipment
  /// @param amount Amount of equipments
  /// @param price  Price of the listing
  function listEquipment(
    uint256 equipmentId,
    uint256 amount,
    uint256 price
  ) external whenNotPaused {
    uint256 availableBalance = equipments.balanceOf(msg.sender, equipmentId) -
      erc1155ListingAmts[equipments][msg.sender];
    require(availableBalance >= amount, "Not enough of asset");

    // see listPerk
    uint256 listingHash = uint256(
      keccak256(abi.encodePacked(equipmentId, amount, tx.origin, block.timestamp))
    );
    require(!equipmentListings[listingHash].active, "Already on sale");

    equipmentListings[listingHash] = ERC1155Listing({
      active: true,
      id: equipmentId,
      owner: msg.sender,
      amount: amount,
      price: price
    });
    erc1155ListingAmts[equipments][msg.sender] += amount;

    emit EquipmentListed(listingHash, msg.sender, equipmentId, amount, price);
  }

  /// @notice Lists a shard
  /// @param shardId ID of the shard
  /// @param amount Amount of shards
  /// @param price  Price of the listing
  function listShard(
    uint256 shardId,
    uint256 amount,
    uint256 price
  ) external whenNotPaused {
    uint256 availableBalance = shards.balanceOf(msg.sender, shardId) -
      erc1155ListingAmts[shards][msg.sender];
    require(availableBalance >= amount, "Not enough of asset");

    // see listPerk
    uint256 listingHash = uint256(
      keccak256(abi.encodePacked(shardId, amount, tx.origin, block.timestamp))
    );
    require(!shardListings[listingHash].active, "Already on sale");

    shardListings[listingHash] = ERC1155Listing({
      active: true,
      id: shardId,
      owner: msg.sender,
      amount: amount,
      price: price
    });
    erc1155ListingAmts[shards][msg.sender] += amount;

    emit ShardListed(listingHash, msg.sender, shardId, amount, price);
  }

  //	███████╗██████╗ ██╗████████╗
  //	██╔════╝██╔══██╗██║╚══██╔══╝
  //	█████╗  ██║  ██║██║   ██║
  //	██╔══╝  ██║  ██║██║   ██║
  //	███████╗██████╔╝██║   ██║
  //	╚══════╝╚═════╝ ╚═╝   ╚═╝

  /// @notice Edits price of a hunter listing
  /// @param hunterId ID of the hunter
  /// @param newPrice New price for the listing
  function editHunter(uint256 hunterId, uint256 newPrice) external whenNotPaused {
    require(hunterListings[hunterId].active, "Not on sale");
    require(hunters.ownerOf(hunterId) == msg.sender, "Not owner of the listing");

    // Change price
    hunterListings[hunterId].price = newPrice;
    emit HunterPriceChanged(hunterId, newPrice);
  }

  /// @notice Edits price of a perk listing
  /// @param listingHash  Hash of the listing
  /// @param newPrice     New price for the listing
  function editPerk(uint256 listingHash, uint256 newPrice) external whenNotPaused {
    ERC1155Listing memory listing = perkListings[listingHash];

    require(listing.active, "Not on sale");
    require(listing.owner == msg.sender, "Not owner of the listing");

    // Change price
    perkListings[listingHash].price = newPrice;
    emit PerkPriceChanged(listingHash, newPrice);
  }

  /// @notice Edits price of an equipment listing
  /// @param listingHash  Hash of the listing
  /// @param newPrice     New price for the listing
  function editEquipment(uint256 listingHash, uint256 newPrice) external whenNotPaused {
    ERC1155Listing memory listing = equipmentListings[listingHash];

    require(listing.active, "Not on sale");
    require(listing.owner == msg.sender, "Not owner of the listing");

    // Change price
    equipmentListings[listingHash].price = newPrice;
    emit EquipmentPriceChanged(listingHash, newPrice);
  }

  /// @notice Edits price of a shard listing
  /// @param listingHash  Hash of the listing
  /// @param newPrice     New price for the listing
  function editShard(uint256 listingHash, uint256 newPrice) external whenNotPaused {
    ERC1155Listing memory listing = shardListings[listingHash];

    require(listing.active, "Not on sale");
    require(listing.owner == msg.sender, "Not owner of the listing");

    // Change price
    shardListings[listingHash].price = newPrice;
    emit ShardPriceChanged(listingHash, newPrice);
  }

  //	██████╗ ███████╗██╗     ██╗███████╗████████╗
  //	██╔══██╗██╔════╝██║     ██║██╔════╝╚══██╔══╝
  //	██║  ██║█████╗  ██║     ██║███████╗   ██║
  //	██║  ██║██╔══╝  ██║     ██║╚════██║   ██║
  //	██████╔╝███████╗███████╗██║███████║   ██║
  //	╚═════╝ ╚══════╝╚══════╝╚═╝╚══════╝   ╚═╝

  /// @notice Delists a hunter listing
  /// @param hunterId ID of the hunter
  function delistHunter(uint256 hunterId) external {
    require(hunterListings[hunterId].active, "Not on sale");
    require(hunters.ownerOf(hunterId) == msg.sender, "Not owner of the listing");

    // Delete listing
    delete hunterListings[hunterId];
    emit HunterDelisted(hunterId);
  }

  /// @notice Delists a perk listing
  /// @param listingHash Hash of the perk listing
  function delistPerk(uint256 listingHash) external {
    ERC1155Listing memory listing = perkListings[listingHash];

    require(listing.active, "Not on sale");
    require(listing.owner == msg.sender, "Not owner of the listing");

    // Decrement listed amount
    erc1155ListingAmts[perks][msg.sender] -= listing.amount;

    // Delete listing
    delete perkListings[listingHash];
    emit PerkDelisted(listingHash);
  }

  /// @notice Delists a equipment listing
  /// @param listingHash Hash of the equipment listing
  function delistEquipment(uint256 listingHash) external {
    ERC1155Listing memory listing = equipmentListings[listingHash];

    require(listing.active, "Not on sale");
    require(listing.owner == msg.sender, "Not owner of the listing");

    // Decrement listed amount
    erc1155ListingAmts[equipments][msg.sender] -= listing.amount;

    // Delete listing
    delete equipmentListings[listingHash];
    emit EquipmentDelisted(listingHash);
  }

  /// @notice Delists a shard listing
  /// @param listingHash Hash of the shard listing
  function delistShard(uint256 listingHash) external {
    ERC1155Listing memory listing = shardListings[listingHash];

    require(listing.active, "Not on sale");
    require(listing.owner == msg.sender, "Not owner of the listing");

    // Decrement listed amount
    erc1155ListingAmts[shards][msg.sender] -= listing.amount;

    // Delete listing
    delete shardListings[listingHash];
    emit ShardDelisted(listingHash);
  }

  //	██████╗ ██╗   ██╗██╗   ██╗
  //	██╔══██╗██║   ██║╚██╗ ██╔╝
  //	██████╔╝██║   ██║ ╚████╔╝
  //	██╔══██╗██║   ██║  ╚██╔╝
  //	██████╔╝╚██████╔╝   ██║
  //	╚═════╝  ╚═════╝    ╚═╝

  /// @notice Buys a hunter listing
  /// @param hunterId         ID of the hunter
  /// @param expectedPrice    Price at the moment of purchase
  function buyHunter(uint256 hunterId, uint256 expectedPrice) external whenNotPaused {
    ERC721Listing memory listing = hunterListings[hunterId];
    address listingOwner = hunters.ownerOf(hunterId);

    require(listing.active, "Not on sale");
    require(msg.sender != listingOwner, "Owner of the listing");

    // This might be required as it would be possible to front-run buyHunter
    // and increase the price so if it was just "buy whatever the price is"
    // kind of function buyer could pay much more than the expected
    require(listing.price == expectedPrice, "Price mismatch");

    uint256 cut = (expectedPrice * boomCut) / BASE_PRECISION;
    totalBoomCut += cut;

    uint256 commission = (expectedPrice * studioCommission) / BASE_PRECISION;
    studioBalance += commission;

    require(
      boom.transferFrom(msg.sender, listingOwner, expectedPrice - commission - cut),
      "BOOM transfer failed"
    );
    hunters.safeTransferFrom(listingOwner, msg.sender, hunterId);

    // Delete listing
    delete hunterListings[hunterId];
    emit HunterBought(hunterId, expectedPrice);
  }

  /// @notice Buys a perk listing
  /// @param listingHash      Hash of the perk listing
  /// @param expectedPrice    Price at the moment of purchase
  function buyPerk(uint256 listingHash, uint256 expectedPrice) external whenNotPaused {
    ERC1155Listing memory listing = perkListings[listingHash];

    require(listing.active, "Not on sale");
    require(msg.sender != listing.owner, "Owner of the listing");

    // see buyHunter about this
    require(listing.price == expectedPrice, "Price mismatch");

    uint256 commission = (expectedPrice * studioCommission) / BASE_PRECISION;
    studioBalance += commission;

    require(
      boom.transferFrom(msg.sender, listing.owner, expectedPrice - commission),
      "BOOM transfer failed"
    );
    perks.safeTransferFrom(listing.owner, msg.sender, listing.id, listing.amount, "");

    // Decrement listed amount
    erc1155ListingAmts[perks][msg.sender] -= listing.amount;

    // Delete listing
    delete perkListings[listingHash];
    emit PerkBought(listingHash, expectedPrice);
  }

  /// @notice Buys a equipment listing
  /// @param listingHash      Hash of the equipment listing
  /// @param expectedPrice    Price at the moment of purchase
  function buyEquipment(uint256 listingHash, uint256 expectedPrice) external whenNotPaused {
    ERC1155Listing memory listing = equipmentListings[listingHash];

    require(listing.active, "Not on sale");
    require(msg.sender != listing.owner, "Owner of the listing");

    // see buyHunter about this
    require(listing.price == expectedPrice, "Price mismatch");

    uint256 commission = (expectedPrice * studioCommission) / BASE_PRECISION;
    studioBalance += commission;

    require(
      boom.transferFrom(msg.sender, listing.owner, expectedPrice - commission),
      "BOOM transfer failed"
    );
    equipments.safeTransferFrom(listing.owner, msg.sender, listing.id, listing.amount, "");

    // Decrement listed amount
    erc1155ListingAmts[equipments][msg.sender] -= listing.amount;

    // Delete listing
    delete equipmentListings[listingHash];
    emit EquipmentBought(listingHash, expectedPrice);
  }

  /// @notice Buys a shard listing
  /// @param listingHash      Hash of the shard listing
  /// @param expectedPrice    Price at the moment of purchase
  function buyShard(uint256 listingHash, uint256 expectedPrice) external whenNotPaused {
    ERC1155Listing memory listing = shardListings[listingHash];

    require(listing.active, "Not on sale");
    require(msg.sender != listing.owner, "Owner of the listing");

    // see buyHunter about this
    require(listing.price == expectedPrice, "Price mismatch");

    uint256 commission = (expectedPrice * studioCommission) / BASE_PRECISION;
    studioBalance += commission;

    require(
      boom.transferFrom(msg.sender, listing.owner, expectedPrice - commission),
      "BOOM transfer failed"
    );
    shards.safeTransferFrom(listing.owner, msg.sender, listing.id, listing.amount, "");

    // Decrement listed amount
    erc1155ListingAmts[shards][msg.sender] -= listing.amount;

    // Delete listing
    delete shardListings[listingHash];
    emit ShardBought(listingHash, expectedPrice);
  }

  function withdrawStudio() external onlyStudio {
    uint256 tmpBal = studioBalance;
    studioBalance = 0;
    boom.transfer(msg.sender, tmpBal);
  }

  /// @notice Allows studio to withdraw 
  function withdrawBoomCut() external onlyStudio {
    uint256 tmpCut = totalBoomCut;
    totalBoomCut = 0;
    boom.transfer(msg.sender, tmpCut);
  }
}

// File: Hunters.sol


pragma solidity ^0.8.10;








contract Hunters is ERC721, Ownable, Pausable {
  using Strings for uint256;
  using Counters for Counters.Counter;

  event HunterLocked(address account, uint256 id);
  event HunterUnlocked(address account, uint256 id);

  // ID -> Account
  mapping(uint256 => address) public lockedHunters;

  Counters.Counter private supply;
  mapping(address => uint256) hunterCounts;
  mapping(uint256 => uint256) boomPower;

  bytes32 constant merkleRoot = 0xa81682d80bb19f95b0f54b6763d7a4f3cbe9964f7d37527abde729429d34180b;

  string public uriPrefix = "https://api.nftroyale.com/h/";
  string public uriSuffix = "";

  uint256 constant cost = 0.1 ether;
  uint256 constant maxSupply = 10000;

  uint256 constant maxMintAmountPerTx = 10;
  uint256 constant maxMintAmountPerWallet = 10;

  bool public isWhitelistMintActive = false;
  bool public isPublicMintActive = false;

  constructor() ERC721("Hunters", "HNTR") {}

  modifier onlyOrigin() {
    require(msg.sender == tx.origin, "Contract calls are not allowed");
    _;
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
    require(supply.current() + _mintAmount <= maxSupply, "Max supply exceeded!");
    _;
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function publicSaleMintHunter(uint256 _mintAmount)
    external
    payable
    mintCompliance(_mintAmount)
    onlyOrigin
  {
    require(isPublicMintActive, "Public mint is not active!");
    require(msg.value >= cost * _mintAmount, "Insufficient funds!");
    require(
      hunterCounts[msg.sender] + _mintAmount <= maxMintAmountPerWallet,
      "Exceeds mint amount per wallet!"
    );

    hunterCounts[msg.sender] += _mintAmount;

    _mintLoop(msg.sender, _mintAmount);
  }

  function preSaleMintHunter(uint256 _mintAmount, bytes32[] calldata proof)
    external
    payable
    mintCompliance(_mintAmount)
    onlyOrigin
  {
    require(isWhitelistMintActive, "Whitelist mint is not active!");
    require(msg.value >= cost * _mintAmount, "Insufficient funds!");
    require(
      hunterCounts[msg.sender] + _mintAmount <= maxMintAmountPerWallet,
      "Exceeds mint amount per wallet!"
    );
    require(
      MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender))),
      "You are not whitelisted!"
    );

    hunterCounts[msg.sender] += _mintAmount;

    _mintLoop(msg.sender, _mintAmount);
  }

  function studioMint(uint256 _mintAmount) external onlyOwner {
    _mintLoop(msg.sender, _mintAmount);
  }

  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      supply.increment();
      _safeMint(_receiver, supply.current());
    }
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "Non-existent hunter token given!");

    string memory currentBaseURI = _baseURI();
    return
      bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

  function totalSupply() external view returns (uint256) {
    return supply.current();
  }

  function setUriPrefix(string memory _uriPrefix) external onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) external onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setIsWhitelistMintActive(bool _state) external onlyOwner {
    isWhitelistMintActive = _state;
  }

  function setIsPublicMintActive(bool _state) external onlyOwner {
    isPublicMintActive = _state;
  }

  function withdrawAll() external onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0);

    _withdraw(payable(0xC13109635A71D00A8701F1607105B3ca476dFE39), (balance * 100) / 100);

    _withdraw(owner(), address(this).balance);
  }

  function _withdraw(address _address, uint256 _amount) private {
    (bool success, ) = _address.call{value: _amount}("");
    require(success, "Transfer failed.");
  }

  //	██╗      ██████╗  ██████╗██╗  ██╗██╗███╗   ██╗ ██████╗
  //	██║     ██╔═══██╗██╔════╝██║ ██╔╝██║████╗  ██║██╔════╝
  //	██║     ██║   ██║██║     █████╔╝ ██║██╔██╗ ██║██║  ███╗
  //	██║     ██║   ██║██║     ██╔═██╗ ██║██║╚██╗██║██║   ██║
  //	███████╗╚██████╔╝╚██████╗██║  ██╗██║██║ ╚████║╚██████╔╝
  //	╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝

  /// @notice Locks a hunter
  /// @param account Address of owner
  /// @param id Hunter ID
  function lockHunter(address account, uint256 id) external onlyOwner {
    // Check if hunter is owned by user
    require(ownerOf(id) == account, "Account doesn't own hunter");

    lockedHunters[id] = account;
    emit HunterLocked(account, id);
  }

  /// @notice Unlocks a hunter
  /// @param account Address of owner
  /// @param id Hunter ID
  function unlockHunter(address account, uint256 id) external onlyOwner {
    // Check if hunter is owned by user
    require(ownerOf(id) == account, "Account doesn't own hunter");

    lockedHunters[id] = address(0x0);
    emit HunterUnlocked(account, id);
  }

  /// @notice Returns if a hunter is locked
  /// @param id Hunter ID
  function isHunterLocked(uint256 id) public view returns (bool) {
    return (lockedHunters[id] != address(0x0));
  }

  /// @notice Returns owner if not locked
  /// @dev If there's no owner returns zero address
  /// @param id Hunter ID
  /// @return Owner address / zero address
  function getHunterLocker(uint256 id) public view returns (address) {
    return lockedHunters[id];
  }

  /// @notice Increments Boom power of an account
  /// @param hunterId ID of the hunter
  /// @param incrementAmount Boom power
  function incrementBoomPower(uint256 hunterId, uint256 incrementAmount) external onlyOwner {
    boomPower[hunterId] += incrementAmount;
  }

  /// @notice Checks if hunter is locked before the transfer
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override whenNotPaused {
    require(!isHunterLocked(tokenId), "Hunter is locked");
    super._beforeTokenTransfer(from, to, tokenId);
  }
}