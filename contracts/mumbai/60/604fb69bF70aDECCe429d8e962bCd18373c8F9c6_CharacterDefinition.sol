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