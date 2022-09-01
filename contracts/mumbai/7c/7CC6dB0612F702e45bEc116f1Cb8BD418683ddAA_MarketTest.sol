// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
// import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
// import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "./IMiningLock.sol";
import "./Whitelist.sol";

/// @custom:security-contact [email protected]
contract MarketTest is IERC721Receiver {
    //Events
    event CreateCollection(
        uint256 collectionId,
        address nftContract,
        string name
    );

    event PutOnSaleNFT(
        uint256 indexed collection,
        uint256 indexed tokenId,
        address seller,
        uint256 price
    );

    event ModifyOnSaleNFT(
        uint256 indexed collection,
        uint256 indexed tokenId,
        address seller,
        uint256 price
    );

    event BuyNFT(
        uint256 indexed collection,
        uint256 indexed tokenId,
        address buyer
    );

    event StartSale(uint256 collectionId);

    event StopSale(uint256 collectionId);

    event CancelSaleNFT(uint256 indexed collectionId, uint256 indexed tokenId);

    event SetFeeRate(uint256 oldFee, uint256 newFee);

    event SetFeeTo(address oldFeeTo, address newFeeTo);

    event SetPlatform(address oldPlatform, address newPlatform);

    event SetSaleFloorPrice(uint256 oldFloorPrice, uint256 newFloorPrice);


    address public platform = msg.sender;
    address payable public feeTo = payable(msg.sender);
    uint256 public saleFeeRate = 0;
    uint256 public floorSalePrice = 0;

    IMiningLock public miningLock;
    Whitelist public whitelist;

    struct Collection {
        bool isOnSale;
        address nftContract;
        string name;
        bytes desc;
    }

    struct Offer {
        address seller;
        uint256 price;
    }

    Collection[] private collections;
    mapping(address => bool) private nftContractExists;
    mapping(address => uint256) private nftContractToCollection; //nft contract => collection id

    mapping(uint256 => mapping(uint256 => Offer)) collectionTokenToOffer; //collection id => token id => Offer


    function setMiningLock(address _miningLock) external  {
        miningLock = IMiningLock(_miningLock);
    }

    function setWhitelist(address _whitelist) external  {
        whitelist = Whitelist(_whitelist);
    }

    //Market functions
    function createCollection(
        address nftContract,
        string memory name,
        bytes memory desc
    ) external returns (uint256) {
        //Arg check
        require(nftContract != address(0), "Market: invalid contract");
        require(bytes(name).length != 0, "Market: invalid name");
        require(
            !nftContractExists[nftContract],
            "Market: Collection already existed"
        );

        //Append collection
        uint256 id = collections.length;
        Collection memory collection = Collection(
            true,
            nftContract,
            name,
            desc
        );
        collections.push(collection);
        nftContractExists[nftContract] = true;
        nftContractToCollection[nftContract] = id;
        emit CreateCollection(id, nftContract, name);
        return id;
    }

    // NOTE：approve before put on sale。
    function putOnSaleNFT(
        uint256 collectionId,
        uint256 tokenId,
        uint256 price
    ) external {
        //Arg check
        require(
            collectionId < collections.length,
            "Market: collection not exist"
        );
        require(
            price >= floorSalePrice,
            "Market: price must GE than floor price"
        );
        Collection storage collection = collections[collectionId];
        require(collection.isOnSale, "Market: Collection not on sale");
        Offer storage offer = collectionTokenToOffer[collectionId][tokenId];
        require(offer.seller == address(0), "Market: already on sale");
        IERC721 erc721 = IERC721(collection.nftContract);
        require(msg.sender == erc721.ownerOf(tokenId), "Market: Not owner");
        //Save onchain
        offer.seller = msg.sender;
        offer.price = price;
        //To ensure the market fully take over this token in case that seller do modification to this token
        erc721.safeTransferFrom(msg.sender, address(this), tokenId);
        emit PutOnSaleNFT(collectionId, tokenId, msg.sender, price);
    }

    function modifyOnSaleNFT(
        uint256 collectionId,
        uint256 tokenId,
        uint256 price
    ) external {
        //Arg check
        require(
            collectionId < collections.length,
            "Market: collection not exist"
        );
        require(
            price >= floorSalePrice,
            "Market: price must GE than floor price"
        );
        Collection storage collection = collections[collectionId];
        require(collection.isOnSale, "Market: Collection not on sale");
        Offer storage offer = collectionTokenToOffer[collectionId][tokenId];
        require(offer.seller == msg.sender, "Market: only seller");

        offer.seller = msg.sender;
        offer.price = price;
        //To ensure the market fully take over this token in case that seller do modification to this token
        emit ModifyOnSaleNFT(collectionId, tokenId, msg.sender, price);
    }


    function buyNFT(uint256 collectionId, uint256 tokenId)
        external
        payable
    {
        Offer memory offer = collectionTokenToOffer[collectionId][tokenId];
        require(msg.value >= offer.price, "Not enough msg value");

        //Pay revenue to seller
        payable(offer.seller).transfer(msg.value);

        //Pay refund to buyer
        if (msg.value > offer.price) {
            payable(msg.sender).transfer(msg.value - offer.price);
        }
        _transferNFT(collectionId, tokenId, msg.sender);
        emit BuyNFT(collectionId, tokenId, msg.sender);
    }

    function buyNFTByAgency(
        uint256 collectionId,
        uint256 tokenId,
        address recipient
    ) external payable {
        Offer memory offer = collectionTokenToOffer[collectionId][tokenId];
        require(msg.value >= offer.price, "Not enough msg value");

        //Pay revenue to seller
        payable(offer.seller).transfer(msg.value);

        //Pay refund to buyer
        if (msg.value > offer.price) {
            payable(msg.sender).transfer(msg.value - offer.price);
        }

        _transferNFT(collectionId, tokenId, recipient);
        emit BuyNFT(collectionId, tokenId, recipient);
    }

    function _buyNFTArgsCheck(
        uint256 collectionId,
        uint256 tokenId,
        address recipient
    ) internal view {
        //Arg check
        require(
            collectionId < collections.length,
            "Market: collection not exist"
        );
        Collection memory collection = collections[collectionId];
        require(collection.isOnSale, "Market: collection not on sale");
        Offer memory offer = collectionTokenToOffer[collectionId][tokenId];
        require(offer.seller != address(0), "Market: sale not exist");
        require(
            offer.seller != recipient,
            "Market: Buyer cannot buy token of himselfs"
        );
    }

    function getFeeInfo(uint256 collectionId, uint256 tokenId)
        public
        view
        returns (
            uint256,
            address,
            uint256,
            uint256
        )
    {
        Offer memory offer = collectionTokenToOffer[collectionId][tokenId];
        //Compute tax, royalty, revenue
        address nftContract = collections[collectionId].nftContract;
        IERC2981 erc2981 = IERC2981(nftContract);
        uint256 price = offer.price;
        uint256 tax = (price * saleFeeRate) / feeDenominator();
        (address receiver, uint256 royalty) = erc2981.royaltyInfo(
            tokenId,
            price
        );
        require(receiver != address(0), "Market: invalid royalty receiver");
        uint256 revenue = price - tax - royalty;
        return (tax, receiver, royalty, revenue);
    }

    function _transferNFT(
        uint256 collectionId,
        uint256 tokenId,
        address recipient
    ) internal {
        //clear status
        delete collectionTokenToOffer[collectionId][tokenId];
        IERC721 erc721 = IERC721(collections[collectionId].nftContract);
        erc721.transferFrom(address(this), recipient, tokenId);
    }

    function cancelSaleNFT(uint256 collectionId, uint256 tokenId) external {
        //Args check
        require(
            collectionId < collections.length,
            "Market: collection not exist"
        );
        Collection storage collection = collections[collectionId];
        require(collection.isOnSale, "Market: Collection not on sale");
        Offer storage offer = collectionTokenToOffer[collectionId][tokenId];
        require(offer.seller != address(0), "Market: sale not exist");
        require(offer.seller == msg.sender, "Market: only seller");

        //Clear status
        delete collectionTokenToOffer[collectionId][tokenId];

        //Transfer back to seller
        IERC721 erc721 = IERC721(collection.nftContract);
        erc721.transferFrom(address(this), msg.sender, tokenId);

        emit CancelSaleNFT(collectionId, tokenId);
    }

    function isTokenOnSale(uint256 collectionId, uint256 tokenId)
        external
        view
        returns (bool)
    {
        require(
            collectionId < collections.length,
            "Market: collection not exist"
        );
        Offer storage offer = collectionTokenToOffer[collectionId][tokenId];
        return offer.seller != address(0);
    }

    function getCollectionId(address nftContract)
        external
        view
        returns (uint256)
    {
        require(nftContract != address(0), "Market: Invalid nft contract");
        require(
            nftContractExists[nftContract],
            "Market: nft contract not registered"
        );
        return nftContractToCollection[nftContract];
    }

    function startSale(uint256 collectionId) public  {
        require(
            collectionId < collections.length,
            "Market: collection not exist"
        );
        require(
            !collections[collectionId].isOnSale,
            "Market: collection already active"
        );
        collections[collectionId].isOnSale = true;
        emit StartSale(collectionId);
    }

    function stopSale(uint256 collectionId) external  {
        require(
            collectionId < collections.length,
            "Market: collection not exist"
        );
        require(
            collections[collectionId].isOnSale,
            "Market: collection is not active"
        );
        collections[collectionId].isOnSale = false;
        emit StopSale(collectionId);
    }

    function setFeeRate(uint256 newFee) external  {
        require(newFee < feeDenominator(), "Market: invalid fee rate");
        require(saleFeeRate != newFee, "Market: should not same fee rate");
        uint256 oldFee = saleFeeRate;
        saleFeeRate = newFee;
        emit SetFeeRate(oldFee, newFee);
    }

    function setFeeTo(address payable newFeeTo) external  {
        require(newFeeTo != address(0), "Market: invalid new fee to");
        require(feeTo != newFeeTo, "Market: should not same fee to");
        address oldFeeTo = feeTo;
        feeTo = newFeeTo;
        emit SetFeeTo(oldFeeTo, newFeeTo);
    }

    function setPlatform(address newPlatform) external  {
        require(newPlatform != address(0), "invalid platform");
        require(platform != newPlatform, "same platform");
        address oldPlatform = platform;
        platform = newPlatform;
        emit SetPlatform(oldPlatform, newPlatform);
    }

    function setSaleFloorPrice(uint256 newFloorPrice) external  {
        require(floorSalePrice != newFloorPrice, "same floor price");
        uint256 oldFloorPrice = floorSalePrice;
        floorSalePrice = newFloorPrice;
        emit SetSaleFloorPrice(oldFloorPrice, newFloorPrice);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function feeDenominator() public pure returns (uint256) {
        return 10000;
    }

    // function _authorizeUpgrade(address newImplementation)
    //     internal
    //     override
    // {}
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IMiningLock {
    function isMining(address holder) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/access/Ownable.sol";

contract Whitelist is Ownable {
    mapping(address => bool) public whitelist;

    constructor() {
        whitelist[msg.sender] = true;
    }

    function addToWhitelist(address[] calldata accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            whitelist[accounts[i]] = true;
        }
    }

    function removeFromWhitelist(address[] calldata accounts)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < accounts.length; i++) {
            whitelist[accounts[i]] = false;
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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