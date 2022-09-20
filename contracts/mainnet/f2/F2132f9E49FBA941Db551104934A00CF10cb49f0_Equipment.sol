// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "../interfaces/ICivilizations.sol";
import "../interfaces/IExperience.sol";
import "../interfaces/IEquipment.sol";
import "../interfaces/IItems.sol";
import "../interfaces/IStats.sol";

/**
 * @title Equipment
 * @notice This contract enables characters to equip/unequip `ERC1155` tokens stored through the [Items](/docs/items/Items.md) implementation.
 *
 * @notice Implementation of the [IEquipment](/docs/interfaces/IEquipment.md) interface.
 */
contract Equipment is IEquipment, Ownable, ERC1155Holder, Pausable {
    // =============================================== Storage ========================================================

    /** @notice Address of the [Civilizations](/docs/core/Civilizations.md) instance. */
    address public civilizations;

    /** @notice Address of the [Experience](/docs/core/Experience.md) instance. */
    address public experience;

    /** @notice Address of the [Items](/docs/items/Items.md) instance. */
    address public items;

    /** @notice Map to track the equipment of characters. */
    mapping(bytes => mapping(EquipmentSlot => ItemEquiped)) character_equipments;

    /** @notice Map to track the equipment slots and its attachable items. */
    mapping(EquipmentSlot => mapping(IItems.ItemType => bool)) slots_types;

    // =============================================== Modifiers ======================================================

    /**
     * @notice Checks against the [Civilizations](/docs/core/Civilizations.md) instance if the `msg.sender` is the owner or
     * has allowance to access a composed ID.
     *
     * Requirements:
     * @param _id   Composed ID of the character.
     */
    modifier onlyAllowed(bytes memory _id) {
        require(
            ICivilizations(civilizations).exists(_id),
            "Equipment: onlyAllowed() token not minted."
        );
        require(
            ICivilizations(civilizations).isAllowed(msg.sender, _id),
            "Equipment: onlyAllowed() msg.sender is not allowed to access this token."
        );
        _;
    }

    // =============================================== Events =========================================================

    /**
     * @notice Event emmited when the [equip](#equip) function is called.
     *
     * Requirements:
     * @param _id       Composed ID of the character.
     * @param _slot     Slot of the item equiped.
     * @param _item_id  ID of the item equipped.
     */
    event Equipped(bytes _id, EquipmentSlot _slot, uint256 _item_id);

    /**
     * @notice Event emmited when the [unequip](#unequip) function is called.
     *
     * Requirements:
     * @param _id       Composed ID of the character.
     * @param _slot     Slot of the item unequipped.
     */
    event Unequipped(bytes _id, EquipmentSlot _slot);

    // =============================================== Setters ========================================================

    /**
     * @notice Constructor.
     *
     * Requirements:
     * @param _civilizations    The address of the [Civilizations](/docs/core/Civilizations.md) instance.
     * @param _experience       The address of the [Experience](/docs/core/Experience.md) instance.
     * @param _items            The address of the [Items](/docs/items/Items.md) instance.
     */
    constructor(
        address _civilizations,
        address _experience,
        address _items
    ) {
        civilizations = _civilizations;
        experience = _experience;
        items = _items;

        slots_types[EquipmentSlot.HELMET][IItems.ItemType.HELMET] = true;
        slots_types[EquipmentSlot.SHOULDER_GUARDS][
            IItems.ItemType.SHOULDER_GUARDS
        ] = true;
        slots_types[EquipmentSlot.ARM_GUARDS][
            IItems.ItemType.ARM_GUARDS
        ] = true;
        slots_types[EquipmentSlot.HANDS][IItems.ItemType.HANDS] = true;
        slots_types[EquipmentSlot.RING][IItems.ItemType.RING] = true;
        slots_types[EquipmentSlot.NECKLACE][IItems.ItemType.NECKLACE] = true;
        slots_types[EquipmentSlot.CHEST][IItems.ItemType.CHEST] = true;
        slots_types[EquipmentSlot.LEGS][IItems.ItemType.LEGS] = true;
        slots_types[EquipmentSlot.BELT][IItems.ItemType.BELT] = true;
        slots_types[EquipmentSlot.FEET][IItems.ItemType.FEET] = true;
        slots_types[EquipmentSlot.CAPE][IItems.ItemType.CAPE] = true;
        slots_types[EquipmentSlot.LEFT_HAND][IItems.ItemType.ONE_HANDED] = true;
        slots_types[EquipmentSlot.LEFT_HAND][IItems.ItemType.TWO_HANDED] = true;
        slots_types[EquipmentSlot.RIGHT_HAND][
            IItems.ItemType.ONE_HANDED
        ] = true;
    }

    /** @notice Pauses the contract */
    function pause() public onlyOwner {
        _pause();
    }

    /** @notice Resumes the contract */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @notice Assigns an item to a character equipment slot. If the slot already has an equiped item
     * it is replaced by the item being equiped.
     *
     * Requirements:
     * @param _id       Composed ID of the character.
     * @param _slot     Slot to equip the item.
     * @param _item_id  ID of the item to equip.
     */
    function equip(
        bytes memory _id,
        EquipmentSlot _slot,
        uint256 _item_id
    ) public whenNotPaused onlyAllowed(_id) {
        IItems.Item memory item_data = IItems(items).getItem(_item_id);

        require(
            slots_types[_slot][item_data.item_type],
            "Equipment: equip() item type not for this slot."
        );

        require(
            IExperience(experience).getLevel(_id) >= item_data.level_required,
            "Equipment: equip() not enough level to equip item."
        );

        if (item_data.item_type == IItems.ItemType.TWO_HANDED) {
            if (character_equipments[_id][EquipmentSlot.RIGHT_HAND].equiped) {
                unequip(_id, EquipmentSlot.RIGHT_HAND);
            }
        }

        if (character_equipments[_id][_slot].equiped) {
            unequip(_id, _slot);
        }

        IERC1155(items).safeTransferFrom(
            msg.sender,
            address(this),
            _item_id,
            1,
            ""
        );

        character_equipments[_id][_slot].equiped = true;
        character_equipments[_id][_slot].id = _item_id;
        emit Equipped(_id, _slot, _item_id);
    }

    /**
     * @notice Removes an item from a character equipment slot.
     *
     * Requirements:
     * @param _id   Composed ID of the character.
     * @param _slot Slot to equip the item.
     */
    function unequip(bytes memory _id, EquipmentSlot _slot)
        public
        whenNotPaused
        onlyAllowed(_id)
    {
        require(
            character_equipments[_id][_slot].equiped,
            "Equipment: unequip() item slot not equiped."
        );

        uint256 item_id = character_equipments[_id][_slot].id;
        character_equipments[_id][_slot].equiped = false;
        character_equipments[_id][_slot].id = 0;

        IERC1155(items).safeTransferFrom(
            address(this),
            ICivilizations(civilizations).ownerOf(_id),
            item_id,
            1,
            ""
        );
        emit Unequipped(_id, _slot);
    }

    // =============================================== Getters ========================================================

    /**
     * @notice External function to return the character slots and items attached.
     *
     * Requirements:
     * @param _id   Composed ID of the character.
     */
    function getCharacterEquipment(bytes memory _id)
        public
        view
        returns (CharacterEquipment memory)
    {
        return
            CharacterEquipment(
                character_equipments[_id][EquipmentSlot.HELMET],
                character_equipments[_id][EquipmentSlot.SHOULDER_GUARDS],
                character_equipments[_id][EquipmentSlot.ARM_GUARDS],
                character_equipments[_id][EquipmentSlot.HANDS],
                character_equipments[_id][EquipmentSlot.RING],
                character_equipments[_id][EquipmentSlot.NECKLACE],
                character_equipments[_id][EquipmentSlot.CHEST],
                character_equipments[_id][EquipmentSlot.LEGS],
                character_equipments[_id][EquipmentSlot.BELT],
                character_equipments[_id][EquipmentSlot.FEET],
                character_equipments[_id][EquipmentSlot.CAPE],
                character_equipments[_id][EquipmentSlot.LEFT_HAND],
                character_equipments[_id][EquipmentSlot.RIGHT_HAND]
            );
    }

    /**
     * @notice External function to return the character stats modifiers.
     *
     * Requirements:
     * @param _id           Composed ID of the character.
     *
     * @return _modifiers   The total modifiers.
     */
    function getCharacterTotalStatsModifiers(bytes memory _id)
        public
        view
        returns (IStats.BasicStats memory _modifiers)
    {
        IStats.BasicStats memory _additions;
        IStats.BasicStats memory _reductions;

        for (uint256 i = 0; i < 13; i++) {
            ItemEquiped memory _slot = character_equipments[_id][
                EquipmentSlot(i)
            ];
            if (_slot.equiped) {
                IItems.Item memory _item = IItems(items).getItem(_slot.id);

                _additions.might += _item.stats_modifiers.might;
                _additions.speed += _item.stats_modifiers.speed;
                _additions.intellect += _item.stats_modifiers.intellect;
                _reductions.might += _item.stats_modifiers.might_reducer;
                _reductions.speed += _item.stats_modifiers.speed_reducer;
                _reductions.intellect += _item
                    .stats_modifiers
                    .intellect_reducer;
            }
        }

        if (_reductions.might <= _additions.might) {
            _modifiers.might = _additions.might - _reductions.might;
        }
        if (_reductions.speed <= _additions.speed) {
            _modifiers.speed = _additions.speed - _reductions.speed;
        }
        if (_reductions.intellect <= _additions.intellect) {
            _modifiers.intellect = _additions.intellect - _reductions.intellect;
        }
    }

    /**
     * @notice External function to return the character total attributes modifiers.
     *
     * Requirements:
     * @param _id           Composed ID of the character.
     *
     * @return _modifiers   The amount of modifiers.
     */
    function getCharacterTotalAttributes(bytes memory _id)
        public
        view
        returns (IItems.BaseAttributes memory _modifiers)
    {
        IItems.BaseAttributes memory _additions;
        IItems.BaseAttributes memory _reductions;
        for (uint256 i = 0; i < 13; i++) {
            ItemEquiped memory _slot = character_equipments[_id][
                EquipmentSlot(i)
            ];

            if (_slot.equiped) {
                IItems.Item memory _item = IItems(items).getItem(_slot.id);

                _additions.atk += _item.attributes.atk;
                _additions.def += _item.attributes.def;
                _additions.range += _item.attributes.range;
                _additions.mag_atk += _item.attributes.mag_atk;
                _additions.mag_def += _item.attributes.mag_def;
                _additions.rate += _item.attributes.rate;

                _reductions.atk += _item.attributes.atk_reducer;
                _reductions.def += _item.attributes.def_reducer;
                _reductions.range += _item.attributes.range_reducer;
                _reductions.mag_atk += _item.attributes.mag_atk_reducer;
                _reductions.mag_def += _item.attributes.mag_def_reducer;
                _reductions.rate += _item.attributes.rate_reducer;
            }
        }

        if (_reductions.atk <= _additions.atk) {
            _modifiers.atk = _additions.atk - _reductions.atk;
        }

        if (_reductions.def <= _additions.def) {
            _modifiers.def = _additions.def - _reductions.def;
        }

        if (_reductions.range <= _additions.range) {
            _modifiers.range = _additions.range - _reductions.range;
        }

        if (_reductions.mag_atk <= _additions.mag_atk) {
            _modifiers.mag_atk = _additions.mag_atk - _reductions.mag_atk;
        }

        if (_reductions.mag_def <= _additions.mag_def) {
            _modifiers.mag_def = _additions.mag_def - _reductions.mag_def;
        }

        if (_reductions.rate <= _additions.rate) {
            _modifiers.rate = _additions.rate - _reductions.rate;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title ICivilizations
 * @notice Interface for the [Civilizations](/docs/core/Civilizations.md) contract.
 */
interface ICivilizations {
    /**
     * @notice Internal struct to store the global state of an upgrade.
     *
     * Requirements:
     * @param price         Price to purchase the upgrade.
     * @param available     Status of the purchase mechanism for the upgrade.
     */
    struct Upgrade {
        uint256 price;
        bool available;
    }

    /** @notice See [Civilizations#pause](/docs/core/Civilizations.md#pause) */
    function pause() external;

    /** @notice See [Civilizations#unpause](/docs/core/Civilizations.md#unpause) */
    function unpause() external;

    /** @notice See [Civilizations#setInitializeUpgrade](/docs/core/Civilizations.md#setInitializeUpgrade) */
    function setInitializeUpgrade(uint256 _upgrade_id, bool _available)
        external;

    /** @notice See [Civilizations#setUpgradePrice](/docs/core/Civilizations.md#setUpgradePrice) */
    function setUpgradePrice(uint256 _upgrade_id, uint256 _price) external;

    /** @notice See [Civilizations#setMintPrice](/docs/core/Civilizations.md#setMintPrice) */
    function setMintPrice(uint256 _price) external;

    /** @notice See [Civilizations#setToken](/docs/core/Civilizations.md#setToken) */
    function setToken(address _token) external;

    /** @notice See [Civilizations#addCivilization](/docs/core/Civilizations.md#addCivilization) */
    function addCivilization(address _civilization) external;

    /** @notice See [Civilizations#mint](/docs/core/Civilizations.md#mint) */
    function mint(uint256 _civilization_id) external;

    /** @notice See [Civilizations#buyUpgrade](/docs/core/Civilizations.md#buyUpgrade) */
    function buyUpgrade(bytes memory _id, uint256 _upgrade_id) external;

    /** @notice See [Civilizations#getCharacterUpgrades](/docs/core/Civilizations.md#getCharacterUpgrades) */
    function getCharacterUpgrades(bytes memory _id)
        external
        view
        returns (bool[3] memory _upgrades);

    /** @notice See [Civilizations#getUpgradeInformation](/docs/core/Civilizations.md#getUpgradeInformation) */
    function getUpgradeInformation(uint256 _upgrade_id)
        external
        view
        returns (Upgrade memory _upgrade);

    /** @notice See [Civilizations#getTokenID](/docs/core/Civilizations.md#getTokenID) */
    function getTokenID(uint256 _civilization_id, uint256 _token_id)
        external
        view
        returns (bytes memory _id);

    /** @notice See [Civilizations#isAllowed](/docs/core/Civilizations.md#isAllowed) */
    function isAllowed(address _spender, bytes memory _id)
        external
        view
        returns (bool _allowed);

    /** @notice See [Civilizations#exists](/docs/core/Civilizations.md#exists) */
    function exists(bytes memory _id) external view returns (bool _exist);

    /** @notice See [Civilizations#ownerOf](/docs/core/Civilizations.md#ownerOf) */
    function ownerOf(bytes memory _id) external view returns (address _owner);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title IExperience
 * @notice Interface for the [Experience](/docs/core/Experience.md) contract.
 */
interface IExperience {
    /** @notice See [Experience#setLevel](/docs/core/Experience.md#setLevel) */
    function setLevels(address _levels) external;

    /** @notice See [Experience#assignExperience](/docs/core/Experience.md#assignExperience) */
    function assignExperience(bytes memory _id, uint256 _amount) external;

    /** @notice See [Experience#addAuthority](/docs/core/Experience.md#addAuthority) */
    function addAuthority(address _authority) external;

    /** @notice See [Experience#removeAuthority](/docs/core/Experience.md#removeAuthority) */
    function removeAuthority(address _authority) external;

    /** @notice See [Experience#getExperience](/docs/core/Experience.md#getExperience) */
    function getExperience(bytes memory _id)
        external
        view
        returns (uint256 _experience);

    /** @notice See [Experience#getLevel](/docs/core/Experience.md#getLevel) */
    function getLevel(bytes memory _id) external view returns (uint256 _level);

    /** @notice See [Experience#getExperienceForNextLevel](/docs/core/Experience.md#getExperienceForNextLevel) */
    function getExperienceForNextLevel(bytes memory _id)
        external
        view
        returns (uint256 _experience);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/IStats.sol";
import "../interfaces/IItems.sol";

/**
 * @title IEquipment
 * @notice Interface for the [Equipment](/docs/core/Equipment.md) contract.
 */
interface IEquipment {
    /**
     * @notice Internal struct to store the information of an equipment slot.
     *
     * Requirements:
     * @param id        ID of the item equiped.
     * @param equiped   Boolean to determine if the slot is being used.
     */
    struct ItemEquiped {
        uint256 id;
        bool equiped;
    }

    /** @notice Enum to define the different slots that can be equiped */
    enum EquipmentSlot {
        HELMET,
        SHOULDER_GUARDS,
        ARM_GUARDS,
        HANDS,
        RING,
        NECKLACE,
        CHEST,
        LEGS,
        BELT,
        FEET,
        CAPE,
        LEFT_HAND,
        RIGHT_HAND
    }

    /**
     * @notice Struct to expose the information of a character equipment.
     *
     * Requirements:
     * @param helmet            Slot for the HELMET slot.
     * @param shoulder_guards   Slot for the SHOULDER_GUARDS slot.
     * @param arm_guards        Slot for the ARM_GUARDS slot.
     * @param hands             Slot for the HANDS slot.
     * @param rings             Slot for the RING slot.
     * @param necklace          Slot for the NECKLACE slot.
     * @param ichestd           Slot for the CHEST slot.
     * @param legs              Slot for the LEGS slot.
     * @param belt              Slot for the BELT slot.
     * @param feet              Slot for the FEET slot.
     * @param cape              Slot for the CAPE slot.
     * @param left_hand         Slot for the LEFT_HAND slot.
     * @param right_hand        Slot for the RIGHT_HAND slot.
     */
    struct CharacterEquipment {
        ItemEquiped helmet;
        ItemEquiped shoulder_guards;
        ItemEquiped arm_guards;
        ItemEquiped hands;
        ItemEquiped rings;
        ItemEquiped necklace;
        ItemEquiped chest;
        ItemEquiped legs;
        ItemEquiped belt;
        ItemEquiped feet;
        ItemEquiped cape;
        ItemEquiped left_hand;
        ItemEquiped right_hand;
    }

    /** @notice See [Equipment#pause](/docs/core/Equipment.md#pause) */
    function pause() external;

    /** @notice See [Equipment#unpause](/docs/core/Equipment.md#unpause) */
    function unpause() external;

    /** @notice See [Equipment#equip](/docs/core/Equipment.md#equip) */
    function equip(
        bytes memory _id,
        EquipmentSlot _slot,
        uint256 _item_id
    ) external;

    /** @notice See [Equipment#unequip](/docs/core/Equipment.md#unequip) */
    function unequip(bytes memory _id, EquipmentSlot _slot) external;

    /** @notice See [Equipment#getCharacterEquipment](/docs/core/Equipment.md#getCharacterEquipment) */
    function getCharacterEquipment(bytes memory _id)
        external
        view
        returns (CharacterEquipment memory);

    /** @notice See [Equipment#getCharacterTotalStatsModifiers](/docs/core/Equipment.md#getCharacterTotalStatsModifiers) */
    function getCharacterTotalStatsModifiers(bytes memory _id)
        external
        view
        returns (IStats.BasicStats memory _modifiers);

    /** @notice See [Equipment#getCharacterTotalAttributes](/docs/core/Equipment.md#getCharacterTotalAttributes) */
    function getCharacterTotalAttributes(bytes memory _id)
        external
        view
        returns (IItems.BaseAttributes memory _modifiers);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title IStats
 * @notice Interface for the [Stats](/docs/core/Stats.md) contract.
 */
interface IStats {
    /**
     * @notice Internal struct for the character stats.
     *
     * Requirements:
     * @param might     The amount of points for the might stat.
     * @param speed     The amount of points for the speed stat.
     * @param intellect The amount of points for the intellect stat.
     */
    struct BasicStats {
        uint256 might;
        uint256 speed;
        uint256 intellect;
    }

    /** @notice See [Stats#pause](/docs/codex/Stats.md#pause) */
    function pause() external;

    /** @notice See [Stats#unpause](/docs/codex/Stats.md#unpause) */
    function unpause() external;

    /** @notice See [Stats#setRefreshCooldown](/docs/codex/Stats.md#setRefreshCooldown) */
    function setRefreshCooldown(uint256 _cooldown) external;

    /** @notice See [Stats#setRefreshToken](/docs/codex/Stats.md#setRefreshToken) */
    function setRefreshToken(address _refresher) external;

    /** @notice See [Stats#setVitalizerToken](/docs/codex/Stats.md#setVitalizerToken) */
    function setVitalizerToken(address _vitalizer) external;

    /** @notice See [Stats#consume](/docs/codex/Stats.md#consume) */
    function consume(bytes memory _id, BasicStats memory _stats) external;

    /** @notice See [Stats#sacrifice](/docs/codex/Stats.md#sacrifice) */
    function sacrifice(bytes memory _id, BasicStats memory _stats) external;

    /** @notice See [Stats#refresh](/docs/codex/Stats.md#refresh) */
    function refresh(bytes memory _id) external;

    /** @notice See [Stats#refreshWithToken](/docs/codex/Stats.md#refreshWithToken) */
    function refreshWithToken(bytes memory _id) external;

    /** @notice See [Stats#vitalize](/docs/codex/Stats.md#vitalize) */
    function vitalize(bytes memory _id, BasicStats memory _stats) external;

    /** @notice See [Stats#assignPoints](/docs/codex/Stats.md#assignPoints) */
    function assignPoints(bytes memory _id, BasicStats memory _stats) external;

    /** @notice See [Stats#getBaseStats](/docs/codex/Stats.md#getBaseStats) */
    function getBaseStats(bytes memory _id)
        external
        view
        returns (BasicStats memory _stats);

    /** @notice See [Stats#getPoolStats](/docs/codex/Stats.md#getPoolStats) */
    function getPoolStats(bytes memory _id)
        external
        view
        returns (BasicStats memory _stats);

    /** @notice See [Stats#getAvailablePoints](/docs/codex/Stats.md#getAvailablePoints) */
    function getAvailablePoints(bytes memory _id)
        external
        view
        returns (uint256 _points);

    /** @notice See [Stats#getNextRefreshTime](/docs/codex/Stats.md#getNextRefreshTime) */
    function getNextRefreshTime(bytes memory _id)
        external
        view
        returns (uint256 _timestamp);

    /** @notice See [Stats#getNextRefreshWithTokenTime](/docs/codex/Stats.md#getNextRefreshWithTokenTime) */
    function getNextRefreshWithTokenTime(bytes memory _id)
        external
        view
        returns (uint256 _timestamp);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title IItems
 * @notice Interface for the [Items](/docs/items/Items.md) contract.
 */
interface IItems {
    /**
     * @notice Internal struct to store the item properties.
     *
     * Requirements:
     * @param id                The id of the item.
     * @param name              The name of the item.
     * @param description       The description of the item
     * @param level_required    The minimum level required to equip the item.
     * @param item_type         The item type to use for the equipment slot.
     * @param stat_modifiers    The modifiers that add or removes from the character pool.
     * @param attributes        The base item attributes.
     * @param available         Boolean to check if the item is available to be equiped.
     */
    struct Item {
        uint256 id;
        string name;
        string description;
        uint256 level_required;
        ItemType item_type;
        StatsModifiers stats_modifiers;
        Attributes attributes;
        bool available;
    }

    /** @notice Enum to define different item types. */
    enum ItemType {
        HELMET,
        SHOULDER_GUARDS,
        ARM_GUARDS,
        HANDS,
        RING,
        NECKLACE,
        CHEST,
        LEGS,
        BELT,
        FEET,
        CAPE,
        ONE_HANDED,
        TWO_HANDED
    }

    /**
     * @notice Internal struct to store the item [IStats.BasicStats](/docs/interfaces/IStats.md#BasicStats) modifiers.
     *
     * Requirements:
     * @param might             The amount of might points added to the stats pool.
     * @param might_reducer     The amount of might points reduced to the stats pool.
     * @param speed             The amount of speed points added to the stats pool.
     * @param speed_reducer     The amount of speed points reduced to the stats pool.
     * @param intellect         The amount of intellect points added to the stats pool.
     * @param intellect_reducer The amount of intellect points reduced to the stats pool.
     */
    struct StatsModifiers {
        uint256 might;
        uint256 might_reducer;
        uint256 speed;
        uint256 speed_reducer;
        uint256 intellect;
        uint256 intellect_reducer;
    }

    /**
     * @notice Internal struct to store the base combat attributes of an item.
     *
     * Requirements:
     * @param atk       The amount of attack points of the item.
     * @param def       The amount of defence points of the item.
     * @param range     The amount of range points of the item.
     * @param mag_atk   The amount of magical attack points of the item.
     * @param mag_def   The amount of magical defence points of the item.
     * @param rate      The rate speed points of the item.
     */
    struct BaseAttributes {
        uint256 atk;
        uint256 def;
        uint256 range;
        uint256 mag_atk;
        uint256 mag_def;
        uint256 rate;
    }

    /**
     * @notice Internal struct to store the base combat attributes with reducers of an item.
     *
     * Requirements:
     * @param atk               The amount of attack points the item adds to the total combat points.
     * @param atk_reducer       The amount of attack points the item reduces to the total combat points.
     * @param def               The amount of defence points the item adds to the total combat points.
     * @param def_reducer       The amount of defence points the item reduces to the total combat points.
     * @param range             The amount of range points the item adds to the total combat points.
     * @param range_reducer     The amount of range points the item reduces to the total combat points.
     * @param mag_atk           The amount of magical attack points the item adds to the total combat points.
     * @param mag_atk_reducer   The amount of magical attack points the item reduces to the total combat points.
     * @param mag_def           The amount of magical defence points the item adds to the total combat points.
     * @param mag_def_reducer   The amount of magical defence points the item reduces to the total combat points.
     * @param rate              The amount of rate speed points the item adds to the total combat points.
     * @param rate_reducer      The amount of rate speed points the item reduces to the total combat points.
     */
    struct Attributes {
        uint256 atk;
        uint256 atk_reducer;
        uint256 def;
        uint256 def_reducer;
        uint256 range;
        uint256 range_reducer;
        uint256 mag_atk;
        uint256 mag_atk_reducer;
        uint256 mag_def;
        uint256 mag_def_reducer;
        uint256 rate;
        uint256 rate_reducer;
    }

    /** @notice See [Items#mint](/docs/items/Items.md#mint) */
    function mint(address _to, uint256 _item_id) external;

    /** @notice See [Items#burn](/docs/items/Items.md#burn) */
    function burn(address _from, uint256 _item_id) external;

    /** @notice See [Items#addAuthority](/docs/items/Items.md#addAuthority) */
    function addAuthority(address _authority) external;

    /** @notice See [Items#removeAuthority](/docs/items/Items.md#removeAuthority) */
    function removeAuthority(address _authority) external;

    /** @notice See [Items#addItem](/docs/items/Items.md#addItem) */
    function addItem(
        string memory _name,
        string memory _description,
        uint256 _level_required,
        ItemType _item_type,
        StatsModifiers memory _stats_modifiers,
        Attributes memory _attributes
    ) external;

    /** @notice See [Items#updateItem](/docs/items/Items.md#updateItem) */
    function updateItem(Item memory _item) external;

    /** @notice See [Items#disableItem](/docs/items/Items.md#disableItem) */
    function disableItem(uint256 _item_id) external;

    /** @notice See [Items#enableItem](/docs/items/Items.md#enableItem) */
    function enableItem(uint256 _item_id) external;

    /** @notice See [Items#getItem](/docs/items/Items.md#getItem) */
    function getItem(uint256 _item_id)
        external
        view
        returns (Item memory _item);
}

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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
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