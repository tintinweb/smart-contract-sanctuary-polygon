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
        uint8 rentingType;
        uint8 chargeCoin;
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
        uint8 rentingType;
        uint8 chargeCoin;
        uint256 price;
        bool perpetual;
        uint256 disbandTs;
        uint revenueShare;
    }

    struct ListingInfo {
        BattleSet battleSet;
        uint8 rentingType;
        uint8 chargeCoin;
        uint256 listingTs;
        address owner;
        uint256 price;
        bool perpetual;
        address[] whitelist;
        uint revenueShare;
    }

    struct PaymentData {
        uint8 rentingType;
        uint8 coin;
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
        return newArray;
    }
}


contract RentingContractStorage is Context, IRentingContract, RBAC {


    using Array256Lib for uint256[];

    mapping(uint256 => TokenRentingStatus) private landsInfos;
    mapping(uint256 => TokenRentingStatus) private botsInfos;

    mapping(uint256 => ListingInfo) private listingInfo;
    mapping(uint256 => RentingInfo) private rentingInfo;

    mapping(uint256 => Collection) private allCollections;

    uint256 collectionIdCounter = 1;


    function getListingInfo(uint256 landId) public view returns (ListingInfo memory) {
        return listingInfo[landId];
    }

    function deleteListingInfo(uint256 landId) external onlyManager {
        ListingInfo memory li = listingInfo[landId];
        setTokensState(li.battleSet, TokenRentingStatus.AVAILABLE);
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

    function createListingInfo(BattleSet memory bs, uint8 rt, address owner, uint8 coin, uint256 price,
        bool perpetual, address[] memory whitelist, uint revenueShare) external onlyManager {
        _createListingInfo(bs, rt, owner, coin, price, perpetual, whitelist, revenueShare);
    }

    function _createListingInfo(BattleSet memory bs, uint8 rt, address owner, uint8 coin, uint256 price,
        bool perpetual, address[] memory whitelist, uint revenueShare) private {
        ListingInfo storage li = listingInfo[bs.landId];
        li.battleSet = bs;
        li.rentingType = rt;
        li.listingTs = block.timestamp;
        li.owner = owner;
        li.chargeCoin = coin;
        li.price = price;
        li.perpetual = perpetual;
        li.whitelist = whitelist;
        li.revenueShare = revenueShare;

        setTokensState(bs, TokenRentingStatus.LISTED_BATTLE_SET);
    }

    function createRenting(BattleSet memory bs, uint8 rt, uint8 coin, uint256 price, address owner, address renter,
        uint256 rentingEnd, uint256 collectionId, bool perpetual, address[] memory whitelist, uint revenueShare) external onlyManager {
        RentingInfo storage ri = rentingInfo[bs.landId];
        ri.battleSet = bs;
        ri.rentingType = rt;
        ri.chargeCoin = coin;
        ri.price = price;
        ri.owner = owner;
        ri.renter = renter;
        ri.rentingTs = block.timestamp;
        ri.rentingEndTs = rentingEnd;
        ri.collectionId = collectionId;
        ri.perpetual = perpetual;
        ri.whitelist = whitelist;
        ri.revenueShare = revenueShare;

        setTokensState(bs, TokenRentingStatus.RENTED);
    }


    function setRentingCancelTs(uint256 id, uint256 cancelTs) external onlyManager {
        rentingInfo[id].cancelTs = cancelTs;
    }

    function renewRenting(uint256 id, uint256 renewTs, uint256 rentingEndTs) external onlyManager {
        RentingInfo storage rt = rentingInfo[id];
        rt.renewTs = renewTs;
        rt.rentingEndTs = rentingEndTs;
    }


    function editCollection(uint256 id, uint8 coin, uint256 price, uint8 rentingType, bool perpetual, uint revenueShare) external onlyManager {
        Collection storage collection = allCollections[id];
        collection.chargeCoin = coin;
        collection.price = price;
        collection.rentingType = rentingType;
        collection.perpetual = perpetual;
        collection.revenueShare = revenueShare;
    }


    function createCollection(address assetsOwner, uint256[] memory landIds, uint256[] memory botIds,
        bool perpetual, address[] memory players, PaymentData memory pd) external onlyManager returns (uint256) {
        uint256 newId = collectionIdCounter++;
        Collection storage collection = allCollections[newId];

        collection.id = newId;
        collection.owner = assetsOwner;
        collection.rentingType = pd.rentingType;
        collection.revenueShare = pd.revenueShare;
        collection.landIds = landIds;
        collection.botsIds = botIds;
        collection.rentedLandIds = new uint[](0);
        collection.rentedBotsIds = new uint[](0);
        collection.landsToRemove = new uint[](0);
        collection.botsToRemove = new uint[](0);
        collection.chargeCoin = pd.coin;
        collection.price = pd.price;
        collection.perpetual = perpetual;
        collection.whitelist = players;

        setState(landIds, botIds, TokenRentingStatus.LISTED_COLLECTION);

        return newId;
    }

    function addAssetsToCollection(uint id, uint256[] memory landIds, uint256[] memory botIds) external onlyManager {
        for (uint i = 0; i < landIds.length; i++) {
            allCollections[id].landIds.push(landIds[i]);
            setLandState(landIds[i], TokenRentingStatus.LISTED_COLLECTION);
        }
        for (uint i = 0; i < botIds.length; i++) {
            allCollections[id].botsIds.push(botIds[i]);
            setBotState(botIds[i], TokenRentingStatus.LISTED_COLLECTION);
        }
    }

    function getCollection(uint256 id) public view returns (Collection memory) {
        return allCollections[id];
    }

    // TODO check me some problem
    function removeListedLand(uint id, uint256 landIdToRemove) external onlyManager {
        Collection storage collection = allCollections[id];
        collection.landIds = Array256Lib.remove(collection.landIds, landIdToRemove);
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
                setBotState(botIdToRemove, TokenRentingStatus.AVAILABLE);
                delete collection.botsIds[collection.botsIds.length];
                return;
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

    function disbandCollection(uint256 id) external onlyManager returns (bool) {
        Collection storage collection = allCollections[id];
        if (collection.rentedLandIds.length == 0) {
            setState(collection.landIds, collection.botsIds, TokenRentingStatus.AVAILABLE);
            delete allCollections[id];
            return true;
        } else {
            allCollections[id].disbandTs = block.timestamp;
            return false;
        }
    }


    function deleteRenting(uint256 landId) external onlyManager {
        RentingInfo memory ri = getRentingInfo(landId);
        delete rentingInfo[landId];
        setTokensState(ri.battleSet, TokenRentingStatus.AVAILABLE);
    }

    function processCollectionRentalEnd(RentingInfo memory ri) external onlyManager returns (Collection memory) {
        Collection storage collection = allCollections[ri.collectionId];

        // process lands
        if (Array256Lib.contains(collection.landsToRemove, ri.battleSet.landId)) {
            collection.landsToRemove = Array256Lib.remove(collection.landsToRemove, ri.battleSet.landId);
            collection.rentedLandIds = Array256Lib.remove(collection.rentedLandIds, ri.battleSet.landId);
            setLandState(ri.battleSet.landId, TokenRentingStatus.AVAILABLE);
        } else {
            collection.rentedLandIds = Array256Lib.remove(collection.rentedLandIds, ri.battleSet.landId);
            collection.landIds.push(ri.battleSet.landId);
            setLandState(ri.battleSet.landId, TokenRentingStatus.LISTED_COLLECTION);
        }

        for (uint i = 0; i < ri.battleSet.botsIds.length; i++) {
            if (Array256Lib.contains(collection.botsToRemove, ri.battleSet.botsIds[i])) {
                collection.botsToRemove = Array256Lib.remove(collection.botsToRemove, ri.battleSet.botsIds[i]);
                collection.rentedBotsIds = Array256Lib.remove(collection.rentedBotsIds, ri.battleSet.botsIds[i]);
                setBotState(ri.battleSet.botsIds[i], TokenRentingStatus.AVAILABLE);
            } else {
                collection.rentedBotsIds = Array256Lib.remove(collection.rentedBotsIds, ri.battleSet.botsIds[i]);
                collection.botsIds.push(ri.battleSet.botsIds[i]);
                setBotState(ri.battleSet.botsIds[i], TokenRentingStatus.LISTED_COLLECTION);
            }
        }

        return allCollections[ri.collectionId];
    }


    function setState(uint256[] memory landIds, uint256[] memory botsIds, TokenRentingStatus status) private {
        for (uint i = 0; i < landIds.length; i++) {
            setLandState(landIds[i], status);
        }
        for (uint i = 0; i < botsIds.length; i++) {
            setBotState(botsIds[i], status);
        }
    }

}