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


interface IRentingContract {

    // TODO think how it will be expendable in case we will have storage in deifferent contract
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
}


interface IRentingContractStorage is IRentingContract {
    function getRentingInfo(uint256 landId) external view returns (RentingInfo memory);

    function getListingInfo(uint256 landId) external view returns (ListingInfo memory);

    function getCollection(uint256 id) external view returns (Collection memory);

    function rentedLandsByOwner(address owner) external view returns (uint);

    function rentedOwnersLandsByIndex(address owner, uint256 idx) external view returns (uint256);
}

contract RentingStorageViewer is IRentingContract {

    IRentingContractStorage internal storageContract;

    constructor(address storageContractAddress) {
        storageContract = IRentingContractStorage(storageContractAddress);
    }


    function getListingInfo(uint256 landId) public view returns (ListingInfo memory) {
        return storageContract.getListingInfo(landId);
    }

    function getRentingInfo(uint256 landId) public view returns (RentingInfo memory) {
        return storageContract.getRentingInfo(landId);
    }

    function getCollection(uint256 id) public view returns (Collection memory) {
        return storageContract.getCollection(id);
    }



    function rentedLandsByOwner(address owner) external view returns (uint) {
        return storageContract.rentedLandsByOwner(owner);
    }

    function rentedOwnersLandsByIndex(address owner, uint256 idx) external view returns (uint256) {
        return storageContract.rentedOwnersLandsByIndex(owner, idx);
    }
}