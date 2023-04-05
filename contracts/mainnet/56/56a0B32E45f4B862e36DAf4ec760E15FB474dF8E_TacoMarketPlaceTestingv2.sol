/**
 *Submitted for verification at polygonscan.com on 2023-04-05
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: contracts/MarketPlace.sol


pragma solidity ^0.8.0;






contract TacoMarketPlaceTestingv2 is Ownable, ReentrancyGuard {
    struct Item {
        address id;
        uint256 itemType; // 1: ERC721, 2: ERC1155, 3: WL spots, 4: Raffle Entry, 255: Other
        string name;
        string imageUrl;
        address contractAddress;
        uint256 tokenId;
        uint256 amount;
        uint256 totalSupply;
        uint256 purchased;
        uint[] costIds;
        uint[] costAmounts;
        uint256 numWinners;
        uint256 maxPerWallet;
        bool ended;
        bool active;
        uint256 createdAt;
    }

    struct Cost {
        uint256 id;
        address contractAddress;
        uint256 tokenId;
        uint256 costType; // 1: ERC1155, 2: ERC20
    }

    struct Order {
        address id;
        address itemId;
        address user;
        uint256 timestamp;
    }

    struct DetailOrder {
        address id;
        address user;
        Item item;
        uint256 timestamp;
    }

    struct RaffleResult {
        address id;
        address[] entries;
        address[] winners;
        Item item;
        uint256 timestamp;
        bool isReroll;
        bool isValid;
    }

    uint256 constant IT_721 = 1;
    uint256 constant IT_1155 = 2;
    uint256 constant IT_WL = 3;
    uint256 constant IT_RAFFLE = 4;
    uint256 constant IT_OTHER = 255;

    uint256 constant CT_1155 = 1;
    uint256 constant CT_20 = 2;


    uint256 randNonce = 0;
    Item[] public items;
    RaffleResult[] public raffleResults;
    address public storageWallet;
    mapping(address => Order[]) userHistory;
    mapping(address => Item) public itemsById;
    mapping(uint256 => Cost) public costs;
    mapping(address => address[]) public purchasedUsers;
    mapping(address => mapping(address => uint256)) public purchaseCount; // itemID => address => count

    constructor() {
        
    }

    function getId() internal returns(address)
    {
        return address(uint160(uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, ++randNonce)))));
    }

    function setStorageWallet(address _address) public onlyOwner {
        storageWallet = _address;
    }

    function _getIndex(address _itemId) internal view returns (uint) {
        uint index;
        for (index = 0; index < items.length; index ++){
            if (items[index].id == _itemId) {
                break;
            }
        }
        require(index < items.length, "Not found");
        return index;
    }

    function setItemProps(address _itemId, string memory _name, string memory _imageUrl) public onlyOwner {
        Item storage item = itemsById[_itemId];
        require(item.id != address(0), "Not exits");
        uint index = _getIndex(_itemId);
        bytes memory temp = bytes(_name);
        if (temp.length > 0) {
            item.name = _name;
            items[index].name = _name;
        }

        temp = bytes(_imageUrl);
        if (temp.length > 0) {
            item.imageUrl = _imageUrl;
            items[index].imageUrl = _imageUrl;
        }
    }

    function setItemActive(address _itemId, bool _active) public onlyOwner {
        Item storage item = itemsById[_itemId];
        require(item.id != address(0), "Not exits");
        uint index = _getIndex(_itemId);
        item.active = _active;
        items[index].active = _active;
    }

    function setItemEnded(address _itemId, bool _ended) public onlyOwner {
        Item storage item = itemsById[_itemId];
        require(item.id != address(0), "Not exits");
        uint index = _getIndex(_itemId);
        item.ended = _ended;
        items[index].ended = _ended;
    }

    function setItemCost(address _itemId, uint256[] memory _costIds, uint256[] memory _costAmounts) public onlyOwner {
        require(_costIds.length == _costAmounts.length, "Length error");
        Item storage item = itemsById[_itemId];
        require(item.id != address(0), "Not exits");
        uint index = _getIndex(_itemId);
        item.costIds = _costIds;
        item.costAmounts = _costAmounts;
        items[index].costIds = _costIds;
        items[index].costAmounts = _costAmounts;
    }

    function createCost(uint256 _costId, uint256 _costType, address _contractAddress, uint256 _tokenId) public onlyOwner {
        costs[_costId] = Cost(_costId, _contractAddress, _tokenId, _costType);
    }

    function add721TokenItem(string memory _name, string memory _imageUrl, address _contractAddress, uint256 _tokenId, uint256[] memory _costIds, uint256[] memory _costAmounts, bool _active) public onlyOwner {
        require(_costIds.length == _costAmounts.length, "Array Error");
        address itemId = getId();
        Item memory newItem = Item(itemId, IT_721, _name, _imageUrl, _contractAddress, _tokenId, 1, 1, 0, _costIds ,_costAmounts, 0, 1, false, _active, block.timestamp);
        itemsById[itemId] = newItem;
        items.push(newItem);
    }

    function add1155TokenItem(string memory _name, string memory _imageUrl, address _contractAddress, uint256 _tokenId, uint256 _amount, uint256 _totalSupply, uint256[] memory _costIds, uint256[] memory _costAmounts, uint256 _maxPerWallet, bool _active) public onlyOwner {
        require(_costIds.length == _costAmounts.length, "Array Error");
        address itemId = getId();
        Item memory newItem = Item(itemId, IT_1155, _name, _imageUrl, _contractAddress, _tokenId, _amount, _totalSupply, 0, _costIds ,_costAmounts, 0, _maxPerWallet, false, _active, block.timestamp);
        itemsById[itemId] = newItem;
        items.push(newItem);
    }

    function addWLItem(string memory _name, string memory _imageUrl, uint256 _totalSupply, uint256[] memory _costIds, uint256[] memory _costAmounts, uint256 _maxPerWallet, bool _active) public onlyOwner {
        require(_costIds.length == _costAmounts.length, "Array Error");
        address itemId = getId();
        Item memory newItem = Item(itemId, IT_WL, _name, _imageUrl, address(0), 0, 0, _totalSupply, 0, _costIds ,_costAmounts, 0, _maxPerWallet, false, _active, block.timestamp);
        itemsById[itemId] = newItem;
        items.push(newItem);
    }

    function addRaffleEntryItem(string memory _name, string memory _imageUrl, uint256 _totalSupply, uint256[] memory _costIds, uint256[] memory _costAmounts, uint256 _numWinners, uint256 _maxPerWallet, bool _active) public onlyOwner {
        require(_costIds.length == _costAmounts.length, "Array Error");
        address itemId = getId();
        Item memory newItem = Item(itemId, IT_RAFFLE, _name, _imageUrl, address(0), 0, 0, _totalSupply, 0, _costIds ,_costAmounts, _numWinners, _maxPerWallet, false, _active, block.timestamp);
        itemsById[itemId] = newItem;
        items.push(newItem);
    }

    function removeItem(address _itemId) public onlyOwner {
        Item storage item = itemsById[_itemId];
        require(item.id != address(0), "Not exists");
        uint index = _getIndex(_itemId);
        items[index] = items[(items.length - 1)];
        items.pop();

        item.id = address(0);
        item.name = "";
        item.imageUrl = "";
        item.contractAddress = address(0);
        item.tokenId = 0;
        item.amount = 0;
        item.purchased = 0;
        item.active = false;
    }

    function getItems(uint cursor, uint limit) public view returns (Item[] memory, uint) {
        uint256 len = limit;
        uint itemsLength = 0;
        for (uint index = 0; index < items.length; index ++) {
            if (isValidItem(items[index].id)) {
                itemsLength++;
            }
        }

        if (len > itemsLength - cursor) {
            len = itemsLength - cursor;
        }

        Item[] memory temp = new Item[](len);
        if (itemsLength == 0) {
            return (temp, 0);
        }

        uint count = 0;
        while(true) {
            if (count >= len) {
                break;
            }
            Item memory item = items[(itemsLength - 1) - (cursor + count)];
            if (isValidItem(item.id)) {
                temp[count] = item;
                count++;
            }
        }

        return (temp, cursor + len);
    }


    function beforePurchase(address _itemId) internal view {
        Item memory item = itemsById[_itemId];
        require(isValidItem(_itemId), "Invalid Item");
        require(item.purchased < item.totalSupply, "Already sold out");
        require(item.maxPerWallet > getPurchaseCount(_itemId, msg.sender), "Already purchased");
    }

    function isValidItem(address _itemId) internal view returns (bool) {
        Item memory item = itemsById[_itemId];
        if(item.id == address(0)) return false;
        if(item.itemType == 0) return false;
        if(item.costIds.length == 0) return false;
        if(item.costAmounts.length == 0) return false;
        if(item.costAmounts.length != item.costIds.length) return false;
        if(!item.active) return false;
        if (item.itemType == IT_721) {
            if(!IERC721(item.contractAddress).isApprovedForAll(storageWallet, address(this))) return false;
        } else if (item.itemType == IT_1155) {
            if(!IERC1155(item.contractAddress).isApprovedForAll(storageWallet, address(this))) return false;
        }
        return true;
    }

    function getPurchaseCount(address _itemId, address _user) public view returns (uint256) {
        return purchaseCount[_itemId][_user];
    }

    function isPurchased(address _itemId, address _user) public view returns (bool) {
        return getPurchaseCount(_itemId, _user) > 0;
    }

    function purchase(address _itemId, uint256 _amount) public {
        for (uint index = 0; index < _amount; index ++) {
            purchase(_itemId);
        }
    }

    function purchase(address _itemId) public {
        beforePurchase(_itemId);
        Item storage item = itemsById[_itemId];
        for (uint i=0; i<item.costIds.length; i++) {
            Cost memory cost = costs[item.costIds[i]];
            require(cost.id != 0 && cost.costType != 0, "Invalid cost");
            uint256 costAmount = item.costAmounts[i];
            if (costAmount > 0) {
                if (cost.costType == CT_1155) {
                    IERC1155 costContract = IERC1155(cost.contractAddress);
                    require(costContract.isApprovedForAll(msg.sender, address(this)), "Approve error");
                    require(costContract.balanceOf(msg.sender, cost.tokenId) >= costAmount, "Balance error");
                    costContract.safeTransferFrom(msg.sender, storageWallet, cost.tokenId, costAmount, "");
                } else if (cost.costType == CT_20){
                    IERC20 costContract = IERC20(cost.contractAddress);
                    require(costContract.balanceOf(msg.sender) >= costAmount, "Balance error");
                    require(costContract.allowance(msg.sender, address(this)) >= costAmount, "Approve error");
                    costContract.transferFrom(msg.sender, storageWallet, costAmount);
                }
            }
        }

        if (item.itemType == IT_721) {
            IERC721(item.contractAddress).safeTransferFrom(storageWallet, msg.sender, item.tokenId);
        } else if (item.itemType == IT_1155) {
            IERC1155(item.contractAddress).safeTransferFrom(storageWallet, msg.sender, item.tokenId, item.amount, "");
        }

        uint index = _getIndex(_itemId);
        items[index].purchased++;
        item.purchased++;
        purchasedUsers[_itemId].push(msg.sender);
        purchaseCount[_itemId][msg.sender]++;
        Order memory order = Order(getId(), _itemId, msg.sender, block.timestamp);
        userHistory[msg.sender].push(order);
    }

    function getHistory(address _user, uint cursor, uint limit) public view returns (DetailOrder[] memory, uint) {
        uint256 len = limit;
        uint historyLength = userHistory[_user].length;
        if (len > historyLength - cursor) {
            len = historyLength - cursor;
        }

        DetailOrder[] memory temp = new DetailOrder[](len);
        if (historyLength == 0) {
            return (temp, 0);
        }

        for (uint256 i = 0; i < len; i++) {
            Order memory order = userHistory[_user][(historyLength - 1) - (cursor + i)];
            temp[i] = DetailOrder(order.id, order.user, itemsById[order.itemId], order.timestamp);
        }

        return (temp, cursor + len);
    }

    function getPurchasedUser(address _itemId, uint cursor, uint limit) public view returns (address[] memory, uint) {
        uint256 len = limit;
        uint listLength = purchasedUsers[_itemId].length;
        if (len > listLength - cursor) {
            len = listLength - cursor;
        }

        address[] memory temp = new address[](len);
        if (listLength == 0) {
            return (temp, 0);
        }

        for (uint256 i = 0; i < len; i++) {
            temp[i] = purchasedUsers[_itemId][(listLength - 1) - (cursor + i)];
        }

        return (temp, cursor + len);
    }

    function pickRaffleWinners(address _itemId, bool _forcePick) public onlyOwner {
        Item memory item = itemsById[_itemId];
        require(item.itemType == IT_RAFFLE, "Not a raffle");
        require(getRafflePickCount(_itemId) == 0, "Raffle error");
        require(_forcePick || item.totalSupply == item.purchased, "Still accepting entries");
        setItemEnded(_itemId, true);
        _pick(item, false);
    }

    function rerollRaffleWinners(address _itemId) public onlyOwner {
        Item memory item = itemsById[_itemId];
        require(item.itemType == IT_RAFFLE, "Not a raffle");
        require(getRafflePickCount(_itemId) > 0, "Raffle error");
        _pick(item, true);
    }

    function _pick(Item memory _item, bool _isReroll) internal {
        address[] memory entries = purchasedUsers[_item.id];
        address[] memory tempWinners = new address[](_item.numWinners);
        RaffleResult memory result;
        result.id = getId();
        result.item = _item;
        result.timestamp = block.timestamp;
        result.entries = entries;
        result.isValid = true;
        result.isReroll = _isReroll;
        entries = _shuffle(entries);

        if (_isReroll) {
            for (uint index = 0; index < raffleResults.length; index++) {
                if (raffleResults[index].item.id == _item.id) {
                    raffleResults[index].isValid = false;
                }
            }
        }

        uint count = 0;
        for (uint index = 0; index < entries.length; index++) {
            bool found = false;
            address entry = entries[index];
            for (uint i=0; i < tempWinners.length; i++) {
                if(tempWinners[i] == entry){
                    found=true;
                    break;
                }
            }
            if (!found) {
                tempWinners[count] = entry;
                count++;
            }
            if (count >= _item.numWinners) {
                break;
            }
        }
        result.winners = tempWinners;
        raffleResults.push(result);
    }

    function getRafflePickCount(address _itemId) public view returns (uint) {
        uint count = 0;
        for (uint index = 0; index < raffleResults.length; index++) {
            if (raffleResults[index].item.id == _itemId) {
                count++;
            }
        }
        return count;
    }

    function getRaffleResults(uint cursor, uint limit) public view returns (RaffleResult[] memory, uint) {
        uint256 len = limit;
        if (len > raffleResults.length - cursor) {
            len = raffleResults.length - cursor;
        }

        RaffleResult[] memory temp = new RaffleResult[](len);
        if (raffleResults.length == 0) {
            return (temp, 0);
        }

        for (uint256 i = 0; i < len; i++) {
            temp[i] = raffleResults[(raffleResults.length - 1) - (cursor + i)];
        }

        return (temp, cursor + len);
    }

    function _shuffle(address[] memory numberArr) internal view returns (address[] memory) {
        for (uint256 i = 0; i < numberArr.length; i++) {
            uint256 n = i + uint256(keccak256(abi.encodePacked(block.timestamp))) % (numberArr.length - i);
            address temp = numberArr[n];
            numberArr[n] = numberArr[i];
            numberArr[i] = temp;
        }
        return numberArr;
    }
}