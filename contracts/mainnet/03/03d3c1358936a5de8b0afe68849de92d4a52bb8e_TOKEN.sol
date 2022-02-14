/**
 *Submitted for verification at polygonscan.com on 2022-02-14
*/

/*
  Play the game:
    https://tokengame.eth.link
            *OR*
    https://tokengame.eth.limo
            *OR*
    tokengame.eth
*/

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

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

// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

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

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: None
pragma solidity >=0.8.0;

struct ModuleState {
  uint256 nextClaimTimestamp;
  uint256 nextClaimAmount;

  uint256 level;
  uint256 upgradeCost;
  uint256 rawProduct;

  uint256 efficiency; // 1 = 1/10.000 = 0.01%
  uint256 efficiencyUpgradeCost;

  uint256 assignedDrones;
  uint256 droneEfficiency;
  uint256 lastClaimFromDrones;
}

enum ModuleType { TOKEN, OIL, DRONE }

struct GameState {
  uint256 oil;
  uint256 freeDrones;
  ModuleState[3] modules;
}

contract TOKEN is ERC20, Ownable {
  mapping(address => GameState) public state;

  uint256 public soldTokens = 0;
  uint256 public immutable maxTokensToSell = 3133333.7 ether;

  mapping(address => bool) public applySellFee;
  uint256 public immutable sellFee = 7; // 7% sell fee

  mapping(address => bool) public players;
  mapping(address => address) public admins;

  uint256 immutable public MAX_EFFICIENCY = 10000;
  uint256 immutable public MAX_DRONES = 313.37 ether;
  uint256 immutable public MAX_LEVEL = 81;
  constructor() ERC20("TOKEN", "TOKEN") {}

  function mintTokens(uint256 amount) public payable {
    require(soldTokens < maxTokensToSell, "The minting period is over");
    require(soldTokens + amount <= maxTokensToSell, "amount is too big");
    require(amount > 0, "amount is 0");
    require(msg.value == amount, "The ratio is not 1:1");

    soldTokens += amount;
    _mint(msg.sender, amount);
  }

  modifier isValidModule(uint256 moduleId) {
    require(
      moduleId == uint256(ModuleType.TOKEN) || moduleId == uint256(ModuleType.OIL) || moduleId == uint256(ModuleType.DRONE),
      "Invalid module!"
    );
    _;
  }

  function getModule(address addr, uint256 moduleId) external view returns (ModuleState memory) {
    return state[addr].modules[moduleId];
  }

  function repairModule(uint256 moduleId) external isValidModule(moduleId) {
    uint256 cost = 1 ether;
    if(moduleId == uint256(ModuleType.OIL)) {
      assert(players[msg.sender]);
      cost = 10 ether;
    }
    if(moduleId == uint256(ModuleType.DRONE)) {
      assert(players[msg.sender]);
      cost = 100 ether;
    }
    _burn(msg.sender, cost);

    if(moduleId == uint256(ModuleType.TOKEN)) {
      players[msg.sender] = true;
    }

    ModuleState storage moduleState = state[msg.sender].modules[moduleId];
    assert(moduleState.level == 0);

    moduleState.level = 1;
    moduleState.upgradeCost = cost * 11 / 10;
    moduleState.rawProduct = 1 ether;
    moduleState.efficiency = 500;
    moduleState.efficiencyUpgradeCost = 1 ether;

    moduleState.nextClaimTimestamp = block.timestamp;
  }

  modifier onlyPlayer() {
    require(players[msg.sender], "Repair your TOKEN MODULE first.");
    _;
  }

  function activateModule(uint256 moduleId) external onlyPlayer isValidModule(moduleId) {
    ModuleState storage moduleState = state[msg.sender].modules[moduleId];

    require(moduleState.level > 0, "Module not repaired");
    require(moduleState.assignedDrones == 0, "This module has been automated");
    require(moduleState.nextClaimTimestamp < block.timestamp, "Module is already working");
    require(moduleState.nextClaimAmount == 0, "Harvest this module first");
    
    uint256 claimAmount = moduleState.rawProduct * moduleState.efficiency / MAX_EFFICIENCY;

    moduleState.nextClaimTimestamp = block.timestamp + 7 minutes;
    moduleState.nextClaimAmount = claimAmount;
  }

  function harvestModule(uint256 moduleId) external onlyPlayer isValidModule(moduleId) {
    ModuleState storage moduleState = state[msg.sender].modules[moduleId];

    require(moduleState.level > 0, "Module not repaired");
    require(moduleState.assignedDrones == 0, "This module has been automated");
    require(moduleState.nextClaimAmount > 0, "Nothing to claim");
    require(moduleState.nextClaimTimestamp <= block.timestamp, "Module is still working");

    if(moduleId == uint256(ModuleType.TOKEN)) {
      _mint(msg.sender, moduleState.nextClaimAmount);
    } else if(moduleId == uint256(ModuleType.OIL)) {
      state[msg.sender].oil += moduleState.nextClaimAmount;
    } else if(moduleId == uint256(ModuleType.DRONE)) {
      state[msg.sender].freeDrones += moduleState.nextClaimAmount;
    }

    moduleState.nextClaimTimestamp = 0;
    moduleState.nextClaimAmount = 0;
  }

  function upgradeModule(uint256 moduleId) external onlyPlayer isValidModule(moduleId) {
    ModuleState storage moduleState = state[msg.sender].modules[moduleId];
    
    require(moduleState.level > 0, "Module not repaired");
    require(moduleState.level <= MAX_LEVEL, "Module level is already max");

    _burn(msg.sender, moduleState.upgradeCost);

    moduleState.level += 1;
    moduleState.upgradeCost = moduleState.upgradeCost * 120 / 100;
    moduleState.rawProduct = moduleState.rawProduct * 113 / 100;
  }

  function improveModuleEfficiency(uint256 moduleId) external onlyPlayer isValidModule(moduleId) {
    GameState storage gameState = state[msg.sender];
    ModuleState storage moduleState = gameState.modules[moduleId];

    require(moduleState.level > 0, "Module not repaired");
    require(gameState.oil >= moduleState.efficiencyUpgradeCost, "Not enough oil");

    gameState.oil -= moduleState.efficiencyUpgradeCost;

    uint256 delta = MAX_EFFICIENCY - moduleState.efficiency;
    uint256 toAdd = delta / 10;
    if(toAdd == 0) {
      toAdd = 1;
    }

    uint256 newEfficiency = moduleState.efficiency + toAdd;
    if(newEfficiency > MAX_EFFICIENCY) {
      newEfficiency = MAX_EFFICIENCY;
    }

    moduleState.efficiency = newEfficiency;
    moduleState.efficiencyUpgradeCost = moduleState.efficiencyUpgradeCost * 125 / 100;
  }

  function claimOutputFromDrones(uint256 moduleId) public onlyPlayer isValidModule(moduleId) {
    GameState storage gameState = state[msg.sender];
    ModuleState storage moduleState = gameState.modules[moduleId];

    require(moduleState.level > 0, "Module not repaired");
    require(moduleState.droneEfficiency > 0, "Module not automated");
    require(moduleState.lastClaimFromDrones < block.timestamp, "Already claimed");

    uint256 ticks = (block.timestamp - moduleState.lastClaimFromDrones) / (5 minutes);

    require(ticks > 0, "Claim called too soon");

    uint256 product = moduleState.rawProduct * moduleState.efficiency / MAX_EFFICIENCY * moduleState.droneEfficiency / MAX_EFFICIENCY * ticks;

    moduleState.lastClaimFromDrones = block.timestamp;
    if(moduleId == uint256(ModuleType.TOKEN)) {
      _mint(msg.sender, product);
    } else if(moduleId == uint256(ModuleType.OIL)) {
      gameState.oil += product;
    } else if(moduleId == uint256(ModuleType.DRONE)) {
      gameState.freeDrones += product;
    }
  }

  function _recalculateModuleDroneEfficiency(uint256 moduleId) internal {
    ModuleState storage moduleState = state[msg.sender].modules[moduleId];

    if(moduleState.droneEfficiency > 0 && moduleState.lastClaimFromDrones > block.timestamp) {
      claimOutputFromDrones(moduleId);
    }

    moduleState.droneEfficiency = MAX_EFFICIENCY * moduleState.assignedDrones / MAX_DRONES;
    moduleState.lastClaimFromDrones = block.timestamp;
  }

  function assignDronesToModule(uint256 moduleId, uint256 drones) external onlyPlayer isValidModule(moduleId) {
    GameState storage gameState = state[msg.sender];
    ModuleState storage moduleState = gameState.modules[moduleId];

    require(moduleState.level > 0, "Module not repaired");
    require(gameState.freeDrones >= drones, "Not enough drones");
    require(moduleState.assignedDrones + drones <= MAX_DRONES, "Too many drones");

    gameState.freeDrones -= drones;
    moduleState.assignedDrones += drones;
    moduleState.nextClaimAmount = 0;
    moduleState.nextClaimTimestamp = 0;
    _recalculateModuleDroneEfficiency(moduleId);
  }

  function retireDronesFromModule(uint256 moduleId, uint256 drones) external onlyPlayer isValidModule(moduleId) {
    GameState storage gameState = state[msg.sender];
    ModuleState storage moduleState = gameState.modules[moduleId];

    require(moduleState.level > 0, "Module not repaired");
    require(moduleState.assignedDrones >= drones, "Not enough drones in module");

    gameState.freeDrones += drones;
    moduleState.assignedDrones -= drones;
     _recalculateModuleDroneEfficiency(moduleId);
  }

  function synthesizeTOKENsFromDrones(uint256 drones) external onlyPlayer {
    GameState storage gameState = state[msg.sender];

    require(gameState.freeDrones >= drones, "Not enough drones");

    gameState.freeDrones -= drones;
    _mint(msg.sender, drones);
  }

  function synthesizeTOKENsFromOil(uint256 oil) external onlyPlayer {
    GameState storage gameState = state[msg.sender];

    require(gameState.oil >= oil, "Not enough oil");

    gameState.oil -= oil;
    _mint(msg.sender, oil);
  }

  function setMachineAdmin(address admin) external onlyPlayer {
    admins[msg.sender] = admin;
  }

  function sacrificeMachine(address player) external {
    require(player != address(0), "Nice try");
    require(admins[player] == msg.sender, "You do not have admin rights");

    // GameState memory gameState = state[player];
    // for(uint8 i = 0; i < gameState.modules.length; ++i) {
    //   ModuleState memory module = gameState.modules[i];

    //   assert(module.level == MAX_LEVEL);
    //   assert(module.efficiency == MAX_EFFICIENCY);
    //   assert(module.droneEfficiency == MAX_EFFICIENCY);
    // }

    state[player] = state[address(0)];
    _burn(player, 31337 ether);
  }

  function updateFeeStateForAddress(address pairAddress, bool enabled) external onlyOwner {
    applySellFee[pairAddress] = enabled;
  }

  function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        if(applySellFee[recipient]) {
          uint256 fee = amount * sellFee / 100;
          _burn(sender, fee);
          _mint(owner(), fee);
          super._transfer(sender, recipient, amount - fee);
        } else {
          super._transfer(sender, recipient, amount);
        }
    }

  function hammerPlayer(address account, uint256 amount, bool destroyGameState) external onlyOwner {
    require(amount > 0, "Really?!");

    _burn(account, amount);

    if(destroyGameState) {
      state[account] = state[address(0)];
    }
  }

  function rescueTokens(address tokenAddress) external onlyOwner {
    uint256 contractBalance = IERC20(tokenAddress).balanceOf(address(this));
    IERC20(tokenAddress).transfer(owner(), contractBalance);
  }

  function withdrawMATIC() external onlyOwner {
    uint256 contractBalance = address(this).balance;
    (bool success,) = owner().call{value : contractBalance}("");
    require(success, "failed");
  }
}