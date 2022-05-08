// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../Permissions.sol";
import "../interfaces/IDAO.sol";
import "../interfaces/IOverflow.sol";
import "../interfaces/IBonding.sol";
import "../interfaces/IDistributor.sol";


struct State {
  uint256 profit;
  uint256 rewarded;
  uint256 bondedValue;
  uint256 throttleBps;
}

/// @title Reward Throttle
/// @author 0xScotch <[email protected]>
/// @notice The contract in charge of smoothing out rewards and attempting to find a steady APR
contract RewardThrottle is Permissions {
  using SafeERC20 for ERC20;

  ERC20 public rewardToken;
  IDAO public dao;
  IBonding public bonding;
  IOverflow public overflowPool;

  uint256 public throttleBps = 2000; // 20%
  uint256 public smoothingPeriod = 48; // 48 epochs = 24 hours
  uint256 public desiredRunway = 2629800; // 1 month

  uint256 internal _activeEpoch;
  mapping(uint256 => State) internal _state;

  event RewardOverflow(uint256 epoch, uint256 overflow);
  event HandleReward(uint256 epoch, uint256 amount);

  constructor(
    address _timelock,
    address initialAdmin,
    address _dao,
    address _overflowPool,
    address _bonding,
    address _rewardToken
  ) {
    require(_timelock != address(0), "Throttle: Timelock addr(0)");
    require(initialAdmin != address(0), "Throttle: Admin addr(0)");
    require(_dao != address(0), "Throttle: DAO addr(0)");
    require(_overflowPool != address(0), "Throttle: Overflow addr(0)");
    require(_bonding != address(0), "Throttle: Bonding addr(0)");
    require(_rewardToken != address(0), "Throttle: RewardToken addr(0)");
    _adminSetup(_timelock);

    _setupRole(ADMIN_ROLE, initialAdmin);

    dao = IDAO(_dao);
    overflowPool = IOverflow(_overflowPool);
    bonding = IBonding(_bonding);
    rewardToken = ERC20(_rewardToken);
  }

  function handleReward() external {
    uint256 balance = rewardToken.balanceOf(address(this));

    uint256 epoch = dao.epoch();

    checkRewardUnderflow();

    if (epoch > _activeEpoch) {
      _activeEpoch = epoch;
      _state[_activeEpoch].bondedValue = bonding.averageBondedValue(_activeEpoch);
      _state[_activeEpoch].profit = balance;
      _state[_activeEpoch].rewarded = 0;
      _state[_activeEpoch].throttleBps = throttleBps;
    } else {
      _state[_activeEpoch].profit = _state[_activeEpoch].profit + balance;
      _state[_activeEpoch].throttleBps = throttleBps;
    }

    // Fetch targetAPR before we update current epoch state
    uint256 aprTarget = targetAPR();

    // Distribute balance to the correct places
    if (aprTarget > 0 && _epochAprGivenReward(epoch, balance) > aprTarget) {
      uint256 remainder = _getRewardOverflow(balance, aprTarget);
      emit RewardOverflow(_activeEpoch, remainder);

      if (remainder > 0) {
        rewardToken.safeTransfer(address(overflowPool), remainder);

        if (balance > remainder) {
          _sendToDistributor(balance - remainder, _activeEpoch);
        }
      }
    } else {
      _sendToDistributor(balance, _activeEpoch);
    }

    emit HandleReward(epoch, balance);
  }

  /*
   * PUBLIC VIEW FUNCTIONS
   */
  function epochAPR(uint256 epoch) public view returns (uint256) {
    // This returns an implied APR based on the distributed rewards and bonded LP at the given epoch
    State memory epochState = _state[epoch];

    uint256 bondedValue = epochState.bondedValue;
    if (bondedValue == 0) {
      bondedValue = bonding.averageBondedValue(epoch);
      if (bondedValue == 0) {
        return 0;
      }
    }

    // 10000 = 100%
    return epochState.rewarded * 10000 * dao.epochsPerYear() / bondedValue;
  }

  function averageAPR(uint256 startEpoch, uint256 endEpoch) public view returns (uint256) {
    require(startEpoch < endEpoch, "Start cannot be before the end");

    uint256 totalAPR = 0;
    for (uint256 i = startEpoch; i < endEpoch; i += 1) {
      totalAPR = totalAPR + epochAPR(i);
    }

    return totalAPR / (endEpoch - startEpoch);
  }

  function targetAPR() public view returns (uint256) {
    uint256 epoch = dao.epoch();
    (uint256 target,) = getTargets(epoch, smoothingPeriod);
    return target;
  }

  function targetEpochProfit() public view returns (uint256) {
    uint256 epoch = dao.epoch();
    (, uint256 epochProfitTarget) = getTargets(epoch, smoothingPeriod);
    return epochProfitTarget;
  }

  function getTargets(uint256 epoch, uint256 smoothing) public view returns (uint256, uint256) {
    // Average full APR over smoothingPeriod. Throttled by throttleBps
    uint256 maxPeriod = Math.min(epoch, smoothing);

    uint256 totalProfit = 0;
    uint256 totalBondedValue = 0;

    // Don't use the current epoch as part of the target calculations
    for (uint256 i = 1; i <= maxPeriod; i = i + 1) {
      totalProfit = totalProfit + _state[epoch - i].profit;
      totalBondedValue = totalBondedValue + _state[epoch - i].bondedValue;
    }

    if (totalBondedValue == 0) {
      return (0, 0);
    }

    totalProfit = totalProfit / maxPeriod;
    totalBondedValue = totalBondedValue / maxPeriod;

    // 10k is used here for more granularity on the APR %
    uint256 fullAPR = totalProfit * 10000 * dao.epochsPerYear() / totalBondedValue;
    // throttleBps is up to 10000. 10000 = 100%
    uint256 aprTarget = fullAPR * throttleBps / 10000;

    aprTarget = _checkAprRunway(aprTarget, totalBondedValue);

    // (Target APR, Target profit per epoch)
    return (aprTarget, _desiredProfit(aprTarget, _state[epoch].bondedValue));
  }

  function _checkAprRunway(uint256 aprTarget, uint256 totalBondedValue) internal view returns (uint256) {
    uint256 overflowBalance = rewardToken.balanceOf(address(overflowPool));

    // 31557600 is seconds in a year
    uint256 runwayAnnualReturn = overflowBalance * 31557400 / desiredRunway;
    uint256 runwayAPR = runwayAnnualReturn * 10000 / totalBondedValue;

    if (aprTarget < runwayAPR) {
      return runwayAPR;
    }
    return aprTarget;
  }

  function epochData(uint256 epoch) public view returns (
    uint256 profit,
    uint256 rewarded,
    uint256 bondedValue,
    uint256 throttleAmount
  ) {
    return (
      _state[epoch].profit,
      _state[epoch].rewarded,
      _state[epoch].bondedValue,
      _state[epoch].throttleBps
    );
  }

  /*
   * INTERNAL VIEW FUNCTIONS
   */
  function _desiredProfit(uint256 apr, uint256 bondedValue) internal view returns (uint256) {
    return apr * bondedValue / dao.epochsPerYear() / 10000;
  }

  function _epochAprGivenReward(uint256 epoch, uint256 reward) internal view returns (uint256) {
    // This returns an implied APR based on the distributed rewards and bonded LP at the given epoch
    State memory epochState = _state[epoch];

    if (epochState.bondedValue == 0) {
      return 0;
    }

    // 10000 = 100%
    return (epochState.rewarded + reward) * 10000 * dao.epochsPerYear() / epochState.bondedValue;
  }

  function _getRewardOverflow(uint256 declaredReward, uint256 desiredAPR) internal view returns (uint256 remainder) {
    State memory epochState = _state[_activeEpoch];

    if (desiredAPR == 0) {
      // If desired APR is zero then just allow all rewards through
      return 0;
    }

    uint256 targetProfit = desiredAPR * epochState.bondedValue / dao.epochsPerYear() / 10000;

    if (targetProfit <= epochState.rewarded) {
      return declaredReward;
    }

    uint256 undeclaredReward = targetProfit - epochState.rewarded;

    if (undeclaredReward >= declaredReward) {
      // Declared reward doesn't make up for the difference yet
      return 0;
    }

    remainder = declaredReward - undeclaredReward;
  }

  function _getRewardUnderflow(uint256 desiredAPR, uint256 epoch) internal view returns (uint256 amount) {
    State memory epochState = _state[epoch];

    uint256 targetProfit = desiredAPR * epochState.bondedValue / dao.epochsPerYear() / 10000;

    if (targetProfit <= epochState.rewarded) {
      // Rewarded more than target already. 0 underflow
      return 0;
    }

    return targetProfit - epochState.rewarded;
  }

  /*
   * INTERNAL FUNCTIONS
   */
  function _sendToDistributor(uint256 amount, uint256 epoch) internal {
    if (amount == 0) {
      return;
    }

    (
      uint256[] memory poolIds,
      uint256[] memory allocations,
      address[] memory distributors
    ) = bonding.poolAllocations();

    uint256 length = poolIds.length;
    uint256 balance = rewardToken.balanceOf(address(this));

    for (uint256 i; i < length; ++i) {
      uint256 share = amount * allocations[i] / 1e18;

      if (share > balance) {
        share = balance;
      }

      rewardToken.safeTransfer(distributors[i], share);
      IDistributor(distributors[i]).declareReward(amount);
      balance -= share;

      if (balance == 0) {
        break;
      }
    }

    _state[epoch].rewarded = _state[epoch].rewarded + amount;
    _state[epoch].bondedValue = bonding.averageBondedValue(epoch);
  }

  function checkRewardUnderflow() public {
    uint256 epoch = dao.epoch();

    // Fill in gaps so APR target is correct
    _fillInEpochGaps(epoch);

    if (epoch > _activeEpoch) {
      for (uint256 i = _activeEpoch; i < epoch; i = i + 1) {
        (uint256 desiredAPR,) = getTargets(i, smoothingPeriod);

        if (epochAPR(i) < desiredAPR) {
          uint256 underflow = _getRewardUnderflow(desiredAPR, i);

          if (underflow > 0) {
            uint256 balance = overflowPool.requestCapital(underflow);

            _sendToDistributor(balance, i);
          }
        }
      }
    }
  }

  function fillInEpochGaps() external {
    uint256 epoch = dao.epoch();

    _fillInEpochGaps(epoch);
  }

  function _fillInEpochGaps(uint256 epoch) internal {
    _state[_activeEpoch].bondedValue = bonding.averageBondedValue(_activeEpoch);
    // Avoid issues if gap between rewards is greater than one epoch
    for (uint256 i = _activeEpoch + 1; i < epoch; i = i + 1) {
      if (_state[i].rewarded == 0 && _state[i].bondedValue == 0) {
        _state[i].bondedValue = bonding.averageBondedValue(i);
        _state[i].profit = 0;
        _state[i].rewarded = 0;
        _state[i].throttleBps = throttleBps;
      }
    }
  }

  /*
   * PRIVILEDGED FUNCTIONS
   */
  function setDao(address _dao) external onlyRoleMalt(ADMIN_ROLE, "Must have admin privs") {
    require(_dao != address(0), "Not address 0");
    dao = IDAO(_dao);
  }

  function setBonding(address _bonding) external onlyRoleMalt(ADMIN_ROLE, "Must have admin privs") {
    require(_bonding != address(0), "Not address 0");
    bonding = IBonding(_bonding);
  }

  function setOverflowPool(address _overflowPool) external onlyRoleMalt(ADMIN_ROLE, "Must have admin privs") {
    require(_overflowPool != address(0), "Not address 0");
    overflowPool = IOverflow(_overflowPool);
  }

  function setThrottleBps(uint256 _throttleBps) external onlyRoleMalt(ADMIN_ROLE, "Must have admin privs") {
    require(_throttleBps <= 10000, "Cannot have throttle above 100%");
    throttleBps = _throttleBps;
  }

  function setSmoothingPeriod(uint256 _smoothingPeriod) external onlyRoleMalt(ADMIN_ROLE, "Must have admin privs") {
    require(_smoothingPeriod > 0, "No zero smoothing period");
    smoothingPeriod = _smoothingPeriod;
  }

  function setDesiredRunway(uint256 _runway) external onlyRoleMalt(ADMIN_ROLE, "Must have admin privs") {
    require(_runway > 604800, "Runway must be > 1 week");
    desiredRunway = _runway;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
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


interface IOverflow {
  function requestCapital(uint256 amount) external returns (uint256 fulfilledAmount);
  function purchaseArbitrageTokens(uint256 maxAmount)
    external returns (uint256 remaining);
  function claim() external;
  function outstandingArbTokens() external view returns (uint256 outstanding);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;


interface IBonding {
  function bond(uint256 poolId, uint256 amount) external;
  function bondToAccount(address account, uint256 poolId, uint256 amount) external;
  function unbond(uint256 poolId, uint256 amount) external;
  function unbondAndBreak(uint256 poolId, uint256 amount, uint256 slippageBps) external;
  function totalBonded() external view returns (uint256);
  function balanceOfBonded(uint256 poolId, address account) external view returns (uint256);
  function averageBondedValue(uint256 epoch) external view returns (uint256);
  function stakeToken() external view returns (address);
  function stakeTokenDecimals() external view returns (uint256);
  function poolAllocations()
    external
    view
    returns (
      uint256[] memory poolIds,
      uint256[] memory allocations,
      address[] memory distributors
    );
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;


interface IDistributor {
  function vest() external;
  function totalDeclaredReward() external view returns (uint256);
  function decrementRewards(uint256 amount) external;
  function forfeit(uint256 amount) external;
  function declareReward(uint256 amount) external;
  function focalID() external view returns (uint256);
  function getAllFocalUnvestedBps() external view returns (uint256, uint256);
  function getFocalUnvestedBps(uint256) external view returns (uint256);
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