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
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex;
                // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

/**
 * @dev Interface of an Lands ERC721 compliant contract.
 */
interface IERC721RentingContract {

    function safeTransferFromForRent(address from, address to, uint256 tokenId, bytes memory _data) external;

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function isTokenRented(uint256 tokenId) external view returns (bool);

    function safeTransferFrom(address from, address to, uint256 tokenId) external;
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
}


interface IRentingContractStorage is IRentingContract {

    function getLandStatus(uint256 landId) external view returns (TokenRentingStatus);

    function getBotStatus(uint256 botId) external view returns (TokenRentingStatus);

    function getListingInfo(uint256 landId) external view returns (ListingInfo memory);

    function deleteListingInfo(uint256 landId) external;

    function getRentingInfo(uint256 landId) external view returns (RentingInfo memory);

    function createListingInfo(BattleSet memory bs, RentingType rt, address owner, Coin coin, uint256 _price, bool _perpetual, address[] memory whitelist) external;

    function setRentingCancelTs(uint256 id, uint256 cancelTs) external;

    function completeRenting(uint256 landId) external;
}


// TODO pausable, ownable, rbac
contract BattleSetManagerContract is Context,  IRentingContract, TokensManager {


    mapping(Coin => address) paymentContracts;
    IRentingContractStorage internal storageContract;

    event BattleSetCreated(uint256 indexed landId, address owner, Coin coin, uint256 price, bool perpetual);
    event BattleSetDelist(uint256 indexed landId);
    event RentEnd(uint256 indexed landId, uint256 collectionId, address renter, address owner);

    constructor(address storageContractAddress, address landsContractAddress, address botsContractAddress, address xoilAddress, address rblsAddress)
    TokensManager(landsContractAddress, botsContractAddress) {
        paymentContracts[Coin.XOIL] = xoilAddress;
        paymentContracts[Coin.RBLS] = rblsAddress;
        storageContract = IRentingContractStorage(storageContractAddress);
    }

    // only for the battle sets
    function cancelBattleSetListing(uint256 landId) external returns (bool) {
        TokenRentingStatus status = storageContract.getLandStatus(landId);
        if (status == TokenRentingStatus.AVAILABLE) {
            return false;
        } else if (status == TokenRentingStatus.LISTED_BATTLE_SET) {
            require(storageContract.getListingInfo(landId).owner == _msgSender(), "Only owner can cancel listing");
            storageContract.deleteListingInfo(landId);
            emit BattleSetDelist(landId);
            return true;
        } else if (status == TokenRentingStatus.RENTED) {
            RentingInfo memory ri = storageContract.getRentingInfo(landId);
            require(ri.owner == _msgSender(), "Only owner can cancel listing");
            require(ri.collectionId == 0, "The land is from collection");
            require(ri.cancelTs != 0, "Already cancelled");
            storageContract.setRentingCancelTs(landId, block.timestamp);

            emit BattleSetDelist(landId);
            return true;
        }
        return false;
    }


    function listBattleSetFixedPrice(uint256 landId, uint256[] memory botIds, Coin coin, uint256 price,
        bool perpetual, address[] memory wallets) external {
        require(botIds.length == 3, "Bots number should be 3");
        require(price > 0, "Price should be positive");
        require(areTokensAvailable(landId, botIds), "One of the asset is present in other battle set or in the collection");
        require(landsContract.ownerOf(landId) == _msgSender() && !landsContract.isTokenRented(landId), "Sender is not an owner");
        require(super.userOwnsBots(botIds, _msgSender()), "Sender is not an owner");
        require(paymentContracts[coin] != address(0), "Not supported payment coin");
        require(wallets.length <= 100, "Incorrect amount of whitelisted addresses");
//
        BattleSet memory bs = BattleSet({landId : landId, botsIds : botIds});
//        storageContract.createListingInfo(bs, RentingType.FIXED_PRICE, _msgSender(), coin, price, perpetual, wallets);
        emit BattleSetCreated(landId,  _msgSender(), coin, price, perpetual);
    }


    function completeRentings(uint256[] memory landIds) external {
        for (uint i = 0; i < landIds.length; i++) {
            if (storageContract.getRentingInfo(landIds[i]).rentingEndTs <= block.timestamp) {
                completeRenting(landIds[i]);
            }
        }
    }

    function completeRenting(uint256 landId) private {
        RentingInfo memory ri = storageContract.getRentingInfo(landId);
        if (ri.rentingTs == 0 || ri.rentingEndTs > block.timestamp) {
            return;
        }

        landsContract.safeTransferFrom(ri.renter, ri.owner, ri.battleSet.landId);
        for (uint i = 0; i < 3; i++) {
            botsContract.safeTransferFrom(ri.renter, ri.owner, ri.battleSet.botsIds[i]);
        }

        storageContract.completeRenting(landId);
        emit RentEnd(landId, ri.collectionId, ri.renter, ri.owner);
    }

    function areTokensAvailable(uint256 landId, uint256[] memory botIds) private view returns (bool) {
        if (storageContract.getLandStatus(landId) != TokenRentingStatus.AVAILABLE) {
            return false;
        }
        for (uint i = 0; i < botIds.length; i++) {
            if (storageContract.getBotStatus(botIds[i]) != TokenRentingStatus.AVAILABLE) {
                return false;
            }
        }
        return true;
    }
}