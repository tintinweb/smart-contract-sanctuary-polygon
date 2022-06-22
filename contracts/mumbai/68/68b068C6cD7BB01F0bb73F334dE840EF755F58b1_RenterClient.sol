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


library Array256Lib {
    function removeAll(uint256[] memory array, uint256[] memory valuesToRemove) internal pure returns (uint256[] memory) {
        uint256[] memory newArray = new uint256[](array.length - valuesToRemove.length);
        uint idx = 0;
        for (uint i = 0; i < array.length; i++) {
            if (!contains(valuesToRemove, array[i])) {
                newArray[idx++] = valuesToRemove[i];
            }
        }
        require(newArray.length == array.length - valuesToRemove.length, "Failed to remove");
        return newArray;
    }

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

    function add(uint256[] memory array, uint256 value) internal pure returns (uint256[] memory){
        uint256[] memory newArray = new uint256[](array.length + 1);
        for (uint i = 0; i < array.length; i++) {
            newArray[i] = array[i];
        }
        newArray[array.length + 1] = value;
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
}


interface IRentingContract {

    enum Coin {
        XOIL,
        RBLS,
        WETH,
        USDC
    }

    enum RentingType {
        FIXED_PRICE,
        SPLIT
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
        RentingType rentingType; // probaby change to uint
        Coin chargeCoin;// probaby change to uint
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
        uint share;
        bool perpetual;
        uint256 disbandTs;
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
    }

    struct PaymentData {
        RentingType rentingType;
        Coin coin;
        uint256 price;
    }
}


interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}


interface IRentingContractStorage is IRentingContract {

    function renewRenting(uint256 id, uint256 renewTs, uint256 rentingEndTs) external;

    function getRentingInfo(uint256 landId) external view returns (RentingInfo memory);

    function getCollection(uint256 id) external view returns (Collection memory);

    function createRenting(BattleSet memory bs, RentingType rt, Coin coin, uint256 price, address owner, address renter,
        uint256 rentingEnd, uint256 collectionId, bool perpetual, address[] memory whitelist) external;

    function deleteListingInfo(uint256 landId) external;

    function getListingInfo(uint256 landId) external view returns (ListingInfo memory);

    function updateCollectionRentedAssets(uint256 id, uint256[] memory availableLands, uint256[] memory availableBotsIds,
        uint256[] memory rentedLandIds, uint256[] memory rentedBotsIds) external;

    function rentedLandsByOwner(address owner) external view returns (uint);

    function rentedOwnersLandsByIndex(address owner, uint256 idx) external view returns (uint256);
}


interface IERC721RentingContract {

    function safeTransferFromForRent(address from, address to, uint256 tokenId, bytes memory _data) external;

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function isTokenRented(uint256 tokenId) external view returns (bool);

    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

abstract contract TokensManager {
    IERC721RentingContract public landsContract;
    IERC721RentingContract public botsContract;

    constructor(address landsContractAddress, address botsContractAddress) {
        landsContract = IERC721RentingContract(landsContractAddress);
        botsContract = IERC721RentingContract(botsContractAddress);
    }

    function userOwnsLands(uint256[] memory landIds, address owner) internal view returns (bool) {

        for (uint i = 0; i < landIds.length; i++) {
            if (landsContract.ownerOf(landIds[i]) != owner || landsContract.isTokenRented(landIds[i])) {
                return false;
            }
        }
        return true;
    }

    function userOwnsBots(uint256[] memory botIds, address owner) internal view returns (bool) {
        for (uint i = 0; i < botIds.length; i++) {
            if (botsContract.ownerOf(botIds[i]) != owner || botsContract.isTokenRented(botIds[i])) {
                return false;
            }
        }
        return true;
    }

    function safeTransferFromSetForRent(address from, address to, uint256 landId, uint256[] memory botIds) internal {
        landsContract.safeTransferFromForRent(from, to, landId, "");
        for (uint i = 0; i < botIds.length; i++) {
            botsContract.safeTransferFromForRent(from, to, botIds[i], "");
        }
    }
}

contract RenterClient is Context, IRentingContract, TokensManager {

    using Array256Lib for uint256[];

    //    uint private constant default_renting_duration = 7 days;
//    uint private constant DEFAULT_RENTING_DURATION = 5 hours;
//    uint private constant RENTING_RENEWAL_PERIOD_GAP = 4 hours;

    uint private constant DEFAULT_RENTING_DURATION = 5 minutes;
    uint private constant RENTING_RENEWAL_PERIOD_GAP = 4 minutes;

    mapping(Coin => address) paymentContracts;
    IRentingContractStorage internal storageContract;

    event RentBattleSetStart(uint256 indexed landId, uint256[] botIds, address renter, address owner);
    event RentCollectionStart(uint256 indexed landId, uint256[] botIds,  uint256 collectionId, address renter, address owner);
    event RentRenewed(uint256 indexed landId);

    constructor(address storageContractAddress, address landsContractAddress, address botsContractAddress, address xoilAddress, address rblsAddress)
    TokensManager(landsContractAddress, botsContractAddress) {
        paymentContracts[Coin.XOIL] = xoilAddress;
        paymentContracts[Coin.RBLS] = rblsAddress;
        storageContract = IRentingContractStorage(storageContractAddress);
    }


    function addressWhitelisted(address[] memory array, address value) internal pure returns (bool) {
        for (uint i = 0; i < array.length; i++) {
            if (array[i] == value) {
                return true;
            }
        }
        return false;
    }

    function rentBattleSet(uint256 landId) external returns (bool) {
        ListingInfo memory li = storageContract.getListingInfo(landId);
        require(li.listingTs != 0, "Listing not found");
        if (li.whitelist.length > 0) {
            require(addressWhitelisted(li.whitelist, _msgSender()), "Address not whitelisted");
        }

        IERC20 paymentContract = IERC20(paymentContracts[li.chargeCoin]);
        if (!paymentContract.transferFrom(_msgSender(), li.owner, li.price)) {
            return false;
        }

        storageContract.deleteListingInfo(landId);

        super.safeTransferFromSetForRent(li.owner, _msgSender(), li.battleSet.landId, li.battleSet.botsIds);

        storageContract.createRenting(li.battleSet, li.rentingType, li.chargeCoin, li.price, li.owner, _msgSender(), block.timestamp + DEFAULT_RENTING_DURATION,
            0, li.perpetual, li.whitelist);

        emit RentBattleSetStart(landId, li.battleSet.botsIds, _msgSender(), li.owner);
        return true;
    }


    function rentFromCollection(uint256 id, uint256 landId, uint256[] memory botsIds) external returns (bool) {
        Collection memory collection = storageContract.getCollection(id);
        require(collection.owner != address(0x0), "Collection not found");
        require(collection.disbandTs == 0, "Collection disbanded");
        if (collection.whitelist.length > 0) {
            require(addressWhitelisted(collection.whitelist, _msgSender()), "Address not whitelisted");
        }

        IERC20 paymentContract = IERC20(paymentContracts[collection.chargeCoin]);
        if (!paymentContract.transferFrom(_msgSender(), collection.owner, collection.price)) {
            return false;
        }

        super.safeTransferFromSetForRent(collection.owner, _msgSender(), landId, botsIds);

        storageContract.updateCollectionRentedAssets(id, Array256Lib.remove(collection.landIds, landId),
            Array256Lib.removeAll(collection.botsIds, botsIds), Array256Lib.add(collection.rentedLandIds, landId),
            Array256Lib.addAll(collection.rentedBotsIds, botsIds));


        BattleSet memory bs = BattleSet({landId : landId, botsIds : botsIds});
        storageContract.createRenting(bs, collection.rentingType, collection.chargeCoin, collection.price, collection.owner, _msgSender(),
            block.timestamp + DEFAULT_RENTING_DURATION, collection.id, collection.perpetual, new address[](0));

        emit RentCollectionStart(landId, botsIds, id, _msgSender(), collection.owner);
        return true;
    }

    function renewRental(uint256 landId) external returns (bool){
        RentingInfo memory ri = storageContract.getRentingInfo(landId);
        require(ri.rentingTs != 0, "Land is not rented");
        require(ri.perpetual, "The listing is not perpetual");
        require(ri.cancelTs == 0, "The listing is cancelled");
        require(ri.renewTs < ri.rentingEndTs - RENTING_RENEWAL_PERIOD_GAP, "Already renewed for next period");
        require(ri.renter == _msgSender(), "Caller is not renter");
        require(block.timestamp < ri.rentingEndTs && block.timestamp > ri.rentingEndTs - RENTING_RENEWAL_PERIOD_GAP, "Renew is not available yet");
        if (ri.collectionId != 0) {
            Collection memory collection = storageContract.getCollection(ri.collectionId);
            require(collection.disbandTs == 0, "Collection disbanded");
            require(addressWhitelistedInCollection(collection, _msgSender()), "Player not whitelisted to renew listing");
            require(!ifCollectionAssetNeedsToBeRemoved(ri.collectionId, ri.battleSet.landId, ri.battleSet.botsIds), "Some asset removed from collection");
        }

        IERC20 paymentContract = IERC20(paymentContracts[ri.chargeCoin]);
        if (!paymentContract.transferFrom(_msgSender(), ri.owner, ri.price)) {
            return false;
        }

        storageContract.renewRenting(landId, block.timestamp, ri.rentingEndTs + DEFAULT_RENTING_DURATION);

        emit RentRenewed(landId);
        return true;
    }


    function ifCollectionAssetNeedsToBeRemoved(uint256 collectionId, uint256 landId, uint256[] memory botIds) private view returns (bool) {
        Collection memory collection = storageContract.getCollection(collectionId);
        if (Array256Lib.contains(collection.landsToRemove, landId)) {
            return true;
        }
        for (uint i = 0; i < botIds.length; i++) {
            if (Array256Lib.contains(collection.botsToRemove, botIds[i])) {
                return true;
            }
        }
        return false;
    }


    function addressWhitelistedInCollection(Collection memory collection, address player) private pure returns (bool){
        for (uint i = 0; i < collection.whitelist.length; i++) {
            if (collection.whitelist[i] == player) {
                return true;
            }
        }
        return false;
    }
}