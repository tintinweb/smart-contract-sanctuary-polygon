// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "../interfaces/ICraft.sol";
import "../interfaces/ICivilizations.sol";
import "../interfaces/IExperience.sol";
import "../interfaces/IStats.sol";
import "../interfaces/IItems.sol";
import "../interfaces/IBaseFungibleItem.sol";

/**
 * @title Craft
 * @notice This contract is used to store and craft recipes through the ecosystem. This is the only contract able to mint
 * items through the [Items](/docs/items/Items.md) `ERC1155` implementation.
 *
 * @notice Implementation of the [ICraft](/docs/interfaces/ICraft.md) interface.
 */
contract Craft is
    ICraft,
    Initializable,
    PausableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    // =============================================== Storage ========================================================

    /** @notice Map to track available recipes for craft. */
    mapping(uint256 => Recipe) public recipes;

    /** @notice Array to track all the recipes IDs. */
    uint256[] private _recipes;

    /** @notice Map to track available upgrades to craft. */
    mapping(uint256 => Upgrade) public upgrades;

    /** @notice Array to track all the upgrades IDs. */
    uint256[] private _upgrades;

    /** @notice Address of the [Civilizations](/docs/core/Civilizations.md) instance. */
    address public civilizations;

    /** @notice Address of the [Experience](/docs/core/Experience.md) instance. */
    address public experience;

    /** @notice Address of the [Stats](/docs/core/Stats.md) instance. */
    address public stats;

    /** @notice Address of the [Items](/docs/items/Items.md) instance. */
    address public items;

    /** @notice Map to track craft slots and cooldowns for each character. */
    mapping(bytes => Slot) public craft_slots;

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
            "Craft: onlyAllowed() token not minted."
        );
        require(
            ICivilizations(civilizations).isAllowed(msg.sender, _id),
            "Craft: onlyAllowed() msg.sender is not allowed to access this token."
        );
        _;
    }

    // =============================================== Events =========================================================

    /**
     * @notice Event emmited when the [addRecipe](#addRecipe) function is called.
     *
     * Requirements:
     * @param _recipe_id    ID of the recipe added.
     * @param _name         Name of the recipe.
     * @param _description  Recipe description
     */
    event AddRecipe(uint256 _recipe_id, string _name, string _description);

    /**
     * @notice Event emmited when the [updateRecipe](#updateRecipe) function is called.
     *
     * Requirements:
     * @param _recipe_id    ID of the recipe added.
     * @param _name         Name of the recipe.
     * @param _description  Recipe description
     */
    event RecipeUpdate(uint256 _recipe_id, string _name, string _description);

    /**
     * @notice Event emmited when the [enableRecipe](#enableRecipe) function is called.
     *
     * Requirements:
     * @param _recipe_id    ID of the recipe enabled.
     */
    event EnableRecipe(uint256 _recipe_id);

    /**
     * @notice Event emmited when the [disableRecipe](#disableRecipe) function is called.
     *
     * Requirements:
     * @param _recipe_id    ID of the recipe disabled.
     */
    event DisableRecipe(uint256 _recipe_id);

    /**
     * @notice Event emmited when the [addUpgrade](#addUpgrade) function is called.
     *
     * Requirements:
     * @param _upgrade_id       ID of the the upgrade added.
     * @param _name             Name of the recipe.
     * @param _description      Recipe description
     */
    event AddUpgrade(uint256 _upgrade_id, string _name, string _description);

    /**
     * @notice Event emmited when the [updateUpgrade](#updateUpgrade) function is called.
     *
     * Requirements:
     * @param _upgrade_id       ID of the the upgrade added.
     * @param _name             Name of the recipe.
     * @param _description      Recipe description
     */
    event UpgradeUpdate(uint256 _upgrade_id, string _name, string _description);

    /**
     * @notice Event emmited when the [enableUpgrade](#enableUpgrade) function is called.
     *
     * Requirements:
     * @param _upgrade_id    ID of the the recipe added.
     */
    event EnableUpgrade(uint256 _upgrade_id);

    /**
     * @notice Event emmited when the [disableUpgrade](#disableUpgrade) function is called.
     *
     * Requirements:
     * @param _upgrade_id    ID of the the recipe added.
     */
    event DisableUpgrade(uint256 _upgrade_id);

    // =============================================== Setters ========================================================

    /**
     * @notice Initialize.
     *
     * Requirements:
     * @param _civilizations    The address of the [Civilizations](/docs/core/Civilizations.md) instance.
     * @param _experience       The address of the [Experience](/docs/core/Experience.md) instance.
     * @param _stats            The address of the [Stats](/docs/core/Stats.md) instance.
     * @param _items            The address of the [Items](/docs/items/Items.md) instance.
     */
    function initialize(
        address _civilizations,
        address _experience,
        address _stats,
        address _items
    ) public initializer {
        __Ownable_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        civilizations = _civilizations;
        experience = _experience;
        stats = _stats;
        items = _items;
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
     * @notice Disables a recipe from beign crafted.
     *
     * Requirements:
     * @param _recipe_id   ID of the recipe.
     */
    function disableRecipe(uint256 _recipe_id) public onlyOwner {
        require(
            _recipe_id != 0 && _recipe_id <= _recipes.length,
            "Craft: disableRecipe() invalid recipe id."
        );
        recipes[_recipe_id].available = false;
        emit DisableRecipe(_recipe_id);
    }

    /**
     * @notice Enables a recipe to be crafted.
     *
     * Requirements:
     * @param _recipe_id   ID of the recipe.
     */
    function enableRecipe(uint256 _recipe_id) public onlyOwner {
        require(
            _recipe_id != 0 && _recipe_id <= _recipes.length,
            "Craft: enableRecipe() invalid recipe id."
        );
        recipes[_recipe_id].available = true;
        emit EnableRecipe(_recipe_id);
    }

    /**
     * @notice Disables an upgrade from beign crafted.
     *
     * Requirements:
     * @param _upgrade_id   ID of the upgrade.
     */
    function disableUpgrade(uint256 _upgrade_id) public onlyOwner {
        require(
            _upgrade_id != 0 && _upgrade_id <= _recipes.length,
            "Craft: disableUpgrade() invalid upgrade id."
        );
        upgrades[_upgrade_id].available = false;
        emit DisableUpgrade(_upgrade_id);
    }

    /**
     * @notice Enables an upgrade to be crafted.
     *
     * Requirements:
     * @param _upgrade_id   ID of the upgrade.
     */
    function enableUpgrade(uint256 _upgrade_id) public onlyOwner {
        require(
            _upgrade_id != 0 && _upgrade_id <= _upgrades.length,
            "Craft: enableUpgrade() invalid upgrade id."
        );
        upgrades[_upgrade_id].available = true;
        emit EnableUpgrade(_upgrade_id);
    }

    /**
     * @notice Adds a new recipe to craft.
     *
     * Requirements:
     * @param _name                 Name of the recipe.
     * @param _description          Description of the recipe.
     * @param _materials            Array of material [BaseFungibleItem](/docs/base/BaseFungibleItem.md) instances address.
     * @param _amounts              Array of amounts for each material.
     * @param _stats                Stats to consume from the pool for craft.
     * @param _cooldown             Number of seconds for the recipe cooldown.
     * @param _level_required       Minimum level required to craft the recipe.
     * @param _reward               ID of the token to reward for the [Items](/docs/items/Items.md) instance.
     * @param _experience_reward    Amount of experience rewarded for the recipe.
     */
    function addRecipe(
        string memory _name,
        string memory _description,
        address[] memory _materials,
        uint256[] memory _amounts,
        IStats.BasicStats memory _stats,
        uint256 _cooldown,
        uint256 _level_required,
        uint256 _reward,
        uint256 _experience_reward
    ) public onlyOwner {
        uint256 _recipe_id = _recipes.length + 1;
        require(
            _materials.length == _amounts.length,
            "Craft: addRecipe() materials and amounts not match."
        );
        recipes[_recipe_id] = Recipe(
            _recipe_id,
            _name,
            _description,
            _materials,
            _amounts,
            _stats,
            _cooldown,
            _level_required,
            _reward,
            _experience_reward,
            true
        );
        _recipes.push(_recipe_id);
        emit AddRecipe(_recipe_id, _name, _description);
    }

    /**
     * @notice Updates a previously added craft recipe.
     *
     * Requirements:
     * @param _recipe   Full information of the recipe.
     */
    function updateRecipe(Recipe memory _recipe) public onlyOwner {
        require(
            _recipe.id != 0 && _recipe.id <= _recipes.length,
            "Craft: updateRecipe() invalid recipe id."
        );
        recipes[_recipe.id] = _recipe;
        emit RecipeUpdate(_recipe.id, _recipe.name, _recipe.description);
    }

    /**
     * @notice Adds a new recipe to craft.
     *
     * Requirements:
     * @param _name                 Name of the upgrade.
     * @param _description          Description of the upgrade.
     * @param _materials            Array of material [BaseFungibleItem](/docs/base/BaseFungibleItem.md) instances address.
     * @param _amounts              Array of amounts for each material.
     * @param _stats                Stats to consume from the pool for upgrade.
     * @param _sacrifice            Stats to sacrficed from the base stats for upgrade.
     * @param _level_required       Minimum level required to craft the recipe.
     * @param _upgraded_item        ID of the token item that is being upgraded from the [Items](/docs/items/Items.md) instance.
     * @param _reward               ID of the token to reward for the [Items](/docs/items/Items.md) instance.
     */
    function addUpgrade(
        string memory _name,
        string memory _description,
        address[] memory _materials,
        uint256[] memory _amounts,
        IStats.BasicStats memory _stats,
        IStats.BasicStats memory _sacrifice,
        uint256 _level_required,
        uint256 _upgraded_item,
        uint256 _reward
    ) public onlyOwner {
        uint256 _upgrade_id = _upgrades.length + 1;
        require(
            _materials.length == _amounts.length,
            "Craft: addUpgrade() materials and amounts not match."
        );
        upgrades[_upgrade_id] = Upgrade(
            _upgrade_id,
            _name,
            _description,
            _materials,
            _amounts,
            _stats,
            _sacrifice,
            _level_required,
            _upgraded_item,
            _reward,
            true
        );
        _upgrades.push(_upgrade_id);
        emit AddUpgrade(_upgrade_id, _name, _description);
    }

    /**
     * @notice Updates a previously added upgrade recipe.
     *
     * Requirements:
     * @param _upgrade   Full information of the recipe.
     */
    function updateUpgrade(Upgrade memory _upgrade) public onlyOwner {
        require(
            _upgrade.id != 0 && _upgrade.id <= _recipes.length,
            "Craft: updateUpgrade() invalid upgrade id."
        );
        upgrades[_upgrade.id] = _upgrade;
        emit UpgradeUpdate(_upgrade.id, _upgrade.name, _upgrade.description);
    }

    /**
     * @notice Initializes a recipe to be crafted.
     *
     * Requirements:
     * @param _id           Composed ID of the character.
     * @param _recipe_id    ID of the recipe.
     */
    function craft(bytes memory _id, uint256 _recipe_id)
        public
        whenNotPaused
        onlyAllowed(_id)
    {
        require(
            _recipe_id != 0 && _recipe_id <= _recipes.length,
            "Craft: craft() invalid recipe id."
        );
        require(
            _isSlotAvailable(_id),
            "Craft: craft() slot not available to craft."
        );

        Recipe memory _recipe = recipes[_recipe_id];
        require(_recipe.available, "Craft: craft() recipe is not available.");

        require(
            IExperience(experience).getLevel(_id) >= _recipe.level_required,
            "Craft: craft() not enough level."
        );

        for (uint256 i = 0; i < _recipe.materials.length; i++) {
            IBaseFungibleItem(_recipe.materials[i]).consume(
                _id,
                _recipe.material_amounts[i]
            );
        }

        IStats(stats).consume(_id, _recipe.stats_required);

        craft_slots[_id] = Slot(
            block.timestamp + _recipe.cooldown,
            _recipe.id,
            false
        );
    }

    /**
     * @notice Claims a recipe already crafted.
     *
     * Requirements:
     * @param _id   Composed ID of the character.
     */
    function claim(bytes memory _id) public whenNotPaused onlyAllowed(_id) {
        require(_isSlotClaimable(_id), "Craft: claim() slot is not claimable.");
        craft_slots[_id].claimed = true;
        Recipe memory _recipe = recipes[craft_slots[_id].last_recipe];
        IItems(items).mint(
            ICivilizations(civilizations).ownerOf(_id),
            _recipe.reward
        );
    }

    /**
     * @notice Upgrades an item.
     *
     * Requirements:
     * @param _id           Composed ID of the character.
     * @param _upgrade_id   ID of the upgrade to perform.
     */
    function upgrade(bytes memory _id, uint256 _upgrade_id)
        public
        whenNotPaused
        onlyAllowed(_id)
    {
        require(
            _upgrade_id != 0 && _upgrade_id <= _recipes.length,
            "Craft: upgrade() invalid recipe id."
        );

        Upgrade memory _upgrade = upgrades[_upgrade_id];
        require(
            _upgrade.available,
            "Craft: upgrade() upgrade is not available."
        );

        require(
            IExperience(experience).getLevel(_id) >= _upgrade.level_required,
            "Craft: upgrade() not enough level."
        );

        for (uint256 i = 0; i < _upgrade.materials.length; i++) {
            IBaseFungibleItem(_upgrade.materials[i]).consume(
                _id,
                _upgrade.material_amounts[i]
            );
        }

        IStats(stats).consume(_id, _upgrade.stats_required);

        IStats(stats).sacrifice(_id, _upgrade.stats_sacrificed);

        IItems(items).burn(
            ICivilizations(civilizations).ownerOf(_id),
            _upgrade.upgraded_item
        );

        IItems(items).mint(
            ICivilizations(civilizations).ownerOf(_id),
            _upgrade.reward
        );
    }

    // =============================================== Getters ========================================================

    /**
     * @notice Returns the full information of a recipe.
     *
     * Requirements:
     * @param _recipe_id   ID of the recipe.
     *
     * @return _recipe     Full information of the recipe
     */
    function getRecipe(uint256 _recipe_id)
        public
        view
        returns (Recipe memory _recipe)
    {
        require(
            _recipe_id != 0 && _recipe_id <= _recipes.length,
            "Craft: getRecipe() invalid recipe id."
        );
        return recipes[_recipe_id];
    }

    /**
     * @notice Returns the full information of an upgrade.
     *
     * Requirements:
     * @param _upgrade_id   ID of the upgrade.
     *
     * @return _upgrade     Full information of the upgrade
     */
    function getUpgrade(uint256 _upgrade_id)
        public
        view
        returns (Upgrade memory _upgrade)
    {
        require(
            _upgrade_id != 0 && _upgrade_id <= _recipes.length,
            "Craft: getUpgrade() invalid recipe id."
        );
        return upgrades[_upgrade_id];
    }

    /**
     * @notice Returns character craft slot information.
     *
     * Requirements:
     * @param _id       Composed ID of the character.
     *
     * @return _slot    Full information of character crafting slot.
     */
    function getCharacterCrafSlot(bytes memory _id)
        public
        view
        returns (Slot memory _slot)
    {
        return craft_slots[_id];
    }

    // =============================================== Internal =======================================================

    /**
     * @notice Internal check if the crafting slot is available to be used.
     *
     * Requirements:
     * @param _id           Composed ID of the character.
     *
     * @return _available   Boolean to know if the slot is available.
     */
    function _isSlotAvailable(bytes memory _id)
        internal
        view
        returns (bool _available)
    {
        Slot memory s = craft_slots[_id];

        if (s.cooldown == 0) {
            return true;
        }

        return s.cooldown <= block.timestamp && s.claimed;
    }

    /**
     * @notice Internal check if the crafting slot is claimable.
     *
     * Requirements:
     * @param _id           Composed ID of the character.
     *
     * @return _available   Boolean to know if the slot is claimable.
     */
    function _isSlotClaimable(bytes memory _id) internal view returns (bool) {
        Slot memory s = craft_slots[_id];
        return
            s.cooldown <= block.timestamp && !s.claimed && s.last_recipe != 0;
    }

    /** @notice Internal function make sure upgrade proxy caller is the owner. */
    function _authorizeUpgrade(address newImplementation)
        internal
        virtual
        override
        onlyOwner
    {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "../interfaces/IStats.sol";

/**
 * @title ICraft
 * @notice Interface for the [Craft](/docs/core/Craft.md) contract.
 */
interface ICraft {
    /**
     * @notice Internal struct to containt all the information of a recipe.
     *
     * Requirements:
     * @param id                    ID of the recipe.
     * @param name                  Name of the recipe.
     * @param description           Description of the recipe.
     * @param materials             Array of addresses of the require material instances.
     * @param amounts               Array of amounts for each required material.
     * @param stats_required        Amount of stats required to consume to create the recipe.
     * @param cooldown              Cooldown in seconds of the recipe.
     * @param level_required        Minimum level required to craft the recipe.
     * @param reward                ID of the reward token.
     * @param available             Boolean to check if the recipe is available.
     */
    struct Recipe {
        uint256 id;
        string name;
        string description;
        address[] materials;
        uint256[] material_amounts;
        IStats.BasicStats stats_required;
        uint256 cooldown;
        uint256 level_required;
        uint256 reward;
        uint256 experience_reward;
        bool available;
    }

    /**
     * @notice Internal struct to containt all the information of an upgrade.
     *
     * Requirements:
     * @param id                    ID of the upgrade.
     * @param name                  Name of the upgrade.
     * @param description           Description of the upgrade.
     * @param materials             Array of addresses of the require material instances.
     * @param amounts               Array of amounts for each required material.
     * @param stats_required        Amount of stats required to consume to create the upgrade.
     * @param stats_sacrificed      Amount of stats required to sacrifice to create the upgrade.
     * @param level_required        Minimum level required to craft the upgrade.
     * @param upgraded_item         ID of the item is beign upgraded.
     * @param reward                ID of the reward token.
     * @param available             Boolean to check if the upgrade is available.
     */
    struct Upgrade {
        uint256 id;
        string name;
        string description;
        address[] materials;
        uint256[] material_amounts;
        IStats.BasicStats stats_required;
        IStats.BasicStats stats_sacrificed;
        uint256 level_required;
        uint256 upgraded_item;
        uint256 reward;
        bool available;
    }

    /**
     * @notice Internal struct to store the information of a crafting or upgrading slot.
     *
     * Requirements:
     * @param cooldown      Timestamp on which the slot is claimable.
     * @param last_recipe   The last crafted recipe.
     * @param claimed       Boolean to know if the last crafted recipe is already claimed.
     */
    struct Slot {
        uint256 cooldown;
        uint256 last_recipe;
        bool claimed;
    }

    /** @notice See [Craft#pause](/docs/core/Craft.md#pause) */
    function pause() external;

    /** @notice See [Craft#unpause](/docs/core/Craft.md#unpause) */
    function unpause() external;

    /** @notice See [Craft#disableRecipe](/docs/core/Craft.md#disableRecipe) */
    function disableRecipe(uint256 _recipe_id) external;

    /** @notice See [Craft#enableRecipe](/docs/core/Craft.md#enableRecipe) */
    function enableRecipe(uint256 _recipe_id) external;

    /** @notice See [Craft#disableUpgrade](/docs/core/Craft.md#disableUpgrade) */
    function disableUpgrade(uint256 _upgrade_id) external;

    /** @notice See [Craft#enableUpgrade](/docs/core/Craft.md#enableUpgrade) */
    function enableUpgrade(uint256 _upgrade_id) external;

    /** @notice See [Craft#addRecipe](/docs/core/Craft.md#addRecipe) */
    function addRecipe(
        string memory _name,
        string memory _description,
        address[] memory _materials,
        uint256[] memory _amounts,
        IStats.BasicStats memory _stats,
        uint256 _cooldown,
        uint256 _level_required,
        uint256 _reward,
        uint256 _experience_reward
    ) external;

    /** @notice See [Craft#updateRecipe](/docs/core/Craft.md#updateRecipe) */
    function updateRecipe(Recipe memory _recipe) external;

    /** @notice See [Craft#addUpgrade](/docs/core/Craft.md#addUpgrade) */
    function addUpgrade(
        string memory _name,
        string memory _description,
        address[] memory _materials,
        uint256[] memory _amounts,
        IStats.BasicStats memory _stats,
        IStats.BasicStats memory _sacrifice,
        uint256 _level_required,
        uint256 _upgraded_item,
        uint256 _reward
    ) external;

    /** @notice See [Craft#updateUpgrade](/docs/core/Craft.md#updateUpgrade) */
    function updateUpgrade(Upgrade memory _upgrade) external;

    /** @notice See [Craft#craft](/docs/core/Craft.md#craft) */
    function craft(bytes memory _id, uint256 _recipe_id) external;

    /** @notice See [Craft#claim](/docs/core/Craft.md#claim) */
    function claim(bytes memory _id) external;

    /** @notice See [Craft#upgrade](/docs/core/Craft.md#upgrade) */
    function upgrade(bytes memory _id, uint256 _upgrade_id) external;

    /** @notice See [Craft#getRecipe](/docs/core/Craft.md#getRecipe) */
    function getRecipe(uint256 _recipe_id)
        external
        view
        returns (Recipe memory _recipe);

    /** @notice See [Craft#getUpgrade](/docs/core/Craft.md#getUpgrade) */
    function getUpgrade(uint256 _upgrade_id)
        external
        view
        returns (Upgrade memory _upgrade);

    /** @notice See [Craft#getCharacterCrafSlot](/docs/core/Craft.md#getCharacterCrafSlot) */
    function getCharacterCrafSlot(bytes memory _id)
        external
        view
        returns (Slot memory _slot);
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
pragma solidity 0.8.17;

/**
 * @title IExperience
 * @notice Interface for the [Experience](/docs/core/Experience.md) contract.
 */
interface IExperience {
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

/**
 * @title IBaseFungibleItem
 * @notice Interface for the [BaseFungibleItem](/docs/base/BaseFungibleItem.md) contract.
 */
interface IBaseFungibleItem {
    /** @notice See [BaseFungibleItem#mintTo](/docs/base/BaseFungibleItem.md#mintTo) */
    function mintTo(bytes memory _id, uint256 _amount) external;

    /** @notice See [BaseFungibleItem#consume](/docs/base/BaseFungibleItem.md#consume) */
    function consume(bytes memory _id, uint256 _amount) external;

    /** @notice See [BaseFungibleItem#wrap](/docs/base/BaseFungibleItem.md#wrap) */
    function wrap(bytes memory _id, uint256 _amount) external;

    /** @notice See [BaseFungibleItem#unwrap](/docs/base/BaseFungibleItem.md#unwrap) */
    function unwrap(bytes memory _id, uint256 _amount) external;

    /** @notice See [BaseFungibleItem#balanceOf](/docs/base/BaseFungibleItem.md#balanceOf) */
    function balanceOf(bytes memory _id)
        external
        view
        returns (uint256 _balance);
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

    /** @notice See [Civilizations#transfer](/docs/core/Civilizations.md#transfer) */
    function transfer(
        address _from,
        address _to,
        uint256 _token_id
    ) external;

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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}