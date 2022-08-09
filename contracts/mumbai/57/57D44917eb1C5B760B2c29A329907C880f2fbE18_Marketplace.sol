// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title Marketplace
/// @author AkylbekAD
/// @notice Marketplace contract where ERC1155 from NFTFactory NFTs could be traded

import "./interfaces/IERC1155UUPS.sol";

contract Marketplace {
    /// @dev Contains all data types of each order
    struct Order {
        uint256 priceWEI;
        uint256 amount;
        uint256 percentFee;
        address seller;
        address buyer;
        bool sellerAccepted;
    }

    /// @dev Contains all data types of each auction
    struct Auction {
        uint256 bestPrice;
        uint256 amount;
        uint256 percentFee;
        uint256 deadline;
        address bestBider;
        address seller;
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

    /// @notice Contains and returns NFT orders structs
    mapping(address => mapping(address => mapping(uint256 => Order))) public NFTOrders;
    /// @notice Contains and returns NFT auction structs
    mapping(address => mapping(address => mapping(uint256 => Auction))) public NFTAuctions;

    event OrderAdded(
        address indexed NFTAddress,
        uint256 indexed tokenID,
        uint256 indexed amount,
        uint256 priceWEI,
        address seller
    );
    event OrderRedeemed(
        address indexed NFTAddress,
        uint256 indexed tokenID,
        address indexed buyer
    );
    event OrderRemoved(
        address indexed NFTAddress,
        uint256 indexed tokenID,
        address seller
    );
    event DepositReturned(
        address indexed NFTAddress,
        uint256 indexed tokenID,
        uint256 indexed priceWEI,
        address buyer
    );
    event SellerAccepted(
        address indexed NFTAddress,
        uint256 indexed tokenID,
        bool indexed accepted
    );
    event OrderInitilized(
        address indexed NFTAddress,
        uint256 indexed tokenID,
        uint256 indexed amount,
        address seller,
        address buyer
    );
    event AuctionStarted(
        address indexed NFTAddress,
        uint256 indexed tokenID,
        uint256 indexed amount,
        uint256 priceWEI,
        address seller
    );
    event BibDone(
        address indexed NFTAddress,
        uint256 indexed tokenID,
        uint256 indexed bestBid,
        address bestBider
    );
    event AuctionEnded(
        address indexed NFTAddress,
        uint256 indexed tokenID,
        uint256 indexed amount,
        uint256 bestPrice,
        address seller,
        address buyer
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
     * @param _NFTAddress ERC1155 contract address
     * @param _tokenID NFT token ID you want to sell
     * @param _priceWEI Price value in WEI for NFT order, must be equal or more 10000 
     * @dev Function makes an call to '_NFTAddress' contract to get 'percentFee' value 
     *      to pay fee to owner
     */
    function addOrder(
        address _NFTAddress,
        uint256 _tokenID,
        uint256 _amount,
        uint256 _priceWEI
    ) external {
        require(NFTOrders[_NFTAddress][msg.sender][_tokenID].seller == address(0), "Remove your previous order");

        IERC1155UUPS(_NFTAddress).safeTransferFrom(
            msg.sender,
            address(this),
            _tokenID,
            _amount,
            bytes("0")
        );
        require(_priceWEI >= 10000, "Minumal price for sale is 10000 WEI");

        NFTOrders[_NFTAddress][msg.sender][_tokenID].priceWEI = _priceWEI;
        NFTOrders[_NFTAddress][msg.sender][_tokenID].amount = _amount;
        NFTOrders[_NFTAddress][msg.sender][_tokenID].seller = msg.sender;
        NFTOrders[_NFTAddress][msg.sender][_tokenID].percentFee = IERC1155UUPS(_NFTAddress).percentFee();

        emit OrderAdded(_NFTAddress, _tokenID, _amount, _priceWEI, msg.sender);
    }

    /**
     * @notice Seller can remove an order, if it is not funded.
     * If not, seller or buyer must call 'declineOrder' to remove order
     * @param _NFTAddress ERC1155 contract address
     * @param _tokenID NFT token ID you want to return
     * @dev Only seller of order can call this function
     */
    function removeOrder(address _NFTAddress, uint256 _tokenID) external {
        Order storage order = NFTOrders[_NFTAddress][msg.sender][_tokenID];
        require(msg.sender == order.seller, "You are not a seller");
        require(
            order.buyer == address(0),
            "Order is funded, funds must be returned"
        );

        IERC1155UUPS(_NFTAddress).safeTransferFrom(address(this), msg.sender, _tokenID, order.amount, bytes("0"));

        delete NFTOrders[_NFTAddress][msg.sender][_tokenID];

        emit OrderRemoved(_NFTAddress, _tokenID, msg.sender);
    }

    /**
     * @notice Funds an order you want to redeem, function must be funded with enough WEI
     * @param _NFTAddress ERC1155 contract address
     * @param _seller Order creator or token seller
     * @param _tokenID NFT token ID you want to buy
     * @dev WEI value must be equal or more then order price, buyer address must be zero
     */
    function redeemOrder(address _NFTAddress, address _seller, uint256 _tokenID)
        external
        payable
    {
        require(
            msg.value >= NFTOrders[_NFTAddress][_seller][_tokenID].priceWEI,
            "Insufficient funds to redeem"
        );
        require(
            NFTOrders[_NFTAddress][_seller][_tokenID].buyer == address(0),
            "Order has been funded"
        );

        NFTOrders[_NFTAddress][_seller][_tokenID].buyer = msg.sender;

        emit OrderRedeemed(_NFTAddress, _tokenID, msg.sender);
    }

    /**
     * @notice Seller can accept an order to be initialized, after it was funded by buyer
     * @param _NFTAddress ERC1155 contract address
     * @param _seller Order creator or token seller
     * @param _tokenID NFT token ID you want to accept an order
     * @dev Only seller of order can call this function
     */
    function acceptOrder(
        address _NFTAddress,
        address _seller,
        uint256 _tokenID,
        bool isAccepted
    ) external nonReentrant {
        address buyer = NFTOrders[_NFTAddress][_seller][_tokenID].buyer;
        require(msg.sender == NFTOrders[_NFTAddress][_seller][_tokenID].seller, "You are not a seller");
        require(buyer != address(0), "Noone redeems an order");

        if (isAccepted) {
            NFTOrders[_NFTAddress][_seller][_tokenID].sellerAccepted = true;
        } else {
            (bool success, ) = buyer.call{value: NFTOrders[_NFTAddress][_seller][_tokenID].priceWEI}("");
            require(success, "Can not send WEI to buyer");

            NFTOrders[_NFTAddress][_seller][_tokenID].buyer = address(0);
        }

        emit SellerAccepted(_NFTAddress, _tokenID, isAccepted);
    }

    /**
     * @notice Initializes token transfer to buyer, fees to NFT contract owner and reward to seller
     * @param _NFTAddress ERC1155 contract address
     * @param _seller Order creator or token seller
     * @param _tokenID NFT token ID you want to initialize order
     * @dev Anyone can call this function, reverts if any 'success' value returns false
     */
    function initializeOrder(address _NFTAddress, address _seller, uint256 _tokenID)
        external
        nonReentrant
    {
        Order storage order = NFTOrders[_NFTAddress][_seller][_tokenID];
        require(order.sellerAccepted, "Seller didnt accept a trade");
        require(order.buyer != address(0), "Noone redeems an order");

        uint256 fee = (order.priceWEI * order.percentFee) / (100 ** percentDecimals);
        uint256 reward = order.priceWEI - fee;
        
        (bool success1, ) = IERC1155UUPS(_NFTAddress).owner().call{value: fee}("");
        require(success1, "Can not send WEI to NFT contract owner");

        (bool success2, ) = order.seller.call{value: reward}("");
        require(success2, "Can not send WEI to seller");

        IERC1155UUPS(_NFTAddress).safeTransferFrom(address(this), order.buyer, _tokenID, order.amount, bytes("0"));

        emit OrderInitilized(_NFTAddress, _tokenID, order.amount, order.seller, order.buyer);

        delete NFTOrders[_NFTAddress][_seller][_tokenID];
    }

    /**
     * @notice Returns funds to order buyer, can only be called by order seller or buyer
     * @param _NFTAddress ERC1155 contract address
     * @param _seller Order creator or token seller
     * @param _tokenID NFT token ID you want to unfund
     * @dev Reverts if 'success' value returns false
     */
    function declineOrder(address _NFTAddress, address _seller, uint256 _tokenID)
        external
        nonReentrant
    {
        Order storage order = NFTOrders[_NFTAddress][_seller][_tokenID];
        require(msg.sender == order.buyer || msg.sender == order.seller, "Only seller or buyer can decline");
        require(order.buyer != address(0), "Nothing to decline");

        (bool success, ) = order.buyer.call{value: order.priceWEI}("");
        require(success, "Can not send WEI to buyer");
        
        NFTOrders[_NFTAddress][_seller][_tokenID].buyer = address(0);
        NFTOrders[_NFTAddress][_seller][_tokenID].sellerAccepted = false;

        emit DepositReturned(_NFTAddress, _tokenID, order.priceWEI, msg.sender);
    }

    /**
     * @notice Creates auction order for NFT, approved by it`s owner to Trade contract
     * @param _NFTAddress ERC1155 contract address
     * @param _tokenID NFT token ID you want to sell on auction
     * @param initialPrice Start price in WEI for NFT on auction 
     * @param secondsToEnd How much seconds should be passed for auction to be ended
     * @dev Gets value of 'percentFee' from '_NFTAddress' contract
     */
    function startAuction(
        address _NFTAddress,
        uint256 _tokenID,
        uint256 amount,
        uint256 initialPrice,
        uint256 secondsToEnd
    ) external {
        require(NFTAuctions[_NFTAddress][msg.sender][_tokenID].seller == address(0), "Previous auction did not end");

        IERC1155UUPS(_NFTAddress).safeTransferFrom(
            msg.sender,
            address(this),
            _tokenID,
            amount,
            bytes("0")
        );
        require(initialPrice >= 10000, "Minumal price for sale is 10000 WEI");
        require(secondsToEnd >= minimumAuctionTime, "Time must be more then minimal auction time");

        NFTAuctions[_NFTAddress][msg.sender][_tokenID].bestPrice = initialPrice;
        NFTAuctions[_NFTAddress][msg.sender][_tokenID].percentFee = IERC1155UUPS(_NFTAddress).percentFee();
        NFTAuctions[_NFTAddress][msg.sender][_tokenID].seller = msg.sender;
        NFTAuctions[_NFTAddress][msg.sender][_tokenID].deadline = block.timestamp + secondsToEnd;

        emit AuctionStarted(_NFTAddress, _tokenID, amount, initialPrice, msg.sender);
    }

    /**
     * @notice Makes a bid for an auction order, must be more then previous one and
     *         pays for transfering the last 'bestBidder' his 'bestBid'
     * @param _NFTAddress ERC1155 contract address
     * @param _seller Order creator or token seller
     * @param _tokenID NFT token ID you want to buy
     * @dev Not reverts if can not send WEI to last 'bestBidder'
     */
    function makeBid(address _NFTAddress, address _seller, uint256 _tokenID) external payable nonReentrant {
        Auction storage auction = NFTAuctions[_NFTAddress][_seller][_tokenID];

        require(auction.seller != address(0), "Tokens is not on sale");
        require(auction.deadline > block.timestamp, "Auction time passed");
        require(msg.value > auction.bestPrice, "Bid must be higher than previous");

        (bool success, ) = auction.bestBider.call{value: auction.bestPrice}("");

        NFTAuctions[_NFTAddress][_seller][_tokenID].bestBider = msg.sender;
        NFTAuctions[_NFTAddress][_seller][_tokenID].bestPrice = msg.value;

        emit BibDone(_NFTAddress, _tokenID, msg.value, msg.sender);
    }

    /**
     * @notice Initialize token transfer to 'bestBidder', fees to NFT contract owner and reward to seller,
     * if there is no any bids, NFT transfers back to seller
     * @param _NFTAddress ERC1155 contract address
     * @param _seller Order creator or token seller
     * @param _tokenID NFT token ID you want auction get finished
     * @dev Reverts if can not send fee to NFT contract owner or reward to 'bestBidder'
     */
    function finishAuction(address _NFTAddress, address _seller, uint256 _tokenID) external nonReentrant {
        Auction storage auction = NFTAuctions[_NFTAddress][_seller][_tokenID];

        require(auction.deadline < block.timestamp, "Auction time did not pass");

        if(auction.bestBider == address(0)) {
            IERC1155UUPS(_NFTAddress).safeTransferFrom(
                address(this),
                auction.seller,
                _tokenID,
                auction.amount,
                bytes("0")
            );
        } else {
            uint256 fee = (auction.bestPrice * auction.percentFee) / (100 ** percentDecimals);
            uint256 reward = auction.bestPrice - fee;

            (bool success1, ) = auction.seller.call{value: reward}("");
            require(success1, "Can not send WEI to seller");

            (bool success2, ) = IERC1155UUPS(_NFTAddress).owner().call{value: fee}("");
            require(success2, "Can not send WEI to NFT contrac owner");

            IERC1155UUPS(_NFTAddress).safeTransferFrom(
                address(this),
                auction.bestBider,
                _tokenID,
                auction.amount,
                bytes("0")
            );
        }

        emit AuctionEnded(_NFTAddress, _tokenID, auction.amount, auction.bestPrice, auction.seller, auction.bestBider);

        delete NFTAuctions[_NFTAddress][_seller][_tokenID];
    }

    function setMinimalAuctionTime(uint256 timeInSeconds) external {
        require(msg.sender == owner, "You are not an owner!");
        minimumAuctionTime = timeInSeconds;
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