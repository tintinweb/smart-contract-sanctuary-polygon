// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function setApprovalForAll(address operator, bool approved) external;

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
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NFTListing {
    struct Listing {
        address owner;
        address buyer;
        address nftContract;
        uint256 tokenId;
        uint256 price;
        bool active;
        string tokenURI; // New field to store the token URI
        uint256 stakingEndTime; // New field to store the staking end time
    }

    mapping(uint256 => Listing) public listings;
    mapping(uint256 => string) public tokenURIs; // Mapping to store token URIs
    mapping(uint256 => uint256) public stakedNFTs; // Mapping to store staked NFTs

    uint256 public nextListingId;
    address payable public owner;
    uint256 public TimePeriod = 1 days; // Staking time set to one day

    event NFTListed(
        uint256 indexed listingId,
        address indexed owner,
        address indexed nftContract,
        uint256 tokenId,
        uint256 price,
        string tokenURI
    );

    event NFTUnlisted(uint256 indexed listingId);
    event NFTSold(uint256 indexed listingId, address indexed buyer);
    event NFTStaked(uint256 indexed tokenId, address indexed staker); // New event for NFT staking
    event NFTUnstaked(uint256 indexed tokenId, address indexed staker); // New event for NFT unstaking
    event Received(address indexed sender, uint256 amount);
    event EtherWithdrawn(address indexed recipient, uint256 amount);

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only owner of the marketplace can change the period"
        );
        _;
    }

    constructor() {
        owner = payable(msg.sender);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid new owner address");
        owner = payable(newOwner);
    }

    function listingNFT(
        address nftContract,
        uint256[] memory tokenIds,
        uint256[] memory prices,
        string[] memory tokenURis // Updated function parameter
    ) external {
        IERC721 nft = IERC721(nftContract);
        require(
            tokenIds.length == prices.length &&
                tokenIds.length == tokenURis.length, // Check array lengths
            "TokenIds, prices, and tokenURIs array length mismatch"
        );

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            uint256 price = prices[i];
            string memory uri = tokenURis[i];

            require(
                nft.ownerOf(tokenId) == msg.sender,
                "You must own the NFT to list it"
            );
            nft.transferFrom(msg.sender, address(this), tokenId);

            listings[nextListingId] = Listing({
                owner: msg.sender,
                buyer: address(0),
                nftContract: nftContract,
                tokenId: tokenId,
                price: price,
                active: true,
                tokenURI: uri, // Store the token URI
                stakingEndTime: 0 // Set staking end time
            });

            tokenURIs[tokenId] = uri; // Store token URI in mapping

            emit NFTListed(
                nextListingId,
                msg.sender,
                nftContract,
                tokenId,
                price,
                uri // Emit the token URI in the event
            );
            nextListingId++;
        }
    }

    function unlistNFT(uint256[] memory listingIds) external {
        for (uint256 i = 0; i < listingIds.length; i++) {
            uint256 listingId = listingIds[i];
            Listing storage listing = listings[listingId];
            require(listing.active, "Listing does not exist");
            require(
                listing.owner == msg.sender,
                "You are not the owner of the listing"
            );

            IERC721 nft = IERC721(listing.nftContract);
            nft.transferFrom(address(this), msg.sender, listing.tokenId);

            listing.active = false;

            emit NFTUnlisted(listingId);
        }
    }

    function buy(uint256[] memory listingIds) external payable {
        for (uint256 i = 0; i < listingIds.length; i++) {
            uint256 listingId = listingIds[i];
            Listing storage listing = listings[listingId];
            require(listing.active, "Listing does not exist");
            require(msg.value == listing.price, "Incorrect payment amount");

            address payable seller = payable(listing.owner);
            seller.transfer(msg.value);

            IERC721 nft = IERC721(listing.nftContract);
            nft.transferFrom(address(this), msg.sender, listing.tokenId);

            // Update the mapping
            listing.active = false;
            listing.buyer = msg.sender;

            emit NFTSold(listingId, msg.sender);
        }
    }

    function stakedNFT(
        address nftContract,
        uint256[] memory tokenIds
    ) external {
        IERC721 nft = IERC721(nftContract);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            Listing storage listing = listings[tokenId];
            require(listing.active == false, "NFT listing does not exist");
            require(stakedNFTs[tokenId] == 0, "NFT is already staked");
            require(
                nft.ownerOf(tokenId) == msg.sender,
                "You must own the NFT to stake it"
            );
            nft.transferFrom(msg.sender, address(this), tokenId);

            stakedNFTs[tokenId] = block.timestamp + TimePeriod;
            listing.stakingEndTime = stakedNFTs[tokenId];

            listing.active = true;

            emit NFTStaked(tokenId, msg.sender);
        }
    }

    function claimStakeNFT(uint256[] memory tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            Listing storage listing = listings[tokenId];
            require(listing.active == true, "NFT is not staked");
            require(stakedNFTs[tokenId] > 0, "The NFT is not staked");
            require(
                stakedNFTs[tokenId] <= block.timestamp,
                "The unlock period has not ended yet"
            );

            require(
                listing.stakingEndTime <= block.timestamp,
                "The unlock period has not ended yet"
            );

            stakedNFTs[tokenId] = 0;

            IERC721 nft = IERC721(listing.nftContract);
            nft.transferFrom(address(this), msg.sender, tokenId);

            listing.active = false;

            emit NFTUnstaked(tokenId, msg.sender);
        }
    }

    function getListedNFT() external view returns (Listing[] memory) {
        Listing[] memory userListedItems = new Listing[](nextListingId);
        uint256 count = 0;
        for (uint256 i = 0; i < nextListingId; i++) {
            if (listings[i].owner == msg.sender && listings[i].active) {
                userListedItems[count] = listings[i];
                count++;
            }
        }
        assembly {
            mstore(userListedItems, count)
        }
        return userListedItems;
    }

    function setTimePeriod(uint256 time) external onlyOwner {
        require(time > 0, "Invalid time period");
        TimePeriod = time;
    }

    function ownerOf(
        address nftContract,
        uint256 tokenId
    ) public view returns (address) {
        IERC721 nft = IERC721(nftContract);
        return nft.ownerOf(tokenId);
    }

    function getOwnedTokenIds(
        address wallet
    ) external view returns (uint256[] memory) {
        uint256[] memory tokenIds = new uint256[](nextListingId);
        uint256 count = 0;
        for (uint256 i = 0; i < nextListingId; i++) {
            Listing storage listing = listings[i];
            if (listing.owner == wallet) {
                tokenIds[count] = listing.tokenId;
                count++;
            }
        }
        assembly {
            mstore(tokenIds, count)
        }
        return tokenIds;
    }

    function withdrawEther(uint256 amount) external onlyOwner {
        require(
            amount <= address(this).balance,
            "Insufficient contract balance"
        );

        owner.transfer(amount);

        emit EtherWithdrawn(owner, amount);
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}