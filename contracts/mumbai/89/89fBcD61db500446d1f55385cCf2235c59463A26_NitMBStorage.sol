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
import "./interfaces/IConditions.sol";

contract NitMBStorage is Ownable { 

    // // STRUCTS

    enum chType {
        ERC1155,
        ERC721,
        ERC20,
        offChain
    }

    struct Item {
        //CB: Needs more reorg to pack data
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

    // // ERRORS

    error OnlyAuthorized();
    error WrongItemRef();

    // // EVENTS

    event ItemAddedToPool(
        uint256 indexed poolIndex,
        uint256 indexed itemRef,
        string itemTitle
    );

    event ItemRemovedFromPool(
        uint256 indexed poolIndex,
        uint256 indexed itemRef,
        bool permanentDelete
    );

    event ItemDistributed(
        address indexed winner,
        uint256 indexed poolIndex,
        uint256 indexed itemRef,
        string itemTitle
    );

    event ItemExpiredWarning(
        uint256 indexed itemRef
    );

    event ItemSoldOut(
        uint256 indexed poolIndex,
        uint256 indexed itemRef,
        string title
    );

    event BoxReturnedToUser(
        uint256 poolIndex,
        address user
    );

    // OPERATOR EVENTS

    event OperatorUpdated(address operator, bool indexed newState, uint256 indexed opType);
    event PoolUpdated(uint256 indexed poolIndex);
    event ItemUpdated(uint256 indexed itemRef);
    
    
    // // STATE

    // OPERATORS

    mapping(address => bool) public governors;
    mapping(address => bool) public admins;
    mapping(address => bool) public keepers;
    mapping(address => bool) public authorizedOp;

    // CONFIG

    bool public paused;
    bool public openingPriceActivated;
    bool public nitConditActivated;
    bool public sigRequired;
    bool public keeperAutoSync;

    uint256 public syncInterval;
    uint256 public cbHolder;
    uint8 public autoPurgeLevel;

    uint8 public maxVRFTries;
    VRFConfig public vrfConfig;
    address public vrfCoordinator;
    
    IERC20 public ydfContract;                  // maybe set in constructor
    address public nitConditionsContract;
    address public defaultBoxesContract;
    address public defaultItemsContract;
    address public defaultItemsVault;
    address public cbSigner;

    // DATA

    uint256 public mbPoolCount;
    mapping(uint256 => MBPool) public Pools;
    mapping(uint256 => string) public PoolsTitles;
    mapping(uint256 => uint32[]) public PoolsConditions;
    
    mapping(uint256 => Item) public itemsRegistry;
    mapping(uint256 => string) public itemsTitles;
    mapping(uint256 => string) public itemsURIs;

    mapping(uint256 => uint256[]) public PoolItems;
    mapping(uint256 => uint256[]) public oldItems;

    mapping(uint256 => address[]) public itemWinners;
    mapping(address => uint256[]) public userWonItems;
    mapping(uint256 => mapping(address => uint256)) public itemWinsOfUserbyRef;
    mapping(uint256 => mapping(address => uint256)) public userNonces;
    mapping(uint256 => mapping(address => uint256)) public lastOpenedBox;

    // // MODIFIERS

    modifier onlyAuthorized() {
        if (!authorizedOp[msg.sender] && msg.sender != owner() ) revert OnlyAuthorized();
        _;
    }

    // // CONSTRUCTOR

    constructor() {
        governors[msg.sender] = true;
        admins[msg.sender] = true;
        syncInterval = 43_200;          //12h
        maxVRFTries = 3;
        paused = true;
    }

    // // MAIN FUNCTIONS

    // REWARD DISTRIBUTION

    function _distributeReward(
        uint256 _poolIndex,
        uint256 _itemIndex,
        address _winner,
        bool _lastOne
    ) public onlyAuthorized {
        uint256 _ref = PoolItems[_poolIndex][_itemIndex];
        Item storage _item = itemsRegistry[_ref];

        _item.supply -= 1;
        Pools[_poolIndex].totalSupply -= 1;
        userWonItems[_winner].push(_ref);
        itemWinners[_ref].push(_winner);
        itemWinsOfUserbyRef[_ref][_winner] += _item.rAmount;
        if (_lastOne || _item.supply < 1) {
            _removeItemFromPool(_poolIndex, _itemIndex, false);
            emit ItemSoldOut(_poolIndex, _ref, itemsTitles[_ref]);
        }
        if(_item.onChainType == chType.ERC1155) {
            IERC1155(_item.itemContract).safeTransferFrom(_item.vaultAddress, _winner, _item.itemTokenId, _item.rAmount, "");
        } else if (_item.onChainType == chType.ERC721) {
            IERC721(_item.itemContract).safeTransferFrom(_item.vaultAddress,_winner,_item.itemTokenId);
        } else if (_item.onChainType == chType.ERC20) {
            IERC20(_item.itemContract).transferFrom(_item.vaultAddress, _winner, _item.rAmount);
        }
        emit ItemDistributed(_winner, _poolIndex, _ref, itemsTitles[_ref]);
    }

    function _moveStuff(
        address _user, 
        uint256 _pool, 
        uint256 _ydfPrice, 
        bool _return
    ) public onlyAuthorized {
        IERC1155(Pools[_pool].mbContract).safeTransferFrom(
            (_return? address(this): _user),
            (_return? _user:address(this)),
            Pools[_pool].mbTokenId,
            1,
            ""
        );
        if(_ydfPrice > 0) {
            if(_return) ydfContract.transfer(_user, _ydfPrice);
            else ydfContract.transferFrom(_user, address(this), _ydfPrice);
        }
        if (_return) {
            emit BoxReturnedToUser(_pool,_user);
        }
    }

    // ITEMS MANAGMENT

    function _removeItemFromPool(
        uint256 _poolIndex,
        uint256 _itemIndex,
        bool _permanentDelete
    ) public onlyAuthorized {
        uint256 _ref = PoolItems[_poolIndex][_itemIndex];
        Item storage _item = itemsRegistry[_ref];
        
        Pools[_poolIndex].itemCount -= 1;
        if (_item.supply > 0)
            Pools[_poolIndex].totalSupply -= _item.supply;

        if (_permanentDelete) {
            delete itemsRegistry[_ref];
            delete itemsTitles[_ref];
            delete itemsURIs[_ref];
        } else {
            _item.expired = true;
            oldItems[_poolIndex].push(_ref);
        }
        uint256 _len = PoolItems[_poolIndex].length;
        if (_itemIndex < _len - 1) {
            uint256 _lastRef = PoolItems[_poolIndex][_len - 1];
            itemsRegistry[_lastRef].itemIndexInPool = _itemIndex;
            PoolItems[_poolIndex][_itemIndex] = _lastRef;
        }
        PoolItems[_poolIndex].pop();
        emit ItemRemovedFromPool(_poolIndex, _ref, _permanentDelete);
    }

    function _insertItemInPool(uint256 _poolIndex, uint256 _itemRef) public onlyAuthorized {
        PoolItems[_poolIndex].push(_itemRef);
        emit ItemAddedToPool(_poolIndex, _itemRef, itemsTitles[_itemRef]);
    }

    function _updateItem(Item memory _item) public onlyAuthorized {
        itemsRegistry[_item.ref] = _item;
        emit ItemUpdated(_item.ref);
    }

    function _setItemTitle(uint256 _itemRef, string calldata _title) public onlyAuthorized {
        if(_itemRef == 0) revert WrongItemRef();
        itemsTitles[_itemRef] = _title;
    }

    function _setItemURI(uint256 _itemRef, string calldata _newURI) public onlyAuthorized {
        itemsURIs[_itemRef] = _newURI;
    }

    // POOLS MANAGEMENT

    function _updatePool(uint256 _pool, MBPool memory _mbpool) public onlyAuthorized {
        Pools[_pool] = _mbpool;
        emit PoolUpdated(_pool);
    }

    function _setPoolTitle(uint256 _poolIndex, string calldata _title) public onlyAuthorized {
        PoolsTitles[_poolIndex] = _title;
    }

    function _incremPoolCount() public onlyAuthorized {
        mbPoolCount++;
    }

    function _setPoolConditions(uint256 _pool, uint32[] calldata _conditions) public onlyAuthorized {
        uint256 _oldLen = PoolsConditions[_pool].length;
        uint256 _newLen = _conditions.length;
        for (
            uint256 i = 0;
            i < ((_newLen < _oldLen) ? _oldLen : _newLen);
            i++
        ) {
            if (i < ((_newLen < _oldLen) ? _newLen : _oldLen))
                PoolsConditions[_pool][i] = _conditions[i];
            else if (_newLen < _oldLen) PoolsConditions[_pool].pop();
            else PoolsConditions[_pool].push(_conditions[i]);
        }
    }

    // USER DATA

    function _incrementMBopens(uint256 _pool, address _user) public onlyAuthorized {
        userNonces[_pool][_user]++;
        Pools[_pool].numOpens++;
        lastOpenedBox[_pool][_user] = block.timestamp;
    }

    // // LIST UPDATE FUNCTIONS

    function _targetList(uint256 _pool, uint256 _listType)
        internal
        view
        returns (uint256[] storage)
    {
        if (_listType == 0) {
            return PoolItems[_pool];
        }
        return oldItems[_pool];
    }
    
    function _forceUpdateList( 
        uint256 _listType,
        uint256 _pool,
        bool _push,
        uint256 _index,
        uint256 _newRef
    ) public onlyAuthorized {
        uint256[] storage _list = _targetList(_pool, _listType);
        if (_push) _list.push(_newRef);
        else _list[_index] = _newRef;
    }

    function _forcePopList(
        uint256 _listType,
        uint256 _pool,
        uint256 _count
    ) public onlyAuthorized {
        uint256[] storage _list = _targetList(_pool, _listType);
        uint _len = (_count < _list.length ? _count : _list.length);
        for (uint256 i = 0; i < _len; i++) {
            _list.pop();
        }
    }

    // // VIEW FUNCTIONS

    // // POOL

    function getPoolTotalSupply(uint256 _poolIndex) public view returns (uint256) {
        return Pools[_poolIndex].totalSupply;
    }

    function getPoolItems(uint256 _poolIndex) public view returns (uint256[] memory) {
        return PoolItems[_poolIndex];
    }

    function getOldItems(uint256 _poolIndex) public view returns (uint256[] memory) {
        return oldItems[_poolIndex];
    }

    function getPoolConditions(uint256 _poolIndex) public view returns (uint32[] memory) {
        return PoolsConditions[_poolIndex];
    }

    function getPoolItemsCount(uint256 _poolIndex) public view returns (uint256) {
        return PoolItems[_poolIndex].length;
    }

    function getOldItemsCount(uint256 _poolIndex) public view returns (uint256) {
        return oldItems[_poolIndex].length;
    }

    function getPoolConditionsCount(uint256 _poolIndex) public view returns (uint256) {
        return PoolsConditions[_poolIndex].length;
    }

    // ITEM SUPPLY

    function getItemSupply(uint256 _itemRef) public view returns (uint256) {
        return itemsRegistry[_itemRef].supply;
    }

    // ITEM WINNERS COUNT

    function getItemWinnersCount(uint256 _ref) public view returns (uint256) {
        return itemWinners[_ref].length;
    }

    // USER WON ITEMS

    function getUserWonItems(address _user) public view returns (uint256[] memory) {
        return userWonItems[_user];
    }

    function getUserWonItemsCount(address _user) public view returns (uint256) {
        return userWonItems[_user].length;
    }

    // // AUTHORIZED FUNCTIONS

    function setPausedState(bool _newState) public onlyAuthorized {
        paused = _newState;
    }

    function setAdmin(address _admin, bool _newState) public onlyAuthorized {
        admins[_admin] = _newState;
        emit OperatorUpdated(_admin, _newState, 2);
    }

    // // OWNER FUNCTIONS 

    function setAuthorized(address _authorized, bool _newState) public onlyOwner {
        authorizedOp[_authorized] = _newState;
        emit OperatorUpdated(_authorized, _newState, 0);
    }

    function setGovernor(address _governor, bool _newState) public onlyOwner {
        governors[_governor] = _newState;
        emit OperatorUpdated(_governor, _newState, 1);
    }

    function setKeeper(address _keeper, bool _newState) public onlyOwner {
        keepers[_keeper] = _newState;
        emit OperatorUpdated(_keeper, _newState, 3);
    }

    function setYdfContract(address _ydfContract) public onlyOwner {
        ydfContract = IERC20(_ydfContract);
    }

    function setNitConditions(address _nitConditionsContract, bool _activated) public onlyOwner {
        if(_activated) require(INitConditions(_nitConditionsContract).ready());
        nitConditionsContract = _nitConditionsContract;
        nitConditActivated = _activated;
    }

    function setVrfCoordinator(address _newVrfCoordinator) public onlyOwner {
        vrfCoordinator = _newVrfCoordinator;
    }

    function setVrfConfig(VRFConfig memory _newVrfConfig) public onlyOwner {
        vrfConfig = _newVrfConfig;
    }

    function setMaxVrfTries(uint8 _newMaxVrfTries) public onlyOwner {
        maxVRFTries = _newMaxVrfTries;
    }

    function setDefaultBoxesContract(address _newDefaultBoxesContract) public onlyOwner {
        defaultBoxesContract = _newDefaultBoxesContract;
    }

    function setDefaultItemsContract(address _newDefaultItemsContract) public onlyOwner {
        defaultItemsContract = _newDefaultItemsContract;
    }

    function setDefaultItemsVault(address _newDefaultItemsVault) public onlyOwner {
        defaultItemsVault = _newDefaultItemsVault;
    }
    
    function setOpeningPriceActivated(bool _openingPriceActivatedState) public onlyOwner {
        openingPriceActivated = _openingPriceActivatedState;
    }

    function setSigRequired(bool _sigRequiredState) public onlyOwner {
        sigRequired = _sigRequiredState;
    }

    function setSigner(address _newSigner) public onlyOwner {
        cbSigner = _newSigner;
    }

    function setAutoPurgeLevel(uint8 _autoPurgeLevel) public onlyOwner {
        autoPurgeLevel = _autoPurgeLevel;
    }

    function setCBHolder(uint256 _newCBHolder) public onlyOwner {
        cbHolder = _newCBHolder;
    }
    
    function setKeeperAutoSync(bool _keeperAutoSync, uint256 _syncInterval) public onlyOwner {
        require(!_keeperAutoSync || _syncInterval > 30);
        keeperAutoSync = _keeperAutoSync;
        syncInterval = _syncInterval;
    }

    function setApproval(
        chType _type,
        address _assetAddress,
        address _operator,
        bool _approval,
        uint256 _allowance
    ) external onlyOwner {
        if (_type == chType.ERC1155) {
            IERC1155(_assetAddress).setApprovalForAll(_operator, _approval); //chType = 0
        } else if (_type == chType.ERC721) {
            IERC721(_assetAddress).setApprovalForAll(_operator, _approval);
        } else if (_type == chType.ERC20) {
            IERC20(_assetAddress).approve(_operator, _allowance);
        }
    }

    // // OTHER

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) external returns (bytes4) {
        return this.onERC1155Received.selector;
    }
}

//SPDX-License-Identifier: GPL-3.0

// ╔══╗────────────╔══╗
// ║  ║ 9Tales.io  ║  ║
// ║ ╔╬═╦╗╔═╦═╦╦═╦╗║╔╗║ 
// ║ ╚╣╬║╚╣╬║║║║╩╣╚╣╔╗║
// ╚══╩═╩═╩═╩╩═╩═╩═╩══╝

pragma solidity ^0.8.9;

interface INitConditions {

    function simpleCheck(address user, uint32[] calldata conditions) external view returns (bool);

    function ready() external view returns(bool);
    
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