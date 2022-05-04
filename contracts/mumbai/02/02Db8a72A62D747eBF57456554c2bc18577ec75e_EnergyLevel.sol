// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../system/HSystemChecker.sol";
import "../../common/Multicall.sol";

contract EnergyLevel is Multicall, HSystemChecker {

    uint256 CURRENT_MAX_ENERGY_COUNT = 4;

    /// @notice Mapping an item's token id to its energy level
    /// @dev Used as a reference to obtain a specific item token id's energy levels
    /// @dev Can track up to a maximum of 4 types of parameters
    mapping(uint256 => uint64) public _itemEnergy;

    /// @notice Mapping of a token type to and its maximum energy level
    /// @dev Used as reference to replenish a token's energy level every midnight
    mapping(bytes32 => uint64) public _maxEnergy;

    /// @notice Emitted when the energy level of an item is set
    /// @param itemTokenId - Item token id being set
    /// @param energyLevels - Energy levels being set
    event LogSetItemEnergyLevel(uint256 itemTokenId, uint16[] energyLevels);

    /// @notice Emitted when the max energy levels for a token type is set
    /// @param tokenType - Token type being set in bytes
    /// @param maxEnergyLevels - Max energy level being set
    event LogSetTokenMaxEnergy(bytes32 tokenType, uint16[] maxEnergyLevels);

    /// @notice Emitted when the max energy count for a token type is set
    /// @notice Set the current max energy count
    /// @param newMaxEnergyCount - New max energy count to set
    event LogSetTokenMaxEnergyCount(uint256 newMaxEnergyCount);

    constructor(address systemCheckerContractAddress)  HSystemChecker(systemCheckerContractAddress) {}

    /* SETTERS */

    /// @notice Set an item's energy level
    /// @param itemTokenId - Item token id being set (item's id from ItemFactory)
    /// @param energyLevels - Array of energy level of an an item
    function setItemEnergyLevel(uint256 itemTokenId, uint16[] calldata energyLevels) external onlyRole(ADMIN_ROLE) {
        require (energyLevels.length == CURRENT_MAX_ENERGY_COUNT, "EL: Exceeded maximum allowable energy count");
        // @dev Store the packed energy levels into the mapping
        _itemEnergy[itemTokenId] = pack(energyLevels);

        emit LogSetItemEnergyLevel(itemTokenId, energyLevels);
    }

    /// @notice Set an item's max energy level
    /// @param tokenType - Token type being set
    /// @param maxEnergy - Max energy level for the token type
    function setTokenMaxEnergy(bytes32 tokenType, uint16[] calldata maxEnergy) external onlyRole(ADMIN_ROLE) {
        require (maxEnergy.length == CURRENT_MAX_ENERGY_COUNT, "EL: Exceeded maximum allowable energy count");

        _maxEnergy[tokenType] = pack(maxEnergy);

        emit LogSetTokenMaxEnergy(tokenType, maxEnergy);
    }

    /// @notice Set the current max energy count
    /// @param newMaxEnergyCount - New max energy count to set
    function setTokenMaxEnergyCount(uint newMaxEnergyCount) external onlyRole(ADMIN_ROLE) {
        // current system only suppoers maximum of 4 paramameters
        require (newMaxEnergyCount < 5, "EL: Exceeded maximum allowable energy count");

        CURRENT_MAX_ENERGY_COUNT = newMaxEnergyCount;

        emit LogSetTokenMaxEnergyCount(newMaxEnergyCount);
    }

    /* GETTERS */

    /// @notice Gets an item's energy levels by its token id
    /// @param itemTokenId - Item token id requested (item's id from ItemFactory)
    function getPackedEnergiesByItem(uint256 itemTokenId) external view returns (uint64) {
        return _itemEnergy[itemTokenId];
    }

    /// @notice Gets an item's energy levels by its token id
    /// @param tokenType - Token type being requested in bytes
    function getPackedMaxEnergy(bytes32 tokenType) external view returns (uint64) {
        return _maxEnergy[tokenType];
    }

    /// @notice Gets an item's energy levels by its token id
    /// @param itemTokenId - Item token id requested
    /// @return energyLevel1 - Energy Level 1 in uint16
    /// @return energyLevel2 - Energy Level 2 in uint16
    /// @return energyLevel3 - Energy Level 3 in uint16
    /// @return energyLevel4 - Energy Level 4 in uint16
    function getUnpackedEnergiesByItem(uint256 itemTokenId) external view returns (
        uint16 energyLevel1, 
        uint16 energyLevel2, 
        uint16 energyLevel3, 
        uint16 energyLevel4
    ) {
        return unpack(_itemEnergy[itemTokenId]);
    }

    /// @notice Gets an item's energy levels by its token id
    /// @param tokenType - Token type being requested in bytes
    /// @return energyLevel1 - Energy Level 1 in uint16
    /// @return energyLevel2 - Energy Level 2 in uint16
    /// @return energyLevel3 - Energy Level 3 in uint16
    /// @return energyLevel4 - Energy Level 4 in uint16
    function getUnpackedMaxEnergy(bytes32 tokenType) external view returns (
        uint16 energyLevel1, 
        uint16 energyLevel2, 
        uint16 energyLevel3, 
        uint16 energyLevel4
    ) {
        return unpack(_maxEnergy[tokenType]);
    }

    /* INTERNAL FUNCTIONS */

    /// @notice Pack token activity data
    /// @param energyLevelsArray - Energy levels in an array [energy1, energy2, energy3, energy4]
    /// @return packedEnergyLevels
    function pack(
        uint16[] calldata energyLevelsArray
    ) internal pure returns(uint64 packedEnergyLevels){
        uint64 packedData = uint64(energyLevelsArray[0]);
        packedData |= uint64(energyLevelsArray[1]) << 16;
        packedData |= uint64(energyLevelsArray[2]) << 32;
        packedData |= uint64(energyLevelsArray[3]) << 48;

        return packedData;
    }

    /// @notice Unpack token activity data
    /// @param packedEnergyLevel - Packed energy level in uint64
    /// @return energyLevel1 - Energy Level 1 in uint16
    /// @return energyLevel2 - Energy Level 2 in uint16
    /// @return energyLevel3 - Energy Level 3 in uint16
    /// @return energyLevel4 - Energy Level 4 in uint16
    function unpack(uint64 packedEnergyLevel) internal pure returns (
        uint16 energyLevel1, 
        uint16 energyLevel2, 
        uint16 energyLevel3, 
        uint16 energyLevel4
    ) {
        return (
            uint16(packedEnergyLevel), // energy: represents 4 diff energy types X 16 uint value
            uint16(packedEnergyLevel >> 16),
            uint16(packedEnergyLevel >> 32), // timestamp
            uint16(packedEnergyLevel >> 48) // activity id
        );
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