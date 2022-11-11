/**
 *Submitted for verification at polygonscan.com on 2022-11-10
*/

// Sources flattened with hardhat v2.12.0 https://hardhat.org

// File @openzeppelin/contracts/utils/introspection/[email protected]


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


// File @openzeppelin/contracts/token/ERC721/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]

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


// File contracts/INFT.sol


pragma solidity ^0.8.0;
interface INFT is IERC721Metadata {
    function safeMint(
        address to,
        uint256 tokenId,
        string memory uri
    ) external;
}


// File contracts/NFTMarketplace.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
contract NFTMarketplace {
    address public owner;
    uint256 idForSale;
    uint256 idForSaleCount;

    struct ItemForSale {
        address contractAddress;
        address buyer;
        uint256 price;
        uint256 tokenId;
        string tokenURI;
        bool state;
    }

    mapping(uint256 => ItemForSale) public idToItemForSale;

    constructor() {
        owner = msg.sender;
    }

    function startNFTSale(
        address contractAddress,
        uint256 price,
        uint256 tokenId,
        string memory tokenURI
    ) public {
        require(msg.sender == owner, "You are not owner!");
        // TODO: Guncellenmeli!!
        // INFT NFT = INFT(contractAddress);
        // require(NFT.ownerOf(tokenId) == address(0), "Token exits!"); // Problem: reverts code if token is invalid.
        idToItemForSale[idForSale] = ItemForSale(
            contractAddress,
            msg.sender,
            price,
            tokenId,
            tokenURI,
            false
        );
        idForSale += 1;
        idForSaleCount += 1;
    }

    function getNftSalePrice(uint256 id) public view returns (uint256) {
        ItemForSale storage info = idToItemForSale[id];
        return info.price;
    }

    function updateNftSalePrice(uint256 id, uint256 new_price) public {
        require(owner == msg.sender);
        require(idToItemForSale[id].price != new_price);
        idToItemForSale[id].price = new_price;
    }

    function cancelNFTSale(uint256 id) public {
        require(owner == msg.sender, "You are not the owner of this NFT!");
        idToItemForSale[id] = ItemForSale(
            address(0),
            address(0),
            0,
            0,
            "",
            true
        );
        idForSaleCount -= 1;
    }

    function buyNFT(uint256 id) public payable {
        ItemForSale storage info = idToItemForSale[id];
        require(id < idForSale, "Wrong ID!");
        require(msg.sender != owner, "You are seller");
        require(msg.value == info.price, "Wrong Price!");
        require(info.state == false, "Cannot buy!");

        INFT NFT = INFT(info.contractAddress);
        require(NFT.ownerOf(info.tokenId) == address(0), "Token already sold!");
        NFT.safeMint(msg.sender, info.tokenId, info.tokenURI);
        uint256 price = (msg.value * 95) / 100;
        payable(owner).transfer(price);
        payable(owner).transfer(msg.value - price);
        info.buyer = msg.sender;
        info.state = true;
        idForSaleCount -= 1;
    }

    function getAllNFTOnSale() public view returns (ItemForSale[] memory) {
        ItemForSale[] memory ret = new ItemForSale[](idForSaleCount);
        uint256 count = 0;
        for (uint i = 0; i < idForSale; i++) {
            if (idToItemForSale[i].state == false) {
                ret[count] = idToItemForSale[i];
                count = count + 1;
            }
        }
        return ret;
    }
}