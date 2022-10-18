// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../access/WorldAccess.sol";

contract EventCheckinLog is WorldAccess {
    struct EventCheckinLogRecord {
        address playerWallet;
        uint256 eventDefinitionId;
        uint256 timestamp;
    }

    uint256 public checkinCount;

    // key: eventDefinitionId, value: count
    mapping(uint256 => uint256) public checkinCountsPerEvent;

    // key: Player Wallet, value: (key: eventDefinitionId, value: count)
    mapping(address => mapping(uint256 => uint256)) public checkinCountsPerPlayer;

    // key: Player Wallet, value: (key: eventDefinitionId, value: timestamp(sec))
    mapping(address => mapping(uint256 => uint256)) public checkinTimeStampPerPlayer;

    // key: logId, value: (key: eventDefinitionId, value: timestamp(sec))
    mapping(uint256 => EventCheckinLogRecord) public logs;

    constructor(uint256 worldId, address gameAddress)
    WorldAccess(worldId, gameAddress) {
    }

    function log(address playerWallet, uint256 eventDefinitionId) public onlyGame {
        checkinCount++;
        checkinCountsPerEvent[eventDefinitionId]++;
        checkinCountsPerPlayer[playerWallet][eventDefinitionId]++;
        checkinTimeStampPerPlayer[playerWallet][eventDefinitionId] = block.timestamp;

        logs[checkinCount] = EventCheckinLogRecord(
            playerWallet,
            eventDefinitionId,
            block.timestamp
        );
    }

    function getLogs(uint256[] calldata logIds) public view returns(EventCheckinLogRecord[] memory) {
        EventCheckinLogRecord[] memory records = new EventCheckinLogRecord[](logIds.length);
        for (uint256 i; i < logIds.length; i++) {
            EventCheckinLogRecord memory record = logs[logIds[i]];
            records[i] = EventCheckinLogRecord(
                record.playerWallet,
                record.eventDefinitionId,
                record.timestamp
            );
        }

        return records;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IGameAccess.sol";
import "./AccessControl.sol";

contract WorldAccess is Ownable, AccessControl {
    uint256 internal _worldId;

    constructor(uint256 worldId, address gameAddress)
    AccessControl(gameAddress) {
        _worldId = worldId;
    }

    modifier onlyGame() {
        bool isInternal = checkAccess(msg.sender, _gameAccess.getInterfaceAddresses(_worldId));
        bool isGameOwner = checkAccess(msg.sender, _gameAccess.getWorldOwnerAddresses(_worldId));
        bool isOwner = msg.sender == owner();
        bool isGame = msg.sender == address(_gameAccess);

        require(isInternal || isGameOwner || isOwner || isGame, "WorldAccess: caller is not Game/Owner");
        _;
    }

    modifier onlyWorldAdmin() {
        bool isWorldAdmin = checkAccess(msg.sender, _gameAccess.getWorldAdminAddresses(_worldId));
        bool isGameOwner = checkAccess(msg.sender, _gameAccess.getWorldOwnerAddresses(_worldId));
        bool isOwner = msg.sender == owner();
        bool isGame = msg.sender == address(_gameAccess);

        require(isWorldAdmin || isGameOwner || isOwner || isGame, "WorldAccess: caller is not WorldAdmin");
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IGameAccess {
    function getInterfaceAddresses(uint256 worldId) external view returns(address[] memory);
    function getWorldOwnerAddresses(uint256 worldId) external view returns(address[] memory);
    function getWorldAdminAddresses(uint256 worldId) external view returns(address[] memory);
    function getGameAdminAddresses() external view returns(address[] memory);
    function getTokenOwnerAddress(uint256 worldId, uint256 tokenId) external view returns(address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IGameAccess.sol";

contract AccessControl is Ownable {
    IGameAccess internal _gameAccess;

    constructor(address gameAddress) {
        _gameAccess = IGameAccess(gameAddress);
    }

    modifier onlyGameOwner() {
        bool isGameOwner = checkAccess(msg.sender, _gameAccess.getGameAdminAddresses());
        bool isOwner = msg.sender == owner();
        bool isGame = msg.sender == address(_gameAccess);

        require(isGameOwner || isOwner || isGame, "WorldAccess: caller is not GameOwner");
        _;
    }

    function setGameAddress(address gameAddress) public virtual onlyGameOwner {
        _gameAccess = IGameAccess(gameAddress);
    }

    function checkAccess(address sender, address[] memory addresses) internal view returns(bool) {
        bool result = false;
        for (uint256 i; i < addresses.length; i++) {
            if (addresses[i] == sender) {
                result = true;
            }
        }

        return result;
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