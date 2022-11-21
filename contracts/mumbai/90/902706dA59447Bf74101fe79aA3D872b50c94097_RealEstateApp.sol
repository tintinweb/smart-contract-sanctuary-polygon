/**
 *Submitted for verification at polygonscan.com on 2022-11-21
*/

//SPDX-License-Identifier: MIT
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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)



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

// File: contracts/RealEstateApp.sol





error RealEstateApp__SellerNotFound();
error RealEstateApp__InvalidUser();
error RealEstateApp__SellerAlreadyRegistered();
error RealEstateApp__NotRegisteredAsSeller();
error RealEstateApp__AlreadyListed();
error RealEstateApp__NotListed();
error RealEstateApp__NotOwner();
error RealEstateApp__NonZeroPrice();
error RealEstateApp__InvalidNumberOfTokenId();
error RealEstateApp__NotApproved();
error RealEstateApp__PropertyPriceNotMet();
error RealEstateApp__NoProceeds();
error RealEstateApp__TransferFailed();

contract RealEstateApp {
    event SellerRegistered(address indexed sellerAddress, uint256 indexed sellerCounter);
    event PropertyListed(
        address indexed nftAddress,
        address indexed seller,
        uint256[] tokenIds,
        uint256 price
    );
    event PropertySold(
        address indexed seller,
        address indexed buyer,
        address indexed nftAddress,
        uint256[] tokenIds,
        uint256 price
    );
    event PropertyListingCancelled(
        address indexed seller,
        address indexed nftAddress,
        uint256[] tokenIds
    );

    struct Property {
        uint256 price;
        uint256[] tokenIds;
        address seller;
    }
    mapping(address => uint256) private s_seller;
    mapping(address => Property) private s_properties;
    mapping(address => uint256) private s_proceeds;
    address private immutable i_owner;
    uint256 private s_sellerCounter;
    bool isLocked = false;

    modifier _exists(address seller) {
        if (s_seller[seller] != 0) revert RealEstateApp__SellerAlreadyRegistered();
        _;
    }
    modifier isSeller(address seller) {
        if (s_seller[seller] == 0) revert RealEstateApp__NotRegisteredAsSeller();
        _;
    }
    modifier notListed(address nftAddress) {
        if (s_properties[nftAddress].price > 0) {
            revert RealEstateApp__AlreadyListed();
        }
        _;
    }
    modifier isListed(address nftAddress) {
        if (s_properties[nftAddress].price == 0) {
            revert RealEstateApp__NotListed();
        }
        _;
    }
    modifier isOwner(address seller, address nftAddress) {
        if (s_properties[nftAddress].seller != seller) {
            revert RealEstateApp__NotOwner();
        }
        _;
    }
    modifier noReentrancy() {
        require(isLocked == false);
        isLocked = true;
        _;
        isLocked = false;
    }

    constructor() {
        i_owner = msg.sender;
        s_sellerCounter = 0;
    }

    function registerSeller() public _exists(msg.sender) {
        if (msg.sender == address(0)) {
            revert RealEstateApp__InvalidUser();
        }
        s_sellerCounter += 1;
        s_seller[msg.sender] = s_sellerCounter;
        emit SellerRegistered(msg.sender, s_sellerCounter);
    }

    function listProperty(
        address nftAddress,
        uint256[] memory tokenIds,
        uint256 price
    ) public notListed(nftAddress) isSeller(msg.sender) {
        if (price <= 0) {
            revert RealEstateApp__NonZeroPrice();
        }
        if (nftAddress == address(0)) {
            revert RealEstateApp__InvalidUser();
        }
        if (tokenIds.length == 0 || tokenIds.length >= 8) {
            revert RealEstateApp__InvalidNumberOfTokenId();
        }
        IERC721 nft = IERC721(nftAddress);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (nft.getApproved(tokenIds[i]) != address(this)) {
                revert RealEstateApp__NotApproved();
            }
        }
        Property memory property = Property(price, tokenIds, msg.sender);
        s_properties[nftAddress] = property;
        emit PropertyListed(nftAddress, msg.sender, tokenIds, price);
    }

    function buyProperty(address nftAddress) external payable isListed(nftAddress) noReentrancy {
        Property memory property = s_properties[nftAddress];
        if (msg.value < property.price) {
            revert RealEstateApp__PropertyPriceNotMet();
        }
        s_proceeds[property.seller] += msg.value;
        delete (s_properties[nftAddress]);
        IERC721 nft = IERC721(nftAddress);
        for (uint256 i = 0; i < property.tokenIds.length; i++) {
            nft.safeTransferFrom(property.seller, msg.sender, property.tokenIds[i]);
        }
        emit PropertySold(nftAddress, msg.sender, nftAddress, property.tokenIds, property.price);
    }

    function cancelPropertyListing(address nftAddress)
        public
        isOwner(msg.sender, nftAddress)
        isListed(nftAddress)
    {
        Property memory property = s_properties[nftAddress];
        delete (s_properties[nftAddress]);
        emit PropertyListingCancelled(msg.sender, nftAddress, property.tokenIds);
    }

    function updatePropertyListing(
        address nftAddress,
        uint256[] memory newtokenIds,
        uint256 newPrice
    ) external isListed(nftAddress) isOwner(nftAddress, msg.sender) {
        cancelPropertyListing(nftAddress);
        listProperty(nftAddress, newtokenIds, newPrice);
    }

    function withdrawProceeds() external {
        uint256 proceeds = s_proceeds[msg.sender];
        if (proceeds <= 0) {
            revert RealEstateApp__NoProceeds();
        }
        s_proceeds[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: proceeds}("");
        if (!success) {
            revert RealEstateApp__TransferFailed();
        }
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getSellerCounter() public view returns (uint256) {
        return s_sellerCounter;
    }

    function getProceeds(address seller) public view returns (uint256) {
        return s_proceeds[seller];
    }

    function getProperty(address nftAddress) public view returns (Property memory) {
        return s_properties[nftAddress];
    }
}