// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../system/HSystemChecker.sol";
import "../milk/ITreasury.sol";
import "../items/IPetInteractionHandler.sol";
import "../../common/Multicall.sol";
import "./IActivityOracle.sol";

contract AdventurersGuild is HSystemChecker, Multicall {

    //Activity names of MultiQuests for ORACLE
    bytes32 constant QUEST = keccak256("QUEST");
    bytes32 constant STAKING = keccak256("STAKING");
    bytes32 constant UNSTAKING = keccak256("UNSTAKING");
     //TokenType name of MultiQuests for ORACLE
    bytes32 constant PET_TOKEN = keccak256("PET");

    IActivityOracle _activityOracle;

    address public _petInteractionHandlerContractAddress;
    address public _treasuryContractAddress;
    address public _activityOracleContractAddress;

    /// @dev Avg expected $MILK from manual questing * 0.6
    uint256 public _dailyRate = 756 ether;

    uint16 public _milkModifier;

    /// @dev Maps pet token id to the last claim time
    mapping(uint256 => uint256) public _lastClaim;

    /// @notice Emitted when gold is claimed from a completed adventure
    /// @param user - Address of the pet owner
    /// @param gold - Gold amount claimed
    /// @param time - The time to claim up to
    /// @param uuid - UUID for backend reasons
    event LogAdventuringGoldClaimed(address user, uint256 gold, uint256 time, uint256 uuid);

    /// @notice Emitted when a pet is staked in the adventurers guild
    /// @param user - Address of the pet owner
    /// @param tokenIds - Array of pet ids to stake
    event LogPetStaked(address user, uint256[] tokenIds);

    /// @notice Emitted when a pet is unstaked from the adventurers guild
    /// @param user - Address of the pet owner
    /// @param tokenIds - Array of pet ids to stake
    event LogPetUnStaked(address user, uint256[] tokenIds);

    /// @notice Emitted when the daily rate earned by each pet is set
    /// @param rate - The daily rate
    event LogSetDailyRateEvent(uint256 rate);

    /// @notice Emitted when the Treasury contract address is updated
    /// @param petInteractionHandlerContractAddress - Pet Interaction Handler contract address
    event LogSetPetInteractionHandlerContractAddressEvent(address petInteractionHandlerContractAddress);

    /// @notice Emitted when the Treasury contract address is updated
    /// @param treasuryContractAddress - Treasury contract address
    event LogSetTreasuryContractAddressEvent(address treasuryContractAddress);

    /// @notice Emitted when new Activity oracle address is set
    /// @param activityOracleContractAddress - New address
    event LogSetActivityOracleContractAddress(address activityOracleContractAddress);

    event LogSetMilkModifier(uint16 milkModifer);

    constructor(
        address systemCheckerContractAddress,
        address treasuryContractAddress,
        address petInteractionHandlerContractAddress,
        address activityOracleContractAddress
    ) HSystemChecker(systemCheckerContractAddress) {
        _treasuryContractAddress = treasuryContractAddress;
        _petInteractionHandlerContractAddress = petInteractionHandlerContractAddress;

        _activityOracleContractAddress = activityOracleContractAddress;
        _activityOracle = IActivityOracle(_activityOracleContractAddress);
    }

    /// @notice Add a pet to the adventurers guild
    /// @dev Sets the last claim time as the block timestamp
    /// @param owner - Address of the pet owner
    /// @param tokenIds - Array of pet ids to stake
    function stake(
        address owner,
        uint256[] calldata tokenIds
    ) public onlyRole(GAME_ROLE) isUser(owner) {
        IPetInteractionHandler pi = IPetInteractionHandler(_petInteractionHandlerContractAddress);

        for (uint256 i; i < tokenIds.length; i++) {
            // _activityOracle.updateTokenActivity(STAKING, PET_TOKEN, tokenIds[i]);
            // require(_activityOracle.updateTokenActivity(STAKING, PET_TOKEN, tokenIds[i]), "AG 102 - Pet is busy");
            /* require(!_activityOracle.isTokenInAPersistentState(STAKING, PET_TOKEN, tokenIds[i]), "AG 101 - Pet is already staked"); */
            require(pi.getCurrentPetStage(tokenIds[i]) == 3, "AG 103 - Pet must be final form to be staked");
            /* require(!_activityOracle.hasTokenDoneActivity(QUEST, PET_TOKEN, tokenIds[i]), "AG 105 - Pet has already completed quests today"); */

            _activityOracle.updateTokenActivity(STAKING, PET_TOKEN, tokenIds[i]);

            _lastClaim[tokenIds[i]] = block.timestamp;
        }

        emit LogPetStaked(owner, tokenIds);
    }

    /// @notice Remove a pet from the adventurers guild
    /// @dev Calls processClaim with an extra boolean to unstake at the same time
    /// @dev this saves us running an extra loop
    /// @param owner - Owner of the pet
    /// @param tokenIds - The pet ids to unstake
    /// @param uuid - UUID for backend purposes
    function unStake(
        address owner,
        uint256[] calldata tokenIds,
        uint256 uuid
    ) public onlyRole(GAME_ROLE) isUser(owner) {
        _processClaim(owner, tokenIds, block.timestamp, uuid, true);

        emit LogPetUnStaked(owner, tokenIds);
    }

    /// @notice Claim gold for an owner with an array of pet token ids
    /// @dev It is vital that this call from a trusted source as the token ids could
    /// @dev be stacked and someone could claim against a single pet multiple times
    /// @dev we also have no way to verify pet ownership
    /// @dev Rate limited is imposed
    /// @param owner Address to pay gold to
    /// @param ids Array of cat ids being claimed against
    function claim(
        address owner,
        uint256[] calldata ids,
        uint256 uuid
    ) public onlyRole(GAME_ROLE) isUser(owner) {
        _processClaim(owner, ids, block.timestamp, uuid, false);
    }

    /// @notice Calculates the current gold claim amount for staked pets
    /// @param ids - Array of pet ids to calculate for
    /// @param timestamp - Epoch time to calculate the claim amount up to
    function calculateClaim(
        uint256[] calldata ids,
        uint256 timestamp
    ) public view returns (uint256) {
        uint256 currentTime = timestamp;
        if (currentTime == 0) {
            currentTime = block.timestamp;
        }

        uint256 reward;
        // Iterate over each pet and check what rewards are owed
        for (uint256 i; i < ids.length; i++) {
            if (_activityOracle.canDoActivity(UNSTAKING, PET_TOKEN, ids[i])) {
                require(currentTime >= _lastClaim[ids[i]], "AG 400 - Cannot calculate claim for negative time difference");
            	// Reward owner based on fraction of a day
            	reward += (_dailyRate * (currentTime - _lastClaim[ids[i]])) / 86400;
            }
        }

        return reward;
    }

    /// @notice Calculates and processes the current gold claim amount for staked pets
    /// @dev If unstake is true, also removes the pet from the adventurers guild
    /// @param owner - Address of the pet owner
    /// @param ids - Array of pet ids to calculate for
    /// @param currentTime - The time to claim up to
    /// @param uuid - UUID for backend reasons
    /// @param unstake - Boolean to unstake or not
    function _processClaim(
        address owner,
        uint256[] calldata ids,
        uint256 currentTime,
        uint256 uuid,
        bool unstake
    ) internal {
        ITreasury treasury = ITreasury(_treasuryContractAddress);

        uint256 reward = calculateClaim(ids, currentTime);

        // Add modifier
        if (_milkModifier > 0) {
            reward = ((reward * (10000 + _milkModifier)) / 10000);
        }

        // Iterate over each pet and update last claim time
        for (uint256 i; i < ids.length; i++) {
            require(_activityOracle.canDoActivity(UNSTAKING, PET_TOKEN, ids[i]), "AG 102 - Pet is not staked");
            _lastClaim[ids[i]] = currentTime;

            if (unstake) {
                /// @dev unstake pet
                _activityOracle.updateTokenActivity(UNSTAKING, PET_TOKEN, ids[i]);
            }
        }

        treasury.mint(owner, reward);

        emit LogAdventuringGoldClaimed(owner, reward, currentTime, uuid);
    }

    /// @notice Returns whether a pet is staked in the guild or not
    /// @param tokenId - The pet token id
    /// @return isStaked - Boolean result
    function isPetStaked(uint256 tokenId) external view returns (bool isStaked) {
        return  _activityOracle.canDoActivity(UNSTAKING, PET_TOKEN, uint128(tokenId));
    }

    /// @notice Returns the last claim time for a given pet
    /// @param tokenId - The pet token id to check the claim time of
    /// @return time - Epoch time of last claim
    function getLastClaimTime(uint256 tokenId) external view returns (uint256 time) {
        return _lastClaim[tokenId];
    }

    /// @notice Set the daily rate earned by each pet
    /// @dev Rate has 18 decimals, so a daily rate of 5 gold should be entered as 5x10^18
    /// @param rate - The daily rate
    function setDailyRate(uint256 rate) external onlyRole(ADMIN_ROLE) {
        require(rate > 86399, "AG 104 - Daily rate value too low");
        _dailyRate = rate;

        emit LogSetDailyRateEvent(rate);
    }

    /// @notice Set the modifier for MILK
    /// @param milkModifier - Modifier as basis points
    function setMilkModifier(uint16 milkModifier) external onlyRole(ADMIN_ROLE) {
        require(milkModifier >= 0 && milkModifier <= 10000, "AG 105 - Milk modifier is out of bounds");
        _milkModifier = milkModifier;

        emit LogSetMilkModifier(milkModifier);
    }

    /// @notice Push new address for the treasury Contract
    /// @param treasuryContractAddress - Address of the new treasury contract
    function setTreasuryContractAddress(address treasuryContractAddress) external onlyRole(ADMIN_ROLE) {
        _treasuryContractAddress = treasuryContractAddress;

        emit LogSetTreasuryContractAddressEvent(treasuryContractAddress);
    }

    /// @notice Push new address for the pet interaction handler
    /// @param petInteractionHandlerContractAddress - Address of the new pet interaction handler
    function setPetInteractionHandlerContractAddress(address petInteractionHandlerContractAddress) external onlyRole(ADMIN_ROLE) {
        _petInteractionHandlerContractAddress = petInteractionHandlerContractAddress;

        emit LogSetPetInteractionHandlerContractAddressEvent(petInteractionHandlerContractAddress);
    }

    /// @notice Push new address for the Activity Oracle
    /// @param activityOracleContractAddress - Address of the new Pet Activity oracle contract
    function setActivityOracleContractAddress(address activityOracleContractAddress) external onlyRole(ADMIN_ROLE) {
        _activityOracleContractAddress = activityOracleContractAddress;
        _activityOracle = IActivityOracle(_activityOracleContractAddress);

        emit LogSetActivityOracleContractAddress(_activityOracleContractAddress);
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

interface ITreasury {
    function balanceOf(address account) external view returns (uint256);

    function withdraw(address user, uint256 amount) external;

    function burn(address owner, uint256 amount) external;

    function mint(address owner, uint256 amount) external;

    function transferFrom(address sender, address recipient, uint256 amount) external;
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

interface IActivityOracle {

    /// @notice Updates the token's activity count. In case an activity has mapped a persistent activity to it
    /// @notice then it also toggles the respective toggle switch.
    /// @dev checks that activityType exists
    /// @dev checks that tokenType exists
    /// @dev checks that midnightTime to log does not exceed block.timestamp to avoid updating past entries
    /// @param activityType - Name of activity in bytes32
    /// @param tokenType - Type of token id
    /// @param tokenId - Token id
    function updateTokenActivity(bytes32 activityType, bytes32 tokenType, uint256 tokenId) external;

    /// @notice Add more energy to token
    /// @param tokenType - Type of token to check
    /// @param tokenId - Id of token to check
    /// @param addEnergy - Energy to add
    function giveEnergy(bytes32 tokenType, uint256 tokenId, uint64 addEnergy) external;

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
    function getActivityTimeStamp(bytes32 tokenType, uint256 tokenId) external view returns (uint64);

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