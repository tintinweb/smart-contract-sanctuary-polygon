// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title Marketplace
/// @author AkylbekAD
/// @notice This is the only marketplace where ERC721 from NFTFactory NFTs could be traded

import "./interfaces/IERC721UUPS.sol";

contract Marketplace721 {
    /// @dev Contains all data types of each order
    struct Order {
        uint256 orderId;
        uint256 tokenId;
        uint256 priceWEI;
        uint256 percentFee;
        address seller;
        address buyer;
        bool sellerAccepted;
    }

    /// @dev Contains all data types of each auction
    struct Auction {
        uint256 auctionId;
        uint256 tokenId;
        uint256 bestBid;
        uint256 percentFee;
        uint256 auctionEndUnix;
        address bestBidder;
        address seller;
    }

    /// @dev Contains all info about existing orders and auctions of ERC721 tokens
    struct NFTContractInfo {
        uint256 lastOrderId;
        uint256 currentOrders;
        uint256 lastAuctionId;
        uint256 currentAuctions;
        mapping(uint256 => Order) NFTOrders;
        mapping(uint256 => Auction) NFTAuctions;
    }

    /// @dev Struct for getting general info about NFTContractInfo without mappings
    struct _NFTContractInfo{
        uint256 lastOrderId;
        uint256 currentOrders;
        uint256 lastAuctionId;
        uint256 currentAuctions;
    }

    /// @dev Address of contract owner
    address public owner;

    /// @notice Amount of decimals of fee percents
    uint256 constant public percentDecimals = 2;

    /// @notice Minimal amount of time for each auction in seconds
    uint256 public minimumAuctionTime = 0;

    /// @dev Some constants for non-Reentrancy modifier
    uint256 private _status;
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    /// @dev Contains all ERC721 Trading info with mappings
    mapping(address => NFTContractInfo) public TradingInfo;

    event OrderAdded(
        address indexed NFTAddress,
        uint256 indexed orderId,
        address indexed seller,
        uint256 tokenId,
        uint256 priceWEI
    );
    event OrderRemoved(
        address indexed NFTAddress,
        uint256 indexed orderId,
        address indexed seller
    );
    event OrderRedeemed(
        address indexed NFTAddress,
        uint256 indexed orderId,
        address indexed buyer
    );
    event FundsReturned(
        address indexed NFTAddress,
        uint256 indexed orderId,
        bool indexed accepted,
        address buyer
    );
    event SellerAccepted(
        address indexed NFTAddress,
        uint256 indexed orderId,
        bool indexed accepted
    );
    event OrderCompleted(
        address indexed NFTAddress,
        uint256 indexed orderId,
        address indexed buyer
    );
    event AuctionStarted(
        address indexed NFTAddress,
        uint256 indexed auctionId,
        address indexed seller,
        uint256 tokenId,
        uint256 startPriceWEI
    );
    event BibDone(
        address indexed NFTAddress,
        uint256 indexed auctionId,
        address indexed bestBidder,
        uint256 bestBid
    );
    event AuctionEnded(
        address indexed NFTAddress,
        uint256 indexed auctionId,
        address indexed bestBidder,
        uint256 bestBid,
        uint256 tokenId
    );

    /* Prevent a contract function from being reentrant-called. */
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
        _;
        // By storing the original value once again, a refund is triggered
        _status = _NOT_ENTERED;
    }

    constructor() {
        owner = msg.sender;
        _status = _NOT_ENTERED;
    }

    /**
     * @notice First you need to approve token transfer to Trade contract.
     *        Then you can add an order for selling you approved NFT
     * @param contractAddress ERC721 contract address
     * @param tokenId NFT token ID you want to sell
     * @param priceWEI Price value in WEI for NFT order, must be equal or more 10000
     * @dev Function makes an call to 'contractAddress' contract to get 'percentFee' value
     *      to pay fee to owner
     */
    function addOrder(
        address contractAddress,
        uint256 tokenId,
        uint256 priceWEI
    ) external {
        IERC721UUPS(contractAddress).safeTransferFrom(
            msg.sender,
            address(this),
            tokenId
        );
        require(priceWEI >= 10000, "Minumal price for sale is 10000 WEI");

        uint256 orderId = TradingInfo[contractAddress].lastOrderId;

        TradingInfo[contractAddress].NFTOrders[orderId].orderId = orderId;
        TradingInfo[contractAddress].NFTOrders[orderId].tokenId = tokenId;
        TradingInfo[contractAddress].NFTOrders[orderId].priceWEI = priceWEI;
        TradingInfo[contractAddress].NFTOrders[orderId].seller = msg.sender;
        TradingInfo[contractAddress].NFTOrders[orderId].percentFee = IERC721UUPS(contractAddress).percentFee();

        TradingInfo[contractAddress].lastOrderId++;
        TradingInfo[contractAddress].currentOrders++;

        emit OrderAdded(contractAddress, orderId, msg.sender, tokenId, priceWEI);
    }

    /**
     * @notice Seller can remove an order, if it is not funded.
     * If not, seller or buyer must call 'declineOrder' to remove order
     * @param contractAddress ERC721 contract address
     * @param orderId Order id you want to remove
     * @dev Only seller of order can call this function
     */
    function removeOrder(address contractAddress, uint256 orderId) external {
        Order storage order = TradingInfo[contractAddress].NFTOrders[orderId];
        require(msg.sender == order.seller, "You are not a seller");
        require(
            order.buyer == address(0),
            "Order is funded, funds must be returned"
        );

        IERC721UUPS(contractAddress).transferFrom(address(this), order.seller, order.tokenId);

        delete TradingInfo[contractAddress].NFTOrders[orderId];
        TradingInfo[contractAddress].currentOrders--;

        emit OrderRemoved(contractAddress, orderId, msg.sender);
    }

    /**
     * @notice Funds an order you want to redeem, function must be funded with enough MATIC
     * @param contractAddress ERC721 contract address
     * @param orderId Order id you want to redeem
     * @dev MATIC value must be equal or more then order price, buyer address must be zero
     */
    function redeemOrder(address contractAddress, uint256 orderId)
        external
        payable
    {
        require(
            msg.value >= TradingInfo[contractAddress].NFTOrders[orderId].priceWEI,
            "Insufficient funds to redeem"
        );
        require(
            TradingInfo[contractAddress].NFTOrders[orderId].buyer == address(0),
            "Order has been funded"
        );

        TradingInfo[contractAddress].NFTOrders[orderId].buyer = msg.sender;

        emit OrderRedeemed(contractAddress, orderId, msg.sender);
    }

    /**
     * @notice Seller can accept an order to be initialized, after it was funded by buyer
     * @param contractAddress ERC721 contract address
     * @param orderId Order id seller want to accept buyer or not
     * @dev Only seller of order can call this function
     */
    function acceptOrder(
        address contractAddress,
        uint256 orderId,
        bool isAccepted
    ) external nonReentrant {
        address buyer = TradingInfo[contractAddress].NFTOrders[orderId].buyer;
        require(msg.sender == TradingInfo[contractAddress].NFTOrders[orderId].seller, "You are not a seller");
        require(buyer != address(0), "No one redeems an order");

        if (isAccepted) {
            TradingInfo[contractAddress].NFTOrders[orderId].sellerAccepted = true;

            emit SellerAccepted(contractAddress, orderId, isAccepted);
        } else {
            (bool success, ) = buyer.call{value: TradingInfo[contractAddress].NFTOrders[orderId].priceWEI}("");

            TradingInfo[contractAddress].NFTOrders[orderId].buyer = address(0);

            emit FundsReturned(contractAddress, orderId, isAccepted, buyer);
        }
    }

    /**
     * @notice Completes order, transfers token to buyer, fees to NFT contract owner and reward to seller
     * @param contractAddress ERC721 contract address
     * @param orderId Order id you want to initialize
     * @dev Anyone can call this function, reverts if 'hasSentWEIToSeller' or 'hasSentWEIToOwner' value returns false
     */
    function completeOrder(address contractAddress, uint256 orderId)
        external
        nonReentrant
    {
        Order storage order = TradingInfo[contractAddress].NFTOrders[orderId];
        require(order.sellerAccepted, "Seller didnt accept a trade");
        require(order.buyer != address(0), "No one redeems an order");

        uint256 fee = (order.priceWEI * order.percentFee) / (100 ** percentDecimals);
        uint256 reward = order.priceWEI - fee;

        (bool hasSentWEIToSeller, ) = order.seller.call{value: reward}("");
        require(hasSentWEIToSeller, "Can not send WEI to seller");

        (bool hasSentWEIToOwner, ) = IERC721UUPS(contractAddress).owner().call{value: fee}("");
        require(hasSentWEIToOwner, "Can not send WEI to NFT contract Owner");

        IERC721UUPS(contractAddress).transferFrom(address(this), order.buyer, order.tokenId);

        TradingInfo[contractAddress].currentOrders--;

        delete TradingInfo[contractAddress].NFTOrders[orderId];

        emit OrderCompleted(contractAddress, orderId, order.buyer);
    }

    /**
     * @notice Returns funds to order buyer, can only be called by order seller or buyer
     * @param contractAddress ERC721 contract address
     * @param orderId Order id you want to return funds
     * @dev Do not revert if can not send WEI to order buyer
     */
    function declineOrder(address contractAddress, uint256 orderId)
        external
        nonReentrant
    {
        Order storage order = TradingInfo[contractAddress].NFTOrders[orderId];
        require(msg.sender == order.buyer || msg.sender == order.seller, "Only seller or buyer can decline");
        require(order.buyer != address(0), "Nothing to decline");

        (bool success, ) = order.buyer.call{value: order.priceWEI}("");

        TradingInfo[contractAddress].NFTOrders[orderId].buyer = address(0);
        TradingInfo[contractAddress].NFTOrders[orderId].sellerAccepted = false;

        emit FundsReturned(contractAddress, orderId, false, msg.sender);
    }

    /**
     * @notice Creates auction order for NFT, approved by it`s owner to Trade contract
     * @param contractAddress ERC721 contract address
     * @param tokenId NFT token ID you want to sell on auction
     * @param initialPrice Start price in WEI for NFT on auction
     * @param secondsToEnd How much seconds should be passed for auction to be ended
     * @dev Gets value of 'percentFee' from 'contractAddress' contract
     */
    function startAuction(
        address contractAddress,
        uint256 tokenId,
        uint256 initialPrice,
        uint256 secondsToEnd
    ) external {
        require(initialPrice >= 10000, "Minumal price for sale is 10000 WEI");
        require(secondsToEnd >= minimumAuctionTime, "Time must be more then minimal auction time");

        IERC721UUPS(contractAddress).safeTransferFrom(
            msg.sender,
            address(this),
            tokenId
        );

        uint256 auctionId = TradingInfo[contractAddress].lastAuctionId;

        TradingInfo[contractAddress].NFTAuctions[auctionId].auctionId = auctionId;
        TradingInfo[contractAddress].NFTAuctions[auctionId].bestBid = initialPrice;
        TradingInfo[contractAddress].NFTAuctions[auctionId].tokenId = tokenId;
        TradingInfo[contractAddress].NFTAuctions[auctionId].percentFee = IERC721UUPS(contractAddress).percentFee();
        TradingInfo[contractAddress].NFTAuctions[auctionId].seller = msg.sender;
        TradingInfo[contractAddress].NFTAuctions[auctionId].auctionEndUnix = block.timestamp + secondsToEnd;

        TradingInfo[contractAddress].lastAuctionId++;
        TradingInfo[contractAddress].currentAuctions++;

        emit AuctionStarted(contractAddress, auctionId, msg.sender, tokenId, initialPrice);
    }

    /**
     * @notice Makes a bid for an auction order, must be more then previous one and
     *         pays for transfering the last 'bestBidder' his 'bestBid'
     * @param contractAddress ERC721 contract address
     * @param auctionId Auction id you want to win
     * @dev Not reverts if can not send MATIC to last 'bestBidder'
     */
    function makeBid(address contractAddress, uint256 auctionId) external payable nonReentrant {
        Auction storage auction = TradingInfo[contractAddress].NFTAuctions[auctionId];

        require(auction.seller != address(0), "Tokens is not on sale");
        require(auction.auctionEndUnix > block.timestamp, "Auction time passed");
        require(msg.value > auction.bestBid, "Bid must be higher than previous");

        (bool success, ) = auction.bestBidder.call{value: auction.bestBid}("");

        TradingInfo[contractAddress].NFTAuctions[auctionId].bestBidder = msg.sender;
        TradingInfo[contractAddress].NFTAuctions[auctionId].bestBid = msg.value;

        emit BibDone(contractAddress, auctionId, msg.sender, msg.value);
    }

    /**
     * @notice Initialize token transfer to 'bestBidder', fees to NFT contract owner and reward to seller,
     * if there is no any bids, NFT transfers back to seller
     * @param contractAddress ERC721 contract address
     * @param auctionId Auction id you want to finish and initialize
     * @dev Reverts if can not send fee to NFT contract owner or reward to 'bestBidder'
     */
    function completeAuction(address contractAddress, uint256 auctionId) external nonReentrant {
        Auction storage auction = TradingInfo[contractAddress].NFTAuctions[auctionId];

        require(auction.auctionEndUnix < block.timestamp, "Auction time did not pass");

        if(auction.bestBidder == address(0)) {
            IERC721UUPS(contractAddress).safeTransferFrom(
                address(this),
                auction.seller,
                auction.tokenId
            );
        } else {
            uint256 fee = (auction.bestBid * auction.percentFee) / (100 ** percentDecimals);
            uint256 reward = auction.bestBid - fee;

            (bool hasSentWEIToSeller, ) = auction.seller.call{value: reward}("");
            require(hasSentWEIToSeller, "Can not send WEI to seller");

            (bool hasSentWEIToOwner, ) = IERC721UUPS(contractAddress).owner().call{value: fee}("");
            require(hasSentWEIToOwner, "Can not send WEI to NFT contract Owner");

            IERC721UUPS(contractAddress).safeTransferFrom(
                address(this),
                auction.bestBidder,
                auction.tokenId
            );
        }

        TradingInfo[contractAddress].currentAuctions--;

        delete TradingInfo[contractAddress].NFTAuctions[auctionId];

        emit AuctionEnded(contractAddress, auctionId, auction.bestBidder, auction.bestBid, auction.tokenId);
    }

    function setMinimalAuctionTime(uint256 timeInSeconds) external {
        require(msg.sender == owner, "You are not an owner!");
        minimumAuctionTime = timeInSeconds;
    }

    /**
    * @notice Returns certain order info of ERC1155 contract
    * @param nftContractAddress ERC1155 contract address
    * @param orderId Order id you want to get
    */
    function getOrder(address nftContractAddress, uint256 orderId) external view returns(Order memory orderInfo) {
        return TradingInfo[nftContractAddress].NFTOrders[orderId];
    }

    /**
    * @notice Returns certain auction info of ERC1155 contract
    * @param nftContractAddress ERC1155 contract address
    * @param auctionId Auction id you want to get
    */
    function getAuction(address nftContractAddress, uint256 auctionId) external view returns(Auction memory auctionInfo) {
        return TradingInfo[nftContractAddress].NFTAuctions[auctionId];
    }

    /**
    * @notice Returns array of all existing orders of ERC1155 contract
    * @param nftContractAddress ERC1155 contract address
    */
    function getAllOrders(address nftContractAddress) external view returns(Order[] memory) {
        Order[] memory ArrayOfOrders = new Order[](TradingInfo[nftContractAddress].currentOrders);
        uint256 j;

        for(uint256 i = 0; i < TradingInfo[nftContractAddress].lastOrderId; i++) {
            if(TradingInfo[nftContractAddress].NFTOrders[i].seller != address(0)) {
                ArrayOfOrders[j] = TradingInfo[nftContractAddress].NFTOrders[i];
                j++;
            }
        }

        return ArrayOfOrders;
    }

    /**
    * @notice Returns array of all existing auctions of ERC1155 contract
    * @param nftContractAddress ERC1155 contract address
    */
    function getAllAuctions(address nftContractAddress) external view returns(Auction[] memory) {
        Auction[] memory ArrayOfAuctions = new Auction[](TradingInfo[nftContractAddress].currentAuctions);
        uint256 j;
        for(uint256 i = 0; i < TradingInfo[nftContractAddress].lastAuctionId; i++) {
            if(TradingInfo[nftContractAddress].NFTAuctions[i].seller != address(0)) {
                ArrayOfAuctions[j] = TradingInfo[nftContractAddress].NFTAuctions[i];
                j++;
            }
        }

        return ArrayOfAuctions;
    }

    /**
    * @notice Returns general info about current quantity and last index of orders and auctions
    * @param nftContractAddress ERC1155 contract address
    */
    function getTradingInfo(address nftContractAddress) external view returns(_NFTContractInfo memory) {
        _NFTContractInfo memory Info;
        Info.currentOrders = TradingInfo[nftContractAddress].currentOrders;
        Info.lastOrderId = TradingInfo[nftContractAddress].lastOrderId;
        Info.currentAuctions = TradingInfo[nftContractAddress].currentAuctions;
        Info.lastAuctionId = TradingInfo[nftContractAddress].lastAuctionId;

        return Info;
    }

    /// @dev Needs for ERC721 token receiving
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface IERC721UUPS is IERC721Upgradeable {
    function percentFee() external returns(uint256);

    function owner() external returns(address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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