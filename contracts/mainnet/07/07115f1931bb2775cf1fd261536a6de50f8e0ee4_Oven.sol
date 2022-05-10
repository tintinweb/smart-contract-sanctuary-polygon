// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./EnumerableItems.sol";

contract Oven is Initializable, OwnableUpgradeable, ERC20BurnableUpgradeable, EnumerableItems {
    IERC20Upgradeable public microwave;

    /// @notice Info of each user.
    /// `amount` xMW amount the user has provided.
    struct ItemInfo {
        uint256 amount;
        uint256 unbondedAt;
    }

    /// @notice Unbonding period
    uint256 public unbondPeriod;

    // The next new item's id.
    uint256 private newItemId;

    /// @notice Info of each user that stakes LP tokens.
    mapping(uint256 => ItemInfo) public itemInfo;

    /// @notice total unbonding token amount of all users.
    uint256 public totalUnbondingAmount;

    /// @notice reward per second
    uint256 public rewardPerSecond;

    /// @notice
    address public rewardTreasury;

    /// @notice
    uint256 public lastRewardedAt;

    event Deposit(address indexed user, uint256 amount, uint256 share);
    event Unbond(address indexed user, uint256 itemId, uint256 amount, uint256 share);
    event Withdraw(address indexed user, uint256 itemId, uint256 amount);

    modifier onlyOwnerOfItem(uint256 itemId) {
        require(ownerOf(itemId) == msg.sender, "Must be the owner of this item");
        _;
    }

    function initialize(
        IERC20Upgradeable _microwave,
        uint256 _unbondPeriod,
        address _treasury,
        uint256 _rewardPerSecond
    ) external initializer {
        __Ownable_init();
        __ERC20Burnable_init();
        __ERC20_init("Microwave Oven", "xMW");
        __EnumerableItems_init();

        microwave = _microwave;
        unbondPeriod = _unbondPeriod;
        newItemId = 1;
        lastRewardedAt = block.timestamp;
        rewardPerSecond = _rewardPerSecond;
        rewardTreasury = _treasury;
    }

    /// Setters

    /**
     * @notice set reward per second
     */
    function setRewardPerSecond(uint256 _rewardPerSecond) external onlyOwner {
        update();
        rewardPerSecond = _rewardPerSecond;
    }

    /**
     * @notice set reward treasury
     */
    function setRewardTreasury(address _treasury) external onlyOwner {
        rewardTreasury = _treasury;
    }

    /// Viewers

    /**
     * @notice return exchange rate of xMicrowave in microwave
     */
    function getExchangeRate() public view returns (uint256) {
        return (totalActiveMicrowave() * 1e18) / totalSupply();
    }

    /**
     * @notice convet xMicrowave to microwave
     */
    function toMicrowave(uint256 xMWAmount) public view returns (uint256 microwaveAmount) {
        microwaveAmount = (xMWAmount * totalActiveMicrowave()) / totalSupply();
    }

    /**
     * @notice convet microwave to xMicrowave
     */
    function toXMicrowave(uint256 microwaveAmount) public view returns (uint256 xMWAmount) {
        xMWAmount = (microwaveAmount * totalSupply()) / totalActiveMicrowave();
    }

    /**
     * @notice return bonded microwave amount
     */
    function totalActiveMicrowave() public view returns (uint256 activeMicrowave) {
        activeMicrowave = _pendingAtTreasury() + microwave.balanceOf(address(this)) - totalUnbondingAmount;
    }

    /**
     * @notice return available reward amount
     * @return rewardInTreasury reward amount in treasury
     * @return rewardAllowedForThisPool allowed reward amount to be spent by this pool
     */
    function availableReward()
        public
        view
        returns (uint256 rewardInTreasury, uint256 rewardAllowedForThisPool)
    {
        rewardInTreasury = microwave.balanceOf(rewardTreasury);
        rewardAllowedForThisPool = microwave.allowance(
            rewardTreasury,
            address(this)
        );
    }

    /// Workers

    function update() public {
        microwave.transferFrom(rewardTreasury, address(this), _pendingAtTreasury());
        lastRewardedAt = block.timestamp;
    }

    // Enter the bar. Pay some MWs. Earn some shares.
    // Locks MW and mints xMW
    function deposit(uint256 _amount) public {
        update();

        // Gets the amount of MW locked in the contract
        uint256 totalMicrowave = totalActiveMicrowave();
        // Gets the amount of xMW in existence
        uint256 totalShares = totalSupply();
        // If no xMW exists, mint it 1:1 to the amount put in
        if (totalShares == 0 || totalMicrowave == 0) {
            _mint(msg.sender, _amount);
            emit Deposit(msg.sender, _amount, _amount);
        } 
        // Calculate and mint the amount of xMW the Microwave is worth. The ratio will change overtime, as xMW is burned/minted and Microwave deposited + gained from fees / withdrawn.
        else {
            uint256 what = _amount * totalShares / totalMicrowave;
            _mint(msg.sender, what);
            emit Deposit(msg.sender, _amount, what);
        }
        // Lock the Microwave in the contract
        microwave.transferFrom(msg.sender, address(this), _amount);
    }

    // Leave the bar. Claim back your MWs.
    // Unlocks the staked + gained Microwave and burns xMW
    function unbond(uint256 _share) public {
        update();

        // Gets the amount of xMW in existence
        uint256 totalShares = totalSupply();
        // Calculates the amount of Microwave the xMW is worth
        uint256 what = _share * totalActiveMicrowave() / totalShares;
        _burn(msg.sender, _share);

        itemInfo[newItemId] = ItemInfo(what, block.timestamp);
        totalUnbondingAmount = totalUnbondingAmount + what;
        _create(msg.sender, newItemId);

        emit Unbond(msg.sender, newItemId, what, _share);

        newItemId = newItemId + 1;
    }

    // Withdraw unbonded tokens
    function withdraw(uint256 itemId) public onlyOwnerOfItem(itemId) {
        update();

        ItemInfo memory item = itemInfo[itemId];
        require(
            item.unbondedAt + unbondPeriod < block.timestamp,
            "Withdraw: Can't withdraw in unbonding period"
        );

        totalUnbondingAmount = totalUnbondingAmount - item.amount;
        _remove(itemId);

        emit Withdraw(msg.sender, itemId, item.amount);

        microwave.transfer(msg.sender, item.amount);
    }

    /// Internal

    function _pendingAtTreasury() internal view returns (uint256 pending) {
        if (totalSupply() > 0) {
            pending = (block.timestamp - lastRewardedAt) * rewardPerSecond;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

pragma solidity ^0.8.0;

import "../ERC20Upgradeable.sol";
import "../../../utils/ContextUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20BurnableUpgradeable is Initializable, ContextUpgradeable, ERC20Upgradeable {
    function __ERC20Burnable_init() internal initializer {
        __Context_init_unchained();
        __ERC20Burnable_init_unchained();
    }

    function __ERC20Burnable_init_unchained() internal initializer {
    }
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract EnumerableItems is Initializable {
    // Mapping from owner to list of owned item IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedItems;

    // Mapping from item ID to index of the owner items list
    mapping(uint256 => uint256) private _ownedItemsIndex;

    // Array with all item ids, used for enumeration
    uint256[] private _allItems;

    // Mapping from item id to position in the allItems array
    mapping(uint256 => uint256) private _allItemsIndex;

    // Mapping from item ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to item count
    mapping(address => uint256) private _balances;

    /**
     * @dev Initializes the contract.
     */
    function __EnumerableItems_init() internal initializer {}

    /**
     * @dev Items balance of the owner.
     */
    function itemCountOf(address owner) public view returns (uint256) {
        require(owner != address(0), "EnumerableItems: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev Return owner of item.
     */
    function ownerOf(uint256 itemId) public view returns (address) {
        address owner = _owners[itemId];
        require(owner != address(0), "EnumerableItems: owner query for nonexistent item");
        return owner;
    }

    /**
     * @dev Query item of an owner by index.
     */
    function itemOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < itemCountOf(owner), "EnumerableItems: owner index out of bounds");
        return _ownedItems[owner][index];
    }

    /**
     * @dev Total count of items.
     */
    function totalCount() public view returns (uint256) {
        return _allItems.length;
    }

    /**
     * @dev Query each item by index.
     */
    function itemByIndex(uint256 index) public view returns (uint256) {
        require(index < totalCount(), "EnumerableItems: global index out of bounds");
        return _allItems[index];
    }


    /**
     * @dev Create `itemId` to `to`.
     *
     * Requirements:
     *
     * - `itemId` must not exist.
     * - `to` cannot be the zero address.
     *
     */
    function _create(address to, uint256 itemId) internal {
        require(to != address(0), "EnumerableItems: mint to the zero address");
        require(!_exists(itemId), "EnumerableItems: item already minted");

        _addItemToAllItemsEnumeration(itemId);
        _addItemToOwnerEnumeration(to, itemId);

        _balances[to] += 1;
        _owners[itemId] = to;
    }

    /**
     * @dev Destroys `itemId`.
     * The approval is cleared when the item is burned.
     *
     * Requirements:
     *
     * - `itemId` must exist.
     *
     */
    function _remove(uint256 itemId) internal {
        address owner = ownerOf(itemId);

        _removeItemFromOwnerEnumeration(owner, itemId);
        _removeItemFromAllItemsEnumeration(itemId);

        _balances[owner] -= 1;
        delete _owners[itemId];
    }

    /**
     * @dev Returns whether `itemId` exists.
     *
     * Tokens start existing when they are minted (`_create`),
     * and stop existing when they are burned (`_remove`).
     */
    function _exists(uint256 itemId) internal view returns (bool) {
        return _owners[itemId] != address(0);
    }

    /**
     * @dev Private function to add a item to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given item ID
     * @param itemId uint256 ID of the item to be added to the items list of the given address
     */
    function _addItemToOwnerEnumeration(address to, uint256 itemId) private {
        uint256 length = itemCountOf(to);
        _ownedItems[to][length] = itemId;
        _ownedItemsIndex[itemId] = length;
    }

    /**
     * @dev Private function to add a item to this extension's item tracking data structures.
     * @param itemId uint256 ID of the item to be added to the items list
     */
    function _addItemToAllItemsEnumeration(uint256 itemId) private {
        _allItemsIndex[itemId] = _allItems.length;
        _allItems.push(itemId);
    }

    /**
     * @dev Private function to remove a item from this extension's ownership-tracking data structures. Note that
     * while the item is not assigned a new owner, the `_ownedItemsIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedItems array.
     * @param from address representing the previous owner of the given item ID
     * @param itemId uint256 ID of the item to be removed from the items list of the given address
     */
    function _removeItemFromOwnerEnumeration(address from, uint256 itemId) private {
        // To prevent a gap in from's items array, we store the last item in the index of the item to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastItemIndex = itemCountOf(from) - 1;
        uint256 itemIndex = _ownedItemsIndex[itemId];

        // When the item to delete is the last item, the swap operation is unnecessary
        if (itemIndex != lastItemIndex) {
            uint256 lastItemId = _ownedItems[from][lastItemIndex];

            _ownedItems[from][itemIndex] = lastItemId; // Move the last item to the slot of the to-delete item
            _ownedItemsIndex[lastItemId] = itemIndex; // Update the moved item's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedItemsIndex[itemId];
        delete _ownedItems[from][lastItemIndex];
    }

    /**
     * @dev Private function to remove a item from this extension's item tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allItems array.
     * @param itemId uint256 ID of the item to be removed from the items list
     */
    function _removeItemFromAllItemsEnumeration(uint256 itemId) private {
        // To prevent a gap in the items array, we store the last item in the index of the item to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastItemIndex = _allItems.length - 1;
        uint256 itemIndex = _allItemsIndex[itemId];

        // When the item to delete is the last item, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted item is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeItemFromOwnerEnumeration)
        uint256 lastItemId = _allItems[lastItemIndex];

        _allItems[itemIndex] = lastItemId; // Move the last item to the slot of the to-delete item
        _allItemsIndex[lastItemId] = itemIndex; // Update the moved item's index

        // This also deletes the contents at the last position of the array
        delete _allItemsIndex[itemId];
        _allItems.pop();
    }
    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
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
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
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
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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