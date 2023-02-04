/**
 *Submitted for verification at polygonscan.com on 2023-02-03
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns(uint256 balance);
    function ownerOf(uint256 tokenId) external view returns(address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool _approved) external;
    function getApproved(uint256 tokenId) external view returns(address operator);
    function isApprovedForAll(address owner, address operator) external view returns(bool);
}

interface IERC20 {
    function balanceOf(address account) external view returns(uint256);
    function transfer(address to, uint256 amount) external returns(bool);
    function allowance(address owner, address spender) external view returns(uint256);
    function approve(address spender, uint256 amount) external returns(bool);
    function transferFrom(address from, address to, uint256 amount) external returns(bool);
    function decimals() external view returns(uint8);
}

interface IFactory {
    function deploy(
        string calldata _collectionName,
        string calldata _collectionSymbol,
        string calldata _collectionDescription
    ) external returns(address);
}

/// @author pooriagg
/// @title Decentralized NFT Marketplace
contract MarketPlaceImpV1 {
    error ExternalCallError();

    address public factory;

    address public proxyOwner;
    // address public implementation;

    address public marketFeeTaker;
    uint8 public marketFee;

    address[] public tokens;

    struct SellOrder {
        address seller;
        address token;
        address contractAddr;
        uint256 nftId;
        address buyer;
        uint256 price;
        uint256 startedAt;
        uint256 endedAt;
        bool isCanceled;
        bool isEnded;
    }
    uint256 public sellOrderCount = 1;

    struct Bid {
        address bidder;
        address token;
        address nftOwner;
        uint256 sellOrderId;
        uint256 price;
        uint256 biddedAt;
        uint256 bidEndedAt;
        bool isCanceled;
        bool isEnded;
    }
    uint256 public bidCount = 1;

    // from sell-order id to sell-order info
    mapping (uint256 => SellOrder) private sellOrders;
    // from bid id to bid info
    mapping (uint256 => Bid) private bids;
    // from user to his/her created ERC721 created contract
    mapping (address => address) private userContract;
    // monitor all contracts which created in the markeplace
    mapping (address => bool) private allContracts;
    // monitor all validated and confirmed tokens
    mapping (address => bool) private marketTokens;

    //* Events
    event SellOrderCreated(address indexed creator, uint256 indexed orderId, uint256 time);
    event BidCreated(address indexed bidder, address indexed contractAddr, uint256 indexed nftId, uint bidId, uint256 time);
    event BidCanceled(address indexed bidder, uint256 indexed bidId, uint256 indexed orderId, uint256 time);
    event SellOrderCanceled(address indexed seller, uint256 indexed orderId, uint256 time);
    event NFTContractCreated(address indexed creator, address indexed contractAddr, uint256 time);
    event BidAccepted(address indexed seller, address indexed buyer, uint256 indexed orderId, uint256 bidId, uint256 time);
    //*

    // guard
    bool isLocked;
    modifier NonReentrant() {
        require(isLocked == false, "Locked!");
        isLocked = true;
        _;
        isLocked = false;
    }

    function _computeFee(
        uint256 _price
    ) private view returns(uint256) {
        return ((_price * marketFee) / 100);
    }

    /// @dev user can create a sell-order on the market by calling this function
    /// @param _contractAddr the contract address that user has some nft and wants to create sell-order for that
    /// @param _nftId the nft that user wants to sell
    /// @param _token the currency that user wants to use (it must be a valid token in marketplace)
    /// @param _price the price of this sell-order
    /// note before creating sell-order user must approve marketplace contract to access his/her nft
    function createSellOrder(
        address _contractAddr,
        uint256 _nftId,
        address _token,
        uint256 _price
    ) external {
        require(allContracts[_contractAddr] == true, "Invalid contract address!");
        require(marketTokens[_token] == true, "Invalid token address!");
        IERC721 nft = IERC721(_contractAddr);
        require(nft.ownerOf(_nftId) == msg.sender, "Only owner can create a sell-order.");

        try nft.transferFrom(msg.sender, address(this), _nftId) {
            require(nft.ownerOf(_nftId) == address(this), "Somthing went wrong!");

            SellOrder memory sellOrder = SellOrder({
                seller: msg.sender,
                token: _token,
                contractAddr: _contractAddr,
                nftId: _nftId,
                buyer: address(0),
                price: _price,
                startedAt: block.timestamp,
                endedAt: 0,
                isCanceled: false,
                isEnded: false
            });

            sellOrders[sellOrderCount] = sellOrder;

            sellOrderCount += 1;

            emit SellOrderCreated({
                creator: msg.sender,
                orderId: sellOrderCount - 1,
                time: block.timestamp
            });
        } catch {
            revert ExternalCallError();
        }
    }

    /// @dev user can create a bid for a arbitrary nft by calling this function
    /// @param _orderId the order-id that user wants to make a bid for that
    /// @param _token the currency that user wants to pay with
    /// @param _price the price of the bid user wishes to make for the order
    /// note before creating bid user must approve marketplace contract to access his/her tokens
    function createBid(
        uint256 _orderId,
        address _token,
        uint256 _price /// note token amount must be in decimal format
    ) external NonReentrant {
        require(marketTokens[_token] == true, "Invalid token address!");
        require(_price > 0, "Invalid price.");
        SellOrder memory order = sellOrders[_orderId];
        require(order.seller != address(0), "Order not found!");
        require(order.isCanceled == false && order.isEnded == false, "Order is not accessible.");
        require(order.seller != msg.sender, "You cannot create a bid for yourself sell-order!");

        IERC20 token = IERC20(_token);

        try token.transferFrom(msg.sender, address(this), _price) returns(bool result) {
            require(result == true, "Somthing went wrong!");

            Bid memory bid = Bid({
                bidder: msg.sender,
                token: _token,
                nftOwner: order.seller,
                sellOrderId: _orderId,
                price: _price,
                biddedAt: block.timestamp,
                bidEndedAt: 0,
                isCanceled: false,
                isEnded: false
            });

            bids[bidCount] = bid;

            bidCount += 1;

            emit BidCreated({
                bidder: msg.sender,
                contractAddr: order.contractAddr,
                nftId: order.nftId,
                bidId: bidCount - 1,
                time: block.timestamp
            });
        } catch {
            revert ExternalCallError();
        }
    }

    /// @dev when the user who created a sell-order for the nft wants to accept a bid he must call this function
    /// @param _bidId the id's of bid that the sell-order's creator accepted
    /// @param _orderId the id's of the sell-order
    /// note the bid or order must not be ended or canceled before calling this function
    function acceptBid(
        uint256 _bidId,
        uint256 _orderId
    ) external NonReentrant {
        Bid storage bid = bids[_bidId];
        SellOrder storage order = sellOrders[_orderId];
        require(bid.bidder != address(0) && order.seller != address(0), "Invalid data entered!");
        require(order.seller == msg.sender, "Only sell-order owner can accept a bid!");
        require(bid.sellOrderId == _orderId, "Bid does not match with the sell-order!");
        require(order.isCanceled == false && order.isEnded == false, "Sell-order is not availabe.");
        require(bid.isCanceled == false && bid.isEnded == false, "Bid is not availabe.");

        // update order struct
        order.buyer = bid.bidder;
        order.isEnded = true;
        order.endedAt = block.timestamp;
        // update bid struct
        bid.bidEndedAt = block.timestamp;
        bid.isEnded = true;
        // compute seller and marketplace share then transfer token to seller and nft to the buyer
        uint totalToken = bid.price;
        uint marketplaceShare = _computeFee(totalToken);
        uint sellerShare = totalToken - marketplaceShare;
        // create instances of erc20 & erc721
        IERC20 token = IERC20(bid.token);
        IERC721 nft = IERC721(order.contractAddr);
        // transfer funds and nft
        try nft.transferFrom(address(this), bid.bidder, order.nftId) {
            require(nft.ownerOf(order.nftId) == bid.bidder, "Somthing went wrong! Please try again later.");

            try token.transfer(msg.sender, sellerShare) returns(bool result1) {
                require(result1 == true, "Somthing went wrong!");

                try token.transfer(marketFeeTaker, marketplaceShare) returns(bool result2) {
                    require(result2 == true, "Somthing went wrong!");

                    emit BidAccepted({
                        seller: msg.sender,
                        buyer: bid.bidder,
                        orderId: _orderId,
                        bidId: _bidId,
                        time: block.timestamp
                    });
                } catch {
                    revert ExternalCallError();
                } 
            } catch {
                revert ExternalCallError();
            } 
        } catch {
            revert ExternalCallError();
        }
    }

    /// @dev user can cancel his/her bid
    function cancelBid(
        uint256 _bidId
    ) external NonReentrant {
        Bid storage bid = bids[_bidId];
        require(bid.bidder == msg.sender, "Invalid bid.");
        require(bid.isEnded == false && bid.isCanceled == false, "Bid is not available.");

        bid.isCanceled = true;
        bid.bidEndedAt = block.timestamp;

        uint tokenToTransder = bid.price;
        IERC20 token = IERC20(bid.token);

        try token.transfer(msg.sender, tokenToTransder) returns(bool res) {
            require(res == true, "Somthing went wrong!");

            emit BidCanceled({
                bidder: msg.sender,
                bidId: _bidId,
                orderId: bid.sellOrderId,
                time: block.timestamp
            });
        } catch {
            revert ExternalCallError();
        }
    }

    /// @dev user can cancel his/her sell-order
    function cancelSellOrder(
        uint256 _orderId
    ) external NonReentrant {
        SellOrder storage order = sellOrders[_orderId];
        require(order.seller == msg.sender, "Invalid order!");
        require(order.isCanceled == false && order.isEnded == false, "Order is not available.");

        order.isCanceled = true;
        order.endedAt = block.timestamp;
        
        uint256 nftId = order.nftId;
        IERC721 nft = IERC721(order.contractAddr);

        try nft.transferFrom(address(this), msg.sender, nftId) {
            require(nft.ownerOf(nftId) == msg.sender, "Somthing went wrong!");

            emit SellOrderCanceled({
                seller: msg.sender,
                orderId: _orderId,
                time: block.timestamp
            });
        } catch {
            revert ExternalCallError();
        }
    }

    /// @dev each wallet can create a full-owned NFT contract for them selves by calling this function
    function createERC721Contract(
        string calldata _collectionName,
        string calldata _collectionSymbol,
        string calldata _collectionDescription,
        address _factory
    ) external NonReentrant {
        require(_factory == factory, "Invalid factory address!");
        require(userContract[msg.sender] == address(0), "Cannot deploy contract again!");
        require(
            bytes(_collectionName).length > 0 &&
            bytes(_collectionSymbol).length > 0 &&
            bytes(_collectionDescription).length > 0,
            "Invalid data eneterd!"
        );

        address nft = IFactory(_factory).deploy(
            _collectionName,
            _collectionSymbol,
            _collectionDescription
        );
        userContract[msg.sender] = nft;
        allContracts[nft] = true;

        emit NFTContractCreated({
            creator: msg.sender,
            contractAddr: nft,
            time: block.timestamp
        });
    }
    
    // getters
    function sellOrder(
        uint256 _sellOrderId
    ) external view returns(SellOrder memory) {
        return sellOrders[_sellOrderId];
    }

    function bid(
        uint256 _bidId
    ) external view returns(Bid memory) {
        return bids[_bidId];
    }

    function getUserContract(
        address _user
    ) external view returns(address) {
        return address(userContract[_user]);
    } 

    function getTokens() external view returns(address[] memory) {
        return tokens;
    }

    function isValid(address _target) external view returns(bool) {
        return allContracts[_target];
    }
}