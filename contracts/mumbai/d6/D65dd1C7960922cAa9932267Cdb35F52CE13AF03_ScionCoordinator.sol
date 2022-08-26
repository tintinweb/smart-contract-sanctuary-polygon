//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '../../tokens/PXL.sol';
import '../../utils/Controllable.sol';
import '../../gameplay/coordinators/InventoryCoordinator/IInventoryCoordinator.sol';
import '../../gameplay/models/Inventory.sol';
import './IScionCoordinator.sol';

contract ScionCoordinator is
  Ownable,
  Controllable,
  InventoryTypesUser,
  IScionCoordinator
{
  IPXL pxl;
  IInventoryCoordinator inventory;

  //need to keep track of addresses for tributes
  mapping(uint256 => address) public parent_owners;
  //maps tokenIds to their indices in the ordered_tokens array
  mapping(uint256 => uint256) public token_indices;
  //this keeps the tokens in order that they appear so we can properly give priority to the first tokens added
  uint256[] public ordered_parents;
  uint256 public total_parents;

  uint256 public current_parent_index = 0;

  //for keeping track of scion attributes for minting
  //maps tokenIds to attribute ids, values
  mapping(uint256 => string[]) public parent_attribute_ids;
  mapping(uint256 => uint32[]) public parent_attribute_values;

  //maps scions to their parents
  mapping(uint256 => uint256) public scion_parents;
  //maps scions to their children
  mapping(uint256 => uint256[]) public parent_scions;
  uint256 public default_tribute_percentage = 10;
  //maps scions to their tribute amounts (assuming they may vary)
  mapping(uint256 => uint256) public tribute_percentages;
  //every time a bot receives a pxl tribute, the contract receives it and the number is stored here
  mapping(uint256 => uint256) public pxl_tribute_amounts;

  constructor(IPXL _pxl, IInventoryCoordinator _inventory) {
    pxl = _pxl;
    inventory = _inventory;
  }

  function addParent(
    uint256 parent_id,
    string[] memory attr_ids,
    uint32[] memory attr_vals,
    address owner
  ) external payable override {
    if (token_indices[parent_id] == 0) {
      parent_attribute_ids[parent_id] = attr_ids;
      parent_attribute_values[parent_id] = attr_vals;
      ordered_parents.push(parent_id);
      token_indices[parent_id] = ordered_parents.length;
      total_parents++;
      parent_owners[parent_id] = owner;
    }
  }

  function removeParent(uint256 parent_id) external payable override {
    if (token_indices[parent_id] != 0) {
      delete ordered_parents[token_indices[parent_id] - 1];
      delete token_indices[parent_id];
      total_parents--;
    }
  }

  function parentOwnerChanged(uint256 parent_id, address new_owner)
    external
    payable
    override
  {
    parent_owners[parent_id] = new_owner;
  }

  function getParent(uint256 parent_id)
    external
    view
    override
    returns (string[] memory, uint32[] memory)
  {
    return (
      parent_attribute_ids[parent_id],
      parent_attribute_values[parent_id]
    );
  }

  function allParents() external view returns (uint256[] memory) {
    return ordered_parents;
  }

  function totalParents() external view override returns (uint256) {
    return total_parents;
  }

  function removeAllParents() external onlyController {
    for (uint256 i = 0; i < ordered_parents.length; i++) {
      delete token_indices[ordered_parents[i]];
    }
    delete ordered_parents;
    total_parents = 0;
  }

  function selectParent()
    external
    view
    override
    onlyController
    returns (
      uint256 token,
      string[] memory attr_ids,
      uint32[] memory attr_values
    )
  {
    uint256 parent_id = ordered_parents[current_parent_index];
    return (
      parent_id,
      parent_attribute_ids[parent_id],
      parent_attribute_values[parent_id]
    );
  }

  function currentParentIndex() external view override returns (uint256) {
    return current_parent_index;
  }

  function updateParentIndex() external override onlyController {
    //bump index to the next scion
    current_parent_index++;
    if (current_parent_index == ordered_parents.length) {
      current_parent_index = 0;
    }
  }

  function connectScion(uint256 parent_id, uint256 scion_id)
    external
    override
    onlyController
  {
    scion_parents[scion_id] = parent_id;
    parent_scions[parent_id].push(scion_id);
    tribute_percentages[scion_id] = default_tribute_percentage;
  }

  function getScions(uint256 parent_id)
    external
    view
    override
    returns (uint256[] memory)
  {
    return parent_scions[parent_id];
  }

  function hasParent(uint256 scion_token_id)
    external
    view
    override
    returns (uint256)
  {
    return scion_parents[scion_token_id];
  }

  function tributePercentage(uint256 scion_id)
    external
    view
    override
    returns (uint256)
  {
    return tribute_percentages[scion_id];
  }

  function addTribute(uint256 parent_id, uint256 amount)
    external
    override
    onlyController
  {
    pxl_tribute_amounts[parent_id] += amount;
  }

  function claimTribute(uint256 parent_id) external override {
    require(
      isController(_msgSender()) || _msgSender() == parent_owners[parent_id],
      'ScionCoordinator: not controller or parent bot owner'
    );
    uint256 amount = pxl_tribute_amounts[parent_id];
    inventory.removeItemFromGame(
      Item({ _contract: IInventoryItemContract(address(pxl)), id: 1 }),
      Entity({ _contract: IInventoryEntityContract(address(this)), id: 0 }),
      amount
    );
    pxl.transfer(parent_owners[parent_id], amount);
  }

  function irlOwner(uint256) external view override returns (address) {
    return address(this);
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '../gameplay/coordinators/InventoryCoordinator/IInventoryItemContract.sol';
import '../utils/Controllable.sol';
import '../utils/Payable.sol';

interface IPXL is IERC20, IInventoryItemContract {
  function mint(address to, uint256 amount) external;
}

contract PXL is IPXL, ERC20, Ownable, Payable, Controllable {
  constructor() ERC20('PXL', 'PXL') {}

  /**
   * mints $PXL to a recipient
   * @param to the recipient of the $PXL
   * @param amount the amount of $PXL to mint
   */
  function mint(address to, uint256 amount) external override onlyController {
    _mint(to, amount);
  }

  /**
   * burns $PXL from a holder
   * @param from the holder of the $PXL
   * @param amount the amount of $PXL to burn
   */
  function burn(address from, uint256 amount) external onlyController {
    _burn(from, amount);
  }

  function irlBalance(uint256, address owner)
    external
    view
    override
    returns (uint256)
  {
    return balanceOf(owner);
  }

  function inventoryItemTransfer(
    uint256,
    uint256 amount,
    address from,
    address to
  ) external override {
    if (from == _msgSender()) {
      transfer(to, amount);
    } else {
      transferFrom(from, to, amount);
    }
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import '../../gameplay/coordinators/InventoryCoordinator/IInventoryEntityContract.sol';

interface IScionCoordinator is IInventoryEntityContract {
  function addParent(
    uint256 parent_id,
    string[] memory attr_ids,
    uint32[] memory attr_vals,
    address owner
  ) external payable;

  function removeParent(uint256 parent_id) external payable;

  function parentOwnerChanged(uint256 parent_id, address new_owner)
    external
    payable;

  function getParent(uint256 parent_id)
    external
    view
    returns (string[] memory, uint32[] memory);

  function selectParent()
    external
    view
    returns (
      uint256 token,
      string[] memory attr_ids,
      uint32[] memory attr_values
    );

  function totalParents() external view returns (uint256);

  function currentParentIndex() external view returns (uint256);

  function updateParentIndex() external;

  function connectScion(uint256 parent_id, uint256 scion_id) external;

  function getScions(uint256 parent_id)
    external
    view
    returns (uint256[] memory);

  function hasParent(uint256 scion_token_id) external view returns (uint256);

  function tributePercentage(uint256 child_token_id)
    external
    view
    returns (uint256);

  function addTribute(uint256 scion_id, uint256 amount) external;

  function claimTribute(uint256 scion_id) external;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

abstract contract Payable is Ownable {
  /**
   * @dev Sends entire balance to contract owner.
   */
  function withdrawAll() external {
    payable(owner()).transfer(address(this).balance);
  }

    /**
   * @dev Sends entire balance of a given ERC20 token to contract owner.
   */
  function withdrawAllERC20(IERC20 _erc20Token) external virtual {
    _erc20Token.transfer(owner(), _erc20Token.balanceOf(address(this)));
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

//defines an "Entity" that can hold an item in inventory (e.g. a pxlbot; consisting of pxlbot contract address and a token ID)
interface IInventoryEntityContract {
  // Base id is determined by the contract. Examples might be tokenId in an ERC721 or simply putting 1 for ERC20
  function irlOwner(uint256 _baseId) external returns (address);
}