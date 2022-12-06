/// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IRentingContractStorage.sol";
import "./IRentingTypes.sol";
import "./IMyListingsStorage.sol";
import "./IERC721Rentable.sol";
import "./IXoiliumMarketplace.sol";


contract RentingStorageViewer is IRentingTypes, Ownable {

    enum MyAssetStatus {
        OWNED,
        LISTED_BATTLE_SET,
        LISTED_COLLECTION,
        RENTED,
        ON_SALE
    }

    uint8 private constant PAGE_SIZE = 100;

    IRentingContractStorage internal storageContract;
    IMyListingsStorage private myListingsStorage;
    IERC721Rentable private landsContract;
    IERC721Rentable private botsContract;
    IXoiliumMarketplace private xoiliumMarketplace;

    constructor(address storageContractAddress, address myListingsStorageAddress,
        address xoiliumMarketplaceAddress) {
        storageContract = IRentingContractStorage(storageContractAddress);
        myListingsStorage = IMyListingsStorage(myListingsStorageAddress);
        xoiliumMarketplace = IXoiliumMarketplace(xoiliumMarketplaceAddress);
    }

    function setTokensAddresses(address lands, address bots) onlyOwner external {
        landsContract = IERC721Rentable(lands);
        botsContract = IERC721Rentable(bots);
    }

    function getLandStatus(uint256 landId) public view returns (TokenRentingStatus) {
        return storageContract.getLandStatus(landId);
    }

    function getBotStatus(uint256 botId) public view returns (TokenRentingStatus) {
        return storageContract.getBotStatus(botId);
    }


    function getListingInfo(uint256 landId) external view returns (ListingInfo memory) {
        return storageContract.getListingInfo(landId);
    }

    function getRentingInfo(uint256 landId) external view returns (RentingInfo memory) {
        return storageContract.getRentingInfo(landId);
    }

    function getCollection(uint256 id) external view returns (Collection memory) {
        return storageContract.getCollection(id);
    }

    struct MyAssets {
        AssetInfo[] assets;
        bool hasNext;
    }

    struct AssetInfo {
        uint256 id;
        address currentOwner;
        MyAssetStatus status;
    }


    function getOwnedAssets(TradedNft nft, address owner, uint page) external view returns (MyAssets memory) {
        uint256[] memory ids = idsOwnedByAddress(nft, owner, page);


        AssetInfo[] memory assetInfo = new AssetInfo[](ids.length);
        for (uint i = 0; i < ids.length; i++) {
            assetInfo[i] = AssetInfo(ids[i], owner, obtainStatus(nft, ids[i]));
        }

        return MyAssets(assetInfo, getERC721Contract(nft).balanceOf(owner) >= PAGE_SIZE * (page + 1));
    }


    function getRentalAssets(TradedNft nft, address owner, uint page) external view returns (MyAssets memory) {
        uint256[] memory ids = myListingsStorage.getRentalAssetsByOwner(nft, owner, page, PAGE_SIZE);

        AssetInfo[] memory assetInfo = new AssetInfo[](ids.length);
        for (uint i = 0; i < ids.length; i++) {
            assetInfo[i] = AssetInfo(ids[i], getERC721Contract(nft).ownerOf(ids[i]), obtainStatus(nft, ids[i]));
        }

        return MyAssets(assetInfo, myListingsStorage.rentalAssetsCount(nft, owner) >= PAGE_SIZE * (page + 1));
    }


    function idsOwnedByAddress(TradedNft nft, address owner, uint page) public view returns (uint256[] memory) {
        uint256 balance = getERC721Contract(nft).balanceOf(owner);
        uint startIdx = PAGE_SIZE * page;
        if (balance == 0 || startIdx >= balance) {
            return new uint[](0);
        }

        uint elementsInPage = PAGE_SIZE > balance - startIdx ? balance - startIdx : PAGE_SIZE;

        uint counter = 0;
        uint[] memory tokensIds = new uint[](elementsInPage);
        for (uint i = startIdx; i < startIdx + elementsInPage; i++) {
            tokensIds[counter++] = getERC721Contract(nft).tokenOfOwnerByIndex(owner, i);
        }
        return tokensIds;
    }

    function obtainStatus(TradedNft nft, uint256 id) private view returns (MyAssetStatus) {
        TokenRentingStatus rentingStatus = nft == TradedNft.RBXL ? getLandStatus(id) : getBotStatus(id);
        if (rentingStatus == TokenRentingStatus.AVAILABLE) {
            return xoiliumMarketplace.getListing(uint8(nft), id).seller == address(0) ? MyAssetStatus.OWNED : MyAssetStatus.ON_SALE;
        } else if (rentingStatus == TokenRentingStatus.LISTED_BATTLE_SET) {
            return MyAssetStatus.LISTED_BATTLE_SET;
        } else if (rentingStatus == TokenRentingStatus.LISTED_COLLECTION) {
            return MyAssetStatus.LISTED_COLLECTION;
        } else {
            return MyAssetStatus.RENTED;
        }
    }

    function getERC721Contract(TradedNft nft) private view returns (IERC721Rentable) {
        return nft == TradedNft.RBXL ? landsContract : botsContract;
    }

    function getListingCount() external view returns (uint256) {
        return storageContract.getListingCount();
    }

    function getRentingsCount() external view returns (uint256) {
        return storageContract.getRentingsCount();
    }

    function getCollectionsCount() external view returns (uint256) {
        return storageContract.getCollectionsCount();
    }

    function getListings(uint256 page) external view returns (ListingInfo[] memory) {
        uint256 count = storageContract.getListingCount();
        if (count < PAGE_SIZE * page) {
            return new ListingInfo[](0);
        }

        ListingInfo[] memory result = new ListingInfo[](PAGE_SIZE);
        uint counter = 0;
        uint256 endIdx = PAGE_SIZE * (page + 1) < count ? PAGE_SIZE * (page + 1) : count;
        for (uint i = PAGE_SIZE * page; i < endIdx; i++) {
            result[counter++] = storageContract.getListingInfo(storageContract.getListingIdByIndex(i));
        }

        if (counter < PAGE_SIZE) {
            ListingInfo[] memory trimmedResult = new ListingInfo[](counter);
            for (uint j = 0; j < counter; j++) {
                trimmedResult[j] = result[j];
            }
            return trimmedResult;
        }
        return result;
    }

    function getRentings(uint256 page) external view returns (RentingInfo[] memory) {
        uint256 count = storageContract.getRentingsCount();
        if (count < PAGE_SIZE * page) {
            return new RentingInfo[](0);
        }

        RentingInfo[] memory result = new RentingInfo[](PAGE_SIZE);
        uint counter = 0;
        uint256 endIdx = PAGE_SIZE * (page + 1) < count ? PAGE_SIZE * (page + 1) : count;
        for (uint i = PAGE_SIZE * page; i < endIdx; i++) {
            result[counter++] = storageContract.getRentingInfo(storageContract.getRentingIdByIndex(i));
        }

        if (counter < PAGE_SIZE) {
            RentingInfo[] memory trimmedResult = new RentingInfo[](counter);
            for (uint j = 0; j < counter; j++) {
                trimmedResult[j] = result[j];
            }
            return trimmedResult;
        }
        return result;
    }

    function getCollectionsIds(uint256 page) external view returns (uint256[] memory) {
        uint256 count = storageContract.getCollectionsCount();
        if (count < PAGE_SIZE * page) {
            return new uint256[](0);
        }

        uint256[] memory result = new uint256[](PAGE_SIZE);
        uint counter = 0;
        uint256 endIdx = PAGE_SIZE * (page + 1) < count ? PAGE_SIZE * (page + 1) : count;
        for (uint i = PAGE_SIZE * page; i < endIdx; i++) {
            result[counter++] = storageContract.getCollectionIdByIndex(i);
        }

        if (counter < PAGE_SIZE) {
            uint256[] memory trimmedResult = new uint256[](counter);
            for (uint j = 0; j < counter; j++) {
                trimmedResult[j] = result[j];
            }
            return trimmedResult;
        }
        return result;
    }
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

/// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./IRentingTypes.sol";

interface IRentingContractStorage is IRentingTypes {

    function getLandStatus(uint256 landId) external view returns (TokenRentingStatus);

    function getBotStatus(uint256 botId) external view returns (TokenRentingStatus);

    function renewRenting(uint256 id, uint256 renewTs, uint256 rentingEndTs) external;

    function getRentingInfo(uint256 landId) external view returns (RentingInfo memory);

    function getCollection(uint256 id) external view returns (Collection memory);

    function createRenting(BattleSet memory bs, RentingType rt, Coin coin, uint256 price, address owner, address renter,
        uint256 rentingEnd, uint256 collectionId, bool perpetual, address[] memory whitelist, uint revenueShare) external;

    function deleteListingInfo(uint256 landId) external;

    function getListingInfo(uint256 landId) external view returns (ListingInfo memory);

    function updateCollectionRentedAssets(uint256 id, uint256[] memory availableLands, uint256[] memory availableBotsIds,
        uint256[] memory rentedLandIds, uint256[] memory rentedBotsIds) external;

    function deleteRenting(uint256 landId) external;

    function createCollection(address assetsOwner, uint256[] memory landIds, uint256[] memory botIds,
        bool perpetual, address[] memory players, PaymentData memory pd) external returns (uint256);

    function editCollection(uint256 id, Coin coin, uint256 price, RentingType rentingType, bool perpetual, uint revenueShare) external;

    function addAssetsToCollection(uint id, uint256[] memory landIds, uint256[] memory botIds) external;

    function removeListedLand(uint id, uint256 landIdToRemove) external;

    function pushToBeRemovedLands(uint id, uint256 landIdToRemove) external;

    function pushToBeRemovedBots(uint id, uint256 botIdToRemove) external;

    function removeListedBot(uint id, uint256 botIdToRemove) external;

    function disbandCollection(uint256 id) external returns (bool);

    function processCollectionRentalEnd(RentingInfo memory ri) external returns (Collection memory);

    function createListingInfo(BattleSet memory bs, RentingType rt, address owner, Coin coin, uint256 price,
        bool perpetual, address[] memory whitelist, uint revenueShare) external;

    function addPlayersToCollection(uint id, address[] memory players) external;

    function removePlayersFromCollection(uint id, address player) external;

    function setRentingCancelTs(uint256 id, uint256 cancelTs) external;

    function getCollectionIdByIndex(uint256 idx) external view returns (uint256);

    function getCollectionsCount() external view returns (uint256);

    function getRentingIdByIndex(uint256 idx) external view returns (uint256);

    function getRentingsCount() external view returns (uint256);

    function getListingIdByIndex(uint256 idx) external view returns (uint256);

    function getListingCount() external view returns (uint256);
}

/// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IRentingTypes {

    enum Coin {
        XOIL,
        RBLS,
        WETH,
        USDC,
        BUSD,
        USDT,
        DAI
    }

    enum RentingType {
        FIXED_PRICE,
        REVENUE_SHARE
    }

    enum TokenRentingStatus {
        AVAILABLE,
        LISTED_BATTLE_SET,
        LISTED_COLLECTION,
        RENTED
    }

    struct BattleSet {
        uint256 landId;
        uint256[] botsIds;
    }

    struct ListingInfo {
        BattleSet battleSet;
        RentingType rentingType;
        Coin chargeCoin;
        uint256 listingTs;
        address owner;
        uint256 price;
        bool perpetual;
        address[] whitelist;
        uint revenueShare;
    }

    struct RentingInfo {
        BattleSet battleSet;
        RentingType rentingType;
        Coin chargeCoin;
        uint256 price;
        address owner;
        address renter;
        uint256 rentingTs;
        uint256 renewTs;
        uint256 rentingEndTs;
        uint256 cancelTs;
        uint256 collectionId;
        bool perpetual;
        address[] whitelist;
        uint revenueShare;
    }

    struct Collection {
        uint256 id;
        address owner;
        uint256[] landIds;
        uint256[] botsIds;
        uint256[] rentedLandIds;
        uint256[] rentedBotsIds;
        uint256[] landsToRemove;
        uint256[] botsToRemove;
        address[] whitelist;
        RentingType rentingType;
        Coin chargeCoin;// probaby change to uint
        uint256 price;
        bool perpetual;
        uint256 disbandTs;
        uint revenueShare;
    }

    struct PaymentData {
        RentingType rentingType;
        Coin coin;
        uint256 price;
        uint revenueShare;
    }

    enum TradedNft {
        RBXL,
        RBFB
    }

}

/// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./IRentingTypes.sol";

interface IMyListingsStorage is IRentingTypes {

    function rentalAssetsCount(TradedNft nft, address owner) external view returns (uint256);

    function rentalOwnersAssetByIndex(TradedNft nft, address owner, uint256 idx) external view returns (uint256);

    function getRentalAssetsByOwner(TradedNft nft, address owner, uint page, uint pageSize) external view returns (uint256[] memory);

    function add(TradedNft nft, address owner, uint256 id) external;

    function remove(TradedNft nft, address owner, uint256 id) external;

    function addAll(TradedNft nft, address owner, uint256[] memory ids) external;

    function removeAll(TradedNft nft, address owner, uint256[] memory ids) external;

}

/// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

//import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC721Enumerable.sol";

interface IERC721Rentable is IERC721Enumerable {
    function isTokenRented(uint256 tokenId) external view returns (bool);

    function safeTransferFromForRent(address from, address to, uint256 tokenId, bytes memory _data) external;
}

/// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;


import "./IXoiliumMarketplaceStorageTypes.sol";

interface IXoiliumMarketplace is IXoiliumMarketplaceStorageTypes {
    function anyListingsExist(uint8 nft, uint256[] memory tokenIds) external view returns (bool);

    function validListingExists(uint8 nft, uint256 tokenId) external view returns (bool);

    function getListing(uint8 nft, uint256 tokenId) external view returns (Listing memory);
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/extensions/IERC721Enumerable.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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

/// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IXoiliumMarketplaceStorageTypes {
    struct Listing {
        uint8 nft;
        uint256 tokenId;
        uint8 coin;
        uint256 price;
        address seller;
        uint256 endTs;
        address allowedBuyer;
    }
}