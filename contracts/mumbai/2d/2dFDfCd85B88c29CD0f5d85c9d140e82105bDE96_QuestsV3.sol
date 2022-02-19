// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import "../system/CrudKeySet.sol";
import "../system/HSystemChecker.sol";
import "../items/IItemFactory.sol";
import "../milk/ITreasury.sol";
import "./IAdventurersGuild.sol";
import "../items/IPetInteractionHandler.sol";


/// @title QuestsV3
/// @author Adam Goodman - Cool Cats Team
/// @dev Allows the rolling of quests built up of a Quest ID, QuestIO for its rarity, and an element.
/// @dev A quest can be completed from a users selection and requirements taken and rewards given.
contract QuestsV3 is Context, HSystemChecker {

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

    /// @dev This is the expanded data for _userQuests
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
    /// @dev items are appended to the struct in _getQuestIoStruct()
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

    uint256[] public _petStageBonus = [0, 500, 1000, 1000];

    bool public _questingPaused = false;

    uint8 public _questAllowance = 10;

    uint8 public _numberOfQuestsToRoll = 5;
    uint8 public _numberOfCommons = 2;

    /// @notice Quest rarity rolls
    uint16 public _commonRoll = 25;     // 24
    uint16 public _uncommonRoll = 65;   // 24 + 40
    uint16 public _rareRoll = 95;       // 24 + 40 + 30
    uint16 public _epicRoll = 99;       // 24 + 40 + 30  4
    uint16 public _legendaryRoll = 101; // 24 + 40 + 30 + 4 + 2

    uint16 public _maxRarityRoll = 100;

    // Percentage chance for a quest to roll with no elemental affinity
    // % based NOT bp
    uint16 public _noElementPercent = 52;

    // MUST be set as midnight at some date before contract deployment
    // The date incremented by 24 hours (in seconds) at each reset
    uint48 public constant START = 1638662400;
    uint48 public constant DAY_IN_SECONDS = 86400;

    // Value in Wei (10^18)
    uint256 public _reRollCost = 27 ether;

    /// @notice maps rarities to the io of that rarity
    mapping(uint256 => CrudKeySetLib.Set) _rarityIOs;

    /// @notice maps user to their currently available (rolled) quests
    mapping(address => uint256[]) _userQuests;

    /// @dev Maps pet token id to claims per day data
    mapping(uint256 => DailyStruct) _petQuestData;

    mapping(bytes32 => uint256) _ioStorage;
    mapping(bytes32 => uint16[]) _itemRewards;

    event LogQuestCreated(uint256 questId);
    event LogQuestDeleted(uint256 questId);

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
    event LogQuestIODeleted(uint ioId);

    event LogRollQuestEvent(address user, bool reRoll, uint256 entropy, uint256[] quests);
    event LogQuestCompletedEvent(
        address user,
        uint256 questId,
        uint256 element,
        uint256 ioId,
        uint256 petTokenId,
        uint256 goldAmount
    );

    event LogQuestingPausedEvent(bool paused);
    event LogChangeDailyQuestAllowanceEvent(uint256 number);
    event LogChangeNumberOfRollsEvent(uint256 number);

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
    /// @param id of quest to convert to key and check
    modifier questExists(uint256 id) {
        require(_questSet.exists(bytes32(id)), "QC 404 - Quest doesn't exist");
        _;
    }

    /// @notice Check that a questIO exists
    /// @param id Id questIO to convert to key and check
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
    /// @param questId - id to add
    function addQuest(
        uint256 questId
    ) public onlyRole(ADMIN_ROLE) {
        require(questId < 65536, "QC 419 - Quest id exceeds max for uint16");

        // This will revert if key already exists
        _questSet.insert(bytes32(questId));

        // quest created event
        emit LogQuestCreated(questId);
    }

    /// @notice Bulk Add quests
    /// @param questIds - ids to add
    function bulkAddQuests(
        uint256[] calldata questIds
    ) external onlyRole(ADMIN_ROLE) {
        for (uint i; i < questIds.length; i++) {
            if (_questSet.exists(bytes32(questIds[i])) == false) {
                addQuest(questIds[i]);
            }
        }
    }

    /// @notice Delete single quest from the system
    /// @param questId - id to delete
    function deleteQuest(uint256 questId) public onlyRole(ADMIN_ROLE) questExists(questId) {
        // nuke it
        _questSet.remove(bytes32(questId));

        // quest edited event
        emit LogQuestDeleted(questId);
    }

    /// @notice Bulk delete quests from the system
    /// @param questIds - list of ids to delete
    function bulkDeleteQuest(uint256[] calldata questIds) external onlyRole(ADMIN_ROLE) {
        for (uint i; i < questIds.length; i++) {
            deleteQuest(questIds[i]);
        }
    }

    /// @notice Add a single QuestIO
    /// @dev Gold amounts should be added in gwei (1E9)
    /// @dev Bonus is added in basis points, where 1% is 100 bonus
    /// @param id - the id to add (starts at 1)
    /// @param rarity - the rarity of the io
    /// @param goldRequirement - the gold required to complete the quest
    /// @param itemRequirements - the number of items that must be sent to complete the quest
    /// @param bonus - the bonus to add to quest gold rewards (in basis points)
    /// @param minGold - the minimum gold reward
    /// @param maxGold - the maximum gold reward
    /// @param items - the item rewards of the quest
    function addQuestIO(
        uint256 id,
        uint256 rarity,
        uint256 goldRequirement,
        uint256 itemRequirements,
        uint256 bonus,
        uint256 minGold,
        uint256 maxGold,
        uint16[] memory items
    ) public onlyRole(ADMIN_ROLE) rarityLimit(rarity) {
        _addQuestIO(id, rarity, goldRequirement, itemRequirements, bonus, minGold, maxGold, items);

        emit LogQuestIOAdded(id, rarity, goldRequirement, itemRequirements, bonus, minGold, maxGold, items);
    }

    /// @notice Add several QuestIOs
    /// @dev Gold amounts should be added in gwei (1E9)
    /// @dev Bonus is added in basis points, where 1% is 100 bonus
    /// @param ids - the ids to add
    /// @param rarities - the rarities of the respective ios
    /// @param goldRequirements - the gold required to complete the quests
    /// @param itemRequirements - the number of items that must be sent to complete the quests
    /// @param bonuses - the bonuses to add to quest gold rewards (in basis points)
    /// @param minGoldAmounts - the minimum gold rewards
    /// @param maxGoldAmounts - the maximum gold rewards
    /// @param items - the item rewards of the quests
    function bulkAddQuestIO(
        uint256[] memory ids,
        uint256[] memory rarities,
        uint256[] memory goldRequirements,
        uint256[] memory itemRequirements,
        uint256[] memory bonuses,
        uint128[] memory minGoldAmounts,
        uint128[] memory maxGoldAmounts,
        uint16[][] memory items
    ) external onlyRole(ADMIN_ROLE) {
        require(
            ids.length == minGoldAmounts.length
            && ids.length == maxGoldAmounts.length
            && ids.length == items.length
            && ids.length == rarities.length
            && ids.length == bonuses.length
            && ids.length == goldRequirements.length
            && ids.length == itemRequirements.length,
            "QC 408 - Invalid questIO data"
        );

        for (uint i; i < ids.length; i++) {

            if (_ioStorage[bytes32(ids[i])] == 0) {
                addQuestIO(
                    ids[i],
                    rarities[i],
                    goldRequirements[i],
                    itemRequirements[i],
                    bonuses[i],
                    minGoldAmounts[i],
                    maxGoldAmounts[i],
                    items[i]
                );
            }
        }
    }

    /// @notice Edit a QuestIO
    /// @dev Gold amounts should be added in gwei (1E9)
    /// @dev Bonus is added in basis points, where 1% is 100 bonus
    /// @dev ioExists handled by _deleteQuestIO
    /// @param id - the id to add (starts at 1)
    /// @param rarity - the rarity of the io
    /// @param goldRequirement - the gold required to complete the quest
    /// @param itemRequirements - the number of items that must be sent to complete the quest
    /// @param bonus - the bonus to add to quest gold rewards (in basis points)
    /// @param minGold - the minimum gold reward
    /// @param maxGold - the maximum gold reward
    /// @param items - the item rewards of the quest
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
    /// @param id - id of the io to delete
    function deleteQuestIO(
        uint256 id
    ) public onlyRole(ADMIN_ROLE) {
        _deleteQuestIO(id);

        emit LogQuestIODeleted(id);
    }

    /// @notice Bulk delete questIos from the system
    /// @param ids - list of ids to delete
    function bulkDeleteQuestIO(uint256[] calldata ids) external onlyRole(ADMIN_ROLE) {
        for (uint i; i < ids.length; i++) {
            deleteQuestIO(ids[i]);
        }
    }

    /// @notice Roll unique user quests and store them in their respective quest array
    /// @param user - address of the user
    /// @param reRoll - whether to nuke a users quests before rolling
    /// @param entropy - backend entropy to remove gaming the system
    function rollUserQuests(address user, bool reRoll, uint256 entropy) external onlyRole(GAME_ROLE) isUser(user) {
        require(!_questingPaused, "QC 406 - Questing is paused");

        if (reRoll) {_handleReRoll(user);}
        require(_userQuests[user].length == 0, "QC 401 - User already has quests");

        // create list for all quest rarities
        uint256[] memory questIds = new uint256[](_questSet.count());
        uint256[] memory quests = new uint256[](_numberOfQuestsToRoll);

        uint256 store;

        uint256 randomNum = uint256(keccak256(abi.encode(block.timestamp, block.difficulty, entropy)));

        for (uint256 i; i < _numberOfQuestsToRoll; i++) {

            // random number handled in here
            bytes32 questKey = _questSet.keyAtIndex(_pickQuestIndex(randomNum >>= 8, questIds));
            uint256 rarity;
            // pick 2 random common quests to ensure there is always 2 quests a user can complete
            if (i < _numberOfCommons) {
                rarity = uint(Rarity.COMMON);
            } else {

                // i > 1
                uint256 randRarity = (randomNum >>= 8) % _maxRarityRoll;

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
            randomNum >>= 8;

            store = _pickElement(randomNum);                            // element
            store |= uint256(questKey) << 8;                            // questId
            store |= uint256(keys[(randomNum) % keys.length]) << 24;    // ioId

            quests[i] = store;
        }
        _userQuests[user] = quests;

        emit LogRollQuestEvent(user, reRoll, entropy, quests);
    }

    /// @notice Complete a quest for a user and send the relevant rewards
    /// @dev emits QuestCompleted
    /// @dev burnItem checks for user holding items
    /// @dev treasury.burn checks for user having enough gold
    /// @dev isUser handled by gold and item factory calls
    /// @param user - address of the user
    /// @param index - the index of a quest in the user rewards array
    /// @param entropy - a value to add make the function less deterministic
    function completeQuest(
        address user,
        uint256 index,
        uint256 petTokenId,
        uint256[] memory chosenItems,
        uint256 entropy,
        bool rewardBonus
    ) external onlyRole(GAME_ROLE) {
        require(!_adventurersGuild.isPetStaked(petTokenId), "QC 402 - Staked pets cannot quest");
        require(index < _numberOfQuestsToRoll, "QC 403 - User quest is out of bounds");
        require(_adventurersGuild._lastClaim(petTokenId) + 86400 < getDailyResetTime(), "QC 421 - Pet cannot quest in the same daily reset period as it was unstaked");

        // Get quest data from available user quests based on index
        (uint256 element , uint256 questId, uint256 ioDataId) = getUserQuest(user, index);

        require(questId > 0, "QC 400 - User does not have quest in their selection");

        // get current stage of this pet
        uint256 currentPetStage = IPetInteractionHandler(_petInteractionHandlerContractAddress).getCurrentPetStage(petTokenId);

        // Handle the burning and minting and quest requirements and rewards
        QuestIOStruct memory io = _getQuestIoStruct(ioDataId);
        _burnRequirement(io, user, chosenItems);
        uint256 rewardedGold = _handleRewards(io, user, entropy, rewardBonus, currentPetStage);

        // Add to daily quest limit
        _incrementDailyQuestCounter(petTokenId);

        // delete all user quests
        delete _userQuests[user];

        emit LogQuestCompletedEvent(user, questId, element, io.ioId, petTokenId, rewardedGold);
    }

    /** INTERNAL */

    function _handleReRoll(address user) internal {
        // _reRoll cost is entered in wei. No conversion necessary.
        if (_reRollCost > 0) {
            _treasury.burn(user, _reRollCost);
        }
        delete _userQuests[user];
    }

    /// @notice Burn the required gold/items
    /// @param io - QuestIOStruct data
    /// @param user - Address of user to give rewards to
    /// @param chosenItems - Array of item ids to be burned
    function _burnRequirement(QuestIOStruct memory io, address user, uint256[] memory chosenItems) internal {
        // Burn gold requirements
        if(io.goldRequirement > 0) {
            _treasury.burn(user, io.goldRequirement * 1 gwei); // Converted from gwei to wei
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
    /// @return goldAmount - Amount of gold given as a reward
    function _handleRewards(
        QuestIOStruct memory io,
        address user,
        uint256 entropy,
        bool rewardBonus,
        uint256 currentPetStage
    ) internal returns (uint256 goldAmount) {
        if (io.maxGold > 0) {
            // Mint and send gold rewards
            goldAmount = _calculateGold(io, entropy, rewardBonus, currentPetStage);
            _treasury.mint(user, goldAmount);
        }

        // Mint and send item rewards
        // Only allow final form pets to get items
        if(currentPetStage == 3){
            for (uint256 i; i < io.items.length; i++) {
                _itemFactory.mintItem(user, io.items[i], 1);
            }
        }

        return goldAmount;
    }

    /// @notice Calculate the gold reward for a quest
    /// @dev bonus is applied in basis points (1% => bonus = 100)
    /// @param io - QuestIO struct of quest rewards
    /// @param entropy - Random number uuid to add entropy to random number
    /// @param rewardBonus - boolean whether to add element bonus or not
    /// @return goldAmount - the calculated gold reward
    function _calculateGold(
        QuestIOStruct memory io,
        uint256 entropy,
        bool rewardBonus,
        uint256 currentPetStage
    ) internal view returns (uint256 goldAmount) {
        goldAmount = _numberBetween(io.minGold, io.maxGold, entropy);

        // start off with pet stage bonus
        uint256 bonus = _petStageBonus[currentPetStage];
        if(rewardBonus){
            bonus += io.bonus;
        }

        // basis points
        goldAmount = (goldAmount * (10000 + bonus)) / 10000;

        goldAmount *= 1 gwei; // Convert from gwei to wei
    }

    /// @notice Picks element randomly for a quest
    /// @dev % based NOT bp
    /// @param randomNum - the random number for choosing an element
    /// @return uint element id - corresponds to element enum
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
    /// @param randomNum A random number
    /// @param arr - the array to choose from
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
        assembly { mstore(arr, sub(mload(arr), 1)) }

        return index;
    }

    /// @notice Increments the daily quest counter by one for a given pet.
    /// @notice If the daily timer has ticked over, reset the counter for the day and set the new reset time.
    /// @param tokenId - pet token id that has quested
    function _incrementDailyQuestCounter(uint256 tokenId) internal {
        uint48 currentTime = uint48(block.timestamp);

        DailyStruct storage _data = _petQuestData[tokenId];
        if (_data.timestamp == 0) {
            // If timestamp is zero, the user has never interacted with the questing before
            // Initialise their timestamp as the current reset time
            _data.timestamp = START + (((currentTime - START) / DAY_IN_SECONDS) * DAY_IN_SECONDS);

            _data.dailyQuests = 1;
        } else if (currentTime > _data.timestamp + DAY_IN_SECONDS) {
            // Update their timestamp to the current reset time
            _data.timestamp = _data.timestamp + (((currentTime - START) / DAY_IN_SECONDS) * DAY_IN_SECONDS);

            _data.dailyQuests = 1;
        } else {
            require(_data.dailyQuests < _questAllowance, "QC 101 - Pet has exceeded their daily quest allowance");

            _data.dailyQuests++;
        }
    }

    /// @notice generates a random number between a minimum and maximum value
    /// @param min - the minimum value
    /// @param max - the maximum value
    /// @param entropy - a value to add make the function less deterministic
    function _numberBetween(uint256 min, uint256 max, uint256 entropy) internal view returns (uint256) {
        uint256 randomHash = uint256(keccak256(abi.encode(block.timestamp, entropy)));
        return min + randomHash % (max - min + 1);
    }

    /// @notice Returns the unpacked QuestIOStruct from it's uint stored value
    /// @param id - the ioId of the QuestIO
    /// @return _io - the QuestIOStruct unpacked
    function _getQuestIoStruct(uint256 id) internal view returns (QuestIOStruct memory _io) {
        bytes32 key = bytes32(id);

        uint256 store = _ioStorage[key];

        _io.ioId = uint256(uint16(store));
        _io.rarity = uint256(uint8(store >> 16));
        _io.goldRequirement = uint256(uint64(store >> 24));
        _io.itemRequirements = uint256(uint8(store >> 88));
        _io.bonus = uint256(uint16(store >> 96));
        _io.minGold = uint64(store >> 112);
        _io.maxGold = uint64(store >> 176);
        _io.items = _itemRewards[key];
    }

    /// @notice Internal method to add a single QuestIO
    /// @dev Used to avoid stack depth errors.
    /// @dev Gold amounts should be added in gwei (1E9)
    /// @dev Bonus is added in basis points, where 1% is 100 bonus
    /// @param id - the id to add (starts at 1)
    /// @param rarity - the rarity of the io
    /// @param goldRequirement - the gold required to complete the quest
    /// @param itemRequirements - the number of items that must be sent to complete the quest
    /// @param bonus - the bonus to add to quest gold rewards (in basis points)
    /// @param minGold - the minimum gold reward
    /// @param maxGold - the maximum gold reward
    /// @param items - the item rewards of the quest
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

        require(_ioStorage[key] == 0, "QC 420 - QuestIO already exists");
        require(minGold <= maxGold, "QC 411 - The minimum gold reward must be less than or equal to the maximum");

        require(id < 65536, "QC 412 - QuestIO id exceeds max of uint16");
        require(rarity < 256, "QC 413 - Rarity exceeds max of uint8");
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
    /// @param id - id of the io to delete
    function _deleteQuestIO(uint256 id) internal ioExists(id) {
        bytes32 key = bytes32(id);

        _rarityIOs[_getQuestIoStruct(id).rarity].remove(key);

        delete _ioStorage[key];
        delete _itemRewards[key];
    }

    /** GETTERS */

    /// @notice Returns the daily reset time for questing
    /// @return time
    function getDailyResetTime() public view returns (uint256) {
        return START + ((((block.timestamp - START) / DAY_IN_SECONDS) + 1) * DAY_IN_SECONDS);
    }

    /// @notice Returns the quest reference struct (with the id of it's questIO) from it's index in the user's selection
    /// @param user - address of the user
    /// @param index - index of the quest in their current selection
    /// @return _quest - the QuestReferenceStruct found
    function getUserQuest(address user, uint256 index) public view returns (uint256, uint256, uint256) {
        require(index < _numberOfQuestsToRoll, "QC 403 - User quest is out of bounds");

        uint256 store = _userQuests[user][index];
        return (
            uint256(uint8(store)),          // element
            uint256(uint16(store >> 8)),    // questId
            uint256(uint16(store >> 24))    // ioDataId
        );
    }

    /// @notice returns user's current quests as reference structs
    /// @param user - address of the user
    /// @return arr - the list of user quests
    function getUserReferenceQuests(address user) external view returns (QuestReferenceStruct[] memory) {
        QuestReferenceStruct[] memory quests = new QuestReferenceStruct[](_numberOfQuestsToRoll);
        for (uint i; i < _numberOfQuestsToRoll; i++) {
            // convert tuple from getUserQuest into a QuestReferenceStruct and store in array
            (uint256 element, uint256 questId, uint256 ioDataId) = getUserQuest(user, i);
            quests[i] = QuestReferenceStruct(element, questId, ioDataId);
        }
        return quests;
    }

    /// @notice returns user's current quests (with the full QuestIO Struct included)
    /// @param user - address of the user
    /// @return out - the list of user quests
    function getUserQuests(address user) external view returns (QuestStruct[] memory) {
        QuestStruct[] memory out = new QuestStruct[](_numberOfQuestsToRoll);

        for (uint256 i; i < _userQuests[user].length; i++) {
            (uint256 element, uint256 questId, uint256 ioDataId) = getUserQuest(user, i);
            out[i] = QuestStruct(questId, element, _getQuestIoStruct(ioDataId));
        }
        return out;
    }

    /// @notice returns questIOs based on the selected rarity
    /// @param rarity - rarity level to return
    /// @return ioArray - the list of quests
    function getQuestIOKeysByRarity(uint256 rarity) external view returns (bytes32[] memory ioArray) {
        return _rarityIOs[rarity].keyList;
    }

    /// @notice returns a questIO based on it's id
    /// @param id - id of the questIO
    /// @return io - corresponding QuestIOStruct
    function getQuestIOById(uint256 id) external view ioExists(id) returns (QuestIOStruct memory io) {
        return _getQuestIoStruct(id);
    }

    /// @notice returns a questIO based on it's key
    /// @param key - key of the questIO
    /// @return io - corresponding QuestIOStruct
    function getQuestIOByKey(bytes32 key) external view ioExists(uint256(key)) returns (QuestIOStruct memory io) {
        return _getQuestIoStruct(uint256(key));
    }

    /// @notice returns the rarity level set for each rarity, and the maximum roll
    /// @return common - rarity level of common quests
    /// @return uncommon - rarity level of uncommon quests
    /// @return rare - rarity level of rare quests
    /// @return epic - rarity level of epic quests
    /// @return legendary - rarity level of legendary quests
    /// @return maxRoll - max rarity level
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
    /// @return keys - bytes32 key array
    function getQuestKeys() external view returns (bytes32[] memory) {
        return _questSet.keyList;
    }

    /// @notice Get the number of daily quests for a given pet token Id
    /// @param tokenId - the token id of the pet
    /// @return dailyQuestCount - array of interactions on a pet
    function getDailyQuestCount(uint256 tokenId) external view returns (uint dailyQuestCount) {
        return _petQuestData[tokenId].dailyQuests;
    }

    /** SETTERS */

    /// @notice returns the rarity level set for each rarity, and the maximum roll
    /// @param common - rarity level of common quests
    /// @param uncommon - rarity level of uncommon quests
    /// @param rare - rarity level of rare quests
    /// @param epic - rarity level of epic quests
    /// @param legendary - rarity level of legendary quests
    /// @param maxRoll - max rarity level
    function setRarityRolls(
        uint16 common,
        uint16 uncommon,
        uint16 rare,
        uint16 epic,
        uint16 legendary,
        uint16 maxRoll
    ) external onlyRole(ADMIN_ROLE) {
        require(common < uncommon, "Common must be less rare than uncommon");
        require(uncommon < rare, "Uncommon must be less rare than rare");
        require(rare < epic, "Rare must be less rare than epic");
        require(epic < legendary, "Epic must be less rare than legendary");
        require(legendary <= maxRoll, "Legendary rarity level must be less than or equal to the max rarity roll");

        _commonRoll = common;
        _uncommonRoll = uncommon;
        _rareRoll = rare;
        _epicRoll = epic;
        _legendaryRoll = legendary;
        _maxRarityRoll = maxRoll;
    }

    /// @notice Pause or unpause quest rolling
    /// @param paused - new paused status
    function setQuestingPaused(bool paused) external onlyRole(ADMIN_ROLE) {
        _questingPaused = paused;

        emit LogQuestingPausedEvent(paused);
    }

    /// @notice Set the total number of quests guaranteed to be rolled
    /// @param number - the number of quests to roll on rollUserQuests
    function setQuestRollNumber(uint8 number) external onlyRole(ADMIN_ROLE) {
        _numberOfQuestsToRoll = number;

        emit LogChangeNumberOfRollsEvent(uint256(number));
    }

    /// @notice Set the number of quests a pet can go on per day
    /// @param number - the number of quests a pet can go on per day
    function setQuestAllowance(uint8 number) external onlyRole(ADMIN_ROLE) {
        _questAllowance = number;

        emit LogChangeDailyQuestAllowanceEvent(uint256(number));
    }

    /// @notice Set the number of common quests guaranteed to be rolled
    /// @param number - the number of common quests
    function setNumberOfCommons(uint8 number) external onlyRole(ADMIN_ROLE) {
        _numberOfCommons = number;
    }

    /// @notice Set the percentage chance of a quest rolling with no element
    /// @param number - the percentage chance
    function setNoElementPercent(uint16 number) external onlyRole(ADMIN_ROLE) {
        require(number < 100, "The percentage should be less than 100");
        if (number != _noElementPercent) {_noElementPercent = number;}
    }

    /// @notice Set the bonuses given for questing for different pet stages
    /// @dev All values should be basis points 1 = 0.01%, 100 = 1%
    /// @param petStageBonus - array of bp values, should be 4
    function setPetStageBonus(uint256[] calldata petStageBonus) external onlyRole(ADMIN_ROLE) {
        require(petStageBonus.length == 4, "QC - Pet Stage Bonus length out of bounds");
        _petStageBonus = petStageBonus;
    }

    /// @notice Set the gold cost of re-rolling quests
    /// @dev Value should be entered in wei (10^18)
    /// @param cost - re-roll cost
    function setReRollCost(uint256 cost) external onlyRole(ADMIN_ROLE) {
        _reRollCost = cost;
    }

    /// @notice Push new address for the ItemFactory Contract
    /// @param itemFactoryContractAddress - address of the Item Factory
    function setItemFactoryContractAddress(address itemFactoryContractAddress) external onlyRole(ADMIN_ROLE) {
        _itemFactoryContractAddress = itemFactoryContractAddress;
        _itemFactory = IItemFactory(itemFactoryContractAddress);
    }

    /// @notice Push new address for the Adventurers Guild Contract
    /// @param adventurersGuildContractAddress - address of the new Adventurers Guild
    function setAdventurersGuildContractAddress(address adventurersGuildContractAddress) external onlyRole(ADMIN_ROLE) {
        _adventurersGuildContractAddress = adventurersGuildContractAddress;
        _adventurersGuild = IAdventurersGuild(adventurersGuildContractAddress);
    }

    /// @notice Push new address for the Pet Interaction Handler
    /// @param petInteractionHandlerContractAddress - address of the new Pet Interaction Handler Contract
    function setPetInteractionHandlerContractAddress(address petInteractionHandlerContractAddress) external onlyRole(ADMIN_ROLE) {
        _petInteractionHandlerContractAddress = petInteractionHandlerContractAddress;
    }

    /// @notice Push new address for the treasury Contract
    /// @param treasuryContractAddress - address of the new treasury Contract
    function setTreasuryContractAddress(address treasuryContractAddress) external onlyRole(ADMIN_ROLE) {
        _treasuryContractAddress = treasuryContractAddress;
        _treasury = ITreasury(treasuryContractAddress);
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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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
        if(rowToReplace != last) {
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
    function gameSafeTransferFrom( address from, address to, uint256 id, uint256 amount, bytes memory data ) external;
    function getItemById(uint256 itemTokenId) external returns(bytes32 categoryKey, bytes32 typeKey);
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

    function isPetStaked(uint256 tokenId) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPetInteractionHandler {
    function getCurrentPetStage(uint256 tokenId) external view returns (uint256);
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