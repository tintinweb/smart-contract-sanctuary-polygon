// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import './ProductV1Types.sol';

interface IProductV1 {
    /* ADMIN */

    /// @notice Amends the variant base URI shared by all variants
    /// @dev Only callable by ADMIN_ROLE
    /// @param newVariantBaseURI The new token metadata URI
    function amendVariantBaseURI(string calldata newVariantBaseURI) external;

    /// @notice Freezes total supply for all variants
    /// @dev Sets available inventory to 0
    function freezeSupply() external;

    /// @notice Freezes total supply for a specific variant
    /// @dev Sets available inventory for the variant to 0
    /// @param variantId The variant identifier
    function freezeSupply(bytes32 variantId) external;

    /// @notice Sets the issue limit for each address
    /// @dev This limit does not apply retrospectively
    /// @dev Setting the limit to 0 means there is no limit
    /// @param newIssueLimit The new issue limit
    function setIssueLimit(uint256 newIssueLimit) external;

    /* OPERATOR */

    /// @notice Issues a new token with variant
    /// @param recipient The token recipient
    /// @param variantId The variant identifier
    /// @return uint256 The new token ID
    function issue(address recipient, bytes32 variantId) external returns (uint256);

    /// @notice Issues a new token with a random variant
    /// @param recipient The token recipient
    /// @param seed An external seed to provide randomness
    /// @return uint256 The new token ID
    function issueRandom(address recipient, uint256 seed) external returns (uint256);

    /* PUBLIC */

    /// @notice Return product inventory
    /// @return Inventory The product inventory across all variants
    function productInventory() external view returns (ProductV1Types.Inventory memory);

    /// @notice Get the variant id for a specfic token
    /// @param tokenId The token id
    /// @return bytes32 The variant id
    function tokenVariant(uint256 tokenId) external view returns (bytes32);

    /// @notice Get the number of product variants
    /// @return uint256 The number of variants
    function totalVariants() external view returns (uint256);

    /// @notice Get total issued tokens for a variant
    /// @param variantId The variant id
    /// @return uint256 The total supply for the provided variant
    function totalSupply(bytes32 variantId) external view returns (uint256);

    /// @notice Get the variant by index
    /// @dev Used for enumeration
    /// @param index The variant index
    function variantByIndex(uint256 index) external view returns (ProductV1Types.Variant memory);

    /// @notice Return variant inventory
    /// @param variantId The variant id to check for
    /// @return Inventory The inventory for the requested variant
    function variantInventory(bytes32 variantId) external view returns (ProductV1Types.Inventory memory);

    /// @notice Return the variant metadata URI
    /// @param variantId The variant id
    /// @return string The variant metadata URI
    function variantURI(bytes32 variantId) external view returns (string memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import './ProductV1Types.sol';

interface IProductV1Reader {
    function getProductsForOwner(address[] calldata products, address owner)
        external
        view
        returns (ProductV1Types.ProductTokens[] memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import 'openzeppelin-contracts/contracts/token/ERC721/IERC721.sol';
import 'openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Enumerable.sol';

import 'medallion/brevity/token/INFTHistoryV1.sol';
import './IProductV1.sol';
import './IProductV1Reader.sol';
import './ProductV1Types.sol';

contract ProductV1Reader is IProductV1Reader {
    function getProductsForOwner(address[] calldata products, address owner)
        public
        view
        returns (ProductV1Types.ProductTokens[] memory)
    {
        ProductV1Types.ProductTokens[] memory productsTokens = new ProductV1Types.ProductTokens[](products.length);
        for (uint256 i = 0; i < products.length; i++) {
            uint256 proofBalance = IERC721(products[i]).balanceOf(owner);
            ProductV1Types.Token[] memory tokens = new ProductV1Types.Token[](proofBalance);
            for (uint256 j = 0; j < proofBalance; j++) {
                uint256 tokenId = IERC721Enumerable(products[i]).tokenOfOwnerByIndex(owner, j);
                ProductV1Types.Token memory token = ProductV1Types.Token({
                    tokenId: tokenId,
                    issuedAt: INFTHistoryV1(products[i]).issuedAt(tokenId),
                    acquiredAt: INFTHistoryV1(products[i]).transferredAt(tokenId, -1),
                    variantId: IProductV1(products[i]).tokenVariant(tokenId)
                });
                tokens[j] = token;
            }
            ProductV1Types.ProductTokens memory proofToken = ProductV1Types.ProductTokens({
                product: products[i],
                tokens: tokens
            });
            productsTokens[i] = proofToken;
        }

        return productsTokens;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

library ProductV1Types {
    struct Inventory {
        uint256 availableInventory;
        uint256 totalSupply;
    }
    struct Variant {
        bytes32 id;
        uint256 initialInventory;
    }
    struct Token {
        uint256 tokenId;
        uint256 issuedAt;
        uint256 acquiredAt;
        bytes32 variantId;
    }

    struct ProductTokens {
        address product;
        Token[] tokens;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

interface INFTHistoryV1 {
    /// @notice Get the issuance (anon) history for a token
    /// @dev Reverts for non-existant tokens
    /// @param tokenId The tokenId
    /// @return uint256 When the token was issued
    function issuedAt(uint256 tokenId) external view returns (uint256);

    /// @notice Get the transfer (anon) history for a token
    /// @dev An index of -1 refers to the most recent transfer
    /// @dev Reverts for non-existant tokens
    /// @param tokenId The tokenId
    /// @param index The transfer index to return history for
    /// @return uint256 When the token was issued
    function transferredAt(uint256 tokenId, int256 index) external view returns (uint256);

    /// @notice Get the number of times a token has been transferred
    /// @dev Reverts for non-existant tokens
    /// @param tokenId The tokenId
    /// @return uint256
    function numTransfers(uint256 tokenId) external view returns (uint256);
}