// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

// @openzeppelin 4.4.1
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "./interfaces/IChibiUtilities.sol";

contract ChibiUtilities is IChibiUtilities {
    /** --------------------EXTERNAL FUNCTIONS-------------------- */
    /*
     * see {IChibiUtilities-totalSupply}
     */
    function totalSupply(IERC721Enumerable erc721Contract)
        external
        view
        override
        returns (uint256)
    {
        return erc721Contract.totalSupply();
    }

    /*
     * see {IChibiUtilities-totalSupply}
     */
    function balanceOf(address owner, IERC721Enumerable erc721Contract)
        external
        view
        override
        returns (uint256)
    {
        return erc721Contract.balanceOf(owner);
    }

    /*
     * see {IChibiUtilities-ownerOf}
     */
    function ownerOf(uint256 tokenId, IERC721Enumerable erc721Contract)
        external
        view
        override
        returns (address)
    {
        return erc721Contract.ownerOf(tokenId);
    }

    /*
     * see {IChibiUtilities-getTokenIdsOfOwner}
     */
    function getTokenIdsOfOwner(
        address owner,
        IERC721Enumerable erc721Contract,
        uint256 startIndex,
        uint256 numberOfTokens
    ) external view override returns (uint256[] memory tokenIds) {
        uint256 tokenCount = Math.min(
            erc721Contract.balanceOf(owner) - startIndex,
            numberOfTokens
        );
        tokenIds = new uint256[](tokenCount);
        for (uint256 i = startIndex; i < startIndex + tokenCount; i++) {
            tokenIds[i - startIndex] = erc721Contract.tokenOfOwnerByIndex(
                owner,
                i
            );
        }
    }

    /*
     * see {IChibiUtilities-getTokenIds}
     */
    function getTokenIds(
        IERC721Enumerable erc721Contract,
        uint256 startIndex,
        uint256 numberOfTokens
    ) external view override returns (uint256[] memory tokenIds) {
        uint256 tokenCount = Math.min(
            erc721Contract.totalSupply() - startIndex,
            numberOfTokens
        );
        tokenIds = new uint256[](tokenCount);
        for (uint256 i = startIndex; i < startIndex + tokenCount; i++) {
            tokenIds[i - startIndex] = erc721Contract.tokenByIndex(i);
        }
    }
    /** --------------------EXTERNAL FUNCTIONS-------------------- */
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.2;

// @openzeppelin 4.4.1
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

/**
 * Chibi Utilities
 */
interface IChibiUtilities {
    /*
     * get total supply
     */
    function totalSupply(IERC721Enumerable erc721Contract)
        external
        view
        returns (uint256);

    /*
     * get balance
     */
    function balanceOf(address owner, IERC721Enumerable erc721Contract)
        external
        view
        returns (uint256);

    /*
     * get owner of a token
     */
    function ownerOf(uint256 tokenId, IERC721Enumerable erc721Contract)
        external
        view
        returns (address);

    /*
     * get token ids by owner by idnex
     */
    function getTokenIdsOfOwner(
        address owner,
        IERC721Enumerable erc721Contract,
        uint256 startIndex,
        uint256 numberOfTokens
    ) external view returns (uint256[] memory tokenIds);

    /*
     * get token ids by idnex
     */
    function getTokenIds(
        IERC721Enumerable erc721Contract,
        uint256 startIndex,
        uint256 numberOfTokens
    ) external view returns (uint256[] memory tokenIds);
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