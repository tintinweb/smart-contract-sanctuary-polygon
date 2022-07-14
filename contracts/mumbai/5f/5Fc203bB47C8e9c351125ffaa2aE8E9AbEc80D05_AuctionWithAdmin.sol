// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./EnumerableMap.sol";

 contract AuctionWithAdmin is Ownable {
    // The NFT token we are selling
    IERC721 private nft_token;
    // The ERC20 token we are using
    IERC20 private token;

    // beneficiary Address
    address beneficiary;

    using EnumerableMap for EnumerableMap.UintToAddressMap;

    // Declare a set state variable
    EnumerableMap.UintToAddressMap private saleId;
    // Declare a set state variable
    EnumerableMap.UintToAddressMap private auctionId;
    // Declare a set state variable
    EnumerableMap.UintToAddressMap private dealId;

    // Represents an auction on an NFT
    struct AuctionDetails {
        // ID of auction
        uint256 id;
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
        // Address of prevOfferer
        address prevOfferer;
        // Time (in seconds) when offer created
        uint256 time;
    }
    
    // Represents an Bid on Auction NFT
    struct BidDetails {
        // Address of next bidder
        address nextBidder;
        // Address of prev bidder
        address prevBidder;
        // Price (in token) when user place bid
        uint256 amount;
        // Time (in seconds) when bid created
        uint256 time;
    }

    // Mapping token ID to their corresponding auction.
    mapping(uint256 => AuctionDetails) private auction;
    // Mapping token ID to their corresponding deal.
    mapping(uint256 => DealDetails) private deal;
    // Mapping token ID to their corresponding offer.
    mapping(uint256 => OfferDetails) private offer;
    // Mapping from addresss to token ID for claim.
    mapping(address => mapping(uint256 => uint256)) private pending_claim_offer;
    // Mapping from addresss to token ID for claim.
    mapping(address => mapping(uint256 => uint256)) private pending_claim_auction;
    // Mapping from address to token ID for bid
    mapping(address => mapping(uint256 => BidDetails)) public bid_info;
    // Mapping from address to token ID for bid
    mapping(address => mapping(uint256 => OfferDetails)) public offer_info;
    // Mapping from token ID to token price
    mapping(uint256 => uint256) private token_price;
    // Mapping from token ID to sale ID
    mapping(uint256 => uint256) private tokenIdToSaleId;
    

    mapping(address => uint256[]) private saleTokenIds;
    mapping(address => uint256[]) private auctionTokenIds;
    mapping(address => uint256[]) private dealTokenIds;

    uint256 public currentSaleId;
    uint256 public currentAuctionId;
    uint256 public currentDealId;

    uint256 public sell_token_fee;
    uint256 public auction_token_fee;
    uint256 private cancel_bid_fee;
    uint256 private cancel_offer_fee;

    bool private sell_service_fee = false;
    bool private auction_service_fee = false;
    bool private cancel_bid_enable = false;
    bool private cancel_offer_enable = false;
    

    event SellFee(
        uint256 indexed _id,
        uint256 _tokenId,
        uint256 _fee,
        uint256 _time
    );
    event AuctionFee(
        uint256 indexed _id,
        uint256 _tokenId,
        uint256 _fee,
        uint256 _time
    );
    event Sell(
        uint256 indexed _id,
        address indexed _seller,
        uint256 _tokenId,
        uint256 _price,
        uint256 _time
    );
    event SellCancelled(
        uint256 indexed _id,
        address indexed _seller,
        uint256 _tokenId,
        uint256 _time
    );
    event Buy(
        uint256 indexed _id,
        address indexed _buyer,
        uint256 _tokenId,
        address _seller,
        uint256 _price,
        uint256 _time
    );
    event AuctionCreated(
        uint256 indexed _id,
        address indexed _seller,
        uint256 _tokenId,
        uint256 _price,
        uint256 _startTime,
        uint256 _endTime
    );
    event Bid(
        uint256 indexed _id,
        address indexed _bidder,
        uint256 indexed _tokenId,
        uint256 _price,
        uint256 _time
    );
    event AuctionCancelled(
        uint256 indexed _id,
        address indexed _seller,
        uint256 _tokenId,
        uint256 _time
    );
    event BidCancelled(
        address indexed _bidder,
        uint256 indexed _auctionId,
        uint256 _tokenId,
        uint256 _amount,
        uint256 _time
    );
    event OfferCancelled(
        address indexed _offerer,
        uint256 _saleId,
        uint256 _tokenId,
        uint256 _amount,
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
        uint256 indexed _saleId,
        address indexed _offerer,
        uint256 _tokenId,
        uint256 _price,
        uint256 _time
    );
    event OfferReceived(
        uint256 indexed _saleId,
        address indexed _buyer,
        uint256 _tokenId,
        address _seller,
        uint256 _price,
        uint256 _time
    );
    event AuctionClaimed(
        uint256 indexed _id,
        address indexed _buyer,
        uint256 _tokenId,
        uint256 _price,
        uint256 _time
    );
    event OfferClaimed(
        address indexed _buyer,
        uint256 indexed _saleId,
        uint256 _tokenId,
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

    /// @dev Contract owner set the cancelbid fee percent.
    /// @param _tokenFee - Token fee.
    function setCancelBidFee(uint256 _tokenFee) public onlyOwner {
        cancel_bid_fee = _tokenFee;
    }

    /// @dev Contract owner set the canceloffer fee percent.
    /// @param _tokenFee - Token fee.
    function setCancelOfferFee(uint256 _tokenFee) public onlyOwner {
        cancel_offer_fee = _tokenFee;
    }

    /// @dev Contract owner enables and disable the sell token service fee.
    function sellServiceFee() public onlyOwner {
        sell_service_fee = !sell_service_fee;
    }

    /// @dev Contract owner enables and disable the auction token service fee.
    function auctionServiceFee() public onlyOwner {
        auction_service_fee = !auction_service_fee;
    }

    /// @dev Contract owner enables and disable the cancel bid.
    function cancelBidEnable() public onlyOwner{
        cancel_bid_enable = !cancel_bid_enable;
    }

    /// @dev Contract owner enables and disable the cancel offer.
    function cancelOfferEnable() public onlyOwner{
        cancel_offer_enable = !cancel_offer_enable;
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
        require(
            _price > 0,
            "Price must be greater than zero"
        );
        currentAuctionId++;
        AuctionDetails memory auctionToken;
        auctionToken = AuctionDetails({
            id: currentAuctionId,
            price: _price,
            startTime: _startTime,
            endTime: _endTime,
            highestBidder: address(0),
            highestBid: 0,
            totalBids: 0
        });
        EnumerableMap.set(auctionId, _tokenId, msg.sender);
        auction[_tokenId] = auctionToken;
        auctionTokenIds[msg.sender].push(_tokenId);
        nft_token.transferFrom(msg.sender, address(this), _tokenId);
        emit AuctionCreated(currentAuctionId, msg.sender, _tokenId, _price, _startTime, _endTime);
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
        require(msg.sender != EnumerableMap.get(auctionId, _tokenId), "Owner can't bid in auction");
        // The first bid, ensure it's >= the reserve price.
        if(_amount < pending_claim_auction[msg.sender][_tokenId]){
            _amount = pending_claim_auction[msg.sender][_tokenId];
        }
        require(
             _amount >= auction[_tokenId].price,
            "Bid must be at least the reserve price"
        );
        // Bid must be greater than last bid.
        require(_amount > auction[_tokenId].highestBid, "Bid amount too low");
        token.transferFrom(msg.sender, address(this), _amount - pending_claim_auction[msg.sender][_tokenId]);
       
        if(auction[_tokenId].highestBidder == msg.sender){
            auction[_tokenId].highestBidder = bid_info[msg.sender][_tokenId].prevBidder;
            auction[_tokenId].totalBids--;
        }else{
            if(bid_info[msg.sender][_tokenId].prevBidder == address(0)){
                bid_info[bid_info[msg.sender][_tokenId].nextBidder][_tokenId].prevBidder = address(0);
            }else{
                bid_info[bid_info[msg.sender][_tokenId].prevBidder][_tokenId].nextBidder = bid_info[msg.sender][_tokenId].nextBidder;
                bid_info[bid_info[msg.sender][_tokenId].nextBidder][_tokenId].prevBidder = bid_info[msg.sender][_tokenId].prevBidder;
            }
        }
        delete bid_info[msg.sender][_tokenId];
        
        pending_claim_auction[msg.sender][_tokenId] = _amount;        
        BidDetails memory bidInfo;
        bidInfo = BidDetails({
            prevBidder : auction[_tokenId].highestBidder,
            nextBidder : address(0),
            amount     : _amount,
            time       : block.timestamp
        });
        if(bid_info[auction[_tokenId].highestBidder][_tokenId].nextBidder == address(0)){
            bid_info[auction[_tokenId].highestBidder][_tokenId].nextBidder = msg.sender;
        }       
        bid_info[msg.sender][_tokenId] = bidInfo;
        pending_claim_auction[msg.sender][_tokenId] = _amount;
        auction[_tokenId].highestBidder = msg.sender;
        auction[_tokenId].highestBid = _amount;
        auction[_tokenId].totalBids++;
        emit Bid(auction[_tokenId].id, msg.sender, _tokenId, _amount, block.timestamp);
    }

    /// @dev Removes the bid from an auction.
    /// Transfer the bid amount to owner.
    /// @param _tokenId - ID of NFT on auction.
    function cancelBid(uint256 _tokenId) public {
        require(cancel_bid_enable, "You can't cancel the bid");
        if(auction[_tokenId].highestBidder == msg.sender){
            auction[_tokenId].highestBidder = bid_info[msg.sender][_tokenId].prevBidder;
            auction[_tokenId].highestBid    = bid_info[bid_info[msg.sender][_tokenId].prevBidder][_tokenId].amount;
        }else{
            if(bid_info[msg.sender][_tokenId].prevBidder == address(0)){
                bid_info[bid_info[msg.sender][_tokenId].nextBidder][_tokenId].prevBidder = address(0);
            }else{
                bid_info[bid_info[msg.sender][_tokenId].prevBidder][_tokenId].nextBidder = bid_info[msg.sender][_tokenId].nextBidder;
                bid_info[bid_info[msg.sender][_tokenId].nextBidder][_tokenId].prevBidder = bid_info[msg.sender][_tokenId].prevBidder;
            }
        }
        delete bid_info[msg.sender][_tokenId];
        auction[_tokenId].totalBids--;
        emit BidCancelled(msg.sender, auction[_tokenId].id, _tokenId, pending_claim_auction[msg.sender][_tokenId] - (pending_claim_auction[msg.sender][_tokenId] * (cancel_bid_fee / 100)), block.timestamp);
        token.transfer(msg.sender, pending_claim_auction[msg.sender][_tokenId] - (pending_claim_auction[msg.sender][_tokenId] * (cancel_bid_fee / 100)));       
        pending_claim_auction[msg.sender][_tokenId] = 0;        
    }

    /// @dev Cancel the Offer.
    /// Transfer the offer amount to owner.
    /// @param _tokenId - ID of NFT on sell.
    function cancelOffer(uint256 _tokenId) public {
        require(cancel_offer_enable, "You can't cancel the offer");
        if(offer[_tokenId].offerer == msg.sender){
            offer[_tokenId].offerer = offer_info[msg.sender][_tokenId].prevOfferer;
            offer[_tokenId].price   = offer_info[offer_info[msg.sender][_tokenId].prevOfferer][_tokenId].price;
        }else{
            if(offer_info[msg.sender][_tokenId].prevOfferer == address(0)){
                offer_info[offer_info[msg.sender][_tokenId].offerer][_tokenId].prevOfferer = address(0);
            }else{
                offer_info[offer_info[msg.sender][_tokenId].prevOfferer][_tokenId].offerer = offer_info[msg.sender][_tokenId].offerer;
                offer_info[offer_info[msg.sender][_tokenId].offerer][_tokenId].prevOfferer = offer_info[msg.sender][_tokenId].prevOfferer;
            }
        }
        delete offer_info[msg.sender][_tokenId];
        emit OfferCancelled(msg.sender, tokenIdToSaleId[_tokenId], _tokenId, pending_claim_offer[msg.sender][_tokenId] - (pending_claim_offer[msg.sender][_tokenId] * (cancel_offer_fee / 100)), block.timestamp);
        token.transfer(msg.sender, pending_claim_offer[msg.sender][_tokenId] - (pending_claim_offer[msg.sender][_tokenId] * (cancel_offer_fee / 100)));       
        pending_claim_offer[msg.sender][_tokenId] = 0;        
    }

    /// @dev Offer on an sell.
    /// @param _tokenId - ID of token to offer on.
    /// @param _amount  - Offerer set the price (in token) of NFT token.
    function makeOffer(uint256 _tokenId, uint256 _amount) public {             
        require(
            EnumerableMap.get(saleId, _tokenId) != address(0) && token_price[_tokenId] > 0,
            "Token not for sell"
        );
        require(msg.sender != EnumerableMap.get(saleId, _tokenId), "Owner can't make the offer");
        if(_amount < pending_claim_offer[msg.sender][_tokenId]){
            _amount = pending_claim_offer[msg.sender][_tokenId];
        }
        // Offer must be greater than last offer.
        require(
            _amount > offer[_tokenId].price,
            "Offer amount less then already offerred"
        );
        token.transferFrom(msg.sender, address(this), _amount - pending_claim_offer[msg.sender][_tokenId]);
        if(offer[_tokenId].offerer == msg.sender){
            offer[_tokenId].offerer = offer_info[msg.sender][_tokenId].prevOfferer;
        }else{
            if(offer_info[msg.sender][_tokenId].prevOfferer == address(0)){
                offer_info[offer_info[msg.sender][_tokenId].offerer][_tokenId].prevOfferer = address(0);
            }else{
                offer_info[offer_info[msg.sender][_tokenId].prevOfferer][_tokenId].offerer = offer_info[msg.sender][_tokenId].offerer;
                offer_info[offer_info[msg.sender][_tokenId].offerer][_tokenId].prevOfferer = offer_info[msg.sender][_tokenId].prevOfferer;
            }
        }
        delete offer_info[msg.sender][_tokenId];       
        OfferDetails memory offerInfo;
        offerInfo = OfferDetails({
            prevOfferer : offer[_tokenId].offerer,
            offerer     : address(0),
            price       : _amount,
            time        : block.timestamp
        });
        if(offer_info[offer[_tokenId].offerer][_tokenId].offerer == address(0)){
            offer_info[offer[_tokenId].offerer][_tokenId].offerer = msg.sender;
        }       
        offer_info[msg.sender][_tokenId] = offerInfo;
        pending_claim_offer[msg.sender][_tokenId] = _amount;
        offer[_tokenId].prevOfferer = offer[_tokenId].offerer;
        offer[_tokenId].offerer = msg.sender;
        offer[_tokenId].price = _amount;
        emit OfferMaked(tokenIdToSaleId[_tokenId], msg.sender, _tokenId, _amount, block.timestamp);
    }

    /// @dev Receive offer from open sell.
    /// Transfer NFT ownership to offerer address.
    /// @param _tokenId - ID of NFT on offer.
    function reciveOffer(uint256 _tokenId) public {
        require(msg.sender ==  EnumerableMap.get(saleId, _tokenId), "You are not owner");
        nft_token.transferFrom(
            address(this),
            offer[_tokenId].offerer,
            _tokenId
        );
        if(sell_service_fee == true){   
            token.transfer(
                beneficiary,
                ((offer[_tokenId].price * sell_token_fee) / 100)
            );
            emit SellFee(
                tokenIdToSaleId[_tokenId],
                _tokenId,
                ((offer[_tokenId].price * sell_token_fee) / 100),
                block.timestamp
            );
            token.transfer(
                EnumerableMap.get(saleId, _tokenId),
                ((offer[_tokenId].price * (100 - sell_token_fee)) / 100)
            );
        }else{
            token.transfer(
                EnumerableMap.get(saleId, _tokenId),
                offer[_tokenId].price
            );
        }
        for(uint256 i = 0; i < saleTokenIds[msg.sender].length; i++){
            if(saleTokenIds[msg.sender][i] == _tokenId){
                saleTokenIds[msg.sender][i] = saleTokenIds[msg.sender][saleTokenIds[msg.sender].length-1];
                delete saleTokenIds[msg.sender][saleTokenIds[msg.sender].length-1];
                break;
            }
        }
        delete token_price[_tokenId];       
        EnumerableMap.remove(saleId, _tokenId);
        pending_claim_offer[offer[_tokenId].offerer][_tokenId] = 0;
        emit OfferReceived(
            tokenIdToSaleId[_tokenId],
            offer[_tokenId].offerer,
            _tokenId,
            msg.sender,
            offer[_tokenId].price,
            block.timestamp
        );
        delete offer_info[offer[_tokenId].offerer][_tokenId];
        delete offer[_tokenId];
        delete tokenIdToSaleId[_tokenId];       
    }
    

    /// @dev Create claim after auction ends.
    /// Transfer NFT to auction winner address.
    /// Seller and Bidders (not win in auction) Withdraw their funds.
    /// @param _tokenId - ID of NFT.
    function auctionClaim(uint256 _tokenId) public {
        require(
           auction[_tokenId].endTime < block.timestamp,
            "auction not compeleted yet"
        );
        require(
            auction[_tokenId].highestBidder == msg.sender || msg.sender == EnumerableMap.get(auctionId, _tokenId) || msg.sender == owner(),
            "You are not highest Bidder or owner"
        );
        
        if(auction_service_fee == true){
            token.transfer(
                beneficiary,
                ((auction[_tokenId].highestBid * auction_token_fee) / 100)
            );
            emit AuctionFee(auction[_tokenId].id, _tokenId, ((auction[_tokenId].highestBid * auction_token_fee) / 100), block.timestamp);
            token.transfer(
                EnumerableMap.get(auctionId, _tokenId),
                ((auction[_tokenId].highestBid * (100 - auction_token_fee)) /
                    100)
            );
        }else{
            token.transfer(
                EnumerableMap.get(auctionId, _tokenId),
                auction[_tokenId].highestBid
            );
        }
        pending_claim_auction[auction[_tokenId].highestBidder][_tokenId] = 0;
        nft_token.transferFrom(address(this), auction[_tokenId].highestBidder, _tokenId);          
        emit AuctionClaimed(auction[_tokenId].id, msg.sender, _tokenId, auction[_tokenId].highestBid, block.timestamp);
        for(uint256 i = 0; i < auctionTokenIds[msg.sender].length; i++){
            if(auctionTokenIds[msg.sender][i] == _tokenId){
                auctionTokenIds[msg.sender][i] = auctionTokenIds[msg.sender][auctionTokenIds[msg.sender].length-1];
                delete auctionTokenIds[msg.sender][auctionTokenIds[msg.sender].length-1];
                break;
            }
        }
        delete auction[_tokenId];
        EnumerableMap.remove(auctionId, _tokenId);      
    }

    /// @dev Create claim after auction claim.
    /// bidders (not win in auction) Withdraw their funds.
    /// @param _tokenId - ID of NFT.
    function auctionPendingClaim(uint256 _tokenId) public {
        require(auction[_tokenId].highestBidder != msg.sender && auction[_tokenId].endTime < block.timestamp, "Your auction is running");
        require(pending_claim_auction[msg.sender][_tokenId] != 0, "You are not a bidder or already claimed");
        token.transfer(msg.sender, pending_claim_auction[msg.sender][_tokenId]);
        emit AuctionClaimed(0, msg.sender, _tokenId, pending_claim_auction[msg.sender][_tokenId], block.timestamp);
        delete bid_info[msg.sender][_tokenId];
        pending_claim_auction[msg.sender][_tokenId] = 0;
    }

    /// @dev Create claim after offer claim.
    /// Offerers (not win in offer) Withdraw their funds.
    /// @param _tokenId - ID of NFT.
    function offerClaim(uint256 _tokenId) public {
        require(offer[_tokenId].offerer != msg.sender, "Your offer is running");
        require(pending_claim_offer[msg.sender][_tokenId] != 0, "You are not a offerer or already claimed");
        token.transfer(msg.sender, pending_claim_offer[msg.sender][_tokenId]);       
        emit OfferClaimed(msg.sender, tokenIdToSaleId[_tokenId], _tokenId, pending_claim_offer[msg.sender][_tokenId], block.timestamp);
        delete offer_info[msg.sender][_tokenId];
        pending_claim_offer[msg.sender][_tokenId] = 0;
    }

    /// @dev Returns auction info for an NFT on auction.
    /// @param _tokenId - ID of NFT on auction.
    function getAuction(uint256 _tokenId)
        public
        view
        virtual
        returns (AuctionDetails memory)
    {
        return (auction[_tokenId]);
    }

    /// @dev Returns auction info for an NFT on auction.
    /// @param _tokenId - ID of NFT on auction.
    function getpending_claim_auction(address _user, uint256 _tokenId)
        public
        view
        virtual
        returns (uint256)
    {
        return pending_claim_auction[_user][_tokenId];
    }

    /// @dev Returns offer info for an NFT on offer.
    /// @param _tokenId - ID of NFT on offer.
    function getpending_claim_offer(address _user, uint256 _tokenId)
        public
        view
        virtual
        returns (uint256)
    {
        return pending_claim_offer[_user][_tokenId];
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
    function buyFromFiat(uint256 _tokenId, uint256 _amount, address _to) public payable {
        require(msg.sender != EnumerableMap.get(saleId, _tokenId), "Owner can't buy");
        require(
            EnumerableMap.get(saleId, _tokenId) != address(0) && token_price[_tokenId] > 0,
            "Token not for sell"
        );
        require(_amount >= token_price[_tokenId], "Your amount is less");
        nft_token.transferFrom(address(this), _to, _tokenId);
        if(sell_service_fee == true){
            token.transferFrom(
                msg.sender,
                beneficiary,
                ((_amount * sell_token_fee) / 100)
            );
            emit SellFee(
                tokenIdToSaleId[_tokenId],
                _tokenId,
                ((offer[_tokenId].price * sell_token_fee) / 100),
                block.timestamp
            );
            token.transferFrom(
                msg.sender,
                EnumerableMap.get(saleId, _tokenId),
                ((_amount * (100 - sell_token_fee)) / 100)
            );   
        }else{
            // token.transferFrom(
            //     msg.sender,
            //     EnumerableMap.get(saleId, _tokenId),
            //     _amount 
            // );  
        }  
        emit Buy(
            tokenIdToSaleId[_tokenId],
            msg.sender,
            _tokenId,
            EnumerableMap.get(saleId, _tokenId),
            _amount,
            block.timestamp
        );
        delete token_price[_tokenId];
        delete tokenIdToSaleId[_tokenId];
        delete offer[_tokenId];
        for(uint256 i = 0; i < saleTokenIds[msg.sender].length; i++){
            if(saleTokenIds[msg.sender][i] == _tokenId){
                saleTokenIds[msg.sender][i] = saleTokenIds[msg.sender][saleTokenIds[msg.sender].length-1];
                delete saleTokenIds[msg.sender][saleTokenIds[msg.sender].length-1];
                break;
            }
        }
        EnumerableMap.remove(saleId, _tokenId);      
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
        require(
            _price > 0,
            "Price must be greater than zero"
        );
        token_price[_tokenId] = _price;
        currentSaleId++;
        tokenIdToSaleId[_tokenId] = currentSaleId;
        EnumerableMap.set(saleId, _tokenId, msg.sender);
        saleTokenIds[msg.sender].push(_tokenId);
        nft_token.transferFrom(msg.sender, address(this), _tokenId);
        emit Sell(currentSaleId, msg.sender, _tokenId, _price, block.timestamp);
    }

    /// @dev Removes token from the list of open sell.
    /// Returns the NFT to original owner.
    /// @param _tokenId - ID of NFT on sell.
    function cancelSell(uint256 _tokenId) public {
        require(msg.sender ==  EnumerableMap.get(saleId, _tokenId) || msg.sender == owner(), "You are not owner");
        require(token_price[_tokenId] > 0, "Can't cancel the sell");
        nft_token.transferFrom(address(this), EnumerableMap.get(saleId, _tokenId), _tokenId);
        delete token_price[_tokenId];
        currentSaleId--;
        for(uint256 i = 0; i < saleTokenIds[EnumerableMap.get(saleId, _tokenId)].length; i++){
            if(saleTokenIds[EnumerableMap.get(saleId, _tokenId)][i] == _tokenId){
                saleTokenIds[EnumerableMap.get(saleId, _tokenId)][i] = saleTokenIds[EnumerableMap.get(saleId, _tokenId)][saleTokenIds[EnumerableMap.get(saleId, _tokenId)].length-1];
                delete saleTokenIds[EnumerableMap.get(saleId, _tokenId)][saleTokenIds[EnumerableMap.get(saleId, _tokenId)].length-1];
                break;
            }
        }
        EnumerableMap.remove(saleId, _tokenId);      
        emit SellCancelled(tokenIdToSaleId[_tokenId], msg.sender, _tokenId, block.timestamp);
        delete tokenIdToSaleId[_tokenId];
    }

    /// @dev Removes an auction from the list of open auctions.
    /// Returns the NFT to original owner.
    /// @param _tokenId - ID of NFT on auction.
    function cancelAuction(uint256 _tokenId) public {
        require(msg.sender ==  EnumerableMap.get(auctionId, _tokenId) || msg.sender == owner(), "You are not owner");
        nft_token.transferFrom(address(this), EnumerableMap.get(auctionId, _tokenId), _tokenId);
        for(uint256 i = 0; i < auctionTokenIds[EnumerableMap.get(auctionId, _tokenId)].length; i++){
            if(auctionTokenIds[EnumerableMap.get(auctionId, _tokenId)][i] == _tokenId){
                auctionTokenIds[EnumerableMap.get(auctionId, _tokenId)][i] = auctionTokenIds[EnumerableMap.get(auctionId, _tokenId)][auctionTokenIds[EnumerableMap.get(auctionId, _tokenId)].length-1];
                delete auctionTokenIds[EnumerableMap.get(auctionId, _tokenId)][auctionTokenIds[EnumerableMap.get(auctionId, _tokenId)].length-1];
                break;
            }
        }
        EnumerableMap.remove(auctionId, _tokenId);
        emit AuctionCancelled(auction[_tokenId].id, msg.sender, _tokenId, block.timestamp);
        delete auction[_tokenId];
    }

    /// @dev Returns the user sell token Ids.
    function getSaleTokenId(address _user) public view returns(uint256[] memory){
        return saleTokenIds[_user];
    }

    /// @dev Returns the user auction token Ids.
    function getAuctionTokenId(address _user) public view returns(uint256[] memory){
        return auctionTokenIds[_user];
    }

    /// @dev Returns the user deal token Ids
    function getDealTokenId(address _user) public view returns(uint256[] memory){
        return dealTokenIds[_user];
    }

    /// @dev Returns the total deal length.
    function totalDeal() public view returns (uint256){
        return EnumerableMap.length(dealId);
    }

    /// @dev Returns the total sale length.
    function totalSale() public view returns (uint256){
        return EnumerableMap.length(saleId);
    }

    /// @dev Returns the total auction length.
    function totalAuction() public view returns (uint256){
        return EnumerableMap.length(auctionId);
    }

    /// @dev Returns the offer details, seller address ,token Id and price.
    /// @param index - Index of NFT on sale.
    function saleDetails(uint256 index) public view returns (OfferDetails memory offerInfo, address seller, uint256 tokenId, uint256 price){
        (uint256 id,) = EnumerableMap.at(saleId, index);
        return (offer[id], EnumerableMap.get(saleId, id), id, token_price[id]);
    }

    /// @dev Returns the auction details and token Id.
    /// @param index - Index of NFT on auction.
    function auctionDetails(uint256 index) public view returns (AuctionDetails memory auctionInfo, uint256 tokenId){
        (uint256 id,) =  EnumerableMap.at(auctionId, index);        
        return (auction[id], id);
    }

    /// @dev Returns sale and offer details on the basis of tokenId.
    /// @param tokenId - Id of NFT on sale.
    function saleDetailsByTokenId(uint256 tokenId) public view returns (OfferDetails memory offerInfo, address seller, uint256 price){             
        return (offer[tokenId], EnumerableMap.get(saleId, tokenId), token_price[tokenId]);
    }

    /// @dev Returns deal details on the basis of tokenId.
    /// @param tokenId - Id of NFT on deal.
    function dealDetailsByTokenId(uint256 tokenId) public view returns (DealDetails memory dealInfo){             
        return (deal[tokenId]);
    }

    /// @dev Returns all auction details.
    function getAllAuctionInfo() public view returns (AuctionDetails[] memory) {
        AuctionDetails[] memory auctionInfo = new AuctionDetails[](EnumerableMap.length(auctionId));
        for(uint256 i = 0; i < EnumerableMap.length(auctionId); i++){
            (uint256 id,) =  EnumerableMap.at(auctionId, i);  
            auctionInfo [i] = (auction[id]);
        }
        return auctionInfo;
    }


    /// @dev Returns all sale details.
    function getAllSaleInfo() public view returns(OfferDetails[] memory, address[] memory seller, uint256[] memory price, uint256[] memory tokenIds){
        OfferDetails[] memory offerInfo = new OfferDetails[](EnumerableMap.length(saleId));
        for(uint256 i = 0; i < EnumerableMap.length(saleId); i++){
            (uint256 id,) =  EnumerableMap.at(saleId, i);  
            offerInfo [i] = (offer[id]);
            seller[i] = EnumerableMap.get(saleId, id);
            price[i] =  token_price[id];
            tokenIds[i] = id;
        }
        return (offerInfo, seller, price, tokenIds);
    }

    /// @dev Returns string for token place in which market.
    /// @param tokenId - Id of NFT.
    function checkMarket(uint256 tokenId) public view returns(string memory){
        if(auction[tokenId].price > 0){
            return "Auction";
        }else if(deal[tokenId].price > 0){
            return "Deal";
        }else if(token_price[tokenId] > 0){
            return "Sale";
        }else{
            return "Not in market";
        }
    }

    function getCancelBidEnabled() public view returns(bool){
        return cancel_bid_enable;
    }

    function getCancelOfferEnabled() public view returns(bool){
        return cancel_offer_enable;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "././Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)
pragma solidity ^0.8.0;

import "././IERC165.sol";

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableMap.sol)

pragma solidity ^0.8.0;

import "./EnumerableSet.sol";

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * The following map types are supported:
 *
 * - `uint256 -> address` (`UintToAddressMap`) since v3.0.0
 * - `address -> uint256` (`AddressToUintMap`) since v4.6.0
 */
library EnumerableMap {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct Map {
        // Storage of keys
        EnumerableSet.Bytes32Set _keys;
        mapping(bytes32 => bytes32) _values;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(
        Map storage map,
        bytes32 key,
        bytes32 value
    ) private returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._keys.length();
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        bytes32 key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function _tryGet(Map storage map, bytes32 key) private view returns (bool, bytes32) {
        bytes32 value = map._values[key];
        if (value == bytes32(0)) {
            return (_contains(map, key), bytes32(0));
        } else {
            return (true, value);
        }
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || _contains(map, key), "EnumerableMap: nonexistent key");
        return value;
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function _get(
        Map storage map,
        bytes32 key,
        string memory errorMessage
    ) private view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || _contains(map, key), errorMessage);
        return value;
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToAddressMap storage map,
        uint256 key,
        address value
    ) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = _tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToAddressMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key), errorMessage))));
    }

    // AddressToUintMap

    struct AddressToUintMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        AddressToUintMap storage map,
        address key,
        uint256 value
    ) internal returns (bool) {
        return _set(map._inner, bytes32(uint256(uint160(key))), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(AddressToUintMap storage map, address key) internal returns (bool) {
        return _remove(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(AddressToUintMap storage map, address key) internal view returns (bool) {
        return _contains(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(AddressToUintMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressToUintMap storage map, uint256 index) internal view returns (address, uint256) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (address(uint160(uint256(key))), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(AddressToUintMap storage map, address key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = _tryGet(map._inner, bytes32(uint256(uint160(key))));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(AddressToUintMap storage map, address key) internal view returns (uint256) {
        return uint256(_get(map._inner, bytes32(uint256(uint160(key)))));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}