// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ReentrancyGuard} from
    "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {INFT} from "./interfaces/INFT.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {
    SafeERC20,
    IERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20Metadata} from
    "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {
    EIP712,
    ECDSA
} from "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import {IOracleRegistry} from "./interfaces/IOracleRegistry.sol";
import {NFTMetadataViews} from "./mutagens/NFTMetadataViews.sol";
import {IMutagenNFT} from "./mutagens/interfaces/IMutagenNFT.sol";
import {IMutagenise} from "./mutagens/interfaces/IMutagenise.sol";
import "./mutagens/NFTMetadataViews.sol";

// contract Facilitator is Ownable, Pausable, ReentrancyGuard, EIP712 {
contract Facilitator is Ownable, Pausable, ReentrancyGuard, EIP712 {
    using SafeERC20 for IERC20;

    //------------------- Errors ---------------------//

    error NotAFactoryOrOwner();
    error ZeroAddress();
    error NFTNotListed();
    error AlreadyListed();
    error NotOpenForPurchase();
    error NotOpenForPackPurchase();
    error InsufficientFundsSent();
    error IncorrectArrayLength();
    error MintPriceIsZero();
    error InvalidSignature();
    error ZeroAuthorisedPurchaseSigner();
    error ZeroFundCollector();
    error ExceedingAllowedMaxSupply();
    error EmptyMetadata();
    error SignatureExpired();
    error QuantityExceedingMaximumSupply();
    error ZeroOracleRegistryAddress();
    error OracleCurrencyPairNotExist();
    error AmountIsZero();
    error PackInfoAlreadyExists();
    error PackInfoNotExists();
    error PackIdDoesnotExists();
    error IncorrectPackQuantity();
    error FailedToSendEther();
    error DiscountGreaterThan100();
    error ZeroNftFactoryAddress();
    error ZeroTokenAddress();
    error NFTSeriesNotListed();
    error TargetAndAllowedStatusLengthDiffers();
    error NoTarget();
    error NotAuthorised();
    error NotValidIndex();
    error ChangeNotAllowedInLiveSeries();
    error NotAllowedToBuy();
    error AlreadyUsedNonce();
    error ZeroMutageniseAddress();
    error ExceededMaximumSupply();
    error EmptyMetadataHashes();
    error IncorrectTokenURIs();

    //------------------- Store variables ----------------//

    /// TypeHash
    bytes32 private constant _VOUCHER_TYPE_HASH = keccak256(
        "BatchPurchaseNFT(NFTMetadataViews.NFTView[] metadata,bytes32[] metadataHashes,address nft,uint256 packId,address receiver,uint256 signatureNonce,uint256 expiry,address verifyContract)"
    );

    /// Signature nonce count.
    mapping(uint256 => bool) public usedNonce;

    /// Authorised signer for the NFT Purchase transactions.
    address public authorisedPurchaseSigner;

    /// Address of the nftFactory.
    address public immutable nftFactory;

    /// Address which collects all the funds of the sale.
    address public fundCollector;

    /// Address of the contract which would give price detail of the mutagen NFTs.
    address public mutagenise;

    /// Instance of the Oracle Registry.
    IOracleRegistry public immutable oracleRegistry;

    struct ListingDetails {
        // Already sold NFT count.
        uint256 soldCount;
        // Price of last series in sale currency.
        uint256 currentSeriesPrice;
        // Index of currentSeries.
        uint256 currentSeriesIndex;
        // Switch to facilitate the purchase of the nft project.
        bool isOpenForPurchase;
        // Base price of the NFT project, In terms of ETH
        uint256[] basePrices;
        // maximum token Id supported for provided series.
        uint256[] maxTokenIds;
        // Token address
        // address(1) for Native Currency
        address tokenAddress;
        // Oracle type for currency
        string oracleCurrencyPair;
        // Switch to facilitate the pack purchase of the nft project
        bool isOpenForPackPurchase;
        // Series
        SeriesDetails[] seriesDetails;
    }

    struct SeriesDetails {
        // Series name
        string seriesName;
        // Switch to facilitate the whitelisting of a series.
        bool isWhitelistingAllowed;
    }

    // Mapping to keep track of whitelisted addresses with nft and series
    mapping(address => mapping(uint256 => mapping(address => bool))) public whiteListed;

    /// Mapping to keep track the listed nfts with the contract.
    mapping(address => bool) public listedNFTs;

    /// Mapping to keep track of the listing details corresponds to the nft.
    mapping(address => ListingDetails) public listings;

    /// Mapping to keep track of the packs discount corresponding to its Ids.
    /// Id is always equal to the no. of NFT a pack offers.
    mapping(uint256 => uint256) public packInfo;

    /// Emitted when new pack info get added.
    event PackInfoAdded(uint256 _packId, uint256 _discountOffered);

    /// Emitted when pack info get updated.
    event PackInfoUpdated(uint256 _packId, uint256 _updatedDiscount);

    /// Emitted when nft is open for purchase.
    event OpenForPurchase();

    /// Emitted when nft is close for purchase.
    event CloseForPurchase();

    /// Emitted when nft is open for pack purchase.
    event OpenForPackPurchase();

    /// Emitted when nft is close for pack purchase.
    event CloseForPackPurchase();

    /// Emitted when the nft get listed with the facilitator contract.
    event NFTListed(
        address _nft,
        uint256[] _basePrice,
        uint256[] _maxTokenIds,
        string[] _series,
        address _tokenAddress,
        string _oracleCurrencyPair
    );

    /// Emitted when the provided nft get unlisted.
    event NFTUnlisted(address _nft);

    /// Emitted when authorised signer changes.
    event AuthorisedSignerChanged(address _newSigner);

    /// Emitted when fund collector changes.
    event FundCollectorChanged(address _newFundCollector);

    /// Emitted when the NFT get purchased.
    event NFTPurchased(
        address indexed _nft,
        address indexed _receiver,
        bytes32 metadataHash,
        address _royaltyReceiver,
        uint256 _tokenId,
        uint256 _mintFeePaid,
        uint256 _royaltyFeePaid
    );

    /// Emitted when the NFT get purchased in batch.
    event BatchNFTPurchased(
        address indexed _nft,
        address indexed _receiver,
        bytes32[] metadataHashes,
        uint256 _totalPrice,
        uint256 _totalMintFee,
        uint256 _batchSize
    );

    /// Emitted when the NFT get purchased in pack.
    event PackPurchased(
        address indexed _nft,
        address indexed _receiver,
        bytes32[] metadataHashes,
        uint256 _totalPrice,
        uint256 _totalMintFee,
        uint256 _packId
    );

    /// Emitted when the allowed list for a series is set.
    event AllowedListForSeries(
        address indexed nft, 
        uint256 seriesIndex, 
        address[] target, 
        bool[] allowedStatus
    );

    /// Emitted when the whitelisting get closed for a series.
    event CloseWhitelistingForSeries(
        address indexed nft, 
        uint256 seriesIndex 
    );

    /// @notice Initializer of the contract.
    /// @param _nftFactory Address of the factory contract.
    constructor(
        address _nftFactory,
        address _authorisedPurchaseSigner,
        address _fundCollector,
        address _mutagenise,
        IOracleRegistry _oracleRegistry
    )
        EIP712("Facilitator", "1")
    {   
        if (_nftFactory == address(0)) {
            revert ZeroNftFactoryAddress();
        }
        if (_authorisedPurchaseSigner == address(0)) {
            revert ZeroAuthorisedPurchaseSigner();
        }
        if (_fundCollector == address(0)) {
            revert ZeroFundCollector();
        }
        if (address(_oracleRegistry) == address(0)) {
            revert ZeroOracleRegistryAddress();
        }
        if (_mutagenise == address(0)) {
            revert ZeroMutageniseAddress();
        }
        nftFactory = _nftFactory;
        authorisedPurchaseSigner = _authorisedPurchaseSigner;
        fundCollector = _fundCollector;
        oracleRegistry = _oracleRegistry;
        mutagenise = _mutagenise;
    }

    /// @notice only factory or owner can call this
    function onlyFactoryOrOwner() private {
        if (msg.sender != nftFactory && owner() != msg.sender) {
            revert NotAFactoryOrOwner();
        }
    }

    /// @notice only nft owner can call this
    function onlyListingOwner(address nft) private {
        if (INFT(nft).owner() != msg.sender) {
            revert NotAuthorised();
        }
    }

    /// @notice Function to provide the ownership of the minting of the given nft.
    /// @param nft Address of the nft whose purchase would be allowed.
    /// @param basePrices Base prices of the NFT during the primary sales for different series.
    /// @param series Supported series for a given nft sale.
    /// @param maxTokenIdForSeries Maximum tokenId supported for different series. (Should be sorted in order).
    /// @param tokenAddress Token address if currency is ERC20.
    /// @param oracleCurrencyPair Currency pair to get price from oracle.
    function addNFTInPrimaryMarket(
        address nft,
        uint256[] calldata basePrices,
        string[] calldata series,
        uint256[] calldata maxTokenIdForSeries,
        address tokenAddress,
        string calldata oracleCurrencyPair
    )
        external
        whenNotPaused
    {
        onlyFactoryOrOwner();
        if (basePrices.length == uint256(0)) {
            revert MintPriceIsZero();
        }
        if (
            maxTokenIdForSeries.length != basePrices.length
                || series.length != basePrices.length
        ) {
            revert IncorrectArrayLength();
        }
        // Should not be already listed.
        if (listedNFTs[nft]) {
            revert AlreadyListed();
        }

        /// Currency should exist in oracle
        if (
            keccak256(
                abi.encodePacked(oracleRegistry.description(oracleCurrencyPair))
            ) == keccak256(abi.encodePacked(""))
        ) {
            revert OracleCurrencyPairNotExist();
        }
        

        listedNFTs[nft] = true;
        listings[nft].basePrices = basePrices;
        listings[nft].maxTokenIds = maxTokenIdForSeries;
        listings[nft].isOpenForPurchase = true;
        listings[nft].soldCount = uint256(0);
        listings[nft].tokenAddress = tokenAddress;
        listings[nft].oracleCurrencyPair = oracleCurrencyPair;
        listings[nft].currentSeriesPrice = uint256(0);
        listings[nft].currentSeriesIndex = uint256(0);
        listings[nft].isOpenForPackPurchase = true;

        for (uint256 i = 0; i < series.length; i++) {
            listings[nft].seriesDetails.push(SeriesDetails({
                seriesName: series[i],
                isWhitelistingAllowed: false
            }));
        }

        // Emit event
        emit NFTListed(
            nft,
            basePrices,
            maxTokenIdForSeries,
            series,
            tokenAddress,
            oracleCurrencyPair
            );
        emit OpenForPurchase();
    }

    function addMutagenNFTInPrimaryMarket(
        address mutagenNFT,
        uint256 basePrice,
        address tokenAddress,
        string calldata oracleCurrencyPair,
        uint256 maxSupply
    ) 
      external
      whenNotPaused 
    {
        onlyFactoryOrOwner();
        if (basePrice == uint256(0)) {
            revert MintPriceIsZero();
        }
        // Should not be already listed.
        if (listedNFTs[mutagenNFT]) {
            revert AlreadyListed();
        }

        if (maxSupply > IMutagenNFT(mutagenNFT).maximumSupply()) {
            revert ExceededMaximumSupply();
        }

        /// Currency should exist in oracle
        if (
            keccak256(
                abi.encodePacked(oracleRegistry.description(oracleCurrencyPair))
            ) == keccak256(abi.encodePacked(""))
        ) {
            revert OracleCurrencyPairNotExist();
        }

        uint256[] memory _basePrices = new uint256[](1);
        _basePrices[0] = basePrice;

        uint256[] memory _maxTokenIds = new uint256[](1);
        _maxTokenIds[0] = maxSupply;
        
        listedNFTs[mutagenNFT] = true;
        listings[mutagenNFT].basePrices = _basePrices;
        // Declaration of the mutagen nft.
        listings[mutagenNFT].maxTokenIds = _maxTokenIds;
        listings[mutagenNFT].isOpenForPurchase = true;
        listings[mutagenNFT].soldCount = uint256(0);
        listings[mutagenNFT].tokenAddress = tokenAddress;
        listings[mutagenNFT].oracleCurrencyPair = oracleCurrencyPair;
        listings[mutagenNFT].currentSeriesPrice = uint256(0);
        listings[mutagenNFT].currentSeriesIndex = uint256(0);
        listings[mutagenNFT].isOpenForPackPurchase = true;

        string[] memory _series = new string[](0);

        // Emit event
        emit NFTListed(
            mutagenNFT,
            _basePrices,
            _maxTokenIds,
            _series,
            tokenAddress,
            oracleCurrencyPair
            );
        emit OpenForPurchase();
    }

    /// @notice Add pack info.
    /// @param packId Id of the pack corresponding to which discount value get added.
    /// @param discountOffered Discount offered by the given pack.
    function addPackInfo(uint256 packId, uint256 discountOffered)
        external
        onlyOwner
    {
        if (packInfo[packId] != uint256(0)) {
            revert PackInfoAlreadyExists();
        }
        if (discountOffered > uint256(100)) {
            revert DiscountGreaterThan100();
        }
        packInfo[packId] = discountOffered;
        emit PackInfoAdded(packId, discountOffered);
    }

    /// @notice Update pack info.
    /// @param packId Id of the pack corresponding to which discount value get updated.
    /// @param newDiscount Updated Discount offered by the given pack.
    function updatePackInfo(uint256 packId, uint256 newDiscount)
        external
        onlyOwner
    {
        if (packInfo[packId] == uint256(0)) {
            revert PackInfoNotExists();
        }
        if (newDiscount > uint256(100)) {
            revert DiscountGreaterThan100();
        }
        packInfo[packId] = newDiscount;
        emit PackInfoUpdated(packId, newDiscount);
    }

    /// @notice Returns the listing details of an nft.
    function getListedNftDetails(address nft)
        external
        view
        returns (
            bool,
            string memory,
            uint256,
            uint256,
            uint256,
            uint256[] memory,
            uint256[] memory
        )
    {
        return (
            listings[nft].isOpenForPurchase,
            listings[nft].oracleCurrencyPair,
            listings[nft].soldCount,
            listings[nft].currentSeriesPrice,
            listings[nft].currentSeriesIndex,
            listings[nft].basePrices,
            listings[nft].maxTokenIds
        );
    }

    /// @notice Expected price of NFT purchase
    /// @dev it is not guranteed that expected price is always a true purchase price
    /// because it takes the sale currency oracle price at the time of execution of this
    /// function, It can be different during the actual purchase of the NFT.
    /// @param nft Address of the NFT whose prices are queried.
    /// @param purchaseQuantity Amount of nfts user is expecting to purchase.
    function getExpectedTotalPrice(address nft, uint256 purchaseQuantity, uint256 packId)
        external
        view
        returns (uint256 totalPrices)
    {
        (totalPrices,,,) = _derivePrices(listings[nft], purchaseQuantity);
        if (packId > 0 && packInfo[packId] != uint256(0)) {
            uint256 remainderAfterDiscount = 100 - packInfo[packId];
            totalPrices = totalPrices * remainderAfterDiscount / 100;
        }
    }

    /// @notice Expected price of Mutagen NFT purchase
    /// @dev it is not guranteed that expected price is always a true purchase price
    /// because it takes the sale currency oracle price at the time of execution of this
    /// function, It can be different during the actual purchase of the NFT.
    /// @param mutagenNft Address of the Mutagen NFT whose prices are queried.
    /// @param metadata metadata of the NFT.
    function getMutagenExpectedTotalPrice(address mutagenNft, NFTMetadataViews.NFTView[] memory metadata)
        external
        view
        returns (uint256 totalPrices)
    {
        (totalPrices,) = _mutagenDerivePrices(mutagenNft, listings[mutagenNft], metadata);
    }

    /// @notice Allow the owner to remove the given NFT from the listings.
    /// @param nft Address of the NFT that needs to be unlisted.
    function removeNFTFromPrimaryMarket(address nft)
        external
        onlyOwner
        whenNotPaused
    {
        delete listedNFTs[nft];
        delete listings[nft];

        // Emit logs
        emit NFTUnlisted(nft);
    }

    /// @notice Allow to change the aurhorised signer.
    /// @dev Not going to change the signer on the fly, A designated downtime would be provided during the change
    /// so least possibility of the frontrun from the owner side.
    /// @param newAuthorisedSigner New address set as the authorised signer.
    function changeAuthorisedSigner(address newAuthorisedSigner)
        external
        onlyOwner
        whenNotPaused
    {
        authorisedPurchaseSigner = newAuthorisedSigner;
        emit AuthorisedSignerChanged(newAuthorisedSigner);
    }

    /// @notice Allow a user to purchase the NFTs in a pack.
    /// @param nft Address of the NFT which need to get purcahse.
    /// @param receiver Address of the receiver.
    /// @param metadataHashes Hash of the metadata of a NFT..
    /// @param expiry Expiry of the signature.
    /// @param signatureNonce Nonce that is used to create the signature.
    /// @param packId Id of the pack that get purchased.
    /// @param signature Offchain signature of the authorised address.
    function purchasePack(
        address nft,
        address receiver,
        bytes32[] memory metadataHashes,
        uint256 expiry,
        uint256 signatureNonce,
        uint256 packId,
        bytes memory signature,
        uint256 erc20TokenAmt,
        string[] calldata tokenURIs
    )
        external
        payable
        nonReentrant
        whenNotPaused
    {
        if (packInfo[packId] == uint256(0)) {
            revert PackIdDoesnotExists();
        }
        if (metadataHashes.length != packId) {
            revert IncorrectPackQuantity();
        }
        if (metadataHashes.length != tokenURIs.length) {
            revert IncorrectTokenURIs();
        }

        NFTMetadataViews.NFTView[] memory metadata = _setMetadataUri(metadataHashes.length, tokenURIs);
        _batchPurchaseNFT(
            metadata, metadataHashes, nft, receiver, expiry, signatureNonce, signature, packId, erc20TokenAmt
        );
    }

    /// @notice Allow a user to purchase the NFTs in batch.
    /// @param nft Address of the NFT which need to get purcahse.
    /// @param receiver Address of the receiver.
    /// @param expiry Expiry of the signature.
    /// @param signatureNonce Nonce that is used to create the signature.
    /// @param signature Offchain signature of the authorised address.
    /// @param erc20TokenAmt Amount of tokens if currency is ERC20.
    /// @param metadataHashes Hash of the metadata of a NFT.
    function batchPurchaseNFT(
        address nft,
        address receiver,
        uint256 expiry,
        uint256 signatureNonce,
        bytes memory signature,
        uint256 erc20TokenAmt,
        bytes32[] memory metadataHashes,
        string[] calldata tokenURIs
    )
        external
        payable
        nonReentrant
        whenNotPaused
    {
        if (metadataHashes.length != tokenURIs.length) {
            revert IncorrectTokenURIs();
        }
        NFTMetadataViews.NFTView[] memory metadata = _setMetadataUri(metadataHashes.length, tokenURIs);
        _batchPurchaseNFT(
            metadata, metadataHashes, nft, receiver, expiry, signatureNonce, signature, uint256(0), erc20TokenAmt
        );
    }

    function _setMetadataUri(uint256 metadataHashesLength, string[] calldata tokenURIs) internal pure returns(NFTMetadataViews.NFTView[] memory) {
        NFTMetadataViews.NFTView[] memory metadata = new NFTMetadataViews.NFTView[](metadataHashesLength);
        for(uint256 i; i < tokenURIs.length;){
            metadata[i].uri = tokenURIs[i]; 
            unchecked{
                ++i;
            }
        }
        return metadata;
    }

    /// @notice Allow a user to purchase the NFTs in batch.
    /// @param nft Address of the NFT which need to get purcahse.
    /// @param receiver Address of the receiver.
    /// @param expiry Expiry of the signature.
    /// @param signatureNonce Nonce that is used to create the signature.
    /// @param signature Offchain signature of the authorised address.
    /// @param erc20TokenAmt Amount of tokens if currency is ERC20.
    /// @param metadata metadata of the NFT.
    function batchPurchaseMutagenNFT(
        address nft,
        address receiver,
        uint256 expiry,
        uint256 signatureNonce,
        bytes memory signature,
        uint256 erc20TokenAmt,
        NFTMetadataViews.NFTView[] calldata metadata
    )
        external
        payable
        nonReentrant
        whenNotPaused
    {   
        bytes32[] memory emptyMetadataHashes = new bytes32[](0);
        
        _batchPurchaseNFT(
            metadata, emptyMetadataHashes, nft, receiver, expiry, signatureNonce, signature, uint256(0), erc20TokenAmt
        );
    }

    function _batchPurchaseNFT(
        NFTMetadataViews.NFTView[] memory metadata,
        bytes32[] memory metadataHashes,
        address nft,
        address receiver,
        uint256 expiry,
        uint256 signatureNonce,
        bytes memory signature,
        uint256 packId,
        uint256 erc20TokenAmt
    )
        internal
    {
        // Check whether metadata exist for all NFTs
        if (metadataHashes.length == 0? metadata.length == 0: false) {
            revert EmptyMetadata();
        }
        // Check whether metadata hash is not zero.
        if (metadata.length == 0? metadataHashes.length == 0: false) {
            revert EmptyMetadataHashes();
        }
        // Check whether signature get expired or not.
        if (expiry < block.timestamp) {
            revert SignatureExpired();
        }
        // Check whether SignatureNonce has been already used
        if (usedNonce[signatureNonce]) {
            revert AlreadyUsedNonce();
        }
        // Chech whether nft listed in market.
        if (!listedNFTs[nft]) {
            revert NFTNotListed();
        }
        {
            if (listings[nft].seriesDetails.length != uint256(0)) { 
                uint256 currentSeriesIndex = listings[nft].currentSeriesIndex;
                if (listings[nft].seriesDetails[currentSeriesIndex].isWhitelistingAllowed) {
                    if (!whiteListed[nft][currentSeriesIndex][receiver]) {
                        revert NotAllowedToBuy();
                    }
                }
            }
        }
        address tokenAddress = listings[nft].tokenAddress;
        // If currency is not native then amount should be non-zero.
        if (tokenAddress != address(1) && erc20TokenAmt == 0) {
            revert AmountIsZero();
        } else if (tokenAddress == address(1)) {
            erc20TokenAmt = msg.value;
        }
        receiver = receiver != address(0) ? receiver : msg.sender;
        uint256 totalPrices;
        uint256[] memory cachedNFTPrices;
        {
            NFTMetadataViews.NFTView[] memory emptyMetadata;
            // Verify signature and price
            (totalPrices, cachedNFTPrices) =
            _verifySignatureAndPrice(
                metadataHashes, metadataHashes.length == 0 ? metadata : emptyMetadata, nft, receiver, expiry, signatureNonce, packId, signature
            );
        }
        totalPrices = totalPrices * (100 - packInfo[packId]) / 100;
        // Validate whether the sufficient funds are sent by the purchaser.
        if (erc20TokenAmt < totalPrices) {
            revert InsufficientFundsSent();
        }
        
        signatureNonce = _mintNFTs(
            metadata, metadataHashes, nft, receiver, cachedNFTPrices,  INFT(nft).nextTokenId(), tokenAddress, packInfo[packId]
        );
        
        uint256 batchSize = metadataHashes.length == 0 ? metadata.length : metadataHashes.length;
        // Update to `soldCount`
        listings[nft].soldCount += batchSize;
        // If native currency
        if (tokenAddress == address(1)) {
            // Transfer minting funds to the veiovia
            payable(fundCollector).call{value: signatureNonce}("");
            // Check whether there is any funds remain in the contract for the msg.sender.
            if (erc20TokenAmt - totalPrices > 0) {
                payable(msg.sender).call{value: erc20TokenAmt - totalPrices}("");
            }
        } else {
            // Transfer minting funds to the veiovia
            IERC20(tokenAddress).safeTransferFrom(
                msg.sender, fundCollector, signatureNonce
            );
        }
       
        if (packId == 0) {
            emit BatchNFTPurchased(nft, receiver, metadataHashes, totalPrices, signatureNonce, batchSize);
        } else {
            emit PackPurchased(nft, receiver, metadataHashes, totalPrices, signatureNonce, packId);
        }
    }

    function _mintNFTs(
        NFTMetadataViews.NFTView[] memory metadata,
        bytes32[] memory metadataHashes,
        address nft,
        address receiver,
        uint256[] memory cachedNFTPrices,
        uint256 tokenId,
        address tokenAddress,
        uint256 pack
    ) internal returns(uint256 totalFee) {
        NFTMetadataViews.NFTView memory emptyMetadata;
        bytes32 emptyMetadataHash;
        // Iterate to mint each NFT and send royality.
        for (uint256 i = 0; i < cachedNFTPrices.length;) {
            // TODO: Transfer metadata of the mutagen NFTs
            totalFee = totalFee
                + _transferRoyaltyAndMintNFT(
                    metadata.length == 0 ? emptyMetadata : metadata[i],
                    metadataHashes.length == 0 ? emptyMetadataHash : metadataHashes[i] ,
                    nft,
                    receiver,
                    cachedNFTPrices[i] * (100 - pack) / 100,
                    tokenId,
                    tokenAddress
                );
            tokenId = tokenId + 1;
            unchecked {
                ++i;
            }
        }
    }

    function _verifySignatureAndPrice(
        bytes32[] memory metadataHashes,
        NFTMetadataViews.NFTView[] memory metadata,
        address nft,
        address receiver,
        uint256 expiry,
        uint256 signatureNonce,
        uint256 packId,
        bytes memory signature
    )
        internal
        returns (uint256 totalPrices, uint256[] memory cachedNFTPrices)
    {
        // register the signature nonce usage within the contract
        usedNonce[signatureNonce] = true;

        //--------------------- Verify the Offchain signature -----------------//
        {
            bytes32 messageHash = keccak256(
                abi.encode(
                    _VOUCHER_TYPE_HASH,
                    abi.encode(metadata),
                    metadataHashes,
                    nft,
                    packId,
                    receiver,
                    signatureNonce,
                    expiry,
                    address(this)
                )
            );
            address recoveredAddress = ECDSA.recover(_hashTypedDataV4(messageHash), signature);
            if (
                recoveredAddress == address(0)
                    || recoveredAddress != authorisedPurchaseSigner
            ) {
                revert InvalidSignature();
            }
        }
        //--------------------------------------------------------------------//

        // Access the details of the listing .
        ListingDetails storage _details = listings[nft];

        // Check whether purchase of nft is allowed or not.
        if (!_details.isOpenForPurchase) {
            revert NotOpenForPurchase();
        }

        // Check whether pack purchase of nft is allowed or not.
        if (packId != uint256(0) && !_details.isOpenForPackPurchase) {
            revert NotOpenForPackPurchase();
        }

        // Derive prices.
        if (_details.maxTokenIds.length == uint256(1) && listings[nft].seriesDetails.length == uint256(0)) {
            // TODO: Convert the totapPrices USD value to token.
            (totalPrices, cachedNFTPrices) = _mutagenDerivePrices(nft, _details, metadata);
        } else {
            (
                totalPrices,
                _details.currentSeriesPrice,
                _details.currentSeriesIndex,
                cachedNFTPrices
            ) = _derivePrices(_details, metadataHashes.length);
        }
        
    }

    function _transferRoyaltyAndMintNFT(
        NFTMetadataViews.NFTView memory metadata,
        bytes32 metadataHash,
        address nft,
        address receiver,
        uint256 price,
        uint256 tokenId,
        address tokenAddress
    )
        internal
        returns (uint256 mintFee)
    {
        // Getting royalty information
        (address rRecv, uint256 rAmt) =
            IERC2981(nft).royaltyInfo(tokenId, price);
        if (rRecv != address(0) && rAmt != uint256(0) && rAmt < price) {
            if (tokenAddress == address(1)) {
                (bool sent,) = payable(rRecv).call{value:rAmt}("");
                if(!sent) {
                    revert FailedToSendEther();
                }
            } else {
                IERC20(tokenAddress).safeTransferFrom(msg.sender, rRecv, rAmt);
            }
            mintFee = price - rAmt;
        } else {
            mintFee = price; 
        }

        // Transfer of nft to the purchaser.
        if (listings[nft].maxTokenIds.length == uint256(1) && listings[nft].seriesDetails.length == uint256(0)) { 
            IMutagenNFT(nft).mint(receiver, metadata);
        } else {
            INFT(nft).commitMint(receiver, metadataHash, metadata.uri);
        }
        
        emit NFTPurchased(nft, receiver, metadataHash, rRecv, tokenId, mintFee, rAmt);
    }

    function _mutagenDerivePrices(address _nft, ListingDetails memory _details, NFTMetadataViews.NFTView[] memory metadata) 
        internal 
        view
        returns(
            uint256 totalPrice,
            uint256[] memory cachedIndividualNFTPrices
        )
    {   
        // Fetch the price of sale currency in terms of USD.
        // NOTE- Fetching the price can fail if the price data is stale.
        (,int256 oraclePrice,,,) = oracleRegistry.latestRoundData(_details.oracleCurrencyPair);
        // Fetch the supported decimal of oracle prices.
        uint8 decimal = oracleRegistry.decimals(_details.oracleCurrencyPair);
        uint8 tokenDecimal =
            _details.tokenAddress == address(1)
            ? 18
            : IERC20Metadata(_details.tokenAddress).decimals();
        uint256 basePriceInSaleCurrency = 10 ** decimal
                        * 10 ** tokenDecimal * _details.basePrices[0]
                        / (uint256(oraclePrice) * 100);
        uint256[] memory individualNFTPrices = new uint256[](metadata.length);
        for (uint256 i = 0; i <  metadata.length;) {
            uint256 mutiplier = IMutagenise(mutagenise).getBaseMultiplier(_nft, metadata[i]);
            individualNFTPrices[i] = basePriceInSaleCurrency + (basePriceInSaleCurrency * mutiplier/10000);
            totalPrice = totalPrice + individualNFTPrices[i];
            unchecked {
                ++i;
            }
        }
        return (totalPrice, individualNFTPrices);
    }

    // Algorithm the derive price to buy next NFT
    // - Cost or price of NFT in a given series would be constant
    // - Series price (i.e price of NFT in that series) would always be greater than the 10 % of previous series price.
    // Ex - A listing has 2 series A & B
    //      Whole series A costing would calculate at the time of purchase of first NFT from the series
    //      i.e op of MATIC = 1 and bp = 100 then price in terms of sale currency would be 100 MATIC throught the series.
    //      While for series B
    //      bp = 110 & op = 2 then base calculative price would be 55 MATIC, so the actual price of
    //      series B would be MAX(series A price + 10 % of series A price , base calculative price).
    function _derivePrices(ListingDetails memory _details, uint256 quantity)
        internal
        view
        returns (
            uint256 totalPrice,
            uint256 currentSeriesPrice,
            uint256 currentSeriesIndex,
            uint256[] memory cachedIndividualNFTPrices
        )
    {
        uint256 soldCount;
        (soldCount, currentSeriesPrice, currentSeriesIndex) = (
            _details.soldCount,
            _details.currentSeriesPrice,
            _details.currentSeriesIndex
        );
        // Fetch the price of sale currency in terms of USD.
        // NOTE- Fetching the price can fail if the price data is stale.
        (,int256 oraclePrice,,,) = oracleRegistry.latestRoundData(_details.oracleCurrencyPair);
        // Fetch the supported decimal of oracle prices.
        uint8 decimal = oracleRegistry.decimals(_details.oracleCurrencyPair);
        uint8 tokenDecimal =
            _details.tokenAddress == address(1)
            ? 18
            : IERC20Metadata(_details.tokenAddress).decimals();
        uint256[] memory individualPriceOfNFT = new uint256[](quantity);
        uint256 fromIndex = 0;
        while (quantity != 0) {
            uint256 maxTokenIdInCurrentSeries =
                _details.maxTokenIds[currentSeriesIndex];
            uint256 noOfNFTCoveredInSeries;
            // Enter in `if` statement if the price of next series get calculated.
            if (
                currentSeriesIndex != 0
                    && soldCount == _details.maxTokenIds[currentSeriesIndex - 1]
                    || soldCount == 0
            ) {
                // bp = base sale prices in USD
                // c  = supported buy currency ,i.e Matic
                // dc = decimal precision of supported buy currency
                // op = oracle prices from chainlink. i.e MATIC/USD
                // od = oracle prices decimal precision
                //
                //            bp * 10**dc * 10**od
                // prices =   -------------------
                //            op * 100
                //
                {
                    uint256 basePriceOfSeries =
                        _details.basePrices[currentSeriesIndex];
                    uint256 basePriceInSaleCurrency = 10 ** decimal
                        * 10 ** tokenDecimal * basePriceOfSeries
                        / (uint256(oraclePrice) * 100);
                    // Minimum change in next series price i.e 10 % of last series price.
                    uint256 minimumPrice = currentSeriesPrice * 11 / 10;
                    // MAX(minimumPrice, basePriceInSaleCurrency)
                    currentSeriesPrice =
                        basePriceInSaleCurrency > minimumPrice
                        ? basePriceInSaleCurrency
                        : minimumPrice;
                }
            }
            // Enter in `if` statement if this is true quantity + soldCount <= maxTokenIdInCurrentSeries
            if (quantity <= maxTokenIdInCurrentSeries - soldCount) {
                totalPrice += quantity * currentSeriesPrice;
                soldCount = soldCount + quantity;
                noOfNFTCoveredInSeries = quantity;
                quantity = 0;
            } else {
                noOfNFTCoveredInSeries = maxTokenIdInCurrentSeries - soldCount;
                totalPrice += currentSeriesPrice * noOfNFTCoveredInSeries;
                soldCount = soldCount + noOfNFTCoveredInSeries;
                quantity = quantity - noOfNFTCoveredInSeries;
                currentSeriesIndex = currentSeriesIndex + 1;
            }
            _cacheNFTPrices(
                individualPriceOfNFT,
                fromIndex,
                fromIndex = fromIndex + noOfNFTCoveredInSeries,
                currentSeriesPrice
            );
        }
        return (
            totalPrice, currentSeriesPrice, currentSeriesIndex, individualPriceOfNFT
        );
    }

    function _cacheNFTPrices(
        uint256[] memory nftPrices,
        uint256 fromIndex,
        uint256 toIndex,
        uint256 price
    )
        internal
        pure
    {
        for (uint256 i = fromIndex; i < toIndex; i++) {
            nftPrices[i] = price;
        }
    }

    /// @notice Allow owner of the facilitator contract to close the purchase of the given NFT.
    /// @param nft Address of the nft whose purchase need to be closed.
    function closePurchase(address nft) external onlyOwner {
        if (!listedNFTs[nft]) {
            revert NFTNotListed();
        }
        listings[nft].isOpenForPurchase = false;
        emit CloseForPurchase();
    }

    // @notice Allow owner of the facilitator contract to open the purchase of the given NFT.
    /// @param nft Address of the nft whose purchase need to be open.
    function openPurchase(address nft) external onlyOwner {
        if (!listedNFTs[nft]) {
            revert NFTNotListed();
        }
        listings[nft].isOpenForPurchase = true;
        emit OpenForPurchase();
    }

    /// @notice Allow owner of the facilitator contract to close the pack purchase of the given NFT.
    /// @param nft Address of the nft whose purchase need to be closed.
    function closePackPurchase(address nft) external onlyOwner {
        if (!listedNFTs[nft]) {
            revert NFTNotListed();
        }
        listings[nft].isOpenForPackPurchase = false;
        emit CloseForPackPurchase();
    }

    // @notice Allow owner of the facilitator contract to open the pack purchase of the given NFT.
    /// @param nft Address of the nft whose purchase need to be open.
    function openPackPurchase(address nft) external onlyOwner {
        if (!listedNFTs[nft]) {
            revert NFTNotListed();
        }
        listings[nft].isOpenForPackPurchase = true;
        emit OpenForPackPurchase();
    }

    /// @notice Allow owner of the facilitator contract to update the fundCollector address.
    /// @param _fundCollector Address of the new fund collector.
    function changeFundCollector(address _fundCollector) external onlyOwner {
        if (_fundCollector == address(0)) {
            revert ZeroAddress();
        }
        fundCollector = _fundCollector;
        emit FundCollectorChanged(_fundCollector);
    }

    /// @notice Allow owner of the nft to add/remove the users from whitelist.
    /// @param nft Address of the nft.
    /// @param seriesIndex Series index to add whitelist.
    /// @param target Address to add/remove from whitelist.
    /// @param allowedStatus Bool to update status of a whitelist address.
    function addAllowedListForListing(address nft, uint256 seriesIndex, address[] calldata target, bool[] calldata allowedStatus) external {
        onlyListingOwner(nft);
        if (!listedNFTs[nft]) {
            revert NFTNotListed();
        }
        if (target.length != allowedStatus.length) {
            revert TargetAndAllowedStatusLengthDiffers();
        }
        if (seriesIndex >= listings[nft].seriesDetails.length) {
            revert NotValidIndex();
        }
        uint256 soldCount = listings[nft].soldCount;
        if (seriesIndex == 0 && soldCount != 0) {
            revert ChangeNotAllowedInLiveSeries();
        } 
        if ((seriesIndex != 0) && (soldCount > listings[nft].maxTokenIds[seriesIndex-1])) {
           revert ChangeNotAllowedInLiveSeries();
        }

        listings[nft].seriesDetails[seriesIndex].isWhitelistingAllowed = true;
        for (uint256 i = 0; i < target.length; i++) {
            whiteListed[nft][seriesIndex][target[i]] = allowedStatus[i];
        }

        emit AllowedListForSeries(nft, seriesIndex, target, allowedStatus);
    }

    /// @notice Allow owner of the nft to close the whitelisting for Series.
    /// @param nft Address of the nft.
    /// @param seriesIndex Series index to add whitelist.
    function closeWhitelistingForSeries(address nft, uint256 seriesIndex) external {
        onlyListingOwner(nft);
        if (!listedNFTs[nft]) {
            revert NFTNotListed();
        }
        if (seriesIndex >= listings[nft].seriesDetails.length) {
            revert NotValidIndex();
        }

        listings[nft].seriesDetails[seriesIndex].isWhitelistingAllowed = false;

        emit CloseWhitelistingForSeries(nft, seriesIndex);
    }

    /// @notice Domain separator.
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    /// @notice allow the owner to pause some of the functionalities offered by the contract.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice allow the owner to unpause the contract.
    function unpause() external onlyOwner {
        _unpause();
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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
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
pragma solidity 0.8.15;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../mutagens/NFTMetadataViews.sol";

interface INFT is IERC721 {
    /// @notice Initialize the NFT collection.
    /// @param _maxSupply maximum supply of a collection.
    /// @param baseUri base Url of the nft's metadata.
    /// @param _name name of the collection.
    /// @param _symbol symbol of the collection.
    /// @param _owner owner of the collection.
    /// @param _minter Address of the minter allowed to mint tokenIds.
    /// @param _royaltyReceiver Beneficary of the royalty.
    /// @param _feeNumerator Percentage of fee charged as royalty.
    /// @param _maxRoyaltyPercentage Percentage of maximum fee charged as royalty.
    function initialize(
        uint256 _maxSupply,
        string calldata baseUri,
        string calldata _name,
        string calldata _symbol,
        address _owner,
        address _minter,
        address _royaltyReceiver,
        uint96 _feeNumerator,
        uint96 _maxRoyaltyPercentage
    )
        external;

    /// @notice Mint a token and assign it to an address.
    /// @param _to NFT transferred to the given address.
    /// @param metadata of the NFT.
    function mint(address _to, NFTMetadataViews.NFTView memory metadata) external;

    /// @notice Mint a token and assign it to an address.
    /// @param _to NFT transferred to the given address.
    /// @param metadataHash Hash of the metadata of the NFT.
    function commitMint(address _to, bytes32 metadataHash, string calldata _tokenUri) external;

    /// @notice Sets the royalty information that all ids in this contract will default to.
    /// Requirements:
    /// `receiver` cannot be the zero address.
    /// `feeNumerator` cannot be greater than the fee denominator.
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external;

    /// @notice Sets the royalty information for a specific token id, overriding the global default.
    /// Requirements:
    /// `receiver` cannot be the zero address.
    /// `feeNumerator` cannot be greater than the fee denominator.
    /// @param tokenId Token identitifer whom royalty information gonna set.
    /// @param receiver Beneficiary of the royalty.
    /// @param feeNumerator Percentage of fee gonna charge as royalty.
    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    )
        external;

    /// @notice Deletes the default royalty information.
    function deleteDefaultRoyalty() external;

    /// @notice Global royalty would not be in use after this.
    function closeGlobalRoyalty() external;

    /// @notice Global royalty would be in use after this.
    function openGlobalRoyalty() external;

    /// @notice Resets royalty information for the token id back to the global default.
    function resetTokenRoyalty(uint256 tokenId) external;

    /// @notice Returns the URI that provides the details of royalty for OpenSea support.
    /// Ref - https://docs.opensea.io/v2.0/docs/contract-level-metadata
    function contractURI() external view returns (string memory);

    /// @notice Returns the Uniform Resource Identifier (URI) for `tokenId` token.
    /// @param tokenId Identifier for the token
    function tokenURI(uint256 tokenId)
        external
        view
        returns (string memory);
    
    /// @notice Returns the base URI for the contract.
    function baseURI() external view returns (string memory);

    /// @notice Set the base URI, Only ADMIN can call it.
    /// @param newBaseUri New base uri for the metadata.
    function setBaseUri(string memory newBaseUri) external;

    /// @notice Set the token URI for the given tokenId.
    /// @param tokenId Identifier for the token
    /// @param tokenUri URI for the given tokenId.
    function setTokenUri(uint256 tokenId, string memory tokenUri) external;

    /// @notice Perform the mutation on a tokenID. Only tokenId owner allowed to perform mutation.
    /// @param tokenId Identifier for the token.
    /// @param mutagen Address of the mutagen.
    /// @param expiry Expiry of the signature.
    /// @param signatureNonce Nonce that is used to create the signature.
    /// @param signature Offchain signature of the authorised address.
    function mutate(
        address projectNFT, 
        uint256 tokenId, 
        address mutagen, 
        uint256 mutagenNFTId,
        uint256 expiry, 
        uint256 signatureNonce,
        bytes memory signature
    ) external;

    /// @notice Reveal the metadata of the already minted tokenId.
    /// @param tokenId Identifier of the NFT whose metadata is going to set.
    /// @param metadata Metadata of the given NFT.
    /// @param salt Unique identifier use to reveal the metadata.
    function revealMetadata(uint256 tokenId, NFTMetadataViews.NFTView memory metadata, string memory salt) external;

    function nextTokenId() external view returns (uint256);

    function maximumSupply() external view returns (uint256);

    function globalRoyaltyInEffect() external view returns (bool);

    function owner() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IOracleRegistry {
    function decimals(string memory target) external view returns (uint8);

    function description(string memory target)
        external
        view
        returns (string memory);

    function latestRoundData(string memory target)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {IMetadataViewResolver} from "./interfaces/IMetadataViewResolver.sol";
import { strings } from "@string-utils/strings.sol";

library NFTMetadataViews {

    using strings for *;

    // bytes32 constant rarityView = keccak256(abi.encode("Struct Rarity{uint256 score, uint256 max, string description}"));
    // bytes32 constant traitView = keccak256(abi.encode("Struct Trait{string name, bytes vaule, string dataType, string displayType, Rarity rarity}"));
    bytes32 constant traitsView = keccak256(abi.encode("Struct Attributes{Attribute[] attributes}"));
    bytes32 constant displayView = keccak256(abi.encode("Struct Display{string name, string description}"));

    /// View to expose rarity information for a single rarity
    /// Note that a rarity needs to have either score or description but it can 
    /// have both
    ///
    struct Rarity {
        /// The score of the rarity as a number
        uint256 score;

        /// The maximum value of score
        uint256 max;

        /// The description of the rarity as a string.
        ///
        /// This could be Legendary, Epic, Rare, Uncommon, Common or any other string value
        string description;
    }

    /// Helper to get Rarity view in a typesafe way
    ///
    /// @param nftContract: NFT contract to get the rarity
    /// @param nftId: NFT id
    /// @return Rarity 
    ///
    // function getRarity(address nftContract, uint256 nftId) external view returns(Rarity rarityMetadata){
    //     bytes rarity = IMetadataViewResolver(nftContract).resolveView(nftId, rarityView);
    //     if (rarity.length > 0) {
    //         rarityMetadata = abi.decode(rarity, (Rarity));
    //     }
    // }


    /// View to represent a single field of metadata on an NFT.
    /// This is used to get traits of individual key/value pairs along with some
    /// contextualized data about the trait
    ///
    struct Attribute {
        // The name of the trait. Like Background, Eyes, Hair, etc.
        string trait_type;

        // The underlying value of the trait, the rest of the fields of a trait provide context to the value.
        bytes value;

        // The data type of the underlying value.
        string data_type;

        // displayType is used to show some context about what this name and value represent
        // for instance, you could set value to a unix timestamp, and specify displayType as "Date" to tell
        // platforms to consume this trait as a date and not a number
        string display_type;

        // Rarity can also be used directly on an attribute.
        //
        // This is optional because not all attributes need to contribute to the NFT's rarity.
        Rarity rarity;
    }


    /// Wrapper view to return all the traits on an NFT.
    /// This is used to return traits as individual key/value pairs along with
    /// some contextualized data about each trait.
    struct Attributes {
        Attribute[] attributes;
    }

    /// Helper to get Traits view in a typesafe way
    ///
    /// @param nftContract: A reference to the resolver resource
    /// @param nftId: A reference to the resolver resource
    ///
    function getTraits(address nftContract, uint256 nftId) public returns(Attributes memory traitsMetadata) {
        bytes memory traits = IMetadataViewResolver(nftContract).resolveView(nftId, traitsView);
        if (traits.length > 0) {
            traitsMetadata = abi.decode(traits, (Attributes));
        }
    }

    /// View to expose a file stored on IPFS.
    /// IPFS images are referenced by their content identifier (CID)
    /// rather than a direct URI. A client application can use this CID
    /// to find and load the image via an IPFS gateway.
    ///
    struct IPFSFile {

        /// CID is the content identifier for this IPFS file.
        ///
        /// Ref: https://docs.ipfs.io/concepts/content-addressing/
        ///
        string cid;

        /// Path is an optional path to the file resource in an IPFS directory.
        ///
        /// This field is only needed if the file is inside a directory.
        ///
        /// Ref: https://docs.ipfs.io/concepts/file-systems/
        ///
        string path;
    }

    /// This function returns the IPFS native URL for this file.
    /// Ref: https://docs.ipfs.io/how-to/address-ipfs-on-web/#native-urls
    ///
    /// @return The string containing the file uri
    ///
    function getUri(IPFSFile memory ipfs) public pure returns(string memory) {
        string memory ipfs_default_location = "ipfs://".toSlice().concat(ipfs.cid.toSlice());
        if (bytes(ipfs.path).length == 0) {
            return (ipfs_default_location
                .toSlice()
                .concat("/".toSlice()))
                .toSlice()
                .concat(ipfs.path.toSlice());
        }
        return ipfs_default_location;
    }


    struct Display {
        /// The name of the object. 
        ///
        /// This field will be displayed in lists and therefore should
        /// be short an concise.
        ///
        string name;

        /// A written description of the object. 
        ///
        /// This field will be displayed in a detailed view of the object,
        /// so can be more verbose (e.g. a paragraph instead of a single line).
        ///
        string description;


        IPFSFile file;
    }


    function getDisplay(address nftContract, uint256 nftId) public returns(Display memory displayMetadata) {
        bytes memory display_content = IMetadataViewResolver(nftContract).resolveView(nftId, displayView);
        if (display_content.length > 0) {
            displayMetadata = abi.decode(display_content, (Display));
        }
    }

    struct NFTView {
        Display display;
        string uri;
        Attributes attributes;
    }

    function getNFTView(address nftContract, uint256 nftId) external returns(NFTView memory nftMetdata) {
        Display memory display = getDisplay(nftContract, nftId);
        return NFTView({
            display: display,
            uri: bytes(display.file.cid).length > 0? getUri(display.file): "" ,
            attributes: getTraits(nftContract, nftId)
        });
    }

    /// @dev This function has been created just to use in abi for the signature generation at FE
    function getView(NFTView[] memory nftView) external pure returns(string memory) {
        return "abc";
    }


}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "../NFTMetadataViews.sol";
import "../Mutagen.sol";

interface IMutagenNFT {

    function initialize (
        string calldata _baseUri,
        string calldata _name,
        string calldata _symbol,
        address _owner,
        address _minter,
        address _royaltyReceiver,
        uint96[3] memory _royaltyMetadata,
        Mutagen.AgentType _agent,
        Mutagen.Classification _classification
    ) external;

    function mint(address _to, NFTMetadataViews.NFTView memory metadata) external;

    function maximumSupply() external view returns(uint256);

    function burn(uint256 tokenId) external;

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {NFTMetadataViews} from "../NFTMetadataViews.sol";

interface IMutagenise {

    function getBaseMultiplier(address mutagenNFT, NFTMetadataViews.NFTView memory metadata) external view returns(uint256);
    
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IMetadataViewResolver is IERC165 {

    function getViews(uint256 nftId) external view returns(bytes32[] memory);
    function resolveView(uint256 nftId, bytes32 viewType) external returns(bytes memory);

}

/*
 * @title String & slice utility library for Solidity contracts.
 * @author Nick Johnson <[email protected]>
 *
 * @dev Functionality in this library is largely implemented using an
 *      abstraction called a 'slice'. A slice represents a part of a string -
 *      anything from the entire string to a single character, or even no
 *      characters at all (a 0-length slice). Since a slice only has to specify
 *      an offset and a length, copying and manipulating slices is a lot less
 *      expensive than copying and manipulating the strings they reference.
 *
 *      To further reduce gas costs, most functions on slice that need to return
 *      a slice modify the original one instead of allocating a new one; for
 *      instance, `s.split(".")` will return the text up to the first '.',
 *      modifying s to only contain the remainder of the string after the '.'.
 *      In situations where you do not want to modify the original slice, you
 *      can make a copy first with `.copy()`, for example:
 *      `s.copy().split(".")`. Try and avoid using this idiom in loops; since
 *      Solidity has no memory management, it will result in allocating many
 *      short-lived slices that are later discarded.
 *
 *      Functions that return two slices come in two versions: a non-allocating
 *      version that takes the second slice as an argument, modifying it in
 *      place, and an allocating version that allocates and returns the second
 *      slice; see `nextRune` for example.
 *
 *      Functions that have to copy string data will return strings rather than
 *      slices; these can be cast back to slices for further processing if
 *      required.
 *
 *      For convenience, some functions are provided with non-modifying
 *      variants that create a new slice and return both; for instance,
 *      `s.splitNew('.')` leaves s unmodified, and returns two values
 *      corresponding to the left and right parts of the string.
 */

pragma solidity ^0.8.0;

library strings {
    struct slice {
        uint _len;
        uint _ptr;
    }

    function memcpy(uint dest, uint src, uint len) private pure {
        // Copy word-length chunks while possible
        for(; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = type(uint).max;
        if (len > 0) {
            mask = 256 ** (32 - len) - 1;
        }
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /*
     * @dev Returns a slice containing the entire string.
     * @param self The string to make a slice from.
     * @return A newly allocated slice containing the entire string.
     */
    function toSlice(string memory self) internal pure returns (slice memory) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

    /*
     * @dev Returns the length of a null-terminated bytes32 string.
     * @param self The value to find the length of.
     * @return The length of the string, from 0 to 32.
     */
    function len(bytes32 self) internal pure returns (uint) {
        uint ret;
        if (self == 0)
            return 0;
        if (uint(self) & type(uint128).max == 0) {
            ret += 16;
            self = bytes32(uint(self) / 0x100000000000000000000000000000000);
        }
        if (uint(self) & type(uint64).max == 0) {
            ret += 8;
            self = bytes32(uint(self) / 0x10000000000000000);
        }
        if (uint(self) & type(uint32).max == 0) {
            ret += 4;
            self = bytes32(uint(self) / 0x100000000);
        }
        if (uint(self) & type(uint16).max == 0) {
            ret += 2;
            self = bytes32(uint(self) / 0x10000);
        }
        if (uint(self) & type(uint8).max == 0) {
            ret += 1;
        }
        return 32 - ret;
    }

    /*
     * @dev Returns a slice containing the entire bytes32, interpreted as a
     *      null-terminated utf-8 string.
     * @param self The bytes32 value to convert to a slice.
     * @return A new slice containing the value of the input argument up to the
     *         first null.
     */
    function toSliceB32(bytes32 self) internal pure returns (slice memory ret) {
        // Allocate space for `self` in memory, copy it there, and point ret at it
        assembly {
            let ptr := mload(0x40)
            mstore(0x40, add(ptr, 0x20))
            mstore(ptr, self)
            mstore(add(ret, 0x20), ptr)
        }
        ret._len = len(self);
    }

    /*
     * @dev Returns a new slice containing the same data as the current slice.
     * @param self The slice to copy.
     * @return A new slice containing the same data as `self`.
     */
    function copy(slice memory self) internal pure returns (slice memory) {
        return slice(self._len, self._ptr);
    }

    /*
     * @dev Copies a slice to a new string.
     * @param self The slice to copy.
     * @return A newly allocated string containing the slice's text.
     */
    function toString(slice memory self) internal pure returns (string memory) {
        string memory ret = new string(self._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        memcpy(retptr, self._ptr, self._len);
        return ret;
    }

    /*
     * @dev Returns the length in runes of the slice. Note that this operation
     *      takes time proportional to the length of the slice; avoid using it
     *      in loops, and call `slice.empty()` if you only need to know whether
     *      the slice is empty or not.
     * @param self The slice to operate on.
     * @return The length of the slice in runes.
     */
    function len(slice memory self) internal pure returns (uint l) {
        // Starting at ptr-31 means the LSB will be the byte we care about
        uint ptr = self._ptr - 31;
        uint end = ptr + self._len;
        for (l = 0; ptr < end; l++) {
            uint8 b;
            assembly { b := and(mload(ptr), 0xFF) }
            if (b < 0x80) {
                ptr += 1;
            } else if(b < 0xE0) {
                ptr += 2;
            } else if(b < 0xF0) {
                ptr += 3;
            } else if(b < 0xF8) {
                ptr += 4;
            } else if(b < 0xFC) {
                ptr += 5;
            } else {
                ptr += 6;
            }
        }
    }

    /*
     * @dev Returns true if the slice is empty (has a length of 0).
     * @param self The slice to operate on.
     * @return True if the slice is empty, False otherwise.
     */
    function empty(slice memory self) internal pure returns (bool) {
        return self._len == 0;
    }

    /*
     * @dev Returns a positive number if `other` comes lexicographically after
     *      `self`, a negative number if it comes before, or zero if the
     *      contents of the two slices are equal. Comparison is done per-rune,
     *      on unicode codepoints.
     * @param self The first slice to compare.
     * @param other The second slice to compare.
     * @return The result of the comparison.
     */
    function compare(slice memory self, slice memory other) internal pure returns (int) {
        uint shortest = self._len;
        if (other._len < self._len)
            shortest = other._len;

        uint selfptr = self._ptr;
        uint otherptr = other._ptr;
        for (uint idx = 0; idx < shortest; idx += 32) {
            uint a;
            uint b;
            assembly {
                a := mload(selfptr)
                b := mload(otherptr)
            }
            if (a != b) {
                // Mask out irrelevant bytes and check again
                uint mask = type(uint).max; // 0xffff...
                if(shortest < 32) {
                  mask = ~(2 ** (8 * (32 - shortest + idx)) - 1);
                }
                unchecked {
                    uint diff = (a & mask) - (b & mask);
                    if (diff != 0)
                        return int(diff);
                }
            }
            selfptr += 32;
            otherptr += 32;
        }
        return int(self._len) - int(other._len);
    }

    /*
     * @dev Returns true if the two slices contain the same text.
     * @param self The first slice to compare.
     * @param self The second slice to compare.
     * @return True if the slices are equal, false otherwise.
     */
    function equals(slice memory self, slice memory other) internal pure returns (bool) {
        return compare(self, other) == 0;
    }

    /*
     * @dev Extracts the first rune in the slice into `rune`, advancing the
     *      slice to point to the next rune and returning `self`.
     * @param self The slice to operate on.
     * @param rune The slice that will contain the first rune.
     * @return `rune`.
     */
    function nextRune(slice memory self, slice memory rune) internal pure returns (slice memory) {
        rune._ptr = self._ptr;

        if (self._len == 0) {
            rune._len = 0;
            return rune;
        }

        uint l;
        uint b;
        // Load the first byte of the rune into the LSBs of b
        assembly { b := and(mload(sub(mload(add(self, 32)), 31)), 0xFF) }
        if (b < 0x80) {
            l = 1;
        } else if(b < 0xE0) {
            l = 2;
        } else if(b < 0xF0) {
            l = 3;
        } else {
            l = 4;
        }

        // Check for truncated codepoints
        if (l > self._len) {
            rune._len = self._len;
            self._ptr += self._len;
            self._len = 0;
            return rune;
        }

        self._ptr += l;
        self._len -= l;
        rune._len = l;
        return rune;
    }

    /*
     * @dev Returns the first rune in the slice, advancing the slice to point
     *      to the next rune.
     * @param self The slice to operate on.
     * @return A slice containing only the first rune from `self`.
     */
    function nextRune(slice memory self) internal pure returns (slice memory ret) {
        nextRune(self, ret);
    }

    /*
     * @dev Returns the number of the first codepoint in the slice.
     * @param self The slice to operate on.
     * @return The number of the first codepoint in the slice.
     */
    function ord(slice memory self) internal pure returns (uint ret) {
        if (self._len == 0) {
            return 0;
        }

        uint word;
        uint length;
        uint divisor = 2 ** 248;

        // Load the rune into the MSBs of b
        assembly { word:= mload(mload(add(self, 32))) }
        uint b = word / divisor;
        if (b < 0x80) {
            ret = b;
            length = 1;
        } else if(b < 0xE0) {
            ret = b & 0x1F;
            length = 2;
        } else if(b < 0xF0) {
            ret = b & 0x0F;
            length = 3;
        } else {
            ret = b & 0x07;
            length = 4;
        }

        // Check for truncated codepoints
        if (length > self._len) {
            return 0;
        }

        for (uint i = 1; i < length; i++) {
            divisor = divisor / 256;
            b = (word / divisor) & 0xFF;
            if (b & 0xC0 != 0x80) {
                // Invalid UTF-8 sequence
                return 0;
            }
            ret = (ret * 64) | (b & 0x3F);
        }

        return ret;
    }

    /*
     * @dev Returns the keccak-256 hash of the slice.
     * @param self The slice to hash.
     * @return The hash of the slice.
     */
    function keccak(slice memory self) internal pure returns (bytes32 ret) {
        assembly {
            ret := keccak256(mload(add(self, 32)), mload(self))
        }
    }

    /*
     * @dev Returns true if `self` starts with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function startsWith(slice memory self, slice memory needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        if (self._ptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let selfptr := mload(add(self, 0x20))
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }
        return equal;
    }

    /*
     * @dev If `self` starts with `needle`, `needle` is removed from the
     *      beginning of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function beyond(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        bool equal = true;
        if (self._ptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let selfptr := mload(add(self, 0x20))
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
            self._ptr += needle._len;
        }

        return self;
    }

    /*
     * @dev Returns true if the slice ends with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function endsWith(slice memory self, slice memory needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        uint selfptr = self._ptr + self._len - needle._len;

        if (selfptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }

        return equal;
    }

    /*
     * @dev If `self` ends with `needle`, `needle` is removed from the
     *      end of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function until(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        uint selfptr = self._ptr + self._len - needle._len;
        bool equal = true;
        if (selfptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
        }

        return self;
    }

    // Returns the memory address of the first byte of the first occurrence of
    // `needle` in `self`, or the first byte after `self` if not found.
    function findPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr = selfptr;
        uint idx;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask;
                if (needlelen > 0) {
                    mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));
                }

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                uint end = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr >= end)
                        return selfptr + selflen;
                    ptr++;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }

                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr;
                    ptr += 1;
                }
            }
        }
        return selfptr + selflen;
    }

    // Returns the memory address of the first byte after the last occurrence of
    // `needle` in `self`, or the address of `self` if not found.
    function rfindPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask;
                if (needlelen > 0) {
                    mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));
                }

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                ptr = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr <= selfptr)
                        return selfptr;
                    ptr--;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr + needlelen;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }
                ptr = selfptr + (selflen - needlelen);
                while (ptr >= selfptr) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr + needlelen;
                    ptr -= 1;
                }
            }
        }
        return selfptr;
    }

    /*
     * @dev Modifies `self` to contain everything from the first occurrence of
     *      `needle` to the end of the slice. `self` is set to the empty slice
     *      if `needle` is not found.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function find(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len -= ptr - self._ptr;
        self._ptr = ptr;
        return self;
    }

    /*
     * @dev Modifies `self` to contain the part of the string from the start of
     *      `self` to the end of the first occurrence of `needle`. If `needle`
     *      is not found, `self` is set to the empty slice.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function rfind(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len = ptr - self._ptr;
        return self;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and `token` to everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function split(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = self._ptr;
        token._len = ptr - self._ptr;
        if (ptr == self._ptr + self._len) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
            self._ptr = ptr + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and returning everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` up to the first occurrence of `delim`.
     */
    function split(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        split(self, needle, token);
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and `token` to everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function rsplit(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = ptr;
        token._len = self._len - (ptr - self._ptr);
        if (ptr == self._ptr) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and returning everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` after the last occurrence of `delim`.
     */
    function rsplit(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        rsplit(self, needle, token);
    }

    /*
     * @dev Counts the number of nonoverlapping occurrences of `needle` in `self`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return The number of occurrences of `needle` found in `self`.
     */
    function count(slice memory self, slice memory needle) internal pure returns (uint cnt) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr) + needle._len;
        while (ptr <= self._ptr + self._len) {
            cnt++;
            ptr = findPtr(self._len - (ptr - self._ptr), ptr, needle._len, needle._ptr) + needle._len;
        }
    }

    /*
     * @dev Returns True if `self` contains `needle`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return True if `needle` is found in `self`, false otherwise.
     */
    function contains(slice memory self, slice memory needle) internal pure returns (bool) {
        return rfindPtr(self._len, self._ptr, needle._len, needle._ptr) != self._ptr;
    }

    /*
     * @dev Returns a newly allocated string containing the concatenation of
     *      `self` and `other`.
     * @param self The first slice to concatenate.
     * @param other The second slice to concatenate.
     * @return The concatenation of the two strings.
     */
    function concat(slice memory self, slice memory other) internal pure returns (string memory) {
        string memory ret = new string(self._len + other._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }
        memcpy(retptr, self._ptr, self._len);
        memcpy(retptr + self._len, other._ptr, other._len);
        return ret;
    }

    /*
     * @dev Joins an array of slices, using `self` as a delimiter, returning a
     *      newly allocated string.
     * @param self The delimiter to use.
     * @param parts A list of slices to join.
     * @return A newly allocated string containing all the slices in `parts`,
     *         joined with `self`.
     */
    function join(slice memory self, slice[] memory parts) internal pure returns (string memory) {
        if (parts.length == 0)
            return "";

        uint length = self._len * (parts.length - 1);
        for(uint i = 0; i < parts.length; i++)
            length += parts[i]._len;

        string memory ret = new string(length);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        for(uint i = 0; i < parts.length; i++) {
            memcpy(retptr, parts[i]._ptr, parts[i]._len);
            retptr += parts[i]._len;
            if (i < parts.length - 1) {
                memcpy(retptr, self._ptr, self._len);
                retptr += self._len;
            }
        }

        return ret;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

library Mutagen {

    type Classification is uint8;

    enum AgentType { PHYSICAL, CHEMICAL, BIOLOGICAL }

    enum PhysicalClassification { HEAT, RADIATION }

    enum ChemicalClassification { BASE_ANALOGS, INTERCALATING_AGENTS, METAL_IONS, ALKYLATING_AGENTS }

    enum BiologicalClassification { TRANSPOSONS_IS, VIRUS, BACTERIA, OTHER }


    function matchClassification(AgentType agent, Classification classification) external pure returns(bool) {
       if (AgentType.PHYSICAL == agent) {
        return physicalAgentClassification(classification);
       } else if (AgentType.CHEMICAL == agent) {
        return chemicalAgentClassification(classification);
       } else if (AgentType.BIOLOGICAL == agent) {
        return biologicalAgentClassification(classification);
       }
       return false;
    }

    function physicalAgentClassification(Classification classification) public pure returns(bool) {
        uint8 _unwrappedClassification = Classification.unwrap(classification);
        if (uint8(PhysicalClassification.HEAT) == _unwrappedClassification) {
            return true;
        } else if (uint8(PhysicalClassification.RADIATION) == _unwrappedClassification) {
            return true;
        } 
        return false;
    }

    function chemicalAgentClassification(Classification classification) public pure returns(bool) {
        uint8 _unwrappedClassification = Classification.unwrap(classification);
        if (uint8(ChemicalClassification.BASE_ANALOGS) == _unwrappedClassification) {
            return true;
        } else if (uint8(ChemicalClassification.INTERCALATING_AGENTS) == _unwrappedClassification) {
            return true;
        } else if (uint8(ChemicalClassification.METAL_IONS) == _unwrappedClassification) {
            return true;
        } else if (uint8(ChemicalClassification.ALKYLATING_AGENTS) == _unwrappedClassification) {
            return true;
        } 
        return false;
    }

    function biologicalAgentClassification(Classification classification) public pure returns(bool) {
        uint8 _unwrappedClassification = Classification.unwrap(classification);
        if (uint8(BiologicalClassification.TRANSPOSONS_IS) == _unwrappedClassification) {
            return true;
        } else if (uint8(BiologicalClassification.VIRUS) == _unwrappedClassification) {
            return true;
        } else if (uint8(BiologicalClassification.BACTERIA) == _unwrappedClassification) {
            return true;
        }
        return false;
    } 
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}