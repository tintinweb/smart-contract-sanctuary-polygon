// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../EscrowContract.sol";
import "../GalleryContractUpgradeable.sol";

library DeployEscrowContract {
    function deployContract(
        address nftAddress,
        address galleryAddress,
        uint256 tokenIdCounter,
        bool commercialTier
    ) public returns (address contractDeployedAddress) {
        EscrowContract contractDeployed = new EscrowContract(
            nftAddress,
            galleryAddress,
            tokenIdCounter,
            commercialTier
        );
        return (address(contractDeployed));
    }
    // PARAMETERIZE THESE THREE FUNCTION AND MAKE SURE THE VARIABLES ALIGN
    function getCounterPartyInfo(bool bid, address escrowAddress)
        public
        view
        returns (
            uint8 counterIndex,
            address counterAddress,
            uint256 counterPrice,
            uint256 counterAmount,
            bool counterFound
        )
    {
        EscrowContract escrowContract = EscrowContract(escrowAddress);

        (counterIndex, counterFound) = escrowContract.findHighestBidLowestAsk(
            bid ? false : true
        );
        if (counterFound) {
            (counterAddress, counterPrice, counterAmount, ) = escrowContract
                .getArrayInfo(counterIndex, bid ? false : true);
        }

        return (
            counterIndex,
            counterAddress,
            counterPrice,
            counterAmount,
            counterFound
        );
    }

    function getExchangeRate(
        uint256 _tokenIdSubmit,
        uint256 _tokenIdExchange,
        address galleryContractAddress
    ) public view returns (uint16 submitToExchange, uint16 exchangeToSubmit) {
        
        GalleryContractUpgradeable galleryContract = GalleryContractUpgradeable(
            galleryContractAddress
        );

        (
            uint256 submittedCollectionId,
            uint16 submittedPercent,
            ,
            ,
            ,

        ) = galleryContract.getTokenInfo(_tokenIdSubmit);
        (
            uint256 exchangedCollectionId,
            uint16 exchangedPercent,
            ,
            ,
            ,

        ) = galleryContract.getTokenInfo(_tokenIdExchange);

        require(
            submittedCollectionId == exchangedCollectionId,
            "Different Collection"
        );

        if (_tokenIdSubmit < _tokenIdExchange) {
            //Exchange up

            submitToExchange = exchangedPercent / submittedPercent;
            exchangeToSubmit = 1;
        } else if (_tokenIdSubmit > _tokenIdExchange) {
            //Exchange down

            exchangeToSubmit = submittedPercent / exchangedPercent;
            submitToExchange = 1;
        }

        return ((submitToExchange, exchangeToSubmit));
    }
    
    function getOtherTokenInCollection(
        uint256 mappedCollectionId,
        uint256 _tokenId,
        uint256 token_Id_counter,
        address galleryContractAddress
    ) public view returns (uint256[10] memory otherTokenIds) {
        GalleryContractUpgradeable galleryContract = GalleryContractUpgradeable(
            galleryContractAddress
        );
        // Both create token functions create token consecutively -> query
        uint8 indexReturn;
        uint256 guessedTokenId;
        for (int256 i = -10; i < 10; i++) {
            if ((int256(_tokenId) + i) < 0) {
                // if any calculated tokenId <0; just ignore it.
                continue;
            }
            guessedTokenId = uint256(int256(_tokenId) + i);

            if (guessedTokenId >= token_Id_counter) {
                break;
            }

            (uint256 CollectionId, , , , , ) = galleryContract.getTokenInfo(
                uint256(guessedTokenId)
            );

            // tokenId + 1 does not exist -> revert

            if (CollectionId == mappedCollectionId) {
                otherTokenIds[indexReturn] = guessedTokenId; // should be guessedTokenId 
                indexReturn += 1;
            }
        }

        return (otherTokenIds);
    }

    function claimSftHelper(uint256 tokenId, address galleryContractAddress, address sender)
        public
        returns (
            uint8 collectionState,
            uint256 collectionPrice,
            uint256 sftOwed, 
            address escrowAddress
        )
    {
        GalleryContractUpgradeable galleryContract = GalleryContractUpgradeable(
            galleryContractAddress
        );
        EscrowContract escrow_contract = galleryContract.getEscrowContract(tokenId);
        escrowAddress = address(escrow_contract);
        (collectionState, , collectionPrice, ) = escrow_contract
            .getContractStatus();

        // collection state 3 = verified : collector calling will be transferred sft
        // colelction state 2 = SUPPORT-Cancelled : collector calling will be refunded NFT that is owed
        if (collectionState == 0 || collectionState == 1) {
            revert GalleryContractV0__CollectionIdNotApproved();
        }
        
        (, sftOwed) = escrow_contract.getYourSupportInfo(sender);

        if (sftOwed == 0){
            revert GalleryContractV0__NotCollector();
        }

        escrow_contract.claimedSupport(sender);

        return (collectionState, collectionPrice, sftOwed, escrowAddress);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./AssetKidNFTUpgradeable.sol";

error EscrowContract__ArrayFull();
error EscrowContract__ContractLocked();
error EscrowContract__CannotCommercialize();
error EscrowContract__CannotSupport();
error EscrowContract__AlreadySubmit();

contract EscrowContract is ERC1155Holder, Ownable {
    // This contract will facillitate the trade of a specific tokenId token belonging to the AssetKidNft collection

    bool public COMMERCIALIZABLE; // whether this escrow is baseTier or maxQuant token or not available for support
    uint256 public SUPPORT_PRICE;
    uint256 public SUPPORT_AMOUNT;

    enum ContractState {
        UNVERIFIED, // when the contract is created
        SEEKING_SUPPORT,
        SUPPORT_CANCELLED, // when the creator cancel the support
        VERIFIED
    }

    mapping(address => uint256) public address2BiaOwed;
    mapping(address => uint256) public address2SftAmtOwed;

    struct Ask {
        address askerAddress;
        uint256 askPrice;
        uint256 askAmount; // total SFT locked
        bool active;
    }

    struct Bid {
        address bidderAddress;
        uint256 bidPrice; // amount of BIA bid
        uint256 bidAmount; // amount of SFT  // total BIA locked = bidPrice*bidAmount
        bool active;
    }

    modifier verifiedCollection() {
        if (contractState != ContractState.VERIFIED) {
            revert EscrowContract__ContractLocked();
        }
        _;
    }

    Bid[50] bid_array; //highest bid will be stored in the 49th place
    Ask[50] ask_array; //lowest ask
    uint256 immutable tokenId;
    address CREATOR_ADDRESS;

    ContractState contractState;

    constructor(
        address _nftAddress,
        address galleryAddress,
        uint256 _nativeTokenId,
        bool _commercialTier
    ) {
        address collectionAddress = _nftAddress;
        AssetKidNftUpgradeable nft_contract = AssetKidNftUpgradeable(collectionAddress);
        nft_contract.setApprovalForAll(galleryAddress, true); // when created, this contract will approve gallery to manage their tokens.
        tokenId = _nativeTokenId;
        COMMERCIALIZABLE = _commercialTier ? true : false;
        contractState = ContractState.UNVERIFIED;
    }

    function commercialize(
        address creatorAddress,
        uint256 amount,
        uint256 price,
        bool cancel
    ) public onlyOwner {
        if (
            (!COMMERCIALIZABLE && !cancel) || (amount * price < 5000 && !cancel)
        ) {
            // Make sure it is the commercial tier token of the collection and amount * price exceeds 5000 BIA.
            revert EscrowContract__CannotCommercialize();
        }

        contractState = cancel
            ? ContractState.SUPPORT_CANCELLED
            : ContractState.SEEKING_SUPPORT;
        COMMERCIALIZABLE = false;
        SUPPORT_PRICE = cancel ? SUPPORT_PRICE : price;
        // need to log creator address to support bia.
        address2BiaOwed[creatorAddress] = cancel ? 0 : amount * SUPPORT_PRICE;
        CREATOR_ADDRESS = creatorAddress;
    }

    function support(
        address supporterAddress,
        uint256 amount,
        bool cancel // sftAmount that user supports
    ) public onlyOwner {
        if (contractState != ContractState.SEEKING_SUPPORT) {
            revert EscrowContract__CannotSupport();
        }
        cancel
            ? address2SftAmtOwed[supporterAddress] = 0
            : address2SftAmtOwed[supporterAddress] = amount;
        cancel ? SUPPORT_AMOUNT -= amount : SUPPORT_AMOUNT += amount; // sft SUPPORT_AMOUNT increases by the user submitted amount
        address2BiaOwed[CREATOR_ADDRESS] = SUPPORT_AMOUNT * SUPPORT_PRICE; // amount submit by collector x price set by creator.
    }

    function recordBidAsk(
        address adr,
        uint256 price,
        uint256 amount,
        bool cancel,
        uint8 cancelIndex,
        bool bid
    )
        external
        onlyOwner
        verifiedCollection
        returns (
            bool _replacement,
            address _replacementAddress,
            uint256 _repleacementAmt
        )
    {
        if (cancel && bid) {
            bid_array[cancelIndex] = Bid(adr, price, amount, true);
            return (false, address(0), 0);
        }

        if (cancel && !bid) {
            ask_array[cancelIndex] = Ask(adr, price, amount, true);
            return (false, address(0), 0);
        }

        (
            uint8 index,
            bool foundPlace,
            bool replacement,
            address replace_address,
            uint256 replace_amt
        ) = findIndex(adr, price, bid);

        // found lowest empty place in the array.
        if (foundPlace && !replacement) {
            if (bid) {
                bid_array[index] = Bid(adr, price, amount, true);
            } else {
                ask_array[index] = Ask(adr, price, amount, true);
            }

            return (false, replace_address, replace_amt);
        }
        // found lower bid to replace.
        else if (foundPlace && replacement) {
            if (bid) {
                bid_array[index] = Bid(adr, price, amount, true);
            } else {
                ask_array[index] = Ask(adr, price, amount, true);
            }
            return (true, replace_address, replace_amt);
        }
        // did not find lower bid or empty place.
        else {
            revert EscrowContract__ArrayFull();
        }
    }

    function check4Submission(address adr, bool bid)
        public
        view
        returns (bool proceed)
    {
        // if bid or ask already exist, revert
        for (uint8 i = 0; i < 50; i++) {
            if (bid && bid_array[i].bidderAddress == adr) {
                revert EscrowContract__AlreadySubmit();
            } else if (!bid && ask_array[i].askerAddress == adr) {
                revert EscrowContract__AlreadySubmit();
            }
        }

        return true;
    }

    function getContractStatus()
        public
        view
        returns (
            uint8,
            bool,
            uint256,
            uint256
        )
    {
        return (
            uint8(contractState),
            COMMERCIALIZABLE,
            SUPPORT_PRICE,
            SUPPORT_AMOUNT
        );
    }

    function getYourSupportInfo(address claimer)
        public
        view
        returns (uint256 biaSupported, uint256 sftOwed)
    {
        return (address2BiaOwed[claimer], address2SftAmtOwed[claimer]);
    }

    function claimedSupport(address claimer) external onlyOwner {
        address2BiaOwed[claimer] = 0;
        address2SftAmtOwed[claimer] = 0;
    }

    // CALL THIS FUNCTION BEFORE RECORD BID/ RECORD ASk

    function findIndex(
        address adr,
        uint256 submitPrice,
        bool bid
    )
        internal
        view
        verifiedCollection
        returns (
            uint8 index,
            bool found,
            bool replacement,
            address replacement_address,
            uint256 refund_amt
        )
    {
        uint256 ref_price = bid ? (2**256 - 1) : 0;
        for (uint8 i; i < 50; i++) {
            require(
                adr !=
                    (
                        bid
                            ? bid_array[i].bidderAddress
                            : ask_array[i].askerAddress
                    ),
                "You have already submitted a offer for this token."
            );
            if (bid ? !bid_array[i].active : !ask_array[i].active) {
                index = i;
                found = true;
                replacement = false;
                replacement_address = address(0);

                return (
                    index,
                    found,
                    replacement,
                    replacement_address,
                    refund_amt
                );
            } else if (
                bid
                    ? (bid_array[i].active &&
                        bid_array[i].bidPrice <= ref_price)
                    : (ask_array[i].active &&
                        ask_array[i].askPrice >= ref_price)
            ) {
                ref_price = bid ? bid_array[i].bidPrice : ask_array[i].askPrice;
                index = i;
            }
        }
        if (
            (
                bid
                    ? (submitPrice > bid_array[index].bidPrice)
                    : (submitPrice < ask_array[index].askPrice)
            )
        ) {
            found = true;
            replacement = true;
            refund_amt = bid
                ? (bid_array[index].bidPrice * bid_array[index].bidAmount)
                : ask_array[index].askAmount;
            replacement_address = bid
                ? bid_array[index].bidderAddress
                : ask_array[index].askerAddress;
        } else {
            found = false;
            replacement = false;
        }

        return (index, found, replacement, replacement_address, refund_amt);
    }

    function findHighestBidLowestAsk(bool bid)
        public
        view
        verifiedCollection
        returns (uint8 _index, bool _submissionExists)
    {
        uint256 ref_price = bid ? 0 : (2**256 - 1);

        for (uint8 i; i < 50; i++) {
            if (
                bid
                    ? (bid_array[i].active && bid_array[i].bidPrice > ref_price)
                    : (ask_array[i].active && ask_array[i].askPrice < ref_price)
            ) {
                ref_price = bid ? bid_array[i].bidPrice : ask_array[i].askPrice;
                _index = i;
                _submissionExists = true;
            }
        }

        return (_index, _submissionExists);
    }

    function reconcileAmount(
        uint256 _newAmt,
        uint8 _index,
        bool bid
    ) external onlyOwner verifiedCollection {
        if (_newAmt == 0) {
            bid
                ? ask_array[_index].active = false
                : bid_array[_index].active = false;
        } else {
            bid
                ? ask_array[_index].askAmount = _newAmt
                : bid_array[_index].bidAmount = _newAmt;
        }
    }

    function getArrayInfo(uint8 _index, bool bid)
        public
        view
        verifiedCollection
        returns (
            address adr,
            uint256 price,
            uint256 amount,
            bool active
        )
    {
        adr = bid
            ? bid_array[_index].bidderAddress
            : ask_array[_index].askerAddress;
        price = bid ? bid_array[_index].bidPrice : ask_array[_index].askPrice;
        amount = bid
            ? bid_array[_index].bidAmount
            : ask_array[_index].askAmount;
        active = bid ? bid_array[_index].active : ask_array[_index].active;
        return (adr, price, amount, active);
    }

    function verifyCollection() external onlyOwner {
        contractState = ContractState.VERIFIED;
        COMMERCIALIZABLE = false;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// IMPORTS

import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "./EscrowContract.sol";
import "./AssemblerContract.sol";

// Error Codes
error GalleryContractV0__CollectionIdAlreadyApproved();
error GalleryContractV0__MismatchContractAddress();
error GalleryContractV0__AddressAlreadyApproved();
error GalleryContractV0__CollectionIdAlreadyExists();
error GalleryContractV0__CollectionIdDoesNotExists();
error GalleryContractV0__TokenIdDoesNotExist();
error GalleryContractV0__TooManyUnapprovedCollection();
error GalleryContractV0__MintingError();
error GalleryContractV0__AddressNotApproved();
error GalleryContractV0__SubmissionError();
error GalleryContractV0__CollectionIdNotApproved();
error GalleryContractV0__BidDoesNotExist();
error GalleryContractV0__AskDoesNotExist();
error GalleryContractV0__NotCreator();
error GalleryContractV0__NotCollector();
error GalleryContractV0__NotAdmin();
error GalleryContractV0__CannotLowLevelCallNftContract();

//Libraries
import "./library/deployEscrowContract.sol";
import "./library/deployAssemblerContract.sol";

contract GalleryContractUpgradeable is ERC1155HolderUpgradeable {
    // Type Declaration

    enum COLLECTIONTYPE {
        UNASSIGNED,
        SIMPLE,
        TIER,
        PUZZLE,
        BIA,
        FFT
    }

    // Map collectionId existance
    mapping(uint256 => bool) internal collectionIdExist;

    //Map address to unapprovedCollection
    mapping(address => uint8) internal address2UnapprovedCollection;

    // Map collectionId to creator address
    mapping(uint256 => address) internal collectionId2CreatorAddress;

    // Map tokenId existance
    mapping(uint256 => bool) internal tokenIdExist;

    // Map collectionId to gallery approval
    mapping(uint256 => bool) internal collectionId2galleryApproval;

    // Map tokenIds to its collection Id.
    mapping(uint256 => uint256) internal tokenId2CollectionId;

    // Map tokenIds to its % representation of the collection.
    mapping(uint256 => uint16) internal tokenId2PercentRep;

    // Token Id to its associated escrow contract.
    mapping(uint256 => address) internal tokenId2EscrowContract;

    // Map collectionId to its collectable types
    mapping(uint256 => COLLECTIONTYPE) internal collectionId2CollectType;

    //Map collectionId to its assembler contract
    //If collect type is not tier, 0x000
    mapping(uint256 => address) internal collectionId2AssemblerContract;

    //Map address => operatorApproval
    mapping(address => bool) internal address2OperatorApproval;

    // Mapping tokenId to tokenHex
    mapping(uint256 => uint256) internal tokenId2Hex;

    // State Variables

    uint256 public collectionIdCounter;
    uint256 public TOKEN_ID_COUNTER;
    address public ASSET_KID_NFT_ADDRESS;
    address GALLERY_2_ADDRESS;
    address GALLERY_ADMIN_ADDRESS;

    // Events

    event simpleCollectableCreated(
        uint256 collectionId,
        uint256[] tokenIds,
        address creator
    );
    event tierCollectableCreated(
        uint256 collectionId,
        uint256[] tokenIds,
        address creator
    );
    event tierExchange(
        uint256 collectionId,
        uint256 exchangeFrom,
        uint256 exchangeTo,
        address exchanger
    );

    // Modifiers

    modifier onlyVerified(uint256 collectionId) {
        // Only allowing approved collectionId
        if (!collectionId2galleryApproval[collectionId]) {
            revert GalleryContractV0__CollectionIdNotApproved();
        }

        // // Only allowing Operator Approved Addresses.
        // if (!address2OperatorApproval[msg.sender])
        //     revert GalleryContractV0__AddressNotApproved();
        _;
    }

    modifier onlyGalleryAdmin() {
        if (msg.sender != GALLERY_ADMIN_ADDRESS) {
            revert GalleryContractV0__NotAdmin();
        }
        _;
    }

    // Function

    //// Initializer

    function initialize(
        address _galleryAdminAddress,
        uint256 _bia,
        uint256 _friendsAndFam
    ) public initializer {
        collectionIdCounter = 0;
        TOKEN_ID_COUNTER = 0;
        GALLERY_ADMIN_ADDRESS = _galleryAdminAddress;
        mapTokenIdsAndEscrow(
            collectionIdCounter,
            _bia,
            address(0),
            uint16(1000)
        );

        mapCollectionId(
            collectionIdCounter,
            address(0),
            COLLECTIONTYPE.BIA,
            address(this)
        );
        address2UnapprovedCollection[address(this)] -= 1;
        collectionId2galleryApproval[0] = true;

        mapTokenIdsAndEscrow(
            collectionIdCounter,
            _friendsAndFam,
            address(0),
            uint16(1000)
        );

        mapCollectionId(
            collectionIdCounter,
            address(0),
            COLLECTIONTYPE.FFT,
            address(this)
        );

        address2UnapprovedCollection[address(this)] -= 1;
        collectionId2galleryApproval[1] = true;
    }

    //// Receive
    //// Fallback

    //// External

    // function setApprovalForTrading(address _address) external {
    //     // This function will be called by the NFT contract and will allow address to access the trading functions of the escrow contract
    //     // Allow only the ERC1155 NFT contract to call

    //     if (msg.sender != ASSET_KID_NFT_ADDRESS)
    //         revert GalleryContractV0__MismatchContractAddress();
    //     else if (address2OperatorApproval[_address])
    //         revert GalleryContractV0__AddressAlreadyApproved();

    //     address2OperatorApproval[_address] = true;
    // }

    // FUND ADDRESS IS NOW IN THE NFT CONTRACT

    //// Public

    function approveCollectionId(uint256 _tokenId) public onlyGalleryAdmin {
        // This function will approve the collection Id after item is verified by the gallery.

        EscrowContract commercialEscrow;
        uint256 biaSupported;

        address creatorAddress = collectionId2CreatorAddress[
            tokenId2CollectionId[_tokenId]
        ];

        uint256[10] memory otherTokenIds = DeployEscrowContract
            .getOtherTokenInCollection(
                tokenId2CollectionId[_tokenId],
                _tokenId,
                TOKEN_ID_COUNTER,
                address(this)
            );

        for (uint256 i; i < 10; i++) {
            EscrowContract _escrowContract = EscrowContract(
                tokenId2EscrowContract[otherTokenIds[i]]
            );
            // Verfifying each contract
            _escrowContract.verifyCollection();
            // finding which contract is the commercial contract

            (, bool commercializable, , ) = _escrowContract.getContractStatus();
            // get biaSupported and commercial Escrow contract
            if (commercializable) {
                commercialEscrow = _escrowContract;
                (biaSupported, ) = _escrowContract.getYourSupportInfo(
                    creatorAddress
                );
                break;
            }

            if (otherTokenIds[i + 1] == 0) {
                break;
            }
        }
        collectionId2galleryApproval[tokenId2CollectionId[_tokenId]] = true;
    }

    function claimBIA(uint256 tokenId) public {
        address creatorAddress = collectionId2CreatorAddress[
            tokenId2CollectionId[tokenId]
        ];
        if (creatorAddress != msg.sender) {
            revert GalleryContractV0__NotCreator();
        }
        EscrowContract commercialEscrow = EscrowContract(
            tokenId2EscrowContract[tokenId]
        );
        (uint256 biaSupported, ) = commercialEscrow.getYourSupportInfo(
            creatorAddress
        );

        nftSafeTransfer(
            address(commercialEscrow),
            creatorAddress,
            tokenId2Hex[0],
            biaSupported
        );
    }

    function claimSFT(uint256 tokenId) public {
        (
            uint8 collectionState,
            uint256 collectionPrice,
            uint256 sftOwed,
            address escrowAddress
        ) = DeployEscrowContract.claimSftHelper(
                tokenId,
                address(this),
                msg.sender
            );

        nftSafeTransfer(
            escrowAddress,
            msg.sender,
            (collectionState == uint8(3))
                ? tokenId2Hex[tokenId]
                : tokenId2Hex[0],
            (collectionState == uint8(3)) ? sftOwed : sftOwed * collectionPrice
        );
    }

    function supportCollectionId(uint256 tokenId, uint256 sftAmount) public {
        if (
            msg.sender ==
            collectionId2CreatorAddress[tokenId2CollectionId[tokenId]]
        ) {
            revert GalleryContractV0__NotCollector();
        }
        EscrowContract escrow_contract = getEscrowContract(tokenId);
        (, , uint256 price, ) = escrow_contract.getContractStatus(); // price set by the creator
        uint256 biaAmount = price * sftAmount; // amount BIA to transfer = price set by creator * sftAmount support

        nftSafeTransfer(
            msg.sender,
            address(escrow_contract),
            tokenId2Hex[0],
            biaAmount
        );
        escrow_contract.support(msg.sender, sftAmount, false);
    }

    function withdrawSupport(uint256 tokenId) public {
        EscrowContract escrow_contract = getEscrowContract(tokenId);
        (, uint256 sftOwed) = escrow_contract.getYourSupportInfo(msg.sender);
        if (sftOwed == 0) {
            revert GalleryContractV0__NotCollector();
        }
        // transfer nft back
        (, , uint256 price, ) = escrow_contract.getContractStatus();
        uint256 biaOwed = sftOwed * price;

        nftSafeTransfer(
            address(escrow_contract),
            msg.sender,
            tokenId2Hex[0],
            biaOwed
        );
        // cancel record
        escrow_contract.support(msg.sender, sftOwed, true);
    }

    function commercializeCollectionId(
        uint256 tokenId,
        uint256 amount,
        uint256 price,
        bool cancel
    ) public {
        if (
            msg.sender !=
            collectionId2CreatorAddress[tokenId2CollectionId[tokenId]]
        ) {
            revert GalleryContractV0__NotCreator();
        }

        EscrowContract escrow_contract = getEscrowContract(tokenId);

        if (cancel) {
            nftTransferAll(
                address(escrow_contract),
                msg.sender,
                tokenId2Hex[tokenId]
            );
        } else {
            nftSafeTransfer(
                msg.sender,
                address(escrow_contract),
                tokenId2Hex[tokenId],
                amount
            );
        }

        //record in escrow
        escrow_contract.commercialize(msg.sender, amount, price, cancel);
    }

    function createSimpleCollectable(
        uint16[10] memory _quantity,
        uint16[10] memory _percentage,
        uint256[10] memory hexArray
    ) public {
        if (address2UnapprovedCollection[msg.sender] >= 5)
            revert GalleryContractV0__TooManyUnapprovedCollection();

        // The minimum percentage equals 0.1%.
        // The maximum amount of token per collection equals 1000;
        // Percentage variable -> 1 = 0.1%, 10 = 1%, 100 = 10%, 1000 = 100%.

        address creator = msg.sender;
        uint16 running_tally = 0;
        uint256[] memory tokenIdArray = new uint256[](10);
        uint256 collectionId = collectionIdCounter;
        uint256 maxQuantity = 0;
        uint8 maxQuantIndex;

        for (uint8 i; i < 10; i++) {
            if (_quantity[i] >= 1000) revert GalleryContractV0__MintingError();
            running_tally += (_quantity[i] * _percentage[i]);
            (maxQuantity < _quantity[i])
                ? maxQuantity = _quantity[i]
                : maxQuantity = maxQuantity;
            (maxQuantity < _quantity[i])
                ? maxQuantIndex = i
                : maxQuantIndex = maxQuantIndex;
        }
        if (running_tally != 1000) revert GalleryContractV0__MintingError();

        for (uint8 i; i < 10; i++) {
            if (_quantity[i] > 0) {
                address escrowContractAddress = DeployEscrowContract
                    .deployContract(
                        ASSET_KID_NFT_ADDRESS,
                        address(this),
                        TOKEN_ID_COUNTER,
                        (i == maxQuantIndex) ? true : false
                    );
                nftMintToken(msg.sender, hexArray[i], _quantity[i]);
                tokenIdArray[i] = TOKEN_ID_COUNTER;
                mapTokenIdsAndEscrow(
                    collectionIdCounter,
                    hexArray[i],
                    escrowContractAddress,
                    uint16(_percentage[i])
                );
            }
        }

        mapCollectionId(
            collectionIdCounter,
            address(0),
            COLLECTIONTYPE.SIMPLE,
            creator
        );

        emit simpleCollectableCreated(collectionId, tokenIdArray, creator);
    }

    function createTierCollectable(
        uint16 _baseTier,
        uint16[10] memory _subsequentTier,
        uint256[10] memory hexIdArray
    ) public {
        // the miniumum percentage is 0.1%
        // Variable -> 1 = 0.1%, 10 = 1%, 100 = 10%, 1000 = 100%.
        // base tier must be divide 1000(100%) with no remainder
        // Each subsequent tier must divide the previous with no remainder.

        if (address2UnapprovedCollection[msg.sender] >= 5)
            revert GalleryContractV0__TooManyUnapprovedCollection();
        else if (1000 % _baseTier != 0 || _baseTier >= 1000)
            revert GalleryContractV0__MintingError();

        for (uint8 i; i < 10; i++) {
            // Compare the first element of _subsequentTier to the _baseTier and make divisibility sure
            // Continue to the next iteration
            if (i == 0) {
                if (
                    _subsequentTier[0] % _baseTier != 0 ||
                    _subsequentTier[0] <= _baseTier ||
                    _subsequentTier[i + 1] % _subsequentTier[i] != 0
                ) revert GalleryContractV0__MintingError();
                continue;
            }

            if (1000 % _subsequentTier[i] != 0)
                revert GalleryContractV0__MintingError();

            //Break if the next tier doesnt exist
            if (_subsequentTier[i + 1] == 0) {
                break;
            }

            // Compare the next tier to this tier and make divisibility sure
            if (
                _subsequentTier[i + 1] <= _subsequentTier[i] ||
                _subsequentTier[i + 1] % _subsequentTier[i] != 0
            ) revert GalleryContractV0__MintingError();
        }

        uint256 collectionId = collectionIdCounter;
        address creator = msg.sender;

        uint256[] memory tokenIdArray = new uint256[](10);

        uint16 baseQuantity = 1000 / _baseTier; // Should be fine because line 172

        // create an escrow contract for the base tier
        address escrowContractAddress = DeployEscrowContract.deployContract(
            ASSET_KID_NFT_ADDRESS,
            address(this),
            TOKEN_ID_COUNTER,
            true
        );

        // minting base tier token
        nftMintToken(creator, hexIdArray[0], baseQuantity);
        address assemblerContractAddress = DeployAssemblerContract
            .deployContract(ASSET_KID_NFT_ADDRESS, address(this));

        tokenIdArray[0] = TOKEN_ID_COUNTER;
        mapTokenIdsAndEscrow(
            collectionIdCounter,
            hexIdArray[0],
            address(escrowContractAddress),
            uint16(_baseTier)
        );

        for (uint8 i; i < 10; i++) {
            uint16 quantity = 1000 / _subsequentTier[i];

            nftMintToken(assemblerContractAddress, hexIdArray[i + 1], quantity); // subsequent tier tokens are minted to the assembler contract.

            address subsequentEscrowContract = DeployEscrowContract
                .deployContract(
                    ASSET_KID_NFT_ADDRESS,
                    address(this),
                    TOKEN_ID_COUNTER,
                    false
                ); //creating new escrow for subsequent tokens
            tokenIdArray[i + 1] = TOKEN_ID_COUNTER;
            mapTokenIdsAndEscrow(
                collectionIdCounter,
                hexIdArray[i + 1],
                address(subsequentEscrowContract),
                uint16(_subsequentTier[i])
            );
            if (_subsequentTier[i + 1] == 0) {
                break;
            }
        }

        mapCollectionId(
            collectionIdCounter,
            assemblerContractAddress,
            COLLECTIONTYPE.TIER,
            creator
        );
        emit tierCollectableCreated(collectionId, tokenIdArray, creator);
    }

    function exchangeTierToken(
        uint256 _collectionId,
        uint256 _tokenIdSubmit,
        uint16 _tokenIdSubmitAmt,
        uint256 _tokenIdExchange
    ) public onlyVerified(_collectionId) {
        address assembler_contract_address = collectionId2AssemblerContract[
            _collectionId
        ];

        (
            uint16 submitToExchange,
            uint16 exchangeToSubmit
        ) = DeployEscrowContract.getExchangeRate(
                _tokenIdSubmit,
                _tokenIdExchange,
                address(this)
            );

        if (_tokenIdSubmitAmt % submitToExchange != 0)
            revert GalleryContractV0__SubmissionError(); //make sure that the submission amt is a multiple of the exchange rate

        uint256 amtMultiplier = _tokenIdSubmitAmt / submitToExchange;

        nftSafeTransfer(
            msg.sender,
            assembler_contract_address,
            tokenId2Hex[_tokenIdSubmit],
            _tokenIdSubmitAmt
        );

        nftSafeTransfer(
            assembler_contract_address,
            msg.sender,
            tokenId2Hex[_tokenIdExchange],
            exchangeToSubmit * amtMultiplier
        );

        emit tierExchange(
            _collectionId,
            _tokenIdSubmit,
            _tokenIdExchange,
            msg.sender
        );
    }

    function submitOfferHelper(
        address sender,
        uint256 tokenId,
        uint256 amount,
        uint256 price,
        bool bid
    ) internal {
        (
            uint8 counterIndex,
            address counterAddress,
            uint256 counterPrice,
            uint256 counterAmount,

        ) = DeployEscrowContract.getCounterPartyInfo(
                bid,
                tokenId2EscrowContract[tokenId]
            );

        EscrowContract escrow_contract = getEscrowContract(tokenId);

        nftMutualEscrowTransfer(
            sender, // sender
            counterAddress, // counterParty
            tokenId2Hex[tokenId], // tokenId
            (counterAmount >= amount) ? amount : counterAmount, // tokenAmount
            bid ? counterPrice : price, // askingPrice
            bid ? price : counterPrice, // bidingPrice
            bid, // bid or ask input
            address(escrow_contract) // escrow contract
        );

        escrow_contract.reconcileAmount(
            (counterAmount > amount) ? counterAmount - amount : 0,
            counterIndex,
            bid
        );
    }

    function submitOffer(
        uint256 tokenId,
        uint256 amount,
        uint256 price,
        bool bid
    ) public onlyVerified(tokenId2CollectionId[tokenId]) {
        // This is required because STACK TOO DEEP error.

        // Check for previous submission ?

        while (amount > 0) {
            // get counter party if available.
            (
                ,
                ,
                uint256 counterPrice,
                uint256 counterAmount,
                bool counterFound
            ) = DeployEscrowContract.getCounterPartyInfo(
                    bid,
                    tokenId2EscrowContract[tokenId]
                );

            // if counter party not available (no highest bid or lowest ask) -> transfer asset to escrow and break
            if (
                !counterFound ||
                (bid ? counterPrice > price : price > counterPrice)
            ) {
                // transfer asset to escrow
                assetToEscrowTransfer(
                    msg.sender, //_from from bidder or from asker
                    tokenId, //_tokenId
                    amount, //_tokenAmt bidAmount / askAmount
                    price, // _tokenPrice bidPrice / askPrice
                    false, // cancel
                    0, // cancelIndex
                    bid // bid
                );

                break;
            }

            submitOfferHelper(msg.sender, tokenId, amount, price, bid);

            if (counterAmount > amount) {
                break;
            } else {
                amount -= counterAmount;
            }
        }
    }

    function cancelOffer(uint256 tokenId, bool bid)
        public
        onlyVerified(tokenId2CollectionId[tokenId])
    {
        EscrowContract escrow_contract = getEscrowContract(tokenId);
        for (uint8 i = 0; i < 50; i++) {
            (
                address refAddress,
                ,
                uint256 refundAmount,
                bool active
            ) = escrow_contract.getArrayInfo(i, bid);

            if (refAddress == msg.sender && active) {
                escrow_contract.recordBidAsk(msg.sender, 0, 0, true, i, bid);
                nftSafeTransfer(
                    address(escrow_contract),
                    msg.sender,
                    bid ? 0 : tokenId,
                    refundAmount
                );
                return;
                // refund the BIA / SFT
            }
        }

        revert GalleryContractV0__NotCollector();
    }

    //// Internal

    function mapCollectionId(
        uint256 _collectionId,
        address _assemblerContract,
        COLLECTIONTYPE _CollectionType,
        address _creatorAddress
    ) internal {
        if (collectionIdExist[_collectionId])
            revert GalleryContractV0__CollectionIdAlreadyExists();

        // Mapping
        collectionIdExist[_collectionId] = true;
        collectionId2AssemblerContract[_collectionId] = _assemblerContract;
        collectionId2CollectType[_collectionId] = _CollectionType;
        collectionId2CreatorAddress[_collectionId] = _creatorAddress;

        // Increasing tracking params.
        collectionIdCounter += 1;
        address2UnapprovedCollection[_creatorAddress] += 1;
    }

    function mapTokenIdsAndEscrow(
        uint256 _collectionId,
        uint256 hexTokenId,
        address _escrowContract,
        uint16 _percentRep
    ) internal {
        tokenId2Hex[TOKEN_ID_COUNTER] = hexTokenId;
        tokenId2CollectionId[TOKEN_ID_COUNTER] = _collectionId;
        tokenIdExist[TOKEN_ID_COUNTER] = true;
        tokenId2EscrowContract[TOKEN_ID_COUNTER] = _escrowContract;
        tokenId2PercentRep[TOKEN_ID_COUNTER] = _percentRep;
        TOKEN_ID_COUNTER += 1;
    }

    function assetToEscrowTransfer(
        address _from,
        uint256 _tokenId,
        uint256 _tokenAmt,
        uint256 _tokenPrice,
        bool cancel,
        uint8 cancelIndex,
        bool bid
    ) internal {
        // pretty sure this can be moved to NFT contract
        EscrowContract escrow_contract = getEscrowContract(_tokenId);

        (
            bool replacement,
            address replacement_address,
            uint256 replacementAmt
        ) = escrow_contract.recordBidAsk(
                _from,
                _tokenPrice,
                _tokenAmt,
                cancel,
                cancelIndex,
                bid
            );

        if (replacement) {
            nftSafeTransfer(
                address(escrow_contract),
                replacement_address,
                bid ? tokenId2Hex[0] : tokenId2Hex[_tokenId],
                replacementAmt
            );
        }

        nftSafeTransfer(
            _from,
            address(escrow_contract),
            bid ? tokenId2Hex[0] : tokenId2Hex[_tokenId],
            bid ? _tokenAmt * _tokenPrice : _tokenAmt
        );

        nftCollectGalleryFee(_from, _tokenAmt * _tokenPrice );
    }

    //// Private
    //// View/Pure

    function getAssetKidNftAddress() public view returns (address) {
        return (ASSET_KID_NFT_ADDRESS);
    }

    function getGalleryContractAddress()
        public
        view
        returns (address galleryContractAddress)
    {
        return (address(this));
    }

    function getAmountOfUnapprovedCollections()
        public
        view
        returns (uint8 numberOfCollections)
    {
        return (address2UnapprovedCollection[msg.sender]);
    }

    function getHexId(uint256 tokenId) public view returns (uint256 hexId) {
        return tokenId2Hex[tokenId];
    }

    function getTokenInfo(uint256 _tokenId)
        public
        view
        returns (
            uint256 CollectionId,
            uint16 PercentRep,
            address EscrowContractAddress,
            address AssemblerContractAddress,
            uint8 CollectionType,
            address CreatorAddress
        )
    {
        if (!tokenIdExist[_tokenId])
            revert GalleryContractV0__TokenIdDoesNotExist();

        return (
            tokenId2CollectionId[_tokenId],
            tokenId2PercentRep[_tokenId],
            tokenId2EscrowContract[_tokenId],
            collectionId2AssemblerContract[tokenId2CollectionId[_tokenId]],
            uint8(collectionId2CollectType[tokenId2CollectionId[_tokenId]]),
            collectionId2CreatorAddress[tokenId2CollectionId[_tokenId]]
        );
    }

    function getEscrowContract(uint256 _tokenId)
        public
        view
        returns (EscrowContract)
    {
        EscrowContract escrow_contract = EscrowContract(
            tokenId2EscrowContract[_tokenId]
        );

        return (escrow_contract);
    }

    function getCollectionOwner(uint256 _collectionId)
        public
        view
        returns (address)
    {
        if (!collectionIdExist[_collectionId])
            revert GalleryContractV0__CollectionIdDoesNotExists();
        return (collectionId2CreatorAddress[_collectionId]);
    }

    function burnTokenId(uint256 tokenId) external {
        if (msg.sender != GALLERY_2_ADDRESS){
            revert GalleryContractV0__MismatchContractAddress();
        }
        tokenIdExist[tokenId] = false;
    }

    function burnCollectionId(uint256 collectionId) external {
        if (msg.sender != GALLERY_2_ADDRESS){
            revert GalleryContractV0__MismatchContractAddress();
        }
        collectionIdExist[collectionId] = false;
    }

    function getTokenIdCounter() public view returns (uint256) {
        return TOKEN_ID_COUNTER;
    }

    function setGallery2Address(address gallery2Address)
        public
        onlyGalleryAdmin
    {
        GALLERY_2_ADDRESS = gallery2Address;
        (bool success, ) = ASSET_KID_NFT_ADDRESS.call(
            abi.encodeWithSignature(
                "setGallery2Address(address)",
                gallery2Address
            )
        );
        if (!success) {
            revert GalleryContractV0__CannotLowLevelCallNftContract();
        }
    }

    function setNftContractAddress(address nftContractAddress)
        public
        onlyGalleryAdmin
    {
        ASSET_KID_NFT_ADDRESS = nftContractAddress;
    }

    function nftSafeTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) internal {
        (bool success, ) = ASSET_KID_NFT_ADDRESS.call(
            abi.encodeWithSignature(
                "safeTransferFrom(address,address,uint256,uint256,bytes)",
                from,
                to,
                tokenId,
                amount,
                ""
            )
        );
        if (!success) {
            revert GalleryContractV0__CannotLowLevelCallNftContract();
        }
    }

    function nftMutualEscrowTransfer(
        address sender,
        address counterParty,
        uint256 tokenId,
        uint256 amount,
        uint256 askPrice,
        uint256 bidPrice,
        bool bid,
        address escrowAddress
    ) internal {
        (bool success, ) = ASSET_KID_NFT_ADDRESS.call(
            abi.encodeWithSignature(
                "mutualEscrowTransfer(address,address,uint256,uint256,uint256,uint256,bool,address)",
                sender,
                counterParty,
                tokenId,
                amount,
                askPrice,
                bidPrice,
                bid,
                escrowAddress
            )
        );
        if (!success) {
            revert GalleryContractV0__CannotLowLevelCallNftContract();
        }
    }

    function nftMintToken(
        address adr,
        uint256 tokenId,
        uint16 quantity
    ) internal {
        (bool success, ) = ASSET_KID_NFT_ADDRESS.call(
            abi.encodeWithSignature(
                "mintToken(address,uint256,uint16)",
                adr,
                tokenId,
                quantity
            )
        );
        if (!success) {
            revert GalleryContractV0__CannotLowLevelCallNftContract();
        }
    }

    function nftCollectGalleryFee(address adr, uint256 txnAmount) internal {
        (bool success, ) = ASSET_KID_NFT_ADDRESS.call(
            abi.encodeWithSignature(
                "collectGalleryFee(address,uint256)",
                adr,
                txnAmount
            )
        );
        if (!success) {
            revert GalleryContractV0__CannotLowLevelCallNftContract();
        }
    }

    function nftTransferAll(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        (bool success, ) = ASSET_KID_NFT_ADDRESS.call(
            abi.encodeWithSignature(
                "transferAll(address,address,uint256)",
                from,
                to,
                tokenId
            )
        );
        if (!success) {
            revert GalleryContractV0__CannotLowLevelCallNftContract();
        }
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
// import "./GalleryContract.sol";

error AssetKidNft__NotAdmin();
error AssetKidNft__NotGalleryContract();

contract AssetKidNftUpgradeable is ERC1155BurnableUpgradeable {
    address public GALLERY_ADMIN_ADDRESS;
    address public GALLERY_PROXY_ADDRESS;
    address public GALLERY2_PROXY_ADDRESS;
    address public PROJECT_WALLET_ADDRESS;
    uint256 public BIA;
    uint256 public FriendsAndFam;

    modifier onlyGalleryAdmin() {
        if (msg.sender != GALLERY_ADMIN_ADDRESS) {
            revert AssetKidNft__NotAdmin();
        }
        _;
    }

    modifier onlyGallery() {
        if (msg.sender != GALLERY_PROXY_ADDRESS) {
            revert AssetKidNft__NotGalleryContract();
        }
        _;
    }

    modifier onlyGallery2() {
        if (msg.sender != GALLERY2_PROXY_ADDRESS) {
            revert AssetKidNft__NotGalleryContract();
        }
        _;
    }

    function initialize(
        // address _proxyGalleryContractAddress,
        // address _proxyGallery2ContractAddress,
        address _galleryAdminAddress,
        address _projectWalletAddress,
        uint256 _bia,
        uint256 _friendsAndFam
    ) public initializer {
        GALLERY_ADMIN_ADDRESS = _galleryAdminAddress;
        PROJECT_WALLET_ADDRESS = _projectWalletAddress;
        BIA = _bia;
        FriendsAndFam = _friendsAndFam;
        _mint(_projectWalletAddress, BIA, 10**9, ""); //mint 10^9 BIA to the gallery address
        _mint(_projectWalletAddress, FriendsAndFam, 50, ""); //mint 50 FF tokens to the gallery address
        setApprovalForAll(GALLERY_ADMIN_ADDRESS, true); // Approving Gallery Admin to manage
    }

    function burnAll ( /// do you want to override this alltogether ? 
        address account,
        uint256 id
    ) public onlyGallery2 {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );

        uint256 value = balanceOf(account, id);

        _burn(account, id, value);
    }

    function mintToken(
        address _addressMintTo,
        uint256 _tokenId,
        uint16 _quantity
    ) external onlyGallery {
        // Called in createSimpleCollectable & createTierCollectable
        // CALLABLE ONLY BY GALLERY1 PROXY CONTRACT.
        _mint(_addressMintTo, _tokenId, _quantity, "");
    }

    function mutualEscrowTransfer(
        address sender,
        address counterParty,
        uint256 tokenId,
        uint256 amount,
        uint256 askPrice,
        uint256 bidPrice,
        bool bid,
        address escrow_address
    ) public onlyGallery {
        // This function pays the record side
        // bid ?    bidder transfer BIA to asker @ _tokenAmt * _askPrice
        //          asker trasnfer SFT to bidder @ _tokenAmt
        // Transfer from sender to counter party.
        // bid ?    sender:bidder ; counterParty:asker
        //          sender:asker ; counterParty:bidder
        safeTransferFrom(
            sender,
            counterParty,
            bid ? BIA : tokenId,
            bid ? amount * askPrice : amount,
            ""
        );

        collectGalleryFee(sender, bid ? amount * askPrice : amount); // fee collected on sender, whether bid or ask.

        // bid? transfer SFT from escrow to bidder : transfer BIA from escrow to asker
        // this functions pays the escrow side (bid or ask)
        // bid ?    escrow transfer SFT to bidder @ _tokenAmt
        //          escrow transfer BIA to asker @ _tokenAmt * _askPrice
        // Transfer from escrow to sender.
        safeTransferFrom(
            escrow_address,
            sender,
            bid ? tokenId : BIA,
            bid ? amount : amount * askPrice,
            ""
        );

        // If price is different, gallery contract does abitrage
        // bid ?    bidder transfer BIA to gallery @  _tokenAmt * (_bidPrice - _askPrice)
        //          escrow transfer BIA to gallery @ _tokenAmt * (_bidPrice - _askPrice)
        if (askPrice < bidPrice) {
            safeTransferFrom(
                bid ? sender : escrow_address,
                PROJECT_WALLET_ADDRESS,
                BIA,
                amount * (bidPrice - askPrice),
                ""
            );
        }
    }

    function collectGalleryFee(address user, uint256 txnAmt)
        public
        onlyGallery
    {
        //Check to see if 1%
        safeTransferFrom(
            user,
            PROJECT_WALLET_ADDRESS,
            BIA,
            (txnAmt > 100) ? (txnAmt / 100) : 1,
            ""
        );
    }

    function uint2hexstr(uint256 i) public pure returns (string memory) {
        if (i == 0) return "0";
        uint256 j = i;
        uint256 length;
        while (j != 0) {
            length++;
            j = j >> 4;
        }
        uint256 mask = 15;
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        while (i != 0) {
            uint256 curr = (i & mask);
            bstr[--k] = curr > 9
                ? bytes1(uint8(55 + curr))
                : bytes1(uint8(48 + curr)); // 55 = 65 - 10
            i = i >> 4;
        }
        return string(bstr);
    }

    function uri(uint256 _tokenID)
        public
        pure
        override
        returns (string memory)
    {
        string memory hexstringtokenID;
        hexstringtokenID = uint2hexstr(_tokenID);

        return string(abi.encodePacked("ipfs://f01701220", hexstringtokenID, "/metadata.json"));
    }

    function setGalleryAddress(address galleryProxyAddress)
        public
        onlyGalleryAdmin
    {
        GALLERY_PROXY_ADDRESS = galleryProxyAddress;
    }

    function setGallery2Address(address gallery2ProxyAddress)
        public
        onlyGallery
    {
        GALLERY2_PROXY_ADDRESS = gallery2ProxyAddress;
    }

    function getAdminAddress() public view returns (address) {
        return GALLERY_ADMIN_ADDRESS;
    }

    function transferAll(
        address from,
        address to,
        uint256 tokenId
    ) public onlyGallery {
        uint256 amount = balanceOf(from, tokenId);
        safeTransferFrom(from, to, tokenId, amount, "");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/extensions/ERC1155Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC1155Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {ERC1155} that allows token holders to destroy both their
 * own tokens and those that they have been approved to use.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155BurnableUpgradeable is Initializable, ERC1155Upgradeable {
    function __ERC1155Burnable_init() internal onlyInitializing {
    }

    function __ERC1155Burnable_init_unchained() internal onlyInitializing {
    }
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );

        _burnBatch(account, ids, values);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155Upgradeable.sol";
import "./IERC1155ReceiverUpgradeable.sol";
import "./extensions/IERC1155MetadataURIUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC1155Upgradeable, IERC1155MetadataURIUpgradeable {
    using AddressUpgradeable for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    function __ERC1155_init(string memory uri_) internal onlyInitializing {
        __ERC1155_init_unchained(uri_);
    }

    function __ERC1155_init_unchained(string memory uri_) internal onlyInitializing {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155Upgradeable.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
                /// @solidity memory-safe-assembly
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
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155HolderUpgradeable is Initializable, ERC1155ReceiverUpgradeable {
    function __ERC1155Holder_init() internal onlyInitializing {
    }

    function __ERC1155Holder_init_unchained() internal onlyInitializing {
    }
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./AssetKidNFTUpgradeable.sol";

contract AssemblerContract is ERC1155Holder, Ownable {
    // This contract will simply hold the ERC1155 token minted as tier collectable.

    constructor(address _nftAddress, address galleryAddress) {
        address collectionAddress = _nftAddress;
        AssetKidNftUpgradeable nft_contract = AssetKidNftUpgradeable(collectionAddress);
        nft_contract.setApprovalForAll(galleryAddress, true); 
        //when created, this contract will approve gallery to manage their tokens.
       
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../AssemblerContract.sol";

library DeployAssemblerContract {

    function deployContract(address nftAddress, address galleryAddress) public returns(address contractDeployedAddress){

        AssemblerContract contractDeployed = new AssemblerContract(nftAddress, galleryAddress);
        return ( address(contractDeployed) );
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155ReceiverUpgradeable.sol";
import "../../../utils/introspection/ERC165Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155ReceiverUpgradeable is Initializable, ERC165Upgradeable, IERC1155ReceiverUpgradeable {
    function __ERC1155Receiver_init() internal onlyInitializing {
    }

    function __ERC1155Receiver_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}