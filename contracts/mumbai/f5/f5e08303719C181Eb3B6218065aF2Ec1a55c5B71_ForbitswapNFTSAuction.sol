// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./NFTAuction.sol";

contract ForbitswapNFTSAuction is NFTAuction {
  string public constant name = "Forbit NFTS Auction";

  constructor() {
    minimumSettableIncreasePercentage = 100;
    protocolFeePercentage = 250;
    protocolFeeRecipient = address(0x00B91B2F8aFE87FCDc2b3fFA9ee2278cd1E4DDf8);
  }

  /**
    * @notice Set up protocol fee
    * @param _protocolFeeRecipient Protocol's fee recipient
    * @param _protocolFeePercentage Protocol's fee percentage 
    */
  function setProtocolFee(address _protocolFeeRecipient, uint16 _protocolFeePercentage) public onlyOwner {
      protocolFeeRecipient = _protocolFeeRecipient;
      protocolFeePercentage = _protocolFeePercentage;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/IERC721.sol";
import "../token/ERC20/IERC20.sol";
import "../access/Ownable.sol";
import "../utils/Context.sol";
import "../utils/ReentrancyGuard.sol";

contract NFTAuction is Context, Ownable, ReentrancyGuard {
  struct Auction {
    uint256 minPrice;
    uint256 auctionBidPeriod;
    uint256 auctionEnd;
    uint256 nftHighestBid;
    uint256[] batchTokenIds;
    uint16 bidIncreasePercentage;
    address nftHighestBidder;
    address nftSeller;
    address nftRecipient;
    address paymentToken;
    uint8 liveOn;
  }

  mapping(address => mapping(uint256 => Auction)) public nftContractAuctions;
  mapping(address => uint256) public failedTransferCredits;

  /**
    * Default values that are used if not specified by the NFT seller
    */
  uint256 public minimumSettableIncreasePercentage;
  address public protocolFeeRecipient;
  uint16 public protocolFeePercentage;

  /***************************
    *         Events
    ***************************/
  
  event NftAuctionCreated(
    address indexed nftContractAddress,
    uint256 indexed tokenId,
    address nftSeller,
    address paymentToken,
    uint256 minPrice,
    uint256 indexed auctionEnd,
    uint16 bidIncreasePercentage
  );

  event NftBatchAuctionCreated(
    address nftContractAddress,
    uint256 indexed masterTokenId,
    uint256[] batchTokens,
    address indexed nftSeller,
    address paymentToken,
    uint256 minPrice,
    uint256 auctionBidPeriod,
    uint16 bidIncreasePercentage
  );

  event BidMade(
    address indexed nftContractAddress,
    uint256 indexed tokenId,
    address bidder,
    address paymentToken,
    uint256 amount
  );

  event AuctionPeriodUpdated(
    address nftContractAddress,
    uint256 tokenId,
    uint256 auctionEndPeriod
  );

  event NFTTransferredAndSellerPaid(
    address nftContractAddress,
    uint256 tokenId,
    uint256 nftHighestBid,
    address nftHighestBidder,
    address nftSeller,
    address nftRecipient
  );

  event AuctionSettled(
    address indexed nftContractAddress,
    uint256 indexed tokenId,
    uint256 nftHighestBid,
    address auctionSettler
  );

  event AuctionCancelled(
    address nftContractAddress,
    uint256 tokenId,
    address nftSeller
  );

  event BidWithdrawn(
    address nftContractAddress,
    uint256 tokenId,
    address highestBidder
  );

  event MinimumPriceUpdated(
    address nftContractAddress,
    uint256 tokenId,
    uint256 newMinPrice
  );

  event HighestBidTaken(
    address nftContractAddress,
    uint256 tokenId
  );

  /****************************
    *        Modifiers
    ****************************/

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

  modifier notNftSeller(address _nftContractAddress, uint256 _tokenId) {
    require(
      _msgSender() != nftContractAuctions[_nftContractAddress][_tokenId].nftSeller,
      "Owner cannot bid on own NFT"
    );
    _;
  }

  modifier onlyNftSeller(address _nftContractAddress, uint256 _tokenId) {
    require(
      _msgSender() == nftContractAuctions[_nftContractAddress][_tokenId].nftSeller,
      "Only nft seller"
    );
    _;
  }

  modifier bidAmountMeetsBidRequirements(
    address _nftContractAddress,
    uint256 _tokenId,
    uint256 _tokenAmount
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

  modifier minimumBidNotMade(address _nftContractAddress, uint256 _tokenId) {
    require(
      !_isMinimumBidMade(_nftContractAddress, _tokenId),
      "The auction has a valid bid made"
    );
    _;
  }

  modifier paymentAccepted(
    address _nftContractAddress,
    uint256 _tokenId,
    address _paymentToken,
    uint256 _amount
  ) {
    require(
      _isPaymentAccepted(
        _nftContractAddress,
        _tokenId,
        _paymentToken,
        _amount
      )
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

  modifier increasePercentageAboveMinimum(uint16 _bidIncreasePercentage) {
    require(
      _bidIncreasePercentage >= minimumSettableIncreasePercentage,
      "Bid increase percentage too low"
    );
    _;
  }

  /**********************************
    *        Check functions
    **********************************/

  /**
    * @notice Check the status of an auction
    * @param _nftContractAddress The address of NFT collectible
    * @param _tokenId Token id of NFT item in collectible
    * @return True if the auction is still going on and vice versa 
    */
  function _isAuctionOngoing(address _nftContractAddress, uint256 _tokenId)
    internal
    view
    returns (bool)
  {
    uint256 auctionEndTimestamp = nftContractAuctions[_nftContractAddress][_tokenId].auctionEnd;
    return (auctionEndTimestamp == 0 || block.timestamp < auctionEndTimestamp);
  }

  /**
    * @notice Check if a bid has been made. This is applicable in the early bid scenario
    * to ensure that if an auction is created after an early bid, the auction
    * begins appropriately or is settled if the buy now price is met.
    * @param _nftContractAddress The address of NFT collectible
    * @param _tokenId Token id of NFT item in collectible
    * @return True if there is a bid
    */
  function _isABidMade(address _nftContractAddress, uint256 _tokenId)
    internal
    view 
    returns (bool)
  {
    return (nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid > 0);
  }

  /**
    * @notice if the minPrice is set by the seller, check that the highest bid meets or exceeds that price.
    * @param _nftContractAddress The address of NFT collectible
    * @param _tokenId Token id of NFT item in collectible
    */
  function _isMinimumBidMade(address _nftContractAddress, uint256 _tokenId)
    internal
    view
    returns (bool)
  {
    uint256 minPrice = nftContractAuctions[_nftContractAddress][_tokenId].minPrice;
    return minPrice > 0 &&
      (nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid >= minPrice);
  }

  /**
    * @notice Check that a bid is applicable for the purchase of the NFT. The bid needs to be a % higher than the previous bid.
    * @param _nftContractAddress The address of NFT collectible
    * @param _tokenId Token id of NFT item in collectible
    */
  function _doesBidMeetBidRequirements(
    address _nftContractAddress,
    uint256 _tokenId,
    uint256 _tokenAmount
  ) internal view returns (bool) {
    uint256 nextBidAmount;
    if (nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid == 0) {
      nextBidAmount = nftContractAuctions[_nftContractAddress][_tokenId].minPrice;
    } else {
      nextBidAmount = (nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid * 
        (10000 + nftContractAuctions[_nftContractAddress][_tokenId].bidIncreasePercentage)) / 10000;
    }
    return (msg.value >= nextBidAmount || _tokenAmount >= nextBidAmount);
  }

  function _isPaymentAccepted(
    address _nftContractAddress,
    uint256 _tokenId,
    address _paymentToken,
    uint256 _amount
  ) internal view returns (bool) {
    address paymentToken = nftContractAuctions[_nftContractAddress][_tokenId].paymentToken;
    if (paymentToken == address(0)) {
      return 
        _paymentToken == address(0) &&
        msg.value != 0 &&
        _amount == 0;
    } else {
      return
        msg.value == 0 &&
        paymentToken == _paymentToken &&
        _amount > 0;
    }
  }


  /**
    * @param _totalBid the total bid
    * @param _percentage percent of each bid
    * @return the percentage of the total bid (used to calculate fee payments)
    */
  function _getPortionOfBid(uint256 _totalBid, uint16 _percentage)
    internal
    pure
    returns (uint256)
  {
    return (_totalBid * _percentage) / 10000;
  }

  /**
    * @param _nftContractAddress The address of NFT collectible
    * @param _tokenId Token id of NFT item in collectible
    * @return Nft recipient when auction is finished
    */
  function _getNftRecipient(address _nftContractAddress, uint256 _tokenId)
    internal
    view
    returns (address)
  {
    address nftRecipient = nftContractAuctions[_nftContractAddress][_tokenId].nftRecipient;

    if (nftRecipient == address(0)) {
      return nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBidder;
    } else {
      return nftRecipient;
    }
  }

  /*************************************
    *      Transfer NFTs to Contract
    *************************************/

  /**
    * @notice Transfer an NFT to auction's contract
    * @param _nftContractAddress The address of NFT collectible
    * @param _tokenId Token id of NFT item in collectible
    */
  function _transferNftToAuctionContract(
    address _nftContractAddress,
    uint256 _tokenId
  ) internal {
    require(IERC721(_nftContractAddress).ownerOf(_tokenId) == _msgSender(), "Only owner can call this");
    IERC721(_nftContractAddress).transferFrom(_msgSender(), address(this), _tokenId);
  }

  /**
    * @notice Transfer batch of NFTs to auction's contract
    * @param _nftContractAddress The address of NFT collectible
    * @param _batchTokenIds Token id of NFT item in collectible
    */
  function _transferNftBatchToAuctionContract(
    address _nftContractAddress,
    uint256[] memory _batchTokenIds
  ) internal {
    for (uint256 i = 0; i < _batchTokenIds.length; i++) {
      require(IERC721(_nftContractAddress).ownerOf(_batchTokenIds[i]) == _msgSender(), "Only owner can call this");
      IERC721(_nftContractAddress).transferFrom(_msgSender(), address(this), _batchTokenIds[i]);
    }
    _reverseAndResetPreviousBid(_nftContractAddress, _batchTokenIds[0]);
    nftContractAuctions[_nftContractAddress][_batchTokenIds[0]].batchTokenIds = _batchTokenIds;
  }

  /****************************
    *     Auction creation
    ****************************/

  /**
    * @notice Set up primary parameters of an auction
    * @param _nftContractAddress The address of NFT collectible
    * @param _tokenId Token id of NFT item in collectible
    * @param _minPrice Minimum price
    * @param _auctionBidPeriod Auction bid period
    * @param _bidIncreasePercentage Increased percentage of each bid
    */
  function _setupAuction(
    address _nftContractAddress,
    uint256 _tokenId,
    address _paymentToken,
    uint256 _minPrice,
    uint256 _auctionBidPeriod,
    uint16 _bidIncreasePercentage
  )
    internal
  {
    nftContractAuctions[_nftContractAddress][_tokenId].paymentToken = _paymentToken;
    nftContractAuctions[_nftContractAddress][_tokenId].minPrice = _minPrice;
    nftContractAuctions[_nftContractAddress][_tokenId].auctionBidPeriod = _auctionBidPeriod;
    nftContractAuctions[_nftContractAddress][_tokenId].auctionEnd = block.timestamp + _auctionBidPeriod;
    nftContractAuctions[_nftContractAddress][_tokenId].bidIncreasePercentage = _bidIncreasePercentage;
    nftContractAuctions[_nftContractAddress][_tokenId].nftSeller = _msgSender();
    nftContractAuctions[_nftContractAddress][_tokenId].liveOn = 1;
  }

  /**
    * @notice Create an auction
    * @param _nftContractAddress The address of NFT collectible
    * @param _tokenId Token id of NFT item in collectible
    * @param _minPrice Minimum price
    * @param _auctionBidPeriod Auction bid period
    * @param _bidIncreasePercentage Increased percentage of each bid
    */
  function _createNewNftAuction(
    address _nftContractAddress,
    uint256 _tokenId,
    address _paymentToken,
    uint256 _minPrice,
    uint256 _auctionBidPeriod,
    uint16 _bidIncreasePercentage
  ) internal {
    _transferNftToAuctionContract(_nftContractAddress, _tokenId);
    _setupAuction(
      _nftContractAddress,
      _tokenId,
      _paymentToken,
      _minPrice,
      _auctionBidPeriod,
      _bidIncreasePercentage
    );
    emit NftAuctionCreated(
      _nftContractAddress,
      _tokenId,
      _msgSender(),
      _paymentToken,
      _minPrice,
      nftContractAuctions[_nftContractAddress][_tokenId].auctionEnd,
      _bidIncreasePercentage
    );
  }

  function createNewNftAuction(
    address _nftContractAddress,
    uint256 _tokenId,
    address _paymentToken,
    uint256 _minPrice,
    uint256 _auctionBidPeriod,
    uint16 _bidIncreasePercentage
  )
    public
    priceGreaterThanZero(_minPrice)
    increasePercentageAboveMinimum(_bidIncreasePercentage)
  {
    _createNewNftAuction(
      _nftContractAddress,
      _tokenId,
      _paymentToken,
      _minPrice,
      _auctionBidPeriod,
      _bidIncreasePercentage
    );
  }

  /**
    * @notice Create an batch of NFTs auction
    * @param _nftContractAddress The address of NFT collectible
    * @param _batchTokenIds Batch of token id of NFT items in collectible
    * @param _minPrice Minimum price
    * @param _auctionBidPeriod Auction bid period
    * @param _bidIncreasePercentage Increased percentage of each bid
    */
  function _createBatchNftAuction(
    address _nftContractAddress,
    uint256[] memory _batchTokenIds,
    address _paymentToken,
    uint256 _minPrice,
    uint256 _auctionBidPeriod,
    uint16 _bidIncreasePercentage
  ) internal {
    _transferNftBatchToAuctionContract(_nftContractAddress, _batchTokenIds);
    _setupAuction(
      _nftContractAddress,
      _batchTokenIds[0],
      _paymentToken,
      _minPrice,
      _auctionBidPeriod,
      _bidIncreasePercentage
    );
    emit NftBatchAuctionCreated(
      _nftContractAddress,
      _batchTokenIds[0],
      _batchTokenIds,
      _msgSender(),
      _paymentToken,
      _minPrice,
      _auctionBidPeriod,
      _bidIncreasePercentage
    );
}

  function createBatchNftAuction(
    address _nftContractAddress,
    uint256[] memory _batchTokenIds,
    address _paymentToken,
    uint256 _minPrice,
    uint256 _auctionBidPeriod,
    uint16 _bidIncreasePercentage
  )
    public
    priceGreaterThanZero(_minPrice)
    increasePercentageAboveMinimum(_bidIncreasePercentage)
  {
    _createBatchNftAuction(
      _nftContractAddress,
      _batchTokenIds,
      _paymentToken,
      _minPrice,
      _auctionBidPeriod,
      _bidIncreasePercentage
    );
  }

  /*******************************
    *       Bid Functions
    *******************************/
  
  /**
    * @notice Make bid on ongoing auction
    * @param _nftContractAddress The address of NFT collectible
    * @param _tokenId Token id of NFT item in collectible
    */
  function _makeBid(
    address _nftContractAddress,
    uint256 _tokenId,
    address _paymentToken,
    uint256 _tokenAmount
  )
    internal
    notNftSeller(_nftContractAddress, _tokenId)
    paymentAccepted(_nftContractAddress, _tokenId, _paymentToken, _tokenAmount)
    bidAmountMeetsBidRequirements(_nftContractAddress, _tokenId, _tokenAmount)
  {
    require(nftContractAuctions[_nftContractAddress][_tokenId].liveOn == 1, "Auction is not live on");
    _reversePreviousBidAndUpdateHighestBid(_nftContractAddress, _tokenId, _tokenAmount);
    uint256 amount = _paymentToken == address(0) ? msg.value : _tokenAmount;
    emit BidMade(_nftContractAddress, _tokenId, _msgSender(), _paymentToken, amount);
  }

  function makeBid(
    address _nftContractAddress,
    uint256 _tokenId,
    address _paymentToken,
    uint256 _tokenAmount
  )
    public
    payable
    auctionOngoing(_nftContractAddress, _tokenId)
  {
    _makeBid(_nftContractAddress, _tokenId, _paymentToken, _tokenAmount);
  }

  /**
    * @notice Make a custom bid on ongoing auction that lets bidder set up a NFT recipient as the auction is finished
    * @param _nftContractAddress The address of NFT collectible
    * @param _tokenId Token id of NFT item in collectible
    * @param _nftRecipient A recipient when the auction is finished
    */
  function makeCustomBid(
    address _nftContractAddress,
    uint256 _tokenId,
    address _nftRecipient,
    address _paymentToken,
    uint256 _tokenAmount
  )
    public
    payable
    auctionOngoing(_nftContractAddress, _tokenId)
  {
    require(_nftRecipient != address(0));
    nftContractAuctions[_nftContractAddress][_tokenId].nftRecipient = _nftRecipient;
    _makeBid(_nftContractAddress, _tokenId, _paymentToken, _tokenAmount);
  }

  /********************************
   *        Reset Functions
   ********************************/
  
  /**
    * @notice Reset an auction
    * @param _nftContractAddress The address of NFT collectible
    * @param _tokenId Token id of NFT item in collectible
    */
  function _resetAuction(address _nftContractAddress, uint256 _tokenId) internal {
    nftContractAuctions[_nftContractAddress][_tokenId].paymentToken = address(0);
    nftContractAuctions[_nftContractAddress][_tokenId].minPrice = 0;
    nftContractAuctions[_nftContractAddress][_tokenId].auctionEnd = 0;
    nftContractAuctions[_nftContractAddress][_tokenId].auctionBidPeriod = 0;
    nftContractAuctions[_nftContractAddress][_tokenId].bidIncreasePercentage = 0;
    nftContractAuctions[_nftContractAddress][_tokenId].nftSeller = address(0);
    nftContractAuctions[_nftContractAddress][_tokenId].liveOn = 0;
  }

  /**
    * @notice Reset a bid
    * @param _nftContractAddress The address of NFT collectible
    * @param _tokenId Token id of NFT item in collectible
    */
  function _resetBids(address _nftContractAddress, uint256 _tokenId) internal {
    nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBidder = address(0);
    nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid = 0;
    nftContractAuctions[_nftContractAddress][_tokenId].nftRecipient = address(0);
  }

  /********************************
    *         Update Bids
    ********************************/
  
  /**
    * @notice Update highest bid
    * @param _nftContractAddress The address of NFT collectible
    * @param _tokenId Token id of NFT item in collectible
    */
  function _updateHighestBid(
    address _nftContractAddress,
    uint256 _tokenId,
    uint256 _tokenAmount
  ) internal {
    address paymentToken = nftContractAuctions[_nftContractAddress][_tokenId].paymentToken;
    if (paymentToken == address(0)) {
      nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid = msg.value;
    } else {
      IERC20(paymentToken).transferFrom(_msgSender(), address(this), _tokenAmount);
      nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid = _tokenAmount;
    }
    nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBidder = _msgSender();
  }

  /**
    * @notice Set up new highest bid and reverse previous onw
    * @param _nftContractAddress The address of NFT collectible
    * @param _tokenId Token id of NFT item in collectible
    */
  function _reverseAndResetPreviousBid(
    address _nftContractAddress,
    uint256 _tokenId
  ) internal {
    address nftHighestBidder = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBidder;
    uint256 nftHighestBid = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid;
    _resetBids(_nftContractAddress, _tokenId);
    _payout(_nftContractAddress, _tokenId , nftHighestBidder, nftHighestBid);
  }

  /**
    * @notice Set up new highest bid and reverse previous onw
    * @param _nftContractAddress The address of NFT collectible
    * @param _tokenId Token id of NFT item in collectible
    */
  function _reversePreviousBidAndUpdateHighestBid(
    address _nftContractAddress,
    uint256 _tokenId,
    uint256 _tokenAmount
  ) internal {
    address prevNftHighestBidder = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBidder;
    uint256 prevNftHighestBid = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid;
    _updateHighestBid(_nftContractAddress, _tokenId, _tokenAmount);

    if (prevNftHighestBidder != address(0)) {
      _payout(_nftContractAddress, _tokenId, prevNftHighestBidder, prevNftHighestBid);
    }
  }

  /************************************
    *   Transfer NFT and Pay Seller
    ************************************/
  
  /**
    * @notice Set up new highest bid and reverse previous one
    * @param _nftContractAddress The address of NFT collectible
    * @param _tokenId Token id of NFT item in collectible
    */
  function _transferNftAndPaySeller(
    address _nftContractAddress,
    uint256 _tokenId
  ) internal {
    address _nftSeller = nftContractAuctions[_nftContractAddress][_tokenId].nftSeller;
    address _nftHighestBidder = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBidder;
    address _nftRecipient = _getNftRecipient(_nftContractAddress, _tokenId);
    uint256 _nftHighestBid = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid;
    _resetBids(_nftContractAddress, _tokenId);
    _payFeesAndSeller(_nftContractAddress, _tokenId, _nftSeller, _nftHighestBid);
    //reset bid and transfer nft last to avoid reentrancy
    uint256[] memory batchTokenIds = nftContractAuctions[_nftContractAddress][_tokenId].batchTokenIds;
    uint256 numberOfTokens = batchTokenIds.length;
    if (numberOfTokens > 0) {
      for (uint256 i = 0; i < numberOfTokens; i++) {
        IERC721(_nftContractAddress).transferFrom(
          address(this),
          _nftRecipient,
          batchTokenIds[i]
        );
      }
    } else {
      IERC721(_nftContractAddress).transferFrom(
        address(this),
        _nftRecipient,
        _tokenId
      );
    }
    _resetAuction(_nftContractAddress, _tokenId);
    emit NFTTransferredAndSellerPaid(
      _nftContractAddress,
      _tokenId,
      _nftHighestBid,
      _nftHighestBidder,
      _nftSeller,
      _nftRecipient
    );
  }

  /**
    * @notice Pay fees and seller
    * @param _nftContractAddress The address of NFT collectible
    * @param _tokenId Token id of NFT item in collectible
    * @param _nftSeller Address of NFT's seller
    * @param _highestBid The highest bid 
    */
  function _payFeesAndSeller(
    address _nftContractAddress,
    uint256 _tokenId,
    address _nftSeller,
    uint256 _highestBid
  ) internal {
    uint256 serviceFee = _getPortionOfBid(_highestBid, protocolFeePercentage);
    _payout(_nftContractAddress, _tokenId , protocolFeeRecipient, serviceFee);
    _payout(_nftContractAddress, _tokenId ,_nftSeller, (_highestBid - serviceFee));
  }

  function _payout(
    address _nftContractAddress,
    uint256 _tokenId,
    address _recipient,
    uint256 _amount
  ) internal nonReentrant() {
    address paymentToken = nftContractAuctions[_nftContractAddress][_tokenId].paymentToken;
    if (paymentToken == address(0)) {
      (bool success, ) = payable(_recipient).call{value: _amount}("");
      if (!success) {
        failedTransferCredits[_recipient] = failedTransferCredits[_recipient] + _amount;
      }
    } else {
      IERC20(paymentToken).transfer(_recipient, _amount);
    }
  }

  /*********************************
    *      Settle and Withdraw
    *********************************/
  
  /**
    * @notice Settle auction when it is finished
    * @param _nftContractAddress The address of NFT collectible
    * @param _tokenId Token id of NFT item in collectible
    */
  function settleAuction(address _nftContractAddress, uint256 _tokenId)
    public
    isAuctionOver(_nftContractAddress, _tokenId)
    onlyNftSeller(_nftContractAddress, _tokenId)
    nonReentrant
  {
    //when no bider could trasfer nft in seller
    uint256 nftHighestBid;
    if (nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid == 0) {
      IERC721(_nftContractAddress).transferFrom(
        address(this),
        nftContractAuctions[_nftContractAddress][_tokenId].nftSeller,
        _tokenId
      );
      nftHighestBid = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid;
      _resetAuction(_nftContractAddress, _tokenId);
    } else {
      nftHighestBid = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid;
      _transferNftAndPaySeller(_nftContractAddress, _tokenId);
    }
    emit AuctionSettled(_nftContractAddress, _tokenId, nftHighestBid, _msgSender());
  }

  /**
    * @notice Cancel auction and withdraw NFT before a bid is made
    * @param _nftContractAddress The address of NFT collectible
    * @param _tokenId Token id of NFT item in collectible
    */
  function cancelAuction(address _nftContractAddress, uint256 _tokenId)
    public
    minimumBidNotMade(_nftContractAddress, _tokenId)
    onlyNftSeller(_nftContractAddress, _tokenId)
  {
    uint256[] memory batchTokenIds = nftContractAuctions[_nftContractAddress][_tokenId].batchTokenIds;
    uint256 numberOfTokens = batchTokenIds.length;
    uint256 nftHighestBid = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid;
    if (numberOfTokens > 0) {
      for (uint256 i = 0; i < numberOfTokens; i++) {
        IERC721(_nftContractAddress).transferFrom(
          address(this),
          nftContractAuctions[_nftContractAddress][_tokenId].nftSeller,
          batchTokenIds[i]
        );
      }
    } else {
      IERC721(_nftContractAddress).transferFrom(
        address(this),
        nftContractAuctions[_nftContractAddress][_tokenId].nftSeller,
        _tokenId
      );
    }
    _resetAuction(_nftContractAddress, _tokenId);
    emit AuctionCancelled(_nftContractAddress, _tokenId, _msgSender());
    emit AuctionSettled(_nftContractAddress, _tokenId, nftHighestBid, _msgSender());
  }

  /**********************************
    *        Update Auction
    **********************************/
  
  /**
    * @notice Update minimum price
    * @param _nftContractAddress The address of NFT collectible
    * @param _tokenId Token id of NFT item in collectible
    * @param _newMinPrice New min price
    */
  function updateMinimumPrice(
    address _nftContractAddress,
    uint256 _tokenId,
    uint256 _newMinPrice
  )
    public
    onlyNftSeller(_nftContractAddress, _tokenId)
    minimumBidNotMade(_nftContractAddress, _tokenId)
    priceGreaterThanZero(_newMinPrice)
  {
    nftContractAuctions[_nftContractAddress][_tokenId].minPrice = _newMinPrice;
    emit MinimumPriceUpdated(_nftContractAddress, _tokenId, _newMinPrice);
  }

  /**
    * @notice Owner of NFT can take the highest bid and end the auction
    * @param _nftContractAddress The address of NFT collectible
    * @param _tokenId Token id of NFT item in collectible
    */
  function takeHighestBid(address _nftContractAddress, uint256 _tokenId)
    public
    onlyNftSeller(_nftContractAddress, _tokenId)
    nonReentrant
  {
    require(
      _isABidMade(_nftContractAddress, _tokenId),
      "Cannot payout 0 bid"
    );
    uint256 nftHighestBid = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid;
    _transferNftAndPaySeller(_nftContractAddress, _tokenId);
    emit HighestBidTaken(_nftContractAddress, _tokenId);
    emit AuctionSettled(_nftContractAddress, _tokenId, nftHighestBid, _msgSender());
  }

  /****************************************
    *         Other useful functions
    ****************************************/
  
  /**
    * @notice Read owner of a NFT item
    * @param _nftContractAddress The address of NFT collectible
    * @param _tokenId Token id of NFT item in collectible
    */
  function ownerOfNFT(address _nftContractAddress, uint256 _tokenId)
    public
    view
    returns (address)
  {
    address nftSeller = nftContractAuctions[_nftContractAddress][_tokenId].nftSeller;
    require(nftSeller != address(0), "NFT not deposited");

    return nftSeller;
  }

  /**
    * @notice Withdraw failed credits of bidder
    */
  function withdrawAllFailedCredits() public nonReentrant {
    uint256 amount = failedTransferCredits[_msgSender()];

    require(amount != 0, "no credits to withdraw");
    failedTransferCredits[_msgSender()] = 0;

    (bool successfulWithdraw, ) = _msgSender().call{
      value: amount
    }("");
    require(successfulWithdraw, "withdraw failed");
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface of the ERC721 standard as defined in the EIP.
 */
interface IERC721 is IERC165 {
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApproveForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 */

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

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