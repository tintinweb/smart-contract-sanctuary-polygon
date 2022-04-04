// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// only for debugging
// import "hardhat/console.sol";

// TODO:
// commenting the contracts
// writing the testcases
// for erc721 approval is given to swap/marketplace contract -------------------------------
// for erc20 approval is given to escrow ---------------------------------------------------
// for trade and auction user have to claim usdt but not for swapping ----------------------
// swapping fees

/**
 * @title Marketplace contract for the NFT
 * @author Kartik Jain
 * @notice User can trade, swap and start the auction for NFT
 */
interface IMarketplace {

    enum SaleType { Trade, Swap, Auction }

    struct Sell {
        uint256 listId;          // ID for the marketplace listing
        uint256 tokenId;         // ID for the ERC721 token
        address tokenContract;   // Address for the ERC721 contract
        uint256 price;           // The price of the token
        address tokenOwner;      // The address that put the NFT on marketplace. It also receives the funds once the NFT is sold.
        bool usdt;               // The bool value to check the currency matic/usdt
    }


    struct ListedToken {
        uint256 saleId;         // ID of the swap or trade
        SaleType saleType;      // enum to define if it is trade or swap
    }

    struct Auction {
        uint256 listId;             // ID for the marketplace listing
        uint256 tokenId;            // ID for the ERC721 token
        address tokenContract;      // Address for the ERC721 contract
        uint256 startTime;          // The time at which the auction is started
        uint256 endTime;            // The time at which the auction will end
        uint256 basePrice;          // The minimum price of the NFT in the auction
        uint256 reservePrice;       // The reserve price of the NFT in the auction
        address tokenOwner;         // The address that should receive the funds once the NFT is sold.
        uint256 incrementalBid;     // The minimum amount of increment in amount for every successive bid.
        address highestBidder;
        uint256 bidAmount;
    }

    event SaleCreated(uint256 indexed saleId, uint256 indexed listId, uint256 amount, bool currency);

    event ListCreated(uint256 indexed listId, SaleType _type);

    event Claim(address indexed recepient, uint256 maticAmount, uint256 usdtAmount);

    event CancelTrade(uint256 indexed orderId);

    event CancelSwap(uint256 indexed swapId);

    event SwapCreated(uint256 indexed swapId, uint256 tokenId, address tokenContract, uint256 time);

    event Unlist(uint256 indexed listId);

    event TradePriceUpdated(uint256 indexed saleId, uint256 price, uint256 oldPrice);

    event OfferMade(
        uint256 indexed offerId, 
        uint256 indexed swapId, 
        uint256 tokenId, 
        address tokenContract, 
        uint exchangeValue, 
        bool usdt
    );

    event BuyOrder(uint256 indexed orderId, uint256 price, address indexed buyer);

    event Swapped(
        uint256 indexed swapId, 
        address originalContract, 
        uint256 originalId, 
        uint256 indexed offerId, 
        address swapContract, 
        uint256 swapTokenId
    );

    event CounterOffered(
        uint256 indexed offerId, 
        uint256 indexed counterOfferId, 
        address tokenContract, 
        uint256 tokenId, 
        uint exchangeValue
    );

    event AuctionCreated(
        uint256 indexed auctionId,
        uint256 indexed endTime,
        uint256 basePrice,
        uint256 reservePrice
    );

    event WhiteListed(address indexed whitelistedAddress, address indexed whiteLister);

    event TreasuryUpdated(address indexed oldAddress, address indexed newAddress);

    event AuctionFeeUpdated(uint indexed oldValue, uint indexed newValue);

    event TradeFeeUpdated(uint indexed oldValue, uint indexed newValue);

    event ClaimAuctionNFT(uint256 indexed auctionId);

    event CancelAuction(uint256 indexed auctionId);
    
    event Bidding(uint256 indexed auctionId, uint256 indexed biddingId, address bidder, uint256 amount);

    event AuctionSuccessful(
        uint256 indexed auctionId, 
        uint256 indexed biddingId, 
        address indexed bidder, 
        uint256 amount
    );

    event EscrowUpdated(address indexed oldAddress, address indexed updatedAddress);
}

interface IWithdraw {

    function claimNFTback(address tokenOwner, address tokenContract, uint256 tokenId) external returns(bool);

    function updateIncomingToken(address recepient, uint _amount, bool usdt) external returns(bool);
    function updateOutgoingToken(address recepient, uint _amount, bool usdt) external returns(bool);

    function transferCurrency(address recepient, uint256 _amount, bool usdt, bool outgoing) external payable;

    function getAuthorised(address _add) external view returns(bool);
}

contract Marketplace is ReentrancyGuard, IMarketplace, Ownable {

    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    /// @notice structure to store the bidding Info
    struct BiddingInfo {
        uint256 id;
        address bidder;
        uint256 amount;
        uint256 time;
        address whitelist;
        bool counterOffer;
    }

    /// @notice Owner's fees percentage
    /// Ex: If fee is 2.5% then tradeFeePercentage should be 250
    /// and if it's 10% then tradeFeePercentage should be 1000
    uint16 public tradeFeePercentage;
    uint16 public auctionFeePercentage;

    /// mapping for whitelisted contract addresses, no can trade personal artwork on the marketplace
    mapping(address => bool) public whitelisted;

    /// @notice stores all the ID's of the NFT which are listed on the marketplace
    uint256[] public listedTokens;
    mapping(uint256 => uint256) private listedTokensIndex; // stores the index of listedTokens ID's

    /// @notice stores all the ID's of the NFT which are listed on the marketplace for trading only
    uint256[] public tradeTokens;
    mapping(uint256 => uint256) private tradeTokensIndex;

    address[] private whitelistedContracts;
    mapping(address=>uint256) private whitelistedContractsIndexMapping;

    /// @notice mapping if the user offer is accepted by the swap owner mapping(offer => bool)
    mapping(uint=>bool) public offerAccepted;

    /// @notice mapping of the auctionId to the array of bidId i.e. Id of the bid for a particular auction 
    mapping(uint256=>uint256[]) public bidId;
    mapping(uint256=>BiddingInfo) public bidAmount; // mapping of bidId to the the BiddingInfo Structure
    mapping(uint256=>BiddingInfo) public counterOffer;
    mapping(uint256=>uint256) public offerToCounter;

    /// A mapping of all of the order currently running.
    mapping(uint256 => ListedToken) public list;
    mapping(uint256 => Sell) public sellOrder;
    mapping(uint256 => Auction) public auctions;

    bytes4 private constant INTERFACE_ID = 0x80ac58cd; // 721 interface id

    /// @dev keeps tracks of Id's
    Counters.Counter private _listOrderTracker;
    Counters.Counter private _saleOrderTracker;
    Counters.Counter private _auctionIdTracker;
    Counters.Counter private _bidIdTracker;

    /// @notice address of the treasurer where fees will be stored after trading NFT
    address public treasury;

    /// @notice address of the escrow contract
    address public escrow;

    // TODO: Needs to be changed for mainnet deployment
    address public constant USDT = 0x8DC0fAF4778076A8a6700078A500C59960880F0F; // Only for Testing

    /// @notice USDT address on polygon mainnet
    //0xc2132D05D31c914a87C6611C10748AEb04B58e8F;

    uint32 private constant ONE_DAY = 24 * 60 * 60;            // 01 day
    uint32 private constant THIRTY_DAYS = 30 * ONE_DAY;        // 30 days
    uint32 private constant TIME_BUFFER = 10 * 60;             // 10 minutes

    /**
     * @notice Require that the specified ID exists
     */
    modifier tradeExists(uint256 tradeId) {
        require(_exists(tradeId, 0), "Trade doesn't exist");
        _;
    }

    /**
     * @notice Require that the specified ID exists
     */
    modifier auctionExist(uint256 auctionId) {
        require(_exists(auctionId, 2), "Auction doesn't exist");
        _;
    }

    /**
    * @notice Contract must be whitelisted before the NFT are traded on the marketplace
    */
    modifier contractWhitelisted(address _contractAddress) {
        require(whitelisted[_contractAddress], "not Whitelisted");
        _;
    }

    /**
    * @param _treasury address of the treasurer
    * @param _tradeFeePercentage percentage of price that will goes to treasury (Trade)
    * @param _auctionFeePercentage percentage of price that will goes to treasury (Auction)
    */
    constructor(address _treasury, uint16 _tradeFeePercentage, uint16 _auctionFeePercentage) {
        require(_treasury != address(0), "Invalid address");

        treasury = _treasury;
        tradeFeePercentage = _tradeFeePercentage;
        auctionFeePercentage = _auctionFeePercentage;
    }

    /// Fallback functions to accept matic
    receive() external payable {}
    fallback() external payable {}

    /// @notice updates the address of treasury
    /// @dev onlyOwner function
    function updateTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "Invalid address");
        address oldAddress = treasury;
        treasury = _treasury;

        emit TreasuryUpdated(oldAddress, _treasury);
    }

    function updateEscrow(address _escrow) external onlyOwner {
        require(_escrow != address(0), "Invalid address");
        require(_escrow != escrow, "Same Address");
        address oldAddress = escrow;
        escrow = _escrow;

        emit EscrowUpdated(oldAddress, _escrow);
    }

    function getEscrow() external view returns(address){
        return escrow;
    }

    function getTreasury() external view returns(address){
        return treasury;
    }

    /**
     * @notice whitelist the contracts that will be available on the marketplace for trade
     * @param _contractAddress contract Address that is to be whitelisted
     * @param _value true or false to whitelist/blacklist contracts
     *
     * @dev onlyOwner function
     */
    function updateWhitelistStatus(address _contractAddress, bool _value) external onlyOwner {
        require(_contractAddress != address(0), "Zero address");
        uint256 size;
        assembly {
            size := extcodesize(_contractAddress)
        }
        require(size > 0, "Only Contracts are whitelisted");

        if (whitelisted[_contractAddress] == !_value) {
            
            whitelisted[_contractAddress] = _value;

            if (_value) {
                whitelistedContracts.push(_contractAddress);
                whitelistedContractsIndexMapping[_contractAddress] = whitelistedContracts.length;
            }
            else {
                uint listIndex = whitelistedContractsIndexMapping[_contractAddress];
                uint lastIndex = whitelistedContracts.length - 1;

                if (listIndex > 0) {
                    whitelistedContracts[listIndex - 1] = whitelistedContracts[lastIndex];
                    whitelistedContractsIndexMapping[whitelistedContracts[lastIndex]] = listIndex;
                    whitelistedContractsIndexMapping[_contractAddress] = 0;
                    whitelistedContracts.pop();
                }
            }

            emit WhiteListed(_contractAddress, msg.sender);
        }
    }

    function isWhitelisted(address _address) external view returns(bool){
        return whitelisted[_address];
    }

    /// @notice updates treasury fees
    /// @dev onlyOwner function
    function updateTradeFee(uint16 _value) external onlyOwner {
        require(_value > 0, "Fee can't be 0");
        uint _oldValue = tradeFeePercentage;
        tradeFeePercentage = _value;

        emit TradeFeeUpdated(_oldValue, tradeFeePercentage);
    }

    /// @notice updates auction fees
    /// @dev onlyOwner function
    function updateAuctionFee(uint16 _value) external onlyOwner {
        require(_value > 0, "Fee can't be 0");
        uint oldValue = auctionFeePercentage;
        auctionFeePercentage = _value;

        emit AuctionFeeUpdated(oldValue, _value);
    }

    /**
     * @notice Create a Sale order.
     * @param tokenId Id of the NFT that user wants to trade
     * @param tokenContract address of the contract of the NFT
     * @param price price of the NFT for which user wants to sell
     * @param usdt true if the user wants payment in usdt else matic
     *
     * @return orderId Id of the order created
     * @return listId Id of the list created on the marketplace
     */
    function saleOrder(
        uint256 tokenId,
        address tokenContract,
        uint256 price,
        bool usdt
    ) external nonReentrant contractWhitelisted(tokenContract) returns (uint256 orderId, uint256 listId) {

        require(tokenContract != address(0), "Zero Address");
        require(tokenId >= 0, "Invalid Id");
        require(price > 0, "Invalid Price");
        require(
            IERC165(tokenContract).supportsInterface(INTERFACE_ID),
            "ERC721 interface not supported"
        );
        address tokenOwner = IERC721(tokenContract).ownerOf(tokenId);
        require(msg.sender == tokenOwner, "Not owner");
        _saleOrderTracker.increment();
        orderId = _saleOrderTracker.current();

        listId = _listing(orderId, SaleType.Trade);

        sellOrder[orderId] = Sell({
            listId: listId,
            tokenId: tokenId,
            tokenContract: tokenContract,
            price: price,
            tokenOwner: tokenOwner,
            usdt: usdt
        });

        tradeTokens.push(orderId);
        tradeTokensIndex[orderId] = tradeTokens.length;

        IERC721(tokenContract).transferFrom(tokenOwner, escrow, tokenId);

        emit SaleCreated(orderId, listId, price, usdt);
    }

    function updateSaleOrderPrice(uint256 saleId, uint256 price) public tradeExists(saleId) {
        require(sellOrder[saleId].tokenOwner == msg.sender, "Invalid User");

        uint256 oldPrice = sellOrder[saleId].price;

        sellOrder[saleId] = Sell({
            listId: sellOrder[saleId].listId,
            tokenId: sellOrder[saleId].tokenId,
            tokenContract: sellOrder[saleId].tokenContract,
            price: price,
            tokenOwner: sellOrder[saleId].tokenOwner,
            usdt: sellOrder[saleId].usdt
        });

        emit TradePriceUpdated(saleId, price, oldPrice);
    }

    /**
    * @notice list nfts on the marketplace
    * @param orderId Id for swap, trade or auction
    * @param _type type of the order if it is swap, trade or auction
    *
    * @return listId Id of the listed NFT
    *
    * @dev internal function, will be called when user put NFT for trade and swap,
    * used to list NFT on marketplace
    */
    function _listing(uint256 orderId, 
                      SaleType _type
                    ) internal returns(uint256) 
        {

        _listOrderTracker.increment();
        uint256 listId = _listOrderTracker.current();
        list[listId] = ListedToken ({
            saleId: orderId,
            saleType: _type
        });

        listedTokens.push(listId);
        listedTokensIndex[listId] = listedTokens.length;

        emit ListCreated(listId, _type);

        return listId;
    }

    function listing(uint256 orderId, 
                      SaleType _type
                    ) public returns(uint256 tokenId) 
        {
            require(IWithdraw(escrow).getAuthorised(msg.sender), "Invalid sender");
            tokenId = _listing(orderId, _type);
        }

    /**
    * @notice unlist the nfts on the marketplace
    *
    * @param listId Id of the listed NFT
    *
    * @return bool true if NFT got unlisted from marketplace
    *
    * @dev internal function, will be called when user cancel trade or swap,
    * used to unlist NFT on marketplace
    */
    function _unlisting(uint listId) internal returns(bool) {

        uint listIndex = listedTokensIndex[listId];
        uint lastIndex = listedTokens.length - 1;

        if (listIndex > 0) {
            listedTokens[listIndex - 1] = listedTokens[lastIndex];
            listedTokensIndex[listedTokens[lastIndex]] = listIndex;
            listedTokensIndex[listId] = 0;
            listedTokens.pop();

            delete list[listId];
        }

        emit Unlist(listId);
        return true;
    }

    function unlisting(uint256 listId) public returns(bool success)
    {
        require(IWithdraw(escrow).getAuthorised(msg.sender), "Invalid sender");
        success = _unlisting(listId);
    }

    /**
     * @notice Creates an auction.
     * @param tokenId Id of the NFT that user wants to auction
     * @param tokenContract address of the contract of the NFT
     * @param duration time in seconds until which the auction will run
     * @param basePrice minimum price from where the auction will start
     * @param reservePrice The upper threshold after which the owner will complete the auction on owner's behalf.
     *                     in other word, the platform will swap the nft with the highest bid without the owner involvement.
     * @param incrementalBid the minimum price that must be greater than the previous bid
     *
     * @dev Store the auction details in the auctions mapping and emit an AuctionCreated event.
     *
     * @return auctionId Id of the auction
     * @return listId Id of the list created on the marketplace
     */
    function createAuction(
        uint256 tokenId,
        address tokenContract,
        uint256 duration,
        uint256 basePrice,
        uint256 reservePrice,
        uint256 incrementalBid
    ) external nonReentrant returns (uint256 auctionId, uint256 listId) {
        
        require(duration >= ONE_DAY && duration <= THIRTY_DAYS, "Invalid Time");
        require(basePrice > 0, "base price too less");
        require(reservePrice == 0 || reservePrice > basePrice, "Invalid reservePrice");
        require(
            IERC165(tokenContract).supportsInterface(INTERFACE_ID),
            "Not supported ERC721 interface"
        );
        
        address tokenOwner = IERC721(tokenContract).ownerOf(tokenId);
        
        require(msg.sender == tokenOwner, "Invalid token Owner");
        
        _auctionIdTracker.increment();
        auctionId = _auctionIdTracker.current();
        
        listId = _listing(auctionId, SaleType.Auction);

        auctions[auctionId] = Auction({
            listId: listId,
            tokenId: tokenId,
            tokenContract: tokenContract,
            basePrice: basePrice,
            endTime: block.timestamp + duration,
            startTime: block.timestamp,
            reservePrice: reservePrice,
            tokenOwner: tokenOwner,
            incrementalBid: incrementalBid,
            highestBidder: address(0),
            bidAmount: 0
        });

        IERC721(tokenContract).transferFrom(tokenOwner, escrow, tokenId);

        emit AuctionCreated(auctionId, duration, basePrice, reservePrice);
    }

    /**
     * @notice NFT owner can claim their NFT back after an unsuccessful Auction
     * @param auctionId Id of the auction for which the user wants to claim their NFT
     */
    function claimAuctionNFT(uint256 auctionId) external auctionExist(auctionId) {
        address tokenOwner = auctions[auctionId].tokenOwner;
        require(msg.sender == tokenOwner, "Invalid Owner");
        require(block.timestamp > auctions[auctionId].endTime, "Auction is running");

        /// unlist the auction from the marketplace
        _unlisting(auctions[auctionId].listId);

        /// transfer back the nft to the user
        IWithdraw(escrow).claimNFTback(tokenOwner, auctions[auctionId].tokenContract, auctions[auctionId].tokenId);
        // IERC721(auctions[auctionId].tokenContract).transferFrom(address(this), tokenOwner, auctions[auctionId].tokenId);
        delete auctions[auctionId];

        emit ClaimAuctionNFT(auctionId);
    }

    /**
     * @notice NFT owner can claim their NFT back in case no one has bid on the nft, resulting in cancelling the auction
     * @param auctionId Id of the auction for which the user wants to claim their NFT
     */
    function cancelAuction(uint256 auctionId) auctionExist(auctionId) external {
        address tokenOwner = auctions[auctionId].tokenOwner;

        require(bidId[auctionId].length == 0, "Bid has been placed");
        require(msg.sender == tokenOwner, "Invalid Owner");
        require(block.timestamp <= auctions[auctionId].endTime, "Auction is running");

        _unlisting(auctions[auctionId].listId);

        delete bidId[auctionId];
        // delete bidderAddresses[auctionId];

        IWithdraw(escrow).claimNFTback(tokenOwner, auctions[auctionId].tokenContract, auctions[auctionId].tokenId);
        // IERC721(auctions[auctionId].tokenContract).transferFrom(address(this), tokenOwner, auctions[auctionId].tokenId);
        delete auctions[auctionId];

        emit CancelAuction(auctionId);
    }

    /**
     * @notice user can successfully do the bidding after the nft is listed in the marketplace for the auction
     * @param auctionId Id of the auction for which the user wants to bid
     * @param amount the amount of usdt that the user wishes to bid
     *
     * @custom:note The user must contain the amount in their wallet before bidding
     * @custom:note The user must approved this contract for the amount that they wish to bid
     */
    function doBiding(uint256 auctionId, uint256 amount, uint256 time) external auctionExist(auctionId) {
        Auction storage auc = auctions[auctionId];

        // address curr = auc.usdt ? USDT : WMATIC;

        require(amount <= IERC20(USDT).balanceOf(msg.sender), "Insufficient Amount");
        require(amount <= IERC20(USDT).allowance(msg.sender, address(this)), "Insufficient Amount");

        require(amount >= auc.basePrice, "less than base price"); // can't bid less than base price
        require(block.timestamp <= auc.endTime, "Auction Ended"); // can't bid after auction time is ended
        require(time >= 15*60 && time <= 3*24*60*60, "Max 3 days"); // min 15 minutes, max 3 days

        if (bidId[auctionId].length > 0) {

            /// calculating the amount in the last bid, then adding the incrementalBid,
            /// user can never bid less than lastBid + incrementalBid
            uint256 lastBid = bidAmount[bidId[auctionId][bidId[auctionId].length - 1]].amount;
            require (amount >= lastBid + auc.incrementalBid, "Under Min Cap");

        }

        /// if the bidding amount is greater than reserve price and last bid, then the tokens of the new bid will be transferred
        /// here and the tokens of the previous bidder will become claimable to the previous bidder, which can be claimed by them.
        if (amount >= auc.reservePrice && auc.reservePrice != 0) {

            IERC20(USDT).safeTransferFrom(msg.sender, escrow, amount);

            if (auc.highestBidder != address(0) && auc.bidAmount >= auc.reservePrice && auc.reservePrice != 0) {

                IWithdraw(escrow).transferCurrency(auc.highestBidder, auc.bidAmount, true, true);
            }
        }

        auc.highestBidder = msg.sender;
        auc.bidAmount = amount;

        _bidIdTracker.increment();
        uint256 biddingId = _bidIdTracker.current();

        bidId[auctionId].push(biddingId);

        bidAmount[biddingId] = BiddingInfo({
            id: auctionId,
            bidder: msg.sender,
            time: block.timestamp + time,
            amount: amount,
            whitelist: auc.tokenOwner,
            counterOffer: false
        });

        /// If the last 10 minutes are left for the auction, and bidders bid in the auction,
        /// then the auction duration will extend for another 10 mins
        if (auc.endTime - block.timestamp <= TIME_BUFFER) auc.endTime += TIME_BUFFER;

        emit Bidding(auctionId, biddingId, msg.sender, amount);
    }

    function auctionCounter(uint256 biddingId, uint256 amount, uint256 time) external auctionExist(bidAmount[biddingId].id) returns(uint256 counterId) {

        BiddingInfo storage bid = bidAmount[biddingId];

        require(bid.time >= block.timestamp, "Offer Expired");
        require(bid.whitelist == msg.sender, "Invalid sender");
        require(time >= 15*60 && time <= 3*24*60*60, "Max 3 days");

        counterId = uint256(keccak256(abi.encodePacked(msg.sender, biddingId)));

        counterOffer[counterId] = BiddingInfo({
            id: biddingId,
            bidder: msg.sender,
            time: block.timestamp + time,
            amount: amount,
            whitelist: bid.bidder,
            counterOffer: true
        });
    }

    function acceptCounter(uint256 counterId) external auctionExist(bidAmount[counterOffer[counterId].id].id) {

        BiddingInfo storage bid = counterOffer[counterId];
        Auction storage auc = auctions[bidAmount[counterOffer[counterId].id].id];

        require(bid.counterOffer, "Not CounterOffer");
        require(bid.time >= block.timestamp, "Offer Expired");
        require(bid.whitelist == msg.sender, "Invalid sender");
        require(bid.amount <= IERC20(USDT).balanceOf(bid.whitelist),"Insufficient Amount");
        require(IERC20(USDT).allowance(bid.whitelist, address(this)) >= bid.amount, "Insufficient Approval");

        IERC20(USDT).safeTransferFrom(msg.sender, bid.bidder, bid.amount);

        IWithdraw(escrow).claimNFTback(bid.whitelist, auc.tokenContract, auc.tokenId);
    }

    /**
     * @notice when the auction is completed and the the bidding amount does not cross the reserve price,
     * then its the auction's owner choice to transfer the NFT to any bidder or they can even claim back nft
     *
     * @param auctionId Id of the auction for which bidding offer is made
     * @param biddingId Id of the bid for which user wants to the trade
     *
     * @custom:note if the bidding amount crosses reservePrice then the platform can transfer the NFT to the
     * highest bidder.
     */
    function finishAuction(uint256 auctionId, uint256 biddingId) external auctionExist(auctionId) {
        Auction storage auc = auctions[auctionId];
        BiddingInfo memory bid = bidAmount[biddingId];

        // address curr = auc.usdt ? USDT : WMATIC;
        bool canExec;

        require(bid.id == auctionId, "Invalid Bid");
        require(bid.amount <= IERC20(USDT).balanceOf(bid.bidder),"Insufficient Amount");
        require(bid.counterOffer == false, "No counter Offer");

        if (msg.sender == owner() && bid.amount >= auc.reservePrice && auc.reservePrice != 0) {
            require(bidId[auctionId][bidId[auctionId].length - 1] == biddingId, "Select highest Bid");
            canExec = true;
        }
        if (auc.tokenOwner == msg.sender) canExec = true;

        require(canExec, "Invalid Caller");

        /// caculating platform fees
        uint256 treasuryCut = bid.amount * auctionFeePercentage / 10000;

        IWithdraw(escrow).updateIncomingToken(treasury, treasuryCut, true);
        uint256 buyersAmount = bid.amount - treasuryCut;
        IWithdraw(escrow).updateIncomingToken(auc.tokenOwner, buyersAmount, true);

        /// transfering ERC20 from user to this address
        IWithdraw(escrow).transferCurrency(bid.bidder, bid.amount, true, false);
        // _handleIncomingBid(bid.amount, true);

        IWithdraw(escrow).claimNFTback(bid.bidder, auc.tokenContract, auc.tokenId);
        // IERC721(auc.tokenContract).transferFrom(address(this), bid.bidder, auc.tokenId);

        delete auctions[auctionId];

        emit AuctionSuccessful(auctionId, biddingId, bid.bidder, bid.amount);
    }

    /**
    * @notice cancels the trade and send NFT back to the owner
    * @param orderId Id of the trade that the owner wants to cancel
    *
    * @custom:note orderId is different from listId
    */
    function cancelSell(uint256 orderId) external tradeExists(orderId) {
        Sell storage sell = sellOrder[orderId];
        address owner = sell.tokenOwner;
        require(msg.sender == owner, "Invalid sender");

        // unlisting nft from marketplace
        _unlisting(sell.listId);

        // transferring nft back to token Owner
        IWithdraw(escrow).claimNFTback(owner, sell.tokenContract, sell.tokenId);
        // IERC721(sell.tokenContract).transferFrom(address(this), owner, sell.tokenId);

        uint listIndex = tradeTokensIndex[orderId];
        uint lastIndex = tradeTokens.length - 1;

        if (listIndex > 0) {
            tradeTokens[listIndex - 1] = tradeTokens[lastIndex];
            tradeTokensIndex[tradeTokens[lastIndex]] = listIndex;
            tradeTokensIndex[orderId] = 0;
            tradeTokens.pop();

            delete sellOrder[orderId];
        }

        emit CancelTrade(orderId);
    }

    /**
     * @notice buy order that owner has put to trade.
     * @param orderId orderId against which user wants to buy the nft
     *
     * @dev user needs to approve usdt to this contract before trading
     */
    function buyOrder(uint256 orderId) external payable tradeExists(orderId) nonReentrant {
        require(treasury != address(0), "Invalid Treasury");

        Sell storage sell = sellOrder[orderId];
        uint256 price = sell.price;
        uint256 treasuryCut = (price * tradeFeePercentage) / 10000;

        // updates the balance of treasury and seller to be claimed later
        if (sell.usdt) {

            // TODO: 
            // transfers the matic/usdt into the escrow contract
            IWithdraw(escrow).transferCurrency(msg.sender, price, sell.usdt, false);

            IWithdraw(escrow).updateIncomingToken(treasury, treasuryCut, true);
            uint256 buyersAmount = price - treasuryCut;
            IWithdraw(escrow).updateIncomingToken(sell.tokenOwner, buyersAmount, true);
        } else {

            IWithdraw(escrow).transferCurrency{value: price}(msg.sender, price, sell.usdt, false);

            IWithdraw(escrow).updateIncomingToken(treasury, treasuryCut, false);
            uint256 buyersAmount = price - treasuryCut;
            IWithdraw(escrow).updateIncomingToken(sell.tokenOwner, buyersAmount, false);
        }

        // transfers the nft to the msg.sender
        IWithdraw(escrow).claimNFTback(msg.sender, sell.tokenContract, sell.tokenId);
        // IERC721(sell.tokenContract).safeTransferFrom(address(this), msg.sender, sell.tokenId);

        // unlist the nft from marketplace
        _unlisting(sell.listId);

        uint listIndex = tradeTokensIndex[orderId];
        uint lastIndex = tradeTokens.length - 1;

        if (listIndex > 0) {
            tradeTokens[listIndex - 1] = tradeTokens[lastIndex];
            tradeTokensIndex[tradeTokens[lastIndex]] = listIndex;
            tradeTokensIndex[orderId] = 0;
            tradeTokens.pop();
        }

        // If the buyer sends more amount than the price,
        // the extra amount is transferred back to the buyer
        if (!sell.usdt && (msg.value - price) > 0) {
            uint256 bal = address(this).balance;
            uint256 amount = msg.value - price;
            require(bal >= amount, "Insufficient Fund");
            
            payable(msg.sender).transfer(amount);
            
            require(address(this).balance == bal - amount, "Err");
        }

        delete sellOrder[orderId];

        emit BuyOrder(orderId, price, msg.sender);
    }

    /// used in the modifier to check if the Id's are valid
    function _exists(uint256 id, uint8 saleType) internal view returns(bool) {
        if(saleType == 0){
            return sellOrder[id].tokenOwner != address(0);
        } else if (saleType == 2){
            return auctions[id].tokenOwner != address(0);
        }
        return false;
    }

    function listTokens() external view returns(uint[] memory) {
        return listedTokens;
    }

    function tradedTokens() external view returns(uint[] memory) {
       return tradeTokens;
    }

    function getWhitelistedContracts() external view returns(address[] memory) {
        return whitelistedContracts;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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