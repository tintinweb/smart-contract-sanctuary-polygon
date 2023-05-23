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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

import "./MarketplaceERC721.sol";

contract FactoryMarketplaceERC721 {
    KeySpaceERC721NFTMarketplace[] public deployedContracts;
    mapping(uint256 => address) public indexToContract; //index to contract address mapping
    mapping(uint256 => address) public indexToOwner; //index to NFT Marketplace owner address

    event ERC721NFTMarketplaceCreated(
        address owner,
        address tokenContract,
        string marketplaceId
    ); //emitted when marketplace contract is deployed

    function deployNFTMarketplaceContract(
        string memory _marketplaceId,
        uint256 _feePercent,
        uint256 _listingFee,
        address payable _originatingWallet
    ) external returns (address) {
        KeySpaceERC721NFTMarketplace newContract = new KeySpaceERC721NFTMarketplace(
            _feePercent,
            _listingFee,
            _marketplaceId,
            _originatingWallet
        );
        deployedContracts.push(newContract);
        indexToContract[deployedContracts.length - 1] = address(newContract);
        indexToOwner[deployedContracts.length - 1] = tx.origin;
        //newContract.transferOwnership(tx.origin); //Transfer ownership of the child contract to user
        emit ERC721NFTMarketplaceCreated(
            msg.sender,
            address(newContract),
            _marketplaceId
        );
        return address(newContract); //Return the address of the deployed contract
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

error PriceNotMet(address nftAddress, uint256 tokenId, uint256 price);
error ItemNotForSale(address nftAddress, uint256 tokenId);
error NotListed(address nftAddress, uint256 tokenId);
error AlreadyListed(address nftAddress, uint256 tokenId);
error NoProceeds();
error NotOwner();
error NotApprovedForMarketplace();

contract KeySpaceERC721NFTMarketplace is ReentrancyGuard {
    using Counters for Counters.Counter;

    address payable public immutable listerAccount; //the account that is allowed to list items on the marketplace
    address payable public immutable feeAccount; //the account that receives fees
    uint256 public immutable feePercent; //the fee percentage on sales
    uint256 public listingFee; //price to list an item on the marketplace

    Counters.Counter private _nftsSold;

    struct NFT {
        address nftContract;
        uint256 tokenId; //from smart contract
        address payable seller;
        address payable listedMarketplace;
        uint256 price;
        bool listed;
        //quantity?
    }

    event NFTListed(
        address nftContract,
        uint256 tokenId,
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
        if (item.price < 0 || item.listed == false) {
            revert NotListed(_nftContract, _tokenId);
        }
        _;
    }

    modifier notListed(address _nftContract, uint256 _tokenId) {
        NFT memory item = _listings[_nftContract][_tokenId];
        if (item.price >= 0 && item.listed == true) {
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
        uint256 _price
    ) public payable notListed(_nftContract, _tokenId) {
        require(
            msg.sender == listerAccount,
            "Only the lister account has permissions to list items for sale"
        );
        require(_price >= 0, "NFT listed price must be at least 0");
        require(msg.value >= listingFee, "Not enough ether for listing fee");

        IERC721 nft = IERC721(_nftContract);
        // if (nft.getApproved(_tokenId) != address(this)) {
        //     revert NotApprovedForMarketplace();
        // }

        nft.transferFrom(msg.sender, address(this), _tokenId);

        _listings[_nftContract][_tokenId] = NFT(
            _nftContract,
            _tokenId,
            payable(msg.sender), //seller
            payable(address(this)), //listedMarketplace
            _price,
            true
        );

        emit NFTListed(
            _nftContract,
            _tokenId,
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
            msg.sender,
            address(this),
            _newPrice
        );
    }

    //Bulk list erc721 collection on marketplace
    function bulkList721NftCollection(
        address _nftContract,
        string calldata _collectionId,
        uint256 _collectionSize,
        uint256 _price
    ) public payable nonReentrant {
        require(_price >= 0, "NFT listed price must be at least 0");
        require(msg.value == listingFee, "Not enough ether for listing fee"); //should listing fee be multiplied to charge per NFT

        for (uint256 i = 0; i < _collectionSize; i++) {
            listNft(_nftContract, i, _price);
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

    function getTotalListingPrice(address _nftContract, uint256 _listingId)
        private
        view
        returns (uint256)
    {
        //Calculate total listing price = price set by seller + market fees
        return ((_listings[_nftContract][_listingId].price *
            (100 + feePercent)) / 100);
    }

    function purchaseNft(address _nftContract, uint256 _tokenId)
        external
        payable
        nonReentrant
    {
        //Check this item exists in the marketplace and is listed
        NFT storage item = _listings[_nftContract][_tokenId];
        require(item.listed, "Item already sold or delisted");

        //Calculate the total price of the item including marketplace feeds
        uint256 _totalPrice = getTotalListingPrice(_nftContract, _tokenId);
        require(
            msg.value >= _totalPrice,
            "Insufficient funds sent to cover NFT price and market fees"
        );

        //Update item state as sold
        item.listed = false;

        //Transfer NFT to the buyer
        IERC721(_nftContract).transferFrom(
            item.listedMarketplace,
            msg.sender,
            item.tokenId
        );

        _proceeds[item.seller] += item.price;

        //Pay seller and feeAccount
        feeAccount.transfer(_totalPrice - item.price);

        delete (_listings[_nftContract][_tokenId]);

        //Emit bought event
        emit NFTSold(
            _nftContract,
            _tokenId,
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
            item.listed,
            "Item not actively listed or has already been sold"
        );

        item.listed = false; //unlist the item

        IERC721(_nftContract).transferFrom(
            address(this),
            item.seller,
            item.tokenId
        ); //send NFT back to the initial owner

        delete (_listings[_nftContract][_tokenId]); //delete the item from the listings mapping

        //Emit event that the item was unlisted
        emit NFTUnlisted(
            _nftContract,
            _tokenId,
            item.seller,
            item.listedMarketplace,
            item.price
        );
    }

    //Unlist entire collection
    function bulkUnlist721NftCollection(
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
            if (_listings[_nftContract][i].listed == true) {
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