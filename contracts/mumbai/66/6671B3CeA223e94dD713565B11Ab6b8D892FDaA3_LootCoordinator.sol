//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '../../../utils/Controllable.sol';
import '../../coordinators/InventoryCoordinator/IInventoryCoordinator.sol';
import '../../coordinators/InventoryCoordinator/IInventoryEntityContract.sol';
import '../../coordinators/InventoryCoordinator/IInventoryItemContract.sol';
import '../../../tokens/rewards/ILootItem.sol';
import '../../../tokens/IPxlbot.sol';
import './ILootCoordinator.sol';

contract LootCoordinator is
  IERC721Receiver,
  Controllable,
  IInventoryEntityContract,
  ILootCoordinator
{
  event LootReserved(Entity owner, uint256 index);
  event LootFilled(Entity owner, uint256 reservation_index, uint256 loot_index);
  event LootSent(uint256 tokenId, uint256 loot_index, uint16 amount);

  IPxlbot pxlbot;
  IInventoryCoordinator inventoryCoordinator;
  Entity this_entity = Entity({ _contract: this, id: 1 });

  //array of of ERC721 contracts that can create loot
  ILootItem[] private loot;
  //keeping track of loot contracts so we don't get repeats
  mapping(address => uint256) private loot_indices;
  //array of tokenIds that are waiting to receive loot
  Entity[] private reservations;

  // mapping(uint256 => ILootItem[]) private awards_filled;

  constructor(IPxlbot _pxlbot, IInventoryCoordinator _inventoryCoordinator) {
    pxlbot = _pxlbot;
    inventoryCoordinator = _inventoryCoordinator;
  }

  function reserve(Entity memory entity)
    external
    payable
    override
    onlyController
  {
    reservations.push(entity);
    emit LootReserved(entity, reservations.length);
  }

  function getReservations()
    external
    view
    onlyController
    returns (Entity[] memory)
  {
    return reservations;
  }

  //this function gets called by an outside entity, so that it can remain a surprise
  function fill(uint256 reservation_index, uint256 loot_index)
    external
    payable
    override
    onlyController
  {
    Entity storage entity = reservations[reservation_index];
    loot[loot_index].mint(1, address(this));
    uint256 loot_token_Id = loot[loot_index].totalSupply();
    Item memory item = Item(
      IInventoryItemContract(address(loot[loot_index])),
      loot_token_Id
    );
    //have to add it to the game from here before we can transfer it
    inventoryCoordinator.addItemToGame(item, this_entity, 1);
    inventoryCoordinator.inGameTransfer(this_entity, entity, item, 1);
    //remove item from array (https://ethereum.stackexchange.com/posts/59234/revisions)
    reservations[reservation_index] = reservations[reservations.length - 1];
    reservations.pop();
    emit LootFilled(entity, reservation_index, loot_index);
  }

  function makeLoot(
    uint256 loot_index,
    uint16 amount,
    uint256 tokenId
  ) internal returns (uint256[] memory) {
    uint256[] memory token_ids = loot[loot_index].mint(amount, address(this));
    //we have to add them each individually
    for (uint256 i = 0; i < token_ids.length; i++) {
      Item memory lootItem = Item(
        IInventoryItemContract(address(loot[loot_index])),
        token_ids[i]
      );
      //we don't have to transfer this because the mission system does it automatically as a reward
      inventoryCoordinator.addItemToGame(lootItem, this_entity, 1);
    }
    // do we want this event?
    // emit LootSent(tokenId, loot_index, amount);
    return token_ids;
  }

  function addLootContract(address _contract)
    external
    payable
    override
    onlyController
  {
    require(
      loot_indices[_contract] == 0,
      'LootCoordinator: contract already added'
    );
    loot.push(ILootItem(_contract));
    //so this contract can transfer tokens from the originating contract
    ILootItem(_contract).setApprovalForAll(address(inventoryCoordinator), true);
    loot_indices[_contract] = loot.length;
  }

  function lootContracts() external view returns (ILootItem[] memory) {
    return loot;
  }

  //this function creates a reward by taking a combination of weighted scores (based on factors) then minting and transferring a given amount of ERC721 tokens
  function getReward(
    uint256 botId,
    uint256,
    uint256 score,
    uint256 totalPossible,
    uint256 bounty,
    int16 loot_index
  ) external override onlyController returns (Reward memory) {
    require(loot_index > -1, 'Loot index must be set');

    uint256 loot_index_cast = uint256(int256(loot_index));

    uint256 rewardAmount;
    //we don't divide ERC721 tokens by attributes
    if (score == totalPossible) {
      rewardAmount = 1;
    }
    if (bounty > 0) {
      rewardAmount += bounty;
    }
    uint256[] memory token_ids = makeLoot(
      loot_index_cast,
      uint16(rewardAmount),
      botId
    );
    Item[] memory items = new Item[](token_ids.length);
    uint256[] memory amounts = new uint256[](token_ids.length);
    for (uint256 i = 0; i < items.length; i++) {
      items[i] = Item({
        _contract: IInventoryItemContract(address(loot[loot_index_cast])),
        id: token_ids[i]
      });
      amounts[i] = 1;
    }

    return
      Reward({
        from: this_entity,
        to: Entity({ _contract: pxlbot, id: botId }),
        items: items,
        amounts: amounts,
        subject_to_tribute: false
      });
  }

  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) public pure override returns (bytes4) {
    return this.onERC721Received.selector;
  }

  function irlOwner(uint256) external view override returns (address) {
    return address(this);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';

abstract contract Controllable is Ownable {
  mapping(address => bool) private _controllers;
  /**
   * @dev Initializes the contract setting the deployer as a controller.
   */
  constructor() {
    _addController(_msgSender());
  }

  modifier mutualControllersOnly(address _caller) {
    Controllable caller = Controllable(_caller);
    require(_controllers[_caller] && caller.isController(address(this)), 'Controllable: not mutual controllers');
    _;
  }

  /**
   * @dev Returns true if the address is a controller.
   */
  function isController(address controller) public view virtual returns (bool) {
    return _controllers[controller];
  }

  /**
   * @dev Throws if called by any account that isn't a controller
   */
  modifier onlyController() {
    require(_controllers[_msgSender()], "Controllable: not controller");
    _;
  }

  modifier nonZero(address a) {
    require(a != address(0), "Controllable: input is zero address");
    _;
  }

  /**
   * @dev Adds a new controller.
   * Can only be called by the current owner.
   */
  function addController(address c) public virtual onlyOwner nonZero(c) {
     _addController(c);
  }

  /**
   * @dev Adds a new controller.
   * Internal function without access restriction.
   */
  function _addController(address newController) internal virtual {
    _controllers[newController] = true;
  }

    /**
   * @dev Removes a controller.
   * Can only be called by the current owner.
   */
  function removeController(address c) public virtual onlyOwner nonZero(c) {
     _removeController(c);
  }
  
  /**
   * @dev Removes a controller.
   * Internal function without access restriction.
   */
  function _removeController(address controller) internal virtual {
    delete _controllers[controller];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import './IInventoryEntityContract.sol';
import './IInventoryItemContract.sol';
import '../../models/Inventory.sol';

interface IInventoryCoordinator is InventoryTypesUser {
  function addItemToGame(
    Item memory game_item,
    Entity memory owner_entity,
    uint256 amount
  ) external;

  function removeItemFromGame(
    Item memory game_item,
    Entity memory owner_entity,
    uint256 amount
  ) external;

  function inGameTransfer(
    Entity memory _from,
    Entity memory _to,
    Item memory _item,
    uint256 _amount
  ) external;

  function balance(Entity memory _entity, Item memory item)
    external
    returns (uint256);

  function addApprovedItemType(IInventoryItemContract collection) external;

  function removeApprovedItemType(IInventoryItemContract collection) external;

  function addApprovedEntityType(IInventoryEntityContract entity) external;

  function removeApprovedEntityType(IInventoryEntityContract entity) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

//defines an "Entity" that can hold an item in inventory (e.g. a pxlbot; consisting of pxlbot contract address and a token ID)
interface IInventoryEntityContract {
  // Base id is determined by the contract. Examples might be tokenId in an ERC721 or simply putting 1 for ERC20
  function irlOwner(uint256 _baseId) external returns (address);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

//defines contracts for "Items" that can be held in inventory (e.g. PXL, an ERC721 token, etc.)
interface IInventoryItemContract {
  // Base id is determined by the contract. Examples might be tokenId in an ERC721 or simply putting 1 for ERC20
  function irlBalance(uint256 baseId, address owner) external returns (uint256);

  function inventoryItemTransfer(
    uint256 baseId,
    uint256 amount,
    address from,
    address to
  ) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import 'erc721a/contracts/interfaces/IERC721AQueryable.sol';

interface ILootItem is IERC721AQueryable {
  function mint(uint256 amount, address to)
    external
    payable
    returns (uint256[] memory);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import 'erc721a/contracts/interfaces/IERC721AQueryable.sol';
import '../gameplay/coordinators/InventoryCoordinator/IInventoryEntityContract.sol';
import '../gameplay/coordinators/AttributeCoordinator/IAttributeCoordinator.sol';
import './IERC721APlayable.sol';

interface IPxlbot is
  IInventoryEntityContract,
  IAttributeCoordinator,
  IERC721AQueryable,
  IERC721APlayable
{
  function mint(uint256 amount, address to) external payable;

  function mintScion(
    address to,
    uint256 parent_id,
    string[] memory attrsIds,
    uint32[] memory attrsVals
  ) external payable;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import '../../models/Inventory.sol';
import '../../missions/MissionBudgets/IMissionBudget.sol';

interface ILootCoordinator is InventoryTypesUser, IMissionBudget {
  function reserve(Entity memory owner) external payable;

  function fill(uint256 reservation_index, uint256 loot_index) external payable;

  function addLootContract(address _contract) external payable;
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import '../coordinators/InventoryCoordinator/IInventoryEntityContract.sol';
import '../coordinators/InventoryCoordinator/IInventoryItemContract.sol';

//Entity is a contract that can "hold" an inventory (doesn't actually hold it, it's represented in the InventoryCoordinator)
// In the case of PXL, it's the MissionPxlBudget contract. In the case of ERC721 rewards, it's the LootCoordinator.
//item is the thing that goes in the inventory (e.g. PXL or ERC721 token)
interface InventoryTypesUser {
  struct Entity {
    IInventoryEntityContract _contract;
    uint256 id;
  }

  struct Item {
    IInventoryItemContract _contract;
    uint256 id;
  }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v3.3.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '../extensions/IERC721AQueryable.sol';

// SPDX-License-Identifier: MIT
// ERC721A Contracts v3.3.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '../IERC721A.sol';

/**
 * @dev Interface of an ERC721AQueryable compliant contract.
 */
interface IERC721AQueryable is IERC721A {
    /**
     * Invalid query range (`start` >= `stop`).
     */
    error InvalidQueryRange();

    /**
     * @dev Returns the `TokenOwnership` struct at `tokenId` without reverting.
     *
     * If the `tokenId` is out of bounds:
     *   - `addr` = `address(0)`
     *   - `startTimestamp` = `0`
     *   - `burned` = `false`
     *
     * If the `tokenId` is burned:
     *   - `addr` = `<Address of owner before token was burned>`
     *   - `startTimestamp` = `<Timestamp when token was burned>`
     *   - `burned = `true`
     *
     * Otherwise:
     *   - `addr` = `<Address of owner>`
     *   - `startTimestamp` = `<Timestamp of start of ownership>`
     *   - `burned = `false`
     */
    function explicitOwnershipOf(uint256 tokenId) external view returns (TokenOwnership memory);

    /**
     * @dev Returns an array of `TokenOwnership` structs at `tokenIds` in order.
     * See {ERC721AQueryable-explicitOwnershipOf}
     */
    function explicitOwnershipsOf(uint256[] memory tokenIds) external view returns (TokenOwnership[] memory);

    /**
     * @dev Returns an array of token IDs owned by `owner`,
     * in the range [`start`, `stop`)
     * (i.e. `start <= tokenId < stop`).
     *
     * This function allows for tokens to be queried if the collection
     * grows too big for a single call of {ERC721AQueryable-tokensOfOwner}.
     *
     * Requirements:
     *
     * - `start` < `stop`
     */
    function tokensOfOwnerIn(
        address owner,
        uint256 start,
        uint256 stop
    ) external view returns (uint256[] memory);

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(totalSupply) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K pfp collections should be fine).
     */
    function tokensOfOwner(address owner) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v3.3.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';

/**
 * @dev Interface of an ERC721A compliant contract.
 */
interface IERC721A is IERC721, IERC721Metadata {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * The caller cannot approve to their own address.
     */
    error ApproveToCaller();

    /**
     * The caller cannot approve to the current owner.
     */
    error ApprovalToCurrentOwner();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    // Compiler will pack this into a single 256bit word.
    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
    }

    // Compiler will pack this into a single 256bit word.
    struct AddressData {
        // Realistically, 2**64-1 is more than enough.
        uint64 balance;
        // Keeps track of mint count with minimal overhead for tokenomics.
        uint64 numberMinted;
        // Keeps track of burn count with minimal overhead for tokenomics.
        uint64 numberBurned;
        // For miscellaneous variable(s) pertaining to the address
        // (e.g. number of whitelist mint slots used).
        // If there are multiple variables, please pack them into a uint64.
        uint64 aux;
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     * 
     * Burned tokens are calculated here, use `_totalMinted()` if you want to count just minted tokens.
     */
    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IAttributeCoordinator {
    function attributeValues(uint256 botId, string[] memory attrIds) external returns(uint32[] memory);
    function setAttributeValues(uint256 botId, string[] memory attrIds, uint32[] memory values) external;
    function totalPossible() external returns(uint32);
    function getAttrIds() external returns (string[] memory);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import 'erc721a/contracts/interfaces/IERC721AQueryable.sol';
import '../gameplay/coordinators/GameplayCoordinator/IGameplayCoordinator.sol';

interface IERC721APlayable is IERC721AQueryable {
    function addTokenToGameplay(uint256 id) external;
    function removeTokenFromGameplay(uint256 id) external;
    function isTokenInPlay(uint256 tokenId) external view returns(bool);
    function setGameplayCoordinator(IGameplayCoordinator c) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IGameplayCoordinator {
    function isBotBusy(uint256 id) external returns(bool);
    function makeBotBusy(uint256 botId) external;
    function makeBotUnbusy(uint256 botId) external;
    function isBotInGame(uint256 botId) external returns(bool);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import '../../models/Missions.sol';

interface IMissionBudget is MissionTypesUser {
  function getReward(
    uint256 botId,
    uint256 missionId,
    uint256 score,
    uint256 totalPossible,
    uint256 bounty,
    int16 loot_index
  ) external returns (Reward memory);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import './Inventory.sol';

interface MissionTypesUser is InventoryTypesUser {
  enum Status {
    COMPLETED,
    CANCELED
  }

  struct Result {
    uint256 missionId;
    uint80 start;
    uint80 end;
    Status status;
  }

  struct RewardHistoryItem {
    Item item;
    uint256 missionId;
  }

  struct Reward {
    Entity from;
    Entity to;
    Item[] items;
    uint256[] amounts;
    bool subject_to_tribute;
  }

  struct AirdropMissionData {
    uint256 _id;
    string origin;
    string destination;
    uint8 reward;
    int16 loot_index;
    string metadata;
  }
}