/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

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
     * by making the `nonReentrant` function external, and make it call a
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


/**
 * @dev Interface of an Lands ERC721 compliant contract.
 */
interface IERC721RentingContract {

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function isTokenRented(uint256 tokenId) external view returns (bool);

    function transferFrom(address from, address to, uint256 tokenId) external;
}

interface IAccountManagers {
    function isManager(address account, address manager) external view returns (bool);
}

interface IRentingContract {

    event CollectionCreated(uint256 id);
    event CollectionUpdated(uint256 id);
    event CollectionPlayersUpdated(uint256 id);
    event CollectionBotsUpdated(uint256 id);
    event CollectionLandsUpdated(uint256 id);
    event CollectionDisband(uint256 id);

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
}




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
}


interface IXoiliumMarketplace {
    function anyListingsExist(uint8 nft, uint256[] memory tokenIds) external view returns (bool);

    function validListingExists(uint8 nft, uint256 tokenId) external view returns (bool);
}


interface IRentingContractStorage is IRentingContract {

    function getLandStatus(uint256 landId) external view returns (TokenRentingStatus);

    function getBotStatus(uint256 botId) external view returns (TokenRentingStatus);

    function createCollection(address assetsOwner, uint256[] memory landIds, uint256[] memory botIds,
        bool perpetual, address[] memory players, PaymentData memory pd) external returns (uint256);

    function addAssetsToCollection(uint id, uint256[] memory landIds, uint256[] memory botIds) external;

    function getCollection(uint256 id) external view returns (Collection memory);

    function removeListedLand(uint id, uint256 landIdToRemove) external;

    function pushToBeRemovedLands(uint id, uint256 landIdToRemove) external;

    function getRentingInfo(uint256 landId) external view returns (RentingInfo memory);

    function pushToBeRemovedBots(uint id, uint256 botIdToRemove) external;

    function removeListedBot(uint id, uint256 botIdToRemove) external;

    function addPlayersToCollection(uint id, address[] memory players) external;

    function removePlayersFromCollection(uint id, address player) external;

    function disbandCollection(uint256 id) external returns (bool);

    function editCollection(uint256 id, Coin coin, uint256 price, RentingType rentingType, bool perpetual, uint revenueShare) external;
}

// TODO pausable, ownable, rbac
contract CollectionOwnerOperator is Context, IRentingContract, ReentrancyGuard {

    uint private constant MAX_LANDS_IN_COLLECTION = 300;
    uint private constant MAX_BOTS_IN_COLLECTION = 600;

    mapping(Coin => address) paymentContracts;
    IRentingContractStorage internal storageContract;
    IERC721RentingContract public landsContract;
    IERC721RentingContract public botsContract;
    IXoiliumMarketplace public xoiliumMarketplace;
    IAccountManagers public accountManagers;

    Coin[] public fixedPriceRentalsSupportedCoins = [Coin.WETH];
    Coin[] public revShareRentalsSupportedCoins = [Coin.RBLS, Coin.XOIL];

    constructor(address storageContractAddress, address xoiliumMarketplaceAddress, address accountManagersAddress, address landsContractAddress, address botsContractAddress,
        address xoilAddress, address rblsAddress, address wethAddress) {
        paymentContracts[Coin.XOIL] = xoilAddress;
        paymentContracts[Coin.RBLS] = rblsAddress;
        paymentContracts[Coin.WETH] = wethAddress;
        storageContract = IRentingContractStorage(storageContractAddress);
        landsContract = IERC721RentingContract(landsContractAddress);
        botsContract = IERC721RentingContract(botsContractAddress);
        xoiliumMarketplace = IXoiliumMarketplace(xoiliumMarketplaceAddress);
        accountManagers = IAccountManagers(accountManagersAddress);
    }

    // TODO onlyOwner
    function setMarketplaceAddress(address xoiliumMarketplaceAddress) external {
        xoiliumMarketplace = IXoiliumMarketplace(xoiliumMarketplaceAddress);
    }


    // TODO onlyOwner
    function setSupportedCoins(Coin[] memory fixedPriceCoins, Coin[] memory revShareCoins) external {
        fixedPriceRentalsSupportedCoins = fixedPriceCoins;
        revShareRentalsSupportedCoins = revShareCoins;
    }

    function editCollection(uint256 id, Coin coin, uint256 price, RentingType rentingType, bool perpetual, uint revenueShare) external {
        Collection memory collection = storageContract.getCollection(id);
        require(isAuthorizedToEdit(collection.owner), "Not authorized");
        require(rentingType == RentingType.FIXED_PRICE || (revenueShare > 0 && revenueShare < 100),
            "Revenue share should be between 0-100 with revenue share renting type");
        require(price > 0, "Price should be positive");
        require(paymentContracts[coin] != address(0), "Not supported payment coin");
        if (rentingType == RentingType.FIXED_PRICE) {
            require(coin == Coin.WETH, "Only WETH is supported for the fixed price rentals");
        } else {
            require(coin == Coin.RBLS || coin == Coin.XOIL, "Only RBLS and XOIL are supported for the revenue share rentals");
        }

        storageContract.editCollection(id, coin, price, rentingType, perpetual, revenueShare);
        emit CollectionUpdated(id);
    }

    function createCollectionFixedPrice(uint256[] memory landIds, uint256[] memory botIds, address[] memory players,
        Coin coin, uint256 price, bool perpetual) nonReentrant external returns (uint256) {
        require(containsCoin(fixedPriceRentalsSupportedCoins, coin), "Not supported payment currency");

        PaymentData memory pd = PaymentData({rentingType : RentingType.FIXED_PRICE, coin : coin, price : price, revenueShare : 0});
        return createCollection(landIds, botIds, players, perpetual, pd);
    }

    function createCollectionShareRental(uint256[] memory landIds, uint256[] memory botIds, address[] memory players,
        Coin coin, uint256 guaranteeAmount, bool perpetual, uint revenueShare) nonReentrant external returns (uint256) {
        require(containsCoin(revShareRentalsSupportedCoins, coin), "Not supported payment currency");
        require(revenueShare > 0 && revenueShare < 100, "Revenue share should be between 0-100 with revenue share renting type");

        PaymentData memory pd = PaymentData({rentingType : RentingType.REVENUE_SHARE, coin : coin, price : guaranteeAmount, revenueShare : revenueShare});
        return createCollection(landIds, botIds, players, perpetual, pd);
    }

    function createCollection(uint256[] memory landIds, uint256[] memory botIds, address[] memory players,
        bool perpetual, PaymentData memory pd) internal returns (uint256) {
        address assetsOwner = landsContract.ownerOf(landIds[0]);
        require(!xoiliumMarketplace.anyListingsExist(1, botIds), "One of the bots listed for sale");
        require(!xoiliumMarketplace.anyListingsExist(0, landIds), "One of the land is listed for sale");
        require(isAuthorizedToEdit(_msgSender()), "Not authorized");
        require(landIds.length >= 2 && botIds.length >= 6 && landIds.length <= MAX_LANDS_IN_COLLECTION
            && botIds.length <= MAX_BOTS_IN_COLLECTION, "Collection should consist minimum of 2 lands and 6 bots");
        require(pd.price > 0, "Price should be positive");
        require(areLandsAvailable(landIds), "One of the land is present in other battle set or in the collection");
        require(areBotsAvailable(botIds), "One of the bots is present in other battle set or in the collection");
        require(paymentContracts[pd.coin] != address(0), "Not supported payment coin");
        require(!landsAreRented(landIds), "One of land is rented");
        require(!botsAreRented(botIds), "One of bots is rented");

        transferTokens(landIds, botIds, _msgSender(), address(storageContract));

        uint256 id = storageContract.createCollection(assetsOwner, landIds, botIds, perpetual, players, pd);

        emit CollectionCreated(id);

        return id;
    }

    function addLandsToCollection(uint id, uint256[] memory landIds) external returns (bool) {
        Collection memory collection = storageContract.getCollection(id);
        require(!xoiliumMarketplace.anyListingsExist(0, landIds), "One of the land is listed for sale");
        require(isAuthorizedToEdit(collection.owner), "Not authorized");
        require(collection.landIds.length + landIds.length <= MAX_LANDS_IN_COLLECTION, "Lands number exceeds the limit");
        require(areLandsAvailable(landIds), "One of the land is present in other battle set or in the collection");
        require(!landsAreRented(landIds), "One of land is rented");

        transferTokens(landIds, new uint256[](0), _msgSender(), address(storageContract));
        storageContract.addAssetsToCollection(id, landIds, new uint256[](0));

        emit CollectionLandsUpdated(id);

        return true;
    }

    function addBotsToCollection(uint id, uint256[] memory botIds) external {
        Collection memory collection = storageContract.getCollection(id);
        require(!xoiliumMarketplace.anyListingsExist(1, botIds), "One of the bots listed for sale");
        require(isAuthorizedToEdit(collection.owner), "Not authorized");
        require(collection.botsIds.length + botIds.length <= MAX_BOTS_IN_COLLECTION, "Bots number exceeds the limit");
        require(areBotsAvailable(botIds), "One of the bots is present in other battle set or in the collection");
        require(!botsAreRented(botIds), "One of land is rented");

        transferTokens(new uint256[](0), botIds, _msgSender(), address(storageContract));
        storageContract.addAssetsToCollection(id, new uint256[](0), botIds);

        emit CollectionBotsUpdated(id);
    }

    function removeLandFromCollection(uint id, uint256 landIdToRemove) nonReentrant external {
        Collection memory collection = storageContract.getCollection(id);
        require(isAuthorizedToEdit(collection.owner), "Not authorized");
        require(collection.landIds.length + collection.rentedLandIds.length - 1 >= 2, "The target size of lands in collection is below of minimum");

        TokenRentingStatus status = storageContract.getLandStatus(landIdToRemove);
        if (status == TokenRentingStatus.LISTED_COLLECTION) {
            storageContract.removeListedLand(id, landIdToRemove);

            landsContract.transferFrom(address(storageContract), collection.owner, landIdToRemove);
        } else if (status == TokenRentingStatus.RENTED) {
            RentingInfo memory ri = storageContract.getRentingInfo(landIdToRemove);
            require(ri.collectionId == id, "The land is not contained in specified collection");

            if (!Array256Lib.contains(collection.landsToRemove, landIdToRemove)) {
                storageContract.pushToBeRemovedLands(id, landIdToRemove);
            }
        }
        emit CollectionLandsUpdated(id);
    }

    function isAuthorizedToEdit(address collectionOwner) private view returns(bool) {
        return collectionOwner == _msgSender() || accountManagers.isManager(collectionOwner, _msgSender());
    }

    function removeBotFromCollection(uint id, uint256 botIdToRemove) external {
        Collection memory collection = storageContract.getCollection(id);
        require(isAuthorizedToEdit(collection.owner), "Not authorized");
        require(collection.botsIds.length + collection.rentedBotsIds.length - 1 >= 6, "The target size of bots in collection is below of minimum");

        if (Array256Lib.contains(collection.botsIds, botIdToRemove)) {//not rented
            storageContract.removeListedBot(id, botIdToRemove);

            botsContract.transferFrom(address(storageContract), collection.owner, botIdToRemove);
        } else if (Array256Lib.contains(collection.botsToRemove, botIdToRemove)) {
            return;
        } else if (Array256Lib.contains(collection.rentedBotsIds, botIdToRemove)) {
            storageContract.pushToBeRemovedBots(id, botIdToRemove);
        }
        emit CollectionBotsUpdated(id);
    }

    function addPlayersToCollection(uint id, address[] memory players) external {
        Collection memory collection = storageContract.getCollection(id);
        require(players.length >= 0, "Wrong number of bots");
        require(isAuthorizedToEdit(collection.owner), "Not authorized");

        storageContract.addPlayersToCollection(id, players);
        emit CollectionPlayersUpdated(id);
    }

    function removePlayersFromCollection(uint id, address player) external {
        Collection memory collection = storageContract.getCollection(id);
        require(isAuthorizedToEdit(collection.owner), "Not authorized");

        storageContract.removePlayersFromCollection(id, player);
        emit CollectionPlayersUpdated(id);
    }


    function disbandCollection(uint256 id) nonReentrant external {
        Collection memory collection = storageContract.getCollection(id);
        require(isAuthorizedToEdit(collection.owner), "Not authorized");
        if (storageContract.disbandCollection(id)) {
            transferTokens(collection.landIds, collection.botsIds, address(storageContract), collection.owner);
            emit CollectionDisband(id);
        }
    }

    function areLandsAvailable(uint256[] memory landIds) private view returns (bool) {
        for (uint i = 0; i < landIds.length; i++) {
            if (storageContract.getLandStatus(landIds[i]) != TokenRentingStatus.AVAILABLE) {
                return false;
            }
        }
        return true;
    }

    function areBotsAvailable(uint256[] memory botIds) private view returns (bool) {
        for (uint i = 0; i < botIds.length; i++) {
            if (storageContract.getBotStatus(botIds[i]) != TokenRentingStatus.AVAILABLE) {
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

    function containsCoin(Coin[] memory array, Coin value) private pure returns (bool) {
        for (uint i = 0; i < array.length; i++) {
            if (array[i] == value) {
                return true;
            }
        }
        return false;
    }

    function botsAreRented(uint256[] memory botIds) private view returns (bool) {
        for (uint i = 0; i < botIds.length; i++) {
            if (botsContract.isTokenRented(botIds[i])) {
                return true;
            }
        }
        return false;
    }

    function landsAreRented(uint256[] memory landIds) private view returns (bool) {
        for (uint i = 0; i < landIds.length; i++) {
            if (landsContract.isTokenRented(landIds[i])) {
                return true;
            }
        }
        return false;
    }
}