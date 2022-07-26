// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/ICollectionNFT.sol";
import "./interfaces/IStanNFT.sol";
import "./interfaces/IStanToken.sol";
import "./library/DataStructure.sol";

contract Auction {
    mapping(address => uint256) public stanFund;
    mapping(bytes => DataStructure.autionStruct) public auctionIdToAuction;
    mapping(bytes => address[]) public autionIdToParticipants;
    mapping(bytes => DataStructure.Listing) public Listings;
    mapping(bytes => DataStructure.Offer) public Offers;

    address public tokenStanAddress;
    address public stanWalletAddress;
    address private owner;
    DataStructure.feeSystem public feeSystem;
    bytes constant NULL = "";

    IStanToken public tokenStan;
    IStanNFT public stanNFT;
    ICollectionNFT private collectionNFT;

    event STAN_EVENT(
        bytes requestId,
        string nameFunction,
        uint256 tokenId,
        bytes[] offerIds,
        DataStructure.PlatForm platForm
    );

    constructor(
        address _tokenStan,
        address _stanNFT,
        address _collectionNFT,
        address _stanWalletAddress
    ) {
        owner = msg.sender;
        tokenStan = IStanToken(_tokenStan);
        stanNFT = IStanNFT(_stanNFT);
        collectionNFT = ICollectionNFT(_collectionNFT);
        stanWalletAddress = _stanWalletAddress;
    }

    modifier checkNFTOwnerShip(uint256 _tokenId) {
        stanNFT.isApprovedOrOwner(_tokenId);
        _;
    }

    modifier checkValidAmout(uint256 _amount) {
        require(_amount > 0, "Invalid amount");
        _;
    }

    modifier checkStateOfAution(bytes memory _auctionId) {
        require(
            auctionIdToAuction[_auctionId].state ==
                DataStructure.StateOfAution.ACTIVE,
            "Invalid aution state"
        );
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not allowed");
        _;
    }

    function setTokenStan(address _tokenStan) external onlyOwner {
        tokenStan = IStanToken(_tokenStan);
    }

    function setStateAuction(
        bytes memory _auctionId,
        DataStructure.StateOfAution _state
    ) external onlyOwner {
        require(
            auctionIdToAuction[_auctionId].state !=
                DataStructure.StateOfAution.DONE,
            "Cannot change the aution in the past"
        );
        auctionIdToAuction[_auctionId].state = _state;
    }

    function setStanNFT(address _stanNFT) external onlyOwner {
        stanNFT = IStanNFT(_stanNFT);
    }

    function setStanAddress(address _stanAddress) external onlyOwner {
        stanWalletAddress = _stanAddress;
    }

    function setCollectionNFTAddress(address _collectionNFTAddress)
        external
        onlyOwner
    {
        collectionNFT = ICollectionNFT(_collectionNFTAddress);
    }

    function setFeeSystem(uint256 _gasLimit, uint256 _userFee)
        public
        onlyOwner
    {
        feeSystem.gasLimit = _gasLimit;
        feeSystem.userFee = _userFee;
    }

    function getTokenIdFromListing(bytes memory _listingId)
        internal
        view
        returns (uint256)
    {
        return Listings[_listingId].tokenId;
    }

    function getInforOffer(bytes memory _indexId, bytes memory _subOfferId)
        public
        view
        returns (
            uint256,
            address,
            address,
            uint256,
            uint256,
            bytes memory,
            bytes memory,
            bytes memory,
            DataStructure.StateOfOffer
        )
    {
        DataStructure.Offer storage offerInstance = Offers[_indexId];

        DataStructure.subOffer memory subOfferInstance = offerInstance
            .subOffers[_subOfferId];
        bytes memory _idcollection = collectionNFT.getTokenIdToCollectionId(
            offerInstance.tokenId
        );

        return (
            offerInstance.tokenId,
            subOfferInstance.owner,
            subOfferInstance.maker,
            subOfferInstance.amount,
            subOfferInstance.expirationTime,
            offerInstance.nftID,
            offerInstance.auctionID,
            _idcollection,
            subOfferInstance.state
        );
    }

    // Stan transfer fee to receivers
    function purchaseProcessing(
        bytes memory _idCollection,
        address _seller,
        address _buyer,
        uint256 _amount,
        uint256 _fee,
        uint256 _tokenId,
        bool buyFixedPrice
    ) public {
        (
            uint256 ratioCreator,
            uint256 ratioStan,
            address creator,
            ,
            ,

        ) = collectionNFT.getInfoCollection(_idCollection, _tokenId, _seller);
        uint256 fee = (_amount * _fee) / 100;
        require(
            (buyFixedPrice && tokenStan.balanceOf(_buyer) > 0) ||
                stanFund[_buyer] >= (_amount + fee),
            "The balance of buyer is not enought to buy nft"
        );
        uint256 creatorAmount = (_amount * ratioCreator) / 100;
        uint256 creatorStan = (_amount * ratioStan) / 100;
        uint256 remainAmount = _amount - creatorAmount - creatorStan - fee;

        if (buyFixedPrice) {
            tokenStan.purchase(_buyer, stanWalletAddress, _amount);
            tokenStan.purchase(stanWalletAddress, creator, creatorAmount);
            tokenStan.purchase(stanWalletAddress, _seller, remainAmount);
        } else {
            stanFund[_buyer] -= _amount;
            stanFund[creator] += creatorAmount;
            stanFund[_seller] += remainAmount;
        }
    }

    function saveOffer(
        bytes memory _subOfferId,
        bytes memory _indexId,
        uint256 _tokenId,
        address _owner,
        address _maker,
        uint256 _expirationTime,
        uint256 _amount,
        bool isAuction
    ) internal {
        Offers[_indexId].tokenId = _tokenId;
        Offers[_indexId].nftID = isAuction ? NULL : _indexId;
        Offers[_indexId].auctionID = isAuction ? _indexId : NULL;

        Offers[_indexId].subOffers[_subOfferId].subOfferId = _subOfferId;
        Offers[_indexId].subOffers[_subOfferId].owner = _owner;
        Offers[_indexId].subOffers[_subOfferId].maker = _maker;
        Offers[_indexId].subOffers[_subOfferId].amount = _amount;
        Offers[_indexId]
            .subOffers[_subOfferId]
            .expirationTime = _expirationTime;
        Offers[_indexId].subOffers[_subOfferId].state = DataStructure
            .StateOfOffer
            .ACTIVE;
    }

    function getInforListing(bytes memory _indexId)
        public
        view
        returns (
            bytes memory,
            address,
            address,
            uint256,
            uint256,
            bytes memory,
            uint256
        )
    {
        DataStructure.Listing memory listing = Listings[_indexId];

        return (
            listing.ListingID,
            listing.Owner,
            listing.ownerOfNFT,
            listing.ExpirationTime,
            listing.Amount,
            listing.AuctionId,
            listing.tokenId
        );
    }

    function backFeeToUserFund(
        bool _cancelListing,
        bool _isAccepted,
        bytes memory _auctionId,
        bytes memory _subOfferId
    ) internal {
        uint256 length = autionIdToParticipants[_auctionId].length;
        address winner = _isAccepted
            ? Offers[_auctionId].subOffers[_subOfferId].maker
            : auctionIdToAuction[_auctionId].winner;
        if (_cancelListing) {
            for (uint256 i = 0; i < length; ) {
                address addressUser = autionIdToParticipants[_auctionId][i];
                stanFund[addressUser] += auctionIdToAuction[_auctionId]
                    .userToBidnumber[addressUser];
                unchecked {
                    ++i;
                }
            }
        } else {
            for (uint256 i = 0; i < length; ) {
                address addressUser = autionIdToParticipants[_auctionId][i];
                if (addressUser != winner) {
                    stanFund[addressUser] += auctionIdToAuction[_auctionId]
                        .userToBidnumber[addressUser];
                }
                unchecked {
                    ++i;
                }
            }
        }
    }

    function chargeFeeTransferNFT(address _from, uint256 _fee) internal {
        require(_from != address(0), "The address is invalid");
        require(
            stanFund[_from] - _fee > 0,
            "The balance of user exceed the fee"
        );

        stanFund[_from] -= _fee;
    }

    function processCancelListing(
        bytes memory _listingId,
        bytes memory _requestId
    ) internal {
        require(
            Listings[_listingId].Owner == msg.sender,
            "You are not allowed"
        );
        (, address _owner, , , , , uint256 _tokenId) = getInforListing(
            _listingId
        );
        Listings[_listingId].state = DataStructure.StateOfListing.INACTIVE;
        stanNFT.updateOwnerNFTAndTransferNFT(
            collectionNFT.getTokenIdToCollectionId(_tokenId),
            address(stanNFT),
            _owner,
            _tokenId,
            _requestId
        );
        delete Listings[_listingId];
    }

    function processEvent(
        bytes[] memory arrayString,
        uint256 _tokenId,
        bytes memory _requestId,
        string memory _nameFunct,
        DataStructure.PlatForm platform
    ) internal {
        DataStructure.dataStructure memory dataInstance = DataStructure
            .dataStructure(_tokenId, arrayString);

        emit STAN_EVENT(
            _requestId,
            _nameFunct,
            dataInstance.tokenId,
            dataInstance.offerIds,
            platform
        );
    }

    function listingNFTFixedPrice(
        bytes memory _listingId,
        uint256 _amount,
        uint256 _tokenId,
        uint256 _expirationTime,
        bytes memory _requestId
    ) external {
        require(
            msg.sender == stanNFT.ownerOf(_tokenId),
            "You are not the owner of this NFT"
        );

        DataStructure.Listing memory newInstance = DataStructure.Listing(
            _listingId,
            msg.sender,
            address(stanNFT),
            _expirationTime,
            _amount,
            _tokenId,
            "",
            DataStructure.StateOfListing.ACTIVE,
            false
        );
        Listings[_listingId] = newInstance;
        stanNFT.setPriceNFT(_tokenId, _amount);
        stanNFT.updateTokenToListing(_listingId, _tokenId);
        bytes memory _idCollection = collectionNFT.getTokenIdToCollectionId(
            _tokenId
        );
        stanNFT.updateOwnerNFTAndTransferNFT(
            _idCollection,
            msg.sender,
            address(stanNFT),
            _tokenId,
            _requestId
        );
        bytes[] memory arrayString = new bytes[](0);

        processEvent(
            arrayString,
            _tokenId,
            _requestId,
            "LIST_FIXED_PRICE",
            DataStructure.PlatForm.WEB
        );
    }

    function listingNFTAuction(
        bytes memory _auctionId,
        bytes memory _requestId,
        uint256 _amount,
        uint256 _tokenId,
        uint256 _expirationTime
    ) external {
        require(
            msg.sender == stanNFT.ownerOf(_tokenId),
            "You are not the owner of this NFT"
        );
        DataStructure.Listing memory newInstance = DataStructure.Listing(
            _auctionId,
            msg.sender,
            address(stanNFT),
            _expirationTime,
            _amount,
            _tokenId,
            _auctionId,
            DataStructure.StateOfListing.ACTIVE,
            true
        );
        Listings[_auctionId] = newInstance;

        auctionIdToAuction[_auctionId].autionId = _auctionId;
        auctionIdToAuction[_auctionId].tokenId = _tokenId;
        auctionIdToAuction[_auctionId].state = DataStructure
            .StateOfAution
            .ACTIVE;
        auctionIdToAuction[_auctionId].owner = msg.sender;
        Listings[_auctionId].state = DataStructure.StateOfListing.ACTIVE;

        bytes memory _idCollection = collectionNFT.getTokenIdToCollectionId(
            _tokenId
        );
        stanNFT.updateOwnerNFTAndTransferNFT(
            _idCollection,
            msg.sender,
            address(stanNFT),
            _tokenId,
            _requestId
        );

        bytes[] memory arrayString = new bytes[](0);

        processEvent(
            arrayString,
            _tokenId,
            _requestId,
            "LIST_AUCTION",
            DataStructure.PlatForm.WEB
        );
    }

    function buyFixPrice(
        address _seller,
        uint256 _tokenId,
        bytes memory _idCollection,
        bytes memory _requestId
    ) external {
        bytes memory _listingId = stanNFT.getTokenToListing(_tokenId);
        require(
            !Listings[_listingId].isAuction,
            "Cannot buy NFT is on auction"
        );
        require(
            Listings[_listingId].state == DataStructure.StateOfListing.ACTIVE,
            "The NFT is not listed"
        );
        address _buyer = msg.sender;
        uint256 priceOfNFT = stanNFT.getPriceNFT(_tokenId);

        require(
            priceOfNFT != 0 && tokenStan.balanceOf(_buyer) > priceOfNFT,
            "You are not afford to buy this NFT"
        );

        Listings[_listingId].ownerOfNFT = _buyer;
        Listings[_listingId].state = DataStructure.StateOfListing.INACTIVE;

        purchaseProcessing(
            _idCollection,
            _seller,
            _buyer,
            priceOfNFT,
            0,
            _tokenId,
            true
        );

        stanNFT.updateOwnerNFTAndTransferNFT(
            _idCollection,
            address(stanNFT),
            _buyer,
            _tokenId,
            _requestId
        );

        bytes[] memory arrayString = new bytes[](0);

        processEvent(
            arrayString,
            _tokenId,
            _requestId,
            "BUY_NFT",
            DataStructure.PlatForm.WEB
        );
    }

    function cancelListingFixedPrice(
        bytes memory _listingId,
        bytes memory _requestId
    ) external {
        processCancelListing(_listingId, _requestId);

        bytes[] memory arrayString = new bytes[](0);
        uint256 tokenId = getTokenIdFromListing(_listingId);

        processEvent(
            arrayString,
            tokenId,
            _requestId,
            "CANCEL_LISTING_FIX_PRICE",
            DataStructure.PlatForm.WEB
        );
    }

    function cancelListingAuction(
        bytes memory _listingId,
        bytes memory _requestId
    ) external {
        require(
            stanFund[msg.sender] >= feeSystem.userFee,
            "Your Stan Fund is not afford to proceed this function"
        );

        processCancelListing(_listingId, _requestId);

        stanFund[msg.sender] -= feeSystem.userFee;
        uint256 tokenId = getTokenIdFromListing(_listingId);

        bytes[] memory arrayString = new bytes[](0);

        processEvent(
            arrayString,
            tokenId,
            _requestId,
            "CANCEL_LISTING_AUCTION",
            DataStructure.PlatForm.WEB
        );
    }

    function makeOfferFixedPrice(
        bytes memory _subOfferId,
        bytes memory _nftID,
        bytes memory _requestId,
        uint256 _tokenId,
        uint256 _expirationTime,
        uint256 _amount
    ) external checkValidAmout(_amount) {
        address _maker = msg.sender;
        require(
            stanFund[_maker] >= _amount,
            "Your stan fund is not enough to make offer"
        );

        require(
            _expirationTime > block.timestamp,
            "This NFT is not available for making offer"
        );

        address ownerOfNFT = stanNFT.ownerOf(_tokenId);
        saveOffer(
            _subOfferId,
            _nftID,
            _tokenId,
            ownerOfNFT,
            _maker,
            _expirationTime,
            _amount,
            false
        );

        bytes[] memory arrayString = new bytes[](0);

        processEvent(
            arrayString,
            _tokenId,
            _requestId,
            "MAKE_OFFER_WITH_NFT",
            DataStructure.PlatForm.WEB
        );
    }

    function reOffer(
        bytes memory _auctionId,
        bytes memory _subOfferId,
        uint256 _amount,
        bytes memory _requestId
    ) external checkValidAmout(_amount) {
        (
            uint256 tokenId,
            ,
            address maker,
            uint256 currentOfferAmount,
            ,
            ,
            ,
            ,
            DataStructure.StateOfOffer state
        ) = getInforOffer(_auctionId, _subOfferId);

        require(
            currentOfferAmount < _amount &&
                maker != address(0) &&
                state == DataStructure.StateOfOffer.ACTIVE,
            "ReOffer failed"
        );

        Offers[_auctionId].subOffers[_subOfferId].amount = _amount;
        stanFund[maker] -= (_amount - currentOfferAmount);
        auctionIdToAuction[_auctionId].userToBidnumber[maker] = _amount;

        bytes[] memory arrayString = new bytes[](0);

        processEvent(
            arrayString,
            tokenId,
            _requestId,
            "RE_OFFER",
            DataStructure.PlatForm.WEB
        );
    }

    function placeBidAuction(
        bytes memory _subOfferId,
        bytes memory _auctionId,
        bytes memory _requestId,
        uint256 _expirationTime,
        uint256 _amount
    ) external checkValidAmout(_amount) {
        require(
            stanFund[msg.sender] >= feeSystem.userFee,
            "Your Stan Fund is not afford to proceed this function"
        );
        (
            ,
            address _owner,
            ,
            uint256 ExpirationTime,
            ,
            ,
            uint256 _tokenId
        ) = getInforListing(_auctionId);

        require(
            ExpirationTime > _expirationTime,
            "Invalid expiration of place bid request"
        );

        address _maker = msg.sender;
        stanFund[_maker] -= feeSystem.userFee;
        saveOffer(
            _subOfferId,
            _auctionId,
            _tokenId,
            _owner,
            _maker,
            _expirationTime,
            _amount,
            true
        );

        bytes[] memory arrayString = new bytes[](0);
        autionIdToParticipants[_auctionId].push(_maker);
        auctionIdToAuction[_auctionId].offerAmount += 1;
        auctionIdToAuction[_auctionId].offerIds.push(_subOfferId);
        auctionIdToAuction[_auctionId].userToBidnumber[_maker] = _amount;
        auctionIdToAuction[_auctionId].offerIdToIndex[_subOfferId] =
            auctionIdToAuction[_auctionId].offerIds.length -
            1;

        processEvent(
            arrayString,
            _tokenId,
            _requestId,
            "MAKE_OFFER_WITH_AUCTION",
            DataStructure.PlatForm.WEB
        );
    }

    function acceptOfferPvP(
        bytes memory _nftId,
        bytes memory _subOfferId,
        bytes memory _requestId
    ) external {
        (
            uint256 tokenId,
            ,
            address maker,
            uint256 amount,
            uint256 expirationTime,
            ,
            ,
            bytes memory _collectionId,
            DataStructure.StateOfOffer state
        ) = getInforOffer(_nftId, _subOfferId);

        address ownerOfNFT = stanNFT.ownerOf(tokenId);

        require(msg.sender == ownerOfNFT, "You are not the owner of this NFT");

        require(
            state == DataStructure.StateOfOffer.ACTIVE,
            "This state is not proper for this function"
        );

        require(
            block.timestamp < expirationTime,
            "This offer has already outdated"
        );

        Offers[_nftId].subOffers[_subOfferId].state = DataStructure
            .StateOfOffer
            .DONE;

        purchaseProcessing(
            _collectionId,
            ownerOfNFT,
            maker,
            amount,
            0,
            tokenId,
            false
        );

        stanNFT.updateOwnerNFTAndTransferNFT(
            _collectionId,
            ownerOfNFT,
            maker,
            tokenId,
            _requestId
        );
        bytes[] memory arrayString = new bytes[](0);

        processEvent(
            arrayString,
            tokenId,
            _requestId,
            "ACCEPT_OFFER_WITH_NFT",
            DataStructure.PlatForm.WEB
        );
    }

    function acceptOfferAuction(
        bytes memory _auctionId,
        bytes memory _subOfferId,
        bytes memory _requestId
    ) external {
        (
            uint256 tokenId,
            address ownerOfOffer,
            address maker,
            uint256 amount,
            uint256 expirationTime,
            ,
            ,
            bytes memory _collectionId,
            DataStructure.StateOfOffer state
        ) = getInforOffer(_auctionId, _subOfferId);

        (, , address ownerOfNFT, , , , ) = getInforListing(_auctionId);

        require(
            state == DataStructure.StateOfOffer.ACTIVE,
            "This state is not proper for this function"
        );

        require(
            block.timestamp < expirationTime,
            "This offer has already outdated"
        );

        auctionIdToAuction[_auctionId].state = DataStructure.StateOfAution.DONE;
        purchaseProcessing(
            _collectionId,
            ownerOfOffer,
            maker,
            amount,
            0,
            tokenId,
            false
        );
        Offers[_auctionId].subOffers[_subOfferId].state = DataStructure
            .StateOfOffer
            .DONE;
        backFeeToUserFund(false, true, _auctionId, _subOfferId);
        stanNFT.updateOwnerNFTAndTransferNFT(
            _collectionId,
            ownerOfNFT,
            maker,
            tokenId,
            _requestId
        );

        bytes[] memory arrayString = new bytes[](0);

        processEvent(
            arrayString,
            tokenId,
            _requestId,
            "ACCEPT_OFFER_WITH_AUCTION",
            DataStructure.PlatForm.WEB
        );
    }

    function cancelOfferPvP(
        bytes memory _nftId,
        bytes memory _subOfferId,
        bytes memory _requestId
    ) external {
        address maker = Offers[_nftId].subOffers[_subOfferId].maker;
        uint256 tokenId = Offers[_nftId].tokenId;
        require(
            msg.sender == maker,
            "You are not allowed to proceed this function"
        );

        delete Offers[_nftId].subOffers[_subOfferId];
        Offers[_nftId].subOffers[_subOfferId].state = DataStructure
            .StateOfOffer
            .INACTIVE;

        bytes[] memory arrayString = new bytes[](0);
        processEvent(
            arrayString,
            tokenId,
            _requestId,
            "CANCEL_OFFER_WITH_NFT",
            DataStructure.PlatForm.WEB
        );
    }

    function cancelOfferAuction(
        bytes memory _auctionId,
        bytes memory _subOfferId,
        bytes memory _requestId
    ) external {
        address maker = Offers[_auctionId].subOffers[_subOfferId].maker;
        uint256 tokenId = Offers[_auctionId].tokenId;
        require(
            msg.sender == maker,
            "You are not allowed to proceed this function"
        );
        require(
            auctionIdToAuction[_auctionId].offerAmount > 0,
            "Invalid Offer Amount"
        );

        delete Offers[_auctionId].subOffers[_subOfferId];
        Offers[_auctionId].subOffers[_subOfferId].state = DataStructure
            .StateOfOffer
            .INACTIVE;
        uint256 index = auctionIdToAuction[_auctionId].offerIdToIndex[
            _subOfferId
        ];
        delete auctionIdToAuction[_auctionId].offerIds[index];
        auctionIdToAuction[_auctionId].offerAmount -= 1;

        bytes[] memory arrayString = new bytes[](0);

        processEvent(
            arrayString,
            tokenId,
            _requestId,
            "CANCEL_OFFER_WITH_AUCTION",
            DataStructure.PlatForm.WEB
        );
    }

    function cancelOfferPvPAuto(
        bytes memory _nftId,
        bytes[] memory subOffersIdParam,
        bytes memory _requestId
    ) external onlyOwner {
        for (uint256 i = 0; i < subOffersIdParam.length; ) {
            delete Offers[_nftId].subOffers[subOffersIdParam[i]];
            unchecked {
                ++i;
            }
        }

        processEvent(
            subOffersIdParam,
            Offers[_nftId].tokenId,
            _requestId,
            "EXPIRED_FIX_PRICE",
            DataStructure.PlatForm.WEB
        );
    }

    function transferNFTPvP(
        address _receiver,
        uint256 _tokenId,
        bytes memory _requestId
    ) external {
        require(
            stanNFT.ownerOf(_tokenId) == msg.sender &&
                Listings[stanNFT.getTokenToListing(_tokenId)].state ==
                DataStructure.StateOfListing.INACTIVE,
            "Cannot transfer NFT"
        );
        uint256 fee = feeSystem.userFee;
        address sender = msg.sender;
        bytes memory _idCollection = collectionNFT.getTokenIdToCollectionId(
            _tokenId
        );

        chargeFeeTransferNFT(sender, fee);
        stanNFT.updateOwnerNFTAndTransferNFT(
            _idCollection,
            sender,
            _receiver,
            _tokenId,
            _requestId
        );

        bytes[] memory arrayString = new bytes[](0);

        processEvent(
            arrayString,
            _tokenId,
            _requestId,
            "TRANSFER_NFT_PVP",
            DataStructure.PlatForm.WEB
        );
    }

    function deposit(uint256 _amount, bytes memory _requestId)
        external
        checkValidAmout(_amount)
    {
        stanFund[msg.sender] += _amount;
        tokenStan.purchase(msg.sender, stanWalletAddress, _amount);

        bytes[] memory arrayString = new bytes[](0);

        processEvent(
            arrayString,
            0,
            _requestId,
            "DEPOSIT",
            DataStructure.PlatForm.WEB
        );
    }

    function withdraw(uint256 _amount, bytes memory _requestId) external {
        require(
            stanFund[msg.sender] > 0 && stanFund[msg.sender] >= _amount,
            "The amount exceed the balance of user"
        );

        stanFund[msg.sender] -= _amount;
        tokenStan.purchase(stanWalletAddress, msg.sender, _amount);

        bytes[] memory arrayString = new bytes[](0);

        processEvent(
            arrayString,
            0,
            _requestId,
            "WITHDRAW",
            DataStructure.PlatForm.WEB
        );
    }

    function findTheBestFitWinner(bytes memory _auctionId)
        internal
        view
        returns (uint256)
    {
        uint256 max;
        uint256 winnerIndex;

        for (uint256 i = 0; i < auctionIdToAuction[_auctionId].offerAmount; ) {
            uint256 _amount = Offers[_auctionId]
                .subOffers[auctionIdToAuction[_auctionId].offerIds[i]]
                .amount;
            if (_amount > max) {
                max = _amount;
                winnerIndex = i;
            }
            unchecked {
                ++i;
            }
        }

        return winnerIndex;
    }

    function processFinishAuction(
        bytes memory _auctionId,
        bytes memory _winnerSubOfferId,
        bytes memory _requestId
    ) internal returns (uint256) {
        (
            uint256 tokenId,
            address ownerNFT,
            address maker,
            uint256 _amount,
            ,
            ,
            ,
            bytes memory _idCollection,
            DataStructure.StateOfOffer state
        ) = getInforOffer(_auctionId, _winnerSubOfferId);

        require(
            state == DataStructure.StateOfOffer.ACTIVE,
            "Invalid state of offer"
        );

        purchaseProcessing(
            _idCollection,
            ownerNFT,
            maker,
            _amount,
            feeSystem.userFee,
            tokenId,
            false
        );

        stanNFT.updateOwnerNFTAndTransferNFT(
            _idCollection,
            address(stanNFT),
            maker,
            tokenId,
            _requestId
        );

        return tokenId;
    }

    function finishAution(bytes memory _auctionId, bytes memory _requestId)
        external
        onlyOwner
        checkNFTOwnerShip(auctionIdToAuction[_auctionId].tokenId)
        checkStateOfAution(_auctionId)
    {
        require(
            auctionIdToAuction[_auctionId].state ==
                DataStructure.StateOfAution.ACTIVE &&
                Listings[_auctionId].state ==
                DataStructure.StateOfListing.ACTIVE,
            "Invalid state"
        );

        uint256 winnerIndex = findTheBestFitWinner(_auctionId);
        bytes memory winnerSubOfferId = auctionIdToAuction[_auctionId].offerIds[
            winnerIndex
        ];
        address winner = Offers[_auctionId].subOffers[winnerSubOfferId].maker;

        require(
            auctionIdToAuction[_auctionId].userToBidnumber[winner] > 0,
            "Invalid winner"
        );

        auctionIdToAuction[_auctionId].winner = winner;
        auctionIdToAuction[_auctionId].state = DataStructure.StateOfAution.DONE;
        auctionIdToAuction[_auctionId].state = DataStructure.StateOfAution.DONE;
        Listings[_auctionId].state = DataStructure.StateOfListing.INACTIVE;

        backFeeToUserFund(false, false, _auctionId, "");
        uint256 tokenId = processFinishAuction(
            _auctionId,
            winnerSubOfferId,
            _requestId
        );

        bytes[] memory arrayString = new bytes[](0);

        processEvent(
            arrayString,
            tokenId,
            _requestId,
            "FINISH_AUCTION",
            DataStructure.PlatForm.WEB
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../library/DataStructure.sol";

interface ICollectionNFT {
    event STAN_EVENT(
        bytes requestId,
        string nameFunction,
        uint256 tokenId,
        bytes[] offerIds,
        DataStructure.PlatForm platform
    );

    function getTokenIdToCollectionId(uint256 _tokenId)
        external
        view
        returns (bytes memory);

    function createCollection(
        bytes memory _collectionId,
        uint160 _maxColletionNumber,
        uint256 _ratioCreator,
        uint256 _ratioStan,
        bytes memory _requestId
    ) external;

    function addNFTtoCollection(
        bytes memory _idCollection,
        uint256 _tokenId,
        address _creator,
        bytes memory _requestId
    ) external;

    function addNFTtoCollection(
        string memory _idCollection,
        uint256 _tokenId,
        address _creator,
        string memory _requestId
    ) external;

    function updateOwnerNFT(
        bytes memory _idCollection,
        address _from,
        address _to,
        bytes memory _requestId
    ) external;

    function getInfoCollection(
        bytes memory _idCollection,
        uint256 _nft,
        address _currentOwnerNFT
    )
        external
        view
        returns (
            uint256 ratioCreator,
            uint256 ratioStan,
            address creator,
            address owner,
            uint256 nft,
            address currentOwnerNFT
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../library/DataStructure.sol";

interface IStanNFT {
    event STAN_EVENT(
        bytes requestId,
        string nameFunction,
        uint256 tokenId,
        bytes[] offerIds,
        DataStructure.PlatForm platform
    );

    function createNFT(
        bytes memory _idCollection,
        string memory _tokenURI,
        bytes memory _requestId
    ) external returns (uint256);

    function isApprovedOrOwner(uint256 _tokenId) external view;

    function updateTokenToListing(bytes memory _listing, uint256 _tokenId)
        external;

    function getTokenToListing(uint256 _tokenId)
        external
        view
        returns (bytes memory);

    function deleteTokenToListing(uint256 _tokenId) external;

    function getListingResult(uint256 _tokenId) external view returns (bool);

    function setPriceNFT(uint256 _tokenId, uint256 _amount) external;

    function getPriceNFT(uint256 _tokenId) external view returns (uint256);

    function updateOwnerNFTAndTransferNFT(
        bytes memory _idCollection,
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _requestId
    ) external;

    function ownerOf(uint256 _tokenId) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStanToken {
    function purchase(
        address _from,
        address _to,
        uint256 _amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";

library DataStructure {
    using Counters for Counters.Counter;

    enum FunctionName {
        TRANSFER,
        LIST_FIXED_PRICE,
        LIST_AUCTION,
        BUY_NFT,
        CANCEL_LISTING_FIX_PRICE,
        CANCEL_LISTING_AUCTION,
        MAKE_OFFER_WITH_NFT,
        MAKE_OFFER_WITH_AUCTION,
        ACCEPT_OFFER_WITH_NFT,
        ACCEPT_OFFER_WITH_AUCTION,
        CANCEL_OFFER_WITH_NFT,
        CANCEL_OFFER_WITH_AUCTION,
        EXPIRED_FIX_PRICE,
        EXPIRED_AUCTION,
        FINISH_AUCTION,
        EXPIRED_OFFER_WITH_NFT,
        TRANSFER_NFT_PVP,
        DEPOSIT,
        WITHDRAW
    }

    struct dataStructure {
        uint256 tokenId;
        bytes[] offerIds;
    }

    struct autionStruct {
        bytes autionId;
        uint256 tokenId;
        StateOfAution state;
        address owner;
        address winner;
        uint256 offerAmount;
        bytes[] offerIds;
        Type _type;
        mapping(bytes => uint256) offerIdToIndex;
        mapping(address => uint256) userToBidnumber;
    }

    struct feeSystem {
        uint256 gasLimit;
        uint256 userFee;
    }

    struct Offer {
        uint256 tokenId;
        mapping(bytes => subOffer) subOffers;
        bytes nftID;
        bytes auctionID;
    }

    struct subOffer {
        bytes subOfferId;
        address owner;
        address maker;
        uint256 amount;
        uint256 expirationTime;
        StateOfOffer state;
    }

    struct Listing {
        bytes ListingID;
        address Owner;
        address ownerOfNFT;
        uint256 ExpirationTime;
        uint256 Amount;
        uint256 tokenId;
        bytes AuctionId;
        StateOfListing state;
        bool isAuction;
    }

    struct stateCollection {
        bytes id;
        Counters.Counter currentNumber;
        uint256 maxNumber;
        uint256 ratioCreator;
        uint256 ratioStan;
        address owner;
        mapping(uint256 => uint256) NFT;
        mapping(address => address) currentOwnerNFT;
        mapping(uint256 => address) creator;
    }

    enum StateOfListing {
        INACTIVE,
        ACTIVE
    }

    enum Method {
        BUY,
        AUTION
    }

    enum Type {
        POINT,
        CRYPTO
    }

    enum StateOfOffer {
        ACTIVE,
        INACTIVE,
        EXPIRED,
        DONE,
        LISTED,
        UNLISTED
    }

    enum StateOfAution {
        ACTIVE,
        DONE,
        CANCEL,
        EXPIRED
    }

    enum PlatForm {
        WEB,
        MOBILE
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