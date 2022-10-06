// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./interfaces/ICollectionNFT.sol";
import "./interfaces/IStanNFT.sol";
import "./StanToken.sol";
import "./interfaces/IListing.sol";
import "./interfaces/IOffer.sol";
import "./interfaces/IAuctionStorage.sol";
import "./library/AuctionLibrary.sol";

contract Auction {
    using AuctionLibrary for AuctionLibrary.Offer;
    using AuctionLibrary for AuctionLibrary.autionStruct;

    mapping(address => uint256) public stanFund;
    mapping(bytes => AuctionLibrary.Offer) public Offers;
    mapping(address => bool) private whiteList;

    address public tokenStanAddress;
    address public stanWalletAddress;
    address private owner;
    AuctionLibrary.feeSystem public feeSystem;
    bytes constant NULL = "";
    uint256 constant WITHDRAW_PERCENTAGE = 80;

    StanToken public tokenStan;
    IStanNFT public stanNFT;
    ICollectionNFT private collectionNFT;
    IListing private listing;
    IOffer private offer;
    IAuctionStorage private auctionStorage;

    event STAN_EVENT(
        bytes requestId,
        AuctionLibrary.FunctionName nameFunction,
        bool platForm,
        uint256 tokenId
    );

    constructor(
        address _tokenStan,
        address _stanNFT,
        address _collectionNFT,
        address _stanWalletAddress,
        address _listingAddress,
        address _offerAddress,
        address _auctionStorage
    ) {
        owner = msg.sender;
        tokenStan = StanToken(_tokenStan);
        stanNFT = IStanNFT(_stanNFT);
        collectionNFT = ICollectionNFT(_collectionNFT);
        stanWalletAddress = _stanWalletAddress;
        whiteList[owner] = true;
        listing = IListing(_listingAddress);
        offer = IOffer(_offerAddress);
        auctionStorage = IAuctionStorage(_auctionStorage);
    }

    modifier checkStateOfAution(bytes memory _auctionId) {
        (, , AuctionLibrary.StateOfAution state, , , , ) = auctionStorage
            .getInforAuction(_auctionId);
        if (state != AuctionLibrary.StateOfAution.ACTIVE) revert InvalidState();
        _;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert InvalidOwner();
        _;
    }

    modifier onlyOwnerNFT(uint256 _tokenId) {
        if (msg.sender != stanNFT.ownerOf(_tokenId) && !whiteList[msg.sender])
            revert InvalidOwnerNFT();
        _;
    }

    function setTokenStan(address _tokenStan) external onlyOwner {
        tokenStan = StanToken(_tokenStan);
    }

    function setWhileList(address _user) external onlyOwner {
        whiteList[_user] = true;
    }

    function setStanNFT(address _stanNFT) external onlyOwner {
        stanNFT = IStanNFT(_stanNFT);
    }

    function setAuctionStorage(address _auctionStorage) external onlyOwner {
        auctionStorage = IAuctionStorage(_auctionStorage);
    }

    function setStanAddress(address _stanAddress) external onlyOwner {
        if (_stanAddress == address(0)) revert InvalidAddress();
        stanWalletAddress = _stanAddress;
    }

    function setCollectionNFTAddress(address _collectionNFTAddress)
        external
        onlyOwner
    {
        collectionNFT = ICollectionNFT(_collectionNFTAddress);
    }

    function setFeeSystem(uint128 _stanFee, uint128 _serviceFee)
        external
        onlyOwner
    {
        AuctionLibrary.feeSystem memory FeeSystem = AuctionLibrary.feeSystem(
            _stanFee,
            _serviceFee
        );
        feeSystem = FeeSystem;
    }

    function distributeToken(
        uint256 _amount,
        address _buyer,
        address _seller,
        address creator,
        uint256 fee,
        uint256 ratioCreator,
        uint256 ratioStan,
        AuctionLibrary.Method _method
    ) private {
        uint256 creatorAmount = (_amount * ratioCreator) / 100;
        uint256 creatorStan = (_amount * ratioStan) / 100;
        uint256 remainAmount = _amount - creatorAmount - creatorStan - fee;

        stanFund[_buyer] = _method == AuctionLibrary.Method.AUCTION
            ? stanFund[_buyer]
            : stanFund[_buyer] - _amount;
        stanFund[creator] += creatorAmount;
        stanFund[_seller] += remainAmount;
    }

    // Stan transfer fee to receivers
    function purchaseProcessing(
        address _seller,
        address _buyer,
        uint256 _amount,
        uint256 _fee,
        uint256 _tokenId,
        AuctionLibrary.Method _method
    ) private {
        (
            uint256 ratioCreator,
            uint256 ratioStan,
            address creator,
            ,
            ,

        ) = collectionNFT.getInfoCollection(
                collectionNFT.getTokenIdToCollectionId(_tokenId),
                _tokenId,
                _seller
            );
        uint256 fee = (_amount * _fee) / 100;
        require(
            (_method == AuctionLibrary.Method.BUY &&
                tokenStan.balanceOf(_buyer) > 0) ||
                stanFund[_buyer] >= (_amount + fee),
            "The balance of buyer is not enought to buy nft"
        );

        distributeToken(
            _amount,
            _buyer,
            _seller,
            creator,
            fee,
            ratioCreator,
            ratioStan,
            _method
        );
    }

    function processEvent(
        uint256 _tokenId,
        bytes memory _requestId,
        AuctionLibrary.FunctionName _nameFunct,
        bool platform
    ) private {
        emit STAN_EVENT(_requestId, _nameFunct, platform, _tokenId);
    }

    function processNFTOwner(
        address _sender,
        address _receiver,
        uint256 _tokenId,
        bytes memory _nftId,
        bool _isWeb
    ) private {
        _isWeb
            ? stanNFT.updateOwnerNFTAndTransferNFT(_sender, _receiver, _tokenId)
            : stanNFT.updateOwnerOfMobile(_nftId, _receiver);
    }

    function getSender(address _maker, address _msgSender)
        private
        view
        returns (address)
    {
        if (_maker != address(0) && !whiteList[_msgSender])
            revert InvalidOwner();

        return _maker != address(0) ? _maker : _msgSender;
    }

    function handleBackFeeToUser(AuctionLibrary.userFund[] memory _users)
        private
    {
        for (uint256 i = 0; i < _users.length; ) {
            stanFund[_users[i].maker] += _users[i].bidnumber;
            unchecked {
                ++i;
            }
        }
    }

    function listingNFTFixedPrice(
        bytes calldata _requestId,
        bytes calldata _listingId,
        uint256 _amount,
        uint256 _tokenId,
        uint256 _expirationTime,
        address _maker,
        bytes calldata _nftId,
        bool _isWeb
    ) external onlyOwnerNFT(_tokenId) {
        processEvent(
            _tokenId,
            _requestId,
            AuctionLibrary.FunctionName.LIST_FIXED_PRICE,
            _isWeb
        );
        listing.listingNFTFixedPrice(
            _listingId,
            _amount,
            _tokenId,
            getSender(_maker, msg.sender),
            _expirationTime,
            _nftId,
            _isWeb
        );
    }

    function listingNFTAuction(
        bytes memory _requestId,
        bytes memory _auctionId,
        uint256 _amount,
        uint256 _tokenId,
        uint256 _expirationTime,
        address _maker,
        bytes memory _nftId,
        bool _isWeb
    ) external onlyOwnerNFT(_tokenId) {
        if (stanFund[msg.sender] < feeSystem.stanFee && !whiteList[msg.sender])
            revert InvalidBalance();

        address maker = getSender(_maker, msg.sender);
        if (!whiteList[msg.sender] || _isWeb)
            stanFund[maker] -= feeSystem.stanFee;

        processEvent(
            _tokenId,
            _requestId,
            AuctionLibrary.FunctionName.LIST_AUCTION,
            _isWeb
        );

        address ownerOfListing = listing.listingNFTAuction(
            _auctionId,
            _amount,
            _tokenId,
            maker,
            _expirationTime,
            _nftId,
            _isWeb
        );
        auctionStorage.listingNFTAuction(_auctionId, _tokenId, ownerOfListing);
    }

    function buyFixPrice(
        bytes memory _requestId,
        address _seller,
        address _maker,
        bytes memory _listingId,
        bool _isWeb
    ) external {
        (
            ,
            ,
            ,
            ,
            ,
            ,
            uint256 _tokenId,
            bool isAuction,
            AuctionLibrary.StateOfListing state,
            bytes memory _nftId
        ) = listing.getInforListing(_listingId);

        if (isAuction) revert NFTAreOnAuction();
        if (state != AuctionLibrary.StateOfListing.ACTIVE)
            revert InvalidState();
        address _buyer = getSender(_maker, msg.sender);
        uint256 priceOfNFT = stanNFT.getPriceNFT(_tokenId);

        if (priceOfNFT != 0 && tokenStan.balanceOf(_buyer) < priceOfNFT)
            revert InvalidBalance();

        listing.updateListing(
            _listingId,
            AuctionLibrary.paramListing(
                _buyer,
                AuctionLibrary.StateOfListing.INACTIVE
            )
        );

        if (!whiteList[msg.sender] || _isWeb)
            purchaseProcessing(
                _seller,
                _buyer,
                priceOfNFT,
                0,
                _tokenId,
                AuctionLibrary.Method.BUY
            );

        processNFTOwner(address(stanNFT), _buyer, _tokenId, _nftId, _isWeb);

        processEvent(
            _tokenId,
            _requestId,
            AuctionLibrary.FunctionName.BUY_NFT,
            _isWeb
        );
    }

    function cancelListingFixedPrice(
        bytes memory _requestId,
        bytes memory _listingId,
        bool _isWeb
    ) external {
        uint256 tokenId = listing.cancelListingFixedPrice(_listingId, _isWeb);

        processEvent(
            tokenId,
            _requestId,
            AuctionLibrary.FunctionName.CANCEL_LISTING_FIX_PRICE,
            _isWeb
        );
    }

    function cancelListingAuction(
        bytes memory _requestId,
        bytes memory _listingId,
        bool _isWeb
    ) external {
        (
            ,
            address ownerOfListing,
            ,
            ,
            ,
            bytes memory auctionId,
            uint256 tokenId,
            ,
            ,

        ) = listing.getInforListing(_listingId);

        if (!whiteList[msg.sender] || _isWeb) {
            handleBackFeeToUser(auctionStorage.backFeeToUserFund(auctionId));
            stanFund[ownerOfListing] -= feeSystem.stanFee;
        }

        if (
            stanFund[ownerOfListing] < feeSystem.stanFee &&
            !whiteList[msg.sender]
        ) revert InvalidBalance();

        processEvent(
            tokenId,
            _requestId,
            AuctionLibrary.FunctionName.CANCEL_LISTING_AUCTION,
            _isWeb
        );

        auctionStorage.changeStateOffers(auctionId, address(0));
        listing.cancelListingAuction(_listingId, _isWeb);
    }

    function makeOfferFixedPrice(
        bytes memory _requestId,
        bytes memory _subOfferId,
        bytes memory _nftID,
        uint256 _tokenId,
        uint256 _expirationTime,
        uint256 _amount,
        address _maker,
        bool _isWeb
    ) external {
        if (_amount <= 0) revert InvalidAmount();
        address maker = getSender(_maker, msg.sender);

        (bytes memory _listingId, address _owner, , , , , , , , ) = listing
            .getInforListing(stanNFT.getTokenToListing(_tokenId));

        if (stanFund[maker] < _amount && !whiteList[msg.sender])
            revert InvalidBalance();
        if (_expirationTime <= block.timestamp) revert InvalidTimestamp();

        address ownerOfNFT = _listingId.length != 0
            ? _owner
            : (
                stanNFT.getOwnerOfNFTMobile(_nftID) == address(0)
                    ? stanNFT.ownerOf(_tokenId)
                    : stanNFT.getOwnerOfNFTMobile(_nftID)
            );

        processEvent(
            _tokenId,
            _requestId,
            AuctionLibrary.FunctionName.MAKE_OFFER_WITH_NFT,
            _isWeb
        );

        offer.makeOfferFixedPrice(
            ownerOfNFT,
            maker,
            _subOfferId,
            _nftID,
            _tokenId,
            _expirationTime,
            _amount
        );
    }

    function reOffer(
        bytes memory _subOfferId,
        bytes memory _auctionId,
        uint256 _amount
    ) private view returns (uint256) {
        (
            ,
            address ownerOffer,
            ,
            uint256 currentAmount,
            ,
            AuctionLibrary.StateOfOffer state
        ) = auctionStorage.getInforOfferAuction(_auctionId, _subOfferId);

        if (
            ownerOffer == address(0) &&
            state == AuctionLibrary.StateOfOffer.INACTIVE
        ) return _amount;

        if ((currentAmount >= _amount)) revert ReOfferFailed();

        return _amount - currentAmount;
    }

    function placeBidAuction(
        bytes memory _requestId,
        bytes memory _subOfferId,
        bytes memory _auctionId,
        uint256 _amount,
        address _maker,
        bool _isWeb
    ) external checkStateOfAution(_auctionId) {
        if (_amount <= 0) revert InvalidAmount();
        address maker = getSender(_maker, msg.sender);
        if (
            stanFund[maker] < (_amount + feeSystem.stanFee) && !whiteList[maker]
        ) revert InvalidBalance();
        (
            ,
            address _owner,
            ,
            uint256 ExpirationTime,
            uint256 Amount,
            ,
            uint256 _tokenId,
            ,
            ,

        ) = listing.getInforListing(_auctionId);

        if (ExpirationTime < block.timestamp) revert InvalidTimestamp();
        if (Amount > _amount && !whiteList[maker]) revert InvalidOffer();
        if (!whiteList[msg.sender] || _isWeb)
            stanFund[maker] -= (reOffer(_subOfferId, _auctionId, _amount) +
                feeSystem.stanFee);

        AuctionLibrary.paramOffer memory params = AuctionLibrary.paramOffer(
            _subOfferId,
            NULL,
            _tokenId,
            _owner,
            maker,
            0,
            _amount,
            true
        );

        processEvent(
            params.tokenId,
            _requestId,
            AuctionLibrary.FunctionName.MAKE_OFFER_WITH_AUCTION,
            _isWeb
        );

        auctionStorage.placeBidAuction(
            _subOfferId,
            _auctionId,
            params,
            _amount,
            maker
        );
    }

    function acceptOfferPvP(
        bytes memory _requestId,
        bytes memory _nftId,
        bytes memory _subOfferId,
        bool _isWeb
    ) external {
        (
            uint256 tokenId,
            address ownerOffer,
            address maker,
            uint256 amount,
            uint256 expirationTime,
            ,
            AuctionLibrary.StateOfOffer state
        ) = offer.getInforOffer(_nftId, _subOfferId);

        if (!whiteList[msg.sender] && msg.sender != ownerOffer)
            revert InvalidOwner();
        if (state != AuctionLibrary.StateOfOffer.ACTIVE) revert InvalidState();
        if (block.timestamp >= expirationTime) revert InvalidTimestamp();
        processEvent(
            tokenId,
            _requestId,
            AuctionLibrary.FunctionName.ACCEPT_OFFER_WITH_NFT,
            _isWeb
        );

        offer.acceptOfferPvP(_nftId, _subOfferId, _isWeb);

        if (!whiteList[msg.sender] || _isWeb)
            purchaseProcessing(
                ownerOffer,
                maker,
                amount,
                0,
                tokenId,
                AuctionLibrary.Method.OTHER
            );
    }

    function acceptOfferAuction(
        bytes memory _requestId,
        bytes memory _auctionId,
        bytes memory _subOfferId,
        bytes memory _nftId,
        bool _isWeb
    ) external {
        (
            uint256 tokenId,
            address OwnerOfOffer,
            address maker,
            uint256 amount,
            ,
            AuctionLibrary.StateOfOffer state
        ) = auctionStorage.getInforOfferAuction(_auctionId, _subOfferId);

        (
            ,
            ,
            ,
            uint256 expirationTime,
            ,
            ,
            ,
            ,
            AuctionLibrary.StateOfListing stateOfListing,

        ) = listing.getInforListing(_auctionId);

        address ownerOfNFT = stanNFT.ownerOf(tokenId);
        if (ownerOfNFT != address(stanNFT)) revert InvalidOwner();
        if (
            state != AuctionLibrary.StateOfOffer.ACTIVE ||
            stateOfListing != AuctionLibrary.StateOfListing.ACTIVE
        ) revert InvalidState();
        if (block.timestamp >= expirationTime) revert InvalidTimestamp();

        processEvent(
            tokenId,
            _requestId,
            AuctionLibrary.FunctionName.ACCEPT_OFFER_WITH_AUCTION,
            _isWeb
        );

        auctionStorage.acceptOfferAuction(_auctionId, _subOfferId);
        if (!whiteList[msg.sender] || _isWeb)
            purchaseProcessing(
                OwnerOfOffer,
                maker,
                amount,
                0,
                tokenId,
                AuctionLibrary.Method.AUCTION
            );
        processNFTOwner(ownerOfNFT, maker, tokenId, _nftId, _isWeb);
        if (_nftId.length > 0) offer.updateOwnerOfNFT(_nftId, maker);
    }

    function cancelOfferPvP(
        bytes memory _requestId,
        bytes memory _nftId,
        bytes memory _subOfferId,
        bool _isWeb
    ) external {
        uint256 tokenId = offer.cancelOfferPvP(
            _nftId,
            _subOfferId,
            msg.sender,
            whiteList[msg.sender]
        );

        processEvent(
            tokenId,
            _requestId,
            AuctionLibrary.FunctionName.CANCEL_OFFER_WITH_NFT,
            _isWeb
        );
    }

    function cancelOfferAuction(
        bytes memory _requestId,
        bytes memory _auctionId,
        bytes calldata _subOfferId,
        bool _isWeb
    ) external {
        (
            address maker,
            uint256 tokenId,
            uint256 subOfferAmount
        ) = auctionStorage.getInforSubOffer(_auctionId, _subOfferId);

        if (!whiteList[msg.sender] && msg.sender != maker)
            revert InvalidOwner();
        if (!whiteList[msg.sender] || _isWeb) stanFund[maker] += subOfferAmount;

        processEvent(
            tokenId,
            _requestId,
            AuctionLibrary.FunctionName.CANCEL_OFFER_WITH_AUCTION,
            _isWeb
        );

        auctionStorage.cancelOfferAuction(_auctionId, _subOfferId);
    }

    function expiredOffer(
        bytes memory _requestId,
        bytes memory _indexId,
        bytes[] calldata subOffersIdParam,
        bool _isWeb
    ) external onlyOwner {
        (, , , , , bytes memory _auctionId, uint256 _tokenId, , , ) = listing
            .getInforListing(_indexId);

        if (_auctionId.length != 0) {
            auctionStorage.expiredOffer(_indexId, subOffersIdParam);
            if (!whiteList[msg.sender] || _isWeb)
                handleBackFeeToUser(auctionStorage.backFeeToUserFund(_indexId));
        } else {
            offer.expiredOffer(_indexId, subOffersIdParam);
        }

        processEvent(
            _tokenId,
            _requestId,
            AuctionLibrary.FunctionName.EXPIRED_FIX_PRICE,
            _isWeb
        );
    }

    function expiredListing(
        bytes memory _requestId,
        bytes[] memory listingIds,
        bool _isAuction,
        bool _isWeb
    ) external onlyOwner {
        listing.expiredListing(listingIds, _isWeb);

        if (_isAuction) {
            auctionStorage.expiredListing(listingIds);
        }

        processEvent(
            0,
            _requestId,
            AuctionLibrary.FunctionName.EXPIRED_LISTING,
            _isWeb
        );
    }

    function transferNFTPvP(
        bytes memory _requestId,
        address _receiver,
        uint256 _tokenId,
        address _maker,
        bytes memory _nftId,
        bool _isWeb
    ) external {
        address maker = getSender(_maker, msg.sender);
        if (stanFund[maker] < feeSystem.stanFee && !whiteList[msg.sender])
            revert FeeExceedBalance();

        (, , , , , , , , AuctionLibrary.StateOfListing state, ) = listing
            .getInforListing(stanNFT.getTokenToListing(_tokenId));
        if (
            (maker != stanNFT.ownerOf(_tokenId) &&
                maker != stanNFT.getOwnerOfNFTMobile(_nftId)) ||
            state != AuctionLibrary.StateOfListing.INACTIVE
        ) revert CannotTransferNFT();

        if (!whiteList[msg.sender] || _isWeb)
            stanFund[maker] -= feeSystem.stanFee;

        processNFTOwner(maker, _receiver, _tokenId, _nftId, _isWeb);

        processEvent(
            _tokenId,
            _requestId,
            AuctionLibrary.FunctionName.TRANSFER_NFT_PVP,
            _isWeb
        );
    }

    function deposit(
        bytes memory _requestId,
        uint256 _amount,
        bool _isWeb
    ) external {
        if (_amount <= 0) revert InvalidAmount();
        stanFund[msg.sender] += _amount;
        tokenStan.transferFrom(msg.sender, stanWalletAddress, _amount);

        processEvent(
            0,
            _requestId,
            AuctionLibrary.FunctionName.DEPOSIT,
            _isWeb
        );
    }

    function withdraw(
        bytes memory _requestId,
        uint256 _amount,
        bool _isWeb
    ) external {
        if (stanFund[msg.sender] == 0 || _amount > stanFund[msg.sender])
            revert InvalidBalance();

        stanFund[msg.sender] -= _amount;
        tokenStan.transferFrom(stanWalletAddress, msg.sender, _amount);

        processEvent(
            0,
            _requestId,
            AuctionLibrary.FunctionName.WITHDRAW,
            _isWeb
        );
    }

    function claimNFT(
        bytes memory _requestId,
        bytes calldata _nftId,
        bool _isWeb
    ) external {
        if (msg.sender != stanNFT.getOwnerOfNFTMobile(_nftId))
            revert InvalidOwnerNFT();
        uint256 tokenId = stanNFT.processNFTClaiming(
            address(stanNFT),
            msg.sender,
            _nftId,
            0,
            true
        );

        processEvent(
            tokenId,
            _requestId,
            AuctionLibrary.FunctionName.CLAIM_NFT,
            _isWeb
        );
    }

    function depositNFT(
        bytes memory _requestId,
        uint256 _tokenId,
        bytes calldata _nftId,
        bool _isWeb
    ) external {
        if (msg.sender != stanNFT.ownerOf(_tokenId)) revert InvalidOwnerNFT();
        uint256 tokenId = stanNFT.processNFTClaiming(
            msg.sender,
            address(stanNFT),
            _nftId,
            _tokenId,
            false
        );

        processEvent(
            tokenId,
            _requestId,
            AuctionLibrary.FunctionName.DEPOSIT_NFT,
            _isWeb
        );
    }

    function processFinishAuction(
        bytes memory _auctionId,
        bytes memory _winnerSubOfferId,
        bytes memory _nftId,
        bool _isWeb
    ) private returns (uint256) {
        (
            uint256 tokenId,
            address ownerOfOffer,
            address maker,
            uint256 _amount,
            ,
            AuctionLibrary.StateOfOffer state
        ) = auctionStorage.getInforOfferAuction(_auctionId, _winnerSubOfferId);

        if (state != AuctionLibrary.StateOfOffer.ACTIVE) revert InvalidState();

        address ownerNFT = stanNFT.ownerOf(tokenId);

        if (!whiteList[msg.sender] || _isWeb)
            purchaseProcessing(
                ownerOfOffer,
                maker,
                _amount,
                feeSystem.serviceFee,
                tokenId,
                AuctionLibrary.Method.AUCTION
            );

        processNFTOwner(ownerNFT, maker, tokenId, _nftId, _isWeb);
        return tokenId;
    }

    function finishAuction(
        bytes memory _requestId,
        bytes memory _auctionId,
        bytes memory _nftId,
        bool _isWeb
    ) external onlyOwner checkStateOfAution(_auctionId) {
        (
            ,
            ,
            address ownerOfNFT,
            ,
            ,
            ,
            ,
            ,
            AuctionLibrary.StateOfListing state,

        ) = listing.getInforListing(_auctionId);

        if (state != AuctionLibrary.StateOfListing.ACTIVE)
            revert InvalidState();
        (address winner, bytes memory winnerSubOfferId) = auctionStorage
            .finishAuction(_auctionId);
        auctionStorage.changeStateOffers(_auctionId, winner);

        listing.updateListing(
            _auctionId,
            AuctionLibrary.paramListing(
                ownerOfNFT,
                AuctionLibrary.StateOfListing.INACTIVE
            )
        );

        if (_nftId.length > 0) offer.updateOwnerOfNFT(_nftId, winner);
        if (!whiteList[msg.sender] || _isWeb)
            handleBackFeeToUser(auctionStorage.backFeeToUserFund(_auctionId));

        uint256 tokenId = processFinishAuction(
            _auctionId,
            winnerSubOfferId,
            _nftId,
            _isWeb
        );

        processEvent(
            tokenId,
            _requestId,
            AuctionLibrary.FunctionName.FINISH_AUCTION,
            _isWeb
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../library/AuctionLibrary.sol";

interface ICollectionNFT {
    event STAN_EVENT(
        bytes requestId,
        string nameFunction,
        bool platForm,
        uint256 tokenId
    );

    function getTokenIdToCollectionId(uint256 _tokenId)
        external
        view
        returns (bytes memory);

    function setInforCollection(
        uint256 _ratioCreator,
        uint256 _ratioStan,
        uint160 _maxColletionNumber
    ) external;

    function createCollection(
        bytes calldata _requestId,
        bytes calldata _collectionId,
        bool _isWeb
    ) external;

    function createCollectionByStan(
        bytes calldata _requestId,
        address _to,
        bytes calldata _collectionId,
        bool _isWeb
    ) external;

    function addNFTtoCollection(
        bytes calldata _requestId,
        bytes calldata _idCollection,
        uint256 _tokenId,
        address _creator,
        bool _isWeb
    ) external;

    function updateOwnerNFT(
        bytes calldata _idCollection,
        address _from,
        address _to
    ) external;

    function getInfoCollection(
        bytes calldata _idCollection,
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
pragma solidity 0.8.4;

import "../library/AuctionLibrary.sol";

interface IStanNFT {
    event STAN_EVENT(
        bytes requestId,
        string nameFunction,
        bool platForm,
        uint256 tokenId
    );

    function createNFT(
        bytes calldata _requestId,
        bytes calldata _idCollection,
        string calldata _tokenURI,
        bool _isWeb
    ) external returns (uint256);

    function createNFTByStan(
        bytes calldata _requestId,
        bytes calldata _idCollection,
        string calldata _tokenURI,
        address _to,
        bytes calldata _nftID,
        bool _isWeb
    ) external returns (uint256);

    function isApprovedOrOwner(uint256 _tokenId) external view;

    function updateTokenToListing(bytes calldata _listing, uint256 _tokenId)
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
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    function ownerOf(uint256 _tokenId) external view returns (address);

    function processNFTClaiming(
        address _from,
        address _to,
        bytes calldata _nftId,
        uint256 _tokenId,
        bool _isClaim
    ) external returns (uint256);

    function getOwnerOfNFTMobile(bytes calldata _nftId)
        external
        view
        returns (address);

    function updateOwnerOfMobile(bytes calldata _nftId, address _owner)
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract StanToken is ERC20, Ownable {
    constructor() ERC20("Stan", "STC") {
        _mint(msg.sender, 100000 * Decimals());
    }

    function Decimals() public pure returns (uint256) {
        return 10**18;
    }

    function purchase(
        address _from,
        address _to,
        uint256 _amount
    ) external {
        _transfer(_from, _to, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../library/AuctionLibrary.sol";

interface IListing {
    function listingNFTFixedPrice(
        bytes calldata _listingId,
        uint256 _amount,
        uint256 _tokenId,
        address _sender,
        uint256 _expirationTime,
        bytes calldata _nftId,
        bool _isWeb
    ) external;

    function listingNFTAuction(
        bytes calldata _auctionId,
        uint256 _amount,
        uint256 _tokenId,
        address _sender,
        uint256 _expirationTime,
        bytes calldata _nftId,
        bool _isWeb
    ) external returns (address);

    function cancelListingFixedPrice(bytes calldata _listingId, bool _isWeb)
        external
        returns (uint256);

    function cancelListingAuction(bytes calldata _listingId, bool _isWeb)
        external;

    function getInforListing(bytes calldata _listing)
        external
        view
        returns (
            bytes memory,
            address,
            address,
            uint256,
            uint256,
            bytes memory,
            uint256,
            bool,
            AuctionLibrary.StateOfListing,
            bytes memory
        );

    function expiredListing(bytes[] calldata listingIds, bool _isWeb) external;

    function updateListing(
        bytes calldata _listingId,
        AuctionLibrary.paramListing calldata params
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../library/AuctionLibrary.sol";

interface IOffer {
    function makeOfferFixedPrice(
        address _owner,
        address _maker,
        bytes calldata _subOfferId,
        bytes calldata _nftID,
        uint256 _tokenId,
        uint256 _expirationTime,
        uint256 _amount
    ) external;

    function acceptOfferPvP(
        bytes calldata _nftId,
        bytes calldata _subOfferId,
        bool _isWeb
    ) external;

    function cancelOfferPvP(
        bytes calldata _nftId,
        bytes calldata _subOfferId,
        address _sender,
        bool isWhiteList
    ) external returns (uint256);

    function getInforOffer(bytes calldata _indexId, bytes calldata _subOfferId)
        external
        view
        returns (
            uint256,
            address,
            address,
            uint256,
            uint256,
            bytes memory,
            AuctionLibrary.StateOfOffer
        );

    function expiredOffer(
        bytes calldata _indexId,
        bytes[] calldata subOffersIdParam
    ) external;

    function updateOwnerOfNFT(bytes calldata _indexId, address _user) external;

    function getInforOfferBasic(bytes calldata _indexId)
        external
        view
        returns (
            uint256,
            address,
            bytes memory
        );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../library/AuctionLibrary.sol";

interface IAuctionStorage {
    function getInforAuction(bytes calldata _auctionId)
        external
        view
        returns (
            bytes memory,
            uint256,
            AuctionLibrary.StateOfAution,
            address,
            address,
            bytes[] memory,
            AuctionLibrary.Type
        );

    function getInforSubOffer(
        bytes calldata _auctionId,
        bytes calldata _subOfferId
    )
        external
        view
        returns (
            address,
            uint256,
            uint256
        );

    function getInforOfferAuction(
        bytes memory _indexId,
        bytes memory _subOfferId
    )
        external
        view
        returns (
            uint256,
            address,
            address,
            uint256,
            uint256,
            AuctionLibrary.StateOfOffer
        );

    function backFeeToUserFund(bytes memory _auctionId)
        external
        view
        returns (AuctionLibrary.userFund[] memory);

    function changeStateOffers(bytes memory _auctionId, address _exceptionist)
        external;

    function listingNFTAuction(
        bytes memory _auctionId,
        uint256 _tokenId,
        address _ownerOfListing
    ) external;

    function placeBidAuction(
        bytes memory _subOfferId,
        bytes memory _auctionId,
        AuctionLibrary.paramOffer memory _params,
        uint256 _amount,
        address maker
    ) external;

    function acceptOfferAuction(
        bytes memory _auctionId,
        bytes memory _subOfferId
    ) external;

    function cancelOfferAuction(
        bytes memory _auctionId,
        bytes calldata _subOfferId
    ) external;

    function expiredOffer(
        bytes memory _indexId,
        bytes[] calldata subOffersIdParam
    ) external;

    function expiredListing(bytes[] memory listingIds) external;

    function finishAuction(bytes memory _auctionId)
        external
        returns (address, bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../interfaces/ICollectionNFT.sol";
import "../interfaces/IStanNFT.sol";

error InvalidAmount();
error InvalidState();
error InvalidOwner();
error InvalidOwnerNFT();
error InvalidBalance();
error FeeExceedBalance();
error NFTAreOnAuction();
error InvalidTimestamp();
error InvalidOfferAmount();
error InvalidWinner();
error InvalidOffer();
error ReOfferFailed();
error CannotTransferNFT();
error AlreadyInActive();
error InvalidAddress();

library AuctionLibrary {
    enum FunctionName {
        LIST_FIXED_PRICE,
        LIST_AUCTION,
        BUY_NFT,
        CANCEL_LISTING_FIX_PRICE,
        CANCEL_LISTING_AUCTION,
        MAKE_OFFER_WITH_NFT,
        RE_OFFER,
        MAKE_OFFER_WITH_AUCTION,
        ACCEPT_OFFER_WITH_NFT,
        ACCEPT_OFFER_WITH_AUCTION,
        CANCEL_OFFER_WITH_NFT,
        CANCEL_OFFER_WITH_AUCTION,
        EXPIRED_FIX_PRICE,
        EXPIRED_LISTING,
        TRANSFER_NFT_PVP,
        DEPOSIT,
        WITHDRAW,
        WITHDRAW_BY_STAN,
        CLAIM_NFT,
        DEPOSIT_NFT,
        FINISH_AUCTION,
        CREATE_NFT_BY_STAN,
        CREATE_NFT,
        CREATE_COLLECTION,
        ADD_NFT_TO_COLLECTION
    }

    struct autionStruct {
        bytes autionId;
        uint256 tokenId;
        StateOfAution state;
        address owner;
        address winner;
        bytes[] offerIds;
        Type _type;
        Offer offers;
        mapping(bytes => uint256) offerIdToIndex;
        mapping(address => uint256) userToBidnumber;
    }

    struct feeSystem {
        uint128 stanFee;
        uint128 serviceFee;
    }

    struct inforCollection {
        uint128 ratioCreator;
        uint128 ratioStan;
        uint128 maxColletionNumber;
    }

    struct Offer {
        uint256 tokenId;
        mapping(bytes => subOffer) subOffers;
        address owner;
        bytes nftID;
    }

    struct userMobile {
        address owner;
        uint256 tokenId;
    }

    struct subOffer {
        bytes subOfferId;
        address maker;
        uint256 amount;
        uint256 expirationTime;
        StateOfOffer state;
    }

    struct Listing {
        bytes ListingID;
        address Owner;
        address ownerOfNFT;
        bool isAuction;
        uint256 ExpirationTime;
        uint256 Amount;
        uint256 tokenId;
        StateOfListing state;
        bytes AuctionId;
        bytes nftId;
    }

    struct stateCollection {
        bytes id;
        uint128 currentNumber;
        uint128 maxNumber;
        uint128 ratioCreator;
        uint128 ratioStan;
        address owner;
        mapping(uint256 => uint256) NFT;
        mapping(address => address) currentOwnerNFT;
        mapping(uint256 => address) creator;
    }

    struct participant {
        address user;
        uint256 index;
    }

    struct paramListing {
        address ownerOfNFT;
        StateOfListing state;
    }

    struct paramOffer {
        bytes subOfferId;
        bytes indexId;
        uint256 tokenId;
        address owner;
        address maker;
        uint256 expiTime;
        uint256 amount;
        bool isAuction;
    }

    struct userFund {
        address maker;
        uint256 bidnumber;
    }

    enum StateOfListing {
        INACTIVE,
        ACTIVE,
        EXPIRED
    }

    enum Method {
        BUY,
        AUCTION,
        OTHER
    }

    enum Type {
        POINT,
        CRYPTO
    }

    enum StateOfOffer {
        INACTIVE,
        ACTIVE,
        EXPIRED,
        DONE,
        CANCELLED
    }

    enum StateOfAution {
        ACTIVE,
        DONE,
        CANCEL,
        EXPIRED
    }

    function saveOffer(Offer storage _offerInstance, paramOffer memory _params)
        internal
    {
        _offerInstance.tokenId = _params.tokenId;
        if (_params.indexId.length != 0) {
            _offerInstance.nftID = _params.indexId;
        }
        _offerInstance.subOffers[_params.subOfferId].subOfferId = _params
            .subOfferId;
        _offerInstance.owner = _params.owner;
        _offerInstance.subOffers[_params.subOfferId].maker = _params.maker;
        _offerInstance.subOffers[_params.subOfferId].amount = _params.amount;
        _offerInstance.subOffers[_params.subOfferId].expirationTime = _params
            .expiTime;
        _offerInstance.subOffers[_params.subOfferId].state = AuctionLibrary
            .StateOfOffer
            .ACTIVE;
    }

    function processCancel(
        Offer storage _offerInstance,
        bytes calldata _subOfferId
    ) internal {
        StateOfOffer stateOfOffer = _offerInstance.subOffers[_subOfferId].state;
        if (
            stateOfOffer == AuctionLibrary.StateOfOffer.CANCELLED ||
            stateOfOffer == AuctionLibrary.StateOfOffer.INACTIVE
        ) revert AlreadyInActive();
        _offerInstance.subOffers[_subOfferId].state = AuctionLibrary
            .StateOfOffer
            .INACTIVE;
    }

    function findTheBestFitWinner(autionStruct storage _auction)
        internal
        view
        returns (uint256)
    {
        uint256 max = 0;
        uint256 winnerIndex = 0;

        for (uint256 i = 0; i < _auction.offerIds.length; ) {
            uint256 _amount = _auction
                .offers
                .subOffers[_auction.offerIds[i]]
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

    function processChangeExpired(
        Offer storage _offerInstance,
        bytes[] calldata subOffersIdParam
    ) internal {
        for (uint256 i = 0; i < subOffersIdParam.length; ) {
            _offerInstance.subOffers[subOffersIdParam[i]].state = AuctionLibrary
                .StateOfOffer
                .CANCELLED;
            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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