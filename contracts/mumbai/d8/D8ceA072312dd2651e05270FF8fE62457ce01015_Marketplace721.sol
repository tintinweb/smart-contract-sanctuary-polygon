// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title Marketplace
/// @author AkylbekAD
/// @notice This is the only marketplace where ERC721 from NFTFactory NFTs could be traded

import "./interfaces/IERC721UUPS.sol";

contract Marketplace721 {
    /// @dev Contains all data types of each order
    struct Order {
        uint256 priceWEI;
        uint256 percentFee;
        address seller;
        address buyer;
        bool sellerAccepted;
    }

    /// @dev Contains all data types of each auction
    struct Auction {
        uint256 bestPriceWEI;
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
    mapping(address => mapping(uint256 => Order)) public NFTOrders;
    /// @notice Contains and returns NFT auction structs
    mapping(address => mapping(uint256 => Auction)) public NFTAuctions;

    event OrderAdded(
        address indexed NFTAddress,
        uint256 indexed tokenID,
        uint256 indexed priceWEI,
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
        address seller,
        address buyer
    );
    event AuctionStarted(
        address indexed NFTAddress,
        uint256 indexed tokenID,
        uint256 indexed priceWEI,
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
        uint256 indexed bestPriceWEI,
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
     * @param _NFTAddress ERC721 contract address
     * @param _tokenID NFT token ID you want to sell
     * @param _priceWEI Price value in WEI for NFT order, must be equal or more 10000
     * @dev Function makes an call to '_NFTAddress' contract to get 'percentFee' value
     *      to pay fee to owner
     */
    function addOrder(
        address _NFTAddress,
        uint256 _tokenID,
        uint256 _priceWEI
    ) external returns (bool isOrderAdded) {
        IERC721UUPS(_NFTAddress).safeTransferFrom(
            msg.sender,
            address(this),
            _tokenID
        );
        require(_priceWEI >= 10000, "Minumal price for sale is 10000 WEI");

        NFTOrders[_NFTAddress][_tokenID].priceWEI = _priceWEI;
        NFTOrders[_NFTAddress][_tokenID].seller = msg.sender;
        NFTOrders[_NFTAddress][_tokenID].percentFee = IERC721UUPS(_NFTAddress).percentFee();

        emit OrderAdded(_NFTAddress, _tokenID, _priceWEI, msg.sender);

        return true;
    }

    /**
     * @notice Seller can remove an order, if it is not funded.
     * If not, seller or buyer must call 'declineOrder' to remove order
     * @param _NFTAddress ERC721 contract address
     * @param _tokenID NFT token ID you want to return
     * @dev Only seller of order can call this function
     */
    function removeOrder(address _NFTAddress, uint256 _tokenID) external {
        address seller = NFTOrders[_NFTAddress][_tokenID].seller;
        require(msg.sender == seller, "You are not an seller");
        require(
            NFTOrders[_NFTAddress][_tokenID].buyer == address(0),
            "Order is funded, funds must be returned"
        );

        IERC721UUPS(_NFTAddress).transferFrom(address(this), seller, _tokenID);

        delete NFTOrders[_NFTAddress][_tokenID];

        emit OrderRemoved(_NFTAddress, _tokenID, seller);
    }

    /**
     * @notice Funds an order you want to redeem, function must be funded with enough MATIC
     * @param _NFTAddress ERC721 contract address
     * @param _tokenID NFT token ID you want to buy
     * @dev MATIC value must be equal or more then order price, buyer address must be zero
     */
    function redeemOrder(address _NFTAddress, uint256 _tokenID)
    external
    payable
    returns (bool success)
    {
        require(
            msg.value >= NFTOrders[_NFTAddress][_tokenID].priceWEI,
            "Insufficient funds to redeem"
        );
        require(
            NFTOrders[_NFTAddress][_tokenID].buyer == address(0),
            "Order has been funded"
        );

        NFTOrders[_NFTAddress][_tokenID].buyer = msg.sender;

        emit OrderRedeemed(_NFTAddress, _tokenID, msg.sender);

        return true;
    }

    /**
     * @notice Seller can accept an order to be initialized, after it was funded by buyer
     * @param _NFTAddress ERC721 contract address
     * @param _tokenID NFT token ID you want to accept an order
     * @dev Only seller of order can call this function
     */
    function acceptOrder(
        address _NFTAddress,
        uint256 _tokenID,
        bool isAccepted
    ) external nonReentrant {
        Order storage order = NFTOrders[_NFTAddress][_tokenID];
        require(msg.sender == order.seller, "You are not a seller");
        require(order.buyer != address(0), "Noone redeems an order");

        if (isAccepted) {
            order.sellerAccepted = true;
        } else {
            (bool success, ) = order.buyer.call{value: order.priceWEI}("");
            require(success, "Can not send MATIC to buyer");

            order.buyer = address(0);
        }

        emit SellerAccepted(_NFTAddress, _tokenID, isAccepted);
    }

    /**
     * @notice Initializes token transfer to buyer, fees to NFT contract owner and reward to seller
     * @param _NFTAddress ERC721 contract address
     * @param _tokenID NFT token ID you want to initialize order
     * @dev Anyone can call this function, reverts if any 'success' value returns false
     */
    function initializeOrder(address _NFTAddress, uint256 _tokenID)
    external
    nonReentrant
    {
        Order storage order = NFTOrders[_NFTAddress][_tokenID];
        require(order.sellerAccepted, "Seller didnt accept a trade");
        require(order.buyer != address(0), "Noone redeems an order");

        uint256 fee = (order.priceWEI * order.percentFee) / (100 ** percentDecimals);
        uint256 reward = order.priceWEI - fee;

        address nftContractOwner = IERC721UUPS(_NFTAddress).owner();

        (bool success1, ) = nftContractOwner.call{value: fee}("");
        require(success1, "Can not send MATIC to NFT contract owner");

        (bool success2, ) = order.seller.call{value: reward}("");
        require(success2, "Can not send MATIC to seller");

        IERC721UUPS(_NFTAddress).transferFrom(address(this), order.buyer, _tokenID);

        delete NFTOrders[_NFTAddress][_tokenID];

        emit OrderInitilized(_NFTAddress, _tokenID, order.seller, order.buyer);
    }

    /**
     * @notice Returns funds to order buyer, can only be called by order seller or buyer
     * @param _NFTAddress ERC721 contract address
     * @param _tokenID NFT token ID you want to unfund
     * @dev Reverts if 'success' value returns false
     */
    function declineOrder(address _NFTAddress, uint256 _tokenID)
    external
    nonReentrant
    {
        Order storage order = NFTOrders[_NFTAddress][_tokenID];
        require(msg.sender == order.buyer || msg.sender == order.seller, "Only seller and buyer can decline");
        require(order.buyer != address(0), "Nothing to decline");

        (bool success, ) = order.buyer.call{value: order.priceWEI}("");
        require(success, "Can not send MATIC to buyer");

        NFTOrders[_NFTAddress][_tokenID].buyer = address(0);
        NFTOrders[_NFTAddress][_tokenID].sellerAccepted = false;

        emit DepositReturned(_NFTAddress, _tokenID, order.priceWEI, msg.sender);
    }

    /**
     * @notice Creates auction order for NFT, approved by it`s owner to Trade contract
     * @param _NFTAddress ERC721 contract address
     * @param _tokenID NFT token ID you want to sell on auction
     * @param initialPrice Start price in WEI for NFT on auction
     * @param secondsToEnd How much seconds should be passed for auction to be ended
     * @dev Gets value of 'percentFee' from '_NFTAddress' contract
     */
    function startAuction(
        address _NFTAddress,
        uint256 _tokenID,
        uint256 initialPrice,
        uint256 secondsToEnd
    ) external {
        IERC721UUPS(_NFTAddress).safeTransferFrom(
            msg.sender,
            address(this),
            _tokenID
        );
        require(initialPrice >= 10000, "Minumal price for sale is 10000 WEI");
        require(secondsToEnd >= minimumAuctionTime, "Time must be more then minimal auction time");

        NFTAuctions[_NFTAddress][_tokenID].bestPriceWEI = initialPrice;
        NFTAuctions[_NFTAddress][_tokenID].percentFee = IERC721UUPS(_NFTAddress).percentFee();
        NFTAuctions[_NFTAddress][_tokenID].seller = msg.sender;
        NFTAuctions[_NFTAddress][_tokenID].deadline = block.timestamp + secondsToEnd;

        emit AuctionStarted(_NFTAddress, _tokenID, initialPrice, msg.sender);
    }

    /**
     * @notice Makes a bid for an auction order, must be more then previous one and
     *         pays for transfering the last 'bestBidder' his 'bestBid'
     * @param _NFTAddress ERC721 contract address
     * @param _tokenID NFT token ID you want to buy
     * @dev Not reverts if can not send MATIC to last 'bestBidder'
     */
    function makeBid(address _NFTAddress, uint256 _tokenID) external payable nonReentrant {
        Auction storage auction = NFTAuctions[_NFTAddress][_tokenID];

        require(auction.seller != address(0), "Token is not on sale");
        require(auction.deadline > block.timestamp, "Auction time passed");
        require(msg.value > auction.bestPriceWEI, "Bid must be higher than previous");

        (bool success, ) = auction.bestBider.call{value: auction.bestPriceWEI}("");

        NFTAuctions[_NFTAddress][_tokenID].bestBider = msg.sender;
        NFTAuctions[_NFTAddress][_tokenID].bestPriceWEI = msg.value;

        emit BibDone(_NFTAddress, _tokenID, msg.value, msg.sender);
    }

    /**
     * @notice Initialize token transfer to 'bestBidder', fees to NFT contract owner and reward to seller,
     * if there is no any bids, NFT transfers back to seller
     * @param _NFTAddress ERC721 contract address
     * @param _tokenID NFT token ID you want auction get finished
     * @dev Reverts if can not send fee to NFT contract owner or reward to 'bestBidder'
     */
    function finishAuction(address _NFTAddress, uint256 _tokenID) external nonReentrant {
        Auction storage auction = NFTAuctions[_NFTAddress][_tokenID];

        require(auction.deadline < block.timestamp, "Auction time did not pass");

        if(auction.bestBider == address(0)) {
            IERC721UUPS(_NFTAddress).safeTransferFrom(
                address(this),
                auction.seller,
                _tokenID
            );
        } else {
            uint256 fee = (auction.bestPriceWEI * auction.percentFee) / (100 ** percentDecimals);
            uint256 reward = auction.bestPriceWEI - fee;

            address nftContractOwner = IERC721UUPS(_NFTAddress).owner();

            (bool success1, ) = auction.seller.call{value: reward}("");
            require(success1, "Can not send MATIC to seller");

            (bool success2, ) = nftContractOwner.call{value: fee}("");
            require(success2, "Can not send MATIC to NFT contrac owner");

            IERC721UUPS(_NFTAddress).safeTransferFrom(
                address(this),
                auction.bestBider,
                _tokenID
            );
        }

        emit AuctionEnded(_NFTAddress, _tokenID, auction.bestPriceWEI, auction.seller, auction.bestBider);

        delete NFTAuctions[_NFTAddress][_tokenID];
    }

    function setMinimalAuctionTime(uint256 timeInSeconds) external {
        require(msg.sender == owner, "You are not an owner!");
        minimumAuctionTime = timeInSeconds;
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