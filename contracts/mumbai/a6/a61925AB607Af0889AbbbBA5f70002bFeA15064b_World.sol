// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

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
        itemPack = new ItemPack(worldId_);
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

    function getItemPackNFTs() public view returns(IItemPackNFT[] memory) {
        return _itemPackNFTs;
    }

    function addCharacterDefinition(uint256 characterDefinitionId, CharacterDefinition.EquipmentSlot[] memory equipableSlots_, uint256[][] memory equipables_) public onlyWorldAdmin {
        characterDefinition.setCharacter(characterDefinitionId, true);
        characterDefinition.setEquipmentSlots(characterDefinitionId, equipableSlots_);

        for (uint256 i; i < equipables_.length; i++) {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

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
pragma solidity ^0.8.0;

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
        require(characters[characterDefinitionId] == true, "character disabled");
        require(equipmentSlots_.length > 0);

        equipmentSlots[characterDefinitionId] = equipmentSlots_;
    }

    function getEquipmentSlots(uint256 characterDefinitionId) public view virtual returns(EquipmentSlot[] memory) {
        return equipmentSlots[characterDefinitionId];
    }

    function isValidEquipmentSlot(uint256 characterDefinitionId, uint256 equipmentSlotIndex) public view virtual returns(bool) {
        return equipmentSlotIndex >= 0 && equipmentSlotIndex < equipmentSlots[characterDefinitionId].length && equipmentSlots[characterDefinitionId][equipmentSlotIndex] != EquipmentSlot.Invalid;
    }

    function setEquipable(uint256 characterDefinitionId, uint256 itemId, uint256 equipmentSlotIndex) public virtual onlyWorldAdmin {
        require(characters[characterDefinitionId] == true);

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
pragma solidity ^0.8.0;

import "../interfaces/definitions/IItemDefinition.sol";
import "../access/WorldAccess.sol";

contract ItemDefinition is IItemDefinition, WorldAccess {
    // key: itemDefinitionId
    mapping(uint256 => string) private _categories;
    mapping(uint256 => bool) private _enables;
    mapping(uint256 => bool) private _salables;
    mapping(uint256 => bool) private _transferables;
    mapping(uint256 => uint256) private _effectivePeriods;

    constructor(uint256 worldId, address gameAddress)
    WorldAccess(worldId, gameAddress) {
    }

    function _setDefinition(uint256 itemDefinitionId, string calldata category, bool enable, bool salable, bool transferable, uint256 effectivePeriod) internal {
        _categories[itemDefinitionId] = category;
        _enables[itemDefinitionId] = enable;
        _salables[itemDefinitionId] = salable;
        _transferables[itemDefinitionId] = transferable;
        _effectivePeriods[itemDefinitionId] = effectivePeriod;
    }

    // TODO: add access control modifier
    function setDefinitions(
        uint256[] calldata itemDefinitionIds,
        string[] calldata categories,
        bool[] calldata enables,
        bool[] calldata salables,
        bool[] calldata transferables,
        uint256[] calldata effectivePeriods
    ) external {
        require(itemDefinitionIds.length == categories.length, "wrong length");
        require(itemDefinitionIds.length == enables.length, "wrong length");
        require(itemDefinitionIds.length == salables.length, "wrong length");
        require(itemDefinitionIds.length == transferables.length, "wrong length");
        require(itemDefinitionIds.length == effectivePeriods.length, "wrong length");

        for (uint256 i; i < itemDefinitionIds.length; i++) {
            _setDefinition(
                itemDefinitionIds[i],
                categories[i],
                enables[i],
                salables[i],
                transferables[i],
                effectivePeriods[i]
            );
        }
    }

    function getDefinition(uint256 itemDefinitionId) public virtual view returns(string memory, bool, bool, bool, uint256) {
        return (
            _categories[itemDefinitionId],
            _enables[itemDefinitionId],
            _salables[itemDefinitionId],
            _transferables[itemDefinitionId],
            _effectivePeriods[itemDefinitionId]
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

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
        for (uint256 i; i < eventDefinitions_.length; i++) {
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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../lib/IDArrayUtil.sol";
import "../interfaces/token/IItemPackNFT.sol";

using IDArrayUtil for uint256[];

contract ItemPack {
    uint256 public worldId;
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

    constructor(uint256 worldId_) {
        worldId = worldId_;
    }

    // TODO: add access control modifier
    function mintToWallet(address playerWallet, uint256 itemPackDefinitionId_) public virtual {
        _mint(itemPackDefinitionId_, playerWallet, address(0), 0);
    }

    // TODO: add access control modifier
    function mintByNFT(address nftAddress, uint256 tokenId, uint256 itemPackDefinitionId_) public virtual {
        _mint(itemPackDefinitionId_, address(0), nftAddress, tokenId);
    }

    // TODO: add access control modifier
    function burnByNFT(address nftAddress, uint256 tokenId, bool burnNFT) public virtual {
        _burn(itemPackIdsByNft[nftAddress][tokenId], burnNFT);
    }

    // TODO: add access control modifier
    function burn(uint256 itemPackId) public virtual {
        _burn(itemPackId, true);
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

    function _burn(uint256 itemPackId, bool burnNFT) internal virtual {
        address playerWallet = itemPackRecords[itemPackId].playerWallet;
        if (playerWallet != address(0)) {
            _itemPackIdsByWallet[playerWallet].removeById(itemPackId);
        }

        address nftAddress = itemPackRecords[itemPackId].nftAddress;
        uint256 tokenId = itemPackRecords[itemPackId].tokenId;
        if (burnNFT && nftAddress != address(0) && tokenId != 0) {
            IItemPackNFT nft = IItemPackNFT(nftAddress);
            nft.burn(tokenId);
        }

        itemPackRecords[itemPackId] = ItemPackRecord(itemPackId, 0, address(0), address(0), 0, true);
    }

    function getItemPackIds(address playerWallet) public virtual view returns(uint256[] memory) {
        // TODO: should not use wallet address
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
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../access/WorldAccess.sol";

contract ItemPackDefinition is WorldAccess {
    struct SlotDefinition {
        uint256[] itemDefinitionIds;
        uint256[] weights;
        int64[] amounts;
    }

    uint256 public worldId;

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
        for (uint256 i; i < itemPacks.length; i++) {
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
pragma solidity ^0.8.0;

interface IItemDefinition {
    function setDefinitions(
        uint256[] calldata itemDefinitionIds,
        string[] calldata categories,
        bool[] calldata enables,
        bool[] calldata salables,
        bool[] calldata transferables,
        uint256[] calldata effectivePeriods
    ) external;

    // @returns Returns ItemDefinition properties.
    // - Category
    // - enabled
    // - salables
    // - transferable
    // - effective period(milli second)
    function getDefinition(uint256 itemDefinitionId_) external view returns(string calldata, bool, bool, bool, uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IItemPackNFT {
    function getEnabled() external view returns(bool);
    function setEnabled(bool enabled) external;
    function mint(address to, uint256 quantity, uint256 itemPackDefinitionId) external;
    function burn(uint256 tokenId) external;
    function getTokens(address owner) external view returns(uint256[] memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

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
        for (uint256 i; i < tokenIds.length; i++) {
            tokenAndEditions[tokenIds[i]] = characterEditionId;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

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
pragma solidity ^0.8.0;

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

        for (uint i; i < itemDefinitionIds.length; i++) {
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
        for (uint256 i; i < itemDefinitionIds.length; i++) {
            result[i] = items[tokenId][itemDefinitionIds[i]];
        }

        return result;
    }

    function hasItem(uint256 tokenId, uint256 itemDefinitionId, int64 amount) public virtual view returns(bool) {
        return items[tokenId][itemDefinitionId] >= amount;
    }

    function getLastAcquisitionTimestamps(uint256 tokenId, uint256[] calldata itemDefinitionIds) public virtual view returns(uint256[] memory) {
        uint256[] memory result = new uint256[](itemDefinitionIds.length);
        for (uint256 i; i < itemDefinitionIds.length; i++) {
            result[i] = lastAcquisitionTimestamps[tokenId][itemDefinitionIds[i]];
        }

        return result;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./token/IL1NFT.sol";

interface IWorld {
    function setGame(address game_) external;
    function getL1NFT() external view returns(IL1NFT);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

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
        for (uint256 i; i < logIds.length; i++) {
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
pragma solidity ^0.8.0;

interface IGameAccess {
    function getInterfaceAddresses(uint256 worldId) external view returns(address[] memory);
    function getWorldOwnerAddresses(uint256 worldId) external view returns(address[] memory);
    function getWorldAdminAddresses(uint256 worldId) external view returns(address[] memory);
    function getGameAdminAddresses() external view returns(address[] memory);
    function getTokenOwnerAddress(uint256 worldId, uint256 tokenId) external view returns(address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IL1NFT {
    function getTokens(address owner) external view returns(uint256[] memory);
    function getOwner(uint256 tokenId) external view returns (address owner);
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
pragma solidity ^0.8.0;

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
        bool isInternal = checkAccess(msg.sender, _gameAccess.getInterfaceAddresses(_worldId));
        bool isGameOwner = checkAccess(msg.sender, _gameAccess.getWorldOwnerAddresses(_worldId));
        bool isOwner = msg.sender == owner();
        bool isGame = msg.sender == address(_gameAccess);

        require(isInternal || isGameOwner || isOwner || isGame, "WorldAccess: caller is not Game/Owner");
        _;
    }

    modifier onlyWorldAdmin() {
        bool isWorldAdmin = checkAccess(msg.sender, _gameAccess.getWorldAdminAddresses(_worldId));
        bool isGameOwner = checkAccess(msg.sender, _gameAccess.getWorldOwnerAddresses(_worldId));
        bool isOwner = msg.sender == owner();
        bool isGame = msg.sender == address(_gameAccess);

        require(isWorldAdmin || isGameOwner || isOwner || isGame, "WorldAccess: caller is not WorldAdmin");
        _;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IGameAccess.sol";

contract AccessControl is Ownable {
    IGameAccess internal _gameAccess;

    constructor(address gameAddress) {
        _gameAccess = IGameAccess(gameAddress);
    }

    modifier onlyGameOwner() {
        bool isGameOwner = checkAccess(msg.sender, _gameAccess.getGameAdminAddresses());
        bool isOwner = msg.sender == owner();
        bool isGame = msg.sender == address(_gameAccess);

        require(isGameOwner || isOwner || isGame, "WorldAccess: caller is not GameOwner");
        _;
    }

    function setGameAddress(address gameAddress) public virtual onlyGameOwner {
        _gameAccess = IGameAccess(gameAddress);
    }

    function checkAccess(address sender, address[] memory addresses) internal view returns(bool) {
        bool result = false;
        for (uint256 i; i < addresses.length; i++) {
            if (addresses[i] == sender) {
                result = true;
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

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