//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import '../../../utils/Controllable.sol';
import './IInventoryEntityContract.sol';
import './IInventoryItemContract.sol';
import './IInventoryCoordinator.sol';

contract InventoryCoordinator is IInventoryCoordinator, Controllable {
  mapping(IInventoryItemContract => bool) private approvedInventory;
  mapping(IInventoryEntityContract => bool) private approvedEntities;

  // holder address => holder id => item address => item id => total item amount
  mapping(address => mapping(uint256 => mapping(address => mapping(uint256 => uint256)))) entityItems;

  // for tracking item type balances
  mapping(address => mapping(uint256 => mapping(address => uint256))) entityTypeBalances;

  // for tracking ids owned
  // owner address => owner id => item address => array of item ids
  mapping(address => mapping(uint256 => mapping(address => uint256[]))) entityTypeIds;

  // for tracking ids' indices
  // owner address => owner id => item address => item id => index
  mapping(address => mapping(uint256 => mapping(address => mapping(uint256 => uint256)))) entityTypeIdIndices;

  // Modifiers
  modifier ownsEntity(Entity memory _entity) {
    address _owner = _entity._contract.irlOwner(_entity.id);
    require(_msgSender() == _owner, 'BaseInventoryLedger: does not own entity');
    _;
  }

  modifier ownsOrIsEntity(Entity memory _entity) {
    address _owner = _entity._contract.irlOwner(_entity.id);
    require(
      _msgSender() == _owner || _msgSender() == address(_entity._contract),
      'BaseInventoryLedger: does not own entity'
    );
    _;
  }

  modifier approvedEntitiesOnly(IInventoryEntityContract _address) {
    require(
      approvedEntities[_address],
      'BaseInventoryLedger: not approved entity'
    );
    _;
  }

  modifier approvedItemsOnly(IInventoryItemContract _address) {
    require(
      approvedInventory[_address],
      'BaseInventoryLedger: not approved item'
    );
    _;
  }

  modifier hasSufficientItemBalance(Item memory item, uint256 amount) {
    require(
      item._contract.irlBalance(item.id, _msgSender()) >= amount,
      'BaseInventoryLedger: does not have sufficient item balance'
    );
    _;
  }

  //game_item is the thing in the inventory to be added (e.g. PXL)
  //owner_entity is the in-game entity that claims the inventory (e.g. Pxlbot)
  //amount is how much of the item to be added
  //this function doesn't need to track original ownership because it only carries a total balance and then transfers from that balance when removed
  function addItemToGame(
    Item memory game_item,
    Entity memory owner_entity,
    uint256 amount
  )
    external
    override
    approvedEntitiesOnly(owner_entity._contract)
    ownsOrIsEntity(owner_entity)
    approvedItemsOnly(IInventoryItemContract(game_item._contract))
    hasSufficientItemBalance(game_item, amount)
  {
    //transfer item to this contract
    game_item._contract.inventoryItemTransfer(
      game_item.id,
      amount,
      _msgSender(),
      address(this)
    );
    //store the item count as a balance
    entityItems[address(owner_entity._contract)][owner_entity.id][
      address(game_item._contract)
    ][game_item.id] += amount;

    addItemToBalances(game_item, owner_entity, amount);
  }

  // game_item is the thing in the inventory to be removed (e.g. PXL)
  // owner_entity is the in-game entity claims the inventory (e.g. Pxlbot)
  // amount is how much of the item to be removed
  function removeItemFromGame(
    Item memory game_item,
    Entity memory owner_entity,
    uint256 amount
  )
    external
    override
    approvedEntitiesOnly(owner_entity._contract)
    approvedItemsOnly(game_item._contract)
    ownsEntity(owner_entity)
  {
    require(
      entityItems[address(owner_entity._contract)][owner_entity.id][
        address(game_item._contract)
      ][game_item.id] >= amount,
      'BaseInventoryLedger: entity does not have sufficient item balance'
    );

    entityItems[address(owner_entity._contract)][owner_entity.id][
      address(game_item._contract)
    ][game_item.id] -= amount;

    removeItemFromBalances(game_item, owner_entity, amount);

    game_item._contract.inventoryItemTransfer(
      game_item.id,
      amount,
      address(this),
      _msgSender()
    );
  }

  // In game transfers
  //_item is the thing in the inventory (e.g. PXL)
  //_from is the entity that has the item (e.g. pxl contract address)
  //_to is the entity that will receive the item (e.g. pxlbot contract address, token ID)
  //_amount is how much of the item will be transferred
  function inGameTransfer(
    Entity memory _from,
    Entity memory _to,
    Item memory _item,
    uint256 _amount
  ) external override onlyController {
    require(
      entityItems[address(_from._contract)][_from.id][address(_item._contract)][
        _item.id
      ] >= _amount,
      'BaseInventoryLedger: entity does not have sufficient item balance'
    );
    entityItems[address(_from._contract)][_from.id][address(_item._contract)][
      _item.id
    ] -= _amount;
    entityItems[address(_to._contract)][_to.id][address(_item._contract)][
      _item.id
    ] += _amount;

    removeItemFromBalances(_item, _from, _amount);
    addItemToBalances(_item, _to, _amount);
  }

  function balance(Entity memory owner, Item memory item)
    public
    view
    override
    returns (uint256)
  {
    return
      entityItems[address(owner._contract)][owner.id][address(item._contract)][
        item.id
      ];
  }

  function balanceOfType(Entity memory owner, address _type)
    public
    view
    returns (uint256)
  {
    return entityTypeBalances[address(owner._contract)][owner.id][_type];
  }

  // way to query the balance of a particular entity where the ids aren't known (ERC721) by an outside party
  function idsOwnedOfItem(Entity memory owner, address item_address)
    public
    view
    returns (uint256[] memory)
  {
    uint256[] storage s_ids = entityTypeIds[address(owner._contract)][owner.id][
      item_address
    ];
    uint256[] memory ids = new uint256[](s_ids.length);
    for (uint256 i = 0; i < s_ids.length; i++) {
      ids[i] = s_ids[i];
    }
    return ids;
  }

  function addItemToBalances(
    Item memory item,
    Entity memory owner,
    uint256 amount
  ) internal {
    //store the total balance of the type
    entityTypeBalances[address(owner._contract)][owner.id][
      address(item._contract)
    ] += amount;

    //store the id of the item for querying (only if it's not already there)
    if (
      entityTypeIdIndices[address(owner._contract)][owner.id][
        address(item._contract)
      ][item.id] == 0
    ) {
      entityTypeIds[address(owner._contract)][owner.id][address(item._contract)]
        .push(item.id);

      //store the index of the id just added (don't subtract 1 b/c we don't want 0 as a default index)
      entityTypeIdIndices[address(owner._contract)][owner.id][
        address(item._contract)
      ][item.id] = entityTypeIds[address(owner._contract)][owner.id][
        address(item._contract)
      ].length;
    }
  }

  function removeItemFromBalances(
    Item memory item,
    Entity memory owner,
    uint256 amount
  ) internal {
    //store the total balance of the type
    entityTypeBalances[address(owner._contract)][owner.id][
      address(item._contract)
    ] -= amount;

    //only unset the Id index if the balance of this particular item is zero
    if (
      entityItems[address(owner._contract)][owner.id][address(item._contract)][
        item.id
      ] == 0
    ) {
      uint256 index = entityTypeIdIndices[address(owner._contract)][owner.id][
        address(item._contract)
      ][item.id];

      uint256[] storage ids = entityTypeIds[address(owner._contract)][owner.id][
        address(item._contract)
      ];
      // see where these are added for why the -1
      ids[index - 1] = ids[ids.length - 1];
      ids.pop();

      entityTypeIdIndices[address(owner._contract)][owner.id][
        address(item._contract)
      ][item.id] = 0;
    }
  }

  // Admin for approved inventory and entities
  function addApprovedItemType(IInventoryItemContract _collection)
    public
    override
    onlyController
  {
    approvedInventory[_collection] = true;
  }

  function removeApprovedItemType(IInventoryItemContract _collection)
    public
    override
    onlyController
  {
    approvedInventory[_collection] = false;
  }

  function addApprovedEntityType(IInventoryEntityContract _entity)
    external
    override
    onlyController
  {
    approvedEntities[_entity] = true;
  }

  function removeApprovedEntityType(IInventoryEntityContract _entity)
    external
    override
    onlyController
  {
    approvedEntities[_entity] = false;
  }
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