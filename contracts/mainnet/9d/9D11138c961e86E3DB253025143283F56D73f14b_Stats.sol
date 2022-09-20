// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "../interfaces/ICivilizations.sol";
import "../interfaces/IExperience.sol";
import "../interfaces/IStats.sol";
import "../interfaces/IEquipment.sol";

/**
 * @title Stats
 * @notice This contract manages the stats points and pools for all the characters stored on the [Civilizations](/docs/core/Civilizations.md) instance.
 * The stats and the concept is based on the Cypher System for role playing games: http://cypher-system.com/.
 *
 * @notice Implementation of the [IStats](/docs/interfaces/IStats.md) interface.
 */
contract Stats is IStats, Ownable, Pausable {
    // =============================================== Storage ========================================================

    /** @notice Constant amount of seconds for refresh cooldown.  **/
    uint256 public REFRESH_COOLDOWN_SECONDS;

    /** @notice Map track the base stats for characters. */
    mapping(bytes => BasicStats) base;

    /** @notice Map track the pool stats for characters. */
    mapping(bytes => BasicStats) pool;

    /** @notice Map track the last refresh timestamps of the characters. */
    mapping(bytes => uint256) last_refresh;

    /** @notice Address of the Refresher [BaseGadgetToken](/docs/base/BaseGadgetToken.md) instance. */
    address public refresher;

    /** @notice Address of the Vitalizer [BaseGadgetToken](/docs/base/BaseGadgetToken.md) instance. */
    address public vitalizer;

    /** @notice Address of the [Civilizations](/docs/core/Civilizations.md) instance. */
    address public civilizations;

    /** @notice Address of the [Experience](/docs/core/Experience.md) instance. */
    address public experience;

    /** @notice Address of the [Equipment](/docs/core/Equipment.md) instance. */
    address public equipment;

    /** @notice Map to track the amount of points sacrificed by a character. */
    mapping(bytes => uint256) public sacrifices;

    /** @notice Map to track the first refresher token usage timestamps. */
    mapping(bytes => uint256) public refresher_usage_time;

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
            "Stats: onlyAllowed() token not minted."
        );
        require(
            ICivilizations(civilizations).isAllowed(msg.sender, _id),
            "Stats: onlyAllowed() msg.sender is not allowed to access this token."
        );
        _;
    }

    // =============================================== Events =========================================================

    /**
     * @notice Event emmited when the character base or pool points change.
     *
     * Requirements:
     * @param _id           Composed ID of the character.
     * @param _pool_stats   Pool stat points.
     * @param _base_stats   Pool stat points
     */
    event ChangedPoints(
        bytes indexed _id,
        BasicStats _base_stats,
        BasicStats _pool_stats
    );

    // =============================================== Setters ========================================================

    /**
     * @notice Constructor.
     *
     * Requirements:
     * @param _civilizations    The address of the [Civilizations](/docs/core/Civilizations.md) instance.
     * @param _experience       The address of the [Experience](/docs/core/Experience.md) instance.
     * @param _equipment       The address of the [Equipment](/docs/core/Equipment.md) instance.
     */
    constructor(
        address _civilizations,
        address _experience,
        address _equipment
    ) {
        civilizations = _civilizations;
        experience = _experience;
        equipment = _equipment;
        REFRESH_COOLDOWN_SECONDS = 86400; // 1 day
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
     * @notice Changes the amount of seconds of cooldown between refreshes.
     *
     * Requirements:
     * @param _cooldown     Amount of seconds to wait between refreshes.
     */
    function setRefreshCooldown(uint256 _cooldown) public onlyOwner {
        REFRESH_COOLDOWN_SECONDS = _cooldown;
    }

    /**
     * @notice Changes the Refresher [BaseGadgetToken](/docs/base/BaseGadgetToken.md) instance to use for paid refreshes.
     *
     * Requirements:
     * @param _refresher    Address of the new Refresher [BaseGadgetToken](/docs/base/BaseGadgetToken.md) instance.
     */
    function setRefreshToken(address _refresher) public onlyOwner {
        refresher = _refresher;
    }

    /**
     * @notice Changes the Vitalizer [BaseGadgetToken](/docs/base/BaseGadgetToken.md) instance to use for sacrifice points recover.
     *
     * Requirements:
     * @param _vitalizer    Address of the new Vitalizer [BaseGadgetToken](/docs/base/BaseGadgetToken.md) instance.
     */
    function setVitalizerToken(address _vitalizer) public onlyOwner {
        vitalizer = _vitalizer;
    }

    /**
     * @notice Removes the amount of points available on the character pool stats.
     *
     * Requirements:
     * @param _id       Composed ID of the character.
     * @param _stats    Stats to consume.
     */
    function consume(bytes memory _id, BasicStats memory _stats)
        public
        whenNotPaused
        onlyAllowed(_id)
    {
        BasicStats memory _modifiers = IEquipment(equipment)
            .getCharacterTotalStatsModifiers(_id);

        BasicStats memory _consumes;

        if (_modifiers.might < _stats.might) {
            _consumes.might = _stats.might - _modifiers.might;
        }

        if (_modifiers.speed <= _stats.speed) {
            _consumes.speed = _stats.speed - _modifiers.speed;
        }

        if (_modifiers.intellect <= _stats.intellect) {
            _consumes.intellect = _stats.intellect - _modifiers.intellect;
        }

        BasicStats storage _pool = pool[_id];

        require(
            _consumes.might <= _pool.might,
            "Stats: consume() not enough might."
        );
        require(
            _consumes.speed <= _pool.speed,
            "Stats: consume() not enough speed."
        );
        require(
            _consumes.intellect <= _pool.intellect,
            "Stats: consume() not enough intellect."
        );

        pool[_id].might -= _consumes.might;
        pool[_id].speed -= _consumes.speed;
        pool[_id].intellect -= _consumes.intellect;

        emit ChangedPoints(_id, base[_id], pool[_id]);
    }

    /**
     * @notice Removes the amount of points available on the character base stats.
     *
     * Requirements:
     * @param _id       Composed ID of the character.
     * @param _stats    Stats to consume.
     */
    function sacrifice(bytes memory _id, BasicStats memory _stats)
        public
        whenNotPaused
        onlyAllowed(_id)
    {
        BasicStats storage _base = base[_id];
        require(
            _stats.might <= _base.might,
            "Stats: sacrifice() not enough might."
        );
        require(
            _stats.speed <= _base.speed,
            "Stats: sacrifice() not enough speed."
        );
        require(
            _stats.intellect <= _base.intellect,
            "Stats: sacrifice() not enough intellect."
        );

        base[_id].might -= _stats.might;
        base[_id].speed -= _stats.speed;
        base[_id].intellect -= _stats.intellect;

        if (pool[_id].might > base[_id].might) {
            pool[_id].might = base[_id].might;
        }

        if (pool[_id].speed > base[_id].speed) {
            pool[_id].speed = base[_id].speed;
        }

        if (pool[_id].intellect > base[_id].intellect) {
            pool[_id].intellect = base[_id].intellect;
        }

        sacrifices[_id] += _stats.might;
        sacrifices[_id] += _stats.speed;
        sacrifices[_id] += _stats.intellect;
        emit ChangedPoints(_id, base[_id], pool[_id]);
    }

    /**
     * @notice Refills the pool stats for the character.
     *
     * Requirements:
     * @param _id   Composed ID of the character.
     */
    function refresh(bytes memory _id) public whenNotPaused onlyAllowed(_id) {
        uint256 _last = last_refresh[_id];
        require(
            _last == 0 || getNextRefreshTime(_id) <= block.timestamp,
            "Stats: refresh() not enough time has passed to refresh pool."
        );
        pool[_id].might = base[_id].might;
        pool[_id].speed = base[_id].speed;
        pool[_id].intellect = base[_id].intellect;
        last_refresh[_id] = block.timestamp;
        emit ChangedPoints(_id, base[_id], pool[_id]);
    }

    /**
     * @notice Refills the pool stats for the character spending a Refresher [BaseGadgetToken](/docs/base/BaseGadgetToken.md) token.
     *
     * Requirements:
     * @param _id   Composed ID of the character.
     */
    function refreshWithToken(bytes memory _id)
        public
        whenNotPaused
        onlyAllowed(_id)
    {
        require(
            IERC20(refresher).balanceOf(msg.sender) >= 1,
            "Stats: refreshWithToken() not enough refresh tokens balance."
        );
        require(
            IERC20(refresher).allowance(msg.sender, address(this)) >= 1,
            "Stats: refreshWithToken() not enough refresh tokens allowance."
        );
        require(
            getNextRefreshWithTokenTime(_id) <= block.timestamp,
            "Stats: refreshWithToken() no more refresh with tokens available."
        );

        ERC20Burnable(refresher).burnFrom(msg.sender, 1);

        if ((base[_id].might - pool[_id].might) > 20) {
            pool[_id].might += 20;
        } else {
            pool[_id].might = base[_id].might;
        }

        if ((base[_id].speed - pool[_id].speed) > 20) {
            pool[_id].speed += 20;
        } else {
            pool[_id].speed = base[_id].speed;
        }

        if ((base[_id].intellect - pool[_id].intellect) > 20) {
            pool[_id].intellect += 20;
        } else {
            pool[_id].intellect = base[_id].intellect;
        }

        refresher_usage_time[_id] = block.timestamp;
        emit ChangedPoints(_id, base[_id], pool[_id]);
    }

    /**
     * @notice Recovers a sacrificed point spending a Vitalizer [BaseGadgetToken](/docs/base/BaseGadgetToken.md) token.
     *
     * Requirements:
     * @param _id       Composed ID of the character.
     * @param _stats    Stats to sacrifice.
     */
    function vitalize(bytes memory _id, BasicStats memory _stats)
        public
        whenNotPaused
        onlyAllowed(_id)
    {
        require(
            sacrifices[_id] > 0,
            "Stats: vitalize() not enough sacrificed points."
        );
        uint256 sum = _stats.might + _stats.speed + _stats.intellect;
        require(sum == 1, "Stats: vitalize() too many points to recover.");
        require(
            IERC20(vitalizer).balanceOf(msg.sender) >= 1,
            "Stats: vitalize() not enough vitalizer tokens balance."
        );
        require(
            IERC20(vitalizer).allowance(msg.sender, address(this)) >= 1,
            "Stats: vitalize() not enough vitalizer tokens allowance."
        );

        ERC20Burnable(vitalizer).burnFrom(msg.sender, 1);

        base[_id].might += _stats.might;
        base[_id].speed += _stats.speed;
        base[_id].intellect += _stats.intellect;
        pool[_id].might += _stats.might;
        pool[_id].speed += _stats.speed;
        pool[_id].intellect += _stats.intellect;

        sacrifices[_id] -= 1;
        emit ChangedPoints(_id, base[_id], pool[_id]);
    }

    /**
     * @notice Increases points of the base pool based on new levels.
     *
     * Requirements:
     * @param _id       Composed ID of the character.
     * @param _stats    Stats to increase.
     */
    function assignPoints(bytes memory _id, BasicStats memory _stats)
        public
        whenNotPaused
        onlyAllowed(_id)
    {
        uint256 sum = _stats.might + _stats.speed + _stats.intellect;
        uint256 available = getAvailablePoints(_id);
        require(
            sum <= available,
            "Stats: assignPoints() too many points selected."
        );
        base[_id].might += _stats.might;
        base[_id].speed += _stats.speed;
        base[_id].intellect += _stats.intellect;
        pool[_id].might += _stats.might;
        pool[_id].speed += _stats.speed;
        pool[_id].intellect += _stats.intellect;
        emit ChangedPoints(_id, base[_id], pool[_id]);
    }

    // =============================================== Getters ========================================================

    /**
     * @notice External function that returns the base points of a character.
     *
     * Requirements:
     * @param _id       Composed ID of the character.
     *
     * @return _stats   Base stats of the character.
     */
    function getBaseStats(bytes memory _id)
        public
        view
        returns (BasicStats memory _stats)
    {
        return base[_id];
    }

    /**
     * @notice External function that returns the available pool points of a character.
     *
     * Requirements:
     * @param _id       Composed ID of the character.
     *
     * @return _stats   Available pool stats of the character.
     */
    function getPoolStats(bytes memory _id)
        public
        view
        returns (BasicStats memory _stats)
    {
        return pool[_id];
    }

    /**
     * @notice External function that returns the assignable points of a character.
     *
     * Requirements:
     * @param _id           Composed ID of the character.
     *
     * @return _points      Number of points available to assign.
     */
    function getAvailablePoints(bytes memory _id)
        public
        view
        returns (uint256 _points)
    {
        BasicStats memory _base = base[_id];
        uint256 _sum = _base.intellect + _base.might + _base.speed;
        uint256 level = IExperience(experience).getLevel(_id);
        uint256 assignableByLevel = _assignablePointsByLevel(level);
        return assignableByLevel - _sum;
    }

    /**
     * @notice External function that returns the next refresher timestamp for a character.
     *
     * Requirements:
     * @param _id           Composed ID of the character.
     *
     * @return _timestamp   Timestamp when the next refresh is available.
     */
    function getNextRefreshTime(bytes memory _id)
        public
        view
        returns (uint256 _timestamp)
    {
        return last_refresh[_id] + REFRESH_COOLDOWN_SECONDS;
    }

    /**
     * @notice External function that returns the next refresher timestamp for a character when using a Refresher [BaseGadgetToken](/docs/base/BaseGadgetToken.md) token.
     *
     * Requirements:
     * @param _id           Composed ID of the character.
     *
     * @return _timestamp   Timestamp when the next refresh is available.
     */
    function getNextRefreshWithTokenTime(bytes memory _id)
        public
        view
        returns (uint256 _timestamp)
    {
        return refresher_usage_time[_id] + REFRESH_COOLDOWN_SECONDS;
    }

    // =============================================== Internal ========================================================

    /**
     * @notice Internal function to get the amount of points assignable by a provided level.
     *
     * Requirements:
     * @param _level     Level to get the assignable points.
     *
     * @return _points   Amount of points spendable for this level.
     */
    function _assignablePointsByLevel(uint256 _level)
        internal
        pure
        returns (uint256 _points)
    {
        uint256 points = 6;
        return points + _level;
    }
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}