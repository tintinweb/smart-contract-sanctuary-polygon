//SPDX-License-Identifier: GPL-3.0

// ╔══╗────────────╔══╗
// ║  ║ 9Tales.io  ║  ║
// ║ ╔╬═╦╗╔═╦═╦╦═╦╗║╔╗║ 
// ║ ╚╣╬║╚╣╬║║║║╩╣╚╣╔╗║
// ╚══╩═╩═╩═╩╩═╩═╩═╩══╝

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IMBStorage.sol";

interface IMBAdmin {
    function syncPoolSupply(uint256 _poolIndex) external;
    // function purgeExpiringItems() external returns(uint256);
}
 
contract MBKeeper is Ownable {

    // // STATE

    bool public paused;
    IMBStorage public mbStorage;
    IMBAdmin public mbAdmin;
    uint256 public lastSync;

    // // ERROR

    error Paused();
    error OnlyOwner();
    error MbNotSet();
    error KeeperSyncingDisabled();
    error TooSoon();
    error OutOfRange();

    // // MODIFIERS

    function _isOwner() internal view returns (bool) {
        return (owner() == _msgSender() || _msgSender() == mbStorage.owner());
    }

    function _checkOwner() internal view override {
        if(!_isOwner()) revert OnlyOwner();
    }

    // // CONSTRUCTOR

    constructor(address _mbStorage) {
        setMBStorageAddress(_mbStorage);
    }

    // // KEEPER FUNCTIONS

    function checkUpkeep(bytes calldata checkData)
        public
        view
        returns (bool upkeepNeeded, bytes memory performData)
    {
        if (address(mbAdmin) == address(0) || address(mbStorage) == address(0)) return (false,"");
        if (paused || mbStorage.paused()) return (false,"");
        // if (checkData.length == 0)
        //     return (mbStorage.getExpiringCount() > 0, "");
        return (mbStorage.keeperAutoSync() 
                && block.timestamp - lastSync >= mbStorage.syncInterval() 
                // && mbStorage.getExpiringCount() == 0 
                && abi.decode(checkData, (uint256)) < mbStorage.mbPoolCount(),
            checkData);
    }

    function performUpkeep(bytes calldata performData) external {
        if (address(mbAdmin) == address(0) || address(mbStorage) == address(0)) revert MbNotSet();
        if (paused || mbStorage.paused()) revert Paused();
        if (!mbStorage.keeperAutoSync()) revert KeeperSyncingDisabled();
        if (block.timestamp - lastSync < mbStorage.syncInterval()) revert TooSoon();
        uint256 _poolIndex = abi.decode(performData, (uint256));
        if (_poolIndex >= mbStorage.mbPoolCount()) revert OutOfRange();
        mbAdmin.syncPoolSupply(_poolIndex);
        lastSync = block.timestamp;
    }

    // // OWNER FUNCTIONS

    function setMBStorageAddress(address _newMBStorageAddress) public onlyOwner {
        IMBStorage(_newMBStorageAddress).owner();
        mbStorage = IMBStorage(_newMBStorageAddress);
    }

    function setMBAdminAddress(address _newMBAdminAddress) public onlyOwner {
        mbAdmin = IMBAdmin(_newMBAdminAddress);
    }

    function setPaused(bool _newState) public onlyOwner {
        paused = _newState;
    }

}

//SPDX-License-Identifier: GPL-3.0

// ╔══╗────────────╔══╗
// ║  ║ 9Tales.io  ║  ║
// ║ ╔╬═╦╗╔═╦═╦╦═╦╗║╔╗║ 
// ║ ╚╣╬║╚╣╬║║║║╩╣╚╣╔╗║
// ╚══╩═╩═╩═╩╩═╩═╩═╩══╝

pragma solidity ^0.8.9;

interface IMBStorage {
    enum chType {
        ERC1155,
        ERC721,
        ERC20,
        offChain
    }

    struct Item {
        uint256 ref;
        uint256 pool;
        chType onChainType;
        address itemContract;
        uint256 itemTokenId;
        address vaultAddress;
        uint256 supply;
        uint256 rAmount;
        uint256 expirationTime;
        bool expired;
        uint256 itemIndexInPool;
    }

    struct MBPool {
        bool active;
        address mbContract;
        uint256 mbTokenId;
        uint256 openingPriceYdf;
        uint256 boxInterval;
        uint256 itemCount;
        uint256 totalSupply;
        uint256 numOpens;
    }

    struct VRFConfig {
        bytes32 keyHash;
        uint64 subId;
        uint16 minRequestConfirmations;
        uint32 callbackGasLimit;
        uint32 numWords;
    }

    // read functions:

    function owner() external view returns (address);

    function governors(address _gov) external view returns (bool);

    function admins(address _adm) external view returns (bool);

    function keepers(address _keep) external view returns (bool);

    function authorizedOp(address _op) external view returns (bool);

    function defaultBoxesContract() external view returns (address);

    function defaultItemsContract() external view returns (address);

    function defaultItemsVault() external view returns (address);

    function paused() external view returns (bool);

    function eoaOnly() external view returns (bool);

    function sigRequired() external view returns (bool);

    function openingPriceActivated() external view returns (bool);

    function nitConditActivated() external view returns (bool);

    function cbSigner() external view returns (address);

    function maxVRFTries() external view returns (uint8);

    function ydfContract() external view returns (address);

    function nitConditionsContract() external view returns (address);

    function vrfCoordinator() external view returns (address);

    function vrfConfig() external view returns (VRFConfig memory);

    // function autoPurge() external view returns (bool);

    function keeperAutoSync() external view returns (bool);

    function syncInterval() external view returns (uint256);

    // pools data

    function mbPoolCount() external view returns (uint256);

    function Pools(uint256 _pool) external view returns (MBPool memory);

    function PoolsTitles(uint256 _index) external view returns (string memory);

    function PoolsConditions(uint256 _pool, uint256 _index) external view returns (uint32);

    function getPoolConditions(uint256 _pool) external view returns (uint32[] memory);

    function getPoolTotalSupply(uint256 _pool) external view returns (uint256);

    function getPoolConditionsCount(uint256 _pool) external view returns (uint256);

    // Pool Items

    function getPoolItemsCount(uint256 _pool) external view returns (uint256);

    function PoolItems(uint256 _pool, uint256 _index) external view returns (uint256);

    // old Items

    function getOldItemsCount(uint256 _pool) external view returns (uint256);

    function oldItems(uint256 _pool, uint256 _index) external view returns (uint256);

    // // expiring Items data

    // function getExpiringCount() external view returns (uint256);

    // function expiringItems(uint256 _index) external view returns (uint256);

    // items data

    function itemsRegistry(uint256 _ref) external view returns (Item memory);

    function itemsTitles(uint256 _ref) external view returns (string memory);

    function itemsURIs(uint256 _index) external view returns (string memory);

    function getItemSupply(uint256 _ref) external view returns (uint256);

    // Item winners

    function getItemWinnersCount(uint256 _itemRef) external view returns (uint256);

    function itemWinners(uint256 _itemRef, uint256 _index) external view returns (address);

    // User won items

    function getUserWonItemsCount(address _user) external view returns (uint256);

    function userWonItems(address _user, uint256 _index) external view returns (uint256);

    function itemWinsOfUserbyRef(uint256 _ref, address _user) external view returns (uint256);

    // User Data

    function userNonces(uint256 _pool, address _user) external view returns (uint256);

    function lastOpenedBox(uint256 _pool, address _user) external view returns (uint256);

    // // write functions

    //Pool

    function _updatePool(uint256 _index, MBPool memory _pool) external;

    function _incremPoolCount() external;

    function _setPoolTitle(uint256 _pool, string calldata) external;

    function _setPoolConditions(uint256 _pool, uint32[] calldata _conditions) external;

    // Item

    function _updateItem(Item memory _item) external;

    function _setItemTitle(uint256 _itemRef, string calldata) external;

    function _setItemURI(uint256 _itemRef, string calldata) external;

    // Items to/from Pools

    function _insertItemInPool(uint256 _pool, uint256 _itemRef)
        external;

    function _removeItemFromPool(uint256 _pool, uint256 _itemIndex, bool _permaDelete ) external;

    // LOGIC

    function _distributeReward(uint256 pool, uint256 itemIndexInPool, address winner, bool lastOne) external;

    function _moveStuff(address _user, uint256 _pool, uint256 _ydfPaid, bool _return) external;

    // function _markItemExpiring(uint256 _itemRef) external;

    function _forcePopList(uint256 _listType, uint256 _pool, uint256 _count) external;

    function _forceUpdateList(uint256 _listType, uint256 _pool, bool _push, uint256 _index, uint256 _newRef) external;

    // OTHER

    function setAdmin(address _admin, bool _newState) external;

    function setPausedState(bool _state) external;

    function _incrementMBopens(uint256 _pool, address _user) external;

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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