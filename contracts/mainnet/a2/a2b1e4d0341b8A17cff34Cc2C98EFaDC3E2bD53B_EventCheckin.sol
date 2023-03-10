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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IGameAccess.sol";

contract AccessControl is Ownable {
    IGameAccess internal _gameAccess;

    constructor(address gameAddress) {
        _gameAccess = IGameAccess(gameAddress);
    }

    modifier onlyGameOwner() {
        bool isGameAdmin = checkAccess(msg.sender, _gameAccess.getGameAdminAddresses());
        bool isInternal = checkAccess(msg.sender, _gameAccess.getInterfaceAddresses());
        bool isOwner = msg.sender == owner();
        bool isGame = msg.sender == address(_gameAccess);

        require(isGameAdmin || isInternal || isOwner || isGame, "WorldAccess: caller is not GameOwner");
        _;
    }

    function setGameAddress(address gameAddress) public virtual onlyGameOwner {
        _gameAccess = IGameAccess(gameAddress);
    }

    function checkAccess(address sender, address[] memory addresses) internal view returns(bool) {
        bool result = false;
        for (uint256 i = 0; i < addresses.length; i++) {
            if (addresses[i] == sender) {
                result = true;
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IGameAccess.sol";
import "./AccessControl.sol";

contract WorldAccess is Ownable, AccessControl {
    uint256 internal _worldId;

    constructor(uint256 worldId, address gameAddress)
    AccessControl(gameAddress) {
        _worldId = worldId;
    }

    modifier onlyGame() {
        bool isInternal = checkAccess(msg.sender, _gameAccess.getInterfaceAddresses());
        bool isGameAdmin = checkAccess(msg.sender, _gameAccess.getGameAdminAddresses());
        bool isWorldOwner = checkAccess(msg.sender, _gameAccess.getWorldOwnerAddresses(_worldId));
        bool isItemPackNFT = checkAccess(msg.sender, _gameAccess.getItemPackNFTAddresses(_worldId));
        bool isOwner = msg.sender == owner();
        bool isGame = msg.sender == address(_gameAccess);

        require(isInternal || isGameAdmin || isWorldOwner || isItemPackNFT || isOwner || isGame, "WorldAccess: caller is not Game/Owner");
        _;
    }

    modifier onlyWorldAdmin() {
        bool isGameAdmin = checkAccess(msg.sender, _gameAccess.getGameAdminAddresses());
        bool isWorldOwner = checkAccess(msg.sender, _gameAccess.getWorldOwnerAddresses(_worldId));
        bool isWorldAdmin = checkAccess(msg.sender, _gameAccess.getWorldAdminAddresses(_worldId));
        bool isOwner = msg.sender == owner();
        bool isGame = msg.sender == address(_gameAccess);

        require(isWorldAdmin || isGameAdmin || isWorldOwner || isOwner || isGame, "WorldAccess: caller is not WorldAdmin");
        _;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "../access/WorldAccess.sol";

contract Character is WorldAccess {
    // key: tokenId, value: characterDefinitionId
    mapping(uint256 => uint256) public characterDefinitionIds;

    // key: tokenId, value: isRevealed
    mapping(uint256 => bool) public isRevealeds;

    constructor(uint256 worldId, address gameAddress)
    WorldAccess(worldId, gameAddress) {
    }

    function setIsRevealed(uint256 tokenId_, bool isRevealed_) public virtual onlyGame {
        isRevealeds[tokenId_] = isRevealed_;
    }

    function setCharacterDefinitionId(uint256 tokenId_, uint256 characterDefinitionId_) public virtual onlyGame {
        characterDefinitionIds[tokenId_] = characterDefinitionId_;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "../access/WorldAccess.sol";

contract CharacterEdition is WorldAccess {
    struct CharacterEditionRecord {
        uint256[] characterDefinitionIds;
        uint256[] weights;
        uint256[][] itemPackDefinitionIds;
    }

    // key: characterEditionId, (key: characterDefinitionId, value: CharacterDefinitionId)
    mapping(uint256 => CharacterEditionRecord) private _records;
    // key: tokenId, value: characterEditionId
    mapping(uint256 => uint256) public tokenAndEditions;

    constructor(uint256 worldId, address gameAddress)
    WorldAccess(worldId, gameAddress) {
    }

    function getCharacterEditionRecord(uint256 characterEditionId) public view returns(CharacterEditionRecord memory) {
        return _records[characterEditionId];
    }

    function setCharacterEdition(uint256 characterEditionId, CharacterEditionRecord calldata record) public onlyGame {
        _records[characterEditionId] = record;
    }

    function setTokenIdsToCharacterEdition(uint256 characterEditionId, uint256[] calldata tokenIds) public onlyGame {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenAndEditions[tokenIds[i]] = characterEditionId;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "../access/WorldAccess.sol";

contract Equipment is WorldAccess {
    // key: tokenId, value: array of equipped itemId
    mapping(uint256 => uint256[]) public equipments;

    constructor(uint256 worldId, address gameAddress)
    WorldAccess(worldId, gameAddress) {
    }

    function getEquipments(uint256 tokenId) public virtual view returns(uint256[] memory) {
        return equipments[tokenId];
    }

    function setEquipments(uint256 tokenId, uint256[] memory itemIds) public virtual onlyGame {
        equipments[tokenId] = itemIds;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "../access/WorldAccess.sol";

contract EventCheckinLog is WorldAccess {
    struct EventCheckinLogRecord {
        address playerWallet;
        uint256 eventDefinitionId;
        uint256 timestamp;
    }

    uint256 public checkinCount;

    // key: eventDefinitionId, value: count
    mapping(uint256 => uint256) public checkinCountsPerEvent;

    // key: Player Wallet, value: (key: eventDefinitionId, value: count)
    mapping(address => mapping(uint256 => uint256)) public checkinCountsPerPlayer;

    // key: Player Wallet, value: (key: eventDefinitionId, value: timestamp(sec))
    mapping(address => mapping(uint256 => uint256)) public checkinTimeStampPerPlayer;

    // key: logId, value: (key: eventDefinitionId, value: timestamp(sec))
    mapping(uint256 => EventCheckinLogRecord) public logs;

    constructor(uint256 worldId, address gameAddress)
    WorldAccess(worldId, gameAddress) {
    }

    function log(address playerWallet, uint256 eventDefinitionId) public onlyGame {
        checkinCount++;
        checkinCountsPerEvent[eventDefinitionId]++;
        checkinCountsPerPlayer[playerWallet][eventDefinitionId]++;
        checkinTimeStampPerPlayer[playerWallet][eventDefinitionId] = block.timestamp;

        logs[checkinCount] = EventCheckinLogRecord(
            playerWallet,
            eventDefinitionId,
            block.timestamp
        );
    }

    function getLogs(uint256[] calldata logIds) public view returns(EventCheckinLogRecord[] memory) {
        EventCheckinLogRecord[] memory records = new EventCheckinLogRecord[](logIds.length);
        for (uint256 i = 0; i < logIds.length; i++) {
            EventCheckinLogRecord memory record = logs[logIds[i]];
            records[i] = EventCheckinLogRecord(
                record.playerWallet,
                record.eventDefinitionId,
                record.timestamp
            );
        }

        return records;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../lib/IDArrayUtil.sol";
import "../interfaces/token/IItemPackNFT.sol";
import "../access/WorldAccess.sol";

contract ItemPack is WorldAccess {
    uint256 private _currentIndex;

    struct ItemPackRecord {
        uint256 itemPackId;
        uint256 itemPackDefinitionId;
        address playerWallet;
        address nftAddress;
        uint256 tokenId;
        bool isRevealed;
    }

    // key: itemPackId, value: array of ItemPackRecord
    mapping(uint256 => ItemPackRecord) public itemPackRecords;

    // key: NFT contract address, value: (key: tokenId, value: itemPackId)
    mapping(address => mapping(uint256 => uint256)) public itemPackIdsByNft;

    // key: Wallet address, array of itemPackId
    mapping(address => uint256[]) private _itemPackIdsByWallet;

    constructor(uint256 worldId, address gameAddress)
    WorldAccess(worldId, gameAddress) {
    }

    function mintToWallet(address playerWallet, uint256 itemPackDefinitionId_) public virtual onlyGame {
        _mint(itemPackDefinitionId_, playerWallet, address(0), 0);
    }

    function mintByNFT(address nftAddress, uint256 tokenId, uint256 itemPackDefinitionId_) public virtual onlyGame {
        _mint(itemPackDefinitionId_, address(0), nftAddress, tokenId);
    }

    function burnByNFT(address nftAddress, uint256 tokenId) public virtual onlyGame {
        _burn(itemPackIdsByNft[nftAddress][tokenId]);
    }

    function burn(uint256 itemPackId) public virtual onlyGame {
        _burn(itemPackId);
    }

    function _mint(uint256 itemPackDefinitionId_, address playerWallet, address nftAddress, uint256 tokenId) internal virtual {
        _currentIndex++;

        if (playerWallet != address(0)) {
            _itemPackIdsByWallet[playerWallet].push(_currentIndex);
        }

        if (nftAddress != address(0) && tokenId != 0) {
            itemPackIdsByNft[nftAddress][tokenId] = _currentIndex;
        }

        itemPackRecords[_currentIndex] = ItemPackRecord(
            _currentIndex,
            itemPackDefinitionId_,
            playerWallet,
            nftAddress,
            tokenId,
            false
        );
    }

    using IDArrayUtil for uint256[];

    function _burn(uint256 itemPackId) internal virtual {
        address playerWallet = itemPackRecords[itemPackId].playerWallet;
        if (playerWallet != address(0)) {
            _itemPackIdsByWallet[playerWallet].removeById(itemPackId);
        }

        itemPackRecords[itemPackId] = ItemPackRecord(itemPackId, 0, address(0), address(0), 0, true);
    }

    function getItemPackIds(address playerWallet) public virtual view returns(uint256[] memory) {
        return _itemPackIdsByWallet[playerWallet];
    }

    function itemPackDefinitionId(uint256 itemPackId) public virtual view returns (uint256) {
        return itemPackRecords[itemPackId].itemPackDefinitionId;
    }

    function itemPackTokenId(uint256 itemPackId) public virtual view returns (uint256) {
        return itemPackRecords[itemPackId].tokenId;
    }

    function isRevealed(uint256 itemPackId) public virtual view returns (bool) {
        return itemPackRecords[itemPackId].isRevealed;
    }

    function getItemPackRecord(uint256 itemPackId) public virtual view returns (ItemPackRecord memory) {
        return itemPackRecords[itemPackId];
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "../access/WorldAccess.sol";

contract ItemStorage is WorldAccess {
    // key: tokenId, (key: itemDefinitionId, value: itemCount)
    mapping(uint256 => mapping(uint256 => int64)) public items;

    // key: tokenId, (key: itemDefinitionId, value: timestamp)
    mapping(uint256 => mapping(uint256 => uint256)) public lastAcquisitionTimestamps;

    constructor(uint256 worldId, address gameAddress)
    WorldAccess(worldId, gameAddress) {
    }

    function addItems(uint256 tokenId, uint256[] calldata itemDefinitionIds, int64[] calldata amounts) public virtual onlyGame {
        require(itemDefinitionIds.length == amounts.length, "wrong length");

        for (uint i = 0; i < itemDefinitionIds.length; i++) {
            addItem(tokenId, itemDefinitionIds[i], amounts[i]);
        }
    }

    function addItem(uint256 tokenId, uint256 itemDefinitionId, int64 amount) public virtual onlyGame {
        items[tokenId][itemDefinitionId] += amount;
        if (amount > 0) {
            lastAcquisitionTimestamps[tokenId][itemDefinitionId] = block.timestamp;
        }
    }

    function getItems(uint256 tokenId, uint256[] memory itemDefinitionIds) public virtual view returns(int64[] memory) {
        int64[] memory result = new int64[](itemDefinitionIds.length);
        for (uint256 i = 0; i < itemDefinitionIds.length; i++) {
            result[i] = items[tokenId][itemDefinitionIds[i]];
        }

        return result;
    }

    function hasItem(uint256 tokenId, uint256 itemDefinitionId, int64 amount) public virtual view returns(bool) {
        return items[tokenId][itemDefinitionId] >= amount;
    }

    function getLastAcquisitionTimestamps(uint256 tokenId, uint256[] calldata itemDefinitionIds) public virtual view returns(uint256[] memory) {
        uint256[] memory result = new uint256[](itemDefinitionIds.length);
        for (uint256 i = 0; i < itemDefinitionIds.length; i++) {
            result[i] = lastAcquisitionTimestamps[tokenId][itemDefinitionIds[i]];
        }

        return result;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "../access/WorldAccess.sol";

contract CharacterDefinition is WorldAccess {
    enum EquipmentSlot { Invalid, Normal }

    // key: characterDefinitionId
    mapping(uint256 => bool) characters;

    // key: characterDefinitionId
    mapping(uint256 => EquipmentSlot[]) public equipmentSlots;

    // key: characterDefinitionId, value: (key: itemId, value: equipmentSlotIndex)
    mapping(uint256 => mapping(uint256 => uint256)) public equipableItems;

    // key: characterDefinitionId, value: array of itemDefinitionId
    mapping(uint256 => uint256[]) public defaultEquipmentIds;

    constructor(uint256 worldId, address gameAddress)
    WorldAccess(worldId, gameAddress) {
    }

    function setCharacter(uint256 characterDefinitionId, bool enabled) public virtual onlyWorldAdmin {
        require(characterDefinitionId > 0);

        characters[characterDefinitionId] = enabled;
    }

    function setEquipmentSlots(uint256 characterDefinitionId, EquipmentSlot[] memory equipmentSlots_) public virtual onlyWorldAdmin {
        require(characters[characterDefinitionId], "character disabled");
        require(equipmentSlots_.length > 0);

        equipmentSlots[characterDefinitionId] = equipmentSlots_;
    }

    function getEquipmentSlots(uint256 characterDefinitionId) public view virtual returns(EquipmentSlot[] memory) {
        return equipmentSlots[characterDefinitionId];
    }

    function isValidEquipmentSlot(uint256 characterDefinitionId, uint256 equipmentSlotIndex) public view virtual returns(bool) {
        return equipmentSlotIndex < equipmentSlots[characterDefinitionId].length && equipmentSlots[characterDefinitionId][equipmentSlotIndex] != EquipmentSlot.Invalid;
    }

    function setEquipable(uint256 characterDefinitionId, uint256 itemId, uint256 equipmentSlotIndex) public virtual onlyWorldAdmin {
        require(characters[characterDefinitionId]);

        equipableItems[characterDefinitionId][itemId] = equipmentSlotIndex;
    }

    function setDefaultEquipment(uint256 characterDefinitionId, uint256 itemId, uint256 equipmentSlotIndex) public onlyWorldAdmin {
        if (defaultEquipmentIds[characterDefinitionId][equipmentSlotIndex] <= itemId) {
            defaultEquipmentIds[characterDefinitionId][equipmentSlotIndex] = itemId;
        }
    }

    function canEquip(uint256 characterDefinitionId, uint256 itemId, uint256 equipmentSlotIndex) public virtual view returns(bool) {
        return equipableItems[characterDefinitionId][itemId] == equipmentSlotIndex || itemId == 0;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "../access/WorldAccess.sol";

contract EventDefinition is WorldAccess {
    struct EventDefinitionRecord {
        uint256 eventDefinitionId;
        bool enabled;
        uint256 itemPackDefinitionId;
        address eventNftAddress;
        uint256 executableTimes;
        uint256 executableTimesPerUser;
        uint256 endPeriod;
        uint256 userExecutableInterval;
        bool gpsCheckEnabled;
    }

    mapping(uint256 => EventDefinitionRecord) private _eventDefinitions;

    constructor(uint256 worldId, address gameAddress)
    WorldAccess(worldId, gameAddress) {
    }

    function getItemPackDefinitionId(uint256 eventDefinitionId) public virtual view returns(uint256) {
        EventDefinitionRecord memory record = _eventDefinitions[eventDefinitionId];

        return record.itemPackDefinitionId;
    }

    function getEventDefinition(uint256 eventDefinitionId) external virtual view returns(
            uint256, bool, uint256, address, uint256, uint256, uint256, uint256, bool) {
        EventDefinitionRecord memory record = _eventDefinitions[eventDefinitionId];

        return (
            record.eventDefinitionId,
            record.enabled,
            record.itemPackDefinitionId,
            record.eventNftAddress,
            record.executableTimes,
            record.executableTimesPerUser,
            record.endPeriod,
            record.userExecutableInterval,
            record.gpsCheckEnabled
        );
    }

    function setEventDefinitions(EventDefinitionRecord[] memory eventDefinitions_) public virtual onlyWorldAdmin {
        for (uint256 i = 0; i < eventDefinitions_.length; i++) {
            EventDefinitionRecord memory record = eventDefinitions_[i];
            _addEventDefinition(
                record.eventDefinitionId,
                record.enabled,
                record.itemPackDefinitionId,
                record.eventNftAddress,
                record.executableTimes,
                record.executableTimesPerUser,
                record.endPeriod,
                record.userExecutableInterval,
                record.gpsCheckEnabled
            );
        }
    }

    function _addEventDefinition(
        uint256 eventDefinitionId,
        bool enabled_,
        uint256 itemPackDefinitionId_,
        address eventNftAddress_,
        uint256 executableTimes_,
        uint256 executableTimesPerUser_,
        uint256 endPeriod_,
        uint256 userExecutableInterval,
        bool gpsCheckEnabled
    ) private {
        _eventDefinitions[eventDefinitionId] = EventDefinitionRecord(
            eventDefinitionId,
            enabled_,
            itemPackDefinitionId_,
            eventNftAddress_,
            executableTimes_,
            executableTimesPerUser_,
            endPeriod_,
            userExecutableInterval,
            gpsCheckEnabled
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "../interfaces/definitions/IItemDefinition.sol";
import "../access/WorldAccess.sol";

contract ItemDefinition is IItemDefinition, WorldAccess {
    mapping(uint256 => IItemDefinition.ItemDefinitionRecord) itemDefinitionRecords;

    constructor(uint256 worldId, address gameAddress)
    WorldAccess(worldId, gameAddress) {
    }

    function _setDefinition(IItemDefinition.ItemDefinitionRecord calldata record) internal {
        itemDefinitionRecords[record.itemDefinitionId] = record;
    }

    function setDefinitions(IItemDefinition.ItemDefinitionRecord[] calldata records) external override onlyWorldAdmin {
        for (uint256 i = 0; i < records.length; i++) {
            _setDefinition(records[i]);
        }
    }

    function getDefinition(uint256 itemDefinitionId_) external view returns(ItemDefinitionRecord memory) {
        return itemDefinitionRecords[itemDefinitionId_];
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../access/WorldAccess.sol";

contract ItemPackDefinition is WorldAccess {
    struct SlotDefinition {
        uint256[] itemDefinitionIds;
        uint256[] weights;
        int64[] amounts;
    }

    // key: itemPackDefinitionId
    mapping(uint256 => SlotDefinition[]) private _slotDefinitions;

    constructor(uint256 worldId, address gameAddress)
    WorldAccess(worldId, gameAddress) {
    }

    function getSlotLength(uint256 itemPackDefinitionId) public virtual view returns(uint256) {
        return _slotDefinitions[itemPackDefinitionId].length;
    }

    function getSlotDefinition(uint256 itemPackDefinitionId, uint256 slot) public virtual view returns(uint256[] memory, uint256[] memory, int64[] memory) {
        SlotDefinition memory s = _slotDefinitions[itemPackDefinitionId][slot];

        return (s.itemDefinitionIds, s.weights, s.amounts);
    }

    function setItemPackDefinition(uint256 itemPackDefinitionId, SlotDefinition[] memory itemPacks) public virtual onlyWorldAdmin {
        delete _slotDefinitions[itemPackDefinitionId];
        for (uint256 i = 0; i < itemPacks.length; i++) {
            SlotDefinition memory itemPack = itemPacks[i];

            // TODO: check itemId
            require(itemPack.itemDefinitionIds.length > 0 && itemPack.itemDefinitionIds.length <= 100, "wrong itemDefinitionIds length");
            require(itemPack.itemDefinitionIds.length == itemPack.amounts.length, "wrong amounts length");
            require(itemPack.itemDefinitionIds.length == itemPack.weights.length, "wrong weights length");

            _slotDefinitions[itemPackDefinitionId].push(itemPacks[i]);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IWorld.sol";
import "./interfaces/IGameAccess.sol";

contract Game is IGameAccess, Ownable {
    mapping(uint256 => address) public worlds;
    mapping(uint256 => address[]) public worldAdmins;
    address[] public gameAdmins;

    // key: interface name
    mapping(string => address) public gameInterfaces;

    string[] public gameInterfaceKeys;

    constructor() {
    }

    function setInterfaceAddress(string memory key, address interfaceAddress) public onlyOwner {
        _setInterfaceAddress(key, interfaceAddress);
    }

    function _setInterfaceAddress(string memory key, address interfaceAddress) private {
        require(_validKey(key), "wrong key");

        gameInterfaces[key] = interfaceAddress;
    }

    function _validKey(string memory key) private view returns(bool) {
        for (uint256 i = 0; i < gameInterfaceKeys.length; i++) {
            if (keccak256(abi.encodePacked(gameInterfaceKeys[i])) == keccak256(abi.encodePacked(key))) {
                return true;
            }
        }

        return false;
    }

    function setInterfaceAddressKeys(string[] memory keys) public onlyOwner {
        gameInterfaceKeys = keys;
    }

    function setWorld(uint256 worldId, address worldAddress) public onlyOwner {
        worlds[worldId] = worldAddress;
        IWorld world = IWorld(worldAddress);
        world.setGame(address(this));
    }

    function getInterfaceAddress(string calldata key) external view returns(address) {
        return gameInterfaces[key];
    }

    function setWorldAdmins(uint256 worldId, address[] calldata admins) public onlyOwner {
        worldAdmins[worldId] = admins;
    }

    function setGameAdmins(address[] calldata admins) public onlyOwner {
        gameAdmins = admins;
    }

    // ==============================
    //          IGameAccess
    // ==============================
    function getInterfaceAddresses() external view override returns(address[] memory) {
        address[] memory addresses = new address[](gameInterfaceKeys.length);
        for (uint256 i = 0; i < gameInterfaceKeys.length; i++) {
            string memory key = gameInterfaceKeys[i];
            addresses[i] = gameInterfaces[key];
        }

        return addresses;
    }

    function getWorldOwnerAddresses(uint256 worldId) external view override returns(address[] memory) {
        address[] memory addresses = new address[](2);
        addresses[0] = this.owner();
        addresses[1] = worlds[worldId];

        return addresses;
    }

    function getWorldAdminAddresses(uint256 worldId) external view override returns(address[] memory) {
        return worldAdmins[worldId];
    }

    function getGameAdminAddresses() external view override returns(address[] memory) {
        return gameAdmins;
    }

    function getTokenOwnerAddress(uint256 worldId, uint256 tokenId) external view override returns(address) {
        IWorld world = IWorld(worlds[worldId]);

        return world.getL1NFT().getOwner(tokenId);
    }

    function getItemPackNFTAddresses(uint256 worldId) external view override returns(address[] memory) {
        IWorld world = IWorld(worlds[worldId]);
        IItemPackNFT[] memory itemPacNFTs = world.getItemPackNFTs();

        address[] memory addresses = new address[](itemPacNFTs.length);
        for (uint256 i = 0; i < itemPacNFTs.length; i++) {
            addresses[i] = address(itemPacNFTs[i]);
        }

        return addresses;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "../interfaces/IEventCheckin.sol";
import "../data/Character.sol";
import "./GameBase.sol";
import "../definitions/EventDefinition.sol";
import "../definitions/ItemPackDefinition.sol";
import "../data/ItemPack.sol";
import "./WorldStore.sol";

contract EventCheckin is IEventCheckin, GameBase, AccessControl {
    uint256 public checkinCount;

    constructor(address game)
    GameBase(game)
    AccessControl(game) {
    }

    function validateCheckin(address playerWallet, uint256 worldId, uint256 eventDefinitionId) external override view returns(bool, bool, bool, bool, bool, bool) {
        bool enabled = _checkEnabled(playerWallet, worldId, eventDefinitionId);
        bool executableTime = _checkExecutableTimes(playerWallet, worldId, eventDefinitionId);
        bool executableTimePerPlayer = _checkExecutableTimesPerPlayer(playerWallet, worldId, eventDefinitionId);
        bool endPeriod = _checkEndPeriod(playerWallet, worldId, eventDefinitionId);
        bool interval = _checkInterval(playerWallet, worldId, eventDefinitionId);
        bool executable = enabled && executableTime && executableTimePerPlayer && endPeriod && interval;

        return (executable, enabled, executableTime, executableTimePerPlayer, endPeriod, interval);
    }

    function checkin(address playerWallet, uint256 worldId, uint256 eventDefinitionId) external virtual override onlyGameOwner {
        require(_checkEnabled(playerWallet, worldId, eventDefinitionId), "Disabled");
        require(_checkExecutableTimes(playerWallet, worldId, eventDefinitionId), "Exceeded limit");
        require(_checkExecutableTimesPerPlayer(playerWallet, worldId, eventDefinitionId), "Exceeded limit per user");
        require(_checkEndPeriod(playerWallet, worldId, eventDefinitionId), "Finished event");
        require(_checkInterval(playerWallet, worldId, eventDefinitionId), "wrong interval check");

        World world = getWorld(worldId);
        EventCheckinLog eventCheckinLog = world.eventCheckinLog();

        eventCheckinLog.log(playerWallet, eventDefinitionId);
        _mintItemPack(playerWallet, worldId, eventDefinitionId);
    }

    function getEventDefinition(uint256 worldId_, uint256 eventDefinitionId_) external virtual view returns(
            uint256, bool, uint256, address, uint256, uint256, uint256, uint256, bool) {
        World world = getWorld(worldId_);
        EventDefinition eventDefinition = world.eventDefinition();

        return eventDefinition.getEventDefinition(eventDefinitionId_);
    }

    function getCheckinCountFromPlayer(address playerWallet, uint256 worldId, uint256 eventDefinitionId) external override view returns(uint256) {
        WorldStore store = WorldStore(_game.getInterfaceAddress("WorldStore"));
        EventCheckinLog eventCheckinLog = EventCheckinLog(store.getDataContract(worldId, "EventCheckinLog"));

        return eventCheckinLog.checkinCountsPerPlayer(playerWallet, eventDefinitionId);
    }

    function getLatestCheckinTimestampFromPlayer(address playerWallet, uint256 worldId, uint256 eventDefinitionId) external override view returns(uint256) {
        WorldStore store = WorldStore(_game.getInterfaceAddress("WorldStore"));
        EventCheckinLog eventCheckinLog = EventCheckinLog(store.getDataContract(worldId, "EventCheckinLog"));

        return eventCheckinLog.checkinTimeStampPerPlayer(playerWallet, eventDefinitionId);
    }

    function _mintItemPack(address playerWallet, uint256 worldId, uint256 eventDefinitionId) private {
        World world = getWorld(worldId);
        EventDefinition eventDefinition = world.eventDefinition();
        uint256 itemPackDefinitionId = eventDefinition.getItemPackDefinitionId(eventDefinitionId);
        if (itemPackDefinitionId == 0) {
            emit Checkin(playerWallet, worldId, eventDefinitionId, 0, 0);
            return;
        }

        ItemPack itemPack = world.itemPack();
        itemPack.mintToWallet(playerWallet, itemPackDefinitionId);

        uint256[] memory itemPackIds = itemPack.getItemPackIds(playerWallet);

        emit Checkin(playerWallet, worldId, eventDefinitionId, itemPackDefinitionId, itemPackIds[itemPackIds.length - 1]);
    }

    function _checkEnabled(address playerWallet_, uint256 worldId_, uint256 eventDefinitionId) private view returns(bool) {
        World world = getWorld(worldId_);
        EventDefinition eventDefinition = world.eventDefinition();
        (,bool enabled,,,,,,,) = eventDefinition.getEventDefinition(eventDefinitionId);

        return enabled;
    }

    function _checkExecutableTimes(address playerWallet_, uint256 worldId_, uint256 eventDefinitionId) private view returns(bool) {
        World world = getWorld(worldId_);
        EventCheckinLog eventCheckinLog = world.eventCheckinLog();
        EventDefinition eventDefinition = world.eventDefinition();
        (,,,, uint256 executableTimes_,,,,) = eventDefinition.getEventDefinition(eventDefinitionId);
        uint256 currentCount = eventCheckinLog.checkinCountsPerEvent(eventDefinitionId);

        return currentCount < executableTimes_ || executableTimes_ == 0;
    }

    function _checkExecutableTimesPerPlayer(address playerWallet_, uint256 worldId_, uint256 eventDefinitionId) private view returns(bool) {
        World world = getWorld(worldId_);
        EventCheckinLog eventCheckinLog = world.eventCheckinLog();
        EventDefinition eventDefinition = world.eventDefinition();
        (,,,,, uint256 executableTimesPerPlayer_,,,) = eventDefinition.getEventDefinition(eventDefinitionId);
        uint256 count = eventCheckinLog.checkinCountsPerPlayer(playerWallet_, eventDefinitionId);

        return count < executableTimesPerPlayer_ || executableTimesPerPlayer_ == 0;
    }

    function _checkEndPeriod(address playerWallet_, uint256 worldId_, uint256 eventDefinitionId) private view returns(bool) {
        World world = getWorld(worldId_);
        EventDefinition eventDefinition = world.eventDefinition();
        (,,,,,, uint256 endPeriod,,) = eventDefinition.getEventDefinition(eventDefinitionId);

        return block.timestamp < endPeriod || endPeriod == 0;
    }

    function _checkInterval(address playerWallet_, uint256 worldId_, uint256 eventDefinitionId) private view returns(bool) {
        World world = getWorld(worldId_);
        EventCheckinLog eventCheckinLog = world.eventCheckinLog();
        EventDefinition eventDefinition = world.eventDefinition();
        (,,,,,,,uint256 userExecutableInterval,) = eventDefinition.getEventDefinition(eventDefinitionId);
        uint256 lastCheckinTimestamp = eventCheckinLog.checkinTimeStampPerPlayer(playerWallet_, eventDefinitionId);

        return block.timestamp > lastCheckinTimestamp + userExecutableInterval || userExecutableInterval == 0;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "../Game.sol";
import "../World.sol";
import "../data/Character.sol";
import "../interfaces/definitions/IItemDefinition.sol";

contract GameBase {
    Game internal _game;

    constructor(address game) {
        _game = Game(game);
    }

    function getWorld(uint256 worldId) internal view virtual returns(World) {
        return World(_game.worlds(worldId));
    }

    function getItemDefinition(uint256 worldId) internal view virtual returns(IItemDefinition) {
        World world = getWorld(worldId);
        if (address(world) == address(0)) {
            return IItemDefinition(address(0));
        }

        return world.itemDefinition();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "../access/AccessControl.sol";

contract WorldStore is AccessControl {
    // key: definition name
    string[] public definitionKeys;

    // key: worldId, value: (key: key, value: contract address)
    mapping(uint256 => mapping(string => address)) private _definitions;

    // key: data contract name
    string[] public dataContractKeys;

    // key: worldId, value: (key: key, value: contract address)
    mapping(uint256 => mapping(string => address)) private _dataContract;


    constructor(address game)
    AccessControl(game) {
    }

    function getDefinition(uint256 worldId, string memory key) public view returns(address) {
        return _definitions[worldId][key];
    }

    function setDefinition(uint256 worldId, string memory key, address definition) public onlyGameOwner {
        require(_validDefinitionKey(key), "wrong key");

        _definitions[worldId][key] = definition;
    }

    function setDefinitionKeys(string[] memory keys) public onlyGameOwner {
        definitionKeys = keys;
    }

    function _validDefinitionKey(string memory key) private view returns(bool) {
        for (uint256 i = 0; i < definitionKeys.length; i++) {
            if (keccak256(abi.encodePacked(definitionKeys[i])) == keccak256(abi.encodePacked(key))) {
                return true;
            }
        }

        return false;
    }

    function getDataContract(uint256 worldId, string memory key) public view returns(address) {
        return _dataContract[worldId][key];
    }

    function setDataContract(uint256 worldId, string memory key, address definition) public onlyGameOwner {
        require(_validDataContractKey(key), "wrong key");

        _dataContract[worldId][key] = definition;
    }

    function setDataContractKeys(string[] memory keys) public onlyGameOwner {
        dataContractKeys = keys;
    }

    function _validDataContractKey(string memory key) private view returns(bool) {
        for (uint256 i = 0; i < dataContractKeys.length; i++) {
            if (keccak256(abi.encodePacked(dataContractKeys[i])) == keccak256(abi.encodePacked(key))) {
                return true;
            }
        }

        return false;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IItemDefinition {
    struct ItemDefinitionRecord {
        uint256 itemDefinitionId;
        string category;
        bool enable;
        bool salable;
        bool transferable;
        uint256 effectivePeriod;
    }

    function setDefinitions(ItemDefinitionRecord[] calldata records) external;

    function getDefinition(uint256 itemDefinitionId_) external view returns(ItemDefinitionRecord memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IEventCheckin {
    struct LogRecord {
        address playerWallet;
        uint256 eventDefinitionId;
        uint256 timestamp;
    }

    event Checkin(address indexed playerWallet, uint256 indexed worldId, uint256 eventDefinitionId, uint256 itemPackDefinitionId, uint256 itemPackId);

    function checkin(address playerWallet, uint256 worldId, uint256 eventDefinitionId) external;

    // @returns Returns executable
    // - bool executable
    // - bool check enabled
    // - bool check executable times
    // - bool check executable times per user
    // - bool check end period
    // - bool check user executable interval
    function validateCheckin(address playerWallet, uint256 worldId, uint256 eventDefinitionId) external view returns(bool, bool, bool, bool, bool, bool);

    // @returns Returns Event definition.
    // - uint256 eventDefinitionId
    // - bool enabled
    // - uint256 itemPackDefinitionId
    // - address eventNftAddress - ERC721
    // - uint256 executableTimes
    // - uint256 executableTimesPerUser
    // - uint256 endPeriod - unix timestamp(seconds)
    // - uint256 userExecutableInterval - seconds
    // - bool gpsCheckEnabled
    function getEventDefinition(uint256 worldId, uint256 eventDefinitionId) external view returns(
        uint256, bool, uint256, address, uint256, uint256, uint256, uint256, bool);

    function getCheckinCountFromPlayer(address playerWallet, uint256 worldId, uint256 eventDefinitionId) external view returns(uint256);

    function getLatestCheckinTimestampFromPlayer(address playerWallet, uint256 worldId, uint256 eventDefinitionId) external view returns(uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IGameAccess {
    function getInterfaceAddresses() external view returns(address[] memory);
    function getWorldOwnerAddresses(uint256 worldId) external view returns(address[] memory);
    function getWorldAdminAddresses(uint256 worldId) external view returns(address[] memory);
    function getGameAdminAddresses() external view returns(address[] memory);
    function getTokenOwnerAddress(uint256 worldId, uint256 tokenId) external view returns(address);
    function getItemPackNFTAddresses(uint256 worldId) external view returns(address[] memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./token/IL1NFT.sol";
import "./token/IItemPackNFT.sol";

interface IWorld {
    function setGame(address game_) external;
    function getL1NFT() external view returns(IL1NFT);
    function getItemPackNFTs() external view returns(IItemPackNFT[] memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IItemPackNFT {
    function getEnabled() external view returns(bool);
    function setEnabled(bool enabled) external;
    function mint(address to, uint256 quantity, uint256 itemPackDefinitionId) external;
    function burn(uint256 tokenId) external;
    function getTokens(address owner) external view returns(uint256[] memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IL1NFT {
    function getTokens(address owner) external view returns(uint256[] memory);
    function getOwner(uint256 tokenId) external view returns (address owner);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

library IDArrayUtil {
    function findIndex(uint256[] memory arr, uint256 id) internal pure returns(uint256) {
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == id) {
                return i;
            }
        }

        revert("ID not found");
    }

    function removeById(uint256[] storage arr, uint256 id) internal {
        uint256 index = findIndex(arr, id);

        remove(arr, index);
    }

    function remove(uint256[] storage arr, uint256 _index) internal {
        require(_index < arr.length, "out of bound");

        for (uint256 i = _index; i < arr.length - 1; i++) {
            arr[i] = arr[i + 1];
        }
        arr.pop();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./data/Character.sol";
import "./definitions/CharacterDefinition.sol";
import "./definitions/ItemDefinition.sol";
import "./definitions/EventDefinition.sol";
import "./data/ItemPack.sol";
import "./definitions/ItemPackDefinition.sol";
import "./interfaces/definitions/IItemDefinition.sol";
import "./interfaces/token/IItemPackNFT.sol";
import "./data/CharacterEdition.sol";
import "./data/Equipment.sol";
import "./data/ItemStorage.sol";
import "./interfaces/IWorld.sol";
import "./data/EventCheckinLog.sol";
import "./interfaces/IGameAccess.sol";
import "./interfaces/token/IL1NFT.sol";

contract World is Ownable, IWorld, WorldAccess {
    IL1NFT private _l1NFT;
    IItemPackNFT[] private _itemPackNFTs;

    IGameAccess public game;
    uint256 public worldId;

    uint256 private _characterIndex;
    uint256 private _characterDefinitionIndex;
    uint256 private _ItemDefinitionIndex;

    CharacterDefinition public characterDefinition;
    ItemDefinition public itemDefinition;
    ItemPackDefinition public itemPackDefinition;
    EventDefinition public eventDefinition;

    Character public character;
    Equipment public equipment;
    ItemStorage public itemStorage;
    ItemPack public itemPack;
    CharacterEdition public characterEdition;
    EventCheckinLog public eventCheckinLog;

    // key: commandDefinitionId
    mapping(uint256 => address) public commandDefinitions;

    constructor(address game_, uint256 worldId_)
    WorldAccess(worldId_, game_) {
        worldId = worldId_;

        characterDefinition = new CharacterDefinition(worldId_, game_);
        itemPackDefinition = new ItemPackDefinition(worldId_, game_);
        eventDefinition = new EventDefinition(worldId_, game_);
        itemDefinition = new ItemDefinition(worldId_, game_);

        character = new Character(worldId_, game_);
        equipment = new Equipment(worldId_, game_);
        itemStorage = new ItemStorage(worldId_, game_);
        itemPack = new ItemPack(worldId_, game_);
        characterEdition = new CharacterEdition(worldId_, game_);
        eventCheckinLog = new EventCheckinLog(worldId_, game_);
    }

    function setGame(address game_) external override onlyWorldAdmin {
        game = IGameAccess(game_);

        characterDefinition.setGameAddress(game_);
        itemPackDefinition.setGameAddress(game_);
        eventDefinition.setGameAddress(game_);
        itemDefinition.setGameAddress(game_);

        character.setGameAddress(game_);
        equipment.setGameAddress(game_);
        itemStorage.setGameAddress(game_);
        characterEdition.setGameAddress(game_);
        eventCheckinLog.setGameAddress(game_);
    }

    function setL1NFT(address l1NFT_) external onlyWorldAdmin {
        _l1NFT = IL1NFT(l1NFT_);
    }

    function setCharacterDefinition(address characterDefinition_) public onlyWorldAdmin {
        characterDefinition = CharacterDefinition(characterDefinition_);
    }

    function addItemPackNFT(address itemPackNFT) public onlyWorldAdmin {
        _itemPackNFTs.push(IItemPackNFT(itemPackNFT));
    }

    function getItemPackNFTs() external view returns(IItemPackNFT[] memory) {
        return _itemPackNFTs;
    }

    function getItemPackNFTs(uint256 itemPackId) external view returns(address) {
        return address(_itemPackNFTs[itemPackId]);
    }

    function addCharacterDefinition(uint256 characterDefinitionId, CharacterDefinition.EquipmentSlot[] memory equipableSlots_, uint256[][] memory equipables_) public onlyWorldAdmin {
        characterDefinition.setCharacter(characterDefinitionId, true);
        characterDefinition.setEquipmentSlots(characterDefinitionId, equipableSlots_);

        for (uint256 i = 0; i < equipables_.length; i++) {
            uint256[] memory equipable = equipables_[i];
            uint256 itemId = equipable[0];
            uint256 slotIndex = equipable[1];

            characterDefinition.setEquipable(characterDefinitionId, itemId, slotIndex);
        }
    }

    function getL1NFT() external view override returns(IL1NFT) {
        return _l1NFT;
    }
}