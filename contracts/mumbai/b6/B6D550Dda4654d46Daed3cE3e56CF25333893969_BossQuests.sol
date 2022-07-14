// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../system/HSystemChecker.sol';
import '../items/IItemFactory.sol';
import '../milk/ITreasury.sol';
import '../items/IPetInteractionHandler.sol';
import '../../common/Multicall.sol';
import './IActivityOracle.sol';

/// @title BossQuests
/// @dev A boss quest can be completed from a users selection and requirements taken and rewards given.
contract BossQuests is Multicall, HSystemChecker {
    ITreasury _treasury;
    IActivityOracle _activityOracle;
    IItemFactory _itemFactory;
    IPetInteractionHandler _petInteractionHandler;

    address public _treasuryContractAddress;
    address public _activityOracleContractAddress;
    address public _itemFactoryContractAddress;
    address public _petInteractionHandlerContractAddress;

    enum eGildedType {
        NOT_GILDED,
        GILDED,
        GILDED_AND_ANIMATED
    }

    struct BossTable {
        uint32 totalKilled;
        uint64 milkRequired;
        uint128 packedMandatoryItems;
    }

    mapping(uint16 => BossTable) public _bossIdToBossTable;

    bytes32 public constant PET_TOKEN = keccak256('PET');
    bytes32 public constant BOSS_QUEST = keccak256('BOSS_QUEST');

    /// 5% percentage (in BP)
    uint256 public _gildedVersionBP = 500;

    /// 0.1% percentage (in BP)
    uint256 public _gildedAndAnimatedVersionBP = 10;

    /// @notice Emitted when a new Boss Quest is added
    /// @param bossQuestId - Id of the boss quest
    /// @param milkRequired - Milk req. in gwei
    /// @param mandatoryItems - uint16[] of req. item ids
    event LogBossQuestAdded(uint256 bossQuestId, uint64 milkRequired, uint16[] mandatoryItems);

    /// @notice Emitted when a new Boss Quest is edited
    /// @param bossQuestId - Id of the boss quest
    /// @param milkRequired - Milk req. in gwei
    /// @param mandatoryItems - uint16[] of req. item ids
    event LogBossQuestEdited(uint256 bossQuestId, uint64 milkRequired, uint16[] mandatoryItems);

    /// @notice Emitted when a new Boss Quest is deleted
    /// @param bossQuestId - Id of the boss quest
    event LogBossQuestDeleted(uint256 bossQuestId);

    /// @notice Emitted when a user triggers a boss quest
    /// @param quester - Address of user
    /// @param bossQuestId - Id of the boss quest
    /// @param awardedItemId - Id of reward item
    event LogBossQuestInitiated(address quester, uint16 bossQuestId, uint256 awardedItemId);

    /// @notice Emitted when the chance of winning Gilded + Animated item changes
    /// @param basisPoint - New chance as basis points
    event LogSetBossQuestGildedAnimatedChanceChanged(uint256 basisPoint);

    /// @notice Emitted when the chance of winning Gilded item changes
    /// @param basisPoint - New chance as basis points
    event LogSetBossQuestGildedChanceChanged(uint256 basisPoint);

    /// @notice Emitted when the Item Factory contract address is updated
    /// @param itemFactoryContractAddress - Item Factory contract address
    event LogSetItemFactoryContractAddress(address itemFactoryContractAddress);

    /// @notice Emitted when the Pet Interaction Handler contract address is updated
    /// @param petInteractionHandlerContractAddress - Item Factory contract address
    event LogSetPetInteractionHandlerContractAddress(address petInteractionHandlerContractAddress);

    /// @notice Emitted when the Treasury contract address is updated
    /// @param treasuryContractAddress - Item Factory contract address
    event LogSetTreasuryContractAddress(address treasuryContractAddress);

    /// @notice Emitted when new address is set
    /// @param activityOracleContractAddress - New address
    event LogSetActivityOracleContractAddress(address activityOracleContractAddress);

    constructor(
        address systemCheckerContractAddress,
        address itemFactoryContractAddress,
        address treasuryContractAddress,
        address petInteractionHandlerContractAddress,
        address activityOracleContractAddress
    ) HSystemChecker(systemCheckerContractAddress) {
        _itemFactoryContractAddress = itemFactoryContractAddress;
        _itemFactory = IItemFactory(itemFactoryContractAddress);

        _treasuryContractAddress = treasuryContractAddress;
        _treasury = ITreasury(treasuryContractAddress);

        _petInteractionHandlerContractAddress = petInteractionHandlerContractAddress;
        _petInteractionHandler = IPetInteractionHandler(petInteractionHandlerContractAddress);

        _activityOracleContractAddress = activityOracleContractAddress;
        _activityOracle = IActivityOracle(_activityOracleContractAddress);
    }

    /// @notice Check that a boss quest exists
    /// @param bossQuestId - quest id
    modifier bossQuestExists(uint16 bossQuestId) {
        if (_bossIdToBossTable[bossQuestId].milkRequired == 0) {
            revert("BQ 100 - BossQuest doesn't exist");
        }
        _;
    }

    /// @notice Check that a boss quest doesnt exist
    /// @param bossQuestId - quest id
    modifier bossQuestDoesntExist(uint16 bossQuestId) {
        if (_bossIdToBossTable[bossQuestId].milkRequired > 0) {
            revert('BQ 101 - BossQuest already exists');
        }
        _;
    }

    /// @notice Initiates a new boss quest based on its requirements and rewards quester for completing the quest
    /// @dev mandatoryItems array NEEDS to be an array of item ids in ascending numerical order
    /// @dev To save on gas we pack the array into uint256 and compare that to another uint256 - data order matters
    /// @param tokenType - Type of token (Cat/Pet)
    /// @param tokenId - Id of token
    /// @param quester - Address of the initiator
    /// @param bossQuestId - The id of the boss (shall be coming from IF)
    /// @param inputMilk - The amount of MILK to be burnt, value in gwei
    /// @param mandatoryItems - The array of the mandatory item Ids
    /// @param entropy - Entropy for pseudo random numbers
    function initiateBossQuest(
        bytes32 tokenType,
        uint256 tokenId,
        address quester,
        uint16 bossQuestId,
        uint64 inputMilk,
        uint16[] memory mandatoryItems,
        uint256 entropy
    ) external onlyRole(GAME_ROLE) bossQuestExists(bossQuestId) isUser(quester) {
        // check for staked pet
        if (tokenType == PET_TOKEN) {
            // Check for final form pet
            if (_petInteractionHandler.getCurrentPetStage(tokenId) < 3) {
                revert('BQ 102 - Invalid pet status');
            }
        }

        // check token can do activity
        _activityOracle.updateTokenActivity(BOSS_QUEST, tokenType, tokenId);

        BossTable memory bossTable = _bossIdToBossTable[bossQuestId];

        if (bossTable.milkRequired > inputMilk) {
            revert('BQ 103 - Insufficient MILK');
        }

        // pack items to compare
        if (_pack16_128(mandatoryItems) != bossTable.packedMandatoryItems) {
            revert('BQ 104 - Invalid items');
        }

        // convert ether to gwei
        _treasury.burn(quester, uint256(inputMilk) * 1 gwei);

        // burn items
        for (uint256 i; i < mandatoryItems.length; ) {
            _itemFactory.burnItem(quester, mandatoryItems[i], 1);
            unchecked {
                ++i;
            }
        }

        // increment kill count;
        unchecked {
            bossTable.totalKilled++;
        }

        // update the total killed count
        _bossIdToBossTable[bossQuestId].totalKilled = bossTable.totalKilled;

        // roll dice on gilded
        eGildedType guildType = _pickGildedType(entropy);

        /// Mint the final token
        uint256 awardedItemId = bossQuestId + uint256(guildType);
        _itemFactory.mintItem(quester, awardedItemId, 1);

        emit LogBossQuestInitiated(quester, bossQuestId, awardedItemId);
    }

    /// @notice Adds a single boss quest - if not exists yet
    /// @dev Milk amounts should be added in gwei
    /// @param bossQuestId - Desired questId
    /// @param milkRequired - The minimum milk required to start the quest
    /// @param mandatoryItems - Array of item Ids (from IF) that must be sent to start the quest
    function addBossQuest(
        uint16 bossQuestId,
        uint64 milkRequired,
        uint16[] calldata mandatoryItems
    ) external bossQuestDoesntExist(bossQuestId) onlyRole(ADMIN_ROLE) {
        _addBossQuest(bossQuestId, milkRequired, mandatoryItems);

        emit LogBossQuestAdded(bossQuestId, milkRequired, mandatoryItems);
    }

    /// @notice Edits a boss quest
    /// @dev Milk amounts should be added in gwei
    /// @param bossQuestId - Desired questId
    /// @param milkRequired - The minimum milk required to start the quest
    /// @param mandatoryItems - Array of item Ids (from IF) that must be sent to start the quest
    function editBossQuest(
        uint16 bossQuestId,
        uint64 milkRequired,
        uint16[] calldata mandatoryItems
    ) external onlyRole(ADMIN_ROLE) {
        _deleteBossQuest(bossQuestId);
        _addBossQuest(bossQuestId, milkRequired, mandatoryItems);

        emit LogBossQuestEdited(bossQuestId, milkRequired, mandatoryItems);
    }

    /// @notice Delete a single BossQuest
    /// @param bossQuestId - id of boss quest to delete
    function deleteBossQuest(uint16 bossQuestId) external onlyRole(ADMIN_ROLE) {
        _deleteBossQuest(bossQuestId);
    }

    /** GETTERS */

    /// @notice Get the data related to a specific Boss Quest ID
    /// @param bossQuestId - Boss Quest ID to fetch data for
    /// @return totalKilled - Total number of this boss killed
    /// @return milkReq - Milk req. to do quest in gwei
    /// @return mandatoryItems - uint16[] of req. item ids
    function getBossQuest(uint16 bossQuestId)
        external
        view
        bossQuestExists(bossQuestId)
        returns (
            uint32 totalKilled,
            uint64 milkReq,
            uint16[] memory mandatoryItems
        )
    {
        BossTable memory bossTable = _bossIdToBossTable[bossQuestId];

        totalKilled = bossTable.totalKilled;
        milkReq = bossTable.milkRequired;
        mandatoryItems = _unpack16_128(bossTable.packedMandatoryItems);
    }

    /** SETTERS */
    /// @notice Set the percentage chance of a quest rolling with gilded
    /// @param number - The percentage chance in BP
    function setGildedBP(uint256 number) external onlyRole(ADMIN_ROLE) {
        require(number < 10000, 'BQ 105 - The basis points should be less than 10000');
        if (number != _gildedVersionBP) {
            _gildedVersionBP = number;
        }

        emit LogSetBossQuestGildedChanceChanged(number);
    }

    /// @notice Set the percentage chance of a quest rolling with gilded & animated in the same place
    /// @param number - The percentage chance in BP
    function setGildedAndAnimatedBP(uint256 number) external onlyRole(ADMIN_ROLE) {
        require(number < 10000, 'BQ 106 - The basis points should be less than 10000');
        if (number != _gildedAndAnimatedVersionBP) {
            _gildedAndAnimatedVersionBP = number;
        }

        emit LogSetBossQuestGildedAnimatedChanceChanged(number);
    }

    /// @notice Push new address for the pet interaction handler
    /// @param petInteractionHandlerContractAddress - Address of the new pet interaction handler
    function setPetInteractionHandlerContractAddress(address petInteractionHandlerContractAddress)
        external
        onlyRole(ADMIN_ROLE)
    {
        _petInteractionHandlerContractAddress = petInteractionHandlerContractAddress;
        emit LogSetPetInteractionHandlerContractAddress(petInteractionHandlerContractAddress);
    }

    /// @notice Push new address for the Treasury Contract
    /// @param treasuryContractAddress - Address of the Item Factory
    function setTreasuryContractAddress(address treasuryContractAddress)
        external
        onlyRole(ADMIN_ROLE)
    {
        _treasuryContractAddress = treasuryContractAddress;
        emit LogSetTreasuryContractAddress(treasuryContractAddress);
    }

    /// @notice Push new address for the Item Factory Contract
    /// @param itemFactoryContractAddress - Address of the Item Factory
    function setItemFactoryContractAddress(address itemFactoryContractAddress)
        external
        onlyRole(ADMIN_ROLE)
    {
        _itemFactoryContractAddress = itemFactoryContractAddress;
        _itemFactory = IItemFactory(itemFactoryContractAddress);
        emit LogSetItemFactoryContractAddress(itemFactoryContractAddress);
    }

    /// @notice Push new address for the Activity Oracle Contract
    /// @param activityOracleContractAddress - Address of the new treasury Contract
    function setActivityOracleContractAddress(address activityOracleContractAddress)
        external
        onlyRole(ADMIN_ROLE)
    {
        _activityOracleContractAddress = activityOracleContractAddress;
        _activityOracle = IActivityOracle(_activityOracleContractAddress);
        emit LogSetActivityOracleContractAddress(activityOracleContractAddress);
    }

    /** INTERNAL */

    /// @notice Internal function to delete a single Quest
    /// @param bossQuestId - id of boss quest to delete
    function _deleteBossQuest(uint16 bossQuestId) internal bossQuestExists(bossQuestId) {
        delete _bossIdToBossTable[bossQuestId];

        emit LogBossQuestDeleted(bossQuestId);
    }

    /// @notice Picks if the item rewarded is gilded or not
    /// @param randomNum - the random number for choosing the 'boolean'
    /// @return gildType if normal: 0, if gilded: 1, if gilded & animated 3
    function _pickGildedType(uint256 randomNum) internal view returns (eGildedType gildType) {
        uint16 percentBP = uint16(randomNum % 10000);

        if (percentBP < _gildedAndAnimatedVersionBP) {
            // 0.1% chance to have gilded & animated
            return eGildedType.GILDED_AND_ANIMATED;
        } else if (percentBP < (_gildedAndAnimatedVersionBP + _gildedVersionBP)) {
            // less than 5% chance to be gilded
            return eGildedType.GILDED;
        }
    }

    /// @notice Internal method to add a single Quest
    /// @dev Milk amounts should be added in gwei
    /// @param bossQuestId - Desired questId
    /// @param milkRequired - The minimum milk required to start the quest
    /// @param mandatoryItems - Array of item Ids (from IF) that must be sent to start the quest
    function _addBossQuest(
        uint16 bossQuestId,
        uint64 milkRequired,
        uint16[] calldata mandatoryItems
    ) internal {
        // enforce a MILK requirement
        require(milkRequired > 0, 'BQ 107 - MILK can not be 0');
        // enforce a max item req
        require(mandatoryItems.length < 9, 'BQ 108 - Max total item req is 8');

        _bossIdToBossTable[bossQuestId] = BossTable(0, milkRequired, _pack16_128(mandatoryItems));
    }

    /// @notice Pack uint16[] into uint256
    /// @param things - uint16 array to pack
    /// @return result - uint16[] packed into uint256
    function _pack16_128(uint16[] memory things) internal view returns (uint128 result) {
        for (uint256 i; i < things.length; ) {
            result |= uint128(things[i]) << (i * 16);
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Unpack uint256 to a dynamic length uint16[]
    /// @param packedThings - Data packed into uint128
    /// @return result - uint16[] of data
    function _unpack16_128(uint128 packedThings) internal view returns (uint16[] memory result) {
        // Nothing to do so return empty array
        if (packedThings == 0) return result;

        // Need to figure out the length of the result array
        uint256 c;
        uint128 data = packedThings;
        while (data > 0) {
            ++c;
            data >>= 16;
        }

        // Getting this far, we know we have some data to handle
        uint256 i;
        result = new uint16[](c);
        while (i < c) {
            result[i] = uint16(packedThings >> (i * 16));
            unchecked {
                ++i;
            }
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ISystemChecker.sol';
import './RolesAndKeys.sol';

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
        require(_systemChecker.hasRole(role, _msgSender()), 'SC: Invalid transaction source');
        _;
    }

    /// @notice Push new address for the SystemChecker Contract
    /// @param systemCheckerContractAddress - address of the System Checker
    function setSystemCheckerContractAddress(address systemCheckerContractAddress)
        external
        onlyRole(ADMIN_ROLE)
    {
        _systemCheckerContractAddress = systemCheckerContractAddress;
        _systemChecker = ISystemChecker(systemCheckerContractAddress);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IItemFactory {
    function burnItem(
        address owner,
        uint256 itemTokenId,
        uint256 amount
    ) external;

    function mintItem(
        address owner,
        uint256 itemTokenId,
        uint256 amount
    ) external;

    function gameSafeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function getItemById(uint256 itemTokenId)
        external
        returns (bytes32 categoryKey, bytes32 typeKey);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITreasury {
    function balanceOf(address account) external view returns (uint256);

    function withdraw(address user, uint256 amount) external;

    function burn(address owner, uint256 amount) external;

    function mint(address owner, uint256 amount) external;

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external;
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
        if (_returnData.length < 68) return 'Transaction reverted silently';

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
        external
        payable
        override
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

interface IActivityOracle {
    /// @notice Updates the token's activity count. In case an activity has mapped a persistent activity to it
    /// @notice then it also toggles the respective toggle switch.
    /// @dev checks that activityType exists
    /// @dev checks that tokenType exists
    /// @dev checks that midnightTime to log does not exceed block.timestamp to avoid updating past entries
    /// @param activityType - Name of activity in bytes32
    /// @param tokenType - Type of token id
    /// @param tokenId - Token id
    function updateTokenActivity(
        bytes32 activityType,
        bytes32 tokenType,
        uint256 tokenId
    ) external;

    /// @notice Add more energy to token
    /// @param tokenType - Type of token to check
    /// @param tokenId - Id of token to check
    /// @param addEnergy - Energy to add
    function giveEnergy(
        bytes32 tokenType,
        uint256 tokenId,
        uint64 addEnergy
    ) external;

    /// @notice Check if a token can start an activity
    /// @param activityType - Key for requested activity
    /// @param tokenType - Token type as key
    /// @param tokenId - Id of token
    function canDoActivity(
        bytes32 activityType,
        bytes32 tokenType,
        uint256 tokenId
    ) external view returns (bool);

    /// @notice Check if a token can start an activity
    /// @dev Almost same as canDoActvity except the reason return
    /// @param activityType - Key for requested activity
    /// @param tokenType - Token type as key
    /// @param tokenId - Id of token
    function canDoActivityForBackend(
        bytes32 activityType,
        bytes32 tokenType,
        uint256 tokenId
    ) external view returns (bool, uint8);

    /// @notice Returns the energy for a given token
    /// @param tokenType - Type of token to check
    /// @param tokenId - Id of token to check
    /// @return uint64 - Energy
    function getEnergy(bytes32 tokenType, uint256 tokenId) external view returns (uint64);

    /// @notice Returns the timestamp for a given token
    /// @param tokenType - Type of token to check
    /// @param tokenId - Id of token to check
    /// @return uint64 - Timestamp
    function getActivityTimeStamp(bytes32 tokenType, uint256 tokenId)
        external
        view
        returns (uint64);

    /// @notice Returns the energy for a given token as an array
    /// @dev Currently returns an array of 4 uint16 energy levels
    /// @param tokenType - Type of token to check
    /// @param tokenId - Id of token to check
    /// @return result - Array of power levels for energy, comfort, playfulness, social
    function getUnpackedEnergy(bytes32 tokenType, uint256 tokenId)
        external
        view
        returns (uint16[4] memory result);

    /// @notice Returns the last activity id for a given token
    /// @param tokenType - Type of token to check
    /// @param tokenId - Id of token to check
    /// @return uint128 - Activity id
    function getLastActivityId(bytes32 tokenType, uint256 tokenId) external view returns (uint128);

    /// @notice Returns the timestamp for a given token
    /// @param tokenType - Type of token to check
    /// @param tokenId - Id of token to check
    /// @return uint64 - Timestamp
    function getLastActivityTimestamp(bytes32 tokenType, uint256 tokenId)
        external
        view
        returns (uint64);

    /// @notice Returns the activity id for a given token
    /// @param tokenType - Type of token to check
    /// @param tokenId - Id of token to check
    /// @return uint128 - Activity id
    function getActivityId(bytes32 tokenType, uint256 tokenId) external view returns (uint128);

    /// @notice Returns the unpacked energy consumption for an activity type
    /// @param activityType - Name of activity in bytes
    /// @return uint16[4] - Array of power levels for energy, comfort, playfulness, social
    function getActivityEnergyConsumption(bytes32 activityType)
        external
        view
        returns (uint16[4] memory);

    /// @notice Returns if the activity is paused or not
    /// @param activityType - Name of activity in bytes
    /// @return bool - True if paused, false if not
    function isActivityPaused(bytes32 activityType) external view returns (bool);

    /// @notice Returns the daily reset time
    /// @return time - The daily reset time
    function getCurrentMidnight() external view returns (uint256);

    /// @notice Returns the Id of the given activity
    /// @dev 0 means not possible to match cause ID starts from 1
    /// @param activityType - Type of activity (QUEST, STAKE, etc.)
    /// @return id - The daily reset time
    function getIdFromActivity(bytes32 activityType) external view returns (uint128);

    /// @notice Get the bonuses given for questing for different pet stages
    /// @dev All values should be basis points 1 = 0.01%, 100 = 1%
    /// @param activityType - Type of activity (QUEST, STAKE, etc.)
    function getPetStageBonus(bytes32 activityType) external view returns (uint256[] memory);

    /// @notice Boost a pet/cat with respective energies - data coming from Energy Level Contract
    /// @dev Only takes calls from the system
    /// @dev burnItem() handles the revert if user has not enough item balance
    /// @param user - Address of user performing the interaction
    /// @param tokenType - Type of token to check (cat, pet , etc.)
    /// @param tokenId - The tokenId of the pet being interacted with
    /// @param itemTokenIds - Array of ids of the items being used in the interaction in uint256
    function boostEnergy(
        address user,
        bytes32 tokenType,
        uint256 tokenId,
        uint256[] calldata itemTokenIds
    ) external;
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
    bytes32 constant MASTER_ROLE = keccak256('MASTER_ROLE');
    bytes32 constant ADMIN_ROLE = keccak256('ADMIN_ROLE');
    bytes32 constant GAME_ROLE = keccak256('GAME_ROLE');
    bytes32 constant CONTRACT_ROLE = keccak256('CONTRACT_ROLE');
    bytes32 constant TREASURY_ROLE = keccak256('TREASURY_ROLE');

    // KEYS
    bytes32 constant MARKETPLACE_KEY_BYTES = keccak256('MARKETPLACE');
    bytes32 constant SYSTEM_KEY_BYTES = keccak256('SYSTEM');
    bytes32 constant QUEST_KEY_BYTES = keccak256('QUEST');
    bytes32 constant BATTLE_KEY_BYTES = keccak256('BATTLE');
    bytes32 constant HOUSE_KEY_BYTES = keccak256('HOUSE');
    bytes32 constant QUEST_GUILD_KEY_BYTES = keccak256('QUEST_GUILD');

    // COMMON
    bytes32 public constant PET_BYTES =
        0x5065740000000000000000000000000000000000000000000000000000000000;
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
    function multicall(bytes[] calldata data, bool revertOnFail)
        external
        payable
        returns (bytes[] memory results);
}