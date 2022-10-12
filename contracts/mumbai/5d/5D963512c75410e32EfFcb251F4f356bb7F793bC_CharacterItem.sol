// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ICharacterItem.sol";
import "../data/Character.sol";
import "../World.sol";
import "./GameBase.sol";

contract CharacterItem is ICharacterItem, GameBase {
    constructor(address game)
    GameBase(game) {
    }

    function getItems(uint256 worldId, uint256 tokenId, uint256[] memory itemDefinitionIds) external view virtual override returns(int64[] memory) {
        ItemStorage itemStorage = getWorld(worldId).itemStorage();
        Character character = getCharacter(worldId, tokenId);

        require(address(character) != address(0), "wrong tokenId or pre-reveal token");

        return itemStorage.getItems(tokenId, itemDefinitionIds);
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

interface ICharacterItem {
    event AddItem(uint256 indexed worldId, uint256 indexed tokenId, uint256 itemId);

    function getItems(uint256 worldId, uint256 tokenId, uint256[] memory itemDefinitionIds) external view returns(int64[] memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../definitions/CharacterDefinition.sol";

contract Character {
    uint256 public worldId;
    uint256 public tokenId;
    uint256 public characterDefinitionId;
    bool public isRevealed;

    // key: tokenId, value: characterDefinitionId
    mapping(uint256 => uint256) public characterDefinitionIds;
    // key: itemId, value: itemCount
    mapping(uint256 => int64) public items;
    CharacterDefinition public characterDefinition;

    constructor(uint256 worldId_, uint256 tokenId_, uint256 characterDefinitionId_, address characterDefinition_) {
        worldId = worldId_;
        tokenId = tokenId_;
        characterDefinitionId = characterDefinitionId_;
        characterDefinition = CharacterDefinition(characterDefinition_);
    }

    // TODO: add access control modifier
    function setIsRevealed(bool isRevealed_) public virtual {
        isRevealed = isRevealed_;
    }
}

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

contract World is Ownable, IWorld {
    IItemPackNFT[] private _itemPackNFTs;

    IGame public game;
    uint256 public worldId;

    uint256 private _characterIndex;
    uint256 private _characterDefinitionIndex;
    uint256 private _ItemDefinitionIndex;

    // key: tokenId
    mapping(uint256 => Character) public characters;

    CharacterDefinition public characterDefinition;
    IItemDefinition public itemDefinition;
    ItemPack public itemPack;
    ItemPackDefinition public itemPackDefinition;
    EventDefinition public eventDefinition;
    CharacterEdition public characterEdition;
    Equipment public equipment;
    ItemStorage public itemStorage;

    // key: commandDefinitionId
    mapping(uint256 => address) public commandDefinitions;

    constructor(address game_, uint256 worldId_) {
        worldId = worldId_;

        characterDefinition = new CharacterDefinition(worldId_);
        itemPack = new ItemPack(worldId_);
        itemPackDefinition = new ItemPackDefinition(worldId_);
        eventDefinition = new EventDefinition(worldId_);
        itemDefinition = new ItemDefinition(worldId_);
        characterEdition = new CharacterEdition(worldId_);
        equipment = new Equipment(worldId_, game_);
        itemStorage = new ItemStorage(worldId_, game_);
    }

    // TODO: add access control modifier
    function setGame(address game_) external override {
        game = IGame(game_);

        equipment.setGame(game_);
        itemStorage.setGame(game_);
    }

    // TODO: add access control modifier
    function setCharacterDefinition(address characterDefinition_) public {
        characterDefinition = CharacterDefinition(characterDefinition_);
    }

    // TODO: add access control modifier
    function addCharacter(uint256 tokenId, uint256 characterDefinitionId) public {
        characters[tokenId] = new Character(worldId, tokenId, characterDefinitionId, address(characterDefinition));
    }

    // TODO: add access control modifier
    function addItemPackNFT(address itemPackNFT) public {
        _itemPackNFTs.push(IItemPackNFT(itemPackNFT));
    }

    function getItemPackNFTs() public view returns(IItemPackNFT[] memory) {
        return _itemPackNFTs;
    }

    // TODO: add access control modifier
    function addCharacterDefinition(uint256 characterDefinitionId, CharacterDefinition.EquipmentSlot[] memory equipableSlots_, uint256[][] memory equipables_) public {
        characterDefinition.setCharacter(characterDefinitionId, true);
        characterDefinition.setEquipmentSlots(characterDefinitionId, equipableSlots_);

        for (uint256 i; i < equipables_.length; i++) {
            uint256[] memory equipable = equipables_[i];
            uint256 itemId = equipable[0];
            uint256 slotIndex = equipable[1];

            characterDefinition.setEquipable(characterDefinitionId, itemId, slotIndex);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

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

    function getCharacter(uint256 worldId, uint256 tokenId) internal view virtual returns(Character) {
        World world = getWorld(worldId);
        if (address(world) == address(0)) {
            return Character(address(0));
        }

        return world.characters(tokenId);
    }

    function getItemDefinition(uint256 worldId) internal view virtual returns(IItemDefinition) {
        World world = getWorld(worldId);
        if (address(world) == address(0)) {
            return IItemDefinition(address(0));
        }

        return world.itemDefinition();
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
pragma solidity ^0.8.0;

contract CharacterDefinition {
    uint256 public worldId;

    enum EquipmentSlot { Invalid, Normal }

    // key: characterDefinitionId
    mapping(uint256 => bool) characters;

    // key: characterDefinitionId
    mapping(uint256 => EquipmentSlot[]) public equipmentSlots;

    // key: characterDefinitionId, value: (key: itemId, value: equipmentSlotIndex)
    mapping(uint256 => mapping(uint256 => uint256)) public equipableItems;

    // key: characterDefinitionId, value: array of itemDefinitionId
    mapping(uint256 => uint256[]) public defaultEquipmentIds;

    constructor(uint256 worldId_) {
        worldId = worldId_;
    }

    // TODO: add access control modifier
    function setCharacter(uint256 characterDefinitionId, bool enabled) public virtual {
        require(characterDefinitionId > 0);

        characters[characterDefinitionId] = enabled;
    }

    // TODO: add access control modifier
    function setEquipmentSlots(uint256 characterDefinitionId, EquipmentSlot[] memory equipmentSlots_) public virtual {
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

    // TODO: add access control modifier
    function setEquipable(uint256 characterDefinitionId, uint256 itemId, uint256 equipmentSlotIndex) public virtual {
        require(characters[characterDefinitionId] == true);

        equipableItems[characterDefinitionId][itemId] = equipmentSlotIndex;
    }

    // TODO: add access control modifier
    function setDefaultEquipment(uint256 characterDefinitionId, uint256 itemId, uint256 equipmentSlotIndex) public {
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

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/definitions/IItemDefinition.sol";

contract ItemDefinition is IItemDefinition {
    uint256 public worldId;

    // key: itemDefinitionId
    mapping(uint256 => string) private _categories;
    mapping(uint256 => bool) private _enables;
    mapping(uint256 => bool) private _salables;
    mapping(uint256 => bool) private _transferables;
    mapping(uint256 => uint256) private _effectivePeriods;

    constructor(uint256 worldId_) {
        worldId = worldId_;
    }

    // TODO: add access control modifier
    function setDefinition(uint256 itemDefinitionId, string calldata category, bool enable, bool salable, bool transferable, uint256 effectivePeriod) external virtual {
        _categories[itemDefinitionId] = category;
        _enables[itemDefinitionId] = enable;
        _salables[itemDefinitionId] = salable;
        _transferables[itemDefinitionId] = transferable;
        _effectivePeriods[itemDefinitionId] = effectivePeriod;
    }

    function setDefinitions(
        uint256[] calldata itemDefinitionIds,
        string[] calldata categories,
        bool[] calldata enables,
        bool[] calldata salables,
        bool[] calldata transferables,
        uint256[] calldata effectivePeriods
    ) external virtual {
        require(itemDefinitionIds.length == categories.length, "wrong length");
        require(itemDefinitionIds.length == enables.length, "wrong length");
        require(itemDefinitionIds.length == salables.length, "wrong length");
        require(itemDefinitionIds.length == transferables.length, "wrong length");
        require(itemDefinitionIds.length == effectivePeriods.length, "wrong length");

        for (uint256 i; i < itemDefinitionIds.length; i++) {
            this.setDefinition(
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

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract EventDefinition {
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

    uint256 public worldId;
    mapping(uint256 => EventDefinitionRecord) private _eventDefinitions;

    constructor(uint256 worldId_) {
        worldId = worldId_;
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

    // TODO: add access control modifier
    function setEventDefinitions(EventDefinitionRecord[] memory eventDefinitions_) public virtual {
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

contract ItemPackDefinition {
    struct SlotDefinition {
        uint256[] itemDefinitionIds;
        uint256[] weights;
        int64[] amounts;
    }

    uint256 public worldId;

    // key: itemPackDefinitionId
    mapping(uint256 => SlotDefinition[]) private _slotDefinitions;

    constructor(uint256 worldId_) {
        worldId = worldId_;
    }

    function getSlotLength(uint256 itemPackDefinitionId) public virtual view returns(uint256) {
        return _slotDefinitions[itemPackDefinitionId].length;
    }

    function getSlotDefinition(uint256 itemPackDefinitionId, uint256 slot) public virtual view returns(uint256[] memory, uint256[] memory, int64[] memory) {
        SlotDefinition memory s = _slotDefinitions[itemPackDefinitionId][slot];

        return (s.itemDefinitionIds, s.weights, s.amounts);
    }

    // TODO:　add access control modifier
    function setItemPackDefinition(uint256 itemPackDefinitionId, SlotDefinition[] memory itemPacks) public virtual {
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
    function setDefinition(uint256 itemDefinitionId, string calldata category, bool enable, bool salable, bool transferable, uint256 effectivePeriod) external;
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

contract CharacterEdition {
    struct CharacterEditionRecord {
        uint256 characterEditionId;
        uint256[] characterDefinitionIds;
        uint256[] weights;
        uint256[][] itemPackDefinitionIds;
    }

    uint256 public worldId;

    // key: characterEditionId, (key: characterDefinitionId, value: CharacterDefinitionId)
    mapping(uint256 => CharacterEditionRecord) public records;
    // key: tokenId, value: characterEditionId
    mapping(uint256 => uint256) public tokenAndEditions;

    constructor(uint256 worldId_) {
        worldId = worldId_;
    }

    function getCharacterEditionRecord(uint256 characterEditionId) public view returns(CharacterEditionRecord memory) {
        return records[characterEditionId];
    }

    // TODO: add access control modifier
    function setCharacterEdition(uint256 characterEditionId, CharacterEditionRecord calldata record) public {
        records[characterEditionId] = record;
    }

    // TODO: add access control modifier
    function setTokenIdsToCharacterEdition(uint256 characterEditionId, uint256[] calldata tokenIds) public {
        for (uint256 i; i < tokenIds.length; i++) {
            tokenAndEditions[tokenIds[i]] = characterEditionId;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../access/GameOnly.sol";

contract Equipment is GameOnly {
    // key: tokenId, value: array of equipped itemId
    mapping(uint256 => uint256[]) public equipments;

    constructor(uint256 worldId, address gameAddress)
    GameOnly(worldId, gameAddress) {
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

import "../access/GameOnly.sol";

contract ItemStorage is GameOnly {
    // key: tokenId, (key: itemDefinitionId, value: itemCount)
    mapping(uint256 => mapping(uint256 => int64)) public items;

    // key: tokenId, (key: itemDefinitionId, value: timestamp)
    mapping(uint256 => mapping(uint256 => uint256)) public lastAcquisitionTimestamps;

    constructor(uint256 worldId, address gameAddress)
    GameOnly(worldId, gameAddress) {
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

interface IWorld {
    function setGame(address game_) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IGame.sol";

contract GameOnly is Ownable {
    IGame private _game;
    uint256 private _worldId;

    constructor(uint256 worldId, address gameAddress) {
        _worldId = worldId;
        _game = IGame(gameAddress);
    }

    modifier onlyGame() {
        address[] memory addresses = _game.getInterfaceAddresses(_worldId);
        bool isInternal = checkAccess(msg.sender, addresses);
        bool isOwner = msg.sender == owner();

        require(isInternal || isOwner, "GameOnly: caller is not Game/Owner");
        _;
    }

    function setGame(address gameAddress) public virtual onlyGame {
        _game = IGame(gameAddress);
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
pragma solidity ^0.8.0;

interface IGame {
    function getInterfaceAddresses(uint256 worldId) external view returns(address[] memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ICharacterEquipment.sol";
import "./interfaces/ICharacterItem.sol";
import "./interfaces/ICharacterReveal.sol";
import "./interfaces/IItemTransfer.sol";
import "./interfaces/IItemPackReveal.sol";
import "./interfaces/IEventCheckin.sol";
import "./interfaces/IGame.sol";
import "./interfaces/IItemAcquisitionHistory.sol";
import "./interfaces/IWorld.sol";

contract Game is IGame, Ownable {
    mapping(uint256 => address) public worlds;

    ICharacterEquipment public characterEquipment;
    ICharacterItem public characterItem;
    ICharacterReveal public characterReveal;
    IItemTransfer public itemTransfer;
    IEventCheckin public eventCheckin;
    IItemPackReveal public itemPackReveal;
    IItemAcquisitionHistory public itemAcquisitionHistory;

    constructor() {
    }

    function setCharacterEquipment(address characterEquipment_) public onlyOwner {
        characterEquipment = ICharacterEquipment(characterEquipment_);
    }

    function setCharacterItem(address characterItem_) public onlyOwner {
        characterItem = ICharacterItem(characterItem_);
    }

    function setCharacterReveal(address characterReveal_) public onlyOwner {
        characterReveal = ICharacterReveal(characterReveal_);
    }

    function setItemTransfer(address itemTransfer_) public onlyOwner {
        itemTransfer = IItemTransfer(itemTransfer_);
    }

    function setEventCheckin(address eventCheckin_) public onlyOwner {
        eventCheckin = IEventCheckin(eventCheckin_);
    }

    function setItemPackReveal(address itemPackReveal_) public onlyOwner {
        itemPackReveal = IItemPackReveal(itemPackReveal_);
    }

    function setItemAcquisitionHistory(address itemAcquisitionHistory_) public onlyOwner {
        itemAcquisitionHistory = IItemAcquisitionHistory(itemAcquisitionHistory_);
    }

    function setWorld(uint256 worldId, address worldAddress) public onlyOwner {
        worlds[worldId] = worldAddress;
        IWorld world = IWorld(worldAddress);
        world.setGame(address(this));
    }

    function getInterfaceAddresses(uint256 worldId) external view override returns(address[] memory) {
        address[] memory addresses = new address[](9);
        addresses[0] = address(characterEquipment);
        addresses[1] = address(characterItem);
        addresses[2] = address(characterReveal);
        addresses[3] = address(itemTransfer);
        addresses[4] = address(eventCheckin);
        addresses[5] = address(itemPackReveal);
        addresses[6] = address(itemAcquisitionHistory);
        addresses[7] = worlds[worldId];
        addresses[8] = this.owner();

        return addresses;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ICharacterEquipment {
    struct EquipValidationResult {
        bool validWorldId;
        bool validTokenId;
        // If the length of the equip slot is exceeded, it becomes false.
        bool validItemDefinitionIdLength;
        // Whether the equip slot is disabled
        bool[] validSlots;
        bool[] validItemDefinitionIds;
        bool[] equipableItems;
        bool[] validItemCounts;
    }

    event Equip(uint256 indexed worldId, uint256 indexed tokenId, uint256[] itemIds);

    function equip(uint256 worldId, uint256 tokenId, uint256[] calldata itemDefinitionIds) external;

    function validateEquip(uint256 worldId, uint256 tokenId, uint256[] calldata itemDefinitionIds) external view returns(EquipValidationResult memory);

    // Returns an array of Equipment itemDefinitionId
    function getEquipments(uint256 worldId, uint256 tokenId) external view returns(uint256[] memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ICharacterReveal {
    struct RevealStateRecord {
        uint256 characterDefinitionId;
        bool isRevealed;
    }

    event Reveal(uint256 indexed worldId, uint256 indexed tokenId, uint256 indexed characterDefinitionId);

    function reveal(uint256 worldId, uint256 tokenId) external;

    function getRevealState(uint256 worldId, uint256 tokenId) external view returns(RevealStateRecord memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IItemTransfer {
    struct TransferRecord {
        uint256 worldId;
        uint256 tokenId;
        uint256 targetTokenId;
        uint256[] itemDefinitionIds;
        int64[] amounts;
    }

    struct TransferValidationResult {
        bool validWorldId;
        bool validTokenId;
        bool validTargetTokenId;
        // length check for itemDefinitionIds and amounts
        bool validLength;
        bool[] validTransferables;
        bool[] validAmounts;
    }

    event TransferItems(uint256 indexed worldId, uint256 indexed tokenId, uint256 indexed targetTokenId, uint256[] itemDefinitionIds, int64[] amounts);

    function transfer(TransferRecord calldata record) external;

    // @returns validate transfer items
    function validateTransfer(TransferRecord calldata record) external view returns(TransferValidationResult memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IItemPackReveal {
    struct ItemPackRecord {
        uint256 itemPackId;
        uint256 itemPackDefinitionId;

        // if not associated with NFT, tokenId will be 0
        uint256 tokenId;
    }

    event RevealItemPack(uint256 indexed worldId, uint256 indexed tokenId, uint256 indexed itemPackId, uint256[] itemDefinitionIds, int64[] amounts);

    function reveal(uint256 worldId, uint256 tokenId, uint256 itemPackId) external;

    function isRevealed(uint256 worldId, uint256 itemPackId) external view returns(bool);

    function getItemPacks(address playerWallet, uint256 worldId) external view returns(ItemPackRecord[] memory);

    function getItemPacksAssociatedWithNFT(address playerWallet, uint256 worldId) external view returns(ItemPackRecord[] memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IEventCheckin {
    event Checkin(address indexed playerWallet, uint256 indexed worldId, uint256 eventDefinitionId);

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
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IItemAcquisitionHistory {
    function getLastAcquisitionTimestamps(uint256 worldId, uint256 tokenId, uint256[] calldata itemDefinitionIds) external view returns(uint256[] memory);
}