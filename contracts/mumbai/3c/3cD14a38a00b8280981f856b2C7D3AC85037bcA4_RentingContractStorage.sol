/// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/utils/Context.sol";
import "./Array256Lib.sol";
import "./MarketplaceAccessControl.sol";

interface IRentingContractStorageTypes {

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


contract RentingContractStorage is Context, IRentingContractStorageTypes, MarketplaceAccessControl {

    mapping(uint256 => TokenRentingStatus) private landsInfos;
    mapping(uint256 => TokenRentingStatus) private botsInfos;

    mapping(uint256 => ListingInfo) private listingInfo;
    mapping(uint256 => RentingInfo) private rentingInfo;

    mapping(uint256 => Collection) private allCollections;

    uint256 collectionIdCounter = 1;


    function getListingInfo(uint256 landId) external view returns (ListingInfo memory) {
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

    function getLandStatus(uint256 landId) external view returns (TokenRentingStatus) {
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

    function getCollection(uint256 id) external view returns (Collection memory) {
        return allCollections[id];
    }

    function removeListedLand(uint id, uint256 landIdToRemove) external onlyManager {
        Collection storage collection = allCollections[id];
        collection.landIds = Array256Lib.remove(collection.landIds, landIdToRemove);
        setLandState(landIdToRemove, TokenRentingStatus.AVAILABLE);
    }


    function removeListedBot(uint id, uint256 botIdToRemove) external onlyManager {
        Collection storage collection = allCollections[id];
        collection.botsIds = Array256Lib.remove(collection.botsIds, botIdToRemove);
        setBotState(botIdToRemove, TokenRentingStatus.AVAILABLE);
    }

    function pushToBeRemovedLands(uint id, uint256 landIdToRemove) external onlyManager {
        allCollections[id].landsToRemove.push(landIdToRemove);
    }

    function pushToBeRemovedBots(uint id, uint256 botIdToRemove) external onlyManager {
        allCollections[id].botsToRemove.push(botIdToRemove);
    }

    function addPlayersToCollection(uint id, address[] memory players) external onlyManager {
        for (uint i = 0; i < players.length; i++) {
            allCollections[id].whitelist.push(players[i]);
        }
    }

    function removePlayersFromCollection(uint id, address player) external onlyManager {
        Collection storage collection = allCollections[id];
        collection.whitelist = Array256Lib.removeAddr(collection.whitelist, player);
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/AccessControl.sol";


contract MarketplaceAccessControl is AccessControl {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    modifier onlyAdmin {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Not authorized");
        _;
    }

    modifier onlyManager {
        require(hasRole(MANAGER_ROLE, _msgSender()), "Not authorized");
        _;
    }

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
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
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
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
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
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
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
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
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
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
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

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
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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