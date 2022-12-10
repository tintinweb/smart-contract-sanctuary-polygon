// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Openzeppelin
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
// Callback
import "../Callback/AmberfiCallbackUpgradeable.sol";
// ERC721 Lockable
import "../ERC721/ERC721LockableUpgradeable.sol";
// ERC721 Storage Content
import "../ERC721/ERC721TokenURIAmberfiStorageContentUpgradeable.sol";
// Key Storage
import "../KeyStorage/AmberfiKeyStorageUpgradeable.sol";
// Storage
import "../Storage/AmberfiStorage.sol";
// Interfaces
import "../interfaces/IERC721FullAmberfiContentFactory.sol";
// Libraries
import "../libs/AmberfiLib.sol";

contract NFT is
    Initializable,
    ERC721Upgradeable,
    ERC721LockableUpgradeable,
    ERC721BurnableUpgradeable,
    ERC721URIStorageUpgradeable,
    ERC721TokenURIAmberfiStorageContentUpgradeable,
    ERC2981Upgradeable,
    IERC721FullAmberfiContentFactory,
    AmberfiCallbackUpgradeable,
    AmberfiKeyStorageUpgradeable,
    ReentrancyGuardUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIdsCounter;
    address private _trustedForwarder;

    address public marketAddress;
    address public amberfiStorageAddress;

    event NFTMinted(
        address indexed to,
        uint256 tokenId,
        address indexed royaltyRecipient,
        uint96 royaltyValue
    );

    function initialize(
        address marketAddress_,
        address amberfiStorageAddress_,
        address trustedForwarder_,
        string calldata name_,
        string calldata symbol_
    ) public initializer {
        __ERC721_init(name_, symbol_);
        __AmberfiContent_init();
        __AmberfiKeyStorage_init();

        if (
            marketAddress_ == address(0) ||
            amberfiStorageAddress_ == address(0) ||
            trustedForwarder_ == address(0)
        ) {
            revert AmberfiLib.NFT_ZeroAddress();
        }

        marketAddress = marketAddress_;
        amberfiStorageAddress = amberfiStorageAddress_;
        _trustedForwarder = trustedForwarder_;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override(ERC721Upgradeable, ERC721LockableUpgradeable) {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    function _burn(uint256 tokenId)
        internal
        override(
            ERC721Upgradeable,
            ERC721LockableUpgradeable,
            ERC721URIStorageUpgradeable
        )
    {
        super._burn(tokenId);
    }

    function _msgSender() internal view override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }

    function mint(
        address to_,
        uint256 tokenId_,
        address royaltyRecipient_,
        uint96 royaltyValue_,
        string calldata tokenUri_,
        bool,
        string calldata contentUri_,
        string calldata encryptKey_,
        uint8 storageLocationId_
    ) external override(IERC721FullAmberfiContentFactory) nonReentrant {
        uint256 newItemId = tokenId_;
        if (tokenId_ == 0) {
            while (_exists(newItemId)) {
                _tokenIdsCounter.increment();
                newItemId = _tokenIdsCounter.current();
            }
        } else {
            _tokenIdsCounter.increment();
        }

        setEncryptKey(newItemId, encryptKey_);
        setContentURI(newItemId, contentUri_);

        // if (bytes(tokenUri_).length > 0) {
        //     _setTokenURI(newItemId, tokenUri_);
        // }

        // if (royaltyValue_ > 0) {
        //     _setTokenRoyalty(
        //         newItemId,
        //         royaltyRecipient_ == address(0)
        //             ? _msgSender()
        //             : royaltyRecipient_,
        //         royaltyValue_
        //     );
        // }

        // setApprovalForAll(marketAddress, true);

        // _safeMint(to_ == address(0x0) ? _msgSender() : to_, newItemId, "");

        // AmberfiStorage(address(amberfiStorageAddress)).registerStorage(
        //     newItemId,
        //     tokenUri_,
        //     storageLocationId_
        // );

        emit NFTMinted(to_, newItemId, royaltyRecipient_, royaltyValue_);
    }

    /**
     * @dev Sets content URI,
     * @param tokenId_ the token id fir which we register the royalties
     * @param isEncrypted_ Content location
     */
    function setContentAsEncrypted(uint256 tokenId_, bool isEncrypted_) public {
        Content memory contentObj = _contents[tokenId_];
        contentObj.isEncrypted = isEncrypted_;
        _contents[tokenId_] = contentObj;
    }

    /**
     * @dev gets content URI
     * @param tokenId_ the token id fir which we register the royalties
     */
    function getContentURI(uint256 tokenId_)
        public
        view
        returns (string memory)
    {
        Content memory contentObj = _contents[tokenId_];
        return contentObj.content;
    }

    /**
     * @dev gets content URI
     * @param tokenId_ the token id fir which we register the royalties
     */
    function getIsEncrypted(uint256 tokenId_) public view returns (bool) {
        Content memory contentObj = _contents[tokenId_];
        return contentObj.isEncrypted;
    }

    function encryptContent(
        uint256 itemId_,
        string calldata encryptCid_,
        uint8 storageLocationId_
    ) public override {
        AmberfiStorage astorage = AmberfiStorage(
            address(amberfiStorageAddress)
        );
        astorage.registerEncryptedStorage(
            itemId_,
            tokenURI(itemId_),
            encryptCid_,
            storageLocationId_
        );
        astorage.setStorageStatus(
            _msgSender(),
            itemId_,
            tokenURI(itemId_),
            AmberfiStorage.Status.Pending
        );
    }

    /**
     * @dev Check if forwarder is trusted forwarder
     * @param forwarder_ (address) Forwarder address
     * @return (bool) result
     */
    function isTrustedForwarder(address forwarder_) public view returns (bool) {
        return forwarder_ == _trustedForwarder;
    }

    /**
     * @dev Sets content URI
     * @param tokenId_ the token id fir which we register the royalties
     * @param content_ recipient of the royalties
     */
    function setContentURI(uint256 tokenId_, string memory content_) public {
        Content memory contentObj = _contents[tokenId_];
        contentObj.content = content_;
        _contents[tokenId_] = contentObj;
    }

    function setContent(
        uint256 itemId_,
        string calldata tempCid_,
        string calldata cid_,
        string calldata,
        Status
    ) public override(AmberfiCallbackUpgradeable) {
        AmberfiStorage astorage = AmberfiStorage(address(marketAddress));
        AmberfiCallbackUpgradeable.Status store = astorage.getStorageStatus(
            itemId_,
            tempCid_
        );
        // string
        //     memory errorBase = "NFT: Amberfi failed to store content on Arweave old status=";
        // string memory errorStatus = " new status= ";
        // string memory errorMessage = append(
        //     errorBase,
        //     stringVar(store),
        //     errorStatus,
        //     stringVar(status_)
        // );
        // // This isn't properly compariing, is the error message the issue?
        // require(
        //     store == Status.Pending && status_ == Status.Finalized,
        //     errorMessage
        // );
        _setTokenURI(itemId_, cid_);
    }

    /**
     * @inheritdoc ERC165Upgradeable
     */
    function supportsInterface(bytes4 interfaceId_)
        public
        view
        virtual
        override(
            ERC721Upgradeable,
            ERC721LockableUpgradeable,
            ERC721TokenURIAmberfiStorageContentUpgradeable,
            ERC2981Upgradeable,
            IERC721FullAmberfiContentFactory,
            AmberfiCallbackUpgradeable,
            AmberfiKeyStorageUpgradeable
        )
        returns (bool)
    {
        return
            interfaceId_ == type(ERC2981Upgradeable).interfaceId ||
            interfaceId_ ==
            type(IERC721FullAmberfiContentFactory).interfaceId ||
            interfaceId_ == type(AmberfiCallbackUpgradeable).interfaceId ||
            interfaceId_ == type(AmberfiKeyStorageUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId_);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library AmberfiLib {
    enum AuctionCreateErrorType {
        INVALID_TIME_RANGE,
        INVALID_PRICE_USD,
        INVALID_START_PRICE,
        INVALID_RESERVED_PRICE,
        INVALID_NFT_CONTRACT,
        INVALID_TOKEN_ID,
        INVALID_PAYMENT_TOKEN_INDEX
    }

    enum AuctionBuyNowErrorType {
        INSTANTSALE_NOT_ENABLED,
        INVALID_PAYMENT_AMOUNT,
        INVALID_PAYMENT_TOKEN_INDEX,
        CREATOR_CANNOT_BUY,
        AUCTION_COMPLETED_OR_CANCELLED,
        AUCTION_ENDED_OR_NOT_STARTED
    }

    enum AuctionBidErrorType {
        CANNOT_BID_TO_INSTANT_SALE_AUCTION,
        INVALID_BID_AMOUNT,
        INVALID_PAYMENT_TOKEN_INDEX,
        CREATOR_CANNOT_BID,
        AUCTION_COMPLETED_OR_CANCELLED,
        AUCTION_ENDED_OR_NOT_STARTED
    }

    enum AuctionRedeemNFTErrorType {
        NOT_AUCTION_WINNER,
        AUCTION_COMPLETED_OR_CANCELLED,
        AUCTION_NOT_ENDED,
        NFT_ALREADY_REDEEMED
    }

    enum AuctionClaimPaymentErrorType {
        NOT_AUCTION_CREATOR,
        AUCTION_COMPLETED_OR_CANCELLED,
        AUCTION_NOT_ENDED,
        NFT_NOT_REDEEMED
    }

    enum AuctionCancelErrorType {
        NOT_AUCTION_CREATOR,
        AUCTION_COMPLETED_OR_ALREADY_CANCELLED,
        AUCTION_ENDED
    }

    enum PaymentTokenRemoveErrorType {
        INVALID_PAYMENT_TOKEN_INDEX,
        WITHDRAW_TOKENS_FIRST,
        ACTIVE_AUCTIONS_EXIST
    }

    enum AuctionState {
        STARTED, // Auction started
        CANCELLED, // Auction cancelled
        COMPLETED // Auction completed
    }

    enum ClaimState {
        NONE,
        REDEEMED, // Auction ended and NFT redeemed
        CLAIMED // Auction ended and payment claimed
    }

    struct Auction {
        uint256 auctionId; // Auction ID
        uint256 startTime; // Auction start time in timestamp
        uint256 endTime; // Auction end time in timestamp
        uint256 priceUSD; // Auction price in USD (for instant sale)
        uint256 startPrice; // Auction start price in PaymentToken
        uint256 reservedPrice; // Auction reserved price in PaymentToken
        address creator; // Auction creator
        address nftContract; // The address of the NFT contract
        uint256 tokenId; // Token ID
        uint256[] paymentTokenIndexes; // Array of PaymentToken indexes to place bid at this auction
        Bid highestBid;
        AuctionState auctionState; // Auction state
        bool instantSale; // true for instant sale, false for not
    }

    struct Bid {
        address bidder; // Bidder address
        uint256 bidAmount; // Bid amount in PaymentToken
        uint256 paymentTokenIndex; // Bid PaymentToken index
    }

    struct PaymentToken {
        address token; // Token address
        address aggregator; // Chainlink Aggregator address
        uint8 tokenDecimals; // Token decimals
        uint8 aggregatorDecimals; // Aggregator decimals
        bool native; // Check if token is native or ERC-20 (if native, token = 0x0, decimals = 18)
        bool enabled; // Check if token is enabled
    }

    struct MarketContract {
        uint256 marketId;
        address marketContract;
        address marketOwner;
        bool enabled;
    }

    struct MarketFeeTier {
        address feeRecipient;
        uint256 feeTier; // 1% = 100
    }

    error Market_InvalidAuctionID();
    error Market_InvalidMetaTxSignature();
    error Market_InvalidMinAuctionPrice();
    error Market_InvalidWithdrawAmount();
    error Market_AuctionCreateFailed(uint8 errorType);
    error Market_AuctionBuyNowFailed(uint8 errorType);
    error Market_AuctionBidFailed(uint8 errorType);
    error Market_AuctionRedeemNFTFailed(uint8 errorType);
    error Market_AuctionClaimPaymentFailed(uint8 errorType);
    error Market_AuctionCancelFailed(uint8 errorType);
    error Market_PaymentTokenAddFailed();
    error Market_PaymentTokenRemoveFailed(uint8 errorType);
    error Market_TokenNotEnabled();
    error Market_ZeroAddress();
    error Market_Paused();
    error Market_InvalidFeeTierRecipient();
    error Market_InvalidFeeTier();
    error Market_InvalidFeeTiersSum();
    error MarketRegistry_NotAmberfiOwner();
    error MarketRegistry_NotMarketOwner();
    error MarketRegistry_NotAmberfiNorMarketOwner();
    error MarketRegistry_NotKYCVerifier();
    error NFT_ZeroAddress();
    error KYCVerify_ZeroAddress();

    event AuctionCreated(
        uint256 auctionId,
        uint256 startTime,
        uint256 endTime,
        uint256 startPrice,
        uint256 reservedPrice,
        address indexed creator,
        address indexed nftContract,
        uint256 tokenId,
        uint256 paymentTokenIndex
    ); // Event emitted when a new auction created
    event InstantSaleCreated(
        uint256 auctionId,
        uint256 startTime,
        uint256 endTime,
        uint256 priceUSD,
        address indexed creator,
        address indexed nftContract,
        uint256 tokenId,
        uint256[] paymentTokenIndexes
    ); // Event emitted when a new instant sale created
    event BoughtNFT(address indexed buyer, uint256 amount, uint256 paymentTokenIndex); // Event emitted when an instant sale auction item sold
    event BidPlaced(address indexed bidder, uint256 bid, uint256 paymentTokenIndex); // Event emitted when a bid placed
    event NFTRedeemed(address indexed winner); // Event emitted when the auction winner redeem the purchased NFT
    event PaymentClaimed(address indexed owner, uint256 amount); // Event emitted when the auction owner claimed the payment
    event AuctionCanceled(uint256 auctionId); // Event emitted when the auction cancelled
    event MarketFeeTierChanged(MarketFeeTier[] feeTiers); // Event emitted when market fee tiers changed
    event MinAuctionListingPriceUSDChanged(uint256 newMinAuctionListingPriceUSD); // Event emitted when new min auction listing price in USD changed
    event MinBidIncrementPercentChanged(uint256 percent); // Event emitted when a new bid increment percent is set
    event PaymentTokenAdded(
        uint256 index,
        address indexed token,
        address indexed aggregator,
        uint8 tokenDecimals,
        uint8 aggregatorDecimals,
        bool native
    ); // Event emitted when payment token added
    event PaymentTokenRemoved(uint256 index); // Event emitted when payment token removed
    event AmberfiPaused(); // Amberfi Registry contract paused
    event AmberfiUnpaused(); // Umberfi Registry contract unpaused
    event MarketPaused(uint256 marketId); // Market contract paused
    event MarketUnpaused(uint256 marketId); // Market contract unpaused
    event AmberfiOwnerRoleGranted(address indexed account);
    event AmberfiOwnerRoleRevoked(address indexed account);
    event MarketOwnerRoleGranted(address indexed account);
    event MarketOwnerRoleRevoked(address indexed account);
    event KYCVerifierRoleGranted(address indexed account);
    event KYCVerifierRoleRevoked(address indexed account);
    event MarketRegistered(
        uint256 marketId,
        address indexed marketContract,
        address indexed marketOwner,
        bool enabled
    );
    event MarketUnregistered(uint256 marketId);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

/**
 * @dev ERC-721 Non-Fungible Token Standard, optional lockable extension
 * ERC721 Token that can be locked for a certain period and cannot be transferred.
 * This is designed for a non-escrow staking contract that comes later to lock a user's NFT
 * while still letting them keep it in their wallet.
 * This extension can ensure the security of user tokens during the staking period.
 * If the nft lending protocol is compatible with this extension, the trouble caused by the NFT
 * airdrop can be avoided, because the airdrop is still in the user's wallet
 */
interface IERC721LockableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is locked by `operator` from `from`.
     */
    event Locked(
        address indexed operator,
        address indexed from,
        uint256 indexed tokenId,
        uint256 expired
    );

    /**
     * @dev Emitted when `tokenId` token is unlocked by `operator` from `from`.
     */
    event Unlocked(
        address indexed operator,
        address indexed from,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to lock the `tokenId` token.
     */
    event LockApproval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to lock all of its tokens.
     */
    event LockApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Returns the locker who is locking the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function lockerOf(uint256 tokenId) external view returns (address locker);

    /**
     * @dev Lock `tokenId` token until the block number is greater than `expired` to be unlocked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - `expired` must be greater than block.timestamp
     * - If the caller is not `from`, it must be approved to lock this token
     * by either {lockApprove} or {setLockApprovalForAll}.
     *
     * Emits a {Locked} event.
     */
    function lockFrom(
        address from,
        uint256 tokenId,
        uint256 expired
    ) external;

    /**
     * @dev Unlock `tokenId` token.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - the caller must be the operator who locks the token by {lockFrom}
     *
     * Emits a {Unlocked} event.
     */
    function unlockFrom(address from, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to lock `tokenId` token.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved lock operator.
     * - `tokenId` must exist.
     *
     * Emits an {LockApproval} event.
     */
    function lockApprove(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an lock operator for the caller.
     * Operators can call {lockFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {LockApprovalForAll} event.
     */
    function setLockApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account lock approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getLockApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to lock all of the assets of `owner`.
     *
     * See {setLockApprovalForAll}
     */
    function isLockApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    /**
     * @dev Returns if the `tokenId` token is locked.
     */
    function isLocked(uint256 tokenId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Content compatible factory with ui supplied token id
/// @dev Interface for the AmberfiContent - Amberfi Minimal Encrypted & custom Content standard
interface IERC721FullAmberfiContentFactory {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId_`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId_) external view returns (bool);

    /// @dev Sets content URI
    /// @param to_ (address)
    /// @param tokenId_ (uint256)
    /// @param royaltyRecipient_ (address)
    /// @param royaltyValue_ (uint96)
    /// @param tokenUri_ (string memory)
    /// @param isEncrypted_ (bool)
    /// @param contentUri_ (string calldata)
    /// @param encryptKey_ (string calldata)
    /// @param storageLocationId_ (uin8)
    function mint(
        address to_,
        uint256 tokenId_,
        address royaltyRecipient_,
        uint96 royaltyValue_,
        string memory tokenUri_,
        bool isEncrypted_,
        string calldata contentUri_,
        string calldata encryptKey_,
        uint8 storageLocationId_
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Amberfi secondary content interface - both encrypted and not, paired with I{specref}{mint style}Factory interfaces
/// @dev Interface for the AmberfiContent - Amberfi Minimal Encrypted & custom Content standard
interface IAmberfiStorageContent {
    struct Content {
        uint256 tokenId;
        address owner;
        uint8 storageLocationId;
        string content;
        string hashVerify;
        bool isEncrypted;
    }

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId_`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId_) external view returns (bool);
}

/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IAmberfiKeyStorageUpgradeable
/// @dev Interface for the Key Storage. Store and retrieve Encrypted Key
interface IAmberfiKeyStorageUpgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId_`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId_)
        external
        view
        returns (bool);

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param tokenId_ - the NFT asset queried for key information
    /// @return encryptKey - the royalty payment amount for value sale price
    function getEncryptKey(uint256 tokenId_)
        external
        view
        returns (string memory encryptKey);

    function setEncryptKey(uint256 tokenId_, string calldata encryptKey_)
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Openzeppelin
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
// Callback
import "../Callback/AmberfiCallbackUpgradeable.sol";

/**
 * This smart contract is proprietary and not to be copied or
 * reproduced without the express permission of the Amberfi
 * Platform.
 */
contract AmberfiStorage is Initializable, OwnableUpgradeable {
    enum Status {
        Pending,
        InProgress,
        Cancelled,
        Failed,
        Finalized
    }

    struct StorageRecord {
        uint256 itemId;
        address owner;
        Status status;
        string tempCid; // Identifying info for content (e.g. CID, "DNA", etc)
        string cidType; // Is this a metadata JSON type or DATA
        string cid; // This will be the final CID of optional content post minting.
        string cidProof; // This will be the block it was minted at
        uint8 storageLocationId; // This will be the final location of  content (arweave, nfts for nft.storage, infura)
    }

    uint8[] private _storageLocationIds;

    mapping(address => mapping(uint256 => mapping(string => StorageRecord)))
        public record;

    event Encrypt(
        address indexed from,
        uint256 indexed itemId,
        uint8 status,
        string tempCid,
        string encryptCid,
        uint256 locationId
    );

    event Store(
        address indexed from,
        uint256 indexed itemId,
        uint8 status,
        string tempCid,
        uint256 locationId
    );

    function initialize() public initializer {
        __Ownable_init();
    }

    function getStorageRecord(
        address account_,
        uint256 itemId_,
        string calldata tempCid_,
        Status status_
    ) public onlyOwner returns (Status) {
        // You can get values from a nested mapping
        // even when it is not initialized
        record[account_][itemId_][tempCid_].status = status_;
        return record[account_][itemId_][tempCid_].status;
    }

    function removeStorageRecord(uint256 itemId_, string calldata tempCid_)
        public
        onlyOwner
    {
        delete record[_msgSender()][itemId_][tempCid_];
    }

    function removeStorageRecord(
        address account_,
        uint256 itemId_,
        string calldata tempCid_
    ) public onlyOwner {
        delete record[account_][itemId_][tempCid_];
    }

    function registerStorage(
        uint256 itemId_,
        string calldata tempCid_,
        uint8 storageLocationId_
    ) public {
        bytes memory strBytes = bytes(tempCid_);
        require(
            strBytes.length > 0,
            "AmberfiStorage: temporary CID is invalid "
        );
        StorageRecord storage srecord = record[_msgSender()][itemId_][tempCid_];
        require(
            keccak256(bytes(tempCid_)) != keccak256(bytes(srecord.tempCid)),
            "AmberfiStorage: Collision of tempCid - already used.  Delete first."
        );
        srecord.status = Status.Pending;
        srecord.tempCid = tempCid_; // Identifying info for content (e.g. CID, "DNA", etc)
        srecord.storageLocationId = storageLocationId_;
        emit Store(
            _msgSender(),
            itemId_,
            uint8(Status.Pending),
            tempCid_,
            storageLocationId_
        );
    }

    function registerEncryptedStorage(
        uint256 itemId_,
        string calldata tempCid_,
        string calldata encryptCid_,
        uint8 storageLocationId_
    ) public {
        bytes memory strBytes = bytes(tempCid_);
        require(
            strBytes.length > 0,
            "AmberfiStorage: temporary CID is invalid "
        );
        StorageRecord storage srecord = record[_msgSender()][itemId_][tempCid_];
        //require( keccak256(bytes(tempCid_)) == keccak256(bytes(srecord.tempCid)), "AmberfiStorage: Collision of tempCid - already used.  Delete first.");
        srecord.status = Status.Pending;
        srecord.tempCid = tempCid_; // Identifying info for content (e.g. CID, "DNA", etc)
        srecord.storageLocationId = storageLocationId_;
        emit Encrypt(
            _msgSender(),
            itemId_,
            uint8(Status.Pending),
            tempCid_,
            encryptCid_,
            storageLocationId_
        );
    }

    function setImageStorage(
        address account_,
        uint256 itemId_,
        string calldata tempCid_,
        string calldata cid_,
        string calldata cidProof_,
        uint8 status_
    ) public onlyOwner {
        require(
            status_ > 0,
            "AmberfiStorage: Only pending transactions can be updated with final storage."
        );
        bytes memory strBytes = bytes(tempCid_);
        require(
            strBytes.length > 0,
            "AmberfiStorage: temporary CID is invalid "
        );
        StorageRecord storage srecord = record[_msgSender()][itemId_][tempCid_];
        srecord.cid = cid_;
        srecord.cidProof = cidProof_;
        AmberfiCallbackUpgradeable.Status status = AmberfiCallbackUpgradeable
            .Status
            .Pending;
        if (AmberfiCallbackUpgradeable.Status.Cancelled == status) {
            status = AmberfiCallbackUpgradeable.Status.Cancelled;
            srecord.status = Status.Cancelled;
        }
        if (AmberfiCallbackUpgradeable.Status.InProgress == status) {
            status = AmberfiCallbackUpgradeable.Status.InProgress;
            srecord.status = Status.InProgress;
        }
        if (AmberfiCallbackUpgradeable.Status.Failed == status) {
            status = AmberfiCallbackUpgradeable.Status.Failed;
            srecord.status = Status.Failed;
        }
        if (AmberfiCallbackUpgradeable.Status.Finalized == status) {
            status = AmberfiCallbackUpgradeable.Status.Finalized;
            srecord.status = Status.Finalized;
        }
        AmberfiCallbackUpgradeable a = AmberfiCallbackUpgradeable(account_);
        a.setContent(
            itemId_,
            srecord.tempCid,
            srecord.cid,
            srecord.cidProof,
            status
        );
    }

    function setStorageRecord(
        address account_,
        uint256 _itemId_,
        string calldata _tempCid_,
        StorageRecord calldata storageRecord_
    ) public onlyOwner {
        record[account_][_itemId_][_tempCid_] = storageRecord_;
    }

    function setStorageStatus(
        address account_,
        uint256 itemId_,
        string calldata _tempCid_,
        Status status_
    ) public {
        record[account_][itemId_][_tempCid_].status = status_;
    }

    function getNewImageLocation(
        address account_,
        uint256 itemId_,
        string calldata tempCid_
    ) public view returns (string memory) {
        // You can get values from a nested mapping
        // even when it is not initialized
        return record[account_][itemId_][tempCid_].cid;
    }

    function getStorageRecord(uint256 itemId_, string calldata tempCid_)
        public
        view
        returns (StorageRecord memory)
    {
        // You can get values from a nested mapping
        // even when it is not initialized
        return record[_msgSender()][itemId_][tempCid_];
    }

    function getStorageStatus(uint256 itemId_, string calldata tempCid_)
        public
        view
        returns (AmberfiCallbackUpgradeable.Status)
    {
        return getStorageStatusforContract(_msgSender(), itemId_, tempCid_);
    }

    function getStorageStatusforContract(
        address account_,
        uint256 itemId_,
        string calldata tempCid_
    ) public view returns (AmberfiCallbackUpgradeable.Status) {
        // You can get values from a nested mapping
        // even when it is not initialized
        Status status = record[account_][itemId_][tempCid_].status;
        if (Status.Pending == status) {
            return AmberfiCallbackUpgradeable.Status.Pending;
        }
        if (Status.InProgress == status) {
            return AmberfiCallbackUpgradeable.Status.InProgress;
        }
        if (Status.Cancelled == status) {
            return AmberfiCallbackUpgradeable.Status.Cancelled;
        }
        if (Status.Failed == status) {
            return AmberfiCallbackUpgradeable.Status.Failed;
        }
        return AmberfiCallbackUpgradeable.Status.Finalized;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Openzeppelin
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
// Interfaces
import "../interfaces/IAmberfiKeyStorageUpgradeable.sol";

/**
 * @dev Amberfi Key Storage for content
 */
abstract contract AmberfiKeyStorageUpgradeable is
    Initializable,
    ERC165Upgradeable,
    IAmberfiKeyStorageUpgradeable
{
    // Optional mapping for token URIs
    mapping(uint256 => string) private _encryptKeys;

    uint256[49] private __gap;

    function __AmberfiKeyStorage_init() internal onlyInitializing {
        __AmberfiKeyStorage_init_unchained();
    }

    function __AmberfiKeyStorage_init_unchained() internal onlyInitializing {
    }

    /**
     * @dev Sets the encrypt key for the tokenid & content
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function setEncryptKey(uint256 tokenId_, string calldata encryptKey_)
        public
        override
    {
        _encryptKeys[tokenId_] = encryptKey_;
    }

    /**
     * @dev this should be called when token is burned if this class
     * is implemented by NFT.
     */
    function _delete(uint256 tokenId_) internal virtual {
        if (bytes(_encryptKeys[tokenId_]).length > 0) {
            _encryptKeys[tokenId_] = "";
        }
    }

    /**
     * @dev Get the token key required to access content
     */
    function getEncryptKey(uint256 tokenId_)
        public
        view
        virtual
        override
        returns (string memory)
    {
        string memory _tokenKey = _encryptKeys[tokenId_];
        return _tokenKey;
    }

    /// @inheritdoc	ERC165Upgradeable
    function supportsInterface(bytes4 interfaceId_)
        public
        view
        virtual
        override(ERC165Upgradeable, IAmberfiKeyStorageUpgradeable)
        returns (bool)
    {
        return
            interfaceId_ == type(IAmberfiKeyStorageUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Openzeppelin
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
// Interfaces
import "../interfaces/IAmberfiStorageContent.sol";

/**
 * This smart contract is proprietary and not to be copied or
 * reproduced without the express permission of the Amberfi
 * Platform.
 */
contract ERC721TokenURIAmberfiStorageContentUpgradeable is
    Initializable,
    OwnableUpgradeable,
    ERC165Upgradeable,
    IAmberfiStorageContent
{
    mapping(uint256 => Content) internal _contents;

    uint256[49] private __gap;

    function __AmberfiContent_init() internal onlyInitializing {
        __AmberfiContent_init_unchained();
    }

    function __AmberfiContent_init_unchained() internal onlyInitializing {
        __Ownable_init();
    }

    /**
     * @dev Sets encrypted URI
     * @param tokenId_ (uint256) the token id fir which we register the royalties
     * @param storageLocationId_ (uin8) Storage location ID
     * @param isEncrypted_ (bool)
     * @param hashVerify_ (string calldata)
     * @param content_ (string calldata)
     */
    function setContent(
        uint256 tokenId_,
        uint8 storageLocationId_,
        bool isEncrypted_,
        string calldata hashVerify_,
        string calldata content_
    ) external virtual {
        Content memory contentObj = _contents[tokenId_];
        require(
            contentObj.owner == address(0x0) ||
                contentObj.owner == _msgSender(),
            "AmberfiEncryption: Too high"
        );
        bytes memory contentBytes = bytes(content_);
        bytes memory storedBytes = bytes(contentObj.content);
        require(
            (contentBytes.length > 0 && storedBytes.length == 0) ||
                (storedBytes.length > 0 && contentBytes.length == 0) ||
                (storedBytes.length > 0 && contentBytes.length == 0),
            "AmberfiEncryption: Content storage can't be overwritten "
        );
        contentObj.isEncrypted = isEncrypted_;
        contentObj.storageLocationId = storageLocationId_;
        contentObj.content = content_;
        bytes memory hashVerifyBytes = bytes(contentObj.hashVerify);
        bytes memory newHashVerifyBytes = bytes(hashVerify_);
        if (
            isEncrypted_ &&
            contentObj.tokenId > 0x0 &&
            newHashVerifyBytes.length > 0
        ) {
            require(
                hashVerifyBytes.length == 0,
                "AmberfiEncryption: Can't change hash value of minted token"
            );
        }
        if (contentObj.owner == address(0x0)) {
            contentObj.owner = _msgSender();
        }
        _contents[tokenId_] = contentObj;
    }

    /**
     * @dev Transfer encrypted content
     * @param tokenId_ the token id fir which we register the royalties
     * @param content_ the content
     * @param newOwner_ new encrypted content owner
     */
    function transferEncryptedContent(
        uint256 tokenId_,
        string calldata content_,
        address newOwner_
    ) public virtual onlyOwner {
        Content memory encrypted = _contents[tokenId_];
        require(encrypted.owner == _msgSender(), "AmberfiContent: Too high");
        _contents[tokenId_].content = content_;
        _contents[tokenId_].owner = newOwner_;
    }

    /**
     * @inheritdoc ERC165Upgradeable
     */
    function supportsInterface(bytes4 interfaceId_)
        public
        view
        virtual
        override(ERC165Upgradeable, IAmberfiStorageContent)
        returns (bool)
    {
        return
            interfaceId_ ==
            type(IAmberfiStorageContent).interfaceId ||
            super.supportsInterface(interfaceId_);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Openzeppelin
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
// Interfaces
import "../interfaces/IERC721LockableUpgradeable.sol";

/**
 * @dev Implementation ERC721Upgradeable Lockable Token
 */
abstract contract ERC721LockableUpgradeable is
    ERC721Upgradeable,
    IERC721LockableUpgradeable
{
    // Mapping from token ID to unlock time
    mapping(uint256 => uint256) public lockedTokens;

    // Mapping from token ID to lock approved address
    mapping(uint256 => address) private _lockApprovals;

    // Mapping from owner to lock operator approvals
    mapping(address => mapping(address => bool)) private _lockOperatorApprovals;

    /**
     * @dev See {IERC721Lockable-lockApprove}.
     */
    function lockApprove(address to, uint256 tokenId) public virtual override {
        require(!isLocked(tokenId), "ERC721L: token is locked");
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721L: lock approval to current owner");

        require(
            _msgSender() == owner || isLockApprovedForAll(owner, _msgSender()),
            "ERC721L: lock approve caller is not owner nor approved for all"
        );

        _lockApprove(owner, to, tokenId);
    }

    /**
     * @dev See {IERC721Lockable-getLockApproved}.
     */
    function getLockApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721L: lock approved query for nonexistent token"
        );

        return _lockApprovals[tokenId];
    }

    /**
     * @dev See {IERC721Lockable-lockerOf}.
     */
    function lockerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721L: locker query for nonexistent token"
        );
        require(
            isLocked(tokenId),
            "ERC721L: locker query for non-locked token"
        );

        return _lockApprovals[tokenId];
    }

    /**
     * @dev See {IERC721Lockable-setLockApprovalForAll}.
     */
    function setLockApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        _setLockApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721Lockable-isLockApprovedForAll}.
     */
    function isLockApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _lockOperatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721Lockable-isLocked}.
     */
    function isLocked(uint256 tokenId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return lockedTokens[tokenId] > block.timestamp;
    }

    /**
     * @dev See {IERC721Lockable-lockFrom}.
     */
    function lockFrom(
        address from,
        uint256 tokenId,
        uint256 expired
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(
            _isLockApprovedOrOwner(_msgSender(), tokenId),
            "ERC721L: lock caller is not owner nor approved"
        );
        require(
            expired > block.timestamp,
            "ERC721L: expired time must be greater than current block number"
        );
        require(!isLocked(tokenId), "ERC721L: token is locked");

        _lock(_msgSender(), from, tokenId, expired);
    }

    /**
     * @dev See {IERC721Lockable-unlockFrom}.
     */
    function unlockFrom(address from, uint256 tokenId) public virtual override {
        require(
            lockerOf(tokenId) == _msgSender(),
            "ERC721L: unlock caller is not lock operator"
        );
        require(
            ERC721Upgradeable.ownerOf(tokenId) == from,
            "ERC721L: unlock from incorrect owner"
        );

        _beforeTokenLock(_msgSender(), from, tokenId, 0);

        delete lockedTokens[tokenId];

        emit Unlocked(_msgSender(), from, tokenId);

        _afterTokenLock(_msgSender(), from, tokenId, 0);
    }

    /**
     * @dev Locks `tokenId` from `from`  until `expired`.
     *
     * Requirements:
     *
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Locked} event.
     */
    function _lock(
        address operator,
        address from,
        uint256 tokenId,
        uint256 expired
    ) internal virtual {
        require(
            ERC721Upgradeable.ownerOf(tokenId) == from,
            "ERC721L: lock from incorrect owner"
        );

        _beforeTokenLock(operator, from, tokenId, expired);

        lockedTokens[tokenId] = expired;
        _lockApprovals[tokenId] = _msgSender();

        emit Locked(operator, from, tokenId, expired);

        _afterTokenLock(operator, from, tokenId, expired);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`, but the `tokenId` is locked and cannot be transferred.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     *
     * Emits {Locked} and {Transfer} event.
     * 
     * Should use with nonReentrant modifier
     */
    function _safeLockMint(
        address to,
        uint256 tokenId,
        uint256 expired,
        bytes memory _data
    ) internal virtual {
        require(
            expired > block.timestamp,
            "ERC721L: lock mint for invalid lock block number"
        );

        _safeMint(to, tokenId, _data);

        _lock(address(0), to, tokenId, expired);
    }

    /**
     * @dev See {ERC721Upgradeable-_burn}. This override additionally clears the lock approvals for the token.
     */
    function _burn(uint256 tokenId) internal virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        super._burn(tokenId);

        _beforeTokenLock(_msgSender(), owner, tokenId, 0);

        // clear lock approvals
        delete lockedTokens[tokenId];
        delete _lockApprovals[tokenId];

        _afterTokenLock(_msgSender(), owner, tokenId, 0);
    }

    /**
     * @dev Approve `to` to lock operate on `tokenId`
     *
     * Emits a {LockApproval} event.
     */
    function _lockApprove(
        address owner,
        address to,
        uint256 tokenId
    ) internal virtual {
        _lockApprovals[tokenId] = to;
        emit LockApproval(owner, to, tokenId);
    }

    /**
     * @dev Approve `operator` to lock operate on all of `owner` tokens
     *
     * Emits a {LockApprovalForAll} event.
     */
    function _setLockApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721L: lock approve to caller");
        _lockOperatorApprovals[owner][operator] = approved;
        emit LockApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Returns whether `spender` is allowed to lock `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isLockApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721L: lock operator query for nonexistent token"
        );
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner ||
            isLockApprovedForAll(owner, spender) ||
            getLockApproved(tokenId) == spender);
    }

    /**
     * @dev See {ERC721Upgradeable-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the `tokenId` must not be locked.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);

        unchecked {
            for (uint256 i = firstTokenId; i < batchSize; ++i) {
                require(!isLocked(i), "ERC721L: token transfer while locked");
            }
        }
    }

    /**
     * @dev Hook that is called before any token lock/unlock.
     *
     * Calling conditions:
     *
     * - `from` is non-zero.
     * - When `expired` is zero, `tokenId` will be unlock for `from`.
     * - When `expired` is non-zero, ``from``'s `tokenId` will be locked.
     *
     */
    function _beforeTokenLock(
        address operator,
        address from,
        uint256 tokenId,
        uint256 expired
    ) internal virtual {}

    /**
     * @dev Hook that is called after any lock/unlock of tokens.
     *
     * Calling conditions:
     *
     * - `from` is non-zero.
     * - When `expired` is zero, `tokenId` will be unlock for `from`.
     * - When `expired` is non-zero, ``from``'s `tokenId` will be locked.
     *
     */
    function _afterTokenLock(
        address operator,
        address from,
        uint256 tokenId,
        uint256 expired
    ) internal virtual {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165Upgradeable, ERC721Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC721LockableUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Openzeppelin
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";

/**
 * This smart contract is proprietary and not to be copied or
 * reproduced without the express permission of the Amberfi
 * Platform.
 */
abstract contract AmberfiCallbackUpgradeable is
    Initializable,
    ERC165Upgradeable
{
    uint256[49] private __gap;

    enum Status {
        Pending,
        InProgress,
        Cancelled,
        Failed,
        Finalized
    }

    function __AmberfiCallback_init() internal onlyInitializing {
        __AmberfiCallback_init_unchained();
    }

    function __AmberfiCallback_init_unchained() internal onlyInitializing {
    }

    function encryptContent(
        uint256 itemId_,
        string calldata encryptCid_,
        uint8 storageLocationId_
    ) public virtual {}

    function setContent(
        uint256 itemId_,
        string calldata tempCid_,
        string calldata cid_,
        string calldata cidProof_,
        Status status_
    ) public virtual {}

    /**
     * @inheritdoc ERC165Upgradeable
     */
    function supportsInterface(bytes4 interfaceId_)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId_ == type(AmberfiCallbackUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId_);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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
library CountersUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "../../interfaces/IERC2981Upgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981Upgradeable is Initializable, IERC2981Upgradeable, ERC165Upgradeable {
    function __ERC2981_init() internal onlyInitializing {
    }

    function __ERC2981_init_unchained() internal onlyInitializing {
    }
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC2981Upgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981Upgradeable
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorageUpgradeable is Initializable, ERC721Upgradeable {
    function __ERC721URIStorage_init() internal onlyInitializing {
    }

    function __ERC721URIStorage_init_unchained() internal onlyInitializing {
    }
    using StringsUpgradeable for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/extensions/ERC721Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "../../../utils/ContextUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be burned (destroyed).
 */
abstract contract ERC721BurnableUpgradeable is Initializable, ContextUpgradeable, ERC721Upgradeable {
    function __ERC721Burnable_init() internal onlyInitializing {
    }

    function __ERC721Burnable_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _burn(tokenId);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721Upgradeable.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
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
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256, /* firstTokenId */
        uint256 batchSize
    ) internal virtual {
        if (batchSize > 1) {
            if (from != address(0)) {
                _balances[from] -= batchSize;
            }
            if (to != address(0)) {
                _balances[to] += batchSize;
            }
        }
    }

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981Upgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}