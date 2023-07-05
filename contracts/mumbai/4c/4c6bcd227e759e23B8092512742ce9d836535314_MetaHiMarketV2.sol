/**
 *Submitted for verification at polygonscan.com on 2023-07-04
*/

// Sources flattened with hardhat v2.12.2 https://hardhat.org

// File @openzeppelin/contracts/utils/introspection/[email protected]

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


// File @openzeppelin/contracts/utils/introspection/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/interfaces/[email protected]

// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/token/common/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;


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
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
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
}


// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/token/ERC1155/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

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


// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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


// File contracts/metahi/MetaHiMarketV2.sol

pragma solidity ^0.8.4;





contract MetaHiMarketV2 is Context, Ownable {
    string public name = "MetaHi Market V2";

    // Percentages within MetaHi are represented in granularity of 0.01%
    // This means that 500 units = 5%
    uint256 public metaHiPercent = 50; // 0.5%
    address payable metaHiWallet;

    uint256 public marketPercent = 150; // 1.5%
    address payable marketWallet;

    // Listing mapping:
    ListingNode[] public listings;
    uint256 public numListings;
    uint256 public lastListingId;
    uint256 public lastValidId; // Tracking separately in case listing gets removed from the back of array

    address public contractUpgradeAddress; // If set, then this contract is dead

    constructor() {
        // sentinel
        listings.push(ListingNode(Listing(0, address(0), payable(0), 0, 0, 0, 0), 0, 0));
    }

    function getListingsPaginated(uint256 cursor, uint256 howMany)
    public
    view
    returns(Listing[] memory values, uint256 length, uint256 newCursor)
    {
        require(cursor == 0 || _isValidNode(cursor));

        uint256 currentIndex = cursor;
        if (currentIndex == 0) {
            // cursor == 0 means the start of the list
            currentIndex = listings[0].next;
        }

        values = new Listing[](howMany);

        uint256 i = 0;
        while (i < howMany && currentIndex != 0) {
            ListingNode storage node = listings[currentIndex];

            values[i] = node.listing;
            currentIndex = node.next;
            i += 1;
        }

        length = i;
        newCursor = currentIndex;

        return (values, length, newCursor);
    }

    /**
     * @dev Find a single listing with the provided id or revert
     */
    function getListing(uint256 listingId) public view returns(Listing memory) {
        return _findListing(listingId);
    }

    /**
     * @dev Get quantity of tokens for sale. The returned number determines whether the listing exists or not
     */
    function getListingQuantity(uint256 listingId) public view returns(uint256 quantity) {
        if (!listingExists(listingId)) return 0;
        return listings[listingId].listing.quantity;
    }

    /**
     * @dev Check whether provided listing id exists
     */
    function listingExists(uint256 listingId) public view returns (bool) {
        if (listingId >= listings.length) return false;
        if (!_isValidNode(listingId)) return false;
        if (listings[listingId].listing.expires > 0 && listings[listingId].listing.expires < block.timestamp) return false;
        return listings[listingId].listing.quantity > 0;
    }

    /**
     * @dev Add a token for sale
     */
    function listForSale(address contractAddress, uint256 tokenId, uint256 quantity, uint256 pricePerToken, uint256 expires)
    public
    returns (uint256 newId)
    {
        require(isNotLocked(), "This contract has been upgraded");

        // Require contractAddress to be a ERC1155 token
//        require(IERC165(contractAddress).supportsInterface(type(IERC1155).interfaceId), "Provided contractAddress does not implement IERC1155 interface");
        IERC1155 tokenContract = IERC1155(contractAddress);

        address payable caller = payable(_msgSender());
        require(tokenContract.isApprovedForAll(caller, address(this)));
        require(tokenContract.balanceOf(caller, tokenId) >= quantity, "You don't have enough tokens for this sale");

        // Create a listing
        Listing memory listing = Listing(0, contractAddress, caller, tokenId, quantity, pricePerToken, expires);

        // Add to listing array
        newId = _insertListingToArray(listing);

        emit ExpiringListingAdded(contractAddress, newId, caller, tokenId, quantity, pricePerToken, expires);
    }

    function batchListForSale(address contractAddress, uint256[] memory tokenId, uint256[] memory quantity, uint256[] memory pricePerToken, uint256[] memory expires)
    public
    {
        require(tokenId.length == quantity.length && quantity.length == pricePerToken.length && pricePerToken.length == expires.length);
        for (uint256 i = 0; i < tokenId.length; ++i) {
            listForSale(contractAddress, tokenId[i], quantity[i], pricePerToken[i], expires[i]);
        }
    }

    function purchaseForSelf(uint256 listingId, uint256 quantity) public payable {
        purchase(listingId, quantity, _msgSender());
    }

    function purchase(uint256 listingId, uint256 quantity, address receiver) public payable {
        require(isNotLocked(), "This contract has been upgraded");

        // Find entry
        require(listingExists(listingId), "Listing does not exist");
        Listing storage listing = listings[listingId].listing;
        require(listing.quantity >= quantity, "Not enough tokens for sale"); // Require enough for sale

        // Require enough funds
        uint256 toPay = listing.pricePerToken * quantity;
        require(msg.value >= toPay, "Insufficient funds");

        uint256 fees = 0;

        if (IERC165(listing.tokenAddress).supportsInterface(type(IERC2981).interfaceId)) {
            address royaltyReceiver;
            uint256 royalties;
            (royaltyReceiver, royalties) = ERC2981(listing.tokenAddress).royaltyInfo(listing.tokenId, toPay);
            payable(royaltyReceiver).transfer(royalties);
            fees += royalties;
        }

        // Transfer MetaHi percent
        uint metahiShare = toPay * metaHiPercent / 10000;
        metaHiWallet.transfer(metahiShare);
        fees += metahiShare;

        // Transfer market percent
        uint marketShare = toPay * marketPercent / 10000;
        marketWallet.transfer(marketShare);
        fees += marketShare;

        // Transfer purchase amount
        listing.originalOwner.transfer(toPay - fees);

        // Return overpay
        payable(receiver).transfer(msg.value - toPay);

        // Transfer tokens
        IERC1155(listing.tokenAddress).safeTransferFrom(listing.originalOwner, receiver, listing.tokenId, quantity, "");

        // Emit success event
        emit ExpiringSaleSuccessful(
            listing.tokenAddress,
            listingId,
            listing.originalOwner,
            listing.tokenId,
            quantity,
            listing.pricePerToken,
            receiver
        );

        if (listing.quantity == quantity) {
            // All tokens purchased
            emit ExpiringListingRemoved(
                listing.tokenAddress,
                listingId,
                listing.originalOwner,
                listing.tokenId,
                quantity,
                listing.pricePerToken
            );

            _removeListingFromArray(listingId);
        } else {
            listing.quantity -= quantity;

            // Some tokens purchased
            emit ExpiringListingChanged(
                listing.tokenAddress,
                listingId,
                listing.originalOwner,
                listing.tokenId,
                listing.quantity,
                listing.pricePerToken,
                listing.quantity + quantity,
                listing.pricePerToken
            );
        }
    }

    // TODO: removeListingAdmin
    function removeListing(uint256 listingId) public {
        address caller = _msgSender();

        // Find entry
        Listing storage listing = _findListing(listingId);
        require(listing.quantity > 0, "Listing does not exist");
        require(caller == listing.originalOwner, "Not the owner of listing");

        emit ExpiringListingRemoved(
            listing.tokenAddress,
            listingId,
            listing.originalOwner,
            listing.tokenId,
            listing.quantity,
            listing.pricePerToken
        );

        _removeListingFromArray(listingId);
    }

    function _findListing(uint256 listingId)
    view
    internal
    returns (Listing storage listing)
    {
        require(listingId < listings.length, "Listing does not exist");
        require(_isValidNode(listingId), "Listing does not exist");
        listing = listings[listingId].listing;
    }

    function _insertListingToArray(Listing memory listing)
    internal
    returns (uint256 newId)
    {
        newId = lastListingId + 1;

        ListingNode storage node = listings[lastValidId]; // Get last node
        listing.listingId = newId;
        listings.push(ListingNode({
            listing: listing,
            prev: lastValidId,
            next: 0
        }));
        node.next = newId;

        numListings++;
        lastListingId++;
        lastValidId = newId;
    }

    function _removeListingFromArray(uint256 id) internal {
        require(_isValidNode(id));

        ListingNode storage lastNode = listings[id];

        if (id == lastValidId) lastValidId = lastNode.prev;

        listings[lastNode.next].prev = lastNode.prev;
        listings[lastNode.prev].next = lastNode.next;

        numListings--;

        delete listings[id];
    }

    function _isValidNode(uint256 id) internal view returns (bool) {
        // 0 is a sentinel and therefore invalid.
        // A valid node is the head or has a previous node.
        return id != 0 && (id == listings[0].next || listings[id].prev != 0);
    }

    function isNotLocked() public view returns (bool) {
        return contractUpgradeAddress == address(0);
    }

    function setContractUpgradeAddress(address newAddress) public onlyOwner {
        contractUpgradeAddress = newAddress;
    }

    function setMetaHiWallet(address payable newWallet) public onlyOwner {
        metaHiWallet = newWallet;
    }

    function setMetaHiPercent(uint256 newPercent) public onlyOwner {
        metaHiPercent = newPercent;
    }

    function setMarketWallet(address payable newWallet) public onlyOwner {
        marketWallet = newWallet;
    }

    function setMarketPercent(uint256 newPercent) public onlyOwner {
        marketPercent = newPercent;
    }

    struct Listing {
        uint256 listingId;
        address tokenAddress;
        address payable originalOwner;
        uint256 tokenId;
        uint256 quantity;
        uint256 pricePerToken;
        uint256 expires;
    }

    struct ListingNode {
        Listing listing;
        uint256 prev;
        uint256 next;
    }

    /**
     * @dev Emitted when someone adds a tokens for sale
     */
    event ExpiringListingAdded(
        address indexed collectionAddress,
        uint256 indexed listingId,
        address originalOwner,
        uint256 indexed tokenId,
        uint256 quantity,
        uint256 pricePerToken,
        uint256 expires
    );

    /**
     * @dev Emitted when original owner removes a listing; or a full sale occurs
     */
    event ExpiringListingRemoved(
        address indexed collectionAddress,
        uint256 indexed listingId,
        address originalOwner,
        uint256 indexed tokenId,
        uint256 quantity,
        uint256 pricePerToken
    );

    /**
     * @dev Emitted when original owner changes a listing price or quantity;
     *      or a partial sale occurs
     */
    event ExpiringListingChanged(
        address indexed collectionAddress,
        uint256 indexed listingId,
        address originalOwner,
        uint256 indexed tokenId,
        uint256 newQuantity,
        uint256 newPricePerToken,
        uint256 oldQuantity,
        uint256 oldPricePerToken
    );

    /**
     * @dev Emitted when a full or partial sale occurs
     */
    event ExpiringSaleSuccessful(
        address indexed collectionAddress,
        uint256 indexed listingId,
        address originalOwner,
        uint256 indexed tokenId,
        uint256 quantity,
        uint256 pricePerToken,
        address newOwner
    );
}