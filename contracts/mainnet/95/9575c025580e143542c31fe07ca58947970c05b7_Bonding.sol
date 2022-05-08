// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IDAO.sol";
import "./interfaces/IMiningService.sol";
import "./interfaces/IDexHandler.sol";
import "./interfaces/IMaltDataLab.sol";
import "./interfaces/IBondExtension.sol";

import "./Permissions.sol";


struct UserState {
  uint256 bonded;
  uint256 bondedEpoch;
}

struct EpochState {
  uint256 lastTotalBonded;
  uint256 lastUpdateTime;
  uint256 cumulativeTotalBonded;
}

struct RewardPool {
  uint256 id;
  uint256 index; // index into the activePools array
  uint256 totalBonded;
  address distributor;
  bytes32 accessRole;
  bool active;
  string name;
}


/// @title LP Bonding
/// @author 0xScotch <[email protected]>
/// @notice The contract which LP tokens are bonded to to make a user eligible for protocol rewards
contract Bonding is Permissions {
  using SafeERC20 for ERC20;

  bytes32 public constant LINEAR_RECIEVER_ROLE = keccak256("LINEAR_RECIEVER_ROLE");

  ERC20 public malt;
  ERC20 public rewardToken;
  ERC20 public stakeToken;
  IDAO public dao;
  IMiningService public miningService;
  IDexHandler public dexHandler;
  IMaltDataLab public maltDataLab;
  IBondExtension public bondExtension;

  uint256 public stakeTokenDecimals;

  uint256 internal _globalBonded;
  uint256 internal _currentEpoch;
  mapping(uint256 => RewardPool) public rewardPools;
  mapping(uint256 => mapping(address => UserState)) internal userState;
  mapping(uint256 => EpochState) internal epochState;
  uint256[] public activePools;

  event Bond(address indexed account, uint256 indexed poolId, uint256 value);
  event Unbond(address indexed account, uint256 indexed poolId, uint256 value);
  event UnbondAndBreak(address indexed account, uint256 indexed poolId, uint256 amountLPToken, uint256 amountMalt, uint256 amountReward);
  event NewBondingRole(string name, bytes32 role);
  event TogglePoolActive(uint256 indexed poolId, bool active);
  event AddRewardPool(uint256 indexed poolId, string name, bool active, bytes32 accessRole);
  event SetPoolDistributor(uint256 indexed poolId, address distributor);

  constructor(
    address _timelock,
    address initialAdmin,
    address _malt,
    address _rewardToken,
    address _stakeToken,
    address _dao,
    address _miningService,
    address _dexHandler,
    address _maltDataLab,
    address _distributor
  ) {
    require(_timelock != address(0), "Bonding: Timelock addr(0)");
    require(initialAdmin != address(0), "Bonding: Admin addr(0)");
    require(_malt != address(0), "Bonding: Malt addr(0)");
    require(_rewardToken != address(0), "Bonding: RewardToken addr(0)");
    require(_stakeToken != address(0), "Bonding: lpToken addr(0)");
    require(_dao != address(0), "Bonding: DAO addr(0)");
    require(_miningService != address(0), "Bonding: MiningSvc addr(0)");
    require(_dexHandler != address(0), "Bonding: DexHandler addr(0)");
    require(_maltDataLab != address(0), "Bonding: DataLab addr(0)");
    _adminSetup(_timelock);

    _setupRole(ADMIN_ROLE, initialAdmin);
    _setRoleAdmin(LINEAR_RECIEVER_ROLE, ADMIN_ROLE);

    dao = IDAO(_dao);
    stakeToken = ERC20(_stakeToken);
    miningService = IMiningService(_miningService);
    dexHandler = IDexHandler(_dexHandler);
    malt = ERC20(_malt);
    rewardToken = ERC20(_rewardToken);
    maltDataLab = IMaltDataLab(_maltDataLab);

    stakeTokenDecimals = stakeToken.decimals();

    rewardPools[0] = RewardPool({
      id: 0,
      index: 0,
      totalBonded: 0,
      distributor: _distributor,
      accessRole: bytes32(0),
      active: true,
      name: "Vesting"
    });

    // Will be used in the future
    rewardPools[1] = RewardPool({
      id: 1,
      index: 1,
      totalBonded: 0,
      distributor: address(0), // Will set in future
      accessRole: LINEAR_RECIEVER_ROLE,
      active: false,
      name: "Linear"
    });

    activePools.push(0);
  }

  function bond(uint256 poolId, uint256 amount)
    external
  {
    bondToAccount(msg.sender, poolId, amount);
  }

  function bondToAccount(address account, uint256 poolId, uint256 amount)
    public
    nonReentrant
  {
    require(account != address(0), "Bonding: 0x0");
    require(amount > 0, "Cannot bond 0");

    RewardPool memory pool = rewardPools[poolId];
    require(pool.id == poolId, "Unknown Pool");
    require(pool.active, "Pool is not active");
    require(pool.distributor != address(0), "Pool not configured");

    if (pool.accessRole != 0) {
      // This throws if msg.sender doesn't have correct role
      _onlyRoleMalt(pool.accessRole, "Not allowed to bond to this pool");
    }

    miningService.onBond(account, poolId, amount);

    _bond(account, poolId, amount);
  }

  function unbond(uint256 poolId, uint256 amount)
    external
    nonReentrant
  {
    require(amount > 0, "Cannot unbond 0");

    uint256 bondedBalance = balanceOfBonded(poolId, msg.sender);

    require(bondedBalance > 0, "< bonded balance");
    require(amount <= bondedBalance, "< bonded balance");

    // Avoid leaving dust behind
    if (amount + (10**(stakeTokenDecimals - 2)) > bondedBalance) {
      amount = bondedBalance;
    }

    miningService.onUnbond(msg.sender, poolId, amount);

    _unbond(poolId, amount);
  }

  function unbondAndBreak(uint256 poolId, uint256 amount, uint256 slippageBps)
    external
    nonReentrant
  {
    require(amount > 0, "Cannot unbond 0");

    uint256 bondedBalance = balanceOfBonded(poolId, msg.sender);

    require(bondedBalance > 0, "< bonded balance");
    require(amount <= bondedBalance, "< bonded balance");

    // Avoid leaving dust behind
    if (amount + (10**(stakeTokenDecimals - 2)) > bondedBalance) {
      amount = bondedBalance;
    }

    miningService.onUnbond(msg.sender, poolId, amount);

    _unbondAndBreak(poolId, amount, slippageBps);
  }

  /*
   * PUBLIC VIEW FUNCTIONS
   */
  function averageBondedValue(uint256 epoch) public view returns (uint256) {
    EpochState storage state = epochState[epoch];
    uint256 epochLength = dao.epochLength();
    uint256 timeElapsed = epochLength;
    uint256 epochStartTime = dao.getEpochStartTime(epoch);
    uint256 diff;
    uint256 lastUpdateTime = state.lastUpdateTime;
    uint256 lastTotalBonded = state.lastTotalBonded;

    if (lastUpdateTime == 0) {
      lastUpdateTime = epochStartTime;
    }

    if (lastTotalBonded == 0) {
      lastTotalBonded = _globalBonded;
    }

    if (block.timestamp < epochStartTime) {
      return 0;
    }

    if (epochStartTime + epochLength <= lastUpdateTime) {
      return maltDataLab.realValueOfLPToken((state.cumulativeTotalBonded) / epochLength);
    }

    if (epochStartTime + epochLength < block.timestamp) {
      // The desired epoch is in the past
      diff = (epochStartTime + epochLength) - lastUpdateTime;
    } else {
      diff = block.timestamp - lastUpdateTime;
      timeElapsed = block.timestamp - epochStartTime;
    }

    if (timeElapsed == 0) {
      // Only way timeElapsed should == 0 is when block.timestamp == epochStartTime
      // Therefore just return the lastTotalBonded value
      return maltDataLab.realValueOfLPToken(lastTotalBonded);
    }

    uint256 endValue = state.cumulativeTotalBonded + (lastTotalBonded * diff);
    return maltDataLab.realValueOfLPToken((endValue) / timeElapsed);
  }

  function totalBonded() public view returns (uint256) {
    return _globalBonded;
  }

  function allActivePools() public view returns(
    uint256[] memory ids,
    uint256[] memory bondedTotals,
    address[] memory distributors,
    bytes32[] memory accessRoles,
    string[] memory names
  ) {
    uint256[] memory poolIds = activePools;
    uint256 length = poolIds.length;

    ids = new uint256[](length);
    bondedTotals = new uint256[](length);
    distributors = new address[](length);
    accessRoles = new bytes32[](length);
    names = new string[](length);

    for (uint256 i; i < length; ++i) {
      ids[i] = rewardPools[poolIds[i]].id;
      bondedTotals[i] = rewardPools[poolIds[i]].totalBonded;
      distributors[i] = rewardPools[poolIds[i]].distributor;
      accessRoles[i] = rewardPools[poolIds[i]].accessRole;
      names[i] = rewardPools[poolIds[i]].name;
    }

    return (
      ids,
      bondedTotals,
      distributors,
      accessRoles,
      names
    );
  }

  function balanceOfBonded(uint256 poolId, address account) public view returns (uint256) {
    return userState[poolId][account].bonded;
  }

  function bondedEpoch(uint256 poolId, address account) public view returns (uint256) {
    return userState[poolId][account].bondedEpoch;
  }

  function epochData(uint256 epoch) public view returns(uint256, uint256, uint256) {
    return (epochState[epoch].lastTotalBonded, epochState[epoch].lastUpdateTime, epochState[epoch].cumulativeTotalBonded);
  }

  function poolAllocations()
    public
    view
    returns (
      uint256[] memory poolIds,
      uint256[] memory allocations,
      address[] memory distributors
    )
  {
    uint256 totalBonded = _globalBonded;

    uint256[] memory poolIds = activePools;
    uint256 length = poolIds.length;
    uint256[] memory allocations = new uint256[](length);
    address[] memory distributors = new address[](length);

    for (uint256 i; i < length; ++i) {
      RewardPool memory pool = rewardPools[poolIds[i]];
      allocations[i] = pool.totalBonded * 1e18 / totalBonded;
      distributors[i] = pool.distributor;
    }

    return (poolIds, allocations, distributors);
  }

  /*
   * INTERNAL VIEW FUNCTIONS
   */
  function _balanceCheck() internal view {
    require(stakeToken.balanceOf(address(this)) >= totalBonded(), "Balance inconsistency");
  }

  /*
   * INTERNAL FUNCTIONS
   */
  function _bond(address account, uint256 poolId, uint256 amount) internal {

    uint256 oldBalance = stakeToken.balanceOf(address(this));
    stakeToken.safeTransferFrom(msg.sender, address(this), amount);
    amount = stakeToken.balanceOf(address(this)) - oldBalance;

    _addToBonded(account, poolId, amount);

    _balanceCheck();

    if (address(bondExtension) != address(0)) {
      bondExtension.onBond(account, poolId, amount);
    }

    emit Bond(account, poolId, amount);
  }

  function _unbond(uint256 poolId, uint256 amountLPToken) internal {
    _removeFromBonded(msg.sender, poolId, amountLPToken);

    stakeToken.safeTransfer(msg.sender, amountLPToken);

    _balanceCheck();

    emit Unbond(msg.sender, poolId, amountLPToken);
  }

  function _unbondAndBreak(uint256 poolId, uint256 amountLPToken, uint256 slippageBps) internal {
    _removeFromBonded(msg.sender, poolId, amountLPToken);

    stakeToken.safeTransfer(address(dexHandler), amountLPToken);
    uint256 initialBalance = stakeToken.balanceOf(address(this));

    (uint256 amountMalt, uint256 amountReward) = dexHandler.removeLiquidity(amountLPToken, slippageBps);

    // Send any excess back
    uint256 currentBalance = stakeToken.balanceOf(address(this));
    if (currentBalance > initialBalance) {
      stakeToken.safeTransfer(msg.sender, currentBalance - initialBalance);
    }

    malt.safeTransfer(msg.sender, amountMalt);
    rewardToken.safeTransfer(msg.sender, amountReward);

    _balanceCheck();

    emit UnbondAndBreak(msg.sender, poolId, amountLPToken, amountMalt, amountReward);
  }

  function _addToBonded(address account, uint256 poolId, uint256 amount) internal {
    userState[poolId][account].bonded += amount;
    rewardPools[poolId].totalBonded += amount;

    _updateEpochState(_globalBonded + amount);

    if (userState[poolId][account].bondedEpoch == 0) {
      userState[poolId][account].bondedEpoch = dao.epoch();
    }
  }

  function _removeFromBonded(address account, uint256 poolId, uint256 amount) internal {
    userState[poolId][account].bonded -= amount;
    rewardPools[poolId].totalBonded -= amount;

    _updateEpochState(_globalBonded - amount);
  }

  function _updateEpochState(uint256 newTotalBonded) internal {
    EpochState storage state = epochState[_currentEpoch];
    uint256 epoch = dao.epoch();
    uint256 epochStartTime = dao.getEpochStartTime(_currentEpoch);
    uint256 lastUpdateTime = state.lastUpdateTime;
    uint256 lengthOfEpoch = dao.epochLength();
    uint256 epochEndTime = epochStartTime + lengthOfEpoch;

    if (lastUpdateTime == 0) {
      lastUpdateTime = epochStartTime;
    }

    if (lastUpdateTime > epochEndTime) {
      lastUpdateTime = epochEndTime;
    }

    if (epoch == _currentEpoch) {
      // We are still in the same epoch. Just update
      uint256 finalTime = block.timestamp;
      if (block.timestamp > epochEndTime) {
        // We are past the end of the epoch so cap to end of epoch
        finalTime = epochEndTime;
      }

      uint256 diff = finalTime - lastUpdateTime;

      if (diff > 0) {
        state.cumulativeTotalBonded = state.cumulativeTotalBonded + (state.lastTotalBonded * diff);

        state.lastUpdateTime = finalTime;
        state.lastTotalBonded = newTotalBonded;
      }
    } else {
      // We have crossed at least 1 epoch boundary

      // Won't underflow due to check on lastUpdateTime above
      uint256 diff = epochEndTime - lastUpdateTime;

      state.cumulativeTotalBonded = state.cumulativeTotalBonded + (state.lastTotalBonded * diff);
      state.lastUpdateTime = epochEndTime;
      state.lastTotalBonded = _globalBonded;

      for (uint256 i = _currentEpoch + 1; i <= epoch; i += 1) {
        state = epochState[i];
        epochStartTime = dao.getEpochStartTime(i);
        epochEndTime = epochStartTime + lengthOfEpoch;
        state.lastTotalBonded = _globalBonded;

        if (epochEndTime < block.timestamp) {
          // The desired epoch is in the past
          diff = lengthOfEpoch;
          state.lastUpdateTime = epochEndTime;
        } else {
          diff = block.timestamp - epochStartTime;
          state.lastUpdateTime = block.timestamp;
        }

        state.cumulativeTotalBonded = state.lastTotalBonded * diff;
      }

      state.lastTotalBonded = newTotalBonded;
      _currentEpoch = epoch;
    }

    _globalBonded = newTotalBonded;
  }

  /*
   * PRIVILEDGED FUNCTIONS
   */
  function setMiningService(address _miningService)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privs")
  {
    require(_miningService != address(0), "Cannot set 0 address");
    miningService = IMiningService(_miningService);
  }

  function setDAO(address _dao)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privs")
  {
    require(_dao != address(0), "Cannot set 0 address");
    dao = IDAO(_dao);
  }

  function setDexHandler(address _dexHandler)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privs")
  {
    require(_dexHandler != address(0), "Cannot set 0 address");
    dexHandler = IDexHandler(_dexHandler);
  }

  function setCurrentEpoch(uint256 _epoch)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privs")
  {
    _currentEpoch = _epoch;
  }

  function addNewRole(string memory roleName)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privs")
  {
    bytes32 role = keccak256(abi.encodePacked(roleName));
    _setRoleAdmin(role, ADMIN_ROLE);
    emit NewBondingRole(roleName, role);
  }

  function addRewardPool(
    uint256 poolId,
    bytes32 accessRole,
    bool active,
    address distributor,
    string calldata name
  )
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privs")
  {
    RewardPool storage pool = rewardPools[poolId];
    require(poolId > 1 && pool.id == 0, "Pool already used");

    rewardPools[poolId] = RewardPool({
      id: poolId,
      index: activePools.length,
      distributor: distributor,
      totalBonded: 0,
      accessRole: accessRole,
      active: active,
      name: name
    });

    activePools.push(poolId);

    emit AddRewardPool(poolId, name, active, accessRole);
  }

  function togglePoolActive(uint256 poolId)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privs")
  {
    RewardPool storage pool = rewardPools[poolId];
    require(pool.id == poolId, "Unknown pool");

    bool active = !pool.active;
    pool.active = active;

    if (active) {
      // setting it to active so add to activePools
      pool.index = activePools.length;
      activePools.push(poolId);
    } else {
      // Becoming inactive so remove from activePools
      uint256 index = pool.index;
      uint256 lastPool = activePools[activePools.length - 1];
      activePools[index] = lastPool;
      activePools.pop();

      rewardPools[lastPool].index = index;
    }

    emit TogglePoolActive(poolId, active);
  }

  function setPoolDistributor(uint256 poolId, address distributor)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privs")
  {
    RewardPool storage pool = rewardPools[poolId];
    require(pool.id == poolId, "Unknown pool");

    pool.distributor = distributor;

    emit SetPoolDistributor(poolId, distributor);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;


interface IDAO {
  function epoch() external view returns (uint256);
  function epochLength() external view returns (uint256);
  function genesisTime() external view returns (uint256);
  function getEpochStartTime(uint256 _epoch) external view returns (uint256);
  function getLockedMalt(address account) external view returns (uint256);
  function epochsPerYear() external view returns (uint256);
  function advance() external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;


interface IMiningService {
  function withdrawAccountRewards(uint256 poolId, uint256 amount) external;
  function balanceOfRewards(address account, uint256 poolId) external view returns (uint256);
  function earned(address account, uint256 poolId) external view returns (uint256);
  function onBond(address account, uint256 poolId, uint256 amount) external;
  function onUnbond(address account, uint256 poolId, uint256 amount) external;
  function withdrawRewardsForAccount(address account,uint256 poolId, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;


interface IDexHandler {
  function buyMalt(uint256, uint256) external returns (uint256 purchased);
  function sellMalt(uint256, uint256) external returns (uint256 rewards);
  function addLiquidity(uint256, uint256, uint256) external returns (
    uint256 maltUsed,
    uint256 rewardUsed,
    uint256 liquidityCreated
  );
  function removeLiquidity(uint256, uint256) external returns (uint256 amountMalt, uint256 amountReward);
  function calculateMintingTradeSize(uint256 priceTarget) external view returns (uint256);
  function calculateBurningTradeSize(uint256 priceTarget) external view returns (uint256);
  function reserves() external view returns (uint256 maltSupply, uint256 rewardSupply);
  function maltMarketPrice() external view returns (uint256 price, uint256 decimals);
  function getOptimalLiquidity(address tokenA, address tokenB, uint256 liquidityB)
    external view returns (uint256 liquidityA);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;


interface IMaltDataLab {
  function priceTarget() external view returns (uint256);
  function smoothedMaltPrice() external view returns (uint256);
  function smoothedK() external view returns (uint256);
  function smoothedReserves() external view returns (uint256);
  function maltPriceAverage(uint256 _lookback) external view returns (uint256);
  function kAverage(uint256 _lookback) external view returns (uint256);
  function poolReservesAverage(uint256 _lookback) external view returns (uint256, uint256);
  function lastMaltPrice() external view returns (uint256, uint64);
  function lastPoolReserves() external view returns (uint256, uint256, uint64);
  function lastK() external view returns (uint256, uint64);
  function realValueOfLPToken(uint256 amount) external view returns (uint256);
  function trackPool() external;
  function trustedTrackPool(uint256, uint256, uint256) external;
  function rewardToken() external view returns(address);
  function malt() external view returns(address);
  function stakeToken() external view returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;

interface IBondExtension {
  function onBond(address, uint256, uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


/// @title Permissions
/// @author 0xScotch <[email protected]>
/// @notice Inherited by almost all Malt contracts to provide access control
contract Permissions is AccessControl, ReentrancyGuard {
  using SafeERC20 for ERC20;

  // Timelock has absolute power across the system
  bytes32 public constant TIMELOCK_ROLE = keccak256("TIMELOCK_ROLE");
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
  bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");

  // Contract types
  bytes32 public constant STABILIZER_NODE_ROLE = keccak256("STABILIZER_NODE_ROLE");
  bytes32 public constant LIQUIDITY_MINE_ROLE = keccak256("LIQUIDITY_MINE_ROLE");
  bytes32 public constant AUCTION_ROLE = keccak256("AUCTION_ROLE");
  bytes32 public constant REWARD_THROTTLE_ROLE = keccak256("REWARD_THROTTLE_ROLE");
  bytes32 public constant INTERNAL_WHITELIST_ROLE = keccak256("INTERNAL_WHITELIST_ROLE");

  address public proposedAdmin;
  address internal globalAdmin;

  event reassignGlobalAdminProposed(address newAdmin, address sender);
  event reassignGlobalAdminAccepted(address newAdmin);

  function _adminSetup(address _timelock) internal {
    require(_timelock != address(0), "Perm: Admin setup 0x0");
    _roleSetup(TIMELOCK_ROLE, _timelock);
    _roleSetup(ADMIN_ROLE, _timelock);
    _roleSetup(GOVERNOR_ROLE, _timelock);
    _roleSetup(STABILIZER_NODE_ROLE, _timelock);
    _roleSetup(LIQUIDITY_MINE_ROLE, _timelock);
    _roleSetup(AUCTION_ROLE, _timelock);
    _roleSetup(REWARD_THROTTLE_ROLE, _timelock);
    _roleSetup(INTERNAL_WHITELIST_ROLE, _timelock);

    globalAdmin = _timelock;
  }

  function assignRole(bytes32 role, address _assignee)
    external
    onlyRoleMalt(getRoleAdmin(role), "Only role admin")
  {
    _grantRole(role, _assignee);
  }

  function removeRole(bytes32 role, address _entity)
    external
    onlyRoleMalt(getRoleAdmin(role), "Only role admin")
  {
    revokeRole(role, _entity);
  }

  function grantRoleMultiple(bytes32 role, address[] calldata addresses)
    external
    onlyRoleMalt(getRoleAdmin(role), "Only role admin")
  {
    uint256 length = addresses.length;
    for (uint i; i < length; ++i) {
      address account = addresses[i];
      require(account != address(0), "0x0");
      _grantRole(role, account);
    }
  }

  function reassignGlobalAdmin(address _admin)
    external
    onlyRoleMalt(TIMELOCK_ROLE, "Only timelock can assign roles")
  {
    require(_admin != address(0), "Perm: Reassign to 0x0");
    proposedAdmin = _admin;
    _grantRole(ADMIN_ROLE, proposedAdmin);
    emit reassignGlobalAdminProposed(_admin, msg.sender);
  }

  function acceptGlobalAdmin() external {
    require(proposedAdmin == msg.sender, "Perm: Not allowed to reassign");
    // give admin role to new admin so he can transfer roles from old admin
    _transferRole(proposedAdmin, globalAdmin, TIMELOCK_ROLE);
    _transferRole(proposedAdmin, globalAdmin, ADMIN_ROLE);
    _transferRole(proposedAdmin, globalAdmin, GOVERNOR_ROLE);
    _transferRole(proposedAdmin, globalAdmin, STABILIZER_NODE_ROLE);
    _transferRole(proposedAdmin, globalAdmin, LIQUIDITY_MINE_ROLE);
    _transferRole(proposedAdmin, globalAdmin, AUCTION_ROLE);
    _transferRole(proposedAdmin, globalAdmin, REWARD_THROTTLE_ROLE);

    globalAdmin = proposedAdmin;
    proposedAdmin = address(0x0);
    emit reassignGlobalAdminAccepted(globalAdmin);
  }

  function emergencyWithdrawGAS(address payable destination)
    external
    onlyRoleMalt(TIMELOCK_ROLE, "Only timelock can assign roles")
  {
    require(destination != address(0), "Withdraw: addr(0)");
    // Transfers the entire balance of the Gas token to destination
    (bool success, ) = destination.call{value: address(this).balance}('');
    require(success, "emergencyWithdrawGAS error");
  }

  function emergencyWithdraw(address _token, address destination)
    external
    onlyRoleMalt(TIMELOCK_ROLE, "Must have timelock role")
  {
    require(destination != address(0), "Withdraw: addr(0)");
    // Transfers the entire balance of an ERC20 token at _token to destination
    ERC20 token = ERC20(_token);
    token.safeTransfer(destination, token.balanceOf(address(this)));
  }

  function partialWithdrawGAS(address payable destination, uint256 amount)
    external
    onlyRoleMalt(TIMELOCK_ROLE, "Must have timelock role")
  {
    require(destination != address(0), "Withdraw: addr(0)");
    (bool success, ) = destination.call{value: amount}('');
    require(success, "partialWithdrawGAS error");
  }

  function partialWithdraw(address _token, address destination, uint256 amount)
    external
    onlyRoleMalt(TIMELOCK_ROLE, "Only timelock can assign roles")
  {
    require(destination != address(0), "Withdraw: addr(0)");
    ERC20 token = ERC20(_token);
    token.safeTransfer(destination, amount);
  }

  /*
   * INTERNAL METHODS
   */
  function _transferRole(address newAccount, address oldAccount, bytes32 role) internal {
    revokeRole(role, oldAccount);
    _grantRole(role, newAccount);
  }

  function _roleSetup(bytes32 role, address account) internal {
    _grantRole(role, account);
    _setRoleAdmin(role, ADMIN_ROLE);
  }

  function _onlyRoleMalt(bytes32 role, string memory reason) internal view {
    require(
      hasRole(
        role,
        _msgSender()
      ),
      reason
    );
  }

  // Using internal function calls here reduces compiled bytecode size
  modifier onlyRoleMalt(bytes32 role, string memory reason) {
    _onlyRoleMalt(role, reason);
    _;
  }

  // verifies that the caller is not a contract.
  modifier onlyEOA() {
    require(hasRole(INTERNAL_WHITELIST_ROLE, _msgSender()) || msg.sender == tx.origin, "Perm: Only EOA");
    _;
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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