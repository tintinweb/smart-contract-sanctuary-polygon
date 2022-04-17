// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../system/RolesAndKeys.sol";
import "../system/HSystemChecker.sol";
import "./IItemFactory.sol";
import "../../common/Multicall.sol";

/// @title Pet Interaction Handler
/// @author Adam Goodman - Cool Cats Team
/// @dev Takes item interaction calls with pets from the system address
/// @dev Logs interactions and emits event to be listened to by back end.
contract PetInteractionHandler is HSystemChecker, Multicall {
    /// @dev PET interactions are
    // egg = 0
    // stage1 = 1
    // stage2 = 2
    // final form = 3

    address public _itemFactoryContractAddress;

    struct InteractionStruct {
        address from;
        uint48 itemTokenId;
        uint48 time;
    }

    struct DailyInteractionStruct {
        uint8 dailyInteractionCount;
        uint48 timestamp;
    }

    /// @dev the interaction limit are cumulative
    uint16 public _blobOneInteractions = 10;
    uint16 public _blobTwoInteractions = 25;
    uint16 public _finalFormInteractions = 50;

    /// @dev MUST be set as midnight at some date before contract deployment
    /// @dev The date incremented by 24 hours (in seconds) at each reset
    uint48 public constant START = 1638662400;
    uint48 public constant DAY_IN_SECONDS = 86400;

    /// @dev maximum allowable pet interactions a day
    uint8 public _dailyInteractionAllowance = 5;

    /// @dev Maps pet token Id to the list of past interactions.
    mapping(uint256 => InteractionStruct[]) public _petInteractions;

    /// @dev Maps pet token Id their daily daily interaction data.
    mapping(uint256 => DailyInteractionStruct) public _petInteractionData;

    /// @dev Map pet token Id to current stage
    mapping(uint256 => uint256) _currentPetStage;

    /// @notice Event that fires to tell the system an interaction has occurred
    /// @param from - Address of user performing the interaction
    /// @param petTokenId - The tokenId of the pet being interacted with
    /// @param itemTokenId - uint256 id of the item being used in the interaction
    event LogPetInteractionEvent(address from, uint256 petTokenId, uint256 itemTokenId);

    /// @notice Event that fires to tell the system a pet has reached its blob one stage
    /// @param from - Address of user performing the interaction
    /// @param petTokenId - The tokenId of the pet being interacted with
    event LogPetReachBlobOneEvent(address from, uint256 petTokenId);

    /// @notice Event that fires to tell the system a pet has reached its blob two stage
    /// @param from - Address of user performing the interaction
    /// @param petTokenId - The tokenId of the pet being interacted with
    event LogPetReachBlobTwoEvent(address from, uint256 petTokenId);

    /// @notice Event that fires to tell the system a pet has reached its final interaction
    /// @param from - Address of user performing the interaction
    /// @param petTokenId - The tokenId of the pet being interacted with
    event LogPetReachFinalFormEvent(address from, uint256 petTokenId);

    /// @notice Event that fires to tell the system that the daily allowed interactions has been updated
    /// @param dailyInteractionAllowance - The number of daily interactions for a pet
    event LogChangeDailyInteractionAllowanceEvent(uint256 dailyInteractionAllowance);

    /// @notice Event that fires to tell the system that a new stage interactions are set
    /// @param blobOneInteractions - New required number of interactions to reach blob one stage
    /// @param blobTwoInteractions - New required number of interactions to reach blob Two stage
    /// @param finalFormInteractions - New required number of interactions to reach final form
    event LogSetStageInteractionsEvent(
        uint16 blobOneInteractions,
        uint16 blobTwoInteractions,
        uint16 finalFormInteractions
    );

    /// @notice Emitted when the Treasury contract address is updated
    /// @param itemFactoryContractAddress - Item Factory contract address
    event LogSetItemFactoryContractAddressEvent(address itemFactoryContractAddress);

    constructor(address itemFactoryContractAddress, address systemCheckerContractAddress) HSystemChecker(systemCheckerContractAddress) {
        _itemFactoryContractAddress = itemFactoryContractAddress;
    }

    /// @notice Logs a new interaction for a given tokenId
    /// @dev Only takes calls from the system
    /// @dev burnItem() handles isUser()
    /// @param from - Address of user performing the interaction
    /// @param petTokenId - The tokenId of the pet being interacted with
    /// @param itemTokenId - Id of the item being used in the interaction in uint256
    function interact(
        address from,
        uint256 petTokenId,
        uint256 itemTokenId
    ) external onlyRole(GAME_ROLE) {
        IItemFactory itemFactory = IItemFactory(_itemFactoryContractAddress);

        // make sure only pet items are given to pets
        (bytes32 categoryKey,) = itemFactory.getItemById(itemTokenId);
        require(categoryKey == PET_BYTES, "PI 403 - Not a pet item");
        require(_petInteractions[petTokenId].length < _finalFormInteractions, "PI 100 - Pet has reached final form");

        // Save interaction data
        _petInteractions[petTokenId].push(InteractionStruct(from, uint48(itemTokenId), uint48(block.timestamp)));

        // Burn permissions is checked in ItemFactory
        itemFactory.burnItem(from, itemTokenId, 1);

        _incrementDailyInteractionCount(petTokenId);

        emit LogPetInteractionEvent(from, petTokenId, itemTokenId);

        if (_petInteractions[petTokenId].length == _blobOneInteractions) {
            _currentPetStage[petTokenId] = 1;
            emit LogPetReachBlobOneEvent(from, petTokenId);
        } else if (_petInteractions[petTokenId].length == _blobTwoInteractions) {
            _currentPetStage[petTokenId] = 2;
            emit LogPetReachBlobTwoEvent(from, petTokenId);
        } else if (_petInteractions[petTokenId].length == _finalFormInteractions) {
            _currentPetStage[petTokenId] = 3;
            emit LogPetReachFinalFormEvent(from, petTokenId);
        }
    }

    /// @notice Increments the daily interactions by one for a given pet.
    /// @dev If the daily timer has ticked over, reset the counter for the day and set the new reset time.
    /// @param tokenId - Pet token id that has interacted
    function _incrementDailyInteractionCount(uint256 tokenId) internal {
        uint48 currentTime = uint48(block.timestamp);

        DailyInteractionStruct memory data = _petInteractionData[tokenId];

        // Pet has no timestamp, so we set it for the first time
        if (data.timestamp == 0) {
            // If timestamp is zero, the user has never interacted with their pets before
            // Initialise their timestamp as the current reset time
            data.timestamp = START + (((currentTime - START) / DAY_IN_SECONDS) * DAY_IN_SECONDS);
            data.dailyInteractionCount = 1;
        }

        // Current time is great than the pet timestamp + a whole day.
        // This means the interaction counter can be reset as it is a new day
        else if (currentTime > data.timestamp + DAY_IN_SECONDS) {
            // Update their timestamp to the current reset time
            data.timestamp = data.timestamp + (((currentTime - data.timestamp) / DAY_IN_SECONDS) * DAY_IN_SECONDS);
            data.dailyInteractionCount = 1;
        }

        // Pet is interacting within a single day so we increment the quest counter to reflect the usage
        // of the daily allowance
        else {
            require(data.dailyInteractionCount < _dailyInteractionAllowance, "PI 101 - Pet has exceeded their daily interaction allowance");
            data.dailyInteractionCount++;
        }

        // Save data to storage
        _petInteractionData[tokenId] = data;
    }

    /// @notice Get the interactions for a given pet token Id
    /// @param tokenId - The token id of the pet
    /// @return interactions - Array of interactions on a pet
    function getInteractions(uint256 tokenId) external view returns (InteractionStruct[] memory) {
        return _petInteractions[tokenId];
    }

    /// @notice Get the number of daily interactions for a given pet token Id
    /// @param tokenId - The token id of the pet
    /// @return dailyInteractionCount - Array of interactions on a pet
    function getDailyInteractionCount(uint256 tokenId) external view returns (uint256 dailyInteractionCount) {
        return _petInteractionData[tokenId].dailyInteractionCount;
    }

    /// @notice Returns the daily reset time for interactions
    /// @return time
    function getDailyResetTime() external view returns (uint256) {
        return START + ((((block.timestamp - START) / DAY_IN_SECONDS) + 1) * DAY_IN_SECONDS);
    }

    /// @notice Get current stage of pet
    /// @param tokenId - The token id of the pet
    /// @return uint256 - Current stage of pet
    function getCurrentPetStage(uint256 tokenId) external view returns (uint256) {
        return _currentPetStage[tokenId];
    }

    /// @notice Set interactions for each stage
    /// @dev Ideally this should only be used for testing
    /// @param blobOneInteractions - New required number of interactions to reach blob one stage
    /// @param blobTwoInteractions - New required number of interactions to reach blob Two stage
    /// @param finalFormInteractions - New required number of interactions to reach final form
    function setStageInteractions(
        uint16 blobOneInteractions,
        uint16 blobTwoInteractions,
        uint16 finalFormInteractions
    ) external onlyRole(ADMIN_ROLE) {
        require(blobOneInteractions < blobTwoInteractions, "PI 400 - Blob one must come before blob two");
        require(blobOneInteractions < finalFormInteractions, "PI 401 - Blob one must come before final form");
        require(blobTwoInteractions < finalFormInteractions, "PI 402 - Blob two must come before final form");

        _blobOneInteractions = blobOneInteractions;
        _blobTwoInteractions = blobTwoInteractions;
        _finalFormInteractions = finalFormInteractions;

        emit LogSetStageInteractionsEvent(blobOneInteractions, blobTwoInteractions, finalFormInteractions);
    }

    /// @notice Set the max number of daily interactions for a pet
    /// @param number - The number of daily interactions for a pet
    function setDailyInteractionAllowance(uint8 number) external onlyRole(ADMIN_ROLE) {
        _dailyInteractionAllowance = number;

        emit LogChangeDailyInteractionAllowanceEvent(uint256(number));
    }

    /// @notice Push new address for the Item Factory Contract
    /// @param itemFactoryContractAddress - Address of the Item Factory
    function setItemFactoryContractAddress(address itemFactoryContractAddress) external onlyRole(ADMIN_ROLE) {
        _itemFactoryContractAddress = itemFactoryContractAddress;

        emit LogSetItemFactoryContractAddressEvent(itemFactoryContractAddress);
    }
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

/// @title Multicall interface
/// @notice Enables calling multiple methods in a single call to the contract
interface IMulticall {
    /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
    /// @dev The `msg.value` should not be trusted for any method callable from multicall.
    /// @param data The encoded function data for each of the calls to make to this contract
    /// @return results The results from each of the calls passed in via data
    function multicall(bytes[] calldata data, bool revertOnFail) external payable returns (bytes[] memory results);
}