// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../system/HSystemChecker.sol';
import '../milk/ITreasury.sol';
import './IActivityOracle.sol';
import '../items/IPetInteractionHandler.sol';
import '../../common/Multicall.sol';

/// @title MultiQuests
/// @dev MultiQuests contract fulfils the needs of having able to quest with multiple pets in the same time in case you are a holding loads of pets.
contract MultiQuests is Multicall, HSystemChecker {
    //Activity names of MultiQuests for ORACLE
    bytes32 constant QUEST = keccak256('QUEST');
    bytes32 constant STAKING = keccak256('STAKING');
    bytes32 constant UNSTAKING = keccak256('UNSTAKING');
    //TokenType name of MultiQuests for ORACLE
    bytes32 constant PET_TOKEN = keccak256('PET');

    ITreasury _treasury;
    IPetInteractionHandler _petInteractionHandler;
    IActivityOracle _activityOracle;

    address public _treasuryContractAddress;
    address public _petInteractionHandlerContractAddress;
    address public _activityOracleContractAddress;

    /// @dev Minimum gold reward. Threshold shall come from backend stats
    uint64 public _minGold = 18;
    /// @dev Maximum gold reward. Threshold shall come from backend stats
    uint64 public _maxGold = 760;
    /// @dev Minimum number of pets to be sent questing
    uint8 public _minPet = 5;
    /// @dev Maximum number of pets to be sent questing
    uint8 public _maxPet = 10;

    /// @notice Emitted when min - max rewards changing
    /// @param minGold - Min gold reward
    /// @param maxGold - Max gold reward
    event LogMultiQuestMinMaxRewardChanged(uint64 minGold, uint64 maxGold);

    /// @notice Emitted when min - max number of pets -who quest- changing
    /// @param minPet - Min pet count
    /// @param maxPet - Max pet count
    event LogMultiQuestMinMaxPetChanged(uint8 minPet, uint8 maxPet);

    /// @notice Emitted when user completes quest with tokenIds and sum of the gold reward
    /// @param user - User address
    /// @param tokenIds - Pets tokenIds
    /// @param goldAmount - Reward amount
    event LogMultiQuestCompleted(address user, uint256[] tokenIds, uint256 goldAmount);

    /// @notice Emitted when new address is set
    /// @param petInteractionHandlerContractAddress - New address
    event LogSetPetInteractionHandlerContractAddress(address petInteractionHandlerContractAddress);

    /// @notice Emitted when new address is set
    /// @param treasuryContractAddress - New address
    event LogSetTreasuryContractAddress(address treasuryContractAddress);

    /// @notice Emitted when new address is set
    /// @param activityOracleContractAddress - New address
    event LogSetActivityOracleContractAddress(address activityOracleContractAddress);

    constructor(
        address systemCheckerContractAddress,
        address treasuryContractAddress,
        address petInteractionHandlerContractAddress,
        address activityOracleContractAddress
    ) HSystemChecker(systemCheckerContractAddress) {
        _petInteractionHandlerContractAddress = petInteractionHandlerContractAddress;
        _petInteractionHandler = IPetInteractionHandler(petInteractionHandlerContractAddress);

        _treasuryContractAddress = treasuryContractAddress;
        _treasury = ITreasury(treasuryContractAddress);

        _activityOracleContractAddress = activityOracleContractAddress;
        _activityOracle = IActivityOracle(_activityOracleContractAddress);
    }

    /// @notice Complete a multi quest for a user and send the relevant rewards
    /// @dev emits LogMultiQuestCompleted
    /// @dev isUser handled by gold and item factory calls
    /// @param user - Address of the user
    /// @param tokenIds - Ids of the pets
    /// @param entropy - Value to add make the function less deterministic
    function completeMultiQuest(
        address user,
        uint256[] memory tokenIds,
        uint256 entropy
    ) external onlyRole(GAME_ROLE) {
        require(tokenIds.length >= _minPet, 'MQC 102 - Too few pets');
        require(tokenIds.length <= _maxPet, 'MQC 103 - Too many pets');

        uint256 rewardedGold;

        for (uint8 index; index < tokenIds.length; index++) {
            // increments or reverts if pet is busy
            _activityOracle.updateTokenActivity(QUEST, PET_TOKEN, tokenIds[index]);

            // Handle rewards
            uint256 currentPetStage = IPetInteractionHandler(_petInteractionHandlerContractAddress)
                .getCurrentPetStage(tokenIds[index]);
            rewardedGold += _calcMilk(entropy, currentPetStage);
        }

        // give all MILK at once
        if (rewardedGold > 0) {
            _treasury.mint(user, (rewardedGold *= 1 gwei));
        }

        emit LogMultiQuestCompleted(user, tokenIds, rewardedGold);
    }

    /** INTERNAL */

    /// @notice Calculate the gold reward for a quest / pet
    /// @param entropy - Random number uuid to add entropy to random number
    /// @param currentPetStage - Boolean whether to add element bonus or not
    /// @return goldAmount - The calculated gold reward
    function _calcMilk(uint256 entropy, uint256 currentPetStage)
        internal
        view
        returns (uint256 goldAmount)
    {
        goldAmount = _numberBetween(_minGold, _maxGold, entropy);

        // Base reward and appending bonus based on current pet stage
        goldAmount =
            (goldAmount * (10000 + _activityOracle.getPetStageBonus(QUEST)[currentPetStage])) /
            10000;
    }

    /// @notice Generates a random number between a minimum and maximum value
    /// @param min - The minimum value
    /// @param max - The maximum value
    /// @param entropy - A value to add make the function less deterministic
    function _numberBetween(
        uint256 min,
        uint256 max,
        uint256 entropy
    ) internal view returns (uint256) {
        uint256 randomHash = uint256(keccak256(abi.encode(block.timestamp, entropy)));
        return min + (randomHash % (max - min + 1));
    }

    /** SETTERS */

    /// @notice Sets the min/max gold rewards
    /// @param minGold - minimum gold as a reward
    /// @param maxGold - maximum gold as a reward
    function setMinMaxReward(uint64 minGold, uint64 maxGold) external onlyRole(ADMIN_ROLE) {
        require(minGold < maxGold, 'MQC 104 - Min gold reward has to be less than or equal to max');

        _minGold = minGold;
        _maxGold = maxGold;

        emit LogMultiQuestMinMaxRewardChanged(minGold, maxGold);
    }

    /// @notice Sets the min/max pets input numbers
    /// @param minPet - minimum pet as input
    /// @param maxPet - maximum pet as input
    function setMinMaxPetRequirements(uint8 minPet, uint8 maxPet) external onlyRole(ADMIN_ROLE) {
        require(
            minPet < maxPet,
            'MQC 105 - Min pet requirements has to be less than or equal to max'
        );

        _minPet = minPet;
        _maxPet = maxPet;

        emit LogMultiQuestMinMaxPetChanged(minPet, maxPet);
    }

    /// @notice Push new address for the Pet Activity Oracle
    /// @param activityOracleContractAddress - Address of the new Pet Activity oracle contract
    function setActivityOracleContractAddress(address activityOracleContractAddress)
        external
        onlyRole(ADMIN_ROLE)
    {
        _activityOracleContractAddress = activityOracleContractAddress;
        _activityOracle = IActivityOracle(_activityOracleContractAddress);

        emit LogSetActivityOracleContractAddress(_activityOracleContractAddress);
    }

    /// @notice Push new address for the petInteractionHandler Contract
    /// @param petInteractionHandlerContractAddress - Address of the new petInteractionHandler Contract
    function setPetInteractionHandlerAddress(address petInteractionHandlerContractAddress)
        external
        onlyRole(ADMIN_ROLE)
    {
        _petInteractionHandlerContractAddress = petInteractionHandlerContractAddress;
        _petInteractionHandler = IPetInteractionHandler(petInteractionHandlerContractAddress);

        emit LogSetPetInteractionHandlerContractAddress(petInteractionHandlerContractAddress);
    }

    /// @notice Push new address for the treasury Contract
    /// @param treasuryContractAddress - Address of the new treasury Contract
    function setTreasuryContractAddress(address treasuryContractAddress)
        external
        onlyRole(ADMIN_ROLE)
    {
        _treasuryContractAddress = treasuryContractAddress;
        _treasury = ITreasury(treasuryContractAddress);

        emit LogSetTreasuryContractAddress(treasuryContractAddress);
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