// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "../interfaces/IForge.sol";
import "../interfaces/ICivilizations.sol";
import "../interfaces/IExperience.sol";
import "../interfaces/IStats.sol";
import "../interfaces/IBaseFungibleItem.sol";

/**
 * @title Forge
 * @notice This contract convets the raw resources into craftable material. It uses multiple instances of [BaseFungibleItem](/docs/base/BaseFungibleItem.md) items.
 * Each character has access to a maximum of three usable forges to convert the resources.
 *
 * @notice Implementation of the [IForge](/docs/interfaces/IForge.md) interface.
 */
contract Forge is IForge, Ownable, Pausable {
    // =============================================== Storage ========================================================

    /** @notice Address of the [Civilizations](/docs/core/Civilizations.md) instance. */
    address public civilizations;

    /** @notice Address of the [Experience](/docs/core/Experience.md) instance. */
    address public experience;

    /** @notice Address of the [Stats](/docs/core/Stats.md) instance. */
    address public stats;

    /** @notice Map to track available recipes on the forge. */
    mapping(uint256 => Recipe) public recipes;

    /** @notice Array to track all the forge recipes IDs. */
    uint256[] private _recipes;

    /** @notice Map to track forges and cooldowns for characters. */
    mapping(bytes => mapping(uint256 => Forge)) public forges;

    /** @notice Constant for address of the `ERC20` token used to purchase forge upgrades. */
    address public token;

    /** @notice Constant for the price of each forge upgrade (in wei). */
    uint256 public price;

    // =============================================== Modifiers ======================================================

    /**
     * @notice Checks against the [Civilizations](/docs/core/Civilizations.md) instance if the `msg.sender` is the owner or
     * has allowance to access a composed ID.
     *
     * Requirements:
     * @param _id    Composed ID of the character.
     */
    modifier onlyAllowed(bytes memory _id) {
        require(
            ICivilizations(civilizations).exists(_id),
            "Forge: onlyAllowed() token not minted."
        );
        require(
            ICivilizations(civilizations).isAllowed(msg.sender, _id),
            "Forge: onlyAllowed() msg.sender is not allowed to access this token."
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
    event AddRecipe(
        uint256 indexed _recipe_id,
        string _name,
        string _description
    );

    /**
     * @notice Event emmited when the [enableRecipe](#enableRecipe) function is called.
     *
     * Requirements:
     * @param _recipe_id    ID of the recipe enabled.
     */
    event EnableRecipe(uint256 indexed _recipe_id);

    /**
     * @notice Event emmited when the [disableRecipe](#disableRecipe) function is called.
     *
     * Requirements:
     * @param _recipe_id    ID of the recipe disabled.
     */
    event DisableRecipe(uint256 indexed _recipe_id);

    // =============================================== Setters ========================================================

    /**
     * @notice Constructor.
     *
     * Requirements:
     * @param _civilizations    The address of the [Civilizations](/docs/core/Civilizations.md) instance.
     * @param _experience       The address of the [Experience](/docs/core/Experience.md) instance.
     * @param _stats            The address of the [Stats](/docs/core/Stats.md) instance.
     * @param _token            Address of the token used to purchase.
     * @param _price            Price for each upgrade.
     */
    constructor(
        address _civilizations,
        address _experience,
        address _stats,
        address _token,
        uint256 _price
    ) {
        civilizations = _civilizations;
        experience = _experience;
        stats = _stats;
        token = _token;
        price = _price;
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
     * @notice Disables a recipe from beign forged.
     *
     * Requirements:
     * @param _recipe_id   ID of the recipe.
     */
    function disableRecipe(uint256 _recipe_id) public onlyOwner {
        require(
            _recipe_id != 0 && _recipe_id <= _recipes.length,
            "Forge: disableRecipe() invalid recipe id."
        );
        recipes[_recipe_id].available = false;
        emit DisableRecipe(_recipe_id);
    }

    /**
     * @notice Enables a recipe to be forged.
     *
     * Requirements:
     * @param _recipe_id   ID of the recipe.
     */
    function enableRecipe(uint256 _recipe_id) public onlyOwner {
        require(
            _recipe_id != 0 && _recipe_id <= _recipes.length,
            "Forge: enableRecipe() invalid recipe id."
        );
        recipes[_recipe_id].available = true;
        emit EnableRecipe(_recipe_id);
    }

    /**
     * @notice Adds a new recipe to the forge.
     *
     * Requirements:
     * @param _name                 Name of the recipe.
     * @param _description          Description of the recipe.
     * @param _materials            Array of material [BaseFungibleItem](/docs/base/BaseFungibleItem.md) instances address.
     * @param _amounts              Array of amounts for each material.
     * @param _stats                Stats to consume from the pool for recipe.
     * @param _cooldown             Number of seconds for the recipe cooldown.
     * @param _level_required       Minimum level required to forge the recipe.
     * @param _reward               Address of the [BaseFungibleItem](/docs/base/BaseFungibleItem.md) instances to be rewarded for the recipe.
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
        address _reward,
        uint256 _experience_reward
    ) public onlyOwner {
        uint256 _recipe_id = _recipes.length + 1;
        require(
            _materials.length == _amounts.length,
            "Forge: addRecipe() materials and amounts not match."
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
     * @notice Updates a previously added forge recipe.
     *
     * Requirements:
     * @param _recipe   Full information of the recipe.
     */
    function updateRecipe(Recipe memory _recipe) public onlyOwner {
        require(
            _recipe.id != 0 && _recipe.id <= _recipes.length,
            "Forge: updateRecipe() invalid recipe id."
        );
        recipes[_recipe.id] = _recipe;
    }

    /**
     * @notice Purchases a forge upgrade for the character provided.
     *
     * Requirements:
     * @param _id  Composed ID of the characrter.
     */
    function buyUpgrade(bytes memory _id)
        public
        whenNotPaused
        onlyAllowed(_id)
    {
        require(
            IERC20(token).balanceOf(msg.sender) >= price,
            "Forge: buyUpgrade() not enough balance to buy upgrade."
        );
        require(
            IERC20(token).allowance(msg.sender, address(this)) >= price,
            "Forge: buyUpgrade() not enough allowance to buy upgrade."
        );

        bool canUpgrade = false;
        if (!forges[_id][2].available) {
            canUpgrade = true;
        }
        if (!forges[_id][3].available) {
            canUpgrade = true;
        }

        require(canUpgrade, "Forge: buyUpgrade() no spot available.");
        IERC20(token).transferFrom(msg.sender, owner(), price);

        if (!forges[_id][2].available) {
            forges[_id][2].available = true;
            return;
        }

        if (!forges[_id][3].available) {
            forges[_id][3].available = true;
            return;
        }
    }

    /**
     * @notice Forges a recipe and assigns it to the forge provided.
     *
     * Requirements:
     * @param _id           Composed ID of the characrter.
     * @param _recipe_id    ID of the recipe to forge.
     * @param _forge_id     ID of the forge to assign the recipe.
     */
    function forge(
        bytes memory _id,
        uint256 _recipe_id,
        uint256 _forge_id
    ) public whenNotPaused onlyAllowed(_id) {
        require(
            _forge_id > 0 && _forge_id <= 3,
            "Forge: forge() invalid forge id."
        );

        if (_forge_id != 1) {
            require(
                forges[_id][_forge_id].available,
                "Forge: forge() forge is not available."
            );
        }

        require(
            _recipe_id != 0 && _recipe_id <= _recipes.length,
            "Forge: forge() invalid recipe id."
        );
        require(
            _isForgeAvailable(_id, _forge_id),
            "Forge: forge() forge is already being used."
        );

        Recipe memory _recipe = recipes[_recipe_id];
        require(_recipe.available, "Forge: forge() recipe not available.");

        require(
            IExperience(experience).getLevel(_id) >= _recipe.level_required,
            "Forge: forge() not enough level."
        );

        for (uint256 i = 0; i < _recipe.materials.length; i++) {
            IBaseFungibleItem(_recipe.materials[i]).consume(
                _id,
                _recipe.amounts[i]
            );
        }

        IStats(stats).consume(_id, _recipe.stats_required);
        forges[_id][_forge_id] = Forge(
            true,
            block.timestamp + _recipe.cooldown,
            _recipe.id,
            false
        );
    }

    /**
     * @notice Claims a recipe already forged.
     *
     * Requirements:
     * @param _id           Composed ID of the character.
     * @param _forge_id     ID of the forge to assign the recipe.
     */
    function claim(bytes memory _id, uint256 _forge_id)
        public
        whenNotPaused
        onlyAllowed(_id)
    {
        require(
            _forge_id > 0 && _forge_id <= 3,
            "Forge: claim() invalid forge id."
        );
        if (_forge_id != 1) {
            require(
                forges[_id][_forge_id].available,
                "Forge: claim() forge is not available."
            );
        }
        require(
            _isForgeClaimable(_id, _forge_id),
            "Forge: claim() forge not claimable."
        );

        forges[_id][_forge_id].last_recipe_claimed = true;

        Recipe memory _recipe = recipes[forges[_id][_forge_id].last_recipe];

        IBaseFungibleItem(_recipe.reward).mintTo(_id, 1);

        IExperience(experience).assignExperience(
            _id,
            _recipe.experience_reward
        );
    }

    // =============================================== Getters ========================================================

    /**
     * @notice External function to return the recipe information.
     *
     * Requirements:
     * @param _recipe_id    ID of the forge recipe.
     *
     * @return _recipe      Full information of the recipe.
     */
    function getRecipe(uint256 _recipe_id)
        public
        view
        returns (Recipe memory _recipe)
    {
        require(
            _recipe_id != 0 && _recipe_id <= _recipes.length,
            "Forge: getRecipe() invalid recipe id."
        );
        return recipes[_recipe_id];
    }

    /**
     * @notice External function to return the information of a character forge.
     *
     * Requirements:
     * @param _id           Composed ID of the character.
     * @param _forge_id     ID of the forge.
     *
     * @return _forge       Full information of the forge.
     */
    function getCharacterForge(bytes memory _id, uint256 _forge_id)
        public
        view
        returns (Forge memory _forge)
    {
        require(
            _forge_id > 0 && _forge_id <= 3,
            "Forge: getCharacterForge() invalid forge id."
        );
        return forges[_id][_forge_id];
    }

    /**
     * @notice External function to return an array of booleans with the purchased forge upgrades for a character.
     *
     * Requirements:
     * @param _id           Composed ID of the character.
     *
     * @return _upgrades    Array of booleans of upgrades purchases.
     */
    function getCharacterForgesUpgrades(bytes memory _id)
        public
        view
        returns (bool[3] memory _upgrades)
    {
        return [true, forges[_id][2].available, forges[_id][3].available];
    }

    /**
     * @notice External function to return an array of booleans with the availability of the character forges.
     *
     * Requirements:
     * @param _id           Composed ID of the character.
     *
     * @return _availability    Array of booleans of forge availability.
     */
    function getCharacterForgesAvailability(bytes memory _id)
        public
        view
        returns (bool[3] memory _availability)
    {
        bool[3] memory upgrades = getCharacterForgesUpgrades(_id);
        return [
            upgrades[0] && _isForgeAvailable(_id, 1),
            upgrades[1] && _isForgeAvailable(_id, 2),
            upgrades[2] && _isForgeAvailable(_id, 3)
        ];
    }

    // =============================================== Internal =======================================================

    /**
     * @notice Internal function to check if a character forge is available.
     *
     * Requirements:
     * @param _id           Composed ID of the character.
     * @param _forge_id     ID of the forge.
     *
     * @return _available   Boolean to know if the forge is available.
     */
    function _isForgeAvailable(bytes memory _id, uint256 _forge_id)
        internal
        view
        returns (bool _available)
    {
        require(
            _forge_id > 0 && _forge_id <= 3,
            "Forge: _isForgeAvailable() invalid forge id."
        );
        if (forges[_id][_forge_id].cooldown == 0) {
            return true;
        }

        return
            forges[_id][_forge_id].cooldown <= block.timestamp &&
            forges[_id][_forge_id].last_recipe_claimed;
    }

    /**
     * @notice Internal function to check if a character forge is claimable.
     *
     * Requirements:
     * @param _id           Composed ID of the character.
     * @param _forge_id     ID of the forge.
     *
     * @return _claimable   Boolean to know if the forge is claimable.
     */
    function _isForgeClaimable(bytes memory _id, uint256 _forge_id)
        internal
        view
        returns (bool _claimable)
    {
        require(
            _forge_id > 0 && _forge_id <= 3,
            "Forge: _isForgeClaimable() invalid forge id."
        );
        return
            forges[_id][_forge_id].cooldown <= block.timestamp &&
            !forges[_id][_forge_id].last_recipe_claimed &&
            forges[_id][_forge_id].last_recipe != 0;
    }
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

import "../interfaces/IStats.sol";

/**
 * @title IForge
 * @notice Interface for the [Forge](/docs/core/Forge.md) contract.
 */
interface IForge {
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
     * @param level_required        Minimum level required to forge the recipe.
     * @param reward                Address of the resulting item of the recipe.
     * @param experience_reward     Amount of experience rewarded from the recipe.
     * @param available             Boolean to check if the recipe is available.
     */
    struct Recipe {
        uint256 id;
        string name;
        string description;
        address[] materials;
        uint256[] amounts;
        IStats.BasicStats stats_required;
        uint256 cooldown;
        uint256 level_required;
        address reward;
        uint256 experience_reward;
        bool available;
    }

    struct Forge {
        bool available;
        uint256 cooldown;
        uint256 last_recipe;
        bool last_recipe_claimed;
    }

    /** @notice See [Forge#pause](/docs/core/Forge.md#pause) */
    function pause() external;

    /** @notice See [Forge#unpause](/docs/core/Forge.md#unpause) */
    function unpause() external;

    /** @notice See [Forge#disableRecipe](/docs/core/Forge.md#disableRecipe) */
    function disableRecipe(uint256 _recipe_id) external;

    /** @notice See [Forge#enableRecipe](/docs/core/Forge.md#enableRecipe) */
    function enableRecipe(uint256 _recipe_id) external;

    /** @notice See [Forge#addRecipe](/docs/core/Forge.md#addRecipe) */
    function addRecipe(
        string memory _name,
        string memory _description,
        address[] memory _materials,
        uint256[] memory _amounts,
        IStats.BasicStats memory _stats,
        uint256 _cooldown,
        uint256 _level_required,
        address _reward,
        uint256 _experience_reward
    ) external;

    /** @notice See [Forge#updateRecipe](/docs/core/Forge.md#updateRecipe) */
    function updateRecipe(Recipe memory _recipe) external;

    /** @notice See [Forge#buyUpgrade](/docs/core/Forge.md#buyUpgrade) */
    function buyUpgrade(bytes memory _id) external;

    /** @notice See [Forge#forge](/docs/core/Forge.md#forge) */
    function forge(
        bytes memory _id,
        uint256 _recipe_id,
        uint256 _forge_id
    ) external;

    /** @notice See [Forge#claim](/docs/core/Forge.md#claim) */
    function claim(bytes memory _id, uint256 _forge_id) external;

    /** @notice See [Forge#getRecipe](/docs/core/Forge.md#getRecipe) */
    function getRecipe(uint256 _recipe_id)
        external
        view
        returns (Recipe memory _recipe);

    /** @notice See [Forge#getCharacterForge](/docs/core/Forge.md#getCharacterForge) */
    function getCharacterForge(bytes memory _id, uint256 _forge_id)
        external
        view
        returns (Forge memory _forge);

    /** @notice See [Forge#getCharacterForgesUpgrades](/docs/core/Forge.md#getCharacterForgesUpgrades) */
    function getCharacterForgesUpgrades(bytes memory _id)
        external
        view
        returns (bool[3] memory _upgrades);

    /** @notice See [Forge#getCharacterForgesAvailability](/docs/core/Forge.md#getCharacterForgesAvailability) */
    function getCharacterForgesAvailability(bytes memory _id)
        external
        view
        returns (bool[3] memory _availability);
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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