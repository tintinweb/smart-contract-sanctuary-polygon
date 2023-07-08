// contracts/ERC1155Auction.sol

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ERC1155Auction {
    mapping(address => mapping(uint256 => Auction)) public auctions;
    mapping(address => uint256) failedTransferCredits;

    //Each Auction is unique to each NFT (contract + id pairing).
    struct Auction {
        //map token ID to
        uint32 amountOfToken;
        uint32 bidIncreasePercentage;
        uint32 auctionBidPeriod; //Increments the length of time the auction is open in which a new bid can be made after each bid.
        uint64 auctionEnd;
        uint128 minPrice;
        uint128 buyNowPrice;
        uint128 nftHighestBid;
        address nftHighestBidder;
        address nftSeller;
        address whitelistedBuyer; //The seller can specify a whitelisted address for a sale (this is effectively a direct sale).
        address nftRecipient; //The bidder can specify a recipient for the NFT if their bid is successful.
        address ERC20Token; // The seller can specify an ERC20 token that can be used to bid or purchase the NFT.
        address[] feeRecipients;
        uint32[] feePercentages;
    }
    /*
     * Default values that are used if not specified by the NFT seller.
     */
    uint32 public defaultBidIncreasePercentage;
    uint32 public minimumSettableIncreasePercentage;
    uint32 public maximumMinPricePercentage;
    uint32 public defaultAuctionBidPeriod;

    event NftAuctionCreated(
        address nftContractAddress,
        uint256 tokenId,
        address nftSeller,
        address erc20Token,
        uint128 minPrice,
        uint128 buyNowPrice,
        uint32 auctionBidPeriod,
        uint32 bidIncreasePercentage,
        address[] feeRecipients,
        uint32[] feePercentages
    );

    event SaleCreated(
        address nftContractAddress,
        uint256 tokenId,
        uint32 _amountOfToken,
        address nftSeller,
        address erc20Token,
        uint128 buyNowPrice,
        address whitelistedBuyer,
        address[] feeRecipients,
        uint32[] feePercentages
    );

    event BidMade(
        address nftContractAddress,
        uint256 tokenId,
        address bidder,
        uint256 ethAmount,
        address erc20Token,
        uint256 tokenAmount
    );

    event AuctionPeriodUpdated(
        address nftContractAddress,
        uint256 tokenId,
        uint64 auctionEndPeriod
    );

    event NFTTransferredAndSellerPaid(
        address nftContractAddress,
        uint256 tokenId,
        address nftSeller,
        uint128 nftHighestBid,
        address nftHighestBidder,
        address nftRecipient
    );

    event AuctionSettled(
        address nftContractAddress,
        uint256 tokenId,
        address auctionSettler
    );

    event AuctionWithdrawn(
        address nftContractAddress,
        uint256 tokenId,
        address nftOwner
    );

    event BidWithdrawn(
        address nftContractAddress,
        uint256 tokenId,
        address highestBidder
    );

    event WhitelistedBuyerUpdated(
        address nftContractAddress,
        uint256 tokenId,
        address newWhitelistedBuyer
    );

    event MinimumPriceUpdated(
        address nftContractAddress,
        uint256 tokenId,
        uint256 newMinPrice
    );

    event BuyNowPriceUpdated(
        address nftContractAddress,
        uint256 tokenId,
        uint128 newBuyNowPrice
    );
    event HighestBidTaken(address nftContractAddress, uint256 tokenId);
    /**********************************/

    modifier isAuctionNotStartedByOwner(
        address _nftContractAddress,
        uint256 _tokenId
    ) {
        require(
            auctions[_nftContractAddress][_tokenId].nftSeller != msg.sender,
            "Auction already started by owner"
        );

        if (auctions[_nftContractAddress][_tokenId].nftSeller != address(0)) {
            require(
                _ownerOf(_nftContractAddress, msg.sender, _tokenId),
                "Sender doesn't own NFT"
            );

            _resetAuction(_nftContractAddress, _tokenId);
        }
        _;
    }

    modifier auctionOngoing(address _nftContractAddress, uint256 _tokenId) {
        require(
            _isAuctionOngoing(_nftContractAddress, _tokenId),
            "Auction has ended"
        );
        _;
    }

    modifier priceGreaterThanZero(uint256 _price) {
        require(_price > 0, "Price cannot be 0");
        _;
    }
    /*
     * The minimum price must be 80% of the buyNowPrice(if set).
     */
    modifier minPriceDoesNotExceedLimit(
        uint128 _buyNowPrice,
        uint128 _minPrice
    ) {
        require(
            _buyNowPrice == 0 ||
                _getPortionOfBid(_buyNowPrice, maximumMinPricePercentage) >=
                _minPrice,
            "MinPrice > 80% of buyNowPrice"
        );
        _;
    }

    modifier notNftSeller(address _nftContractAddress, uint256 _tokenId) {
        require(
            msg.sender != auctions[_nftContractAddress][_tokenId].nftSeller,
            "Owner cannot bid on own NFT"
        );
        _;
    }
    modifier onlyNftSeller(address _nftContractAddress, uint256 _tokenId) {
        require(
            msg.sender == auctions[_nftContractAddress][_tokenId].nftSeller,
            "Only nft seller"
        );
        _;
    }
    /*
     * The bid amount was either equal the buyNowPrice or it must be higher than the previous
     * bid by the specified bid increase percentage.
     */
    modifier bidAmountMeetsBidRequirements(
        address _nftContractAddress,
        uint256 _tokenId,
        uint128 _tokenAmount
    ) {
        require(
            _doesBidMeetBidRequirements(
                _nftContractAddress,
                _tokenId,
                _tokenAmount
            ),
            "Not enough funds to bid on NFT"
        );
        _;
    }
    // check if the highest bidder can purchase this NFT.
    modifier onlyApplicableBuyer(
        address _nftContractAddress,
        uint256 _tokenId
    ) {
        require(
            !_isWhitelistedSale(_nftContractAddress, _tokenId) ||
                auctions[_nftContractAddress][_tokenId].whitelistedBuyer ==
                msg.sender,
            "Only the whitelisted buyer"
        );
        _;
    }

    modifier minimumBidNotMade(address _nftContractAddress, uint256 _tokenId) {
        require(
            !_isMinimumBidMade(_nftContractAddress, _tokenId),
            "The auction has a valid bid made"
        );
        _;
    }

    /*
     * Payment is accepted if the payment is made in the ERC20 token or ETH specified by the seller.
     * Early bids on NFTs not yet up for auction must be made in ETH.
     */
    modifier paymentAccepted(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint128 _tokenAmount
    ) {
        require(
            _isPaymentAccepted(
                _nftContractAddress,
                _tokenId,
                _erc20Token,
                _tokenAmount
            ),
            "Bid to be in specified ERC20/Eth"
        );
        _;
    }

    modifier isAuctionOver(address _nftContractAddress, uint256 _tokenId) {
        require(
            !_isAuctionOngoing(_nftContractAddress, _tokenId),
            "Auction is not yet over"
        );
        _;
    }

    modifier notZeroAddress(address _address) {
        require(_address != address(0), "Cannot specify 0 address");
        _;
    }

    modifier increasePercentageAboveMinimum(uint32 _bidIncreasePercentage) {
        require(
            _bidIncreasePercentage >= minimumSettableIncreasePercentage,
            "Bid increase percentage too low"
        );
        _;
    }

    modifier isFeePercentagesLessThanMaximum(uint32[] memory _feePercentages) {
        uint32 totalPercent;
        for (uint256 i = 0; i < _feePercentages.length; i++) {
            totalPercent = totalPercent + _feePercentages[i];
        }
        require(totalPercent <= 10000, "Fee percentages exceed maximum");
        _;
    }

    modifier correctFeeRecipientsAndPercentages(
        uint256 _recipientsLength,
        uint256 _percentagesLength
    ) {
        require(
            _recipientsLength == _percentagesLength,
            "Recipients != percentages"
        );
        _;
    }

    modifier isNotASale(address _nftContractAddress, uint256 _tokenId) {
        require(
            !_isASale(_nftContractAddress, _tokenId),
            "Not applicable for a sale"
        );
        _;
    }

    /**********************************/

    constructor() {
        defaultBidIncreasePercentage = 100;
        defaultAuctionBidPeriod = 86400; //1 day
        minimumSettableIncreasePercentage = 100;
        maximumMinPricePercentage = 8000;
    }

    function _ownerOf(
        address _nftContractAddress,
        address sender,
        uint256 tokenId
    ) internal view returns (bool) {
        return IERC1155(_nftContractAddress).balanceOf(sender, tokenId) != 0;
    }

    function _isAuctionOngoing(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal view returns (bool) {
        uint64 auctionEndTimestamp = auctions[_nftContractAddress][_tokenId]
            .auctionEnd;
        //if the auctionEnd is set to 0, the auction is technically on-going, however
        //the minimum bid price (minPrice) has not yet been met.
        return (auctionEndTimestamp == 0 ||
            block.timestamp < auctionEndTimestamp);
    }

    /*
     * Check if a bid has been made. This is applicable in the early bid scenario
     * to ensure that if an auction is created after an early bid, the auction
     * begins appropriately or is settled if the buy now price is met.
     */
    function _isABidMade(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal view returns (bool) {
        return (auctions[_nftContractAddress][_tokenId].nftHighestBid > 0);
    }

    /*
     *if the minPrice is set by the seller, check that the highest bid meets or exceeds that price.
     */
    function _isMinimumBidMade(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal view returns (bool) {
        uint128 minPrice = auctions[_nftContractAddress][_tokenId].minPrice;
        return
            minPrice > 0 &&
            (auctions[_nftContractAddress][_tokenId].nftHighestBid >= minPrice);
    }

    /*
     * If the buy now price is set by the seller, check that the highest bid meets that price.
     */
    function _isBuyNowPriceMet(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal view returns (bool) {
        uint128 buyNowPrice = auctions[_nftContractAddress][_tokenId]
            .buyNowPrice;
        return
            buyNowPrice > 0 &&
            auctions[_nftContractAddress][_tokenId].nftHighestBid >=
            buyNowPrice;
    }

    /*
     * Check that a bid is applicable for the purchase of the NFT.
     * In the case of a sale: the bid needs to meet the buyNowPrice.
     * In the case of an auction: the bid needs to be a % higher than the previous bid.
     */
    function _doesBidMeetBidRequirements(
        address _nftContractAddress,
        uint256 _tokenId,
        uint128 _tokenAmount
    ) internal view returns (bool) {
        uint128 buyNowPrice = auctions[_nftContractAddress][_tokenId]
            .buyNowPrice;
        //if buyNowPrice is met, ignore increase percentage
        if (
            buyNowPrice > 0 &&
            (msg.value >= buyNowPrice || _tokenAmount >= buyNowPrice)
        ) {
            return true;
        }
        //if the NFT is up for auction, the bid needs to be a % higher than the previous bid
        uint256 bidIncreaseAmount = (auctions[_nftContractAddress][_tokenId]
            .nftHighestBid *
            (10000 +
                _getBidIncreasePercentage(_nftContractAddress, _tokenId))) /
            10000;
        return (msg.value >= bidIncreaseAmount ||
            _tokenAmount >= bidIncreaseAmount);
    }

    /*
     * An NFT is up for sale if the buyNowPrice is set, but the minPrice is not set.
     * Therefore the only way to conclude the NFT sale is to meet the buyNowPrice.
     */
    function _isASale(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal view returns (bool) {
        return (auctions[_nftContractAddress][_tokenId].buyNowPrice > 0 &&
            auctions[_nftContractAddress][_tokenId].minPrice == 0);
    }

    function _isWhitelistedSale(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal view returns (bool) {
        return (auctions[_nftContractAddress][_tokenId].whitelistedBuyer !=
            address(0));
    }

    /*
     * The highest bidder is allowed to purchase the NFT if
     * no whitelisted buyer is set by the NFT seller.
     * Otherwise, the highest bidder must equal the whitelisted buyer.
     */
    function _isHighestBidderAllowedToPurchaseNFT(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal view returns (bool) {
        return
            (!_isWhitelistedSale(_nftContractAddress, _tokenId)) ||
            _isHighestBidderWhitelisted(_nftContractAddress, _tokenId);
    }

    function _isHighestBidderWhitelisted(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal view returns (bool) {
        return (auctions[_nftContractAddress][_tokenId].nftHighestBidder ==
            auctions[_nftContractAddress][_tokenId].whitelistedBuyer);
    }

    /**
     * Payment is accepted in the following scenarios:
     * (1) Auction already created - can accept ETH or Specified Token
     *  --------> Cannot bid with ETH & an ERC20 Token together in any circumstance<------
     * (2) Auction not created - only ETH accepted (cannot early bid with an ERC20 Token
     * (3) Cannot make a zero bid (no ETH or Token amount)
     */
    function _isPaymentAccepted(
        address _nftContractAddress,
        uint256 _tokenId,
        address _bidERC20Token,
        uint128 _tokenAmount
    ) internal view returns (bool) {
        address auctionERC20Token = auctions[_nftContractAddress][_tokenId]
            .ERC20Token;
        if (_isERC20Auction(auctionERC20Token)) {
            return
                msg.value == 0 &&
                auctionERC20Token == _bidERC20Token &&
                _tokenAmount > 0;
        } else {
            return
                msg.value != 0 &&
                _bidERC20Token == address(0) &&
                _tokenAmount == 0;
        }
    }

    function _isERC20Auction(
        address _auctionERC20Token
    ) internal pure returns (bool) {
        return _auctionERC20Token != address(0);
    }

    /*
     * Returns the percentage of the total bid (used to calculate fee payments)
     */
    function _getPortionOfBid(
        uint256 _totalBid,
        uint256 _percentage
    ) internal pure returns (uint256) {
        return (_totalBid * (_percentage)) / 10000;
    }

    /**********************************/

    /*╔══════════════════════════════╗
      ║    DEFAULT GETTER FUNCTIONS  ║
      ╚══════════════════════════════╝*/
    /*****************************************************************
     * These functions check if the applicable auction parameter has *
     * been set by the NFT seller. If not, return the default value. *
     *****************************************************************/

    function _getBidIncreasePercentage(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal view returns (uint32) {
        uint32 bidIncreasePercentage = auctions[_nftContractAddress][_tokenId]
            .bidIncreasePercentage;

        if (bidIncreasePercentage == 0) {
            return defaultBidIncreasePercentage;
        } else {
            return bidIncreasePercentage;
        }
    }

    function _getAuctionBidPeriod(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal view returns (uint32) {
        uint32 auctionBidPeriod = auctions[_nftContractAddress][_tokenId]
            .auctionBidPeriod;

        if (auctionBidPeriod == 0) {
            return defaultAuctionBidPeriod;
        } else {
            return auctionBidPeriod;
        }
    }

    /*
     * The default value for the NFT recipient is the highest bidder
     */
    function _getNftRecipient(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal view returns (address) {
        address nftRecipient = auctions[_nftContractAddress][_tokenId]
            .nftRecipient;

        if (nftRecipient == address(0)) {
            return auctions[_nftContractAddress][_tokenId].nftHighestBidder;
        } else {
            return nftRecipient;
        }
    }

    /**********************************/

    /*╔══════════════════════════════╗
      ║  TRANSFER NFTS TO CONTRACT   ║
      ╚══════════════════════════════╝*/
    function _transferNftToAuctionContract(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal {
        address _nftSeller = auctions[_nftContractAddress][_tokenId].nftSeller;
        if (_ownerOf(_nftContractAddress, _nftSeller, _tokenId)) {
            IERC1155(_nftContractAddress).safeTransferFrom(
                _nftSeller,
                address(this),
                _tokenId,
                auctions[_nftContractAddress][_tokenId].amountOfToken,
                "0x0"
            );
            require(
                _ownerOf(_nftContractAddress, address(this), _tokenId),
                "nft transfer failed"
            );
        } else {
            require(
                _ownerOf(_nftContractAddress, address(this), _tokenId),
                "Seller doesn't own NFT"
            );
        }
    }

    /**********************************/

    /*╔══════════════════════════════╗
      ║       AUCTION CREATION       ║
      ╚══════════════════════════════╝*/
    /**
     * Setup parameters applicable to all auctions and whitelised sales:
     * -> ERC20 Token for payment (if specified by the seller) : _erc20Token
     * -> minimum price : _minPrice
     * -> buy now price : _buyNowPrice
     * -> the nft seller: msg.sender
     * -> The fee recipients & their respective percentages for a sucessful auction/sale
     */
    function _setupAuction(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint128 _minPrice,
        uint128 _buyNowPrice,
        address[] memory _feeRecipients,
        uint32[] memory _feePercentages
    )
        internal
        minPriceDoesNotExceedLimit(_buyNowPrice, _minPrice)
        correctFeeRecipientsAndPercentages(
            _feeRecipients.length,
            _feePercentages.length
        )
        isFeePercentagesLessThanMaximum(_feePercentages)
    {
        // if (_erc20Token != address(0)) {
        //     revert("Disabled ERC20 functionality");
        // }

        auctions[_nftContractAddress][_tokenId].feeRecipients = _feeRecipients;
        auctions[_nftContractAddress][_tokenId]
            .feePercentages = _feePercentages;
        auctions[_nftContractAddress][_tokenId].ERC20Token = _erc20Token;
        auctions[_nftContractAddress][_tokenId].buyNowPrice = _buyNowPrice;
        auctions[_nftContractAddress][_tokenId].minPrice = _minPrice;
        auctions[_nftContractAddress][_tokenId].nftSeller = msg.sender;
    }

    function _createNewNftAuction(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint128 _minPrice,
        uint128 _buyNowPrice,
        address[] memory _feeRecipients,
        uint32[] memory _feePercentages
    ) internal {
        // Sending the NFT to this contract
        _setupAuction(
            _nftContractAddress,
            _tokenId,
            _erc20Token,
            _minPrice,
            _buyNowPrice,
            _feeRecipients,
            _feePercentages
        );
        emit NftAuctionCreated(
            _nftContractAddress,
            _tokenId,
            msg.sender,
            _erc20Token,
            _minPrice,
            _buyNowPrice,
            _getAuctionBidPeriod(_nftContractAddress, _tokenId),
            _getBidIncreasePercentage(_nftContractAddress, _tokenId),
            _feeRecipients,
            _feePercentages
        );
        _updateOngoingAuction(_nftContractAddress, _tokenId);
    }

    function _setupBidDetails(
        address _nftContractAddress,
        uint256 _tokenId,
        uint32 _amountOfToken,
        uint32 _auctionBidPeriod,
        uint32 _bidIncreasePercentage
    ) internal {
        auctions[_nftContractAddress][_tokenId].amountOfToken = _amountOfToken;
        auctions[_nftContractAddress][_tokenId]
            .auctionBidPeriod = _auctionBidPeriod;
        auctions[_nftContractAddress][_tokenId]
            .bidIncreasePercentage = _bidIncreasePercentage;
    }

    function createNewNftAuction(
        address _nftContractAddress,
        uint256 _tokenId,
        uint32 _amountOfToken,
        address _erc20Token,
        uint128 _minPrice,
        uint128 _buyNowPrice,
        uint32 _auctionBidPeriod, //this is the time that the auction lasts until another bid occurs
        uint32 _bidIncreasePercentage,
        address[] memory _feeRecipients,
        uint32[] memory _feePercentages
    )
        external
        isAuctionNotStartedByOwner(_nftContractAddress, _tokenId)
        priceGreaterThanZero(_minPrice)
        increasePercentageAboveMinimum(_bidIncreasePercentage)
    {
        _setupBidDetails(
            _nftContractAddress,
            _tokenId,
            _amountOfToken,
            _auctionBidPeriod,
            _bidIncreasePercentage
        );

        _createNewNftAuction(
            _nftContractAddress,
            _tokenId,
            _erc20Token,
            _minPrice,
            _buyNowPrice,
            _feeRecipients,
            _feePercentages
        );
    }

    /**********************************/

    /*╔══════════════════════════════╗
      ║            SALES             ║
      ╚══════════════════════════════╝*/
    /********************************************************************
     * Allows for a standard sale mechanism where the NFT seller can    *
     * can select an address to be whitelisted. This address is then    *
     * allowed to make a bid on the NFT. No other address can bid on    *
     * the NFT.                                                         *
     ********************************************************************/
    function _setupSale(
        address _nftContractAddress,
        uint256 _tokenId,
        uint32 _amountOfToken,
        address _erc20Token,
        uint128 _buyNowPrice,
        address _whitelistedBuyer,
        address[] memory _feeRecipients,
        uint32[] memory _feePercentages
    )
        internal
        correctFeeRecipientsAndPercentages(
            _feeRecipients.length,
            _feePercentages.length
        )
        isFeePercentagesLessThanMaximum(_feePercentages)
    {
        // if (_erc20Token != address(0)) {
        //     revert("Disabled ERC20 functionality");
        // }
        auctions[_nftContractAddress][_tokenId].amountOfToken = _amountOfToken;
        auctions[_nftContractAddress][_tokenId].feeRecipients = _feeRecipients;
        auctions[_nftContractAddress][_tokenId]
            .feePercentages = _feePercentages;
        auctions[_nftContractAddress][_tokenId].ERC20Token = _erc20Token;
        auctions[_nftContractAddress][_tokenId].buyNowPrice = _buyNowPrice;
        auctions[_nftContractAddress][_tokenId]
            .whitelistedBuyer = _whitelistedBuyer;
        auctions[_nftContractAddress][_tokenId].nftSeller = msg.sender;
    }

    function createSale(
        address _nftContractAddress,
        uint256 _tokenId,
        uint32 _amountOfToken,
        address _erc20Token,
        uint128 _buyNowPrice,
        address _whitelistedBuyer,
        address[] memory _feeRecipients,
        uint32[] memory _feePercentages
    )
        external
        isAuctionNotStartedByOwner(_nftContractAddress, _tokenId)
        priceGreaterThanZero(_buyNowPrice)
    {
        //min price = 0
        _setupSale(
            _nftContractAddress,
            _tokenId,
            _amountOfToken,
            _erc20Token,
            _buyNowPrice,
            _whitelistedBuyer,
            _feeRecipients,
            _feePercentages
        );

        emit SaleCreated(
            _nftContractAddress,
            _tokenId,
            _amountOfToken,
            msg.sender,
            _erc20Token,
            _buyNowPrice,
            _whitelistedBuyer,
            _feeRecipients,
            _feePercentages
        );
        //check if buyNowPrice is meet and conclude sale, otherwise reverse the early bid
        if (_isABidMade(_nftContractAddress, _tokenId)) {
            if (
                //we only revert the underbid if the seller specifies a different
                //whitelisted buyer to the highest bidder
                _isHighestBidderAllowedToPurchaseNFT(
                    _nftContractAddress,
                    _tokenId
                )
            ) {
                if (_isBuyNowPriceMet(_nftContractAddress, _tokenId)) {
                    _transferNftToAuctionContract(
                        _nftContractAddress,
                        _tokenId
                    );
                    _transferNftAndPaySeller(_nftContractAddress, _tokenId);
                }
            } else {
                _reverseAndResetPreviousBid(_nftContractAddress, _tokenId);
            }
        }
    }

    /**********************************/

    /*╔═════════════════════════════╗
      ║        BID FUNCTIONS        ║
      ╚═════════════════════════════╝*/
    /********************************************************************
     * Make bids with ETH or an ERC20 Token specified by the NFT seller.*
     * Additionally, a buyer can pay the asking price to conclude a sale*
     * of an NFT.                                                      *
     ********************************************************************/

    function _makeBid(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint128 _tokenAmount
    )
        internal
        notNftSeller(_nftContractAddress, _tokenId)
        paymentAccepted(
            _nftContractAddress,
            _tokenId,
            _erc20Token,
            _tokenAmount
        )
        bidAmountMeetsBidRequirements(
            _nftContractAddress,
            _tokenId,
            _tokenAmount
        )
    {
        _reversePreviousBidAndUpdateHighestBid(
            _nftContractAddress,
            _tokenId,
            _tokenAmount
        );
        emit BidMade(
            _nftContractAddress,
            _tokenId,
            msg.sender,
            msg.value,
            _erc20Token,
            _tokenAmount
        );
        _updateOngoingAuction(_nftContractAddress, _tokenId);
    }

    function makeBid(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint128 _tokenAmount
    )
        external
        payable
        auctionOngoing(_nftContractAddress, _tokenId)
        onlyApplicableBuyer(_nftContractAddress, _tokenId)
    {
        _makeBid(_nftContractAddress, _tokenId, _erc20Token, _tokenAmount);
    }

    function makeCustomBid(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint128 _tokenAmount,
        address _nftRecipient
    )
        external
        payable
        auctionOngoing(_nftContractAddress, _tokenId)
        notZeroAddress(_nftRecipient)
        onlyApplicableBuyer(_nftContractAddress, _tokenId)
    {
        auctions[_nftContractAddress][_tokenId].nftRecipient = _nftRecipient;
        _makeBid(_nftContractAddress, _tokenId, _erc20Token, _tokenAmount);
    }

    /**********************************/

    /*╔══════════════════════════════╗
      ║       UPDATE AUCTION         ║
      ╚══════════════════════════════╝*/
    /***************************************************************
     * Settle an auction or sale if the buyNowPrice is met or set  *
     *  auction period to begin if the minimum price has been met. *
     ***************************************************************/
    function _updateOngoingAuction(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal {
        if (_isBuyNowPriceMet(_nftContractAddress, _tokenId)) {
            _transferNftToAuctionContract(_nftContractAddress, _tokenId);
            _transferNftAndPaySeller(_nftContractAddress, _tokenId);
            return;
        }
        //min price not set, nft not up for auction yet
        if (_isMinimumBidMade(_nftContractAddress, _tokenId)) {
            _transferNftToAuctionContract(_nftContractAddress, _tokenId);
            _updateAuctionEnd(_nftContractAddress, _tokenId);
        }
    }

    function _updateAuctionEnd(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal {
        //the auction end is always set to now + the bid period
        auctions[_nftContractAddress][_tokenId].auctionEnd =
            _getAuctionBidPeriod(_nftContractAddress, _tokenId) +
            uint64(block.timestamp);
        emit AuctionPeriodUpdated(
            _nftContractAddress,
            _tokenId,
            auctions[_nftContractAddress][_tokenId].auctionEnd
        );
    }

    /**********************************/

    /*╔══════════════════════════════╗
      ║       RESET FUNCTIONS        ║
      ╚══════════════════════════════╝*/
    /*
     * Reset all auction related parameters for an NFT.
     * This effectively removes an EFT as an item up for auction
     */
    function _resetAuction(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal {
        auctions[_nftContractAddress][_tokenId].minPrice = 0;
        auctions[_nftContractAddress][_tokenId].buyNowPrice = 0;
        auctions[_nftContractAddress][_tokenId].auctionEnd = 0;
        auctions[_nftContractAddress][_tokenId].auctionBidPeriod = 0;
        auctions[_nftContractAddress][_tokenId].bidIncreasePercentage = 0;
        auctions[_nftContractAddress][_tokenId].nftSeller = address(0);
        auctions[_nftContractAddress][_tokenId].whitelistedBuyer = address(0);
        auctions[_nftContractAddress][_tokenId].ERC20Token = address(0);
    }

    /*
     * Reset all bid related parameters for an NFT.
     * This effectively sets an NFT as having no active bids
     */
    function _resetBids(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal {
        auctions[_nftContractAddress][_tokenId].nftHighestBidder = address(0);
        auctions[_nftContractAddress][_tokenId].nftHighestBid = 0;
        auctions[_nftContractAddress][_tokenId].nftRecipient = address(0);
    }

    /**********************************/

    /*╔══════════════════════════════╗
      ║         UPDATE BIDS          ║
      ╚══════════════════════════════╝*/
    /******************************************************************
     * Internal functions that update bid parameters and reverse bids *
     * to ensure contract only holds the highest bid.                 *
     ******************************************************************/
    function _updateHighestBid(
        address _nftContractAddress,
        uint256 _tokenId,
        uint128 _tokenAmount
    ) internal {
        address auctionERC20Token = auctions[_nftContractAddress][_tokenId]
            .ERC20Token;
        if (_isERC20Auction(auctionERC20Token)) {
            IERC20(auctionERC20Token).transferFrom(
                msg.sender,
                address(this),
                _tokenAmount
            );
            auctions[_nftContractAddress][_tokenId]
                .nftHighestBid = _tokenAmount;
        } else {
            auctions[_nftContractAddress][_tokenId].nftHighestBid = uint128(
                msg.value
            );
        }
        auctions[_nftContractAddress][_tokenId].nftHighestBidder = msg.sender;
    }

    function _reverseAndResetPreviousBid(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal {
        address nftHighestBidder = auctions[_nftContractAddress][_tokenId]
            .nftHighestBidder;

        uint128 nftHighestBid = auctions[_nftContractAddress][_tokenId]
            .nftHighestBid;
        _resetBids(_nftContractAddress, _tokenId);

        _payout(_nftContractAddress, _tokenId, nftHighestBidder, nftHighestBid);
    }

    function _reversePreviousBidAndUpdateHighestBid(
        address _nftContractAddress,
        uint256 _tokenId,
        uint128 _tokenAmount
    ) internal {
        address prevNftHighestBidder = auctions[_nftContractAddress][_tokenId]
            .nftHighestBidder;

        uint256 prevNftHighestBid = auctions[_nftContractAddress][_tokenId]
            .nftHighestBid;
        _updateHighestBid(_nftContractAddress, _tokenId, _tokenAmount);

        if (prevNftHighestBidder != address(0)) {
            _payout(
                _nftContractAddress,
                _tokenId,
                prevNftHighestBidder,
                prevNftHighestBid
            );
        }
    }

    /**********************************/

    /*╔══════════════════════════════╗
      ║  TRANSFER NFT & PAY SELLER   ║
      ╚══════════════════════════════╝*/
    function _transferNftAndPaySeller(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal {
        address _nftSeller = auctions[_nftContractAddress][_tokenId].nftSeller;
        address _nftHighestBidder = auctions[_nftContractAddress][_tokenId]
            .nftHighestBidder;
        address _nftRecipient = _getNftRecipient(_nftContractAddress, _tokenId);
        uint128 _nftHighestBid = auctions[_nftContractAddress][_tokenId]
            .nftHighestBid;
        _resetBids(_nftContractAddress, _tokenId);

        _payFeesAndSeller(
            _nftContractAddress,
            _tokenId,
            _nftSeller,
            _nftHighestBid
        );

        IERC1155(_nftContractAddress).safeTransferFrom(
            address(this),
            _nftRecipient,
            _tokenId,
            auctions[_nftContractAddress][_tokenId].amountOfToken,
            "0x0"
        );

        _resetAuction(_nftContractAddress, _tokenId);
        emit NFTTransferredAndSellerPaid(
            _nftContractAddress,
            _tokenId,
            _nftSeller,
            _nftHighestBid,
            _nftHighestBidder,
            _nftRecipient
        );
    }

    function _payFeesAndSeller(
        address _nftContractAddress,
        uint256 _tokenId,
        address _nftSeller,
        uint256 _highestBid
    ) internal {
        uint256 feesPaid;
        for (
            uint256 i = 0;
            i < auctions[_nftContractAddress][_tokenId].feeRecipients.length;
            i++
        ) {
            uint256 fee = _getPortionOfBid(
                _highestBid,
                auctions[_nftContractAddress][_tokenId].feePercentages[i]
            );
            feesPaid = feesPaid + fee;
            _payout(
                _nftContractAddress,
                _tokenId,
                auctions[_nftContractAddress][_tokenId].feeRecipients[i],
                fee
            );
        }
        _payout(
            _nftContractAddress,
            _tokenId,
            _nftSeller,
            (_highestBid - feesPaid)
        );
    }

    function _payout(
        address _nftContractAddress,
        uint256 _tokenId,
        address _recipient,
        uint256 _amount
    ) internal {
        address auctionERC20Token = auctions[_nftContractAddress][_tokenId]
            .ERC20Token;
        if (_isERC20Auction(auctionERC20Token)) {
            IERC20(auctionERC20Token).transfer(_recipient, _amount);
        } else {
            // attempt to send the funds to the recipient
            (bool success, ) = payable(_recipient).call{
                value: _amount,
                gas: 20000
            }("");
            // if it failed, update their credit balance so they can pull it later
            if (!success) {
                failedTransferCredits[_recipient] =
                    failedTransferCredits[_recipient] +
                    _amount;
            }
        }
    }

    /**********************************/

    /*╔══════════════════════════════╗
      ║      SETTLE & WITHDRAW       ║
      ╚══════════════════════════════╝*/
    function settleAuction(
        address _nftContractAddress,
        uint256 _tokenId
    ) external isAuctionOver(_nftContractAddress, _tokenId) {
        _transferNftAndPaySeller(_nftContractAddress, _tokenId);
        emit AuctionSettled(_nftContractAddress, _tokenId, msg.sender);
    }

    function withdrawAuction(
        address _nftContractAddress,
        uint256 _tokenId
    ) external {
        //only the NFT owner can prematurely close and auction
        require(
            _ownerOf(_nftContractAddress, msg.sender, _tokenId),
            "Not NFT owner"
        );
        _resetAuction(_nftContractAddress, _tokenId);
        emit AuctionWithdrawn(_nftContractAddress, _tokenId, msg.sender);
    }

    function withdrawBid(
        address _nftContractAddress,
        uint256 _tokenId
    ) external minimumBidNotMade(_nftContractAddress, _tokenId) {
        address nftHighestBidder = auctions[_nftContractAddress][_tokenId]
            .nftHighestBidder;
        require(msg.sender == nftHighestBidder, "Cannot withdraw funds");

        uint128 nftHighestBid = auctions[_nftContractAddress][_tokenId]
            .nftHighestBid;
        _resetBids(_nftContractAddress, _tokenId);

        _payout(_nftContractAddress, _tokenId, nftHighestBidder, nftHighestBid);

        emit BidWithdrawn(_nftContractAddress, _tokenId, msg.sender);
    }

    /**********************************/

    /*╔══════════════════════════════╗
      ║       UPDATE AUCTION         ║
      ╚══════════════════════════════╝*/
    function updateWhitelistedBuyer(
        address _nftContractAddress,
        uint256 _tokenId,
        address _newWhitelistedBuyer
    ) external onlyNftSeller(_nftContractAddress, _tokenId) {
        require(_isASale(_nftContractAddress, _tokenId), "Not a sale");
        auctions[_nftContractAddress][_tokenId]
            .whitelistedBuyer = _newWhitelistedBuyer;
        //if an underbid is by a non whitelisted buyer,reverse that bid
        address nftHighestBidder = auctions[_nftContractAddress][_tokenId]
            .nftHighestBidder;
        uint128 nftHighestBid = auctions[_nftContractAddress][_tokenId]
            .nftHighestBid;
        if (nftHighestBid > 0 && !(nftHighestBidder == _newWhitelistedBuyer)) {
            //we only revert the underbid if the seller specifies a different
            //whitelisted buyer to the highest bider

            _resetBids(_nftContractAddress, _tokenId);

            _payout(
                _nftContractAddress,
                _tokenId,
                nftHighestBidder,
                nftHighestBid
            );
        }

        emit WhitelistedBuyerUpdated(
            _nftContractAddress,
            _tokenId,
            _newWhitelistedBuyer
        );
    }

    function updateMinimumPrice(
        address _nftContractAddress,
        uint256 _tokenId,
        uint128 _newMinPrice
    )
        external
        onlyNftSeller(_nftContractAddress, _tokenId)
        minimumBidNotMade(_nftContractAddress, _tokenId)
        isNotASale(_nftContractAddress, _tokenId)
        priceGreaterThanZero(_newMinPrice)
        minPriceDoesNotExceedLimit(
            auctions[_nftContractAddress][_tokenId].buyNowPrice,
            _newMinPrice
        )
    {
        auctions[_nftContractAddress][_tokenId].minPrice = _newMinPrice;

        emit MinimumPriceUpdated(_nftContractAddress, _tokenId, _newMinPrice);

        if (_isMinimumBidMade(_nftContractAddress, _tokenId)) {
            _transferNftToAuctionContract(_nftContractAddress, _tokenId);
            _updateAuctionEnd(_nftContractAddress, _tokenId);
        }
    }

    function updateBuyNowPrice(
        address _nftContractAddress,
        uint256 _tokenId,
        uint128 _newBuyNowPrice
    )
        external
        onlyNftSeller(_nftContractAddress, _tokenId)
        priceGreaterThanZero(_newBuyNowPrice)
        minPriceDoesNotExceedLimit(
            _newBuyNowPrice,
            auctions[_nftContractAddress][_tokenId].minPrice
        )
    {
        auctions[_nftContractAddress][_tokenId].buyNowPrice = _newBuyNowPrice;
        emit BuyNowPriceUpdated(_nftContractAddress, _tokenId, _newBuyNowPrice);
        if (_isBuyNowPriceMet(_nftContractAddress, _tokenId)) {
            _transferNftToAuctionContract(_nftContractAddress, _tokenId);
            _transferNftAndPaySeller(_nftContractAddress, _tokenId);
        }
    }

    /*
     * The NFT seller can opt to end an auction by taking the current highest bid.
     */
    function takeHighestBid(
        address _nftContractAddress,
        uint256 _tokenId
    ) external onlyNftSeller(_nftContractAddress, _tokenId) {
        require(
            _isABidMade(_nftContractAddress, _tokenId),
            "cannot payout 0 bid"
        );
        _transferNftToAuctionContract(_nftContractAddress, _tokenId);
        _transferNftAndPaySeller(_nftContractAddress, _tokenId);
        emit HighestBidTaken(_nftContractAddress, _tokenId);
    }

    /*
     * Query the owner of an NFT deposited for auction
     */
    function ownerOfNFT(
        address _nftContractAddress,
        uint256 _tokenId
    ) external view returns (address) {
        address nftSeller = auctions[_nftContractAddress][_tokenId].nftSeller;
        require(nftSeller != address(0), "NFT not deposited");

        return nftSeller;
    }

    /*
     * If the transfer of a bid has failed, allow the recipient to reclaim their amount later.
     */
    function withdrawAllFailedCredits() external {
        uint256 amount = failedTransferCredits[msg.sender];

        require(amount != 0, "no credits to withdraw");

        failedTransferCredits[msg.sender] = 0;

        (bool successfulWithdraw, ) = msg.sender.call{
            value: amount,
            gas: 20000
        }("");
        require(successfulWithdraw, "withdraw failed");
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
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
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

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
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

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