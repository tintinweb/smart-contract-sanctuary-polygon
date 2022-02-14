/**
 *Submitted for verification at polygonscan.com on 2022-02-13
*/

contract Auction {
    //Represents an auction on an NFT
    struct AuctionDetails {
        //Current owner of NFT
        address payable seller;
        //Price (in wei) at beginning of auction
        uint256 basePrice;
        //Highest bidder
        address highestBidder;
        //Highest bid (in wei)
        uint256 highestBid;
        //Duration (in seconds) of auction
        uint256 endingUnix;
        //Time when auction started
        uint256 startingUnix;
        //To check if the auction has ended
        bool ended;
        //nft contract
        address nftContract;
    }

    struct Bid {
        //Bidder's address
        address bidder;
        //Bidders amount
        uint256 amount;
        //Time
        uint256 biddingUnix;
    }

    //The following structs are used for events only

    struct referenceAuction {
        address seller;
        uint256 basePrice;
        uint256 startingTime;
        referenceToken tokenDetails;
    }

    //Check Reference token with nftContract address and tokenId id

    struct referenceToken {
        address nftContract;
        uint256 tokenId;
    }

    //Event will fire after Listing NFT by artist giving address, Baseprice of the nft, starting and ending time of NFT and token details

    event AuctionCreated(
        address indexed seller,
        uint256 basePrice,
        uint256 indexed startingTime,
        uint256 endingTime,
        referenceToken indexed tokenDetails
    );

    //Event will fire after Placing bid by bider 

    event bidPlaced(
        address indexed bidder,
        uint256 amount,
        uint256 indexed biddingTime,
        referenceAuction indexed auction
    );

    //Event will fire after time is Increased

    event auctionTimeIncreased(
        address indexed seller,
        uint256 basePrice,
        uint256 indexed startingTime,
        uint256 endingTime,
        address highestBidder,
        uint256 highestBid,
        referenceToken indexed tokenDetails
    );

    //Event auctionEnded(address indexed seller, uint256 basePrice , uint256 indexed startingTime, uint256 endingTime, referenceToken indexed tokenDetails, address bidWinner, uint256 winningBid);

    event pendingReturnsWithdrawn(
        address indexed user,
        uint256 indexed amount,
        uint256 indexed withdrawlTime
    );

    //Event will fire after succesfull bidding winner

    event auctionConcluded(
        address indexed seller,
        uint256 basePrice,
        uint256 indexed startingTime,
        uint256 endingTime,
        referenceToken indexed tokenDetails,
        address bidWinner,
        uint256 winningBid,
        uint256 assetsTransferTime
    );

    //Array of auctions for a token
    mapping(address => mapping(uint256 => AuctionDetails))
        public tokenIdToAuction;

    //Allowed withdrawals for who didnt win the bid
    mapping(address => uint256) public pendingReturns;

    //Array of bids in an auction
    mapping(address => mapping(uint256 => Bid[])) public auctionBids;

    //Company's cut in each transfer
    uint256 public companyCutPercentage = 5;

    //Company's address
    address payable private companyERC20Address;

    //Constructor need Payable company token address (owner address )

    constructor() {
        //companyERC20Address = _companyERC20Address;
    }

    //Function for creating auction 

    function createAuction(
        uint256 _basePrice,
        uint256 _endingUnix,
        address _nftContract,
        uint256 _tokenId,
        address _msgSender
    ) public {
        AuctionDetails memory auction = tokenIdToAuction[_nftContract][
            _tokenId
        ];

        _endingUnix = block.timestamp + _endingUnix;

        if (auction.seller != address(0)) {
            require(
                auction.ended == true,
                "An auction for this nft is already in progress"
            );
        }

        require(
            _endingUnix - block.timestamp >= 9,
            "The ending unix should be atleast 5 minutes from now"
        );

        tokenIdToAuction[_nftContract][_tokenId] = AuctionDetails(
            payable(_msgSender),
            _basePrice,
            address(0),
            0,
            _endingUnix,
            block.timestamp,
            false,
            _nftContract
        );

        emit AuctionCreated(
            _msgSender,
            _basePrice,
            block.timestamp,
            _endingUnix,
            referenceToken(_nftContract, _tokenId)
        );
    }

    //Function for seller giving tokenId and payable adddress of nftContract in parameters

    function getSeller(uint256 _tokenId, address payable _nftContract)
        public
        view
        returns (address payable)
    {
        return tokenIdToAuction[_nftContract][_tokenId].seller;
    }

    //Function for updating status for the auction giving tokenId and nftContract address in para meters

    function _updateAuctionStatus(uint256 _tokenId, address _nftContract)
        internal
    {
        AuctionDetails memory auction = tokenIdToAuction[_nftContract][
            _tokenId
        ];

        require(
            auction.seller != address(0),
            "Auction for this NFT is not in progress"
        );

        if (auction.ended == false) {
            if (auction.endingUnix <= block.timestamp) {
                auction.ended = true;
                tokenIdToAuction[_nftContract][_tokenId] = auction;
            }
        }
    }

    //Function for checking the current auction status by giving tokinId and nftContract address in parameters

    function _checkAuctionStatus(uint256 _tokenId, address _nftContract)
        public
        view
        returns (bool)
    {
        AuctionDetails memory auction = tokenIdToAuction[_nftContract][
            _tokenId
        ];

        require(
            auction.seller != address(0),
            "Auction for this NFT is not in progress"
        );

        return auction.ended;
    }

    //Function for find out the current auction time left by giving tokenId and nftContract address in parameters

    function auctionTimeLeft(uint256 _tokenId, address _nftContract)
        public
        view
        returns (uint256)
    {
        AuctionDetails memory auction = tokenIdToAuction[_nftContract][
            _tokenId
        ];

        require(
            auction.seller != address(0),
            "Auction for this NFT is not in progress"
        );

        uint256 timeLeft = auction.endingUnix - block.timestamp;

        return timeLeft;
    }

    //Function for bidder who will bid by giving tokenId, nftContract address and bid amount in parameters

    function bid(
        uint256 _tokenId,
        address _nftContract,
        uint256 _amount
    ) public payable {
        _updateAuctionStatus(_tokenId, _nftContract);

        bool ended = _checkAuctionStatus(_tokenId, _nftContract);

        require(ended == false, "The auction has ended");

        require(
            pendingReturns[msg.sender] + msg.value >= _amount,
            "Insufficient funds"
        );

        AuctionDetails memory auction = tokenIdToAuction[_nftContract][
            _tokenId
        ];

        require(
            msg.sender != auction.seller,
            "You cannot bid in your own auction"
        );

        if (auction.highestBid == 0) {
            require(
                _amount >= auction.basePrice,
                "Your bid is lower than the base price"
            );
        } else {
            require(
                _amount > auction.highestBid,
                "Your bid is lower than the previous bid"
            );
            require(
                _amount - auction.highestBid >= 50000000000000000,
                "Your bid should be atleast 0.5 eth higher than the last bid"
            );
        }

        pendingReturns[msg.sender] =
            pendingReturns[msg.sender] -
            (_amount - msg.value);

        if (auction.highestBid != 0) {
            pendingReturns[auction.highestBidder] += auction.highestBid;
        }

        auction.highestBid = _amount;
        auction.highestBidder = msg.sender;

        if (block.timestamp - auction.endingUnix <= 900) {
            auction.endingUnix = auction.endingUnix + 900;
            emit auctionTimeIncreased(
                auction.seller,
                auction.basePrice,
                auction.startingUnix,
                auction.endingUnix,
                auction.highestBidder,
                auction.highestBid,
                referenceToken(_nftContract, _tokenId)
            );
        }

        tokenIdToAuction[_nftContract][_tokenId] = auction;
        auctionBids[_nftContract][_tokenId].push(
            Bid(msg.sender, _amount, block.timestamp)
        );

        emit bidPlaced(
            msg.sender,
            _amount,
            block.timestamp,
            referenceAuction(
                auction.seller,
                auction.basePrice,
                auction.startingUnix,
                referenceToken(_nftContract, _tokenId)
            )
        );
    }

    //Function for Withdraw funds.
    function withdrawPendingReturns() public payable {
        require(
            pendingReturns[msg.sender] > 0,
            "You do not have any funds to withdraw"
        );

        uint256 pendingReturnAmount = pendingReturns[msg.sender];
        delete pendingReturns[msg.sender];
        payable(msg.sender).transfer(pendingReturnAmount);

        emit pendingReturnsWithdrawn(
            msg.sender,
            pendingReturnAmount,
            block.timestamp
        );
    }

    //Function for check balance.
    function checkPendingReturnsBalance() public view returns (uint256) {
        return pendingReturns[msg.sender];
    }

    function getBidWinner(uint256 _tokenId, address _nftContract)
        public
        view
        returns (address, uint256)
    {
        AuctionDetails memory auction = tokenIdToAuction[_nftContract][
            _tokenId
        ];
        require(auction.highestBid >= 0, "No bids received");
        return (auction.highestBidder, auction.highestBid);
    }

    //Function for concludeAuction by giving tokinId and nftContract address in parameters
    function concludeAuction(uint256 _tokenId, address _nftContract)
        public
        payable
    {
        require(
            (msg.sender == tokenIdToAuction[_nftContract][_tokenId].seller) ||
                (msg.sender ==
                    tokenIdToAuction[_nftContract][_tokenId].highestBidder),
            "You are not authorized to conclude the auction"
        );

        _updateAuctionStatus(_tokenId, _nftContract);

        bool ended = _checkAuctionStatus(_tokenId, _nftContract);

        require(ended == true, "The auction has not ended yet");

        AuctionDetails memory auction = tokenIdToAuction[_nftContract][
            _tokenId
        ];

        delete tokenIdToAuction[_nftContract][_tokenId];
        delete auctionBids[_nftContract][_tokenId];

        uint256 companyCut = (companyCutPercentage * auction.highestBid) / 100;
        uint256 sellerCut = auction.highestBid - companyCut;

        //ERC721(auction.nftContract).transferFrom(address(this), auction.highestBidder , _tokenId);
        auction.seller.transfer(sellerCut);
        companyERC20Address.transfer(companyCut);

        emit auctionConcluded(
            auction.seller,
            auction.basePrice,
            auction.startingUnix,
            auction.endingUnix,
            referenceToken(_nftContract, _tokenId),
            auction.highestBidder,
            auction.highestBid,
            block.timestamp
        );
    }
}