//SPDX-License-Identifier: GPL-3.0

// 9tales.io

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IMBStorage.sol";

contract MBView is Ownable {
    IMBStorage public mbStorage;

    constructor(address _mbStorage) {
        mbStorage = IMBStorage(_mbStorage);
    }

    function setMbStorag(address _newMBStorAddress) public onlyOwner {
        mbStorage = IMBStorage(_newMBStorAddress);
    }

    // GET POOL

    function getPoolsCount() public view returns (uint256) {
        return mbStorage.mbPoolCount();
    }

    function getPool(uint256 _poolIndex)
        external
        view
        returns (string memory, IMBStorage.MBPool memory)
    {
        return (mbStorage.PoolsTitles(_poolIndex), mbStorage.Pools(_poolIndex));
    }

    function getPoolsRAW() public view returns (IMBStorage.MBPool[] memory) {
        uint256 _poolsCount = mbStorage.mbPoolCount();
        IMBStorage.MBPool[] memory _pools = new IMBStorage.MBPool[](
            _poolsCount
        );
        for (uint256 i = 0; i < _poolsCount; i++) {
            _pools[i] = mbStorage.Pools(i);
        }
        return _pools;
    }

    function openedBoxCount(uint256 _pool) public view returns(uint256) {
        return mbStorage.Pools(_pool).numOpens;
    }

    function totalOpenedBoxesCount() public view returns(uint256 _total) {
        for ( uint256 i=0; i< mbStorage.mbPoolCount(); i++) {
            _total += mbStorage.Pools(i).numOpens;
        }
    }

    // GET ITEM

    function getItemByRef(uint256 _ref)
        external
        view
        returns (string memory, IMBStorage.Item memory)
    {
        return (mbStorage.itemsTitles(_ref), mbStorage.itemsRegistry(_ref));
    }

    function getItemByPoolIndex(uint256 _pool, uint256 _index)
        external
        view
        returns (string memory, IMBStorage.Item memory)
    {
        uint256 _ref = mbStorage.PoolItems(_pool, _index);
        return (mbStorage.itemsTitles(_ref), mbStorage.itemsRegistry(_ref));
    }

    // GET MULTIPLE ITEMS

    function getItemsByRef(uint256[] calldata _refs)
        public
        view
        returns (IMBStorage.Item[] memory)
    {
        uint256 _len = _refs.length;
        IMBStorage.Item[] memory _items = new IMBStorage.Item[](_len);
        for (uint256 i = 0; i < _len; i++)
            _items[i] = mbStorage.itemsRegistry(_refs[i]);
        return _items;
    }

    function getItemsTitles(uint256[] calldata _refs)
        public
        view
        returns (string[] memory)
    {
        uint256 _len = _refs.length;
        string[] memory _titles = new string[](_len);
        for (uint256 i = 0; i < _len; i++)
            _titles[i] = mbStorage.itemsTitles(_refs[i]);
        return _titles;
    }

    function getItemsURIs(uint256[] calldata _refs)
        public
        view
        returns (string[] memory)
    {
        uint256 _len = _refs.length;
        string[]
            memory _itemsUris = new string[](_len);
        for (uint256 i = 0; i < _len; i++)
            _itemsUris[i] = mbStorage.itemsURIs(_refs[i]);
        return _itemsUris;
    }

    // VIEW POOL ITEMS

    function getPoolItemsCount(uint256 _poolIndex)
        public
        view
        returns (uint256)
    {
        return mbStorage.getPoolItemsCount(_poolIndex);
    }

    function getPoolTotalSupply(uint256 _pool) public view returns (uint256) {
        return mbStorage.getPoolTotalSupply(_pool);
    }

    function getPoolRefsPAGE(
        uint256 _pool,
        uint256 _start,
        uint256 _maxLen
    ) public view returns (uint256[] memory) {
        uint256 _poolItemsCount = mbStorage.getPoolItemsCount(_pool);
        if (_start >= _poolItemsCount) {
            return (new uint256[](0));
        }
        uint256 finalLen = (_start + _maxLen < _poolItemsCount)
            ? _maxLen
            : _poolItemsCount - _start;
        uint256[] memory poolRefs = new uint256[](finalLen);
        for (uint256 i = 0; i < finalLen; i++) {
            poolRefs[i] = mbStorage.PoolItems(_pool, _start + i);
        }
        return poolRefs;
    }

    // //          //CB: KEEP OR OMIT RAW VIEWS ??!
    // function getPoolItemsRAW(uint256 _poolIndex)
    //     public
    //     view
    //     returns (IMBStorage.Item[] memory)
    // {
    //     uint256 _poolItemsCount = mbStorage.getPoolItemsCount(_poolIndex);
    //     IMBStorage.Item[] memory _poolItems = new IMBStorage.Item[](
    //         _poolItemsCount
    //     );
    //     for (uint256 i = 0; i < _poolItemsCount; i++)
    //         _poolItems[i] = mbStorage.itemsRegistry(
    //             mbStorage.PoolItems(_poolIndex, i)
    //         );
    //     return _poolItems;
    // }

    function getPoolItemsPAGE(
        uint256 _pool,
        uint256 _start,
        uint256 _maxLen
    ) public view returns (string[] memory, IMBStorage.Item[] memory) {
        // view pool Items URIs and objects Paginated
        uint256 _poolItemsCount = mbStorage.getPoolItemsCount(_pool);
        if (_start >= _poolItemsCount) {
            return (new string[](0), new IMBStorage.Item[](0));
        }
        uint256 finalLen = (_start + _maxLen < _poolItemsCount)
            ? _maxLen
            : _poolItemsCount - _start;
        IMBStorage.Item[] memory _poolItems = new IMBStorage.Item[](finalLen);
        string[] memory _uris = new string[](finalLen);
        for (uint256 i = 0; i < finalLen; i++) {
            _poolItems[i] = mbStorage.itemsRegistry(
                mbStorage.PoolItems(_pool, _start + i)
            );
            _uris[i] = mbStorage.itemsURIs(mbStorage.PoolItems(_pool, _start + i));
        }
        return (_uris, _poolItems);
    }

    function getItemTotalWins(uint256 _ref) public view returns (uint256) {
        return mbStorage.getItemWinnersCount(_ref);
    }

    // OLD ITEMS

    function getOldItemsCount(uint256 _poolIndex)
        public
        view
        returns (uint256)
    {
        return mbStorage.getOldItemsCount(_poolIndex);
    }

    function getOldRefsPAGE(
        uint256 _pool,
        uint256 _start,
        uint256 _maxLen
    ) public view returns (uint256[] memory) {
        uint256 _oldItemsCount = mbStorage.getOldItemsCount(_pool);
        if (_start >= _oldItemsCount) {
            return (new uint256[](0));
        }
        uint256 finalLen = (_start + _maxLen < _oldItemsCount)
            ? _maxLen
            : _oldItemsCount - _start;
        uint256[] memory oldRefs = new uint256[](finalLen);
        for (uint256 i = 0; i < finalLen; i++) {
            oldRefs[i] = mbStorage.oldItems(_pool, _start + i);
        }
        return oldRefs;
    }

    function getOldItemsPAGE(
        uint256 _pool,
        uint256 _start,
        uint256 _maxLen
    ) public view returns (string[] memory, IMBStorage.Item[] memory) {
        // view Old Items uris and objects Paginated
        uint256 _oldItemsCount = mbStorage.getOldItemsCount(_pool);
        if (_start >= _oldItemsCount) {
            return (new string[](0), new IMBStorage.Item[](0));
        }
        uint256 finalLen = (_start + _maxLen < _oldItemsCount)
            ? _maxLen
            : _oldItemsCount - _start;
        IMBStorage.Item[] memory _oldItems = new IMBStorage.Item[](finalLen);
        string[] memory _uris = new string[](finalLen);
        for (uint256 i = 0; i < finalLen; i++) {
            uint256 _ref = mbStorage.oldItems(_pool, _start + i);
            _oldItems[i] = mbStorage.itemsRegistry(_ref);
            _uris[i] = mbStorage.itemsURIs(_ref);
        }
        return (_uris, _oldItems);
    }

    // EXPIRING ITEMS REFS

    function getExpiringCount() public view returns (uint256) {
        return mbStorage.getExpiringCount();
    }

    function getExpiringRefsRAW() public view returns (uint256[] memory) {
        uint256 _expiringItemsCount = mbStorage.getExpiringCount();
        uint256[] memory _expiringRefs = new uint256[](_expiringItemsCount);
        for (uint256 i = 0; i < _expiringItemsCount; i++)
            _expiringRefs[i] = mbStorage.expiringItems(i);
        return _expiringRefs;
    }

    function getExpiringRefsPAGE(uint256 _start, uint256 _maxLen)
        public
        view
        returns (uint256[] memory)
    {
        uint256 _expiringItemsCount = mbStorage.getExpiringCount();
        if (_start >= _expiringItemsCount) {
            return (new uint256[](0));
        }
        uint256 finalLen = (_start + _maxLen < _expiringItemsCount)
            ? _maxLen
            : _expiringItemsCount - _start;
        uint256[] memory _expiringRefs = new uint256[](finalLen);
        for (uint256 i = 0; i < finalLen; i++) {
            _expiringRefs[i] = mbStorage.expiringItems(_start + i);
        }
        return _expiringRefs;
    }

    // ITEM WINNERS :

    function getItemWinnersCount(uint256 _itemRef)
        public
        view
        returns (uint256)
    {
        return mbStorage.getItemWinnersCount(_itemRef);
    }

    function getItemWinnersPAGE(
        uint256 _ref,
        uint256 _start,
        uint256 _maxLen,
        bool _latestFirst
    ) public view returns (address[] memory) {
        uint256 _winnersLength = mbStorage.getItemWinnersCount(_ref);
        if (_start >= _winnersLength) {
            return (new address[](0));
        }
        uint256 finalLen = (_start + _maxLen < _winnersLength)
            ? _maxLen
            : _winnersLength - _start;
        address[] memory _winners = new address[](finalLen);
        for (uint256 i = 0; i < finalLen; i++)
            _winners[i] = (
                (_latestFirst)
                    ? mbStorage.itemWinners(_ref, _start + finalLen - i - 1)
                    : mbStorage.itemWinners(_ref, _start + i)
            );
        return _winners;
    }

    // USER WON ITEMS

    function getUserWonItemsCount(address _user) public view returns (uint256) {
        return mbStorage.getUserWonItemsCount(_user);
    }

    function getUserWinAmountOfItem(address _user, uint256 _ref)
        public
        view
        returns (uint256)
    {
        return mbStorage.itemWinsOfUserbyRef(_ref, _user);
    }

    function getUserWonRefsPAGE(
        address _user,
        uint256 _start,
        uint256 _maxLen,
        bool _latestFirst
    ) public view returns (uint256[] memory) {
        uint256 _itemsLen = mbStorage.getUserWonItemsCount(_user);
        if (_start >= _itemsLen) {
            return (new uint256[](0));
        }
        uint256 finalLen = (_start + _maxLen < _itemsLen)
            ? _maxLen
            : _itemsLen - _start;
        uint256[] memory _wonItems = new uint256[](finalLen);
        for (uint256 i = 0; i < finalLen; i++)
            _wonItems[i] = (_latestFirst)
                ? mbStorage.userWonItems(_user, _start + finalLen - i - 1)
                : mbStorage.userWonItems(_user, _start + i);
        return _wonItems;
    }

    // function getUserWonItemsRAW(address _user)
    //     public
    //     view
    //     returns (IMBStorage.Item[] memory)
    // {
    //     uint256 _itemsLen = mbStorage.getUserWonItemsCount(_user);
    //     IMBStorage.Item[] memory _wonItems = new IMBStorage.Item[](_itemsLen);
    //     for (uint256 i = 0; i < _itemsLen; i++)
    //         _wonItems[i] = mbStorage.itemsRegistry(
    //             mbStorage.userWonItems(_user, _itemsLen - i - 1)
    //         );
    //     return _wonItems;
    // }

    function getUserWonItemsPAGE(
        address _user,
        uint256 _start,
        uint256 _maxLen,
        bool _latestFirst
    ) public view returns (IMBStorage.Item[] memory) {
        uint256 _itemsLen = mbStorage.getUserWonItemsCount(_user);
        if (_start >= _itemsLen) {
            return (new IMBStorage.Item[](0));
        }
        uint256 finalLen = (_start + _maxLen < _itemsLen)
            ? _maxLen
            : _itemsLen - _start;

        IMBStorage.Item[] memory _wonItems = new IMBStorage.Item[](_itemsLen);
        for (uint256 i = 0; i < finalLen; i++)
            _wonItems[i] = (_latestFirst)
                ? mbStorage.itemsRegistry(
                    mbStorage.userWonItems(_user, _start + finalLen - i - 1)
                )
                : mbStorage.itemsRegistry(
                    mbStorage.userWonItems(_user, _start + i)
                );
        return _wonItems;
    }

    // OTHER

    function getBPoolCountOfUser(address _user, uint256 _pool)
        public
        view
        returns (uint256)
    {
        return mbStorage.userNonces(_pool, _user);
    }

    function getTotalBoxCountOfUser(address _user)
        public
        view
        returns (uint256 _total)
    {
        for ( uint256 i=0; i< mbStorage.mbPoolCount(); i++) {
            _total += mbStorage.userNonces(i, _user);
        }
    }
    
    function userLastOpenedBox(uint256 _pool, address _user)
        public
        view
        returns (uint256)
    {
        return mbStorage.lastOpenedBox(_pool, _user);
    }

    // STATE

    function IsPaused() public view returns (bool) {
        return mbStorage.paused();
    }

    function ydfContract() public view returns (address) {
        return mbStorage.ydfContract();
    }

    function vrfCoordinator() public view returns (address) {
        return mbStorage.vrfCoordinator();
    }

    function vrfConfig() public view returns (IMBStorage.VRFConfig memory) {
        return mbStorage.vrfConfig();
    }
}

//SPDX-License-Identifier: GPL-3.0

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
    

    // function mbKeeper() external view returns (address);

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

    function PoolsConditions(uint256 _pool) external view returns (uint32[] memory);

    function getPoolTotalSupply(uint256 _pool) external view returns (uint256);

    function getPoolConditionsCount(uint256 _pool) external view returns (uint256);

    // Pool Items

    function getPoolItemsCount(uint256 _pool) external view returns (uint256);

    function PoolItems(uint256 _pool, uint256 _index) external view returns (uint256);

    // old Items

    function getOldItemsCount(uint256 _pool) external view returns (uint256);

    function oldItems(uint256 _pool, uint256 _index) external view returns (uint256);

    // expiring Items data

    function getExpiringCount() external view returns (uint256);

    function expiringItems(uint256 _index) external view returns (uint256);

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

    // User opened Data

    function userNonces(uint256 _pool, address _user) external view returns (uint256);

    function lastOpenedBox(uint256 _pool, address _user) external view returns (uint256);

    //// write functions

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

    function _markItemExpiring(uint256 _itemRef) external;

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