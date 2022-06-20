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
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
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


abstract contract AccessControl is Context {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }


    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
            string(
                abi.encodePacked(
                    "AccessControl: account ",
                    Strings.toHexString(uint160(account), 20),
                    " is missing role ",
                    Strings.toHexString(uint256(role), 32)
                )
            )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }


    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
        }
    }
}


contract RBAC is AccessControl {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    modifier onlyAdmin {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Sender is not a admin");
        _;
    }

    modifier onlyManager {
        require(hasRole(MANAGER_ROLE, _msgSender()), "Sender is not a manager");
        _;
    }

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
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
        //        address[] whitelistedRenters;
    }

    struct PaymentData {
        RentingType rentingType;
        Coin coin;
        uint256 price;
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


contract RentingContractStorage is Context, IRentingContract, RBAC {

    using EnumerableSet for EnumerableSet.UintSet;
    using Array256Lib for uint256[];

    mapping(uint256 => TokenRentingStatus) private landsInfos;
    mapping(uint256 => TokenRentingStatus) private botsInfos;

    mapping(uint256 => ListingInfo) private listingInfo;
    mapping(uint256 => RentingInfo) private rentingInfo;

    mapping(uint256 => Collection) private allCollections;

    uint256 collectionIdCounter = 1;

    uint256[] private rentedLands;

    mapping(uint256 => uint256) private rentedLandsIndex;

    mapping(address => EnumerableSet.UintSet) private _rentedBattleSetsOwnersMapping;


    function getListingInfo(uint256 landId) public view returns (ListingInfo memory) {
        return listingInfo[landId];
    }

    function deleteListingInfo(uint256 landId) external onlyManager {
        delete listingInfo[landId];
    }


    function getRentingInfo(uint256 landId) public view returns (RentingInfo memory) {
        return rentingInfo[landId];
    }


    function setTokensState(BattleSet memory battleSet, TokenRentingStatus stage) private {
        setLandState(battleSet.landId, stage);
        for (uint i = 0; i < battleSet.botsIds.length; i++) {
            setBotState(battleSet.botsIds[i], stage);
        }
    }

    function setLandState(uint256 landId, TokenRentingStatus stage) private {
        landsInfos[landId] = stage;
    }

    function setBotState(uint256 botId, TokenRentingStatus stage) private {
        botsInfos[botId] = stage;
    }

    function getLandStatus(uint256 landId) public view returns (TokenRentingStatus) {
        return landsInfos[landId];
    }

    function getBotStatus(uint256 botId) external view returns (TokenRentingStatus) {
        return botsInfos[botId];
    }

    function createListingInfo(BattleSet memory bs, RentingType rt, address owner, Coin coin, uint256 _price, bool _perpetual) external onlyManager {
        _createListingInfo(bs, rt, owner, coin, _price, _perpetual);
    }

    function _createListingInfo(BattleSet memory bs, RentingType rt, address owner, Coin coin, uint256 _price, bool _perpetual) private {
        listingInfo[bs.landId] = ListingInfo({
        battleSet : bs,
        rentingType : rt,
        listingTs : block.timestamp,
        owner : owner,
        chargeCoin : coin,
        price : _price,
        perpetual : _perpetual
        //        whitelistedRenters : new address[](0)
        });

        setTokensState(bs, TokenRentingStatus.LISTED_BATTLE_SET);
    }

    function createRenting(BattleSet memory bs, RentingType rt, Coin coin, uint256 price, address owner, address renter,
        uint256 rentingEnd, uint256 collectionId, bool perpetual) external onlyManager {
        rentingInfo[bs.landId] = RentingInfo({
        battleSet : bs,
        rentingType : rt,
        chargeCoin : coin,
        price : price,
        owner : owner,
        renter : renter,
        rentingTs : block.timestamp,
        renewTs : 0,
        rentingEndTs : rentingEnd,
        cancelTs : 0,
        collectionId : collectionId,
        perpetual : perpetual
        });

        addTokenFromRentedTokensList(bs.landId);

        setTokensState(bs, TokenRentingStatus.RENTED);

        _rentedBattleSetsOwnersMapping[owner].add(bs.landId);
    }


    function setRentingCancelTs(uint256 id, uint256 cancelTs) external onlyManager {
        rentingInfo[id].cancelTs = cancelTs;
    }

    function renewRenting(uint256 id, uint256 renewTs, uint256 rentingEndTs) external onlyManager {
        RentingInfo storage rt = rentingInfo[id];
        rt.renewTs = renewTs;
        rt.rentingEndTs = rentingEndTs;
    }

    function rentedLandsByOwner(address owner) external view returns (uint256) {
        return _rentedBattleSetsOwnersMapping[owner].length();
    }

    function rentedOwnersLandsByIndex(address owner, uint256 idx) external view returns (uint256) {
        return _rentedBattleSetsOwnersMapping[owner].at(idx);
    }

    function editCollection(uint256 id, Coin coin, uint256 price, RentingType rentingType, bool perpetual) external onlyManager {
        Collection storage collection = allCollections[id];
        collection.chargeCoin = coin;
        collection.price = price;
        collection.rentingType = rentingType;
        collection.perpetual = perpetual;
    }


    function createCollection(address assetsOwner, uint256[] memory _landIds, uint256[] memory _botIds,
        bool _perpetual, uint share, address[] memory players, PaymentData memory pd) external onlyManager returns (uint256) {
        uint256 newId = ++collectionIdCounter;
        allCollections[newId] = Collection({
        id : newId,
        owner : assetsOwner,
        rentingType : pd.rentingType,
        landIds : _landIds,
        botsIds : _botIds,
        rentedLandIds : new uint[](0),
        rentedBotsIds : new uint[](0),
        landsToRemove : new uint[](0),
        botsToRemove : new uint[](0),
        chargeCoin : pd.coin,
        price : pd.price,
        perpetual : _perpetual,
        share : share,
        whitelist : players,
        disbandTs : 0
        });

        for (uint i = 0; i < _landIds.length; i++) {
            setLandState(_landIds[i], TokenRentingStatus.LISTED_COLLECTION);
        }
        for (uint i = 0; i < _botIds.length; i++) {
            setBotState(_botIds[i], TokenRentingStatus.LISTED_COLLECTION);
        }
        return newId;
    }

    function addAssetsToCollection(uint id, uint256[] memory _landIds, uint256[] memory _botIds) external onlyManager {
        for (uint i = 0; i < _landIds.length; i++) {
            allCollections[id].landIds.push(_landIds[i]);
        }
        for (uint i = 0; i < _botIds.length; i++) {
            allCollections[id].botsIds.push(_botIds[i]);
        }
    }

    function getCollection(uint256 id) public view returns (Collection memory) {
        return allCollections[id];
    }

    function removeListedLand(uint id, uint256 landIdToRemove) external onlyManager {
        Collection storage collection = allCollections[id];
        for (uint i = 0; i < collection.landIds.length; i++) {
            if (collection.landIds[i] == landIdToRemove) {
                collection.landIds[i] = collection.landIds[collection.landIds.length];
                delete collection.landIds[collection.landIds.length];
            }
        }
    }

    function pushToBeRemovedLands(uint id, uint256 landIdToRemove) external onlyManager {
        allCollections[id].landsToRemove.push(landIdToRemove);
    }

    function pushToBeRemovedBots(uint id, uint256 botIdToRemove) external onlyManager {
        allCollections[id].botsToRemove.push(botIdToRemove);
    }

    function removeListedBot(uint id, uint256 botIdToRemove) external onlyManager {
        Collection storage collection = allCollections[id];
        for (uint i = 0; i < collection.botsIds.length; i++) {
            if (collection.botsIds[i] == botIdToRemove) {
                collection.botsIds[i] = collection.botsIds[collection.botsIds.length];
                delete collection.botsIds[collection.botsIds.length];
            }
        }
    }

    function addPlayersToCollection(uint id, address[] memory players) external onlyManager {
        for (uint i = 0; i < players.length; i++) {
            allCollections[id].whitelist.push(players[i]);
        }
    }

    function removePlayersFromCollection(uint id, address player) external onlyManager {
        Collection storage collection = allCollections[id];
        for (uint i = 0; i < collection.whitelist.length; i++) {
            if (collection.whitelist[i] == player) {
                collection.whitelist[i] = collection.whitelist[collection.whitelist.length];
                delete collection.whitelist[collection.whitelist.length];
                return;
            }
        }
    }

    function updateCollectionRentedAssets(uint256 id, uint256[] memory availableLands, uint256[] memory availableBotsIds,
        uint256[] memory rentedLandIds, uint256[] memory rentedBotsIds) external onlyManager {
        Collection storage collection = allCollections[id];
        collection.landIds = availableLands;
        collection.botsIds = availableBotsIds;
        collection.rentedLandIds = rentedLandIds;
        collection.rentedBotsIds = rentedBotsIds;
    }

    function processCollectionRentalEnd(uint256 collectionId, RentingInfo memory ri) private {
        Collection storage collection = allCollections[ri.collectionId];

        // process lands
        if (Array256Lib.contains(collection.landsToRemove, ri.battleSet.landId) || collection.disbandTs != 0) {
            collection.landsToRemove = Array256Lib.remove(collection.landsToRemove, ri.battleSet.landId);
            setLandState(ri.battleSet.landId, TokenRentingStatus.AVAILABLE);
        } else {
            collection.rentedLandIds = Array256Lib.remove(collection.rentedLandIds, ri.battleSet.landId);
            collection.landIds.push(ri.battleSet.landId);
            setLandState(ri.battleSet.landId, TokenRentingStatus.LISTED_COLLECTION);
        }

        for (uint i = 0; i < ri.battleSet.botsIds.length; i++) {
            if (Array256Lib.contains(collection.botsToRemove, ri.battleSet.botsIds[i]) || collection.disbandTs != 0) {
                collection.botsToRemove = Array256Lib.remove(collection.botsToRemove, ri.battleSet.botsIds[i]);
                setBotState(ri.battleSet.botsIds[i], TokenRentingStatus.AVAILABLE);
            } else {
                collection.rentedBotsIds = Array256Lib.remove(collection.rentedBotsIds, ri.battleSet.botsIds[i]);
                collection.botsIds.push(ri.battleSet.botsIds[i]);
                setBotState(ri.battleSet.botsIds[i], TokenRentingStatus.LISTED_COLLECTION);
            }
        }

        if (collection.disbandTs != 0 && collection.rentedLandIds.length == 0) {
            delete allCollections[collectionId];
        }
    }

    function disbandCollection(uint256 id) external onlyManager {
        Collection storage collection = allCollections[id];
        if (collection.rentedLandIds.length == 0) {
            delete allCollections[id];
        } else {
            allCollections[id].disbandTs = block.timestamp;
        }
    }

    function getTotalRentings() external view returns (uint256) {
        return rentedLands.length;
    }

    function rentedLandByIdx(uint idx) external view returns (uint256) {
        return rentedLands[idx];
    }

    function addTokenFromRentedTokensList(uint256 tokenId) private {
        rentedLandsIndex[tokenId] = rentedLands.length;
        rentedLands.push(tokenId);
    }

    function _removeTokenFromRentedTokensList(uint256 tokenId) private {
        uint256 lastTokenIndex = rentedLands.length - 1;
        uint256 tokenIndex = rentedLandsIndex[tokenId];

        uint256 lastTokenId = rentedLands[lastTokenIndex];

        rentedLands[tokenIndex] = lastTokenId;
        rentedLandsIndex[lastTokenId] = tokenIndex;

        delete rentedLandsIndex[tokenId];
        rentedLands.pop();
    }

    function completeRenting(uint256 landId) external onlyManager {
        delete rentingInfo[landId];
        _removeTokenFromRentedTokensList(landId);

        RentingInfo memory ri = getRentingInfo(landId);

        _rentedBattleSetsOwnersMapping[ri.owner].remove(ri.battleSet.landId);

        if (ri.collectionId != 0) {
            processCollectionRentalEnd(ri.collectionId, ri);
        } else {
            if (ri.cancelTs == 0 && ri.perpetual) {
                _createListingInfo(ri.battleSet, ri.rentingType, ri.owner, ri.chargeCoin, ri.price, ri.perpetual);
            } else {
                setTokensState(ri.battleSet, TokenRentingStatus.AVAILABLE);
            }
        }
    }

}