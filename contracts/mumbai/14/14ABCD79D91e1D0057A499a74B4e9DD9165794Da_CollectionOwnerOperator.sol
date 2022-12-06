/// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Array256Lib.sol";
import "./IRentingTypes.sol";
import "./IERC721Rentable.sol";
import "./IAccountManagers.sol";
import "./IRentingContractStorage.sol";
import "./IXoiliumMarketplace.sol";
import "./IMyListingsStorage.sol";


contract CollectionOwnerOperator is Context, Ownable, Pausable, IRentingTypes, ReentrancyGuard {

    event CollectionCreated(uint256 id);
    event CollectionUpdated(uint256 id);
    event CollectionPlayersUpdated(uint256 id);
    event CollectionBotsUpdated(uint256 id);
    event CollectionLandsUpdated(uint256 id);
    event CollectionDisband(uint256 id, bool completed);

    uint private constant MAX_LANDS_IN_COLLECTION = 300;
    uint private constant MAX_BOTS_IN_COLLECTION = 600;

    mapping(Coin => address) private paymentContracts;
    IRentingContractStorage private storageContract;
    IERC721Rentable private landsContract;
    IERC721Rentable private botsContract;
    IXoiliumMarketplace private xoiliumMarketplace;
    IAccountManagers private accountManagers;
    IMyListingsStorage private myListingsStorage;


    mapping(RentingType => Coin[]) supportedCoins;

    constructor(address storageAddr, address myListingsStorageAddr, address marketplaceAddr, address accountManagersAddr) {
        storageContract = IRentingContractStorage(storageAddr);
        xoiliumMarketplace = IXoiliumMarketplace(marketplaceAddr);
        accountManagers = IAccountManagers(accountManagersAddr);
        myListingsStorage = IMyListingsStorage(myListingsStorageAddr);
        supportedCoins[RentingType.REVENUE_SHARE] = [Coin.XOIL];
        supportedCoins[RentingType.FIXED_PRICE] = [Coin.XOIL];
    }

    function setTokensAddresses(address lands, address bots, address xoil, address rbls, address weth) onlyOwner external {
        paymentContracts[Coin.XOIL] = xoil;
        paymentContracts[Coin.RBLS] = rbls;
        paymentContracts[Coin.WETH] = weth;
        landsContract = IERC721Rentable(lands);
        botsContract = IERC721Rentable(bots);
    }

    function setMarketplaceAddress(address xoiliumMarketplaceAddress) onlyOwner external {
        xoiliumMarketplace = IXoiliumMarketplace(xoiliumMarketplaceAddress);
    }

    function setUpSupportedCoins(Coin[] memory fixedPriceCoins, Coin[] memory revShareCoins) onlyOwner external {
        supportedCoins[RentingType.FIXED_PRICE] = fixedPriceCoins;
        supportedCoins[RentingType.REVENUE_SHARE] = revShareCoins;
    }

    function editCollection(uint256 id, Coin coin, uint256 price, RentingType rentingType, bool perpetual, uint revenueShare) whenNotPaused external {
        Collection memory collection = storageContract.getCollection(id);
        require(isAuthorizedToEdit(collection.owner), "Not authorized");
        require(rentingType == RentingType.FIXED_PRICE || (revenueShare != 0 && revenueShare < 100),
            "Revenue share should be between 0-100 with revenue share renting type");
        require(rentingType == RentingType.REVENUE_SHARE || price >= 100, "Price should be greater than 100");
        require(paymentContracts[coin] != address(0), "Not supported payment coin");
        require(isSupportedCoin(rentingType, coin), "Not supported payment currency for selected renting type");

        storageContract.editCollection(id, coin, price, rentingType, perpetual, revenueShare);
        emit CollectionUpdated(id);
    }

    function createCollectionFixedPrice(uint256[] memory landIds, uint256[] memory botIds, address[] memory players,
        Coin coin, uint256 price, bool perpetual) whenNotPaused nonReentrant external {
        require(isSupportedCoin(RentingType.FIXED_PRICE, coin), "Not supported payment currency");
        require(price >= 100, "Price should be greater than 100");

        createCollection(landIds, botIds, players, perpetual, PaymentData(RentingType.FIXED_PRICE, coin, price, 0));
    }

    function createCollectionShareRental(uint256[] memory landIds, uint256[] memory botIds, address[] memory players,
        Coin coin, uint256 guaranteeAmount, bool perpetual, uint revenueShare) whenNotPaused nonReentrant external {
        require(isSupportedCoin(RentingType.REVENUE_SHARE, coin), "Not supported payment currency");
        require(revenueShare != 0 && revenueShare < 100, "Revenue share should be between 0-100 with revenue share renting type");

        createCollection(landIds,
            botIds,
            players,
            perpetual,
            PaymentData(RentingType.REVENUE_SHARE, coin, guaranteeAmount, revenueShare));
    }

    function addLandsToCollection(uint id, uint256[] memory landIds) whenNotPaused external {
        Collection memory collection = storageContract.getCollection(id);
        require(!xoiliumMarketplace.anyListingsExist(0, landIds), "One of the land is listed for sale");
        require(collection.landIds.length + collection.rentedLandIds.length + landIds.length <= MAX_LANDS_IN_COLLECTION, "Lands number exceeds the limit");
        require(areTokensAvailable(TradedNft.RBXL, landIds), "One of the land is present in other battle set or in the collection");
        require(isAuthorizedToEdit(collection.owner), "Not authorized");

        transferTokens(landIds, new uint256[](0), collection.owner, address(storageContract));
        storageContract.addAssetsToCollection(id, landIds, new uint256[](0));
        myListingsStorage.addAll(TradedNft.RBXL, collection.owner, landIds);

        emit CollectionLandsUpdated(id);
    }

    function addBotsToCollection(uint id, uint256[] memory botIds) whenNotPaused external {
        Collection memory collection = storageContract.getCollection(id);
        require(!xoiliumMarketplace.anyListingsExist(1, botIds), "One of the bots listed for sale");
        require(collection.botsIds.length + collection.rentedBotsIds.length + botIds.length <= MAX_BOTS_IN_COLLECTION,
            "Bots number exceeds the limit");
        require(areTokensAvailable(TradedNft.RBFB, botIds), "One of the bots is present in other battle set or in the collection");
        require(isAuthorizedToEdit(collection.owner), "Not authorized");

        transferTokens(new uint256[](0), botIds, collection.owner, address(storageContract));
        storageContract.addAssetsToCollection(id, new uint256[](0), botIds);
        myListingsStorage.addAll(TradedNft.RBFB, collection.owner, botIds);

        emit CollectionBotsUpdated(id);
    }

    function removeLandFromCollection(uint id, uint256 landIdToRemove) whenNotPaused external {
        Collection memory collection = storageContract.getCollection(id);
        require(isAuthorizedToEdit(collection.owner), "Not authorized");
        require(collection.landIds.length + collection.rentedLandIds.length - collection.landsToRemove.length - 1 >= 2,
            "The target size of lands in collection is below of minimum");

        TokenRentingStatus status = storageContract.getLandStatus(landIdToRemove);
        if (status == TokenRentingStatus.LISTED_COLLECTION) {
            storageContract.removeListedLand(id, landIdToRemove);

            landsContract.transferFrom(address(storageContract), collection.owner, landIdToRemove);

            myListingsStorage.remove(TradedNft.RBXL, collection.owner, landIdToRemove);
        } else if (status == TokenRentingStatus.RENTED) {
            RentingInfo memory ri = storageContract.getRentingInfo(landIdToRemove);
            require(ri.collectionId == id, "The land is not contained in specified collection");

            if (!Array256Lib.contains(collection.landsToRemove, landIdToRemove)) {
                storageContract.pushToBeRemovedLands(id, landIdToRemove);
            }
        }
        emit CollectionLandsUpdated(id);
    }

    function removeBotFromCollection(uint id, uint256 botIdToRemove) whenNotPaused external {
        Collection memory collection = storageContract.getCollection(id);
        require(isAuthorizedToEdit(collection.owner), "Not authorized");
        require(collection.botsIds.length + collection.rentedBotsIds.length - collection.botsToRemove.length - 1 >= 6, "The target size of bots in collection is below of minimum");

        if (Array256Lib.contains(collection.botsIds, botIdToRemove)) {//not rented
            storageContract.removeListedBot(id, botIdToRemove);

            botsContract.transferFrom(address(storageContract), collection.owner, botIdToRemove);
            myListingsStorage.remove(TradedNft.RBFB, collection.owner, botIdToRemove);
        } else if (Array256Lib.contains(collection.rentedBotsIds, botIdToRemove)) {
            storageContract.pushToBeRemovedBots(id, botIdToRemove);
        }
        emit CollectionBotsUpdated(id);
    }

    function addPlayersToCollection(uint id, address[] memory players) whenNotPaused external {
        require(isAuthorizedToEdit(storageContract.getCollection(id).owner), "Not authorized");

        storageContract.addPlayersToCollection(id, players);
        emit CollectionPlayersUpdated(id);
    }

    function removePlayersFromCollection(uint id, address player) whenNotPaused external {
        require(isAuthorizedToEdit(storageContract.getCollection(id).owner), "Not authorized");

        storageContract.removePlayersFromCollection(id, player);
        emit CollectionPlayersUpdated(id);
    }

    function disbandCollection(uint256 id) whenNotPaused nonReentrant external {
        Collection memory collection = storageContract.getCollection(id);
        require(isAuthorizedToEdit(collection.owner), "Not authorized");
        if (storageContract.disbandCollection(id)) {
            transferTokens(collection.landIds, collection.botsIds, address(storageContract), collection.owner);
            removeFromMyListingStorage(collection.owner, collection.landIds, collection.botsIds);
            emit CollectionDisband(id, true);
        } else {
            emit CollectionDisband(id, false);
        }
    }

    function isAuthorizedToEdit(address collectionOwner) private view returns (bool) {
        return collectionOwner == _msgSender() || accountManagers.isManager(collectionOwner, _msgSender());
    }

    function createCollection(uint256[] memory landIds, uint256[] memory botIds, address[] memory players, bool perpetual, PaymentData memory pd) private {
        address assetsOwner = landsContract.ownerOf(landIds[0]);
        require(!xoiliumMarketplace.anyListingsExist(1, botIds) && !xoiliumMarketplace.anyListingsExist(0, landIds), "One of the assets listed for sale");
        require(areTokensAvailable(TradedNft.RBXL, landIds) && areTokensAvailable(TradedNft.RBFB, botIds), "One of the asset is present in other battle set or in the collection");
        require(isAuthorizedToEdit(assetsOwner), "Not authorized");
        require(landIds.length >= 2 && botIds.length >= 6 && landIds.length <= MAX_LANDS_IN_COLLECTION
            && botIds.length <= MAX_BOTS_IN_COLLECTION, "Collection should consist of 2 - 200 lands and 6 - 600 bots");

        transferTokens(landIds, botIds, assetsOwner, address(storageContract));
        addToMyListingStorage(assetsOwner, landIds, botIds);

        uint256 id = storageContract.createCollection(assetsOwner, landIds, botIds, perpetual, players, pd);
        emit CollectionCreated(id);
    }

    function addToMyListingStorage(address owner, uint256[] memory landIds, uint256[] memory botIds) private {
        myListingsStorage.addAll(TradedNft.RBXL, owner, landIds);
        myListingsStorage.addAll(TradedNft.RBFB, owner, botIds);
    }

    function removeFromMyListingStorage(address owner, uint256[] memory landIds, uint256[] memory botIds) private {
        myListingsStorage.removeAll(TradedNft.RBXL, owner, landIds);
        myListingsStorage.removeAll(TradedNft.RBFB, owner, botIds);
    }

    function areTokensAvailable(TradedNft nft, uint256[] memory ids) private view returns (bool) {
        for (uint i = 0; i < ids.length; i++) {
            TokenRentingStatus status;
            bool isTokenRented;
            if (nft == TradedNft.RBXL) {
                status = storageContract.getLandStatus(ids[i]);
                isTokenRented = landsContract.isTokenRented(ids[i]);
            } else {
                status = storageContract.getBotStatus(ids[i]);
                isTokenRented = botsContract.isTokenRented(ids[i]);
            }
            if (status != TokenRentingStatus.AVAILABLE || isTokenRented) {
                return false;
            }
        }
        return true;
    }


    function transferTokens(uint256[] memory landIds, uint256[] memory botIds, address from, address to) private {
        for (uint i = 0; i < landIds.length; i++) {
            landsContract.transferFrom(from, to, landIds[i]);
        }
        for (uint i = 0; i < botIds.length; i++) {
            botsContract.transferFrom(from, to, botIds[i]);
        }
    }

    function isSupportedCoin(RentingType rt, Coin value) private view returns (bool) {
        Coin[] memory coins = supportedCoins[rt];
        for (uint i = 0; i < coins.length; i++) {
            if (coins[i] == value) {
                return true;
            }
        }
        return false;
    }


    /**
     * @dev Pauses operations.
    */
    function setPaused(bool pause) external onlyOwner {
        if (pause) {
            _pause();
        } else {
            _unpause();
        }
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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

/// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

library Array256Lib {
    function contains(uint256[] memory array, uint256 value) internal pure returns (bool) {
        for (uint i = 0; i < array.length; i++) {
            if (array[i] == value) {
                return true;
            }
        }
        return false;
    }

    function remove(uint256[] memory array, uint256 value) internal pure returns (uint256[] memory){
        uint256[] memory newArray = new uint256[](array.length - 1);
        uint idx = 0;
        for (uint i = 0; i < array.length; i++) {
            if (array[i] != value) {
                newArray[idx++] = array[i];
            }
        }
        require(newArray.length == array.length - 1, "Failed to remove");
        return newArray;
    }

    function removeAll(uint256[] memory array, uint256[] memory valuesToRemove) internal pure returns (uint256[] memory) {
        uint256[] memory newArray = new uint256[](array.length - valuesToRemove.length);
        uint idx = 0;
        for (uint i = 0; i < array.length; i++) {
            if (!contains(valuesToRemove, array[i])) {
                newArray[idx++] = array[i];
            }
        }
        require(newArray.length == array.length - valuesToRemove.length, "Failed to remove");
        return newArray;
    }

    function add(uint256[] memory array, uint256 value) internal pure returns (uint256[] memory){
        uint256[] memory newArray = new uint256[](array.length + 1);
        for (uint i = 0; i < array.length; i++) {
            newArray[i] = array[i];
        }
        newArray[array.length] = value;
        return newArray;
    }

    function addAll(uint256[] memory array, uint256[] memory valuesToAdd) internal pure returns (uint256[] memory){
        uint256[] memory newArray = new uint256[](array.length + valuesToAdd.length);
        for (uint i = 0; i < array.length; i++) {
            newArray[i] = array[i];
        }
        for (uint i = array.length; i < array.length + valuesToAdd.length; i++) {
            newArray[i] = valuesToAdd[i - array.length];
        }
        return newArray;
    }

    function containsAddress(address[] memory array, address value) internal pure returns (bool) {
        for (uint i = 0; i < array.length; i++) {
            if (array[i] == value) {
                return true;
            }
        }
        return false;
    }

    function removeAddr(address[] memory array, address value) internal pure returns (address[] memory){
        address[] memory newArray = new address[](array.length - 1);
        uint idx = 0;
        for (uint i = 0; i < array.length; i++) {
            if (array[i] != value) {
                newArray[idx++] = array[i];
            }
        }
        return newArray;
    }
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

//import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC721Enumerable.sol";

interface IERC721Rentable is IERC721Enumerable {
    function isTokenRented(uint256 tokenId) external view returns (bool);

    function safeTransferFromForRent(address from, address to, uint256 tokenId, bytes memory _data) external;
}

/// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;



interface IAccountManagers {
    function addManagers(address[] memory managers) external;

    function removeManagers(address[] memory managers) external;

    function totalManagers(address account) external view returns (uint256);

    function isManager(address account, address manager) external view returns (bool);

    function getManagers(address account, uint from, uint to) external view returns (address[] memory);
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


import "./IXoiliumMarketplaceStorageTypes.sol";

interface IXoiliumMarketplace is IXoiliumMarketplaceStorageTypes {
    function anyListingsExist(uint8 nft, uint256[] memory tokenIds) external view returns (bool);

    function validListingExists(uint8 nft, uint256 tokenId) external view returns (bool);

    function getListing(uint8 nft, uint256 tokenId) external view returns (Listing memory);
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