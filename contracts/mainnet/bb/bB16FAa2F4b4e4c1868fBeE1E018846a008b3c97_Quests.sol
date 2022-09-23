// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "../base/BaseFungibleItem.sol";

import "../interfaces/IQuests.sol";
import "../interfaces/ICivilizations.sol";
import "../interfaces/IExperience.sol";
import "../interfaces/IStats.sol";
import "../interfaces/IBaseFungibleItem.sol";

/**
 * @title Quests
 * @notice This contracts stores multiple quests and enables all the characters stored on the [Civilizations](/docs/core/Civilizations.md) instance
 * to obtain rewards and experience from them.
 *
 * @notice Implementation of the [IQuests](/docs/interfaces/IQuests.md) interface.
 */
contract Quests is
    IQuests,
    Initializable,
    PausableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    // =============================================== Storage ========================================================

    /** @notice Address of the [Civilizations](/docs/core/Civilizations.md) instance. */
    address public civilizations;

    /** @notice Address of the [Experience](/docs/core/Experience.md) instance. */
    address public experience;

    /** @notice Address of the [Stats](/docs/core/Stats.md) instance. */
    address public stats;

    /** @notice Map to track all the available quests. */
    mapping(uint256 => Quest) quests;

    /** @notice Array to track a full list of quests IDs. */
    uint256[] _quests;

    /** @notice Map to track current quests for all characters. **/
    mapping(bytes => CurrentQuest) public character_quests;

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
            "Quests: onlyAllowed() token not minted."
        );
        require(
            ICivilizations(civilizations).isAllowed(msg.sender, _id),
            "Quests: onlyAllowed() msg.sender is not allowed to access this token."
        );
        _;
    }

    // =============================================== Events =========================================================

    /**
     * @notice Event emmited when the [addQuest](#addQuest) function is called.
     *
     * Requirements:
     * @param _quest_id     ID of the quest added.
     * @param _name         Name of the quest.
     * @param _description  Quest description
     */
    event AddQuest(uint256 _quest_id, string _name, string _description);

    /**
     * @notice Event emmited when the [updateQuest](#updateQuest) function is called.
     *
     * Requirements:
     * @param _quest_id     ID of the quest added.
     * @param _name         Name of the quest.
     * @param _description  Quest description
     */
    event QuestUpdate(uint256 _quest_id, string _name, string _description);

    /**
     * @notice Event emmited when the [enableQuest](#enableQuest) function is called.
     *
     * Requirements:
     * @param _quest_id    ID of the quest enabled.
     */
    event EnableQuest(uint256 _quest_id);

    /**
     * @notice Event emmited when the [disableQuest](#disableQuest) function is called.
     *
     * Requirements:
     * @param _quest_id    ID of the recipe disabled.
     */
    event DisableQuest(uint256 _quest_id);

    // =============================================== Setters ========================================================

    /**
     * @notice Constructor.
     *
     * Requirements:
     * @param _civilizations    The address of the [Civilizations](/docs/core/Civilizations.md) instance.
     * @param _experience       The address of the [Experience](/docs/core/Experience.md) instance.
     * @param _stats            The address of the [Stats](/docs/core/Stats.md) instance.
     */
    function initialize(
        address _civilizations,
        address _experience,
        address _stats
    ) public initializer {
        __Ownable_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        civilizations = _civilizations;
        experience = _experience;
        stats = _stats;
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
     * @notice Disables a quest for characters.
     *
     * Requirements:
     * @param _quest_id   ID of the quest.
     */
    function disableQuest(uint256 _quest_id) public onlyOwner {
        require(
            _quest_id != 0 && _quest_id <= _quests.length,
            "Quests: disableQuest() invalid quest id."
        );
        quests[_quest_id].available = false;
        emit DisableQuest(_quest_id);
    }

    /**
     * @notice Enables a quest for characters.
     *
     * Requirements:
     * @param _quest_id   ID of the quest.
     */
    function enableQuest(uint256 _quest_id) public onlyOwner {
        require(
            _quest_id != 0 && _quest_id <= _quests.length,
            "Quests: enableQuest() invalid quest id."
        );
        quests[_quest_id].available = true;
        emit EnableQuest(_quest_id);
    }

    /**
     * @notice Adds a new quest for characters.
     *
     * Requirements:
     * @param _name                 Name of the quest.
     * @param _description          Description of the quest.
     * @param _quest_type           Type of the added quest.
     * @param _resources_reward     Array of [BaseFungibleItem](/docs/base/BaseFungibleItem.md) instances to reward for the quest.
     * @param _resources_amounts    Array of amounts for each resource reward.
     * @param _experience_reward    Amount of experience rewarded for the quest.
     * @param _stats                Stats to consume from the pool for the quest.
     * @param _cooldown             Number of seconds for the quest cooldown.
     * @param _level_required       Minimum level required to start the quest.
     */
    function addQuest(
        string memory _name,
        string memory _description,
        QuestType _quest_type,
        address[] memory _resources_reward,
        uint256[] memory _resources_amounts,
        uint256 _experience_reward,
        IStats.BasicStats memory _stats,
        uint256 _cooldown,
        uint256 _level_required
    ) public onlyOwner {
        uint256 _quest_id = _quests.length + 1;
        require(
            _resources_reward.length == _resources_amounts.length,
            "Quest: addQuest() materials and amounts not match."
        );
        quests[_quest_id] = Quest(
            _quest_id,
            _name,
            _description,
            _quest_type,
            _resources_reward,
            _resources_amounts,
            _experience_reward,
            _stats,
            _cooldown,
            _level_required,
            true
        );
        _quests.push(_quest_id);
        emit AddQuest(_quest_id, _name, _description);
    }

    /**
     * @notice Updates a previously added quest.
     *
     * Requirements:
     * @param _quest   Full information of the quest.
     */
    function updateQuest(Quest memory _quest) public onlyOwner {
        require(
            _quest.id != 0 && _quest.id <= _quests.length,
            "Quests: updateQuest() invalid quest id."
        );
        quests[_quest.id] = _quest;
        emit QuestUpdate(_quest.id, _quest.name, _quest.description);
    }

    /**
     * @notice Starts a quest for the character provided.
     *
     * Requirements:
     * @param _id               Composed ID of the character.
     * @param _quest_id         ID of the quest.
     * @param _stats_consumed   Amount of stats to consume for the quest.
     */
    function startQuest(
        bytes memory _id,
        uint256 _quest_id,
        IStats.BasicStats memory _stats_consumed
    ) public whenNotPaused onlyAllowed(_id) {
        require(
            _quest_id != 0 && _quest_id <= _quests.length,
            "Quests: startQuest() invalid quest id."
        );
        require(
            _isAvailableForQuest(_id),
            "Quest: startQuest() not available for quest."
        );
        Quest memory _quest = quests[_quest_id];
        require(
            _quest.available,
            "Quests: startQuest() quest is not available."
        );
        require(
            IExperience(experience).getLevel(_id) >= _quest.level_required,
            "Quests: startQuest() not enough level."
        );
        IStats(stats).consume(_id, _stats_consumed);
        uint256 _total_stats_consumed = _stats_consumed.might +
            _stats_consumed.speed +
            _stats_consumed.intellect;
        uint256 _max_quest_stats = _quest.stats_cost.might +
            _quest.stats_cost.speed +
            _quest.stats_cost.intellect;
        uint256 _fullfilment = _total_stats_consumed >= _max_quest_stats
            ? 100
            : (_total_stats_consumed * 100) / _max_quest_stats;
        character_quests[_id] = CurrentQuest(
            _quest_id,
            false,
            block.timestamp + _quest.cooldown,
            _fullfilment
        );
    }

    /**
     * @notice Claims a finished quest for the character.
     *
     * Requirements:
     * @param _id   Composed ID of the character.
     */
    function claimQuest(bytes memory _id)
        public
        whenNotPaused
        onlyAllowed(_id)
    {
        require(
            _isQuestClaimable(_id),
            "Quest: claimQuest() not available to claim."
        );

        character_quests[_id].claimed_reward = true;

        Quest memory _quest = quests[character_quests[_id].last_quest_id];

        uint256 _experience = (_quest.experience_reward *
            character_quests[_id].fullfilment) / 100;

        IExperience(experience).assignExperience(_id, _experience);

        for (uint256 i = 0; i < _quest.resources_reward.length; i++) {
            uint256 _amount = (_quest.resources_amounts[i] *
                character_quests[_id].fullfilment) / 100;

            IBaseFungibleItem(_quest.resources_reward[i]).mintTo(_id, _amount);
        }
    }

    // =============================================== Getters ========================================================

    /**
     * @notice Returns the full information of a quest.
     *
     * Requirements:
     * @param _quest_id       ID of the quest.
     *
     * @return _quest    Full quest information.
     */
    function getQuest(uint256 _quest_id)
        public
        view
        returns (Quest memory _quest)
    {
        return quests[_quest_id];
    }

    /**
     * @notice Returns the character current quest information.
     *
     * Requirements:
     * @param _id   Composed ID of the character.
     *
     * @return _quest    Current character quest information.
     */
    function getCharacterCurrentQuest(bytes memory _id)
        public
        view
        returns (CurrentQuest memory _quest)
    {
        return character_quests[_id];
    }

    // =============================================== Internal =======================================================

    /**
     * @notice Internal function to check if the character is able to start a quest.
     *
     * Requirements:
     * @param _id           Composed ID of the character.
     *
     * @return _available   Boolean to know if the character is available to start a quest.
     */
    function _isAvailableForQuest(bytes memory _id)
        internal
        view
        returns (bool _available)
    {
        if (character_quests[_id].cooldown == 0) {
            return true;
        }

        return
            character_quests[_id].cooldown <= block.timestamp &&
            character_quests[_id].claimed_reward;
    }

    /**
     * @notice Internal function to check if the last character quest is claimable.
     *
     * Requirements:
     * @param _id           Composed ID of the character.
     *
     * @return _claimable   Boolean to know if the last quest is claimable.
     */
    function _isQuestClaimable(bytes memory _id)
        internal
        view
        returns (bool _claimable)
    {
        return
            character_quests[_id].cooldown <= block.timestamp &&
            !character_quests[_id].claimed_reward &&
            character_quests[_id].last_quest_id != 0;
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

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../interfaces/ICivilizations.sol";
import "../interfaces/IBaseFungibleItem.sol";
import "../interfaces/IBaseERC20Wrapper.sol";

import "./BaseERC20Wrapper.sol";

/**
 * @title BaseERC721
 * @notice This contract an imitation of the `ERC20` standard to work around the character context.
 * It tracks balances of characters tokens. This also includes functions to wrap and unwrap to a
 * [BaseERC20Wrapper](/docs/base/BaseERC20Wrapper.md) instance.
 *
 * @notice Implementation of the [IBaseFungibleItem](/docs/interfaces/IBaseFungibleItem.md) interface.
 */
contract BaseFungibleItem is
    IBaseFungibleItem,
    Initializable,
    OwnableUpgradeable
{
    // =============================================== Storage ========================================================

    /** @notice Constant for the name of the item. */
    string public name;

    /** @notice Constant for the symbol of the item. */
    string public symbol;

    /** @notice Constant for the address of the [Civilizations](/docs/core/Civilizations.md) instance. */
    address public civilizations;

    /** @notice Map to track the balances of characters. */
    mapping(bytes => uint256) balances;

    /** @notice Constant for the address of the [BaseERC20Wrapper](/docs/base/BaseERC20Wrapper.md) instance. */
    address public wrapper;

    /** @notice Constant to enable/disable the token wrap. */
    bool public enable_wrap;

    /** @notice Map to store the list of authorized addresses to mint items. */
    mapping(address => bool) authorized;

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
            "BaseFungibleItem: onlyAllowed() token not minted."
        );
        require(
            ICivilizations(civilizations).isAllowed(msg.sender, _id),
            "BaseFungibleItem: onlyAllowed() msg.sender is not allowed to access this token."
        );
        _;
    }

    /** @notice Checks if the wrap functionality is enabled. */
    modifier onlyEnabled() {
        require(
            enable_wrap,
            "BaseFungibleItem: onlyEnabled() wrap is not enabled."
        );
        _;
    }

    /** @notice Checks if the `msg.sender` is authorized to mint items. */
    modifier onlyAuthorized() {
        require(
            authorized[msg.sender],
            "BaseFungibleItem: onlyAuthorized() msg.sender not authorized."
        );
        _;
    }

    // =============================================== Setters ========================================================

    /**
     * @notice Initialize.
     *
     * Requirements:
     * @param _name             Name of the `ERC20` token.
     * @param _symbol           Symbol of the `ERC20` token.
     * @param _civilizations    Address of the [Civilizations](/docs/core/Civilizations.md) instance.
     */
    function initialize(
        string memory _name,
        string memory _symbol,
        address _civilizations
    ) public initializer {
        __Ownable_init();
        name = _name;
        symbol = _symbol;
        civilizations = _civilizations;
        wrapper = address(new BaseERC20Wrapper(_name, _symbol));
        enable_wrap = false;
        authorized[msg.sender] = true;
    }

    /**
     * @notice Assigns a new address as an authority to mint items.
     *
     * Requirements:
     * @param _authority    Address to give authority.
     */
    function addAuthority(address _authority) public onlyOwner {
        authorized[_authority] = true;
    }

    /**
     * @notice Removes an authority to mint items.
     *
     * Requirements:
     * @param _authority    Address to give authority.
     */
    function removeAuthority(address _authority) public onlyOwner {
        require(
            authorized[_authority],
            "BaseFungibleItem: removeAuthority() address is not authorized."
        );
        authorized[_authority] = false;
    }

    /**
     * @notice Enables or disables the wrap function for the token.
     *
     * Requirements:
     * @param _enabled    Enable or diable wrap function.
     */
    function setWrapFunction(bool _enabled) public onlyOwner {
        enable_wrap = _enabled;
    }

    /**
     * @notice Creates tokens to the character composed ID provided.
     *
     * Requirements:
     * @param _id       Composed ID of the character.
     * @param _amount   Amount of tokens to create.
     */
    function mintTo(bytes memory _id, uint256 _amount) public onlyAuthorized {
        _mint(_id, _amount);
    }

    /**
     * @notice Reduces tokens to the character composed ID provided.
     *
     * Requirements:
     * @param _id       Composed ID of the character.
     * @param _amount   Amount of tokens to create.
     */
    function consume(bytes memory _id, uint256 _amount)
        public
        onlyAllowed(_id)
    {
        require(
            balances[_id] >= _amount,
            "BaseFungibleItem: consume() not enough balance."
        );
        balances[_id] -= _amount;
    }

    /**
     * @notice Converts the internal item to an `ERC20` through the [BaseERC20Wrapper](/docs/base/BaseERC20Wrapper.md).
     *
     * Requirements:
     * @param _id       Composed ID of the character.
     * @param _amount   Amount of tokens to create.
     */
    function wrap(bytes memory _id, uint256 _amount)
        public
        onlyAllowed(_id)
        onlyEnabled
    {
        consume(_id, _amount);
        IBaseERC20Wrapper(wrapper).mint(
            ICivilizations(civilizations).ownerOf(_id),
            _amount * 1 ether
        );
    }

    /**
     * @notice Converts the wrapped `ERC20` token to an internal fungible item.
     *
     * Requirements:
     * @param _id       Composed ID of the character.
     * @param _amount   Amount of tokens to create.
     */
    function unwrap(bytes memory _id, uint256 _amount)
        public
        onlyAllowed(_id)
        onlyEnabled
    {
        ERC20Burnable(wrapper).burnFrom(msg.sender, _amount * 1 ether);
        _mint(_id, _amount);
    }

    // =============================================== Getters ========================================================

    /**
     * @notice External function to get the balance of the character composed ID provided.
     *
     * Requirements:
     * @param _id           Composed ID of the character.
     *
     * @return _balance     Amount of tokens of the character from the composed ID.
     */
    function balanceOf(bytes memory _id)
        public
        view
        returns (uint256 _balance)
    {
        return balances[_id];
    }

    // =============================================== Internal ========================================================

    /**
     * @notice Internal function to create tokens to the character composed ID provided without
     * without owner check.
     *
     * Requirements:
     * @param _id       Composed ID of the character.
     * @param _amount   Amount of tokens to create.
     */
    function _mint(bytes memory _id, uint256 _amount) internal {
        balances[_id] += _amount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/IStats.sol";

/**
 * @title IQuests
 * @notice Interface for the [Quests](/docs/core/Quests.md) contract.
 */
interface IQuests {
    /**
     * @notice Internal enum to determine a quest type.
     *
    
     */
    enum QuestType {
        JOB,
        FARM,
        RAID
    }

    /**
     * @notice Internal struct for the quests information.
     *
     * Requirements:
     * @param id                    ID of the quest.
     * @param name                  Name of the quest.
     * @param description           Description of the quest.
     * @param quest_type            Type of the added quest.
     * @param resources_reward      Array of [BaseFungibleItem](/docs/base/BaseFungibleItem.md) instances to reward for the quest.
     * @param resources_amounts     Array of amounts for each resource reward.
     * @param experience_reward     Amount of experience rewarded for the quest.
     * @param stats_cost            The total amount of stats available to consume for the quest.
     * @param cooldown              Number of seconds for the quest cooldown.
     * @param level_required        Minimum level required to start the quest.
     * @param available             Boolean to check if the quest is available.
     */
    struct Quest {
        uint256 id;
        string name;
        string description;
        QuestType quest_type;
        address[] resources_reward;
        uint256[] resources_amounts;
        uint256 experience_reward;
        IStats.BasicStats stats_cost;
        uint256 cooldown;
        uint256 level_required;
        bool available;
    }

    /**
     * @notice Internal struct to store the current character quest information.
     *
     * Requirements:
     * @param last_quest_id     ID of the last quest.
     * @param claimed_reward    Boolean to know if the quest reward is already claimed.
     * @param cooldown          Timestamp until the quest reward can be claimed.
     * @param fullfilment       Percentage of fulfillment of the quest based on the stats assigned for reward calculations.
     */
    struct CurrentQuest {
        uint256 last_quest_id;
        bool claimed_reward;
        uint256 cooldown;
        uint256 fullfilment;
    }

    /** @notice See [Quests#pause](/docs/core/Quests.md#pause) */
    function pause() external;

    /** @notice See [Quests#unpause](/docs/core/Quests.md#unpause) */
    function unpause() external;

    /** @notice See [Quests#disableQuest](/docs/core/Quests.md#disableQuest) */
    function disableQuest(uint256 _quest_id) external;

    /** @notice See [Quests#enableQuest](/docs/core/Quests.md#enableQuest) */
    function enableQuest(uint256 _quest_id) external;

    /** @notice See [Quests#addQuest](/docs/core/Quests.md#addQuest) */
    function addQuest(
        string memory _name,
        string memory _description,
        QuestType _quest_type,
        address[] memory _resources_reward,
        uint256[] memory _resources_amounts,
        uint256 _experience_reward,
        IStats.BasicStats memory _stats,
        uint256 _cooldown,
        uint256 _level_required
    ) external;

    /** @notice See [Quests#updateQuest](/docs/core/Quests.md#updateQuest) */
    function updateQuest(Quest memory _quest) external;

    /** @notice See [Quests#startQuest](/docs/core/Quests.md#startQuest) */
    function startQuest(
        bytes memory _id,
        uint256 _quest_id,
        IStats.BasicStats memory _stats_consumed
    ) external;

    /** @notice See [Quests#claimQuest](/docs/core/Quests.md#claimQuest) */
    function claimQuest(bytes memory _id) external;

    /** @notice See [Quests#getQuest](/docs/core/Quests.md#getQuest) */
    function getQuest(uint256 _quest_id)
        external
        view
        returns (Quest memory _quest);

    /** @notice See [Quests#getCharacterCurrentQuest](/docs/core/Quests.md#getCharacterCurrentQuest) */
    function getCharacterCurrentQuest(bytes memory _id)
        external
        view
        returns (CurrentQuest memory _quest);
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
pragma solidity 0.8.17;

/**
 * @title IBaseERC20Wrapper
 * @notice Interface for the [BaseERC20Wrapper](/docs/base/BaseERC20Wrapper.md) contract.
 */
interface IBaseERC20Wrapper {
    /** @notice See [BaseERC20Wrapper#mint](/docs/base/BaseERC20Wrapper.md#mint) */
    function mint(address _to, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../interfaces/IBaseERC20Wrapper.sol";

/**
 * @title BaseERC20Wrapper
 * @notice This contract is a standard `ERC20` implementation with burnable and mintable
 * functions exposed to the contract owner. This contract is a wrapper for the [BaseFungibleItem](/docs/base/BaseFungibleItem.md) instance to convert
 * an internal fungible token to the `ERC20` standard.
 *
 * @notice Implementation of the [IBaseERC20Wrapper](/docs/interfaces/IBaseERC20Wrapper.md) interface.
 */
contract BaseERC20Wrapper is IBaseERC20Wrapper, Ownable, ERC20Burnable {
    // =============================================== Setters ========================================================

    /**
     * @notice Constructor.
     *
     * Requirements:
     * @param _name     Name of the `ERC20` token.
     * @param _symbol   Symbol of the `ERC20` token.
     */
    constructor(string memory _name, string memory _symbol)
        ERC20(_name, _symbol)
    {}

    /**
     * @notice Creates tokens to the address provided.
     *
     * Requirements:
     * @param _to        Address that receives the tokens.
     * @param _amount    Amount to be minted.
     */
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
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