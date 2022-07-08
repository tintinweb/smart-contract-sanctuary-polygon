// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "IERC721.sol";
import "IERC721Metadata.sol";
import "IERC721Enumerable.sol";
import "Address.sol";
import "Context.sol";
import "Strings.sol";
import "ERC165.sol";
import "IERC165.sol";

import {LibERC721} from "LibERC721.sol";
import {LibTokenURI} from "LibTokenURI.sol";

contract ERC721Facet is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    using Address for address;
    using Strings for uint256;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view    
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner)
        public
        view
        returns (uint256)
    {
        return LibERC721.balanceOf(owner);
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId)
        external
        view
        returns (address)
    {
        return LibERC721.ownerOf(tokenId);
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view returns (string memory) {
        return LibERC721.erc721Storage().name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view returns (string memory) {
        return LibERC721.erc721Storage().symbol;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     * @dev See https://docs.opensea.io/docs/contract-level-metadata
     */
    function contractURI() public view returns (string memory) {
        return LibERC721.erc721Storage().contractURI;
    }

    /**
     * @dev Reference URI for the NFT license file hosted on Arweave permaweb.
     */
    function license() public view returns (string memory) {
        return LibERC721.erc721Storage().licenseURI;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        return LibTokenURI.generateTokenURI(tokenId);
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public {
        address owner = LibERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || LibERC721.isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        LibERC721.approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId)
        external
        view
        returns (address)
    {
        return LibERC721.getApproved(tokenId);
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
    {
        LibERC721.setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool)
    {
        return LibERC721.isApprovedForAll(owner, operator);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public {
        require(
            LibERC721.isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        LibERC721.transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public {
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
    ) public {
        require(
            LibERC721.isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        LibERC721.safeTransfer(from, to, tokenId, _data);
    }

    /**
     * The following methods add support for IERC721Enumerable.
     */

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return LibERC721.erc721Storage().allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        returns (uint256)
    {
        require(
            index < balanceOf(owner),
            "ERC721Enumerable: owner index out of bounds"
        );
        return LibERC721.erc721Storage().ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index)
        public
        view
        returns (uint256)
    {
        require(
            index < totalSupply(),
            "ERC721Enumerable: global index out of bounds"
        );
        return LibERC721.erc721Storage().allTokens[index];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC165.sol";

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

pragma solidity ^0.8.0;

import "IERC721.sol";

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

pragma solidity ^0.8.0;

import "IERC721.sol";

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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "IERC165.sol";

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "IERC721Receiver.sol";
import "Address.sol";

import {LibShadowcornDNA} from "LibShadowcornDNA.sol";
import {LibEvents} from "LibEvents.sol";

library LibERC721 {
    using Address for address;

    bytes32 private constant ERC721_STORAGE_POSITION =
        keccak256("CryptoUnicorns.ERC721.storage");

    struct ERC721Storage {
        // Mapping from token ID to owner address
        mapping(uint256 => address) owners;
        // Mapping owner address to token count
        mapping(address => uint256) balances;
        // Mapping of owners to owned token IDs
        mapping(address => mapping(uint256 => uint256)) ownedTokens;
        // Mapping of tokens to their index in their owners ownedTokens array.
        mapping(uint256 => uint256) ownedTokensIndex;
        // Array with all token ids, used for enumeration
        uint256[] allTokens;
        // Mapping from token id to position in the allTokens array
        mapping(uint256 => uint256) allTokensIndex;
        // Mapping from token ID to approved address
        mapping(uint256 => address) tokenApprovals;
        // Mapping from owner to operator approvals
        mapping(address => mapping(address => bool)) operatorApprovals;
        string name;
        // Token symbol
        string symbol;
        // Token contractURI - permaweb location of the contract json file
        string contractURI;
        // Token licenseURI - permaweb location of the license.txt file
        string licenseURI;
        mapping(uint256 => string) tokenURIs;
        uint256 curentTokenId;
    }

    function erc721Storage() internal pure returns (ERC721Storage storage es) {
        bytes32 position = ERC721_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
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
    function safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal {
        transfer(from, to, tokenId);
        require(
            checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`mint`),
     * and stop existing when they are burned (`burn`).
     */
    function exists(uint256 tokenId) internal view returns (bool) {
        return erc721Storage().owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        require(
            exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
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
    function safeMint(address to, uint256 tokenId) internal {
        safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-safeMint-address-uint256-}[`safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal {
        mint(to, tokenId);
        require(
            checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!exists(tokenId), "ERC721: token already minted");

        beforeTokenTransfer(address(0), to, tokenId);
        ERC721Storage storage ds = erc721Storage();
        ds.balances[to] += 1;
        ds.owners[tokenId] = to;

        emit LibEvents.Transfer(address(0), to, tokenId);
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
    function burn(uint256 tokenId) internal {
        enforceUnicornIsTransferable(tokenId);
        address owner = ownerOf(tokenId);

        beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        approve(address(0), tokenId);
        ERC721Storage storage ds = erc721Storage();
        ds.balances[owner] -= 1;
        delete ds.owners[tokenId];

        if (bytes(ds.tokenURIs[tokenId]).length != 0) {
            delete ds.tokenURIs[tokenId];
        }

        emit LibEvents.Transfer(owner, address(0), tokenId);
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
    function transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        require(
            ownerOf(tokenId) == from,
            "ERC721: transfer of token that is not own"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        enforceUnicornIsTransferable(tokenId);

        beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        approve(address(0), tokenId);
        ERC721Storage storage ds = erc721Storage();
        ds.balances[from] -= 1;
        ds.balances[to] += 1;
        ds.owners[tokenId] = to;

        emit LibEvents.Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function approve(address to, uint256 tokenId) internal {
        ERC721Storage storage ds = erc721Storage();
        ds.tokenApprovals[tokenId] = to;
        emit LibEvents.Approval(ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal {
        require(owner != operator, "ERC721: approve to caller");
        ERC721Storage storage ds = erc721Storage();
        ds.operatorApprovals[owner][operator] = approved;
        emit LibEvents.ApprovalForAll(owner, operator, approved);
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
    function checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    msg.sender,
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
                } else {
                    // solhint-disable-next-line no-inline-assembly
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        if (from == address(0)) {
            addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function addTokenToOwnerEnumeration(address to, uint256 tokenId) internal {
        ERC721Storage storage ds = erc721Storage();
        uint256 length = balanceOf(to);
        ds.ownedTokens[to][length] = tokenId;
        ds.ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function removeTokenFromOwnerEnumeration(address from, uint256 tokenId)
        internal
    {
        ERC721Storage storage ds = erc721Storage();

        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).
        uint256 lastTokenIndex = balanceOf(from) - 1;
        uint256 tokenIndex = ds.ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = ds.ownedTokens[from][lastTokenIndex];

            ds.ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            ds.ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete ds.ownedTokensIndex[tokenId];
        delete ds.ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function addTokenToAllTokensEnumeration(uint256 tokenId) internal {
        ERC721Storage storage ds = erc721Storage();

        ds.allTokensIndex[tokenId] = ds.allTokens.length;
        ds.allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function removeTokenFromAllTokensEnumeration(uint256 tokenId) internal {
        ERC721Storage storage ds = erc721Storage();

        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ds.allTokens.length - 1;
        uint256 tokenIndex = ds.allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = ds.allTokens[lastTokenIndex];

        ds.allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        ds.allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete ds.allTokensIndex[tokenId];
        ds.allTokens.pop();
    }

    function ownerOf(uint256 tokenId) internal view returns(address) {
        address owner = erc721Storage().owners[tokenId];
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );
        return owner;
    }

    function getApproved(uint256 tokenId) internal view returns(address) {
        require(
            exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );

        return erc721Storage().tokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner, address operator) internal view returns(bool) {
        return erc721Storage().operatorApprovals[owner][operator];
    }

    function balanceOf(address owner) internal view returns(uint256) {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );
        return erc721Storage().balances[owner];
    }

    function enforceUnicornIsTransferable(uint256 tokenId) internal view {
        require(!LibShadowcornDNA.getLocked(LibShadowcornDNA.getDNA(tokenId)), "ERC721: Shadowcorn is locked.");
    }

    function enforceCallerOwnsNFT(uint256 tokenId) internal view {
        require(
            ownerOf(tokenId) == msg.sender,
            "ERC721: Caller must own NFT"
        );
    }

    function mintNextToken(address _to)
        internal
        returns (uint256 nextTokenId)
    {
        ERC721Storage storage ds = erc721Storage();
        nextTokenId = ds.curentTokenId + 1;
        mint(_to, nextTokenId);
        ds.curentTokenId = nextTokenId;
        return nextTokenId;
    }

}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {LibBin} from "LibBin.sol";
import {LibShadowcorn} from "LibShadowcorn.sol";
import {LibEvents} from "LibEvents.sol";

library LibShadowcornDNA {

    uint256 internal constant MAX =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    //  version is in bits 0-7 = 0b11111111
    uint internal constant DNA_VERSION_MASK = 0xFF;
    //  locked is in bit 8 = 0b100000000
    uint internal constant DNA_LOCKED_MASK = 0x100;
    //  limitedEdition is in bit 9 = 0b1000000000
    uint internal constant DNA_LIMITEDEDITION_MASK = 0x200;
    //  class is in bits 10-12 = 0b1110000000000
    uint internal constant DNA_CLASS_MASK = 0x1C00;
    //  rarity is in bits 13-14 = 0b110000000000000
    uint internal constant DNA_RARITY_MASK = 0x6000;
    //  tier is in bits 15-22 = 0b11111111000000000000000
    uint internal constant DNA_TIER_MASK = 0x7F8000;
    //  might is in bits 23-32 = 0b111111111100000000000000000000000
    uint internal constant DNA_MIGHT_MASK = 0x1FF800000;
    //  wickedness is in bits 33-42 = 0b1111111111000000000000000000000000000000000
    uint internal constant DNA_WICKEDNESS_MASK = 0x7FE00000000;
    //  tenacity is in bits 43-52 = 0b11111111110000000000000000000000000000000000000000000
    uint internal constant DNA_TENACITY_MASK = 0x1FF80000000000;
    //  cunning is in bits 53-62 = 0b111111111100000000000000000000000000000000000000000000000000000
    uint internal constant DNA_CUNNING_MASK = 0x7FE0000000000000;
    //  arcana is in bits 63-72 = 0b1111111111000000000000000000000000000000000000000000000000000000000000000
    uint internal constant DNA_ARCANA_MASK = 0x1FF8000000000000000;
    //  firstName is in bits 73-82 = 0b11111111110000000000000000000000000000000000000000000000000000000000000000000000000
    uint internal constant DNA_FIRSTNAME_MASK = 0x7FE000000000000000000;
    //  lastName is in bits 83-92 = 0b111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000
    uint internal constant DNA_LASTNAME_MASK = 0x1FF800000000000000000000;

    function getDNA(uint256 _tokenId) internal view returns (uint256) {
        return LibShadowcorn.shadowcornDNA(_tokenId);
    }

    function setDNA(uint256 _tokenId, uint256 _dna)
        internal
        returns (uint256)
    {
        require(_dna > 0, "LibShadowcornDNA: cannot set 0 DNA");
        LibShadowcorn.setShadowcornDNA(_tokenId, _dna);
        emit LibEvents.DNAUpdated(_tokenId, _dna);
        return _dna;
    }

    //  The currently supported DNA version - all DNA should be at this number,
    //  or lower if migrating...
    function targetDNAVersion() internal view returns (uint256) {
        return LibShadowcorn.targetDNAVersion();
    }

    function enforceDNAVersionMatch(uint256 _dna) internal view {
        require(
            getVersion(_dna) == targetDNAVersion(),
            "LibShadowcornDNA: Invalid DNA version"
        );
    }

    function setVersion(uint256 _dna, uint256 _val) internal pure returns(uint256) {
        return LibBin.splice(_dna, _val, DNA_VERSION_MASK);
    }

    function getVersion(uint256 _dna) internal pure returns(uint256) {
        return LibBin.extract(_dna, DNA_VERSION_MASK);
    }
    
    function setLocked(uint256 _dna, bool _val) internal pure returns(uint256) {
        return LibBin.splice(_dna, _val, DNA_LOCKED_MASK);
    }

    function getLocked(uint256 _dna) internal pure returns(bool) {
        return LibBin.extractBool(_dna, DNA_LOCKED_MASK);
    }
    
    function setLimitedEdition(uint256 _dna, bool _val) internal pure returns(uint256) {
        return LibBin.splice(_dna, _val, DNA_LIMITEDEDITION_MASK);
    }

    function getLimitedEdition(uint256 _dna) internal pure returns(bool) {
        return LibBin.extractBool(_dna, DNA_LIMITEDEDITION_MASK);
    }

    function setClass(uint256 _dna, uint256 _val) internal pure returns(uint256) {
        return LibBin.splice(_dna, _val, DNA_CLASS_MASK);
    }

    function getClass(uint256 _dna) internal pure returns(uint256) {
        return LibBin.extract(_dna, DNA_CLASS_MASK);
    }

    function setRarity(uint256 _dna, uint256 _val) internal pure returns(uint256) {
        return LibBin.splice(_dna, _val, DNA_RARITY_MASK);
    }

    function getRarity(uint256 _dna) internal pure returns(uint256) {
        return LibBin.extract(_dna, DNA_RARITY_MASK);
    }

    function setTier(uint256 _dna, uint256 _val) internal pure returns(uint256) {
        return LibBin.splice(_dna, _val, DNA_TIER_MASK);
    }

    function getTier(uint256 _dna) internal pure returns(uint256) {
        return LibBin.extract(_dna, DNA_TIER_MASK);
    }

    function setMight(uint256 _dna, uint256 _val) internal pure returns(uint256) {
        return LibBin.splice(_dna, _val, DNA_MIGHT_MASK);
    }

    function getMight(uint256 _dna) internal pure returns(uint256) {
        return LibBin.extract(_dna, DNA_MIGHT_MASK);
    }

    function setWickedness(uint256 _dna, uint256 _val) internal pure returns(uint256) {
        return LibBin.splice(_dna, _val, DNA_WICKEDNESS_MASK);
    }

    function getWickedness(uint256 _dna) internal pure returns(uint256) {
        return LibBin.extract(_dna, DNA_WICKEDNESS_MASK);
    }

    function setTenacity(uint256 _dna, uint256 _val) internal pure returns(uint256) {
        return LibBin.splice(_dna, _val, DNA_TENACITY_MASK);
    }

    function getTenacity(uint256 _dna) internal pure returns(uint256) {
        return LibBin.extract(_dna, DNA_TENACITY_MASK);
    }

    function setCunning(uint256 _dna, uint256 _val) internal pure returns(uint256) {
        return LibBin.splice(_dna, _val, DNA_CUNNING_MASK);
    }

    function getCunning(uint256 _dna) internal pure returns(uint256) {
        return LibBin.extract(_dna, DNA_CUNNING_MASK);
    }

    function setArcana(uint256 _dna, uint256 _val) internal pure returns(uint256) {
        return LibBin.splice(_dna, _val, DNA_ARCANA_MASK);
    }

    function getArcana(uint256 _dna) internal pure returns(uint256) {
        return LibBin.extract(_dna, DNA_ARCANA_MASK);
    }

    function setFirstName(uint256 _dna, uint256 _val) internal pure returns(uint256) {
        return LibBin.splice(_dna, _val, DNA_FIRSTNAME_MASK);
    }

    function getFirstName(uint256 _dna) internal pure returns(uint256) {
        return LibBin.extract(_dna, DNA_FIRSTNAME_MASK);
    }

    function setLastName(uint256 _dna, uint256 _val) internal pure returns(uint256) {
        return LibBin.splice(_dna, _val, DNA_LASTNAME_MASK);
    }

    function getLastName(uint256 _dna) internal pure returns(uint256) {
        return LibBin.extract(_dna, DNA_LASTNAME_MASK);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library LibBin {

    uint256 internal constant MAX =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    // Using the mask, determine how many bits we need to shift to extract the desired value
    //  @param _mask A bitstring with right-padding zeroes
    //  @return The number of right-padding zeroes on the _mask
    function getShiftAmount(uint256 _mask) internal pure returns (uint256) {
        uint256 count = 0;
        while (_mask & 0x1 == 0) {
            _mask >>= 1;
            ++count;
        }
        return count;
    }

    //  Insert _insertion data into the _bitArray bitstring
    //  @param _bitArray The base dna to manipulate
    //  @param _insertion Data to insert (no right-padding zeroes)
    //  @param _mask The location in the _bitArray where the insertion will take place
    //  @return The combined _bitArray bitstring
    function splice(
        uint256 _bitArray,
        uint256 _insertion,
        uint256 _mask
    ) internal pure returns (uint256) {
        uint256 offset = getShiftAmount(_mask);
        uint256 passthroughMask = MAX ^ _mask;
        //  remove old value,  shift new value to correct spot,  mask new value
        return (_bitArray & passthroughMask) | ((_insertion << offset) & _mask);
    }

    //  Alternate function signature for boolean insertion
    function splice(
        uint256 _bitArray,
        bool _insertion,
        uint256 _mask
    ) internal pure returns (uint256) {
        return splice(_bitArray, _insertion ? 1 : 0, _mask);
    }

    //  Retrieves a segment from the _bitArray bitstring
    //  @param _bitArray The dna to parse
    //  @param _mask The location in teh _bitArray to isolate
    //  @return The data from _bitArray that was isolated in the _mask (no right-padding zeroes)
    function extract(uint256 _bitArray, uint256 _mask)
        internal
        pure
        returns (uint256)
    {
        uint256 offset = getShiftAmount(_mask);
        return (_bitArray & _mask) >> offset;
    }

    //  Alternate function signature for boolean retrieval
    function extractBool(uint256 _bitArray, uint256 _mask)
        internal
        pure
        returns (bool)
    {
        return (_bitArray & _mask) != 0;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {LibDiamond} from "LibDiamond.sol";

library LibShadowcorn {
    bytes32 private constant SHADOWCORN_STORAGE_POSITION =
        keccak256("CryptoUnicorns.ShadowCorn.storage");

    struct ShadowcornStorage {
        address gameBank;
        address UNIMAddress;
        address RBWAddress;
        // DNA version
        uint256 targetDNAVersion;
        // mapping from shadowcorn tokenId to shadowcorn DNA
        mapping(uint256 => uint256) shadowcornDNA;
        //classId => rarityId => shadowcorn image URI
        mapping(uint256 => mapping(uint256 => string)) shadowcornImage;
        mapping(uint256 => uint256) shadowcornBirthnight;
        // Address of the terminus contract that holds the ERC1155 Shadowcorn Egg. 
        address terminusAddress;
        uint256 commonEggPoolId;
        uint256 rareEggPoolId;
        uint256 mythicEggPoolId;
    }

    function shadowcornStorage() internal pure returns (ShadowcornStorage storage scs) {
        bytes32 position = SHADOWCORN_STORAGE_POSITION;
        assembly {
            scs.slot := position
        }
    }

    function enforceIsContractOwner() internal view {
        LibDiamond.enforceIsContractOwner();
    }

    function setGameBank(address newGameBank) internal {
        // We enforce contract ownership directly here because this functionality needs to be highly
        // protected.
        enforceIsContractOwner();
        shadowcornStorage().gameBank = newGameBank;
    }

    function gameBank() internal view returns (address) {
        return shadowcornStorage().gameBank;
    }

    function setUNIMAddress(address newUNIMAddress) internal {
        // We enforce contract ownership directly here because this functionality needs to be highly
        // protected.
        enforceIsContractOwner();
        shadowcornStorage().UNIMAddress = newUNIMAddress;
    }

    function unimAddress() internal view returns (address) {
        return shadowcornStorage().UNIMAddress;
    }

    function setRBWAddress(address newRBWAddress) internal {
        // We enforce contract ownership directly here because this functionality needs to be highly
        // protected.
        enforceIsContractOwner();
        shadowcornStorage().RBWAddress = newRBWAddress;
    }

    function rbwAddress() internal view returns (address) {
        return shadowcornStorage().RBWAddress;
    }

    function setTargetDNAVersion(uint256 newTargetDNAVersion) internal {
        // We enforce contract ownership directly here because this functionality needs to be highly
        // protected.
        enforceIsContractOwner();
        ShadowcornStorage storage scs = shadowcornStorage();
        require(newTargetDNAVersion > scs.targetDNAVersion, "LibShadowcorn: new version must be greater than current");
        require(newTargetDNAVersion < 256, "LibShadowcorn: version cannot be greater than 8 bits");
        scs.targetDNAVersion = newTargetDNAVersion;
    }

    function targetDNAVersion() internal view returns (uint256) {
        return shadowcornStorage().targetDNAVersion;
    }

    function setShadowcornDNA(uint256 tokenId, uint256 newDNA) internal {
        ShadowcornStorage storage scs = shadowcornStorage();
        scs.shadowcornDNA[tokenId] = newDNA;
    }

    function shadowcornDNA(uint256 tokenId) internal view returns (uint256) {
        return shadowcornStorage().shadowcornDNA[tokenId];
    }

    function setShadowcornImage(string[15] memory newShadowcornImage) internal {
        ShadowcornStorage storage scs = shadowcornStorage();

        scs.shadowcornImage[1][1] = newShadowcornImage[0];
        scs.shadowcornImage[2][1] = newShadowcornImage[1];
        scs.shadowcornImage[3][1] = newShadowcornImage[2];
        scs.shadowcornImage[4][1] = newShadowcornImage[3];
        scs.shadowcornImage[5][1] = newShadowcornImage[4];
        
        scs.shadowcornImage[1][2] = newShadowcornImage[5];
        scs.shadowcornImage[2][2] = newShadowcornImage[6];
        scs.shadowcornImage[3][2] = newShadowcornImage[7];
        scs.shadowcornImage[4][2] = newShadowcornImage[8];
        scs.shadowcornImage[5][2] = newShadowcornImage[9];
        
        scs.shadowcornImage[1][3] = newShadowcornImage[10];
        scs.shadowcornImage[2][3] = newShadowcornImage[11];
        scs.shadowcornImage[3][3] = newShadowcornImage[12];
        scs.shadowcornImage[4][3] = newShadowcornImage[13];
        scs.shadowcornImage[5][3] = newShadowcornImage[14];
    }

    function shadowcornImage(uint256 classId, uint256 rarityId) internal view returns(string memory) {
        return shadowcornStorage().shadowcornImage[classId][rarityId];
    }

    function setTerminusAddress(address newTerminusAddress) internal {
        enforceIsContractOwner();
        shadowcornStorage().terminusAddress = newTerminusAddress;
    }

    function terminusAddress() internal view returns(address){
        return shadowcornStorage().terminusAddress;
    }

    function setCommonEggPoolId(uint256 newCommonEggPoolId) internal {
        enforceIsContractOwner();
        shadowcornStorage().commonEggPoolId = newCommonEggPoolId;
    }

    function commonEggPoolId() internal view returns(uint256){
        return shadowcornStorage().commonEggPoolId;
    }

    function setRareEggPoolId(uint256 newRareEggPoolId) internal {
        enforceIsContractOwner();
        shadowcornStorage().rareEggPoolId = newRareEggPoolId;
    }

    function rareEggPoolId() internal view returns(uint256){
        return shadowcornStorage().rareEggPoolId;
    }

    function setMythicEggPoolId(uint256 newMythicEggPoolId) internal {
        enforceIsContractOwner();
        shadowcornStorage().mythicEggPoolId = newMythicEggPoolId;
    }

    function mythicEggPoolId() internal view returns(uint256){
        return shadowcornStorage().mythicEggPoolId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Adapted from the Diamond 3 reference implementation by Nick Mudge:
// https://github.com/mudgen/diamond-3-hardhat

import { IDiamondCut } from "IDiamondCut.sol";

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
        enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
        ds.facetAddresses.push(_facetAddress);
    }


    function addFunction(DiamondStorage storage ds, bytes4 _selector, uint96 _selectorPosition, address _facetAddress) internal {
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(DiamondStorage storage ds, address _facetAddress, bytes4 _selector) internal {
        require(_facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), "LibDiamondCut: Can't remove immutable function");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Adapted from the Diamond 3 reference implementation by Nick Mudge:
// https://github.com/mudgen/diamond-3-hardhat

interface IDiamondCut {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library LibEvents {
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

    event DNAUpdated(uint256 tokenId, uint256 dna);

    event HatchingShadowcornRNGRequested(uint256 indexed tokenId, address indexed playerWallet, uint256 indexed blockDeadline);
    event HatchingShadowcornCompleted(uint256 indexed tokenId, address indexed playerWallet);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {LibShadowcornDNA} from "LibShadowcornDNA.sol";
import {LibNames} from "LibNames.sol";
import {LibShadowcorn} from "LibShadowcorn.sol";
import {Base64} from "Base64.sol";


library LibTokenURI {

    // string constant METADATA_VERSION = "1";  //  inline

    struct JSONShadowcornData {
        string fullName;
        string image;
        string locked;
        string class;
        string rarity;
        string birthnight;
        string tier;
        string might;
        string wickedness;
        string tenacity;
        string cunning;
        string arcana;
    }

    function getJSONReadyShadowcornData(uint256 tokenId) internal view returns(JSONShadowcornData memory) {
        uint256 dna = LibShadowcornDNA.getDNA(tokenId);
        uint256 classId = LibShadowcornDNA.getClass(dna);
        uint256 rarityId = LibShadowcornDNA.getRarity(dna);
        return JSONShadowcornData(
            LibNames.getFullName(tokenId),
            LibShadowcorn.shadowcornStorage().shadowcornImage[classId][rarityId],
            LibShadowcornDNA.getLocked(dna) ? "Locked" : "Unlocked",
            getClassNameFromId(classId),
            getRarityNameFromId(rarityId),
            uintToString(LibShadowcorn.shadowcornStorage().shadowcornBirthnight[tokenId]),
            uintToString(LibShadowcornDNA.getTier(dna)),
            uintToString(LibShadowcornDNA.getMight(dna) * 10),
            uintToString(LibShadowcornDNA.getWickedness(dna) * 10), 
            uintToString(LibShadowcornDNA.getTenacity(dna) * 10),
            uintToString(LibShadowcornDNA.getCunning(dna) * 10),
            uintToString(LibShadowcornDNA.getArcana(dna) * 10)
        );
    }

    function generateTokenURI(uint256 tokenId) internal view returns(string memory) {
        JSONShadowcornData memory shadowcornData = getJSONReadyShadowcornData(tokenId);
        bytes memory json = abi.encodePacked(
            '{"token_id":"', uintToString(tokenId),
            '","name":"', shadowcornData.fullName,
            '","external_url":"https://www.cryptounicorns.fun","image":"', shadowcornData.image,
            '","metadata_version":1,"attributes":[{"trait_type":"Game Lock","value":"', shadowcornData.locked,
            '"},{"trait_type":"Class","value":"', shadowcornData.class,
            '"},{"trait_type":"Rarity","value":"', shadowcornData.rarity,
            '"},{"trait_type":"Birthnight","display_type":"date","value":', shadowcornData.birthnight
        );
        
        json = abi.encodePacked(
            json,
            '},{"trait_type":"Tier","display_type":"number","value":', shadowcornData.tier,
            '},{"trait_type":"Might","display_type":"number","value":', shadowcornData.might,
            '},{"trait_type":"Wickedness","display_type":"number","value":', shadowcornData.wickedness,
            '},{"trait_type":"Tenacity","display_type":"number","value":', shadowcornData.tenacity,
            '},{"trait_type":"Cunning","display_type":"number","value":', shadowcornData.cunning,
            '},{"trait_type":"Arcana","display_type":"number","value":', shadowcornData.arcana,
            '}]}'
        );
        
        return string ( 
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(json)
        ));
    }

    function getClassNameFromId(uint256 classId) internal pure returns(string memory){
        if(classId == 1) {
            return "Fire";
        }
        if(classId == 2) {
            return "Slime";
        }
        if(classId == 3) {
            return "Volt";
        }
        if(classId == 4) {
            return "Soul";
        }
        if(classId == 5) {
            return "Nebula";
        }
        return "None";
    }

    function getRarityNameFromId(uint256 rarityId) internal pure returns(string memory){
        if(rarityId == 1) {
            return "Common";
        }
        if(rarityId == 2) {
            return "Rare";
        }
        if(rarityId == 3) {
            return "Mythic";
        }
        return "None";
    }
    
    // function boolToString(bool _b) internal pure returns (string memory _boolAsString) { 
    //     return (_b) ? "true" : "false";
    // }

    function uintToString(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {LibShadowcornDNA} from "LibShadowcornDNA.sol";


library LibNames {
    bytes32 private constant NAMES_STORAGE_POSITION =
        keccak256("CryptoUnicorns.Names.storage");

    struct NamesStorage {
         // nameIndex -> name string
        mapping(uint256 => string) firstNamesList;
        mapping(uint256 => string) lastNamesList;

        // Names which can be chosen by RNG for new lands (unordered)
        uint256[] validFirstNames;
        uint256[] validLastNames;
    }

    function namesStorage() internal pure returns (NamesStorage storage ns) {
        bytes32 position = NAMES_STORAGE_POSITION;
        assembly {
            ns.slot := position
        }
    }

    function resetFirstNamesList() internal {
        NamesStorage storage ns = namesStorage();
        delete ns.validFirstNames;
        for(uint16 i = 0; i < 1024; ++i){
            delete ns.firstNamesList[i];
        }
    }

    function resetLastNamesList() internal {
        NamesStorage storage ns = namesStorage();
        delete ns.validLastNames;
        for(uint16 i = 0; i < 1024; ++i){
            delete ns.lastNamesList[i];
        }
    }

    //  New names are automatically added as valid options for the RNG
    function registerFirstNames(uint256[] memory _ids, string[] memory _names) internal {
        require(_names.length == _ids.length, "NameLoader: Mismatched id and name array lengths");
        NamesStorage storage ns = namesStorage();
        uint256 len = _ids.length;
        for(uint256 i = 0; i < len; ++i) {
            ns.firstNamesList[_ids[i]] = _names[i];
            ns.validFirstNames.push(_ids[i]);
        }
    }

    //  New names are automatically added as valid options for the RNG
    function registerLastNames(uint256[] memory _ids, string[] memory _names) internal {
        require(_names.length == _ids.length, "NameLoader: Mismatched id and name array lengths");
        NamesStorage storage ns = namesStorage();
        uint256 len = _ids.length;
        for(uint256 i = 0; i < len; ++i) {
            ns.lastNamesList[_ids[i]] = _names[i];
            ns.validLastNames.push(_ids[i]);
        }
    }

    //  If _delete is TRUE, the name will no longer be retrievable, and
    //  any legacy DNA using that name will point to (undefined -> "").
    //  If FALSE, the name will continue to work for existing DNA,
    //  but the RNG will not assign the name to any new tokens.
    function retireFirstName(uint256 _id, bool _delete) internal returns (bool) {
        NamesStorage storage ns = namesStorage();
        uint256 len = ns.validFirstNames.length;
        if(len == 0) return true;
        for(uint256 i = 0; i < len; ++i) {
            if(ns.validFirstNames[i] == _id) {
                ns.validFirstNames[i] = ns.validFirstNames[len - 1];
                ns.validFirstNames.pop();
                if(_delete) {
                    delete ns.firstNamesList[_id];
                }
                return true;
            }
        }
        return false;
    }

    //  If _delete is TRUE, the name will no longer be retrievable, and
    //  any legacy DNA using that name will point to (undefined -> "").
    //  If FALSE, the name will continue to work for existing DNA,
    //  but the RNG will not assign the name to any new tokens.
    function retireLastName(uint256 _id, bool _delete) internal returns (bool) {
        NamesStorage storage ns = namesStorage();
        uint256 len = ns.validLastNames.length;
        if(len == 0) return true;
        for(uint256 i = 0; i < len; ++i) {
            if(ns.validLastNames[i] == _id) {
                ns.validLastNames[i] = ns.validLastNames[len - 1];
                ns.validLastNames.pop();
                if(_delete) {
                    delete ns.lastNamesList[_id];
                }
                return true;
            }
        }
        return false;
    }

    function lookupFirstName(uint256 _nameId) internal view returns (string memory) {
        return namesStorage().firstNamesList[_nameId];
    }

    function lookupLastName(uint256 _nameId) internal view returns (string memory) {
        return namesStorage().lastNamesList[_nameId];
    }

    function getFullName(uint256 _tokenId) internal view returns (string memory) {
        return getFullNameFromDNA(LibShadowcornDNA.getDNA(_tokenId));
    }

    function getFullNameFromDNA(uint256 _dna) internal view returns (string memory) {
        LibShadowcornDNA.enforceDNAVersionMatch(_dna);
        NamesStorage storage ns = namesStorage();
        return string(
            abi.encodePacked(
                ns.firstNamesList[LibShadowcornDNA.getFirstName(_dna)], ' ',
                ns.lastNamesList[LibShadowcornDNA.getLastName(_dna)]
            )
        );
    }

    function getRandomFirstName(uint256 randomnessFirstName) internal view returns (uint256) {
        NamesStorage storage ns = namesStorage();
        require(ns.validFirstNames.length > 0, "Names: First-name list is empty");
        return ns.validFirstNames[(randomnessFirstName % ns.validFirstNames.length)];
    }

    function getRandomLastName(uint256 randomnessLastName) internal view returns (uint256) {
        NamesStorage storage ns = namesStorage();
        require(ns.validLastNames.length > 0, "Names: Last-name list is empty");
        return ns.validLastNames[(randomnessLastName % ns.validLastNames.length)];
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