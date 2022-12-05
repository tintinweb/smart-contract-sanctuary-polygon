//SPDX-License-Identifier: GPL-3.0

// ╔══╗────────────╔══╗
// ║  ║ 9Tales.io  ║  ║
// ║ ╔╬═╦╗╔═╦═╦╦═╦╗║╔╗║ 
// ║ ╚╣╬║╚╣╬║║║║╩╣╚╣╔╗║
// ╚══╩═╩═╩═╩╩═╩═╩═╩══╝

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interfaces/IConditions.sol";

contract GSstorage is Ownable {
    enum chType {
        ERC1155,
        ERC721,
        offChain
    }

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

    // // ERRORS

    error OnlyAuthorized();

    // // EVENTS

    event ItemPurchased(address indexed buyer, uint256 indexed itemRef, uint256 amount, string indexed title);
    event ItemSoldOut(uint256 indexed ref);

    // // STATE

    // OPERATORS

    mapping(address => bool) public admins;
    mapping(address => bool) public keepers;
    mapping(address => bool) public authorizedOp;

    // CONFIG

    bool public gsPaused;
    bool public nitConditActivated;
    bool public sigRequired;
    bool public keeperAutoSync;

    uint256 public globalMaxAmount;
    uint256 public syncInterval;
    uint256 public cbHolder;

    IERC20 public ydfContract;
    address public nitConditionsContract;
    address public defaultItemsContract;
    address public itemsVault; 
    address public cbSigner;

    // DATA

    mapping(uint256 => Item) public itemsRegistry;
    mapping(uint256 => string) public itemsTitles;
    mapping(uint256 => string) public itemsURIs;
    mapping(uint256 => uint32[]) public itemsConditions;

    uint256[] public allItems;
    uint256[] public activeItems;
    uint256[] public oldItems;

    mapping(uint256 => address[]) public itemBuyers;
    mapping(address => uint256[]) public userBoughtItems;
    mapping(uint256 => mapping(address => uint256)) public itemPurchasesOfUser;
    mapping(uint256 => mapping(address => uint256)) public lastBoughtItem;

    // MODIFIERS

    modifier onlyAuthorized() {
        if (!authorizedOp[msg.sender] && msg.sender != owner() ) revert OnlyAuthorized();
        _;
    }

    // CONSTRUCTOR

    constructor() {
        admins[msg.sender] = true;
        syncInterval = 43_200;          //12h
        globalMaxAmount = 10;
    }

    // FUNCTIONS

    // ITEM DISTRIBUTION

    function _distributeItem(address _buyer, uint256 _ref, uint256 _amount) public onlyAuthorized { //, bool _lastOne
        Item storage _item = itemsRegistry[_ref];
        _item.supply -= _amount;
        userBoughtItems[_buyer].push(_ref);
        itemBuyers[_ref].push(_buyer);
        itemPurchasesOfUser[_ref][_buyer] += _amount;
        lastBoughtItem[_ref][_buyer] = block.timestamp;
        _item.totalPurchases += _amount;
        if (_item.supply < 1) { 
            _item.active = false;
            emit ItemSoldOut(_ref);
        }
        ydfContract.transferFrom(_buyer, address(this), _item.priceYdf * _amount);
        if(_item.onChainType == chType.ERC1155) {
            IERC1155(_item.itemContract).safeTransferFrom(itemsVault, _buyer, _item.itemTokenId, _amount, "");
        } else if (_item.onChainType == chType.ERC721) {
            IERC721(_item.itemContract).safeTransferFrom(itemsVault,_buyer,_item.itemTokenId);
        }
        emit ItemPurchased(_buyer, _ref, _amount, itemsTitles[_ref]);
    }

    // ITEMS MANAGMENT

    function _updateItem(Item calldata _item) public onlyAuthorized {
        itemsRegistry[_item.ref] = _item;
    }

    function _setItemTitle(uint256 _itemRef, string calldata _title) public onlyAuthorized {
        itemsTitles[_itemRef] = _title;
    }

    function _setItemURI(uint256 _itemRef, string calldata _newURI) public onlyAuthorized {
        itemsURIs[_itemRef] = _newURI;
    }

    function _setItemConditions(uint256 _ref, uint32[] calldata _conditions) public onlyAuthorized {
        uint256 _oldLen = itemsConditions[_ref].length;
        uint256 _newLen = _conditions.length;
        for (
            uint256 i = 0;
            i < ((_newLen < _oldLen) ? _oldLen : _newLen);
            i++
        ) {
            if (i < ((_newLen < _oldLen) ? _newLen : _oldLen))
                itemsConditions[_ref][i] = _conditions[i];
            else if (_newLen < _oldLen) itemsConditions[_ref].pop();
            else itemsConditions[_ref].push(_conditions[i]);
        }
    }

    // // VIEW FUNCTIONS

    // Lists

    function getAllItems() public view returns (uint256[] memory) {
        return allItems;
    }

    function getActiveItems() public view returns (uint256[] memory) {
        return activeItems;
    }

    function getOldItems() public view returns (uint256[] memory) {
        return oldItems;
    }

    function getItemConditions(uint256 _ref) public view returns(uint32[] memory) {
        return itemsConditions[_ref];
    }

    // Counts

    function getAllItemsCount() public view returns (uint256) {
        return allItems.length;
    }

    function getActiveItemsCount() public view returns (uint256) {
        return activeItems.length;
    }

    function getOldItemsCount() public view returns (uint256) {
        return oldItems.length;
    }

    function getItemConditionsCount(uint256 _ref) public view returns(uint256) {
        return itemsConditions[_ref].length;
    }

    // Item data

    function getItemSupply(uint256 _itemRef) public view returns (uint256) {
        return itemsRegistry[_itemRef].supply;
    }

    function getItemTotalPurchases(uint256 _itemRef) public view returns (uint256) {
        return itemsRegistry[_itemRef].totalPurchases;
    }

    // BUYERS AND USER PURCHASES

    function getItemBuyersCount(uint256 _ref) public view returns (uint256) {
        return itemBuyers[_ref].length;
    }

    function getUserBoughtItems(address _user) public view returns (uint256[] memory) {
        return userBoughtItems[_user];
    }

    function getUserBoughtItemsCount(address _user) public view returns (uint256) {
        return userBoughtItems[_user].length;
    }

    // // LIST UPDATE FUNCTIONS

    function _targetList(uint256 _listType) internal view returns (uint256[] storage) {
        if (_listType == 0) {
            return activeItems;
        } else if (_listType == 1) {
            return oldItems;
        }
        return allItems;
    }
 
    function _forceUpdateList( 
        uint256 _listType,
        uint256 _op,
        uint256 _index,
        uint256 _value
    ) public onlyAuthorized {
        uint256[] storage _list = _targetList(_listType);
        if (_op == 0) _list.pop();
        else if (_op == 1) _list.push(_value);
        else _list[_index] = _value;
    }

    // // AUTHORIZED FUNCTIONS

    function setPausedState(bool _newState) public onlyAuthorized {
        gsPaused = _newState;
    }

    function setAdmin(address _admin, bool _newState) public onlyAuthorized {
        admins[_admin] = _newState;
    }
    
    // // OWNER FUNCTIONS 

    function setAuthorized(address _authorized, bool _newState) public onlyOwner {
        authorizedOp[_authorized] = _newState;
    }

    function setKeeper(address _keeper, bool _newState) public onlyOwner {
        keepers[_keeper] = _newState;
    }

    function setYdfContract(address _ydfContract) public onlyOwner {
        ydfContract = IERC20(_ydfContract);
    }

    function setNitConditions(address _nitConditionsContract, bool _activated) public onlyOwner {
        if(_activated) require(INitConditions(_nitConditionsContract).ready());
        nitConditionsContract = _nitConditionsContract;
        nitConditActivated = _activated;
    }

    function setDefaultItemsContract(address _newDefaultItemsContract) public onlyOwner {
        defaultItemsContract = _newDefaultItemsContract;
    }

    function setItemsVault(address _newItemsVault) public onlyOwner {
        itemsVault = _newItemsVault;
    }

    function setSigRequired(bool _sigRequiredState) public onlyOwner {
        sigRequired = _sigRequiredState;
    }

    function setSigner(address _newSigner) public onlyOwner {
        cbSigner = _newSigner;
    }

    function setKeeperAutoSync(bool _keeperAutoSync, uint256 _syncInterval) public onlyOwner {
        require(!_keeperAutoSync || _syncInterval > 0);
        keeperAutoSync = _keeperAutoSync;
        syncInterval = _syncInterval;
    }

    function setGlobalMaxAmount(uint256 _newGlobalMaxAmount) public onlyOwner {
        globalMaxAmount = _newGlobalMaxAmount;
    }

    function setCBHolder(uint256 _newCBHolder) public onlyOwner {
        cbHolder = _newCBHolder;
    }

    function withdrawYDF(address receiver, uint256 amount) public onlyOwner {
        uint256 _bal = ydfContract.balanceOf(address(this));
        ydfContract.transfer(
                (receiver != address(0)) ? receiver: owner(),
                (amount > 0) ? amount: _bal
            );
    }

    function setApproval(
        uint256 _type,
        address _assetAddress,
        address _operator,
        bool _approval,
        uint256 _allowance
    ) external onlyOwner {
        if (_type == 0) {
            IERC1155(_assetAddress).setApprovalForAll(_operator, _approval); //chType = 0
        } else if (_type == 1) {
            IERC721(_assetAddress).setApprovalForAll(_operator, _approval);
        } else if (_type == 3) {
            IERC20(_assetAddress).approve(_operator, _allowance);
        }
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