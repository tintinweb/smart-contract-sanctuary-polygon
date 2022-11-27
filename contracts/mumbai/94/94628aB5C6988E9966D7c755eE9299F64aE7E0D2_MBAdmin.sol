//SPDX-License-Identifier: GPL-3.0

// ╔══╗────────────╔══╗
// ║  ║ 9Tales.io  ║  ║
// ║ ╔╬═╦╗╔═╦═╦╦═╦╗║╔╗║ 
// ║ ╚╣╬║╚╣╬║║║║╩╣╚╣╔╗║
// ╚══╩═╩═╩═╩╩═╩═╩═╩══╝

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IMBStorage.sol";

contract MBAdmin is Ownable {

    // // STATE DATA

    IMBStorage public mbStorage;

    // // EVENTS

    event ItemAddedToPool(address indexed admin, uint256 indexed poolIndex, uint256 indexed itemRef, string itemTitle);
    event ItemRemovedByAdmin(address indexed admin, uint256 indexed poolIndex, uint256 indexed itemRef, string title, bool permanentDelete);
    event ItemUpdated(address indexed admin,uint256 indexed itemRef,string indexed whatsModified);

    event PoolSyncForced(address indexed admin, uint256 indexed poolIndex, uint256 removedItems, uint256 newItemCount, uint256 newTotalSupply); 
    event MBStorageAddressSet(address MBStorageAddress);

    // // ERRORS
    
    error OnlyAdmin();
    error OnlyKeeper();
    error OnlyOwner();
    error WrongItemRef();
    error RefExists();
    error RefDontExist();
    error WrongPoolIndex();
    error WrongItemTitle();
    error NoTitle();
    error InvalidSupplyOrRAmount();
    error InvalidExpirationTime();
    error ItemExpired();
    error CheckVaultSupply();
    error CheckItemContract();
    error mbNeedsVaultApproval();
    error WrongTitle();
    error ItemNotInPool();

    // // MODIFIERS

    function _isOwner() internal view returns (bool) {
        return (owner() == _msgSender() || _msgSender() == mbStorage.owner());
    }

    function _checkOwner() internal view override {
        if(!_isOwner()) revert OnlyOwner();
    }

    modifier onlyAdmin() {
        if (
            !mbStorage.admins(msg.sender) &&
            !mbStorage.governors(msg.sender) &&
            !_isOwner()
        ) revert OnlyAdmin();
        _;
    }

    modifier onlyKeeper() {
        if (
            !mbStorage.keepers(msg.sender) &&
            !mbStorage.admins(msg.sender) &&
            !mbStorage.governors(msg.sender) &&
            !_isOwner()
        ) revert OnlyKeeper();
        _;
    }

    // // CONSTRUCTOR 

    constructor(address _mbStorageAddress) {
        setMBStorage(_mbStorageAddress);
    }

    // // ADMIN FUNCTIONS

    function adminAddItemInPool(
        uint256 _poolIndex,
        string memory _title,
        string memory _uri,
        IMBStorage.Item memory _item
    ) public onlyAdmin { 
        if (_item.ref == 0) revert WrongItemRef();
        if (bytes(mbStorage.PoolsTitles(_poolIndex)).length == 0)
            revert WrongPoolIndex();
        if (_poolIndex != _item.pool) revert WrongPoolIndex();
        if (bytes(mbStorage.itemsTitles(_item.ref)).length > 0)
            revert RefExists();
        if (bytes(_title).length == 0) revert NoTitle();
        if (_item.expired) revert ItemExpired();
        if (_item.rAmount == 0 || _item.supply == 0)
            revert InvalidSupplyOrRAmount();
        if (_item.expirationTime > 0 && _item.expirationTime <= block.timestamp)
            revert InvalidExpirationTime();
        if (_item.onChainType != IMBStorage.chType.offChain) {
            if(_item.itemContract == address(0)) _item.itemContract = mbStorage.defaultItemsContract();
            if(_item.vaultAddress == address(0)) _item.vaultAddress = mbStorage.defaultItemsVault(); 
            address _itemContract = _item.itemContract;
            uint256 cSize;
            assembly {cSize := extcodesize(_itemContract)}
            if (cSize == 0) revert CheckItemContract();
        }
        if (_item.onChainType == IMBStorage.chType.ERC1155) {
            if (IERC1155(_item.itemContract).balanceOf(_item.vaultAddress, _item.itemTokenId) <
                _item.supply * _item.rAmount) 
                revert CheckVaultSupply();
            if (!IERC1155(_item.itemContract).isApprovedForAll(_item.vaultAddress, address(mbStorage))) 
                revert mbNeedsVaultApproval();
        } else if (_item.onChainType == IMBStorage.chType.ERC721) {
            if (_item.rAmount != 1 || _item.supply != 1) 
                revert InvalidSupplyOrRAmount(); 
            if (IERC721(_item.itemContract).ownerOf(_item.itemTokenId) != _item.vaultAddress)
                revert CheckVaultSupply();
            if (!IERC721(_item.itemContract).isApprovedForAll(_item.vaultAddress, address(mbStorage))
            ) revert mbNeedsVaultApproval();
        } else if (_item.onChainType == IMBStorage.chType.ERC20) {
            if (IERC20(_item.itemContract).balanceOf(_item.vaultAddress) < _item.supply * _item.rAmount)
                revert CheckVaultSupply();
            if (IERC20(_item.itemContract).allowance(_item.vaultAddress, address(mbStorage)) <
                _item.supply * _item.rAmount) revert mbNeedsVaultApproval();
        }

        uint256 _itemIndexInPool = mbStorage.getPoolItemsCount(_poolIndex);
        _item.itemIndexInPool = _itemIndexInPool;
        mbStorage._setItemTitle(_item.ref, _title);
        mbStorage._setItemURI(_item.ref, _uri);
        mbStorage._updateItem(_item);
        mbStorage._insertItemInPool(_poolIndex, _item.ref);

        IMBStorage.MBPool memory _mbp = mbStorage.Pools(_poolIndex);
        _mbp.itemCount++;
        _mbp.totalSupply += _item.supply;
        mbStorage._updatePool(_poolIndex, _mbp);

        emit ItemAddedToPool(
            msg.sender,
            _poolIndex,
            _item.ref,
            _title
        );
    }

    function adminRemoveItemFromPool(
        uint256 _poolindex,
        uint256 _ref,
        string memory _title,
        bool _permanentDelete
    ) public onlyAdmin {
        if (_ref == 0) revert WrongItemRef();
        if (bytes(mbStorage.itemsTitles(_ref)).length == 0)
            revert RefDontExist();
        IMBStorage.Item memory _item = mbStorage.itemsRegistry(_ref);
        if (_item.pool != _poolindex) revert WrongPoolIndex();
        if (
            keccak256(abi.encodePacked(mbStorage.itemsTitles(_ref))) !=
            keccak256(abi.encodePacked(_title))
        ) revert WrongTitle();
        if (mbStorage.PoolItems(_poolindex, _item.itemIndexInPool) != _ref)
            revert ItemNotInPool();
        mbStorage._removeItemFromPool(_poolindex, _item.itemIndexInPool, _permanentDelete);
        emit ItemRemovedByAdmin(
            msg.sender,
            _poolindex,
            _ref,
            _title,
            _permanentDelete
        );
    }

    function admChangeItemExpirationTime(
        uint256 _ref,
        string calldata _oldTitle,
        uint256 _expirationTime
    ) public onlyAdmin {
        if (_ref == 0) revert WrongItemRef();
        if (bytes(mbStorage.itemsTitles(_ref)).length == 0)
            revert RefDontExist();
        if (
            keccak256(abi.encodePacked(mbStorage.itemsTitles(_ref))) !=
            keccak256(abi.encodePacked(_oldTitle))
        ) revert WrongItemTitle();
        if (_expirationTime > 0 && _expirationTime <= block.timestamp) revert InvalidExpirationTime();

        IMBStorage.Item memory _item = mbStorage.itemsRegistry(_ref);
        _item.expirationTime = _expirationTime;
        mbStorage._updateItem(_item);
        emit ItemUpdated(msg.sender, _ref, "expirationTime");
    }

    function adminUpdateItemData(
        uint256 _ref,
        string calldata _oldTitle,
        string calldata _newTitle,
        string calldata _newUri
    ) public onlyAdmin {
        if (_ref == 0) revert WrongItemRef();
        if (bytes(mbStorage.itemsTitles(_ref)).length == 0)
            revert RefDontExist();
        if (
            keccak256(abi.encodePacked(mbStorage.itemsTitles(_ref))) !=
            keccak256(abi.encodePacked(_oldTitle))
        ) revert WrongItemTitle();
        if (bytes(_newTitle).length > 0) {
            mbStorage._setItemTitle(_ref, _newTitle);
            emit ItemUpdated(msg.sender, _ref, "title");
        }
        if (bytes(_newUri).length > 0) {
            mbStorage._setItemURI(_ref, _newUri);
            emit ItemUpdated(msg.sender, _ref, "uri");
        }
    }

    // // KEEPER FUNCTIONS

    // function purgeExpiringItems() public onlyKeeper returns(uint256 _removedCount) {
    //     uint256 _count = mbStorage.getExpiringCount();
    //     if (_count == 0) revert NoExpiringItems();
    //     for (uint256 i = 0; i < _count; i++) {
    //         uint256 _ref = mbStorage.expiringItems(_count - i - 1);
    //         IMBStorage.Item memory _item = mbStorage.itemsRegistry(_ref);
    //         if (_item.itemIndexInPool >= mbStorage.getPoolItemsCount(_item.pool)
    //             || mbStorage.PoolItems(_item.pool, _item.itemIndexInPool) != _ref
    //             ) {
    //             emit SomethingWrong(_ref);
    //             continue;
    //             }
    //         mbStorage._removeItemFromPool(_item.pool,_item.itemIndexInPool,false);
    //         mbStorage._forceUpdateList(9, 11, false, _count - i - 1, mbStorage.expiringItems(_count-_removedCount-1));
    //         mbStorage._forcePopList(8,7,1);
    //         _removedCount++;
    //         }
    //     emit ExpiringItemsPurged(msg.sender, (_removedCount == _count), _count, _removedCount);
    //     return _removedCount;
    // }

    function syncPoolSupply(uint256 _pool) public onlyKeeper returns (uint256 _removedCount) {
        // if (mbStorage.getExpiringCount() > 0) revert PurgeExpiringItemsFirst();
        uint256 _poolItemsCount = mbStorage.getPoolItemsCount(_pool);
        uint256 _itemCount;
        uint256 _totalSupply;
        for (uint256 i = 0; i < _poolItemsCount; i++) {
            uint256 _itemRef = mbStorage.PoolItems(_pool, _poolItemsCount - i - 1);
            IMBStorage.Item memory _item = mbStorage.itemsRegistry(_itemRef);
            if (
                _item.expired
                || (_item.expirationTime > 0 && _item.expirationTime <= block.timestamp)
                || _item.supply < 1
                ) {
                mbStorage._removeItemFromPool(_pool, _poolItemsCount - i - 1, false);
                _removedCount++;
            } else {
                _itemCount++;
                _totalSupply += _item.supply;
            }
        }
        IMBStorage.MBPool memory _mbPool = mbStorage.Pools(_pool);
        _mbPool.itemCount = _itemCount;
        _mbPool.totalSupply = _totalSupply;
        mbStorage._updatePool(_pool, _mbPool);

        emit PoolSyncForced(
            msg.sender,
            _pool,
            _removedCount,
            _itemCount,
            _totalSupply
        );
    }

    // // OWNER FUNCTIONS

    function setMBStorage(address _newMBStorageAddress) public onlyOwner {
        IMBStorage(_newMBStorageAddress).owner();
        mbStorage = IMBStorage(_newMBStorageAddress);
        emit MBStorageAddressSet(_newMBStorageAddress); 
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}