/**
 *Submitted for verification at polygonscan.com on 2022-05-25
*/

// File: contracts/interfaces/IPlayerselfRegistry.sol


pragma solidity ^0.8.1;

interface IPlayerselfRegistry {

    struct NFT {
        bool enabled;
        bool supportsBatch;
    }

    function isSupported(address addr) external view returns(bool);
    function getNFT(address addr) external view returns (NFT memory);

}
// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;


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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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

// File: contracts/PlayerselfAuction.sol


pragma solidity ^0.8.1;







/**
 * @title Playerself auctions/sales contract
 * @author Playerself srl developers
 * @notice This contract allows wallets to open, manage and partecipate in auctions and sales
 */
contract PlayerselfAuction is IERC721Receiver, IERC1155Receiver {
    
    address private _owner;
    mapping(bytes32 => Auction) public nftAuctions;
    mapping(address => uint256) public failedTransferCredits;
    mapping(address => address) public _splitFeeRecipients;
    
    struct Auction {
        uint256 bidIncreasePercentage;
        uint32 auctionBidPeriod;
        uint64 auctionEnd;
        uint256 minPrice;
        uint256 buyNowPrice;
        uint256 nftHighestBid;
        address nftHighestBidder;
        address nftSeller;
        address whitelistedBuyer;
        address nftAddress;
        uint256[] tokenIds;
        address[] feeRecipients;
        uint256[] feePercentages;
    }
    
    /** Public attributes **/
    uint256 public defaultBidIncreasePercentage;
    uint256 public minimumSettableIncreasePercentage;
    uint32 public defaultAuctionBidPeriod;
    IPlayerselfRegistry public registry;
    
    address private _defaultFeeRecipient;
    uint256 private _defaultFee;
    
    /**
     * @notice Creates a new instance of the PlayerselfAuction contract
     * @param _registry PlayerselfRegistry contract address
     * @param defaultFeeRecipient default base fee recipient
     * @param defaultFee default base fee (eg. 1% = 1e16)
     */
    constructor(address _registry, address defaultFeeRecipient, uint256 defaultFee) {
        require(_registry != address(0), "NFT address cannot be address(0).");
        defaultBidIncreasePercentage = 1e16;
        defaultAuctionBidPeriod = 86400; // 1 day
        minimumSettableIncreasePercentage = 1e16;
        registry = IPlayerselfRegistry(_registry);
        _defaultFeeRecipient = defaultFeeRecipient;
        _defaultFee = defaultFee;
        _owner = msg.sender;
    }
    
    /** Events **/
    event NftAuctionCreated(address indexed nftSeller, address indexed contractAddress, bytes32 auctionHash);
    event NftAuctionPeriodUpdated(bytes32 indexed hash, uint64 auctionEnd);
    event NftAuctionWithdrawn(bytes32 indexed hash, address indexed nftSeller);
    event NftAuctionSettled(bytes32 indexed hash, address indexed nftSeller);
    event NftSaleCreated(address indexed nftSeller, address indexed contractAddress, bytes32 saleHash);
    event NftSold(bytes32 indexed hash, address indexed nftBuyer, uint256[] tokenIds, uint256 amount, address contractAddress);
    event BidMade(bytes32 indexed hash, address indexed bidder, uint256 amount);
    event WhitelistedBuyerUpdated(bytes32 indexed hash, address newWhitelistedBuyer);
    event MinimumPriceUpdated(bytes32 indexed hash, uint256 newMinPrice);
    event BuyNowPriceUpdated(bytes32 indexed hash, uint256 newBuyNowPrice);
    event HighestBidTaken(bytes32 indexed hash);
    
    /** Modifiers **/
    modifier acceptanceCheck(address _nftAddress, uint256[] memory _tokenIds) {
        require(_nftAddress != address(0), "Invalid NFT address.");
        require(registry.isSupported(_nftAddress), "Token not supported.");
        require(_tokenIds.length > 0, "No tokens provided.");
        bytes32 auctionHash = keccak256(abi.encodePacked(msg.sender, _tokenIds, block.timestamp));
        require(
            nftAuctions[auctionHash].nftSeller == address(0),
            "Auction already exists."
        );
        IPlayerselfRegistry.NFT memory _nft = registry.getNFT(_nftAddress);
        if (_nft.supportsBatch) {
            address[] memory addresses = new address[](_tokenIds.length);
            for (uint256 i = 0; i < _tokenIds.length; i++) {
                addresses[i] = msg.sender;
            }
            uint256[] memory balances = IERC1155(_nftAddress).balanceOfBatch(addresses, _tokenIds);
            for (uint256 i = 0; i < balances.length; i++) {
                require(balances[i] > 0, "Sender does not own the NFT.");
            }
            IERC1155(_nftAddress).safeBatchTransferFrom(msg.sender, address(this), _tokenIds, balances, "");
        } else {
            for (uint256 i = 0; i < _tokenIds.length; i++) {
                address owner = IERC721(_nftAddress).ownerOf(_tokenIds[i]);
                require(owner == msg.sender, "Sender does not own the NFT.");
                IERC721(_nftAddress).safeTransferFrom(msg.sender, address(this), _tokenIds[i]);
            }
        }
        _;
    }

    modifier auctionExists(bytes32 hash) {
        require(nftAuctions[hash].nftSeller != address(0) && nftAuctions[hash].tokenIds.length > 0, "Auction does not exist.");
        _;
    }

    modifier auctionNotExists(bytes32 hash) {
        require(nftAuctions[hash].nftSeller == address(0), "Auction already exists.");
        _;
    }

    modifier sellerOnly(bytes32 hash) {
        require(nftAuctions[hash].nftSeller == msg.sender, "Unauthorized.");
        _;
    }
    
    /** Getter **/
    function getTokensAndFees(bytes32 hash) public view returns (uint256[] memory, address[] memory, uint256[] memory) {
        return (nftAuctions[hash].tokenIds, nftAuctions[hash].feeRecipients, nftAuctions[hash].feePercentages);
    }

    /** Setter */
    function setFeeRecipient(address nftAddress, address feeRecipient) external {
        require(msg.sender == _owner, "Unauthorized.");
        require(nftAddress != address(0) && feeRecipient != address(0), "Invalid address.");
        _splitFeeRecipients[nftAddress] = feeRecipient;
    }

    receive () external payable {}
    
    /** Auctions **/

    /**
     * @notice Internal function used to setup an auction
     * @dev Makes the basics checks for an auction and then sets the auction in the private mapping above
     * @param auctionHash hash of the auction
     * @param _nftAddress address of the NFT contract (must be registered on the PlayerselfRegistry contract)
     * @param _tokenIds array of token ids from the NFT contract that are being sold
     * @param _minPrice minimum price for the auction (must be greater than 0)
     * @param _buyNowPrice instant buy now price for the auction (must be 0 or greater than the _minPrice)
     * @param _auctionDuration duration of the auction (in seconds)
     * @param _auctionBidPeriod period between bids (in seconds) - if the current duration is lower than this value, the auction duration is set to its auction bid period
     * @param _bidIncreasePercentage increase percentage between bids
     * @param _feeRecipients array with the fee recipients (index matching the fee percentages below)
     * @param _feePercentages array with the fee percentages (index matching the fee recipients above)
     */
    function _setupAuction(
        bytes32 auctionHash,
        address _nftAddress,
        uint256[] memory _tokenIds,
        uint256 _minPrice,
        uint256 _buyNowPrice,
        uint64 _auctionDuration,
        uint32 _auctionBidPeriod,
        uint256 _bidIncreasePercentage,
        address[] memory _feeRecipients,
        uint256[] memory _feePercentages
    ) internal auctionNotExists(auctionHash) {
        // Perform checks on the given data
        require(_minPrice > 0, "Min price must be greater than 0.");
        require(_buyNowPrice == 0 || _buyNowPrice >= _minPrice, "Invalid buy now price.");
        require(_feeRecipients.length == _feePercentages.length, "Invalid fees.");
        require(_bidIncreasePercentage == 0 || _bidIncreasePercentage >= minimumSettableIncreasePercentage, "Bid increase percentage too low.");
        require(_auctionDuration >= defaultAuctionBidPeriod, "Invalid auction bid period.");

        (uint256[] memory percentages, address[] memory recipients) = _getRecipientsAndFees(_nftAddress, _feePercentages, _feeRecipients);
        
        // Create the auction
        nftAuctions[auctionHash].nftAddress = _nftAddress;
        nftAuctions[auctionHash].tokenIds = _tokenIds;
        nftAuctions[auctionHash].auctionBidPeriod = _auctionBidPeriod != 0 ? _auctionBidPeriod : defaultAuctionBidPeriod;
        nftAuctions[auctionHash].bidIncreasePercentage = _bidIncreasePercentage != 0 ? _bidIncreasePercentage : defaultBidIncreasePercentage;
        nftAuctions[auctionHash].feeRecipients = recipients;
        nftAuctions[auctionHash].feePercentages = percentages;
        nftAuctions[auctionHash].buyNowPrice = _buyNowPrice;
        nftAuctions[auctionHash].auctionEnd = uint64(block.timestamp) + _auctionDuration;
        nftAuctions[auctionHash].minPrice = _minPrice;
        nftAuctions[auctionHash].nftSeller = msg.sender;
        // Emit the event
        emit NftAuctionCreated(msg.sender, _nftAddress, auctionHash);
    }
    
    /**
     * @notice External function used to setup an auction
     * @dev Calls the internal function above to setup an auction
     * @param _nftAddress address of the NFT contract (must be registered on the PlayerselfRegistry contract)
     * @param _tokenIds array of token ids from the NFT contract that are being sold
     * @param _minPrice minimum price for the auction (must be greater than 0)
     * @param _buyNowPrice instant buy now price for the auction (must be 0 or greater than the _minPrice)
     * @param _auctionDuration duration of the auction (in seconds)
     * @param _auctionBidPeriod period between bids (in seconds) - if the current duration is lower than this value, the auction duration is set to its auction bid period
     * @param _bidIncreasePercentage increase percentage between bids
     * @param _feeRecipients array with the fee recipients (index matching the fee percentages below)
     * @param _feePercentages array with the fee percentages (index matching the fee recipients above)
     */
    function createNftAuction(    
        address _nftAddress,   
        uint256[] memory _tokenIds,
        uint256 _minPrice,
        uint256 _buyNowPrice,
        uint64 _auctionDuration,
        uint32 _auctionBidPeriod,
        uint256 _bidIncreasePercentage,
        address[] memory _feeRecipients,
        uint256[] memory _feePercentages
    ) external acceptanceCheck(_nftAddress, _tokenIds) {
        bytes32 auctionHash = keccak256(abi.encodePacked(msg.sender, _nftAddress, _tokenIds, block.timestamp));
        _setupAuction(auctionHash, _nftAddress, _tokenIds, _minPrice, _buyNowPrice, _auctionDuration, _auctionBidPeriod, _bidIncreasePercentage, _feeRecipients, _feePercentages);
    }
    
    /**
     * @notice Internal function that updates the ongoing auction
     * @dev Transfers the NFT and pays the seller if the buy now price is met, otherwise updates the auction end
     * @param hash auction hash
     */
    function _updateOngoingAuction(bytes32 hash) internal {
        uint256 buyNowPrice = nftAuctions[hash].buyNowPrice;
        bool buyNowPriceMet = buyNowPrice > 0 && nftAuctions[hash].nftHighestBid >= buyNowPrice;
        if (buyNowPriceMet) {
            _transferNftAndPaySeller(hash);
            return;
        }
        
        uint256 minPrice = nftAuctions[hash].minPrice;
        bool minBidMade = minPrice > 0 && (nftAuctions[hash].nftHighestBid >= minPrice);
        if (minBidMade) {
            _updateAuctionEnd(hash);
        }
    }

    function _updateAuctionEnd(bytes32 hash) internal {
        uint32 auctionBidPeriod = _getAuctionBidPeriod(hash);
        if (nftAuctions[hash].auctionEnd - uint64(block.timestamp) <= auctionBidPeriod) {
            nftAuctions[hash].auctionEnd = uint64(block.timestamp) + auctionBidPeriod;
        }
        emit NftAuctionPeriodUpdated(hash, nftAuctions[hash].auctionEnd);
    }
    
    
    /** Sales **/
    function _setupSale(
        bytes32 saleHash,
        address _nftAddress,
        uint256[] memory _tokenIds,
        uint256 _buyNowPrice,
        address _whitelistedBuyer,
        address[] memory _feeRecipients,
        uint256[] memory _feePercentages
    ) internal auctionNotExists(saleHash) {
        require(_buyNowPrice > 0, "Buy now price must be greater than 0.");
        require(_feeRecipients.length == _feePercentages.length, "Invalid fees.");
        require(msg.sender != _whitelistedBuyer, "Whitelisted buyer matches the seller.");

        (uint256[] memory percentages, address[] memory recipients) = _getRecipientsAndFees(_nftAddress, _feePercentages, _feeRecipients);

        nftAuctions[saleHash].nftAddress = _nftAddress;
        nftAuctions[saleHash].tokenIds = _tokenIds;
        nftAuctions[saleHash].feeRecipients = recipients;
        nftAuctions[saleHash].feePercentages = percentages;
        nftAuctions[saleHash].buyNowPrice = _buyNowPrice;
        nftAuctions[saleHash].nftSeller = msg.sender;
        nftAuctions[saleHash].whitelistedBuyer = _whitelistedBuyer;
        
        emit NftSaleCreated(msg.sender, _nftAddress, saleHash);
    }
    
    function createSale(
        address _nftAddress,
        uint256[] memory _tokenIds,
        uint256 _buyNowPrice,
        address _whitelistedBuyer,
        address[] memory _feeRecipients,
        uint256[] memory _feePercentages
    )
        external
        acceptanceCheck(_nftAddress, _tokenIds)
    {
        bytes32 saleHash = keccak256(abi.encodePacked(msg.sender, _nftAddress, _tokenIds, block.timestamp));
        _setupSale(
            saleHash,
            _nftAddress,
            _tokenIds,
            _buyNowPrice,
            _whitelistedBuyer,
            _feeRecipients,
            _feePercentages
        );
    }
    
    /** Check functions **/
    function _isAuctionOngoing(bytes32 hash) internal view returns (bool) {
        uint64 auctionEndTimestamp = nftAuctions[hash].auctionEnd;
        return (auctionEndTimestamp == 0 || block.timestamp < auctionEndTimestamp);
    }
    
    function _isSale(bytes32 hash) internal view returns (bool) {
        return (nftAuctions[hash].buyNowPrice > 0 && nftAuctions[hash].minPrice == 0);
    }

    function _isWhitelistedSale(bytes32 hash) internal view returns (bool) {
        return (nftAuctions[hash].whitelistedBuyer != address(0));
    }
    
    function _getAuctionBidPeriod(bytes32 hash) internal view returns (uint32) {
        uint32 auctionBidPeriod = nftAuctions[hash].auctionBidPeriod;
        if (auctionBidPeriod == 0) {
            return defaultAuctionBidPeriod;
        } else {
            return auctionBidPeriod;
        }
    }
    
    function _getBidIncreasePercentage(bytes32 hash) internal view returns (uint256) {
        uint256 bidIncreasePercentage = nftAuctions[hash].bidIncreasePercentage;
        if (bidIncreasePercentage == 0) {
            return defaultBidIncreasePercentage;
        } else {
            return bidIncreasePercentage;
        }
    }
    
    function _bidRequirementsCheck(bytes32 hash) internal view returns (bool) {
        uint256 buyNowPrice = nftAuctions[hash].buyNowPrice;
        //if buyNowPrice is met, ignore increase percentage
        if (buyNowPrice > 0 && msg.value >= buyNowPrice) {
            return true;
        }
        //if the NFT is up for auction, the bid needs to be a % higher than the previous bid
        uint256 bidIncreaseAmount = (nftAuctions[hash].nftHighestBid * (1e18 + _getBidIncreasePercentage(hash))) / 1e18;
        return msg.value >= bidIncreaseAmount;
    }
    
    function _getPortionOfBid(uint256 _totalBid, uint256 _percentage) internal pure returns (uint256) {
        return (_totalBid * (_percentage)) / 1e18;
    }
    
    /** Bid functions **/
    function makeBid(bytes32 hash) external payable auctionExists(hash) {
        require(nftAuctions[hash].nftSeller != address(0), "Non-existing auction.");
        require(_isAuctionOngoing(hash), "Auction ended.");
        require(!_isWhitelistedSale(hash) || nftAuctions[hash].whitelistedBuyer == msg.sender, "Only whitelisted buyer.");
        require(nftAuctions[hash].nftSeller != msg.sender, "Bidding own auction?");
        require(msg.value > 0 && (nftAuctions[hash].minPrice == 0 || msg.value >= nftAuctions[hash].minPrice), "Invalid payment.");
        require(_bidRequirementsCheck(hash));
        _reverseAndUpdateBid(hash);
        emit BidMade(hash, msg.sender, msg.value);
        _updateOngoingAuction(hash);
    }
    
    /** Transfer functions **/
    function _transferNftAndPaySeller(bytes32 hash) internal {
        address _nftHighestBidder = nftAuctions[hash].nftHighestBidder;
        uint256 _nftHighestBid = nftAuctions[hash].nftHighestBid;
        _resetBids(hash);
        uint256 feesPaid;
        for (uint256 i = 0; i < nftAuctions[hash].feeRecipients.length; i++) {
            uint256 fee = _getPortionOfBid(_nftHighestBid, nftAuctions[hash].feePercentages[i]);
            feesPaid = feesPaid + fee;
            _payout(nftAuctions[hash].feeRecipients[i], fee);
        }
        emit HighestBidTaken(hash);
        emit NftSold(hash, _nftHighestBidder, nftAuctions[hash].tokenIds, _nftHighestBid, nftAuctions[hash].nftAddress);
        _payout(nftAuctions[hash].nftSeller, (_nftHighestBid - feesPaid));
        
        address[] memory addresses = new address[](nftAuctions[hash].tokenIds.length);
        for (uint256 i = 0; i < nftAuctions[hash].tokenIds.length; i++) {
            addresses[i] = address(this);
        }

        IPlayerselfRegistry.NFT memory _nft = registry.getNFT(nftAuctions[hash].nftAddress);
        if (_nft.supportsBatch) {
            uint256[] memory balances = IERC1155(nftAuctions[hash].nftAddress).balanceOfBatch(addresses, nftAuctions[hash].tokenIds);
            IERC1155(nftAuctions[hash].nftAddress).safeBatchTransferFrom(address(this), _nftHighestBidder, nftAuctions[hash].tokenIds, balances, "");
        } else {
            for (uint256 i = 0; i < nftAuctions[hash].tokenIds.length; i++) {
                IERC721(nftAuctions[hash].nftAddress).safeTransferFrom(address(this), _nftHighestBidder, nftAuctions[hash].tokenIds[i]);
            }
        }
        _resetAuction(hash);
    }
    
    function _updateHighestBid(bytes32 hash) internal {
        nftAuctions[hash].nftHighestBid = uint256(msg.value);
        nftAuctions[hash].nftHighestBidder = msg.sender;
    }
    
    function _payout(address _recipient, uint256 _amount) internal {
        // attempt to send the funds to the recipient
        (bool success, ) = payable(_recipient).call{
            value: _amount,
            gas: 20000
        }("");
        // if it failed, update their credit balance so they can pull it later
        if (!success) {
            failedTransferCredits[_recipient] =  failedTransferCredits[_recipient] +  _amount;
        }
    }
    
    function _reverseAndUpdateBid(bytes32 hash) internal {
        address prevNftHighestBidder = nftAuctions[hash].nftHighestBidder;
        uint256 prevNftHighestBid = nftAuctions[hash].nftHighestBid;
        _updateHighestBid(hash);

        if (prevNftHighestBidder != address(0)) {
            _payout(prevNftHighestBidder, prevNftHighestBid);
        }
    }
    
    /** Settle & Withdraw function **/
    function settleAuction(bytes32 hash) external {
        require(!_isAuctionOngoing(hash), "Auction is still going.");
        _transferNftAndPaySeller(hash);
        emit NftAuctionSettled(hash, nftAuctions[hash].nftSeller);
    }

    function withdrawAuction(bytes32 hash) external sellerOnly(hash) {
        address prevNftHighestBidder = nftAuctions[hash].nftHighestBidder;
        if (prevNftHighestBidder != address(0)) {
            _payout(prevNftHighestBidder, nftAuctions[hash].nftHighestBid);
        }
        
        address[] memory addresses = new address[](nftAuctions[hash].tokenIds.length);
        for (uint256 i = 0; i < nftAuctions[hash].tokenIds.length; i++) {
            addresses[i] = address(this);
        }
        IPlayerselfRegistry.NFT memory _nft = registry.getNFT(nftAuctions[hash].nftAddress);
        if (_nft.supportsBatch) {
            uint256[] memory balances = IERC1155(nftAuctions[hash].nftAddress).balanceOfBatch(addresses, nftAuctions[hash].tokenIds);
            IERC1155(nftAuctions[hash].nftAddress).safeBatchTransferFrom(address(this), nftAuctions[hash].nftSeller, nftAuctions[hash].tokenIds, balances, "");
        } else {
            for (uint256 i = 0; i < nftAuctions[hash].tokenIds.length; i++) {
              IERC721(nftAuctions[hash].nftAddress).safeTransferFrom(address(this), nftAuctions[hash].nftSeller, nftAuctions[hash].tokenIds[i]);
            }
        }
        _resetAuction(hash);
        emit NftAuctionWithdrawn(hash, nftAuctions[hash].nftSeller);
    }
    
    /** Update methods **/
    function updateWhitelistedBuyer(bytes32 hash, address _newWhitelistedBuyer) external sellerOnly(hash) {
        require(_isSale(hash), "Not a sale.");
        
        nftAuctions[hash].whitelistedBuyer = _newWhitelistedBuyer;
        
        //if an underbid is by a non whitelisted buyer,reverse that bid
        address nftHighestBidder = nftAuctions[hash].nftHighestBidder;
        uint256 nftHighestBid = nftAuctions[hash].nftHighestBid;
        
        if (nftHighestBid > 0 && nftHighestBidder != _newWhitelistedBuyer) {
            _resetBids(hash);
            _payout(nftHighestBidder, nftHighestBid);
        }

        emit WhitelistedBuyerUpdated(hash, _newWhitelistedBuyer);
    }

    function updateMinimumPrice(bytes32 hash, uint256 _newMinPrice) external sellerOnly(hash) {        
        uint256 minPrice = nftAuctions[hash].minPrice;
        bool minBidMade = minPrice > 0 && (nftAuctions[hash].nftHighestBid >= minPrice);
        require(!minBidMade, "Minimum bid already made.");
        require(!_isSale(hash), "Not an auction.");
        require(_newMinPrice > 0, "Invalid new min price.");
        
        nftAuctions[hash].minPrice = _newMinPrice;

        emit MinimumPriceUpdated(hash, _newMinPrice);
        
        minBidMade = minPrice > 0 && (nftAuctions[hash].nftHighestBid >= minPrice);

        if (minBidMade) {
            _updateAuctionEnd(hash);
        }
    }

    function updateBuyNowPrice(bytes32 hash, uint256 _newBuyNowPrice) external sellerOnly(hash) {
        require(!_isSale(hash) || _newBuyNowPrice > 0, "Invalid new buy now price.");
        nftAuctions[hash].buyNowPrice = _newBuyNowPrice;
        emit BuyNowPriceUpdated(hash, _newBuyNowPrice);
        
        bool buyNowPriceMet = _newBuyNowPrice > 0 && nftAuctions[hash].nftHighestBid >= _newBuyNowPrice;
        if (buyNowPriceMet) {
            _transferNftAndPaySeller(hash);
        }
    }

    function takeHighestBid(bytes32 hash) external sellerOnly(hash) {
        require(nftAuctions[hash].nftHighestBid > 0, "Cannot payout 0 bid.");
        _transferNftAndPaySeller(hash);
    }


    function withdrawFailedCredits() external {
        uint256 amount = failedTransferCredits[msg.sender];
        require(amount != 0, "No credits.");

        failedTransferCredits[msg.sender] = 0;

        (bool successfulWithdraw, ) = msg.sender.call{
            value: amount,
            gas: 20000
        }("");
        
        require(successfulWithdraw, "Withdraw failed.");
    }
    
    /** Reset **/
    function _resetAuction(bytes32 auctionHash) internal {
        nftAuctions[auctionHash].minPrice = 0;
        nftAuctions[auctionHash].buyNowPrice = 0;
        nftAuctions[auctionHash].auctionEnd = 0;
        nftAuctions[auctionHash].auctionBidPeriod = 0;
        nftAuctions[auctionHash].bidIncreasePercentage = 0;
        nftAuctions[auctionHash].nftAddress = address(0);
        nftAuctions[auctionHash].nftSeller = address(0);
        nftAuctions[auctionHash].whitelistedBuyer = address(0);
        nftAuctions[auctionHash].tokenIds = new uint256[](0);
        nftAuctions[auctionHash].feeRecipients = new address[](0);
        nftAuctions[auctionHash].feePercentages = new uint32[](0);
    }

    function _resetBids(bytes32 auctionHash) internal {
        nftAuctions[auctionHash].nftHighestBidder = address(0);
        nftAuctions[auctionHash].nftHighestBid = 0;
    }

    function _getRecipientsAndFees(address _nftAddress, uint256[] memory _feePercentages, address[] memory _feeRecipients) internal view returns (uint256[] memory, address[] memory) {
        address[] memory recipients = new address[](
            _defaultFee > 0 && _defaultFeeRecipient != address(0) 
            ? _splitFeeRecipients[_nftAddress] != address(0) 
            ? _feeRecipients.length + 2 
            : _feeRecipients.length + 1
            : _feeRecipients.length
        );
        uint256[] memory percentages = new uint256[](
            _defaultFee > 0 && _defaultFeeRecipient != address(0) 
            ? _splitFeeRecipients[_nftAddress] != address(0) 
            ? _feeRecipients.length + 2 
            : _feeRecipients.length + 1
            : _feeRecipients.length
        );
        for (uint i = 0; i < _feeRecipients.length; i++) {
            recipients[i] = _feeRecipients[i];
            percentages[i] = _feePercentages[i];
        }
        if (_defaultFee > 0 && _defaultFeeRecipient != address(0)) {
            recipients[recipients.length - 1] = _defaultFeeRecipient;
            percentages[percentages.length - 1] = _splitFeeRecipients[_nftAddress] != address(0) ? _defaultFee / 2 : _defaultFee;
            if (_splitFeeRecipients[_nftAddress] != address(0)) {
                recipients[recipients.length - 2] = _splitFeeRecipients[_nftAddress];
                percentages[recipients.length - 2] = _defaultFee / 2;
            }
        }

        uint256 totalPercentages = 0;
        for (uint256 k = 0; k < percentages.length; k++) {
            totalPercentages += percentages[k];
        }
        require(totalPercentages < 1e18, "Invalid percentages.");

        return (percentages, recipients);
    }

    /** ERC-721 receiver methods */
    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns(bytes4) {
        return this.onERC721Received.selector;
    }
    
    /** ERC-1155 receiver methods **/
    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure override returns(bytes4) {
        return this.onERC1155Received.selector;
    }
    
    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata) external pure override returns(bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
    
    function supportsInterface(bytes4 interfaceID) external pure override returns (bool) {
        return interfaceID == bytes4(keccak256('supportsInterface(bytes4)')) || interfaceID == this.onERC1155BatchReceived.selector ^ this.onERC1155Received.selector || interfaceID == this.onERC721Received.selector;
    }

}