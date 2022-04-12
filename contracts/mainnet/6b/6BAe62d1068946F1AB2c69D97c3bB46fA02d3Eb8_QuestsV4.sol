// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../system/CrudKeySet.sol";
import "../system/HSystemChecker.sol";
import "../items/IItemFactory.sol";
import "../milk/ITreasury.sol";
import "./IAdventurersGuild.sol";
import "../items/IPetInteractionHandler.sol";
import "../../common/Multicall.sol";

/// @title QuestsV4
/// @dev Allows the rolling of quests built up of a Quest ID, QuestIO for its rarity, and an element.
/// @dev A quest can be completed from a users selection and requirements taken and rewards given.
contract QuestsV4 is HSystemChecker, Multicall {

    using CrudKeySetLib for CrudKeySetLib.Set;
    CrudKeySetLib.Set _questSet;

    ITreasury _treasury;
    IAdventurersGuild _adventurersGuild;
    IItemFactory _itemFactory;

    address public _treasuryContractAddress;
    address public _adventurersGuildContractAddress;
    address public _itemFactoryContractAddress;
    address public _petInteractionHandlerContractAddress;

    enum Rarity {
        COMMON, UNCOMMON, RARE, EPIC, LEGENDARY
    }

    enum Element {
        NONE, GRASS, AIR, FIRE, WATER
    }

    /// @dev This is the expanded data for user Quests
    /// @dev as derived from user random quest number
    struct QuestReferenceStruct {
        uint256 element;
        uint256 questId;
        uint256 ioDataId;
    }

    struct QuestStruct {
        uint256 questId;
        uint256 element;
        QuestIOStruct ioData;
    }

    /// @dev gold amounts should be entered in gwei (1E9) and are multipled to 1E18 on reward minting
    /// @dev bonus is the percentage on top of the gold amount from the quest we wish to reward.
    /// @dev e.g a bonus of 2500 will add 25% to the total gold reward
    /// @dev items are appended to the struct in getQuestIOById()
    struct QuestIOStruct {
        uint256 ioId;
        uint256 rarity;
        uint256 goldRequirement;
        uint256 itemRequirements;
        uint256 bonus;
        uint64 minGold;
        uint64 maxGold;
        uint16[] items;
    }

    struct DailyStruct {
        uint8 dailyQuests;
        uint48 timestamp;
    }

    struct RewardStruct {
        uint256 totalReward;
        uint256 baseReward;
        uint256 modifiedBase;
        uint256 elementBonus;
        uint256 petStageBonus;
    }

    uint256[] public _petStageBonus = [0, 500, 1000, 1000];

    bool public _questingPaused = false;

    uint8 public _questAllowance = 10;

    uint8 public _numberOfQuestsToRoll = 5;
    uint8 public _numberOfCommons = 2;
    uint16 public _milkModifier;

    /// @notice Quest rarity rolls
    uint16 public _commonRoll = 24;
    uint16 public _uncommonRoll = 64;
    uint16 public _rareRoll = 94;
    uint16 public _epicRoll = 98;
    uint16 public _legendaryRoll = 100;

    uint16 public _maxRarityRoll = 100;

    /// @dev Percentage chance for a quest to roll with no elemental affinity
    /// @dev % based NOT bp
    uint16 public _noElementPercent = 52;

    /// @dev MUST be set as midnight at some date before contract deployment
    /// @dev The date incremented by 24 hours (in seconds) at each reset
    uint48 public constant START = 1638662400;
    uint48 public constant DAY_IN_SECONDS = 86400;

    /// @dev Value in Wei (10^18)
    uint256 public _reRollCost = 27 ether;

    /// @notice maps rarities to the io of that rarity
    mapping(uint256 => CrudKeySetLib.Set) _rarityIOs;

    /// @notice maps user to their random quest number
    mapping(address => uint256) public _userQuestRandomNumber;

    /// @dev Maps pet token id to quests per day data
    mapping(uint256 => DailyStruct) public _petQuestData;

    /// @dev io data packed into uint256
    /// @dev item[] overflows into the _itemRewards mapping
    mapping(bytes32 => uint256) public _ioStorage;
    mapping(bytes32 => uint16[]) public _itemRewards;

    /// @notice Emitted when a quest is added
    /// @param questId - Quest id added
    event LogQuestCreated(uint256 questId);

    /// @notice Emitted when a quest is deleted
    /// @param questId - Quest id deleted
    event LogQuestDeleted(uint256 questId);

    /// @notice Emitted when a QuestIO is added
    /// @param ioId - Id of io
    /// @param rarity - The rarity of the io
    /// @param goldRequirements - The gold required to complete the quest
    /// @param itemRequirements - The number of items that must be sent to complete the quest
    /// @param bonus - The bonus to add to quest gold rewards (in basis points)
    /// @param minGold - The minimum gold reward
    /// @param maxGold - The maximum gold reward
    /// @param items - The item rewards of the quest
    event LogQuestIOAdded(
        uint256 ioId,
        uint256 rarity,
        uint256 goldRequirements,
        uint256 itemRequirements,
        uint256 bonus,
        uint256 minGold,
        uint256 maxGold,
        uint16[] items
    );

    /// @notice Emitted when a QuestIO is edited
    /// @param ioId - The id to add (starts at 1)
    /// @param rarity - The rarity of the io
    /// @param goldRequirements - The gold required to complete the quest
    /// @param itemRequirements - The number of items that must be sent to complete the quest
    /// @param bonus - The bonus to add to quest gold rewards (in basis points)
    /// @param minGold - The minimum gold reward
    /// @param maxGold - The maximum gold reward
    /// @param items - The item rewards of the quest
    event LogQuestIOEdited(
        uint ioId,
        uint256 rarity,
        uint256 goldRequirements,
        uint256 itemRequirements,
        uint256 bonus,
        uint256 minGold,
        uint256 maxGold,
        uint16[] items
    );

    /// @notice Emitted when a QuestIO is deleted
    /// @param ioId - id of the io to delete
    event LogQuestIODeleted(uint ioId);

    /// @notice Emitted when quests are rolled for a user
    /// @param user - Address of the user
    /// @param reRoll - Flag to decide whether to nuke a users quests before rolling
    /// @param random - The user's random quest number
    /// @param entropy - Backend entropy to remove gaming the system
    event LogRollQuest(address user, bool reRoll, uint256 random, uint256 entropy);

    /// @notice Emitted when a quest is completed
    /// @param user - Address of the user
    /// @param questId - Quest id completed
    /// @param element - Element of the quest
    /// @param ioId - Id of the QuestIO
    /// @param petTokenId - Id of the pet completing the quest
    /// @param rewardStruct - Struct containing details of the reward
    event LogQuestCompleted(
        address user,
        uint256 questId,
        uint256 element,
        uint256 ioId,
        uint256 petTokenId,
        RewardStruct rewardStruct
    );

    /// @notice Emitted when rarity rolls are set
    /// @param common - Rarity level of common quests
    /// @param uncommon - Rarity level of uncommon quests
    /// @param rare - Rarity level of rare quests
    /// @param epic - Rarity level of epic quests
    /// @param legendary - Rarity level of legendary quests
    /// @param maxRoll - Max rarity level
    event LogSetRarityRolls(
        uint16 common,
        uint16 uncommon,
        uint16 rare,
        uint16 epic,
        uint16 legendary,
        uint16 maxRoll
    );

    /// @notice Emitted when quest rolling is paused or unpaused
    /// @param paused - New paused status
    event LogQuestingPaused(bool paused);

    /// @notice Emitted when daily quest allowance is set
    /// @param number - The number of quests a pet can go on per day
    event LogChangeDailyQuestAllowance(uint256 number);

    /// @notice Emitted when number of rolls guaranteed is set
    /// @param number - The number of rolls quaranteed to be rolled
    event LogChangeNumberOfRolls(uint256 number);

    /// @notice Emitted when number of commons is set
    /// @param number - The number of rolls quaranteed to be rolled
    event LogSetNumberOfCommons(uint8 number);

    /// @notice Emmited when the percentage chance of a quest rolling with no element is set
    /// @param number - The percentage chance
    event LogSetNoElementPercent(uint16 number);

    /// @notice Emitted when the bonuses given for questing for different pet stages is set
    /// @param petStageBonus - Array of bp values
    event LogSetPetStageBonus(uint256[] petStageBonus);

    /// @notice Emitted when the gold cost of re-rolling quests is set
    /// @param cost - Re-roll cost in wei
    event LogSetReRollCost(uint256 cost);

    /// @notice Emitted when the Item Factory contract address is updated
    /// @param itemFactoryContractAddress - Item Factory contract address
    event LogSetItemFactoryContractAddress(address itemFactoryContractAddress);

    /// @notice Emitted when the Adventurers Guild contract address is updated
    /// @param adventurersGuildContractAddress - Item Factory contract address
    event LogSetAdventurersGuildContractAddress(address adventurersGuildContractAddress);

    /// @notice Emitted when the Pet Interaction Handler contract address is updated
    /// @param petInteractionHandlerContractAddress - Item Factory contract address
    event LogSetPetInteractionHandlerContractAddress(address petInteractionHandlerContractAddress);

    /// @notice Emitted when the Treasury contract address is updated
    /// @param treasuryContractAddress - Item Factory contract address
    event LogSetTreasuryContractAddress(address treasuryContractAddress);

    /// @notice Emitted when the Milk modifier is set
    /// @param milkModifer - Milk modifier
    event LogSetMilkModifier(uint16 milkModifer);

    constructor(
        address systemCheckerContractAddress,
        address itemFactoryContractAddress,
        address treasuryContractAddress,
        address adventureContractAddress,
        address petInteractionHandlerContractAddress
    ) HSystemChecker(systemCheckerContractAddress) {
        _petInteractionHandlerContractAddress = petInteractionHandlerContractAddress;

        _treasuryContractAddress = treasuryContractAddress;
        _treasury = ITreasury(treasuryContractAddress);

        _adventurersGuildContractAddress = adventureContractAddress;
        _adventurersGuild = IAdventurersGuild(adventureContractAddress);

        _itemFactoryContractAddress = itemFactoryContractAddress;
        _itemFactory = IItemFactory(itemFactoryContractAddress);
    }

    /// @notice Check that a quest exists
    /// @param id - Id of quest to convert to key and check
    modifier questExists(uint256 id) {
        require(_questSet.exists(bytes32(id)), "QC 404 - Quest doesn't exist");
        _;
    }

    /// @notice Check that a questIO exists
    /// @param id - Id questIO to convert to key and check
    modifier ioExists(uint256 id) {
        require(_ioStorage[bytes32(id)] != 0, "QC 407 - IO structure doesn't exist");
        _;
    }

    /// @notice Check that a rarity is within bounds
    /// @param rarity - Rarity of quest to check is within bounds
    modifier rarityLimit(uint256 rarity) {
        require(rarity <= uint(Rarity.LEGENDARY), "QC 405 - Rarity out of bounds");
        _;
    }

    /// @notice Add single quest
    /// @param questId - Id of the quest to add
    function addQuest(uint256 questId) public onlyRole(ADMIN_ROLE) {
        require(questId < 65536, "QC 419 - Quest id exceeds max for uint16");

        // This will revert if key already exists
        _questSet.insert(bytes32(questId));

        // quest created event
        emit LogQuestCreated(questId);
    }

    /// @notice Delete single quest from the system
    /// @param questId - Id of the quest to delete
    function deleteQuest(uint256 questId) public onlyRole(ADMIN_ROLE) questExists(questId) {
        // nuke it
        _questSet.remove(bytes32(questId));

        // quest edited event
        emit LogQuestDeleted(questId);
    }

    /// @notice Add a single QuestIO
    /// @dev Gold amounts should be added in gwei (1E9)
    /// @dev Bonus is added in basis points, where 1% is 100 bonus
    /// @param id - The id to add (starts at 1)
    /// @param rarity - The rarity of the io
    /// @param goldRequirement - The gold required to complete the quest
    /// @param itemRequirements - The number of items that must be sent to complete the quest
    /// @param bonus - The bonus to add to quest gold rewards (in basis points)
    /// @param minGold - The minimum gold reward
    /// @param maxGold - The maximum gold reward
    /// @param items - The item rewards of the quest
    function addQuestIO(
        uint256 id,
        uint256 rarity,
        uint256 goldRequirement,
        uint256 itemRequirements,
        uint256 bonus,
        uint256 minGold,
        uint256 maxGold,
        uint16[] memory items
    ) external onlyRole(ADMIN_ROLE) rarityLimit(rarity) {
        require(_ioStorage[bytes32(id)] == 0, "QC 420 - QuestIO already exists");
        _addQuestIO(id, rarity, goldRequirement, itemRequirements, bonus, minGold, maxGold, items);

        emit LogQuestIOAdded(id, rarity, goldRequirement, itemRequirements, bonus, minGold, maxGold, items);
    }

    /// @notice Edit a QuestIO
    /// @dev Gold amounts should be added in gwei (1E9)
    /// @dev Bonus is added in basis points, where 1% is 100 bonus
    /// @dev ioExists handled by _deleteQuestIO
    /// @param id - The id to add (starts at 1)
    /// @param rarity - The rarity of the io
    /// @param goldRequirement - The gold required to complete the quest
    /// @param itemRequirements - The number of items that must be sent to complete the quest
    /// @param bonus - The bonus to add to quest gold rewards (in basis points)
    /// @param minGold - The minimum gold reward
    /// @param maxGold - The maximum gold reward
    /// @param items - The item rewards of the quest
    function editQuestIO(
        uint256 id,
        uint256 rarity,
        uint256 goldRequirement,
        uint256 itemRequirements,
        uint256 bonus,
        uint256 minGold,
        uint256 maxGold,
        uint16[] memory items
    ) external onlyRole(ADMIN_ROLE) rarityLimit(rarity) {
        _deleteQuestIO(id);
        _addQuestIO(id, rarity, goldRequirement, itemRequirements, bonus, minGold, maxGold, items);

        emit LogQuestIOEdited(id, rarity, goldRequirement, itemRequirements, bonus, minGold, maxGold, items);
    }

    /// @notice Delete a single QuestIO
    /// @param id - Id of the io to delete
    function deleteQuestIO(uint256 id) public onlyRole(ADMIN_ROLE) {
        _deleteQuestIO(id);

        emit LogQuestIODeleted(id);
    }

    /// @notice Roll randomNumber per user so that quests could be derived from those random number
    /// @param user - address of the user
    /// @param reRoll - whether to nuke a users quests before rolling
    /// @param entropy - backend entropy to remove gaming the system
    function rollUserQuests(address user, bool reRoll, uint256 entropy) public onlyRole(GAME_ROLE) isUser(user) {
        uint256 userQuestRandomNumber = _userQuestRandomNumber[user];
        require(!_questingPaused, "QC 406 - Questing is paused");
        require((userQuestRandomNumber == 0 || reRoll), "QC 401 - User already has quests");

        // If the user requests a reroll we dont have to zero the number we simply have to take their MILK
        // the rest of the function will roll a new value, this way we can save on gas
        // the _burn will error if use has insufficient funds
        if (reRoll && _reRollCost > 0) {
            _treasury.burn(user, _reRollCost);
        }

        // only need the random number
        // solidity deterministic FTW!
        userQuestRandomNumber = uint256(keccak256(abi.encode(block.timestamp, block.difficulty, entropy)));
        _userQuestRandomNumber[user] = userQuestRandomNumber;

        emit LogRollQuest(user, reRoll, userQuestRandomNumber, entropy);
    }

    /// @notice Complete a quest for a user and send the relevant rewards
    /// @dev emits QuestCompleted
    /// @dev burnItem checks for user holding items
    /// @dev treasury.burn checks for user having enough gold
    /// @dev isUser handled by gold and item factory calls
    /// @param user - Address of the user
    /// @param index - The index of a quest in the user rewards array
    /// @param entropy - A value to add make the function less deterministic
    function completeQuest(
        address user,
        uint256 index,
        uint256 petTokenId,
        uint256[] memory chosenItems,
        uint256 entropy,
        bool rewardBonus
    ) external {
        _completeQuest(user, index, petTokenId, chosenItems, entropy, rewardBonus);
    }

    /// @notice Complete a quest as above and roll immediately after
    /// @dev emits QuestCompleted
    /// @dev burnItem checks for user holding items
    /// @dev treasury.burn checks for user having enough gold
    /// @dev isUser handled by gold and item factory calls
    /// @param user - address of the user
    /// @param index - the index of a quest in the user rewards array
    /// @param entropy - a value to add make the function less deterministic
    function completeQuestAndRoll(
        address user,
        uint256 index,
        uint256 petTokenId,
        uint256[] memory chosenItems,
        uint256 entropy,
        bool rewardBonus
    ) external {
        _completeQuest(user, index, petTokenId, chosenItems, entropy, rewardBonus);
        rollUserQuests(user, false, entropy);
    }

    /** INTERNAL */

    /// @notice Complete a quest for a user and send the relevant rewards
    /// @dev emits QuestCompleted
    /// @dev burnItem checks for user holding items
    /// @dev treasury.burn checks for user having enough gold
    /// @dev isUser handled by gold and item factory calls
    /// @param user - address of the user
    /// @param index - the index of a quest in the user rewards array
    /// @param entropy - a value to add make the function less deterministic
    function _completeQuest(
        address user,
        uint256 index,
        uint256 petTokenId,
        uint256[] memory chosenItems,
        uint256 entropy,
        bool rewardBonus
    ) internal onlyRole(GAME_ROLE) {

        uint256 userQuestRandomNumber = _userQuestRandomNumber[user];
        require(userQuestRandomNumber > 0, "QC 403 - User has no quests");

        require(!_adventurersGuild.isPetStaked(petTokenId), "QC 402 - Staked pets cannot quest");
        require(_adventurersGuild._lastClaim(petTokenId) + 86400 < getDailyResetTime(), "QC 421 - Pet cannot quest in the same daily reset period as it was unstaked");

        QuestReferenceStruct memory questStruct = _unpackQuestByIndex(userQuestRandomNumber, index);

        uint256 currentPetStage = IPetInteractionHandler(_petInteractionHandlerContractAddress).getCurrentPetStage(petTokenId);

        // Handle the burning and minting and quest requirements and rewards
        QuestIOStruct memory io = getQuestIOById(questStruct.ioDataId);
        _burnRequirement(io, user, chosenItems);

        // Get the various rewards amounts
        RewardStruct memory rewardStruct = _handleRewards(io, user, entropy, rewardBonus, currentPetStage);

        // Add to daily quest limit
        _incrementDailyQuestCounter(petTokenId);

        // delete user quest number
        delete _userQuestRandomNumber[user];

        emit LogQuestCompleted(user, questStruct.questId, questStruct.element, io.ioId, petTokenId, rewardStruct);
    }

    /// @notice Determine user's quests based on their random number and return the indexed one
    /// @param questNumber - User's random number equivalent to their quests
    /// @param index - Index within the quest list
    /// @return QuestReferenceStruct - Indexed quest in the quests list
    function _unpackQuestByIndex(uint256 questNumber, uint256 index) internal view returns (QuestReferenceStruct memory) {

        // Based on the user's random number, derive the quests
        uint256[] memory userQuests = _getUserQuestsFromQuestNumber(questNumber);
        require(index < userQuests.length, "QC 400 - Quest index out of bounds");

        // Access the one with index and return
        uint256 quest = userQuests[index];

        return QuestReferenceStruct(
            uint256(uint8(quest)), // element
            uint256(uint16(quest >> 8)), // questId
            uint256(uint16(quest >> 24))    // ioDataId
        );
    }

    /// @notice Determine user's quests based on their random number
    /// @param questNumber - User's random number equivalent to their quests
    /// @return uint256[] - The uint256 array - data packed - which equivalent to quests
    function _getUserQuestsFromQuestNumber(uint256 questNumber) internal view returns (uint256[] memory) {

        uint256 store;
        uint256[] memory questIds = new uint256[](_questSet.count());
        uint256[] memory quests = new uint256[](_numberOfQuestsToRoll);

        for (uint256 i; i < _numberOfQuestsToRoll; i++) {

            uint256 rarity;
            // pick 2 random common quests to ensure there is always 2 quests a user can complete
            if (i < _numberOfCommons) {
                rarity = uint(Rarity.COMMON);
            } else {

                // i > 1
                uint256 randRarity = questNumber % _maxRarityRoll;

                // pick rarity based on quest rarity chances
                if (randRarity < _commonRoll) {
                    rarity = uint(Rarity.COMMON);
                } else if (randRarity < _uncommonRoll) {
                    rarity = uint(Rarity.UNCOMMON);
                } else if (randRarity < _rareRoll) {
                    rarity = uint(Rarity.RARE);
                } else if (randRarity < _epicRoll) {
                    rarity = uint(Rarity.EPIC);
                } else {
                    rarity = uint(Rarity.LEGENDARY);
                }
            }

            bytes32[] memory keys = _rarityIOs[rarity].keyList;
            questNumber >>= 8;

            store = _pickElement(questNumber);
            // element
            store |= uint256(_questSet.keyAtIndex(_pickQuestIndex(questNumber, questIds))) << 8;
            // questId
            store |= uint256(keys[(questNumber) % keys.length]) << 24;
            // ioId

            quests[i] = store;
        }

        return quests;
    }

    /// @notice Burn the required gold/items
    /// @param io - QuestIOStruct data
    /// @param user - Address of user to give rewards to
    /// @param chosenItems - Array of item ids to be burned
    function _burnRequirement(QuestIOStruct memory io, address user, uint256[] memory chosenItems) internal {
        // Burn gold requirements
        if (io.goldRequirement > 0) {
            _treasury.burn(user, io.goldRequirement * 1 gwei);
            // Converted from gwei to wei
        }

        // Burns item requirements
        require(chosenItems.length == io.itemRequirements, "QC 409 - Wrong number of items sent");

        for (uint256 i; i < chosenItems.length; i++) {
            _itemFactory.burnItem(user, chosenItems[i], 1);
        }
    }

    /// @notice Handled the rewards for quests
    /// @param io - QuestIOStruct data
    /// @param user - Address of user to give rewards to
    /// @param entropy - Some entropy for random number handling
    /// @param rewardBonus - Use the reward bonus
    /// @return rewardStruct - Varies rewards for the quest
    function _handleRewards(
        QuestIOStruct memory io,
        address user,
        uint256 entropy,
        bool rewardBonus,
        uint256 currentPetStage
    ) internal returns (RewardStruct memory rewardStruct) {

        // calculate the base MILK reward
        // Note: Can only grant other bonuses if we have a base amount of MILK to bonus from
        if (io.maxGold > 0) {

            // Calculate reward and convert from wei to gwei
            rewardStruct.baseReward = _numberBetween(io.minGold, io.maxGold, entropy) * 1 gwei;

            // Add modifier
            if (_milkModifier > 0) {
                rewardStruct.modifiedBase = ((rewardStruct.baseReward * (10000 + _milkModifier)) / 10000) - rewardStruct.baseReward;
            }

            // Calculate the elemental Bonus - % as BP
            if (rewardBonus) {
                rewardStruct.elementBonus = ((rewardStruct.baseReward * (10000 + io.bonus)) / 10000) - rewardStruct.baseReward;
            }

            // Calculate pet stage bonus
            rewardStruct.petStageBonus = ((rewardStruct.baseReward * (10000 + _petStageBonus[currentPetStage])) / 10000) - rewardStruct.baseReward;

            // Give total reward
            rewardStruct.totalReward = rewardStruct.baseReward + rewardStruct.elementBonus + rewardStruct.petStageBonus + rewardStruct.modifiedBase;
            _treasury.mint(user, rewardStruct.totalReward);
        }

        // Mint and send item rewards
        // Only allow final form pets to get items
        if (currentPetStage == 3) {
            for (uint256 i; i < io.items.length; i++) {
                _itemFactory.mintItem(user, io.items[i], 1);
            }
        }

        return rewardStruct;
    }

    /// @notice Picks element randomly for a quest
    /// @dev % based NOT bp
    /// @param randomNum - The random number for choosing an element
    /// @return uint - Element id that corresponds to element enum
    function _pickElement(uint256 randomNum) internal view returns (uint256) {
        uint16 percent = uint16(randomNum % 100);
        if (percent < _noElementPercent) {
            return uint256(Element.NONE);
        }
        return 1 + (percent % 4);
    }

    /// @notice Pick a quest index randomly from an array
    /// @dev Written to minimise gas costs when generating the uint array
    /// @dev Allows us to edit the length of a memory array (saves writing the array to storage)
    /// @dev Uses inline assembly to achieve this
    /// @param randomNum - A random number
    /// @param arr - The array to choose from
    function _pickQuestIndex(uint256 randomNum, uint256[] memory arr) internal pure returns (uint256 index) {
        require(arr.length > 0, "QC 410 - Not enough quests to pick from");

        uint256 rollVal = randomNum % arr.length;

        // If the element of the array at the rolled value is nonzero,
        // then that is the index of the quest we have selected.
        // If it is zero we want to return the index of that element (the roll value)
        if (arr[rollVal] != 0) {
            index = arr[rollVal];
        } else {
            index = rollVal;
        }

        if (rollVal != arr.length - 1) {
            // Handles the changes to the array when we pop the final element.
            // Allows us to pass a fixed length zero array, rather than an
            // array with the index value as the element.
            if (arr[arr.length - 1] == 0) {
                arr[rollVal] = arr.length - 1;
            } else {
                arr[rollVal] = arr[arr.length - 1];
            }
        }

        // Inline assembly (slightly scary) to reduce the length of the memory array by 1. Pop.
        assembly {mstore(arr, sub(mload(arr), 1))}

        return index;
    }

    /// @notice Increments the daily quest counter by one for a given pet.
    /// @dev If the daily timer has ticked over, reset the counter for the day and set the new reset time.
    /// @param tokenId - Pet token id that has quested
    function _incrementDailyQuestCounter(uint256 tokenId) internal {
        uint48 currentTime = uint48(block.timestamp);

        DailyStruct memory data = _petQuestData[tokenId];

        // Pet has no timestamp, so we set it for the first time
        if (data.timestamp == 0) {
            // If timestamp is zero, the user has never interacted with the questing before
            // Initialise their timestamp as the current reset time
            data.timestamp = START + (((currentTime - START) / DAY_IN_SECONDS) * DAY_IN_SECONDS);
            data.dailyQuests = 1;
        }

        // Current time is great than the pet timestamp + a whole day.
        // This means the quests counter can be reset as it is a new day
        else if (currentTime > data.timestamp + DAY_IN_SECONDS) {
            // Update their timestamp to the current reset time
            data.timestamp = data.timestamp + (((currentTime - data.timestamp) / DAY_IN_SECONDS) * DAY_IN_SECONDS);
            data.dailyQuests = 1;
        }

        // Pet is completing quests within a single day so we increment the quest counter to reflect the usage
        // of the daily allowance
        else {
            require(data.dailyQuests < _questAllowance, "QC 101 - Pet has exceeded their daily quest allowance");
            data.dailyQuests++;
        }

        // Save data to storage
        _petQuestData[tokenId] = data;
    }

    /// @notice generates a random number between a minimum and maximum value
    /// @param min - The minimum value
    /// @param max - The maximum value
    /// @param entropy - A value to add make the function less deterministic
    function _numberBetween(uint256 min, uint256 max, uint256 entropy) internal view returns (uint256) {
        uint256 randomHash = uint256(keccak256(abi.encode(block.timestamp, entropy)));
        return min + randomHash % (max - min + 1);
    }

    /// @notice Internal method to add a single QuestIO
    /// @dev Used to avoid stack depth errors.
    /// @dev Gold amounts should be added in gwei (1E9)
    /// @dev Bonus is added in basis points, where 1% is 100 bonus
    /// @param id - The id to add (starts at 1)
    /// @param rarity - The rarity of the io
    /// @param goldRequirement - The gold required to complete the quest
    /// @param itemRequirements - The number of items that must be sent to complete the quest
    /// @param bonus - The bonus to add to quest gold rewards (in basis points)
    /// @param minGold - The minimum gold reward
    /// @param maxGold - The maximum gold reward
    /// @param items - The item rewards of the quest
    function _addQuestIO(
        uint256 id,
        uint256 rarity,
        uint256 goldRequirement,
        uint256 itemRequirements,
        uint256 bonus,
        uint256 minGold,
        uint256 maxGold,
        uint16[] memory items
    ) internal {
        bytes32 key = bytes32(id);

        require(minGold <= maxGold, "QC 411 - The minimum gold reward must be less than or equal to the maximum");

        require(id < 65536, "QC 412 - QuestIO id exceeds max of uint16");
        require(goldRequirement < 18446744073709551616, "QC 414 - Gold requirement exceeds max of uint64");
        require(itemRequirements < 256, "QC 415 - Item requirements exceed max of uint8");
        require(bonus < 65536, "QC 416 - Bonus exceeds max of uint16");
        require(minGold < 18446744073709551616, "QC 417 - Minimum gold reward exceeds max of uint64");
        require(maxGold < 18446744073709551616, "QC 418 - Maximum gold reward exceeds max of uint64");

        uint256 store = id;
        store |= rarity << 16;
        store |= goldRequirement << 24;
        store |= itemRequirements << 88;
        store |= bonus << 96;
        store |= minGold << 112;
        store |= maxGold << 176;
        _ioStorage[key] = store;

        _itemRewards[key] = items;

        _rarityIOs[rarity].insert(key);
    }

    /// @notice Internal function to delete a single QuestIO
    /// @dev Does not emit any events, used to avoid stack depth errors
    /// @param id - Id of the io to delete
    function _deleteQuestIO(uint256 id) internal ioExists(id) {
        bytes32 key = bytes32(id);

        _rarityIOs[getQuestIOById(id).rarity].remove(key);

        delete _ioStorage[key];
        delete _itemRewards[key];
    }

    /** GETTERS */

    /// @notice Returns the daily reset time for questing
    /// @return time - The daily reset time
    function getDailyResetTime() public view returns (uint256) {
        return START + ((((block.timestamp - START) / DAY_IN_SECONDS) + 1) * DAY_IN_SECONDS);
    }

    /// @notice Returns the quest reference struct (with the id of it's questIO) from it's index in the user's selection
    /// @param user - Address of the user
    /// @param index - Index of the quest in their current selection
    /// @return _quest - The QuestReferenceStruct found
    function getUserQuest(address user, uint256 index) external view returns (QuestStruct memory) {
        uint256 userQuestNumber = _userQuestRandomNumber[user];
        require(userQuestNumber > 0, "QC 401 - User has no quests");

        QuestReferenceStruct memory qrs = _unpackQuestByIndex(userQuestNumber, index);

        return QuestStruct(qrs.questId, qrs.element, getQuestIOById(qrs.ioDataId));
    }

    /// @notice returns user's current quests (with the full QuestIO Struct included)
    /// @param user - Address of the user
    /// @return out - The list of user quests
    function getUserQuests(address user) external view returns (QuestStruct[] memory) {

        uint256 userQuestNumber = _userQuestRandomNumber[user];
        require(userQuestNumber > 0, "QC 401 - User has no quests");

        QuestStruct[] memory out = new QuestStruct[](_numberOfQuestsToRoll);

        for (uint256 i; i < out.length; i++) {
            QuestReferenceStruct memory qrs = _unpackQuestByIndex(userQuestNumber, i);
            out[i] = QuestStruct(qrs.questId, qrs.element, getQuestIOById(qrs.ioDataId));
        }
        return out;
    }

    /// @notice returns user's current quests as reference structs
    /// @param user - Address of the user
    /// @return arr - The list of user quests
    function getUserReferenceQuests(address user) external view returns (QuestReferenceStruct[] memory) {

        uint256 userQuestNumber = _userQuestRandomNumber[user];
        require(userQuestNumber > 0, "QC 401 - User has no quests");

        QuestReferenceStruct[] memory quests = new QuestReferenceStruct[](_numberOfQuestsToRoll);

        for (uint i; i < _numberOfQuestsToRoll; i++) {
            quests[i] = _unpackQuestByIndex(userQuestNumber, i);
        }
        return quests;
    }

    /// @notice returns questIOs based on the selected rarity
    /// @param rarity - Rarity level to return
    /// @return ioArray - The list of quests
    function getQuestIOKeysByRarity(uint256 rarity) external view returns (bytes32[] memory) {
        return _rarityIOs[rarity].keyList;
    }

    /// @notice returns a questIO based on it's id
    /// @param id - Id of the questIO
    /// @return io - Corresponding QuestIOStruct
    function getQuestIOById(uint256 id) public view ioExists(id) returns (QuestIOStruct memory io) {
        bytes32 key = bytes32(id);

        uint256 store = _ioStorage[key];

        io.ioId = uint256(uint16(store));
        io.rarity = uint256(uint8(store >> 16));
        io.goldRequirement = uint256(uint64(store >> 24));
        io.itemRequirements = uint256(uint8(store >> 88));
        io.bonus = uint256(uint16(store >> 96));
        io.minGold = uint64(store >> 112);
        io.maxGold = uint64(store >> 176);
        io.items = _itemRewards[key];
    }

    /// @notice returns a questIO based on it's key
    /// @param key - Key of the questIO
    /// @return io - Corresponding QuestIOStruct
    function getQuestIOByKey(bytes32 key) external view ioExists(uint256(key)) returns (QuestIOStruct memory) {
        return getQuestIOById(uint256(key));
    }

    /// @notice View function to calculate the current remaining number of quests for a pet
    /// @dev does not account for the lockouts due to staking or staking lockout
    /// @param petTokenId - The token id of the pet
    /// @return - The number of quests remaining for the pet
    function getQuestsRemainingForPet(uint256 petTokenId) external view returns (uint256) {
        uint48 currentTime = uint48(block.timestamp);
        DailyStruct memory data = _petQuestData[petTokenId];

        if (data.timestamp == 0) {
            return _questAllowance;
        } else if (currentTime > data.timestamp + DAY_IN_SECONDS) {
            return _questAllowance;
        } else {
            return _questAllowance - data.dailyQuests;
        }
    }

    /// @notice Returns whether or not a pet is locked out of questing due to being un-staked in the last 24 hours
    /// @notice or by being currently staked
    /// @param petTokenId - The token id of the pet
    /// @return - Boolean for whether or not the pet can quest
    function isPetAllowedToQuest(uint256 petTokenId) external view returns (bool) {
        return !_adventurersGuild.isPetStaked(petTokenId) && _adventurersGuild.getLastClaimTime(petTokenId) + 86400 < getDailyResetTime();
    }

    /// @notice Returns whether or not a pet is quested today
    /// @notice or by being currently staked
    /// @param petTokenId - the token id of the pet
    /// @return whether or not the pet has quested today
    function hasPetQuestedToday(uint256 petTokenId) external view returns (bool) {
        uint48 currentTime = uint48(block.timestamp);
        DailyStruct memory data = _petQuestData[petTokenId];

        if ( (data.timestamp == 0) || (currentTime > data.timestamp + DAY_IN_SECONDS) ) {
            return false;
        }
        return true;
    }

    /// @notice returns the rarity level set for each rarity, and the maximum roll
    /// @return common - Rarity level of common quests
    /// @return uncommon - Rarity level of uncommon quests
    /// @return rare - Rarity level of rare quests
    /// @return epic - Rarity level of epic quests
    /// @return legendary - Rarity level of legendary quests
    /// @return maxRoll - Max rarity level
    function getRarityRolls() external view returns (
        uint16 common,
        uint16 uncommon,
        uint16 rare,
        uint16 epic,
        uint16 legendary,
        uint16 maxRoll
    ) {
        return (
        _commonRoll,
        _uncommonRoll,
        _rareRoll,
        _epicRoll,
        _legendaryRoll,
        _maxRarityRoll
        );
    }

    /// @notice Get total number of quests
    /// @return count - number of quests
    function getQuestCount() external view returns (uint256) {
        return _questSet.count();
    }

    /// @notice get the list of all quest keys
    /// @return keys - Bytes32 key array
    function getQuestKeys() external view returns (bytes32[] memory) {
        return _questSet.keyList;
    }

    /// @notice Get the number of daily quests for a given pet token Id
    /// @param tokenId - The token id of the pet
    /// @return dailyQuestCount - Array of interactions on a pet
    function getDailyQuestCount(uint256 tokenId) external view returns (uint256) {
        return _petQuestData[tokenId].dailyQuests;
    }

    /** SETTERS */

    /// @notice returns the rarity level set for each rarity, and the maximum roll
    /// @param common - Rarity level of common quests
    /// @param uncommon - Rarity level of uncommon quests
    /// @param rare - Rarity level of rare quests
    /// @param epic - Rarity level of epic quests
    /// @param legendary - Rarity level of legendary quests
    /// @param maxRoll - Max rarity level
    function setRarityRolls(
        uint16 common,
        uint16 uncommon,
        uint16 rare,
        uint16 epic,
        uint16 legendary,
        uint16 maxRoll
    ) external onlyRole(ADMIN_ROLE) {
        require(common < uncommon, "QC 422 - Common must be less rare than uncommon");
        require(uncommon < rare, "QC 423 - Uncommon must be less rare than rare");
        require(rare < epic, "QC 424 - Rare must be less rare than epic");
        require(epic < legendary, "QC 425 - Epic must be less rare than legendary");
        require(legendary <= maxRoll, "QC 426 - Legendary rarity level must be less than or equal to the max rarity roll");

        _commonRoll = common;
        _uncommonRoll = uncommon;
        _rareRoll = rare;
        _epicRoll = epic;
        _legendaryRoll = legendary;
        _maxRarityRoll = maxRoll;

        emit LogSetRarityRolls(common, uncommon, rare, epic, legendary, maxRoll);
    }

    /// @notice Pause or unpause quest rolling
    /// @param paused - New paused status
    function setQuestingPaused(bool paused) external onlyRole(ADMIN_ROLE) {
        _questingPaused = paused;

        emit LogQuestingPaused(paused);
    }

    /// @notice Set the total number of quests guaranteed to be rolled
    /// @dev Ensure number less than 10 to avoid exceeding 256 bits after 10 loops
    /// @dev refer to loop in _getUserQuestsFromQuestNumber
    /// @param number - The number of quests to roll on rollUserQuests
    function setQuestRollNumber(uint8 number) external onlyRole(ADMIN_ROLE) {
        require(number < 10, "QC 427 - Maximum allowed quests to roll exceeded.");

        _numberOfQuestsToRoll = number;

        emit LogChangeNumberOfRolls(uint256(number));
    }

    /// @notice Set the number of quests a pet can go on per day
    /// @param number - The number of quests a pet can go on per day
    function setQuestAllowance(uint8 number) external onlyRole(ADMIN_ROLE) {
        _questAllowance = number;

        emit LogChangeDailyQuestAllowance(uint256(number));
    }

    /// @notice Set the number of common quests guaranteed to be rolled
    /// @param number - The number of common quests
    function setNumberOfCommons(uint8 number) external onlyRole(ADMIN_ROLE) {
        _numberOfCommons = number;

        emit LogSetNumberOfCommons(number);
    }

    /// @notice Set the percentage chance of a quest rolling with no element
    /// @param number - The percentage chance
    function setNoElementPercent(uint16 number) external onlyRole(ADMIN_ROLE) {
        require(number < 100, "QC 428 - The percentage should be less than 100");
        if (number != _noElementPercent) {_noElementPercent = number;}

        emit LogSetNoElementPercent(number);
    }

    /// @notice Set the bonuses given for questing for different pet stages
    /// @dev All values should be basis points 1 = 0.01%, 100 = 1%
    /// @param petStageBonus - Array of bp values, should be 4
    function setPetStageBonus(uint256[] calldata petStageBonus) external onlyRole(ADMIN_ROLE) {
        require(petStageBonus.length == 4, "QC 429 - Pet Stage Bonus length out of bounds");
        _petStageBonus = petStageBonus;

        emit LogSetPetStageBonus(petStageBonus);
    }

    /// @notice Set the gold cost of re-rolling quests
    /// @dev Value should be entered in wei (10^18)
    /// @param cost - Re-roll cost
    function setReRollCost(uint256 cost) external onlyRole(ADMIN_ROLE) {
        _reRollCost = cost;

        emit LogSetReRollCost(cost);
    }

    /// @notice Set the modifier for MILK
    /// @param milkModifier - Modifier as basis points
    function setMilkModifier(uint16 milkModifier) external onlyRole(ADMIN_ROLE) {
        require(milkModifier >= 0 && milkModifier <= 10000, "QC 430 - Milk modifier is out of bounds");
        _milkModifier = milkModifier;

        emit LogSetMilkModifier(milkModifier);
    }

    /// @notice Push new address for the ItemFactory Contract
    /// @param itemFactoryContractAddress - Address of the Item Factory
    function setItemFactoryContractAddress(address itemFactoryContractAddress) external onlyRole(ADMIN_ROLE) {
        _itemFactoryContractAddress = itemFactoryContractAddress;
        _itemFactory = IItemFactory(itemFactoryContractAddress);

        emit LogSetItemFactoryContractAddress(itemFactoryContractAddress);
    }

    /// @notice Push new address for the Adventurers Guild Contract
    /// @param adventurersGuildContractAddress - Address of the new Adventurers Guild
    function setAdventurersGuildContractAddress(address adventurersGuildContractAddress) external onlyRole(ADMIN_ROLE) {
        _adventurersGuildContractAddress = adventurersGuildContractAddress;
        _adventurersGuild = IAdventurersGuild(adventurersGuildContractAddress);

        emit LogSetAdventurersGuildContractAddress(adventurersGuildContractAddress);
    }

    /// @notice Push new address for the Pet Interaction Handler
    /// @param petInteractionHandlerContractAddress - Address of the new Pet Interaction Handler Contract
    function setPetInteractionHandlerContractAddress(address petInteractionHandlerContractAddress) external onlyRole(ADMIN_ROLE) {
        _petInteractionHandlerContractAddress = petInteractionHandlerContractAddress;

        emit LogSetPetInteractionHandlerContractAddress(petInteractionHandlerContractAddress);
    }

    /// @notice Push new address for the treasury Contract
    /// @param treasuryContractAddress - Address of the new treasury Contract
    function setTreasuryContractAddress(address treasuryContractAddress) external onlyRole(ADMIN_ROLE) {
        _treasuryContractAddress = treasuryContractAddress;
        _treasury = ITreasury(treasuryContractAddress);

        emit LogSetTreasuryContractAddress(treasuryContractAddress);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
Hitchens UnorderedKeySet v0.93
Library for managing CRUD operations in dynamic key sets.
https://github.com/rob-Hitchens/UnorderedKeySet
Copyright (c), 2019, Rob Hitchens, the MIT License
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
THIS SOFTWARE IS NOT TESTED OR AUDITED. DO NOT USE FOR PRODUCTION.
*/
// Edited to suit our needs

library CrudKeySetLib {
    struct Set {
        mapping(bytes32 => uint256) keyPointers;
        bytes32[] keyList;
    }

    function insert(Set storage self, bytes32 key) internal {
        require(key != 0x0, "UnorderedKeySet 100 - Key cannot be 0x0");
        require(
            !exists(self, key),
            "UnorderedKeySet 101 - Key already exists in the set."
        );
        self.keyList.push(key);
        self.keyPointers[key] = self.keyList.length - 1;
    }

    function remove(Set storage self, bytes32 key) internal {
        require(
            exists(self, key),
            "UnorderedKeySet 102 - Key does not exist in the set."
        );
        uint last = count(self) - 1;
        uint rowToReplace = self.keyPointers[key];
        if (rowToReplace != last) {
            bytes32 keyToMove = self.keyList[last];
            self.keyPointers[keyToMove] = rowToReplace;
            self.keyList[rowToReplace] = keyToMove;
        }
        delete self.keyPointers[key];
        self.keyList.pop();
    }

    function count(Set storage self) internal view returns (uint256) {
        return (self.keyList.length);
    }

    function exists(Set storage self, bytes32 key)
    internal
    view
    returns (bool)
    {
        if (self.keyList.length == 0) return false;
        return self.keyList[self.keyPointers[key]] == key;
    }

    function keyAtIndex(Set storage self, uint256 index)
    internal
    view
    returns (bytes32)
    {
        return self.keyList[index];
    }

    function nukeSet(Set storage self) internal {
        for (uint256 i; i < self.keyList.length; i++) {
            delete self.keyPointers[self.keyList[i]];
        }
        delete self.keyList;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ISystemChecker.sol";
import "./RolesAndKeys.sol";

contract HSystemChecker is RolesAndKeys {

    ISystemChecker _systemChecker;
    address public _systemCheckerContractAddress;

    constructor(address systemCheckerContractAddress) {
        _systemCheckerContractAddress = systemCheckerContractAddress;
        _systemChecker = ISystemChecker(systemCheckerContractAddress);
    }

    /// @notice Check if an address is a registered user or not
    /// @dev Triggers a require in systemChecker
    modifier isUser(address user) {
        _systemChecker.isUser(user);
        _;
    }

    /// @notice Check that the msg.sender has the desired role
    /// @dev Triggers a require in systemChecker
    modifier onlyRole(bytes32 role) {
        require(_systemChecker.hasRole(role, _msgSender()), "SC: Invalid transaction source");
        _;
    }

    /// @notice Push new address for the SystemChecker Contract
    /// @param systemCheckerContractAddress - address of the System Checker
    function setSystemCheckerContractAddress(address systemCheckerContractAddress) external onlyRole(ADMIN_ROLE) {
        _systemCheckerContractAddress = systemCheckerContractAddress;
        _systemChecker = ISystemChecker(systemCheckerContractAddress);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IItemFactory {
    function burnItem(address owner, uint256 itemTokenId, uint256 amount) external;

    function mintItem(address owner, uint256 itemTokenId, uint256 amount) external;

    function gameSafeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) external;

    function getItemById(uint256 itemTokenId) external returns (bytes32 categoryKey, bytes32 typeKey);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITreasury {
    function balanceOf(address account) external view returns (uint256);

    function withdraw(address user, uint256 amount) external;

    function burn(address owner, uint256 amount) external;

    function mint(address owner, uint256 amount) external;

    function transferFrom(address sender, address recipient, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAdventurersGuild {
    function _lastClaim(uint256 tokenId) external returns (uint256);

    function isPetStaked(uint256 tokenId) external view returns (bool);

    function getLastClaimTime(uint256 tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPetInteractionHandler {
    function getCurrentPetStage(uint256 tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IMulticall.sol';

/// @title Multicall
/// @notice Enables calling multiple methods in a single call to the contract
abstract contract Multicall is IMulticall {
    /**
      * @dev mostly lifted from https://github.com/boringcrypto/BoringSolidity/blob/master/contracts/BoringBatchable.sol
      */
    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";

        assembly {
        // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string));
        // All that remains is the revert string
    }

    /**
      * @inheritdoc IMulticall
      * @dev does a basic multicall to any function on this contract
      */
    function multicall(bytes[] calldata data, bool revertOnFail)
    external payable override
    returns (bytes[] memory returning)
    {
        returning = new bytes[](data.length);
        bool success;
        bytes memory result;
        for (uint256 i = 0; i < data.length; i++) {
            (success, result) = address(this).delegatecall(data[i]);

            if (!success && revertOnFail) {
                revert(_getRevertMsg(result));
            }
            returning[i] = result;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISystemChecker {
    function createNewRole(bytes32 role) external;
    function hasRole(bytes32 role, address account) external returns (bool);
    function hasPermission(bytes32 role, address account) external;
    function isUser(address user) external;
    function getSafeAddress(bytes32 key) external returns (address);
    function grantRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Context.sol';

abstract contract RolesAndKeys is Context {
    // ROLES
    bytes32 constant MASTER_ROLE = keccak256("MASTER_ROLE");
    bytes32 constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 constant GAME_ROLE = keccak256("GAME_ROLE");
    bytes32 constant CONTRACT_ROLE = keccak256("CONTRACT_ROLE");
    bytes32 constant TREASURY_ROLE = keccak256("TREASURY_ROLE");

    // KEYS
    bytes32 constant MARKETPLACE_KEY_BYTES = keccak256("MARKETPLACE");
    bytes32 constant SYSTEM_KEY_BYTES = keccak256("SYSTEM");
    bytes32 constant QUEST_KEY_BYTES = keccak256("QUEST");
    bytes32 constant BATTLE_KEY_BYTES = keccak256("BATTLE");
    bytes32 constant HOUSE_KEY_BYTES = keccak256("HOUSE");
    bytes32 constant QUEST_GUILD_KEY_BYTES = keccak256("QUEST_GUILD");

    // COMMON
    bytes32 constant public PET_BYTES = 0x5065740000000000000000000000000000000000000000000000000000000000;
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
pragma solidity ^0.8.0;

/// @title Multicall interface
/// @notice Enables calling multiple methods in a single call to the contract
interface IMulticall {
    /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
    /// @dev The `msg.value` should not be trusted for any method callable from multicall.
    /// @param data The encoded function data for each of the calls to make to this contract
    /// @return results The results from each of the calls passed in via data
    function multicall(bytes[] calldata data, bool revertOnFail) external payable returns (bytes[] memory results);
}