// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../system/HSystemChecker.sol';
import '../../common/Multicall.sol';
import './IItemFactory.sol';
import '../quests/IActivityOracle.sol';

contract CatGathering is HSystemChecker, Multicall {
    /// @dev Activity name GATHERING for ActivityOracle
    bytes32 constant GATHERING = keccak256('GATHERING');

    /// @dev TokenType CAT for ActivityOracle
    bytes32 constant CAT_TOKEN = keccak256('CAT');

    /// @dev Item factory interface and contract address
    IItemFactory _itemFactory;
    IActivityOracle _activityOracle;

    address public _itemFactoryContractAddress;
    address public _activityOracleContractAddress;

    /// @dev taskName => [item1, item2, item3, item4, item5];
    /// @dev eg. mining => [mallow, rainore, fortisore, bright, crusacuti]
    mapping(bytes32 => uint256[]) public _gatherableItems;

    /// @notice Gatherable items rarity rolls % as BP
    uint16 public _commonRoll = 5440;
    uint16 public _uncommonRoll = 7840;
    uint16 public _rareRoll = 9640;
    uint16 public _epicRoll = 9880;
    uint16 public _legendaryRoll = 10000;

    /// @notice Emitted when a cat(s) successfully does a task
    /// @param account - Address of owner of cats doing the task
    /// @param taskKey - Identifier of task in bytes32
    /// @param catIds - Array of cat ids doing task
    /// @param gatherableItemsMintedCount - Array of count of gatherable items minted
    event LogDoTask(
        address account,
        bytes32 taskKey,
        uint256[] catIds,
        uint8[5] gatherableItemsMintedCount
    );

    /// @notice Emitted when gatherable item for a task is set
    /// @param taskType - Identifier of task in bytes32
    /// @param itemIds - Array of gatherable item token ids
    event LogSetGatherableItems(bytes32 taskType, uint256[] itemIds);

    /// @notice Emitted when the Item Factory contract address is updated
    /// @param itemFactoryContractAddress - Item Factory contract address
    event LogSetItemFactoryAddress(address itemFactoryContractAddress);

    /// @notice Emitted when new Activity oracle address is set
    /// @param activityOracleContractAddress - New address
    event LogSetActivityOracleContractAddress(address activityOracleContractAddress);

    /// @notice Sets the rarity level set for each gatherable items in BP
    /// @param common - Rarity level of common gatherable items
    /// @param uncommon - Rarity level of uncommon gatherable items
    /// @param rare - Rarity level of rare gatherable items
    /// @param epic - Rarity level of epic gatherable items
    /// @param legendary - Rarity level of legendary gatherable items
    event LogSetRarityRolls(
        uint256 common,
        uint256 uncommon,
        uint256 rare,
        uint256 epic,
        uint256 legendary
    );

    constructor(
        address systemCheckerContractAddress,
        address itemFactoryContractAddress,
        address activityOracleContractAddress
    ) HSystemChecker(systemCheckerContractAddress) {
        _itemFactoryContractAddress = itemFactoryContractAddress;
        _itemFactory = IItemFactory(itemFactoryContractAddress);

        _activityOracleContractAddress = activityOracleContractAddress;
        _activityOracle = IActivityOracle(_activityOracleContractAddress);
    }

    /// @notice Check that a task exists
    /// @param taskKey - Identifier for the desired task
    modifier taskExists(bytes32 taskKey) {
        require(_gatherableItems[taskKey].length > 0, 'CG 400 - Task doesnt exist');
        _;
    }

    /// @notice Carry out a task and receive gathering items based on rarity rolled.
    /// @param account - Address of owner of cats doing the task
    /// @param taskKey - Identifier of task in bytes32
    /// @param catIds - Array of cat ids doing task
    /// @param entropy - Backend entropy to remove gaming the system
    function doTask(
        address account,
        bytes32 taskKey,
        uint256[] calldata catIds,
        uint256 entropy
    ) external taskExists(taskKey) onlyRole(GAME_ROLE) {
        // allow a maximum of 10 cats per task call
        require(catIds.length < 11, 'CG 100 - Cat number out of bounds');

        // generate a random number
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, entropy)));

        // retrieve the gatherable items of the requested task
        uint256[] memory gatheringItems = _gatherableItems[taskKey];

        // declare a bytes array with 5 bytes1 elements representing the 5 rarity tiers
        // this array will track the number of times each rarity is rolled
        bytes memory mintCountBytes = new bytes(5);

        // for each cat, roll and determine which gatherable item they will receive based on the rarity tiers
        // increase the count of the bytes value representing the respective rarity tier rolled
        for (uint256 i; i < catIds.length; ) {
            // check if the provided cat can do the activity
            if (_activityOracle.canDoActivity(GATHERING, CAT_TOKEN, catIds[i])) {
                uint256 rn = (randomNumber >>= 2) % 10000;

                // mint token id of specific gathering item based on the rarity rolled
                // bytes conversion steps:
                // retrieve bytes1 value from mintCountBytes array, convert it to uint8 to increase value by 1
                // then convert it back to bytes1 to store back into mintCountBytes array
                if (rn < _commonRoll) {
                    mintCountBytes[0] = bytes1(uint8(mintCountBytes[0]) + uint8(1));
                } else if (rn < _uncommonRoll) {
                    mintCountBytes[1] = bytes1(uint8(mintCountBytes[1]) + uint8(1));
                } else if (rn < _rareRoll) {
                    mintCountBytes[2] = bytes1(uint8(mintCountBytes[2]) + uint8(1));
                } else if (rn < _epicRoll) {
                    mintCountBytes[3] = bytes1(uint8(mintCountBytes[3]) + uint8(1));
                } else {
                    mintCountBytes[4] = bytes1(uint8(mintCountBytes[4]) + uint8(1));
                }

                // update cat's activity in the activity oracle
                _activityOracle.updateTokenActivity(GATHERING, CAT_TOKEN, catIds[i]);
            }

            // save gas as catIds array length is fixed
            unchecked {
                i++;
            }
        }

        // once we have the array of the number of count to mint for each rarity
        // if the value is grater than 0, mint that for the user
        for (uint256 i; i < mintCountBytes.length; ) {
            if (uint8(mintCountBytes[i]) > 0) {
                _itemFactory.mintItem(account, gatheringItems[i], uint8(mintCountBytes[i]));
            }
            unchecked {
                i++;
            }
        }

        emit LogDoTask(
            account,
            taskKey,
            catIds,
            [
                uint8(mintCountBytes[0]),
                uint8(mintCountBytes[1]),
                uint8(mintCountBytes[2]),
                uint8(mintCountBytes[3]),
                uint8(mintCountBytes[4])
            ]
        );
    }

    /* SETTERS */

    ///@notice Set a task and its gatherable items
    ///@param taskKey - Task key in bytes
    ///@param itemIds - Array of gatherable item ids
    function setGatherableItems(bytes32 taskKey, uint256[] calldata itemIds)
        external
        onlyRole(ADMIN_ROLE)
    {
        require(itemIds.length == 5, 'CG 101 - Item list is too long');
        _gatherableItems[taskKey] = itemIds;
        emit LogSetGatherableItems(taskKey, itemIds);
    }

    /// @notice Push new address for the Item Factory Contract
    /// @param itemFactoryContractAddress - Address of the Item Factory
    function setItemFactoryContractAddress(address itemFactoryContractAddress)
        external
        onlyRole(ADMIN_ROLE)
    {
        _itemFactoryContractAddress = itemFactoryContractAddress;
        _itemFactory = IItemFactory(itemFactoryContractAddress);
        emit LogSetItemFactoryAddress(itemFactoryContractAddress);
    }

    /// @notice Push new address for the Activity Oracle
    /// @param activityOracleContractAddress - Address of the new Pet Activity oracle contract
    function setActivityOracleContractAddress(address activityOracleContractAddress)
    external
    onlyRole(ADMIN_ROLE)
    {
        _activityOracleContractAddress = activityOracleContractAddress;
        _activityOracle = IActivityOracle(_activityOracleContractAddress);

        emit LogSetActivityOracleContractAddress(_activityOracleContractAddress);
    }

    /// @notice Sets the rarity level set for each gatherable items in BP
    /// @param common - Rarity level of common gatherable items
    /// @param uncommon - Rarity level of uncommon gatherable items
    /// @param rare - Rarity level of rare gatherable items
    /// @param epic - Rarity level of epic gatherable items
    /// @param legendary - Rarity level of legendary gatherable items
    function setRarityRolls(
        uint16 common,
        uint16 uncommon,
        uint16 rare,
        uint16 epic,
        uint16 legendary
    ) external onlyRole(ADMIN_ROLE) {
        require(common < uncommon, 'CG 102 - Common must be less rare than uncommon');
        require(uncommon < rare, 'CG 103 - Uncommon must be less rare than rare');
        require(rare < epic, 'CG 104 - Rare must be less rare than epic');
        require(epic < legendary, 'CG 105 - Epic must be less rare than legendary');
        require(
            legendary <= 10000,
            'CG 106 - Legendary rarity level must be less than or equal to 10000'
        );

        _commonRoll = common;
        _uncommonRoll = uncommon;
        _rareRoll = rare;
        _epicRoll = epic;
        _legendaryRoll = legendary;

        emit LogSetRarityRolls(common, uncommon, rare, epic, legendary);
    }

    /// @notice Gets list of gatherable item ids for a given task
    /// @param taskName - Task name in bytes32
    /// @return gatherableItems - Gatherable item id array of the given task
    function getGatherableItems(bytes32 taskName) external view returns (uint256[] memory) {
        return _gatherableItems[taskName];
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

    /// @notice Returns the activity id for a given token
    /// @param tokenType - Type of token to check
    /// @param tokenId - Id of token to check
    /// @return uint128 - Activity id
    function getActivityId(bytes32 tokenType, uint256 tokenId) external view returns (uint128);

    /// @notice Returns the daily allowance for an activity type
    /// @param activityType - Name of activity in bytes
    /// @return unit128 - The daily allowed count for an activity
    function getActivityEnergyConsumption(bytes32 activityType) external view returns (uint128);

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