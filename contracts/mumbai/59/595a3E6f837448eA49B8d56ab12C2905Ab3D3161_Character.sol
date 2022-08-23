// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./CharacterDefinition.sol";

contract Character {
    uint256 public worldId;
    uint256 public tokenId;
    uint256 public characterDefinitionId;
    // key: statusSlotIndex, value: itemId
    mapping(uint256 => int64) public statuses;
    // key: equipmentSlotIndex, value: itemId
    mapping(uint256 => uint256) public equipments;
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
    function addItem(uint256 itemId, int64 value) public virtual {
        // TODO: check itemId
        items[itemId] += value;
    }

    // TODO: add access control modifier
    function addItems(uint256[] memory itemIds, int64[] memory amounts) public virtual {
        require(itemIds.length == amounts.length, "wrong length");

        for (uint256 i; i < itemIds.length; i++) {
            addItem(itemIds[i], amounts[i]);
        }
    }

    // TODO: add access control modifier
    function setEquipments(uint256[] memory itemIds) public virtual {
        for (uint256 equipmentSlotIndex; equipmentSlotIndex < itemIds.length; equipmentSlotIndex++) {
            uint256 itemId = itemIds[equipmentSlotIndex];
            uint256 oldItemId = equipments[equipmentSlotIndex];

            require(characterDefinition.isValidEquipmentSlot(characterDefinitionId, equipmentSlotIndex), "invalid propertyId");
            require(itemId == 0 || items[itemId] > 0, "No items");
            require(itemId == 0 || characterDefinition.canEquip(characterDefinitionId, itemId, equipmentSlotIndex), "Cannot equip");

            if (itemId > 0) {
                items[itemId] -= 1;
            }
            equipments[equipmentSlotIndex] = itemId;
            if (oldItemId > 0) {
                items[oldItemId] += 1;
            }
        }
    }

    function getEquipments() public virtual view returns(uint256[] memory) {
        CharacterDefinition.EquipmentSlot[] memory propertyTypes = characterDefinition.getEquipmentSlots(characterDefinitionId);
        uint256[] memory result = new uint256[](propertyTypes.length);
        for (uint256 i; i < propertyTypes.length; i++) {
            result[i] = equipments[i];
        }

        return result;
    }

    // TODO: add access control modifier
    function setStatus(uint256 statusSlotIndex, int64 value) public virtual {
        uint256[] memory statusSlots = characterDefinition.getStatusSlots(characterDefinitionId);
        uint256 itemId = statusSlots[statusSlotIndex];

        require(characterDefinition.isValidStatusSlot(characterDefinitionId, statusSlotIndex, itemId), "invalid statusSlotIndex");
        require(itemId != 0 || items[itemId] > value, "No items");

        items[itemId] -= value;
        statuses[statusSlotIndex] += value;
    }

    function getStatuses() public virtual view returns(int64[] memory) {
        uint256[] memory statusSlots = characterDefinition.getStatusSlots(characterDefinitionId);

        int64[] memory result = new int64[](statusSlots.length);
        for (uint256 i; i < statusSlots.length; i++) {
            result[i] = statuses[i];
        }

        return result;
    }

    function getItems(uint256[] memory itemIds) public virtual view returns(int64[] memory) {
        int64[] memory result = new int64[](itemIds.length);
        for (uint256 i; i < itemIds.length; i++) {
            result[i] = items[itemIds[i]];
        }

        return result;
    }

    function hasItem(uint256 itemId, int64 amount) public virtual view returns(bool) {
        return items[itemId] >= amount;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract CharacterDefinition {
    uint256 public worldId;

    enum EquipmentSlot { Invalid, Normal }
    enum ItemType { Invalid, Normal, Status }

    // key: characterDefinitionId
    mapping(uint256 => bool) characters;

    // key: characterDefinitionId
    mapping(uint256 => EquipmentSlot[]) public equipmentSlots;

    // key: characterDefinitionId, value: itemId[]
    mapping(uint256 => uint256[]) public statusSlots;

    // key: characterDefinitionId, value: (key: itemId, value: equipmentSlotIndex)
    mapping(uint256 => mapping(uint256 => uint256)) public equipableItems;

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
    function setStatusSlots(uint256 characterDefinitionId, uint256[] memory statusSlots_) public virtual {
        require(characters[characterDefinitionId] == true);
        require(statusSlots_.length > 0);

        statusSlots[characterDefinitionId] = statusSlots_;
    }

    function getStatusSlots(uint256 characterDefinitionId) public view virtual returns(uint256[] memory) {
        return statusSlots[characterDefinitionId];
    }

    function isValidStatusSlot(uint256 characterDefinitionId, uint256 statusSlotIndex, uint256 itemId) public view virtual returns(bool) {
        return statusSlotIndex >= 0 && statusSlotIndex < statusSlots[characterDefinitionId].length && statusSlots[characterDefinitionId][statusSlotIndex] == itemId;
    }

    // TODO: add access control modifier
    function setEquipable(uint256 characterDefinitionId, uint256 itemId, uint256 equipmentSlotIndex) public virtual {
        require(characters[characterDefinitionId] == true);

        equipableItems[characterDefinitionId][itemId] = equipmentSlotIndex;
    }

    function canEquip(uint256 characterDefinitionId, uint256 itemId, uint256 equipmentSlotIndex) public virtual view returns(bool) {
        return equipableItems[characterDefinitionId][itemId] == equipmentSlotIndex || itemId == 0;
    }
}