// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../system/HSystemChecker.sol";
import "../milk/ITreasury.sol";
import "../items/IPetInteractionHandler.sol";
import "../../common/Multicall.sol";
import "./IQuestsV4.sol";

contract AdventurersGuild is HSystemChecker, Multicall {

    address public _petInteractionHandlerContractAddress;
    address public _treasuryContractAddress;
    address public _questsContractAddress;

    /// @dev Avg expected $MILK from manual questing * 0.6
    uint256 public _dailyRate = 756 ether;

    uint16 public _milkModifier;

    /// @dev Maps pet token id to the last claim time
    mapping(uint256 => uint256) public _lastClaim;

    /// @dev Map pet token id to a bool if staked or not
    mapping(uint256 => bool) public _staked;

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
    event LogSetQuestsContractAddress(address questsContractAddress);
    event LogSetMilkModifier(uint16 milkModifer);

    constructor(
        address systemCheckerContractAddress,
        address treasuryContractAddress,
        address petInteractionHandlerContractAddress,
        address questsContractAddress
    ) HSystemChecker(systemCheckerContractAddress) {
        _treasuryContractAddress = treasuryContractAddress;
        _petInteractionHandlerContractAddress = petInteractionHandlerContractAddress;
        /// @dev During 'normal' deployment procedure, where script deploys contract from one after the other
        /// @dev the AG contract has to be deployed first, so it might happen that during contract creation the
        /// @dev constructor is called with 0x0 address of quest contract. It has to be set correctly before staking !
        _questsContractAddress = questsContractAddress;
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
        /// @dev If interface address is not set (or address 0x0) the following revert message
        /// @dev comes : "Error: Transaction reverted: function call to a non-contract account"
        IQuestsV4 quests = IQuestsV4(_questsContractAddress);

        for (uint256 i; i < tokenIds.length; i++) {
            require(!_staked[tokenIds[i]], "AG 101 - Pet is already staked");
            require(pi.getCurrentPetStage(tokenIds[i]) == 3, "AG 103 - Pet must be final form to be staked");
            require(!quests.hasPetQuestedToday(tokenIds[i]), "AG 105 - Pet has already completed quests today");

            _lastClaim[tokenIds[i]] = block.timestamp;

            _staked[tokenIds[i]] = true;
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
            if (!_staked[ids[i]]) {
                continue;
            }
            require(currentTime >= _lastClaim[ids[i]], "AG 400 - Cannot calculate claim for negative time difference");

            // Reward owner based on fraction of a day
            reward += (_dailyRate * (currentTime - _lastClaim[ids[i]])) / 86400;
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
            require(_staked[ids[i]], "AG 102 - Pet is not staked");

            _lastClaim[ids[i]] = currentTime;

            if (unstake) {
                _staked[ids[i]] = false;
            }
        }

        treasury.mint(owner, reward);

        emit LogAdventuringGoldClaimed(owner, reward, currentTime, uuid);
    }

    /// @notice Returns whether a pet is staked in the guild or not
    /// @param tokenId - The pet token id
    /// @return isStaked - Boolean result
    function isPetStaked(uint256 tokenId) external view returns (bool isStaked) {
        return _staked[tokenId];
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

    /// @notice Push new address for quest contract address
    /// @param questsContractAddress - address of the new quest contract address
    function setQuestsContractAddress(address questsContractAddress) external onlyRole(ADMIN_ROLE) {
        _questsContractAddress = questsContractAddress;

        emit LogSetQuestsContractAddress(_questsContractAddress);
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

struct QuestReferenceStruct {
    uint256 element;
    uint256 questId;
    uint256 ioDataId;
}

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

struct QuestStruct {
    uint256 questId;
    uint256 element;
    QuestIOStruct ioData;
}

interface IQuestsV4 {
    // GETTERS
    function getRarityRolls() external view returns ( uint16 common, uint16 uncommon, uint16 rare, uint16 epic, uint16 legendary, uint16 maxRoll);
    function getQuestCount() external view returns (uint256);
    function getQuestKeys() external view returns (bytes32[] memory);
    function getDailyQuestCount(uint256 tokenId) external view returns (uint256);
    function hasPetQuestedToday(uint256 petTokenId) external view returns (bool);
    function getUserQuest(address user, uint256 index) external view returns (QuestStruct memory);
    function getUserQuests(address user) external view returns (QuestStruct[] memory);
    function getUserReferenceQuests(address user) external view returns (QuestReferenceStruct[] memory);
    function getQuestIOKeysByRarity(uint256 rarity) external view returns (bytes32[] memory);
    function getQuestIOByKey(bytes32 key) external view returns (QuestIOStruct memory);
    function getQuestsRemainingForPet(uint256 petTokenId) external view returns (uint256);
    function isPetAllowedToQuest(uint256 petTokenId) external view returns (bool);
    
    // SETTERS
    function setRarityRolls(uint16 common, uint16 uncommon, uint16 rare, uint16 epic, uint16 legendary, uint16 maxRoll) external;
    function setQuestingPaused(bool paused) external;
    function setQuestRollNumber(uint8 number) external;
    function setQuestAllowance(uint8 number) external;
    function setNumberOfCommons(uint8 number) external;
    function setNoElementPercent(uint16 number) external;
    function setPetStageBonus(uint256[] calldata petStageBonus) external;
    function setReRollCost(uint256 cost) external;
    function setItemFactoryContractAddress(address itemFactoryContractAddress) external;
    function setAdventurersGuildContractAddress(address adventurersGuildContractAddress) external;
    function setPetInteractionHandlerContractAddress(address petInteractionHandlerContractAddress) external;
    function setTreasuryContractAddress(address treasuryContractAddress) external;
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