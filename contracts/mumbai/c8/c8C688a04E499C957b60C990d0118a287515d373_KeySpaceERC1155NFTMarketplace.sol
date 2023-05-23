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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

error PriceNotMet(address nftAddress, uint256 tokenId, uint256 price);
error ItemNotForSale(address nftAddress, uint256 tokenId);
error NotListed(address nftAddress, uint256 tokenId);
error AlreadyListed(address nftAddress, uint256 tokenId);
error NoProceeds();
error NotOwner();
error NotApprovedForMarketplace();

contract KeySpaceERC1155NFTMarketplace is ReentrancyGuard, ERC1155Holder {
    using Counters for Counters.Counter;

    address payable public immutable listerAccount; //the account that is allowed to list items on the marketplace
    address payable public immutable feeAccount; //the account that receives fees
    uint256 public immutable feePercent; //the fee percentage on sales
    uint256 public listingFee; //price to list an item on the marketplace

    Counters.Counter private _nftsSold;

    struct NFT {
        address nftContract;
        uint256 tokenId; //from smart contract
        uint256 quantityInStock;
        address payable seller;
        address payable listedMarketplace;
        uint256 price;
        bool listed;
    }

    event NFTListed(
        address nftContract,
        uint256 tokenId,
        uint256 quantityInStock,
        address seller,
        address listedMarketplace,
        uint256 price
    );

    //should collection support custom prices per token id?
    event NFTCollectionListed(
        address nftContract,
        string collectionId,
        uint256 collectionSize,
        address seller,
        address listedMarketplace,
        uint256 price
    );

    event NFTUnlisted(
        address nftContract,
        uint256 tokenId,
        uint256 quantityInStock,
        address seller,
        address listedMarketplace,
        uint256 price
    );

    event NFTCollectionUnlisted(
        address nftContract,
        string collectionId,
        address listedMarketplace
    );

    event NFTSold(
        address nftContract,
        uint256 tokenId,
        uint256 quantityPurchased,
        address buyer,
        address seller,
        address listedMarketplace,
        uint256 price
    );

    //map token contract -> token id > listing
    mapping(address => mapping(uint256 => NFT)) private _listings;
    mapping(address => uint256) private _proceeds;

    //Custom function modifiers
    modifier isListed(address _nftContract, uint256 _tokenId) {
        NFT memory item = _listings[_nftContract][_tokenId];
        if (
            item.price < 0 || item.quantityInStock <= 0 || item.listed == false
        ) {
            revert NotListed(_nftContract, _tokenId);
        }
        _;
    }

    modifier notListed(address _nftContract, uint256 _tokenId) {
        NFT memory item = _listings[_nftContract][_tokenId];
        if (
            item.price >= 0 && item.quantityInStock > 0 && item.listed == true
        ) {
            revert AlreadyListed(_nftContract, _tokenId);
        }
        _;
    }

    modifier isOwner(
        address _nftContract,
        uint256 _tokenId,
        address spender
    ) {
        NFT memory item = _listings[_nftContract][_tokenId];
        address owner = item.seller;
        if (spender != owner) {
            revert NotOwner();
        }
        _;
    }

    constructor(
        uint256 _feePercent,
        uint256 _listingFee,
        string memory _marketplaceId,
        address payable _originatingWallet
    ) {
        listerAccount = _originatingWallet;
        listingFee = _listingFee;
        feeAccount = _originatingWallet; //should this be keyspace?
        feePercent = _feePercent;
    }

    // List the NFT on the marketplace
    function listNft(
        address _nftContract,
        uint256 _tokenId,
        uint256 _quantityInStock,
        uint256 _price
    ) public payable notListed(_nftContract, _tokenId) {
        require(
            msg.sender == listerAccount,
            "Only the lister account has permissions to list items for sale"
        );
        require(_price >= 0, "NFT listed price must be at least 0");
        require(msg.value >= listingFee, "Not enough ether for listing fee");

        IERC1155 nft = IERC1155(_nftContract);
        // if (nft.getApproved(_tokenId) != address(this)) {
        //     revert NotApprovedForMarketplace();
        // }

        nft.safeTransferFrom(
            msg.sender,
            address(this),
            _tokenId,
            _quantityInStock,
            "0x0"
        );

        _listings[_nftContract][_tokenId] = NFT(
            _nftContract,
            _tokenId,
            _quantityInStock,
            payable(msg.sender), //seller
            payable(address(this)), //listedMarketplace
            _price,
            true
        );

        emit NFTListed(
            _nftContract,
            _tokenId,
            _quantityInStock,
            msg.sender,
            address(this),
            _price
        );
    }

    //Update listing price
    function updateNftListing(
        address _nftContract,
        uint256 _tokenId,
        uint256 _newPrice
    )
        external
        isListed(_nftContract, _tokenId)
        isOwner(_nftContract, _tokenId, msg.sender)
        nonReentrant
    {
        require(_newPrice >= 0, "NFT listed price must be at least 0");

        _listings[_nftContract][_tokenId].price = _newPrice;

        emit NFTListed(
            _nftContract,
            _tokenId,
            _listings[_nftContract][_tokenId].quantityInStock,
            msg.sender,
            address(this),
            _newPrice
        );
    }

    //Bulk list erc1155 collection on marketplace
    function bulkList1155NftCollection(
        address _nftContract,
        string calldata _collectionId,
        uint256[] memory _quantitiesInStock,
        uint256 _collectionSize,
        uint256 _price
    ) public payable nonReentrant {
        require(
            _quantitiesInStock.length == _collectionSize,
            "List of stock quantities must match collection size"
        );
        require(_price >= 0, "NFT listed price must be at least 0");
        require(msg.value == listingFee, "Not enough ether for listing fee"); //should listing fee be multiplied to charge per NFT

        for (uint256 i = 0; i < _collectionSize; i++) {
            listNft(_nftContract, i, _quantitiesInStock[i], _price);
        }

        emit NFTCollectionListed(
            _nftContract,
            _collectionId,
            _collectionSize,
            msg.sender,
            address(this),
            _price
        );
    }

    function getTotalListingPrice(address _nftContract, uint256 _listingId, uint256 _quantityToPurchase)
        private
        view
        returns (uint256)
    {
        //Calculate total listing price = price set by seller + market fees
        return ((_listings[_nftContract][_listingId].price * _quantityToPurchase *
            (100 + feePercent)) / 100);
    }

    function purchaseNft(
        address _nftContract,
        uint256 _tokenId,
        uint256 _quantityToPurchase
    ) external payable nonReentrant {
        //Check this item exists in the marketplace and is listed
        NFT storage item = _listings[_nftContract][_tokenId];
        require(item.listed, "Item already sold or delisted");
        require(_quantityToPurchase > 0, "Must purchase at least one unit");
        require(
            item.quantityInStock >= _quantityToPurchase,
            "Item out of stock"
        );

        //Calculate the total price of the item including marketplace feeds
        uint256 _totalPrice = getTotalListingPrice(_nftContract, _tokenId, _quantityToPurchase);
        require(
            msg.value >= _totalPrice,
            "Insufficient funds sent to cover NFT price and market fees"
        );

        //Update item state as sold
        item.quantityInStock -= _quantityToPurchase;

        //Transfer NFT to the buyer
        IERC1155(_nftContract).safeTransferFrom(
            item.listedMarketplace,
            msg.sender,
            _tokenId,
            _quantityToPurchase,
            "0x0"
        );

        _proceeds[item.seller] += item.price * _quantityToPurchase;

        //Pay seller and feeAccount
        feeAccount.transfer(_totalPrice - (item.price * _quantityToPurchase));

        //Remove listing if out of stock
        if (item.quantityInStock == 0) {
            delete (_listings[_nftContract][_tokenId]);
        }
        
        //Emit bought event
        emit NFTSold(
            _nftContract,
            _tokenId,
            _quantityToPurchase,
            msg.sender,
            item.seller,
            item.listedMarketplace,
            item.price
        );
    }

    //Unlist item
    function unlistNft(address _nftContract, uint256 _tokenId) public {
        require(
            msg.sender == listerAccount,
            "Only the lister account has permissions to unlist items from marketplace"
        );

        NFT storage item = _listings[_nftContract][_tokenId];

        require(
            item.listed && item.quantityInStock > 0,
            "Item not actively listed or is already out of stock"
        );

        item.listed = false; //unlist the item

        IERC1155(_nftContract).safeTransferFrom(
            address(this),
            item.seller,
            item.tokenId,
            item.quantityInStock,
            "0x0"
        ); //send NFT back to the initial owner

        delete (_listings[_nftContract][_tokenId]); //delete the item from the listings mapping

        //Emit event that the item was unlisted
        emit NFTUnlisted(
            _nftContract,
            _tokenId,
            item.quantityInStock,
            item.seller,
            item.listedMarketplace,
            item.price
        );
    }

    //Unlist entire collection
    function bulkUnlist1155NftCollection(
        address _nftContract,
        uint256 _collectionSize,
        string calldata _collectionId
    ) external nonReentrant {
        require(
            msg.sender == listerAccount,
            "Only the lister account has permissions to unlist items from marketplace"
        );

        for (uint256 i = 0; i < _collectionSize; i++) {
            //Check if listing has not already been sold
            if (_listings[_nftContract][i].listed == true && _listings[_nftContract][i].quantityInStock > 0) {
                unlistNft(_nftContract, i);
            }
        }

        //Emit event that the colleciton was unlisted
        emit NFTCollectionUnlisted(_nftContract, _collectionId, address(this));
    }

    //GET all listed NFTs in the marketplace
    function getListedNfts() public view returns (NFT[] memory) {}

    // GET a user's listed NFTs
    function getUserListedNfts(address user)
        public
        view
        returns (NFT[] memory)
    {}

    //GET the listed NFTs from a given contract address/collectionId
    function getCollectionListedNfts(
        address _nftContract,
        uint256 collectionSize
    ) public view returns (NFT[] memory) {
        NFT[] memory items = new NFT[](collectionSize);
        for (uint256 i = 0; i < collectionSize; i++) {
            if (_listings[_nftContract][i].listed == true) {
                NFT storage currentItem = _listings[_nftContract][i];
                items[i] = currentItem;
            }
        }
        return items;
    }

    //GET a listed NFT by contract address and tokenId
    function getListedNft(address _nftContract, uint256 tokenId)
        external
        view
        returns (NFT[] memory)
    {
        NFT[] memory items = new NFT[](1);
        if (_listings[_nftContract][tokenId].listed == true) {
            NFT storage currentItem = _listings[_nftContract][tokenId];
            items[0] = currentItem;
        }
        return items;
    }

    function getListingFee() public view returns (uint256) {
        return listingFee;
    }

    function getMarketplaceFeePercent() public view returns (uint256) {
        return feePercent;
    }

    function getProceeds(address seller) external view returns (uint256) {
        return _proceeds[seller];
    }

    function withdrawProceeds() external {
        uint256 proceeds = _proceeds[msg.sender];
        if (proceeds <= 0) {
            revert NoProceeds();
        }
        _proceeds[msg.sender] = 0;

        (bool success, ) = payable(msg.sender).call{value: proceeds}("");
        require(success, "Transfer failed");
    }
}