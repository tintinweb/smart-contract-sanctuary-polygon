//SPDX-License-Identifier: GPL-3.0

// ╔══╗────────────╔══╗
// ║  ║ 9Tales.io  ║  ║
// ║ ╔╬═╦╗╔═╦═╦╦═╦╗║╔╗║ 
// ║ ╚╣╬║╚╣╬║║║║╩╣╚╣╔╗║
// ╚══╩═╩═╩═╩╩═╩═╩═╩══╝

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IGSstorage.sol";

contract GSview is Ownable {
    IGSstorage public gsStorage;

    constructor(address _gsStorage) {
        gsStorage = IGSstorage(_gsStorage);
    }

    function setMBStorage(address _newGSStorAddress) public onlyOwner {
        gsStorage = IGSstorage(_newGSStorAddress);
    }

    // VIEW ITEM & ITEM DATA

    function getItem(uint256 _itemRef) external view
        returns (string memory, IGSstorage.Item memory)
    {
        return (gsStorage.itemsTitles(_itemRef), gsStorage.itemsRegistry(_itemRef));
    }

    function getItemTotalPurchases(uint256 _itemRef) external view returns (uint256) {
        return gsStorage.getItemTotalPurchases(_itemRef);
    }

    // VIEW MULTIPLE ITEMS

    function getItemsByRef(uint256[] calldata _refs)
        public
        view
        returns (IGSstorage.Item[] memory)
    {
        uint256 _len = _refs.length;
        IGSstorage.Item[] memory _items = new IGSstorage.Item[](_len);
        for (uint256 i = 0; i < _len; i++)
            _items[i] = gsStorage.itemsRegistry(_refs[i]);
        return _items;
    }

    function getItemsSupplies(uint256[] calldata _refs) public view returns(uint256[] memory) {
        uint256 _len = _refs.length;
        uint256[] memory _supplies = new uint256[](_len);
        for(uint256 i = 0; i < _len; i++){
            if(!gsStorage.itemsRegistry(_refs[i]).active) _supplies[i] = 0;
            else _supplies[i] = gsStorage.getItemSupply(_refs[i]);
        }
        return _supplies;
    }

    function getItemsTitles(uint256[] calldata _refs)
        public
        view
        returns (string[] memory)
    {
        uint256 _len = _refs.length;
        string[] memory _titles = new string[](_len);
        for (uint256 i = 0; i < _len; i++)
            _titles[i] = gsStorage.itemsTitles(_refs[i]);
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
            _itemsUris[i] = gsStorage.itemsURIs(_refs[i]);
        return _itemsUris;
    }
    
    // VIEW ITEMS COUNT

    function allItemsCount() public view returns(uint256) {
        return gsStorage.getAllItemsCount();
    }

    function activeItemsCount() public view returns(uint256) {
        return gsStorage.getActiveItemsCount();
    }

    function oldItemsCount() public view returns(uint256) {
        return gsStorage.getOldItemsCount();
    }

    // VIEW REFS RAW

    function getActiveRefsRAW(bool _latestFirst) public view returns (uint256[] memory) {
        uint256 _length = gsStorage.getActiveItemsCount();
        uint256[] memory _refs = new uint256[](_length);
        for (uint256 i = 0; i < _length; i++)
            _refs[i] = (
                (_latestFirst)
                    ? gsStorage.activeItems(_length - i - 1)
                    : gsStorage.activeItems(i)
            );
        return _refs;
    }

    function getOldRefsRAW(bool _latestFirst) public view returns (uint256[] memory) {
        uint256 _length = gsStorage.getOldItemsCount();
        uint256[] memory _refs = new uint256[](_length);
        for (uint256 i = 0; i < _length; i++)
            _refs[i] = (
                (_latestFirst)
                    ? gsStorage.oldItems(_length - i - 1)
                    : gsStorage.oldItems(i)
            );
        return _refs;
    }

    function getRefsRAW_all(bool _latestFirst) public view returns (uint256[] memory) {
        uint256 _length = gsStorage.getAllItemsCount();
        uint256[] memory _refs = new uint256[](_length);
        for (uint256 i = 0; i < _length; i++)
            _refs[i] = (
                (_latestFirst)
                    ? gsStorage.allItems(_length - i - 1)
                    : gsStorage.allItems(i)
            );
        return _refs;
    }


    // VIEW REFS PAGE

    function getActiveRefsPAGE(
        uint256 _start,
        uint256 _maxLen,
        bool _latestFirst
    ) public view returns (uint256[] memory) {
        uint256 _length = gsStorage.getActiveItemsCount();
        if (_start >= _length) {
            return (new uint256[](0));
        }
        uint256 finalLen = (_start + _maxLen < _length)
            ? _maxLen
            : _length - _start;
        uint256[] memory _refs = new uint256[](finalLen);
        for (uint256 i = 0; i < finalLen; i++)
            _refs[i] = (
                (_latestFirst)
                    ? gsStorage.activeItems(_start + finalLen - i - 1)
                    : gsStorage.activeItems(_start + i)
            );
        return _refs;
    }

    function getOldRefsPAGE(
        uint256 _start,
        uint256 _maxLen,
        bool _latestFirst
    ) public view returns (uint256[] memory) {
        uint256 _length = gsStorage.getOldItemsCount();
        if (_start >= _length) {
            return (new uint256[](0));
        }
        uint256 finalLen = (_start + _maxLen < _length)
            ? _maxLen
            : _length - _start;
        uint256[] memory _refs = new uint256[](finalLen);
        for (uint256 i = 0; i < finalLen; i++)
            _refs[i] = (
                (_latestFirst)
                    ? gsStorage.oldItems(_start + finalLen - i - 1)
                    : gsStorage.oldItems(_start + i)
            );
        return _refs;
    }

    function getRefsPAGE_all(
        uint256 _start,
        uint256 _maxLen,
        bool _latestFirst
    ) public view returns (uint256[] memory) {
        uint256 _length = gsStorage.getAllItemsCount();
        if (_start >= _length) {
            return (new uint256[](0));
        }
        uint256 finalLen = (_start + _maxLen < _length)
            ? _maxLen
            : _length - _start;
        uint256[] memory _refs = new uint256[](finalLen);
        for (uint256 i = 0; i < finalLen; i++)
            _refs[i] = (
                (_latestFirst)
                    ? gsStorage.allItems(_start + finalLen - i - 1)
                    : gsStorage.allItems(_start + i)
            );
        return _refs;
    }

    // ITEM BUYERS

    function getItemBuyersCount(uint256 _itemRef)
        public
        view
        returns (uint256)
    {
        return gsStorage.getItemBuyersCount(_itemRef);
    }

    function getItemWinnersPAGE(
        uint256 _ref,
        uint256 _start,
        uint256 _maxLen,
        bool _latestFirst
    ) public view returns (address[] memory) {
        uint256 _lenght = gsStorage.getItemBuyersCount(_ref);
        if (_start >= _lenght) {
            return (new address[](0));
        }
        uint256 finalLen = (_start + _maxLen < _lenght)
            ? _maxLen
            : _lenght - _start;
        address[] memory _buyers = new address[](finalLen);
        for (uint256 i = 0; i < finalLen; i++)
            _buyers[i] = (
                (_latestFirst)
                    ? gsStorage.itemBuyers(_ref, _start + finalLen - i - 1)
                    : gsStorage.itemBuyers(_ref, _start + i)
            );
        return _buyers;
    }

    // USER WON ITEMS

    function getUserBoughtItemsCount(address _user) public view returns (uint256) {
        return gsStorage.getUserBoughtItemsCount(_user);
    }

    function getUserBoughtAmountOfItem(address _user, uint256 _ref)
        public
        view
        returns (uint256)
    {
        return gsStorage.itemPurchasesOfUser(_ref, _user);
    }

    function getUserBoughtRefsPAGE(
        address _user,
        uint256 _start,
        uint256 _maxLen,
        bool _latestFirst
    ) public view returns (uint256[] memory) {
        uint256 _lenght = gsStorage.getUserBoughtItemsCount(_user);
        if (_start >= _lenght) {
            return (new uint256[](0));
        }
        uint256 finalLen = (_start + _maxLen < _lenght)
            ? _maxLen
            : _lenght - _start;
        uint256[] memory _purchasedRefs = new uint256[](finalLen);
        for (uint256 i = 0; i < finalLen; i++)
            _purchasedRefs[i] = (_latestFirst)
                ? gsStorage.userBoughtItems(_user, _start + finalLen - i - 1)
                : gsStorage.userBoughtItems(_user, _start + i);
        return _purchasedRefs;
    }

    function getUserBoughtItemsRAW(address _user)
        public
        view
        returns (IGSstorage.Item[] memory)
    {
        uint256 _lenght = gsStorage.getUserBoughtItemsCount(_user);
        IGSstorage.Item[] memory _purchasedItems = new IGSstorage.Item[](_lenght);
        for (uint256 i = 0; i < _lenght; i++)
            _purchasedItems[i] = gsStorage.itemsRegistry(
                gsStorage.userBoughtItems(_user, _lenght - i - 1)
            );
        return _purchasedItems;
    }

    function getUserWonItemsPAGE(
        address _user,
        uint256 _start,
        uint256 _maxLen,
        bool _latestFirst
    ) public view returns (IGSstorage.Item[] memory) {
        uint256 _length = gsStorage.getUserBoughtItemsCount(_user);
        if (_start >= _length) {
            return (new IGSstorage.Item[](0));
        }
        uint256 finalLen = (_start + _maxLen < _length)
            ? _maxLen
            : _length - _start;

        IGSstorage.Item[] memory _purchasedItems = new IGSstorage.Item[](_length);
        for (uint256 i = 0; i < finalLen; i++)
            _purchasedItems[i] = (_latestFirst)
                ? gsStorage.itemsRegistry(
                    gsStorage.userBoughtItems(_user, _start + finalLen - i - 1)
                )
                : gsStorage.itemsRegistry(
                    gsStorage.userBoughtItems(_user, _start + i)
                );
        return _purchasedItems;
    }

    function userLastBoughtItem(address _user, uint256 _ref)
        public
        view
        returns (uint256)
    {
        return gsStorage.lastBoughtItem(_ref,_user);
    }

    // STATE

    function IsPaused() public view returns (bool) {
        return gsStorage.gsPaused();
    }

    function ydfContract() public view returns (address) {
        return gsStorage.ydfContract();
    }

    function nitConditonsActivated() public view returns (bool) {
        return gsStorage.nitConditActivated();
    }

}

//SPDX-License-Identifier: GPL-3.0

// ╔══╗────────────╔══╗
// ║  ║ 9Tales.io  ║  ║
// ║ ╔╬═╦╗╔═╦═╦╦═╦╗║╔╗║ 
// ║ ╚╣╬║╚╣╬║║║║╩╣╚╣╔╗║
// ╚══╩═╩═╩═╩╩═╩═╩═╩══╝

pragma solidity ^0.8.9;

interface IGSstorage {
    enum chType {
        ERC1155,
        ERC721,
        offChain
    }

    // [ref, startTime, endTime, supply, maxAmount, priceYdf, interval, totalPurchases, itemTokenId, itemContract, onChainType, active]

    struct Item {
        uint256 ref;
        uint256 startTime;
        uint256 endTime;
        uint256 supply;
        uint256 maxAmount;
        uint256 priceYdf;
        uint256 interval;
        uint256 totalPurchases;
        uint256 itemTokenId;
        address itemContract;
        chType onChainType;
        bool active;
    }

    function owner() external view returns(address);
    function admins(address) external view returns(bool);
    function authorizedOp(address) external view returns(bool);
    
    function gsPaused() external view returns(bool);
    function nitConditActivated() external view returns(bool);
    function sigRequired() external view returns(bool);
    function keeperAutoSync() external view returns(bool);
    function syncInterval() external view returns(uint256);
    function globalMaxAmount() external view returns(uint256);
    
    function ydfContract() external view returns(address);
    function nitConditionsContract() external view returns(address);
    function defaultItemsContract() external view returns(address);
    function itemsVault() external view returns(address);
    function cbSigner() external view returns(address);

    function itemsRegistry(uint256) external view returns(Item memory);
    function itemsTitles(uint256) external view returns(string memory);
    function itemsURIs(uint256) external view returns(string memory);
    function itemsConditions(uint256, uint256) external view returns(uint32);
    function getItemSupply(uint256) external view returns(uint256);
    function getItemTotalPurchases(uint256) external view returns(uint256);

    function allItems(uint256) external view returns(uint256);
    function activeItems(uint256) external view returns(uint256);
    function oldItems(uint256) external view returns(uint256);

    function itemBuyers(uint256,uint256) external view returns(address);
    function userBoughtItems(address,uint256) external view returns(uint256);
    function itemPurchasesOfUser(uint256,address) external view returns(uint256);
    
    function getAllItemsCount() external view returns(uint256);
    function getActiveItemsCount() external view returns(uint256);
    function getOldItemsCount() external view returns(uint256);
    function lastBoughtItem(uint256, address) external view returns(uint256);
    
    function getItemConditionsCount(uint256) external view returns(uint256);
    function getItemBuyersCount(uint256) external view returns(uint256);
    function getUserBoughtItemsCount(address) external view returns(uint256);
    
    function _distributeItem(address, uint256, uint256) external;

    function _updateItem(Item calldata) external;
    function _setItemTitle(uint256, string calldata) external;
    function _setItemURI(uint256, string calldata) external;
    function _forceUpdateList(uint256,uint256,uint256,uint256) external;
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