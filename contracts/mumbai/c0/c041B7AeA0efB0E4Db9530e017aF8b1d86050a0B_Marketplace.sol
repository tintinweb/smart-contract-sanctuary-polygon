/**
 *Submitted for verification at polygonscan.com on 2023-05-23
*/

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


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

// File: @openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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

// File: contracts/MarketPlaceTest.sol


pragma solidity ^0.8.0;



contract Marketplace is ERC721Holder {
    struct Item {
        address seller;
        uint256 price;
        bool isForSale;
        uint256 tokenPosition;
    }

    mapping(uint256 => Item) public items;
    mapping(uint256 => address) public acceptedTokensByPosition;
    address payable public marketplaceOwner;
    uint256 public commissionRate;

    event ItemListed(uint256 indexed itemId, address indexed seller, uint256 price);
    event ItemSold(uint256 indexed itemId, address indexed seller, address indexed buyer, uint256 price, uint256 commissionFee);

    modifier onlyMarketplaceOwner() {
        require(msg.sender == marketplaceOwner, "Only marketplace owner can call this function");
        _;
    }

    constructor() {
        marketplaceOwner = payable(msg.sender);
        commissionRate = 2; // 2%
        acceptedTokensByPosition[0] = address(0); // Matic or other base token
    }

    function addAcceptedToken(address tokenAddress) external onlyMarketplaceOwner {
        uint256 newPosition = getNumAcceptedTokens();
        acceptedTokensByPosition[newPosition] = tokenAddress;
    }

    function getNumAcceptedTokens() public view returns (uint256) {
        uint256 numTokens = 0;
        while (acceptedTokensByPosition[numTokens] != address(0)) {
            numTokens++;
        }
        return numTokens;
    }

    function listForSale(uint256 itemId, uint256 price, uint256 tokenPosition) external {
        require(items[itemId].seller == address(0), "Item already listed");
        require(acceptedTokensByPosition[tokenPosition] != address(0), "Token not accepted");

        IERC721 nft = IERC721(items[itemId].seller);
        address owner = nft.ownerOf(itemId);
        require(owner == msg.sender, "You don't own this item");

        // Approve the marketplace contract to transfer the NFT
        nft.safeTransferFrom(msg.sender, address(this), itemId);

        items[itemId] = Item(owner, price, true, tokenPosition);
        emit ItemListed(itemId, owner, price);
    }

    function buy(uint256 itemId) external payable {
        Item storage item = items[itemId];
        require(item.isForSale, "Item is not for sale");
        require(item.seller != address(0), "Item does not exist");
        require(item.tokenPosition < getNumAcceptedTokens(), "Invalid token position");
        require(msg.value >= item.price, "Insufficient funds");

        address payable seller = payable(item.seller);
        uint256 price = item.price;

        item.isForSale = false;

        // Calculate commission fee as percentage of the price
        uint256 commissionFee = (price * commissionRate) / 100;

        emit ItemSold(itemId, seller, msg.sender, price, commissionFee);

        // Transfer the NFT to the buyer
        IERC721 nft = IERC721(seller);
        nft.safeTransferFrom(address(this), msg.sender, itemId);

        // Transfer funds to the seller
        seller.transfer(price - commissionFee);

        // Transfer commission fee to the marketplace contract
        payable(address(this)).transfer(commissionFee);

        // Refund excess payment to the buyer
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function cancelSale(uint256 itemId) external {
        Item storage item = items[itemId];
        require(item.seller == msg.sender, "You are not the seller");

        item.isForSale = false;

        // Transfer the NFT back to the seller
        IERC721 nft = IERC721(msg.sender);
        nft.safeTransferFrom(address(this), msg.sender, itemId);
    }

    function setMarketplaceOwner(address payable newOwner) external onlyMarketplaceOwner {
        marketplaceOwner = newOwner;
    }

    function setCommissionRate(uint256 rate) external onlyMarketplaceOwner {
        require(rate <= 100, "Commission rate exceeds 100%");
        commissionRate = rate;
    }

    function getTokenByPosition(uint256 position) public view returns (address) {
        if (position >= getNumAcceptedTokens()) {
            revert("Invalid token position");
        }

        return acceptedTokensByPosition[position];
    }
}