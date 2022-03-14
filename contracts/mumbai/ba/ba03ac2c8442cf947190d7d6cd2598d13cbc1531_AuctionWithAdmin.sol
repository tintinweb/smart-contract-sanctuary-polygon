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
    // Mapping from token ID to token price
    mapping(uint256 => uint256) private token_price;

    mapping(address => uint256[]) private saleTokenIds;
    mapping(address => uint256[]) private auctionTokenIds;
    mapping(address => uint256[]) private dealTokenIds;

    uint256 private curr_sale_id;
    uint256 private curr_auction_id;
    uint256 private curr_deal_id;

    uint256 private sell_token_fee;
    uint256 private auction_token_fee;

    bool private sell_service_fee = false;
    bool private auction_service_fee = false;

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
        uint256 indexed _tokenId,
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

    event AuctionClaimed(
        address indexed _buyer,
        uint256 _tokenId,
        uint256 _price,
        uint256 _time
    );

    event OfferClaimed(
        address indexed _buyer,
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

    /// @dev Returns the nft token contract address.
    function getNFTToken() public view returns (IERC721) {
        return nft_token;
    }

    /// @dev Returns the token contract address.
    function getToken() public view returns (IERC20) {
        return token;
    }

    /// @dev Returns the sell token fee percent
    function getTokenFeePercentForSell()  public view returns (uint256){
        return sell_token_fee;
    }

    /// @dev Returns the auction token fee percent
    function getTokenFeePercentForAuction()  public view returns (uint256){
        return auction_token_fee;
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

    /// @dev Contract owner enables and disable the sell token service fee.
    function sellServiceFee() public onlyOwner {
        sell_service_fee = !sell_service_fee;
    }

    /// @dev Contract owner enables and disable the auction token service fee.
    function auctionServiceFee() public onlyOwner {
        auction_service_fee = !auction_service_fee;
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
        AuctionDetails memory auctionToken;
        auctionToken = AuctionDetails({
            price: _price,
            startTime: _startTime,
            endTime: _endTime,
            highestBidder: address(0),
            highestBid: 0,
            totalBids: 0
        });
        curr_auction_id++;
        EnumerableMap.set(auctionId, _tokenId, msg.sender);
        auction[_tokenId] = auctionToken;
        auctionTokenIds[msg.sender].push(_tokenId);
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
        require(
            _price > 0,
            "Price must be greater than zero"
        );

        DealDetails memory dealToken;
        dealToken = DealDetails({
            price: _price,
            startTime: _startTime,
            endTime: _endTime
        });
        curr_deal_id++;
        deal[_tokenId] = dealToken;
        dealTokenIds[msg.sender].push(_tokenId);
        EnumerableMap.set(dealId, _tokenId, msg.sender);
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
            EnumerableMap.get(dealId, _tokenId)!= address(0) && deal[_tokenId].price > 0,
            "Token not for deal"
        );
        require(_amount >= deal[_tokenId].price, "Your amount is less");
        nft_token.transferFrom(address(this), msg.sender, _tokenId);
        if(sell_service_fee == true){       
            token.transferFrom(
                msg.sender,
                beneficiary,
                ((_amount * sell_token_fee) / 100)
            );
            token.transferFrom(
                msg.sender,
                EnumerableMap.get(dealId, _tokenId),
                ((_amount * (100 - sell_token_fee)) / 100)
            );
        }else{
           token.transferFrom(
                msg.sender,
                EnumerableMap.get(dealId, _tokenId),
                _amount
            ); 
        }
        emit BuyDeal(
            msg.sender,
            _tokenId,
            EnumerableMap.get(dealId, _tokenId),
            _amount,
            block.timestamp
        );
        delete deal[_tokenId];
        for(uint256 i = 0; i < dealTokenIds[msg.sender].length; i++){
            if(dealTokenIds[msg.sender][i] == _tokenId){
                dealTokenIds[msg.sender][i] = dealTokenIds[msg.sender][dealTokenIds[msg.sender].length-1];
                delete dealTokenIds[msg.sender][dealTokenIds[msg.sender].length-1];
                break;
            }
        }
        EnumerableMap.remove(dealId, _tokenId);
    }

    /// @dev Removes an deal from the list of open deals.
    /// Returns the NFT to original owner.
    /// @param _tokenId - ID of NFT on deal.
    function cancelDeal(uint256 _tokenId) public {
        require(msg.sender == EnumerableMap.get(dealId, _tokenId) || msg.sender == owner(), "You are not owner");
        require(deal[_tokenId].price > 0, "Can't cancel this deal");
        nft_token.transferFrom(address(this), EnumerableMap.get(dealId, _tokenId), _tokenId);
        curr_deal_id--;
        delete deal[_tokenId];  
        for(uint256 i = 0; i < dealTokenIds[EnumerableMap.get(dealId, _tokenId)].length; i++){
            if(dealTokenIds[EnumerableMap.get(dealId, _tokenId)][i] == _tokenId){
                dealTokenIds[EnumerableMap.get(dealId, _tokenId)][i] = dealTokenIds[EnumerableMap.get(dealId, _tokenId)][dealTokenIds[EnumerableMap.get(dealId, _tokenId)].length-1];
                delete dealTokenIds[EnumerableMap.get(dealId, _tokenId)][dealTokenIds[EnumerableMap.get(dealId, _tokenId)].length-1];
                break;
            }
        }      
        EnumerableMap.remove(dealId, _tokenId);
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
        token.transferFrom(msg.sender, address(this), _amount - pending_claim_auction[msg.sender][_tokenId]);
        pending_claim_auction[msg.sender][_tokenId] += _amount;
        auction[_tokenId].highestBidder = msg.sender;
        auction[_tokenId].highestBid = _amount;
        auction[_tokenId].totalBids++;
        emit Bid(msg.sender, _tokenId, _amount, block.timestamp);
    }

    /// @dev Offer on an sell.
    /// @param _tokenId - ID of token to offer on.
    /// @param _amount  - Offerer set the price (in token) of NFT token.
    function makeOffer(uint256 _tokenId, uint256 _amount) public {
        require(
            EnumerableMap.get(saleId, _tokenId) != address(0) && token_price[_tokenId] > 0,
            "Token not for sell"
        );
        // Offer must be greater than last offer.
        require(
            _amount > offer[_tokenId].price,
            "Offer amount less then already offerred"
        );
        token.transferFrom(msg.sender, address(this), _amount);
        pending_claim_offer[msg.sender][_tokenId] += _amount;
        offer[_tokenId].offerer = msg.sender;
        offer[_tokenId].price = pending_claim_offer[msg.sender][_tokenId];
        emit OfferMaked(msg.sender, _tokenId, _amount, block.timestamp);
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
            offer[_tokenId].offerer,
            _tokenId,
            msg.sender,
            offer[_tokenId].price,
            block.timestamp
        );
        delete offer[_tokenId];
        
    }

    /// @dev Create claim after auction ends.
    /// Transfer NFT to auction winner address.
    /// Seller and Bidders (not win in auction) Withdraw their funds.
    /// @param _tokenId - ID of NFT.
    function auctionClaim(uint256 _tokenId) public {
        require(
            auction[_tokenId].highestBidder != msg.sender,
            "You are highest Bidder"
        );
        if (msg.sender == EnumerableMap.get(auctionId, _tokenId) || auction[_tokenId].highestBidder == msg.sender) {
            if(auction_service_fee == true){
                token.transfer(
                    beneficiary,
                    ((auction[_tokenId].highestBid * auction_token_fee) / 100)
                );
                token.transfer(
                    msg.sender,
                    ((auction[_tokenId].highestBid * (100 - auction_token_fee)) /
                        100)
                );
            }else{
                token.transfer(
                    msg.sender,
                    auction[_tokenId].highestBid
                );
            }
            pending_claim_auction[auction[_tokenId].highestBidder][_tokenId] = 0;
            nft_token.transferFrom(address(this), msg.sender, _tokenId);          
            emit AuctionClaimed(msg.sender, _tokenId, auction[_tokenId].highestBid, block.timestamp);
            for(uint256 i = 0; i < auctionTokenIds[msg.sender].length; i++){
                if(auctionTokenIds[msg.sender][i] == _tokenId){
                    auctionTokenIds[msg.sender][i] = auctionTokenIds[msg.sender][auctionTokenIds[msg.sender].length-1];
                    delete auctionTokenIds[msg.sender][auctionTokenIds[msg.sender].length-1];
                    break;
                }
            }
            delete auction[_tokenId];
            EnumerableMap.remove(auctionId, _tokenId);
        } else {
            token.transfer(msg.sender, pending_claim_auction[msg.sender][_tokenId]);
            emit AuctionClaimed(msg.sender, _tokenId, pending_claim_auction[msg.sender][_tokenId], block.timestamp);
            pending_claim_auction[msg.sender][_tokenId] = 0;
            
        }
    }

    /// @dev Create claim after offer claim.
    /// Seller and Bidders (not win in offer) Withdraw their funds.
    /// @param _tokenId - ID of NFT.
    function offerClaim(uint256 _tokenId) public {
        require(offer[_tokenId].offerer != msg.sender, "Your offer is running");
        token.transfer(msg.sender, pending_claim_offer[msg.sender][_tokenId]);       
        emit OfferClaimed(msg.sender, _tokenId, pending_claim_offer[msg.sender][_tokenId], block.timestamp);
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
        return auction[_tokenId];
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
            EnumerableMap.get(saleId, _tokenId) != address(0) && token_price[_tokenId] > 0,
            "Token not for sell"
        );
        require(_amount >= token_price[_tokenId], "Your amount is less");
        nft_token.transferFrom(address(this), msg.sender, _tokenId);
        if(sell_service_fee == true){
            token.transferFrom(
                msg.sender,
                beneficiary,
                ((_amount * sell_token_fee) / 100)
            );
            token.transferFrom(
                msg.sender,
                EnumerableMap.get(saleId, _tokenId),
                ((_amount * (100 - sell_token_fee)) / 100)
            );   
        }else{
            token.transferFrom(
                msg.sender,
                EnumerableMap.get(saleId, _tokenId),
                _amount 
            );  
        }  
        emit Buy(
            msg.sender,
            _tokenId,
            EnumerableMap.get(saleId, _tokenId),
            _amount,
            block.timestamp
        );
        delete token_price[_tokenId];
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
        curr_sale_id++;
        EnumerableMap.set(saleId, _tokenId, msg.sender);
        saleTokenIds[msg.sender].push(_tokenId);
        nft_token.transferFrom(msg.sender, address(this), _tokenId);
        emit Sell(msg.sender, _tokenId, _price, block.timestamp);
    }

    /// @dev Removes token from the list of open sell.
    /// Returns the NFT to original owner.
    /// @param _tokenId - ID of NFT on sell.
    function cancelSell(uint256 _tokenId) public {
        require(msg.sender ==  EnumerableMap.get(saleId, _tokenId) || msg.sender == owner(), "You are not owner");
        require(token_price[_tokenId] > 0, "Can't cancel the sell");
        nft_token.transferFrom(address(this), EnumerableMap.get(saleId, _tokenId), _tokenId);
        curr_sale_id--;
        delete token_price[_tokenId];
        for(uint256 i = 0; i < saleTokenIds[EnumerableMap.get(saleId, _tokenId)].length; i++){
            if(saleTokenIds[EnumerableMap.get(saleId, _tokenId)][i] == _tokenId){
                saleTokenIds[EnumerableMap.get(saleId, _tokenId)][i] = saleTokenIds[EnumerableMap.get(saleId, _tokenId)][saleTokenIds[EnumerableMap.get(saleId, _tokenId)].length-1];
                delete saleTokenIds[EnumerableMap.get(saleId, _tokenId)][saleTokenIds[EnumerableMap.get(saleId, _tokenId)].length-1];
                break;
            }
        }
        EnumerableMap.remove(saleId, _tokenId);      
        emit SellCancelled(msg.sender, _tokenId, block.timestamp);
    }

    /// @dev Removes an auction from the list of open auctions.
    /// Returns the NFT to original owner.
    /// @param _tokenId - ID of NFT on auction.
    function cancelAuction(uint256 _tokenId) public {
        require(msg.sender ==  EnumerableMap.get(auctionId, _tokenId) || msg.sender == owner(), "You are not owner");
        require(
            auction[_tokenId].endTime > block.timestamp,
            "Can't cancel this auction"
        );
        nft_token.transferFrom(address(this), EnumerableMap.get(auctionId, _tokenId), _tokenId);
        delete auction[_tokenId];
        curr_auction_id--;
        for(uint256 i = 0; i < auctionTokenIds[EnumerableMap.get(auctionId, _tokenId)].length; i++){
            if(auctionTokenIds[EnumerableMap.get(auctionId, _tokenId)][i] == _tokenId){
                auctionTokenIds[EnumerableMap.get(auctionId, _tokenId)][i] = auctionTokenIds[EnumerableMap.get(auctionId, _tokenId)][auctionTokenIds[EnumerableMap.get(auctionId, _tokenId)].length-1];
                delete auctionTokenIds[EnumerableMap.get(auctionId, _tokenId)][auctionTokenIds[EnumerableMap.get(auctionId, _tokenId)].length-1];
                break;
            }
        }
        EnumerableMap.remove(auctionId, _tokenId);
        emit AuctionCancelled(msg.sender, _tokenId, block.timestamp);
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

    /// @dev Returns the current sale id.
    function currentSaleId() public view returns (uint256){
        return curr_sale_id;
    }

    /// @dev Returns the current auction id.
    function currentAuctionId() public view returns (uint256){
        return curr_auction_id;
    }

    /// @dev Returns the current deal id.
    function currentDealId() public view returns (uint256){
        return curr_deal_id;
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

    /// @dev Returns the deal details and token Id.
    /// @param index - Index of NFT on deal.
    function dealDetails(uint256 index) public view returns (DealDetails memory dealInfo, uint256 tokenId){
        (uint256 id,) = EnumerableMap.at(dealId, index);
        return (deal[id], id);
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
        return deal[tokenId];
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

    /// @dev Returns all deal details.
    function getAllDealInfo() public view returns (DealDetails[] memory) {
        DealDetails[] memory dealInfo = new DealDetails[](EnumerableMap.length(dealId));
        for(uint256 i = 0; i < EnumerableMap.length(dealId); i++){
            (uint256 id,) =  EnumerableMap.at(dealId, i);  
            dealInfo [i] = (deal[id]);
        }
        return dealInfo;
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

}