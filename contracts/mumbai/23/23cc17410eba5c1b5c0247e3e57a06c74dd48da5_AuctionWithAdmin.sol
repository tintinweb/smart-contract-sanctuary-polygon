// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC20.sol";
import "./Ownable.sol";

contract AuctionWithAdmin is Ownable {
    // The NFT token we are selling
    IERC721 private nft_token;
    // The ERC20 token we are using
    IERC20 private token;

    // beneficiary Address
    address beneficiary;

    // Represents an auction on an NFT
    struct AuctionDetails {
        // Price (in token) at beginning of auction
        uint256 price;
        // Time (in seconds) when auction started
        uint256 startTime;
        // Time (in seconds) when auction ended
        uint256 endTime;
        // Address of highest bidder
        address highestBidder;
        // Highest bid amount
        uint256 highestBid;
        // Total number of bids
        uint256 totalBids;
    }

    // Represents an deal on an NFT
    struct DealDetails {
        // Price (in token) at beginning of deal
        uint256 price;
        // Time (in seconds) when deal started
        uint256 startTime;
        // Time (in seconds) when deal ended
        uint256 endTime;
    }

    // Represents an offer on an NFT
    struct OfferDetails {
        // Price (in token) at beginning of auction
        uint256 price;
        // Address of offerer
        address offerer;
        // Offer accepted
        bool accepted;
    }

    // Mapping token ID to their corresponding auction.
    mapping(uint256 => AuctionDetails) private auction;
    // Mapping token ID to their corresponding deal.
    mapping(uint256 => DealDetails) private deal;
    // Mapping token ID to their corresponding offer.
    mapping(uint256 => OfferDetails) private offer;
    // Mapping from addresss to token ID for claim.
    mapping(address => mapping(uint256 => uint256)) private pending_claim;
    // Mapping from token ID to token price
    mapping(uint256 => uint256) private token_price;
    // Mapping from token ID to token seller
    mapping(uint256 => address) private token_seller;

    uint256 sell_token_fee;
    uint256 auction_token_fee;

    event Sell(
        address indexed _seller,
        uint256 _tokenId,
        uint256 _price,
        uint256 _time
    );
    event SellCancelled(
        address indexed _seller,
        uint256 _tokenId,
        uint256 _time
    );
    event Buy(
        address indexed _buyer,
        uint256 _tokenId,
        address _seller,
        uint256 _price,
        uint256 _time
    );

    event AuctionCreated(
        address indexed _seller,
        uint256 _tokenId,
        uint256 _price,
        uint256 _startTime,
        uint256 _endTime
    );
    event Bid(
        address indexed _bidder,
        uint256 _tokenId,
        uint256 _price,
        uint256 _time
    );
    event AuctionCancelled(
        address indexed _seller,
        uint256 _tokenId,
        uint256 _time
    );

    event DealCreated(
        address indexed _seller,
        uint256 _tokenId,
        uint256 _price,
        uint256 _startTime,
        uint256 _endTime
    );
    event BuyDeal(
        address indexed _buyer,
        uint256 _tokenId,
        address _seller,
        uint256 _price,
        uint256 _time
    );
    event DealCancelled(
        address indexed _seller,
        uint256 _tokenId,
        uint256 _time
    );

    event OfferMaked(
        address indexed _offerer,
        uint256 _tokenId,
        uint256 _price,
        uint256 _time
    );
    event OfferReceived(
        address indexed _buyer,
        uint256 _tokenId,
        address _seller,
        uint256 _price,
        uint256 _time
    );

    /// @dev Initialize the nft token contract address.
    /// @param _nftToken - NFT token addess.
    /// @param _token    - ERC20 token addess.
    function initialize(address _nftToken, address _token)
        public
        virtual
        onlyOwner
        returns (bool)
    {
        require(_nftToken != address(0));
        nft_token = IERC721(_nftToken);
        token = IERC20(_token);
        return true;
    }

    /// @dev Returns the nft token contract address.
    function getNFTToken() public view returns (IERC721) {
        return nft_token;
    }

    /// @dev Returns the token contract address.
    function getToken() public view returns (IERC20) {
        return token;
    }

    /// @dev Set the beneficiary address.
    /// @param _owner - beneficiary addess.
    function setBeneficiary(address _owner) public onlyOwner {
        beneficiary = _owner;
    }

    /// @dev Contract owner set the token fee percent which is for sell.
    /// @param _tokenFee - Token fee.
    function setTokenFeePercentForSell(uint256 _tokenFee) public onlyOwner {
        sell_token_fee = _tokenFee;
    }

    /// @dev Contract owner set the token fee percent which is for auction.
    /// @param _tokenFee - Token fee.
    function setTokenFeePercentForAuction(uint256 _tokenFee) public onlyOwner {
        auction_token_fee = _tokenFee;
    }

    /// @dev Creates and begins a new auction.
    /// @param _tokenId - ID of token to auction, sender must be owner.
    /// @param _price - Price of token (in token) at beginning of auction.
    /// @param _startTime - Start time of auction.
    /// @param _endTime - End time of auction.
    function createAuction(
        uint256 _tokenId,
        uint256 _price,
        uint256 _startTime,
        uint256 _endTime
    ) public {
        require(msg.sender == nft_token.ownerOf(_tokenId), "You are not owner");
        require(
            nft_token.getApproved(_tokenId) == address(this),
            "Token not approved"
        );
        require(
            _startTime < _endTime && _endTime > block.timestamp,
            "Check Time"
        );
        AuctionDetails memory auctionToken;
        auctionToken = AuctionDetails({
            price: _price,
            startTime: _startTime,
            endTime: _endTime,
            highestBidder: address(0),
            highestBid: 0,
            totalBids: 0
        });
        token_seller[_tokenId] = msg.sender;
        auction[_tokenId] = auctionToken;
        nft_token.transferFrom(msg.sender, address(this), _tokenId);
        emit AuctionCreated(msg.sender, _tokenId, _price, _startTime, _endTime);
    }

    /// @dev Creates and begins a new deal.
    /// @param _tokenId - ID of token to deal, sender must be owner.
    /// @param _price - Price of token (in token) at deal.
    /// @param _startTime - Start time of deal.
    /// @param _endTime - End time of deal.
    function createDeal(
        uint256 _tokenId,
        uint256 _price,
        uint256 _startTime,
        uint256 _endTime
    ) public {
        require(msg.sender == nft_token.ownerOf(_tokenId), "You are not owner");
        require(
            nft_token.getApproved(_tokenId) == address(this),
            "Token not approved"
        );
        require(
            _startTime < _endTime && _endTime > block.timestamp,
            "Check Time"
        );
        DealDetails memory dealToken;
        dealToken = DealDetails({
            price: _price,
            startTime: _startTime,
            endTime: _endTime
        });
        token_seller[_tokenId] = msg.sender;
        deal[_tokenId] = dealToken;
        nft_token.transferFrom(msg.sender, address(this), _tokenId);
        emit DealCreated(msg.sender, _tokenId, _price, _startTime, _endTime);
    }

    /// @dev Buy from open sell.
    /// Transfer NFT ownership to buyer address.
    /// @param _tokenId - ID of NFT on buy.
    /// @param _amount  - Seller set the price (in token) of NFT token.
    function buyDeal(uint256 _tokenId, uint256 _amount) public {
        require(
            block.timestamp > deal[_tokenId].startTime,
            "Deal not started yet"
        );
        require(block.timestamp < deal[_tokenId].endTime, "Deal is over");
        require(
            token_seller[_tokenId] != address(0) && deal[_tokenId].price > 0,
            "Token not for deal"
        );
        require(_amount >= deal[_tokenId].price, "Your amount is less");
        nft_token.transferFrom(address(this), msg.sender, _tokenId);
        token.transferFrom(
            msg.sender,
            beneficiary,
            ((_amount * sell_token_fee) / 100)
        );
        token.transferFrom(
            msg.sender,
            token_seller[_tokenId],
            ((_amount * (100 - sell_token_fee)) / 100)
        );
        delete token_seller[_tokenId];
        delete deal[_tokenId];
        emit BuyDeal(
            msg.sender,
            _tokenId,
            token_seller[_tokenId],
            _amount,
            block.timestamp
        );
    }

    /// @dev Removes an deal from the list of open deals.
    /// Returns the NFT to original owner.
    /// @param _tokenId - ID of NFT on deal.
    function cancelDeal(uint256 _tokenId) public {
        require(msg.sender == token_seller[_tokenId], "You are not owner");
        require(deal[_tokenId].price > 0, "Can't cancel this deal");
        nft_token.transferFrom(address(this), msg.sender, _tokenId);
        delete deal[_tokenId];
        delete token_seller[_tokenId];
        emit DealCancelled(msg.sender, _tokenId, block.timestamp);
    }

    /// @dev Bids on an open auction.
    /// @param _tokenId - ID of token to bid on.
    /// @param _amount  - Bidder set the bid (in token) of NFT token.
    function bid(uint256 _tokenId, uint256 _amount) public {
        require(
            block.timestamp > auction[_tokenId].startTime,
            "Auction not started yet"
        );
        require(block.timestamp < auction[_tokenId].endTime, "Auction is over");
        // The first bid, ensure it's >= the reserve price.
        require(
            _amount >= auction[_tokenId].price,
            "Bid must be at least the reserve price"
        );
        // Bid must be greater than last bid.
        require(_amount > auction[_tokenId].highestBid, "Bid amount too low");
        token.transferFrom(msg.sender, address(this), _amount);
        pending_claim[msg.sender][_tokenId] += _amount;
        auction[_tokenId].highestBidder = msg.sender;
        auction[_tokenId].highestBid = pending_claim[msg.sender][_tokenId];
        auction[_tokenId].totalBids++;
        emit Bid(msg.sender, _tokenId, _amount, block.timestamp);
    }

    /// @dev Offer on an sell.
    /// @param _tokenId - ID of token to offer on.
    /// @param _amount  - Offerer set the price (in token) of NFT token.
    function makeOffer(uint256 _tokenId, uint256 _amount) public {
        require(
            token_seller[_tokenId] != address(0) && token_price[_tokenId] > 0,
            "Token not for sell"
        );
        // Offer must be greater than last offer.
        require(
            _amount > offer[_tokenId].price,
            "Offer amount less then already offerred"
        );
        token.transferFrom(msg.sender, address(this), _amount);
        pending_claim[msg.sender][_tokenId] += _amount;
        offer[_tokenId].offerer = msg.sender;
        offer[_tokenId].price = pending_claim[msg.sender][_tokenId];
        emit OfferMaked(msg.sender, _tokenId, _amount, block.timestamp);
    }

    /// @dev Receive offer from open sell.
    /// Transfer NFT ownership to offerer address.
    /// @param _tokenId - ID of NFT on offer.
    function reciveOffer(uint256 _tokenId) public {
        require(msg.sender == token_seller[_tokenId], "You are not owner");
        nft_token.transferFrom(
            address(this),
            offer[_tokenId].offerer,
            _tokenId
        );
        token.transfer(
            beneficiary,
            ((offer[_tokenId].price * sell_token_fee) / 100)
        );
        token.transfer(
            token_seller[_tokenId],
            ((offer[_tokenId].price * (100 - sell_token_fee)) / 100)
        );
        delete token_seller[_tokenId];
        delete token_price[_tokenId];
        delete offer[_tokenId];
        emit OfferReceived(
            offer[_tokenId].offerer,
            _tokenId,
            msg.sender,
            offer[_tokenId].price,
            block.timestamp
        );
    }

    /// @dev Create claim after auction ends.
    /// Transfer NFT to auction winner address.
    /// Seller and Bidders (not win in auction) Withdraw their funds.
    /// @param _tokenId - ID of NFT.
    function claim(uint256 _tokenId) public {
        require(
            block.timestamp > auction[_tokenId].endTime,
            "Auction not ended yet"
        );
        if (msg.sender == token_seller[_tokenId]) {
            token.transfer(
                beneficiary,
                ((auction[_tokenId].highestBid * auction_token_fee) / 100)
            );
            token.transfer(
                msg.sender,
                ((auction[_tokenId].highestBid * (100 - auction_token_fee)) /
                    100)
            );
            pending_claim[auction[_tokenId].highestBidder][_tokenId] = 0;
        } else if (auction[_tokenId].highestBidder == msg.sender) {
            nft_token.transferFrom(address(this), msg.sender, _tokenId);
        } else {
            token.transfer(msg.sender, pending_claim[msg.sender][_tokenId]);
            pending_claim[msg.sender][_tokenId] = 0;
        }
    }

    /// @dev Returns auction info for an NFT on auction.
    /// @param _tokenId - ID of NFT on auction.
    function getAuction(uint256 _tokenId)
        public
        view
        virtual
        returns (AuctionDetails memory)
    {
        return auction[_tokenId];
    }

    /// @dev Returns auction info for an NFT on auction.
    /// @param _tokenId - ID of NFT on auction.
    function getPending_claim(address _user, uint256 _tokenId)
        public
        view
        virtual
        returns (uint256)
    {
        return pending_claim[_user][_tokenId];
    }

    /// @dev Returns sell NFT token price.
    /// @param _tokenId - ID of NFT.
    function getSellTokenPrice(uint256 _tokenId) public view returns (uint256) {
        return token_price[_tokenId];
    }

    /// @dev Buy from open sell.
    /// Transfer NFT ownership to buyer address.
    /// @param _tokenId - ID of NFT on buy.
    /// @param _amount  - Seller set the price (in token) of NFT token.
    function buy(uint256 _tokenId, uint256 _amount) public {
        require(
            token_seller[_tokenId] != address(0) && token_price[_tokenId] > 0,
            "Token not for sell"
        );
        require(_amount >= token_price[_tokenId], "Your amount is less");
        nft_token.transferFrom(address(this), msg.sender, _tokenId);
        token.transferFrom(
            msg.sender,
            beneficiary,
            ((_amount * sell_token_fee) / 100)
        );
        token.transferFrom(
            msg.sender,
            token_seller[_tokenId],
            ((_amount * (100 - sell_token_fee)) / 100)
        );
        delete token_seller[_tokenId];
        delete token_price[_tokenId];
        emit Buy(
            msg.sender,
            _tokenId,
            token_seller[_tokenId],
            _amount,
            block.timestamp
        );
    }

    /// @dev Creates a new sell.
    /// Transfer NFT ownership to this contract.
    /// @param _tokenId - ID of NFT on sell.
    /// @param _price   - Seller set the price (in token) of NFT token.
    function sell(uint256 _tokenId, uint256 _price) public {
        require(msg.sender == nft_token.ownerOf(_tokenId), "You are not owner");
        require(
            nft_token.getApproved(_tokenId) == address(this),
            "Token not approved"
        );
        token_price[_tokenId] = _price;
        token_seller[_tokenId] = msg.sender;
        nft_token.transferFrom(msg.sender, address(this), _tokenId);
        emit Sell(msg.sender, _tokenId, _price, block.timestamp);
    }

    /// @dev Removes token from the list of open sell.
    /// Returns the NFT to original owner.
    /// @param _tokenId - ID of NFT on sell.
    function cancelSell(uint256 _tokenId) public {
        require(msg.sender == token_seller[_tokenId], "You are not owner");
        nft_token.transferFrom(address(this), msg.sender, _tokenId);
        delete token_seller[_tokenId];
        delete token_price[_tokenId];
        emit SellCancelled(msg.sender, _tokenId, block.timestamp);
    }

    /// @dev Removes an auction from the list of open auctions.
    /// Returns the NFT to original owner.
    /// @param _tokenId - ID of NFT on auction.
    function cancelAuction(uint256 _tokenId) public {
        require(msg.sender == token_seller[_tokenId], "You are not owner");
        require(
            auction[_tokenId].endTime > block.timestamp,
            "Can't cancel this auction"
        );
        nft_token.transferFrom(address(this), msg.sender, _tokenId);
        delete auction[_tokenId];
        delete token_seller[_tokenId];
        emit AuctionCancelled(msg.sender, _tokenId, block.timestamp);
    }
}