// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../../system/HSystemChecker.sol';
import '../../../common/Multicall.sol';
import '../ITreasury.sol';

contract AnnouncerActions is HSystemChecker, Multicall {
    address public _treasuryContractAddress;

    ITreasury _treasury;

    /// @dev one day in seconds
    uint256 public constant DAY_IN_SECONDS = 86400;

    /// @dev price in $MILK for one day announcer
    uint256 public _announcerPrice = 200000 ether;

    /// @dev Token types in bytes
    bytes32 constant CAT_TOKEN = keccak256('CAT');
    bytes32 constant PET_TOKEN = keccak256('PET');

    struct AnnouncerData {
        bytes32 tokenType; // Cat/Pet
        uint256 tokenId; // token id of Cat/Pet
        address announcer; // address of user
    }

    /// @dev Mapping timestamp to announcerData
    mapping(uint256 => uint256) public _announcerData;

    /// @dev Mapping tokenTypeName to tokenTypeId
    mapping(bytes32 => uint256) _tokenTypeToId;

    /// @dev Mapping tokenTypeId to tokenTypeName
    mapping(uint256 => bytes32) _idToTokenType;

    /// @dev tokenType id counter
    uint256 _tokenTypeCounter = 1;

    /// @notice Emitted when set announcer price
    /// @param price - price of announcer
    event LogSetAnnouncerPrice(uint256 price);

    /// @notice Emitted when the Treasury contract address is updated
    /// @param treasuryContractAddress - Treasury contract address
    event LogSetTreasuryContractAddress(address treasuryContractAddress);

    /// @notice Emitted when user buy Announcer
    /// @param buyer - Address of buyer
    /// @param tokenType - token type CAT/PET
    /// @param tokenId - Identifier of token
    /// @param timestamp - UNIX timestamp for announcer's day
    event LogBuyAnnouncer(address buyer, bytes32 tokenType, uint256 tokenId, uint256 timestamp);

    /// @notice Emitted when announcer removed
    /// @param timestamp - UNIX timestamp of announcer to be removed
    event LogRemoveAnnouncer(uint256 timestamp);

    /// @notice Emitted when a new token type is set
    /// @param tokenType - Name of token type in bytes32
    event LogAddTokenType(bytes32 tokenType);

    /// @notice Emitted when a token type is removed
    /// @param tokenType - Name of token type in bytes32
    event LogRemoveTokenType(bytes32 tokenType);

    constructor(address systemCheckerContractAddress, address treasuryContractAddress)
        HSystemChecker(systemCheckerContractAddress)
    {
        /// @dev To be compatible with pets & cats immediately
        _tokenTypeToId[PET_TOKEN] = 1;
        _tokenTypeToId[CAT_TOKEN] = 2;
        _idToTokenType[1] = PET_TOKEN;
        _idToTokenType[2] = CAT_TOKEN;
        _tokenTypeCounter += 2;

        _treasuryContractAddress = treasuryContractAddress;
        _treasury = ITreasury(_treasuryContractAddress);
    }

    /// @notice Check if a token type exists
    /// @param tokenType - Name of token type in bytes32
    modifier tokenTypeExists(bytes32 tokenType) {
        require(_tokenTypeToId[tokenType] > 0, "AA 101 - Token type doesn't exist");
        _;
    }

    /// @notice Check if announcer exists on given date
    /// @param timestamp - UNIX timestamp for given date
    modifier announcerExists(uint256 timestamp) {
        uint256 timekey = getStartOfDay(timestamp);
        require(_announcerData[timekey] != 0, "AA 102 - Announcer doesn't exist");
        _;
    }

    /// @notice Check if announcer exists on today
    modifier currentAnnouncerExists() {
        uint256 timekey = getStartOfDay(block.timestamp);
        require(_announcerData[timekey] != 0, "AA 103 - Announcer on today doesn't exist");
        _;
    }

    /// @notice Check if a token type exists
    /// @param tokenType - Name of token type in bytes32
    modifier tokenTypeNotExists(bytes32 tokenType) {
        require(_tokenTypeToId[tokenType] == 0, 'AA 107 - Token type already exists');
        _;
    }

    /** SETTERS */
    // Designed for admin use only.

    /// @notice Remove Announcer of given day
    /// @param timestamp - UNIX timestamp of Announcer to be deleted
    function removeAnnouncer(uint256 timestamp)
        external
        announcerExists(timestamp)
        onlyRole(ADMIN_ROLE)
    {
        // get starting of day
        uint256 timekey = getStartOfDay(timestamp);

        delete _announcerData[timekey];

        emit LogRemoveAnnouncer(timekey);
    }

    /// @notice Set price of Announcer
    /// @param price - Desired price in wei
    function setAnnouncerPrice(uint256 price) external onlyRole(ADMIN_ROLE) {
        _announcerPrice = price;

        emit LogSetAnnouncerPrice(price);
    }

    /// @notice Sets a new token type
    /// @param tokenType - Name of tokenType in bytes32
    function addTokenType(bytes32 tokenType)
        external
        tokenTypeNotExists(tokenType)
        onlyRole(ADMIN_ROLE)
    {
        _tokenTypeToId[tokenType] = _tokenTypeCounter;
        _idToTokenType[_tokenTypeCounter] = tokenType;

        _tokenTypeCounter++;

        emit LogAddTokenType(tokenType);
    }

    /// @notice Removes an existing token type
    /// @param tokenType - Name of tokenType in bytes32
    function removeTokenType(bytes32 tokenType)
        external
        tokenTypeExists(tokenType)
        onlyRole(ADMIN_ROLE)
    {
        uint256 tokenTypeId = _tokenTypeToId[tokenType];
        delete _idToTokenType[tokenTypeId];
        delete _tokenTypeToId[tokenType];

        emit LogRemoveTokenType(tokenType);
    }

    /// @notice Push new address for the Treasury Contract
    /// @param treasuryContractAddress - Address of the Treasury Contract
    function setTreasuryContractAddress(address treasuryContractAddress)
        external
        onlyRole(ADMIN_ROLE)
    {
        _treasuryContractAddress = treasuryContractAddress;
        _treasury = ITreasury(_treasuryContractAddress);

        emit LogSetTreasuryContractAddress(treasuryContractAddress);
    }

    /** GETTERS */

    /// @notice Get AnnouncerAction
    /// @param timestamp - UNIX timestamp of announcer action
    /// @return announcerData - Announcer Data of given day
    function getAnnouncer(uint256 timestamp)
        external
        view
        announcerExists(timestamp)
        returns (AnnouncerData memory)
    {
        uint256 timekey = getStartOfDay(timestamp);
        (uint256 tokenTypeKey, uint256 tokenId, address user) = _unpack(_announcerData[timekey]);
        return AnnouncerData(_idToTokenType[tokenTypeKey], tokenId, user);
    }

    //// @notice Get Announcer of today
    /// @return announcerData - Announcer Data of current day
    function getCurrentAnnouncer()
        external
        view
        currentAnnouncerExists
        returns (AnnouncerData memory)
    {
        uint256 timekey = getStartOfDay(block.timestamp);
        (uint256 tokenTypeKey, uint256 tokenId, address user) = _unpack(_announcerData[timekey]);
        return AnnouncerData(_idToTokenType[tokenTypeKey], tokenId, user);
    }

    /// @notice buy Announcer of given day
    /// @param buyer - address of buyer
    /// @param tokenType - token type Cat/Pet
    /// @param tokenId - token Id of Cat/Pet
    /// @param timestamp - UNIX timestamp for announcer
    function buyAnnouncer(
        address buyer,
        bytes32 tokenType,
        uint256 tokenId,
        uint256 timestamp
    ) external isUser(buyer) tokenTypeExists(tokenType) onlyRole(GAME_ROLE) {
        require(tokenId < 18446744073709551616, 'AA 104 - tokenId exceeds max of uint64');
        require(timestamp < 18446744073709551616, 'AA 105 - timestamp exceeds max of uint64');

        // get starting of day
        uint256 startTimestamp = getStartOfDay(timestamp);
        require(_announcerData[startTimestamp] == 0, 'AA 106 - Announcer already exists');

        // burn MILK
        _treasury.burn(buyer, _announcerPrice);

        // add announcer data
        _announcerData[startTimestamp] = _pack(_tokenTypeToId[tokenType], tokenId, buyer);

        emit LogBuyAnnouncer(buyer, tokenType, tokenId, startTimestamp);
    }

    /** PUBLIC */

    /// @notice Get starting timestamp of given day
    /// @param timestamp - UNIX timestamp
    /// @return timestamp - UNIX timestamp returning the start of the day
    function getStartOfDay(uint256 timestamp) public pure returns (uint256) {
        return (timestamp / DAY_IN_SECONDS) * DAY_IN_SECONDS;
    }

    /** INTERNAL */

    /// @notice pack announcerData
    /// @param tokenType - Token type index of _tokenTypeSet
    /// @param tokenId - Token Id
    /// @param announcer - Address of announcer
    /// @return packedData - uin256 packed announcer data
    function _pack(
        uint256 tokenType,
        uint256 tokenId,
        address announcer
    ) internal pure returns (uint256 packedData) {
        packedData = uint256(tokenType); // token type index MAX size uint16
        packedData |= uint256(tokenId) << 16; // token id MAX size uint64
        packedData |= uint256(uint160(announcer)) << 80; // address uint160
    }

    /// @notice unpack announcerData
    /// @param packedData - uint256 packed value of announcer data
    /// @return tokenType - Token type index of _tokenTypeSet
    /// @return tokenId - Token Id
    /// @return announcer - Address of announcer
    function _unpack(uint256 packedData)
        internal
        pure
        returns (
            uint256 tokenType,
            uint256 tokenId,
            address announcer
        )
    {
        tokenType = uint256(uint16(packedData)); // token type index MAX size uint16
        tokenId = uint256(uint64(packedData >> 16)); // token id MAX size uint64
        announcer = address(uint160(packedData >> 80)); // address uint160
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