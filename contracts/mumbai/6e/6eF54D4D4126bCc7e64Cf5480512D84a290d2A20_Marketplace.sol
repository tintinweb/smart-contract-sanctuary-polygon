// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/// @title Marketplace
/// @author AkylbekAD
/// @notice Marketplace contract where ERC1155 from NFTFactory NFTs could be traded

import "./interfaces/IERC1155UUPS.sol";

contract Marketplace {
    /// @dev Contains all data types of each order
    struct Order {
        uint256 priceWEI;
        uint256 tokenId;
        uint256 amount;
        uint256 percentFee;
        address seller;
        address buyer;
        bool sellerAccepted;
    }

    /// @dev Contains all data types of each auction
    struct Auction {
        uint256 bestPrice;
        uint256 tokenId;
        uint256 amount;
        uint256 percentFee;
        uint256 deadline;
        address bestBider;
        address seller;
    }

    /// @dev Contains all info about existing orders and auctions of ERC1155 nfts
    struct NFTContractInfo {
        uint256 lastOrderId;
        uint256 currentOrders;
        uint256 lastAuctionId;
        uint256 currentAuctions;
        mapping(uint256 => Order) NFTOrders;
        mapping(uint256 => Auction) NFTAuctions;
    }

    /// @dev Struct for getting general info about NFTCotractInfo without mappings
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

    /// @notice Minimal amount of time for each auction
    uint256 public minimumAuctionTime = 2 days;

    /// @dev Some constants for non-Reetrancy modifier
    uint256 private _status;
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    mapping(address => NFTContractInfo) public TradingInfo;

    event OrderAdded(
        address indexed NFTAddress,
        uint256 indexed orderId,
        address indexed seller,
        uint256 tokenId,
        uint256 amount,
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
    event OrderInitilized(
        address indexed NFTAddress,
        uint256 indexed orderId,
        address indexed buyer
    );
    event AuctionStarted(
        address indexed NFTAddress,
        uint256 indexed auctionId,
        address indexed seller,
        uint256 tokenId,
        uint256 amount,
        uint256 startPriceWEI
    );
    event BibDone(
        address indexed NFTAddress,
        uint256 indexed auctionId,
        address indexed bestBider,
        uint256 bestBid
    );
    event AuctionEnded(
        address indexed NFTAddress,
        uint256 indexed auctionId,
        address indexed bestBider,
        uint256 bestPrice,
        uint256 tokenId,
        uint256 amount
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
     * @param contractAddress ERC1155 contract address
     * @param tokenId NFT token ID you want to sell
     * @param amount Quantity on tokens to sell
     * @param priceWEI Price value in WEI for NFT order, must be equal or more 10000 
     * @dev Function makes an call to 'contractAddress' contract to get 'percentFee' value 
     *      to pay fee to owner
     */
    function addOrder(
        address contractAddress,
        uint256 tokenId,
        uint256 amount,
        uint256 priceWEI
    ) external {
        require(priceWEI >= 10000, "Minumal price for sale is 10000 WEI");
        
        IERC1155UUPS(contractAddress).safeTransferFrom(
            msg.sender,
            address(this),
            tokenId,
            amount,
            bytes("0")
        );

        uint256 orderId = TradingInfo[contractAddress].lastOrderId;

        TradingInfo[contractAddress].NFTOrders[orderId].priceWEI = priceWEI;
        TradingInfo[contractAddress].NFTOrders[orderId].amount = amount;
        TradingInfo[contractAddress].NFTOrders[orderId].seller = msg.sender;
        TradingInfo[contractAddress].NFTOrders[orderId].percentFee = IERC1155UUPS(contractAddress).percentFee();

        TradingInfo[contractAddress].lastOrderId++;
        TradingInfo[contractAddress].currentOrders++;

        emit OrderAdded(contractAddress, orderId, msg.sender, tokenId, amount, priceWEI);
    }

    /**
     * @notice Seller can remove an order, if it is not funded.
     * If not, seller or buyer must call 'declineOrder' to remove order
     * @param contractAddress ERC1155 contract address
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

        IERC1155UUPS(contractAddress).safeTransferFrom(address(this), msg.sender, order.tokenId, order.amount, bytes("0"));

        delete TradingInfo[contractAddress].NFTOrders[orderId];
        TradingInfo[contractAddress].currentOrders--;

        emit OrderRemoved(contractAddress, orderId, msg.sender);
    }

    /**
     * @notice Funds an order you want to redeem, function must be funded with enough WEI
     * @param contractAddress ERC1155 contract address
     * @param orderId Order id you want to redeem
     * @dev WEI value must be equal or more then order price, buyer address must be zero
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
     * @param contractAddress ERC1155 contract address
     * @param orderId Your order id you want to accept or return funding
     * @dev Only seller of order can call this function
     */
    function acceptOrder(
        address contractAddress,
        uint256 orderId,
        bool isAccepted
    ) external nonReentrant {
        address buyer = TradingInfo[contractAddress].NFTOrders[orderId].buyer;
        require(msg.sender == TradingInfo[contractAddress].NFTOrders[orderId].seller, "You are not a seller");
        require(buyer != address(0), "Noone redeems an order");

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
     * @notice Initializes token transfer to buyer, fees to NFT contract owner and reward to seller
     * @param contractAddress ERC1155 contract address
     * @param orderId Order id you want to initialize 
     * @dev Anyone can call this function, reverts if any 'success' value returns false
     */
    function initializeOrder(address contractAddress, uint256 orderId)
        external
        nonReentrant
    {
        Order storage order = TradingInfo[contractAddress].NFTOrders[orderId];
        require(order.sellerAccepted, "Seller didnt accept a trade");
        require(order.buyer != address(0), "Noone redeems an order");

        uint256 fee = (order.priceWEI * order.percentFee) / (100 ** percentDecimals);
        uint256 reward = order.priceWEI - fee;
        
        (bool success1, ) = IERC1155UUPS(contractAddress).owner().call{value: fee}("");
        require(success1, "Can not send WEI to NFT contract owner");

        (bool success2, ) = order.seller.call{value: reward}("");
        require(success2, "Can not send WEI to seller");

        IERC1155UUPS(contractAddress).safeTransferFrom(address(this), order.buyer, order.tokenId, order.amount, bytes("0"));

        TradingInfo[contractAddress].currentOrders--;

        delete TradingInfo[contractAddress].NFTOrders[orderId];

        emit OrderInitilized(contractAddress, orderId, order.buyer);
    }

    /**
     * @notice Returns funds to order buyer, can only be called by order seller or buyer
     * @param contractAddress ERC1155 contract address
     * @param orderId Order id you want to undo redeem
     * @dev Reverts if 'success' value returns false
     */
    function declineOrder(address contractAddress, uint256 orderId)
        external
        nonReentrant
    {
        Order storage order = TradingInfo[contractAddress].NFTOrders[orderId];
        require(msg.sender == order.buyer || msg.sender == order.seller, "Only seller or buyer can decline");
        require(order.buyer != address(0), "Nothing to decline");

        (bool success, ) = order.buyer.call{value: order.priceWEI}("");
        require(success, "Can not send WEI to buyer");
        
        TradingInfo[contractAddress].NFTOrders[orderId].buyer = address(0);
        TradingInfo[contractAddress].NFTOrders[orderId].sellerAccepted = false;

        emit FundsReturned(contractAddress, orderId, false, msg.sender);
    }

    /**
     * @notice Creates auction order for NFT, approved by it`s owner to Trade contract
     * @param contractAddress ERC1155 contract address
     * @param tokenId NFT token ID you want to sell on auction
     * @param amount Quantity of tokens you want to sell on auction
     * @param initialPrice Start price in WEI for NFT on auction 
     * @param secondsToEnd How much seconds should be passed for auction to be ended
     * @dev Gets value of 'percentFee' from 'contractAddress' contract
     */
    function startAuction(
        address contractAddress,
        uint256 tokenId,
        uint256 amount,
        uint256 initialPrice,
        uint256 secondsToEnd
    ) external {
        require(initialPrice >= 10000, "Minumal price for sale is 10000 WEI");
        require(secondsToEnd >= minimumAuctionTime, "Time must be more then minimal auction time");

        IERC1155UUPS(contractAddress).safeTransferFrom(
            msg.sender,
            address(this),
            tokenId,
            amount,
            bytes("0")
        );

        uint256 auctionId = TradingInfo[contractAddress].lastAuctionId;

        TradingInfo[contractAddress].NFTAuctions[auctionId].bestPrice = initialPrice;
        TradingInfo[contractAddress].NFTAuctions[auctionId].tokenId = tokenId;
        TradingInfo[contractAddress].NFTAuctions[auctionId].amount = amount;
        TradingInfo[contractAddress].NFTAuctions[auctionId].percentFee = IERC1155UUPS(contractAddress).percentFee();
        TradingInfo[contractAddress].NFTAuctions[auctionId].seller = msg.sender;
        TradingInfo[contractAddress].NFTAuctions[auctionId].deadline = block.timestamp + secondsToEnd;

        TradingInfo[contractAddress].lastAuctionId++;
        TradingInfo[contractAddress].currentAuctions++;

        emit AuctionStarted(contractAddress, tokenId, msg.sender, tokenId, amount, initialPrice);
    }

    /**
     * @notice Makes a bid for an auction order, must be more then previous one and
     *         pays for transfering the last 'bestBidder' his 'bestBid'
     * @param contractAddress ERC1155 contract address
     * @param auctionId Auction id you want to win
     * @dev Not reverts if can not send WEI to last 'bestBidder'
     */
    function makeBid(address contractAddress, uint256 auctionId) external payable nonReentrant {
        Auction storage auction = TradingInfo[contractAddress].NFTAuctions[auctionId];

        require(auction.seller != address(0), "Tokens is not on sale");
        require(auction.deadline > block.timestamp, "Auction time passed");
        require(msg.value > auction.bestPrice, "Bid must be higher than previous");

        (bool success, ) = auction.bestBider.call{value: auction.bestPrice}("");

        TradingInfo[contractAddress].NFTAuctions[auctionId].bestBider = msg.sender;
        TradingInfo[contractAddress].NFTAuctions[auctionId].bestPrice = msg.value;

        emit BibDone(contractAddress, auctionId, msg.sender, msg.value);
    }

    /**
     * @notice Initialize token transfer to 'bestBidder', fees to NFT contract owner and reward to seller,
     * if there is no any bids, NFT transfers back to seller
     * @param contractAddress ERC1155 contract address
     * @param auctionId Auction id you want to finish and initialize
     * @dev Reverts if can not send fee to NFT contract owner or reward to 'bestBidder'
     */
    function finishAuction(address contractAddress, uint256 auctionId) external nonReentrant {
        Auction storage auction = TradingInfo[contractAddress].NFTAuctions[auctionId];

        require(auction.deadline < block.timestamp, "Auction time did not pass");

        if(auction.bestBider == address(0)) {
            IERC1155UUPS(contractAddress).safeTransferFrom(
                address(this),
                auction.seller,
                auction.tokenId,
                auction.amount,
                bytes("0")
            );
        } else {
            uint256 fee = (auction.bestPrice * auction.percentFee) / (100 ** percentDecimals);
            uint256 reward = auction.bestPrice - fee;

            (bool success1, ) = auction.seller.call{value: reward}("");
            require(success1, "Can not send WEI to seller");

            (bool success2, ) = IERC1155UUPS(contractAddress).owner().call{value: fee}("");
            require(success2, "Can not send WEI to NFT contrac owner");

            IERC1155UUPS(contractAddress).safeTransferFrom(
                address(this),
                auction.bestBider,
                auction.tokenId,
                auction.amount,
                bytes("0")
            );
        }

        TradingInfo[contractAddress].currentAuctions--;

        delete TradingInfo[contractAddress].NFTAuctions[auctionId];

        emit AuctionEnded(contractAddress, auctionId, auction.bestBider, auction.bestPrice, auction.tokenId, auction.amount);
    }

    function setMinimalAuctionTime(uint256 timeInSeconds) external {
        require(msg.sender == owner, "You are not an owner!");
        minimumAuctionTime = timeInSeconds;
    }

    /** 
    * @notice Returns ceratin order info of ERC1155 contract
    * @param nftContractAddress ERC1155 contract address
    * @param orderId Order id you want to get
    */
   function getOrder(address nftContractAddress, uint256 orderId) external view returns(Order memory orderInfo) {
        return TradingInfo[nftContractAddress].NFTOrders[orderId];
   }

    /** 
    * @notice Returns ceratin auction info of ERC1155 contract
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

        for(uint256 i = 0; i < TradingInfo[nftContractAddress].lastOrderId; i++) {
            if(TradingInfo[nftContractAddress].NFTOrders[i].seller != address(0)) {
                ArrayOfOrders[i] = TradingInfo[nftContractAddress].NFTOrders[i];
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

        for(uint256 i = 0; i < TradingInfo[nftContractAddress].lastOrderId; i++) {
            if(TradingInfo[nftContractAddress].NFTAuctions[i].seller != address(0)) {
                ArrayOfAuctions[i] = TradingInfo[nftContractAddress].NFTAuctions[i];
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

    /// @dev Needs for ERC1155 token receiving
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

interface IERC1155UUPS is IERC1155Upgradeable {
    function percentFee() external returns(uint256);
    
    function owner() external returns(address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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