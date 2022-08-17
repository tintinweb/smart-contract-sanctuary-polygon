// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./IWombatPoo.sol";
import "./IStaking.sol";


contract WombatDao is ERC20Upgradeable, OwnableUpgradeable {
    using Math for uint;

    uint private constant SECONDS_IN_DAY = 60*60*24;
    uint public constant MAX_TOTAL_SUPPLY = 21 * 1e6 * 1e18;
    // We distribute rewards for 15 years.
    uint public constant REWARD_DISTRIBUTION_TOTAL_DAYS = 365 * 15;
    uint private constant DAILY_REWARD = MAX_TOTAL_SUPPLY / REWARD_DISTRIBUTION_TOTAL_DAYS;

    uint public numberOfFertilizationDays;
    uint public rewardsStartDayTime;

    /** You deposit now (startTime)
     * first fertilization day is tomorrow
     * reward for this day is day after tomorrow
     */
    struct UserInfo {
        uint amount;
        // Reward starts on next day
        uint startTime;
        uint pendingReward;
        // Set only if user added WPOO to existing fertilization
        uint zeroDayReward;
        uint collectedReward;
    }

    IWombatPoo _wombatPoo;

    mapping(address => UserInfo) public userFertilizationInfo;
    mapping(uint => uint) public wpooToFertilizeInDay;

    IStaking public _staking;
    uint public stakingStartDayTime;

    uint public wdaoStakingIntroducedTimestamp;

    event WPooAddedForFertilization(address indexed user, uint newPoo, uint remainingPoo, uint pendingReward, uint zeroDayReward, uint previousReward);
    event WDaoFertilizationRewardCollected(address indexed user, uint collectedReward, uint totalCollectedReward, uint newWdaoBalance);
    event RewardsStartDaySet(uint timestamp);
    event StakingStartDaySet(uint timestamp);
    event WDaoRewardCollected(address indexed user, uint totalReward, uint fertilizationReward, uint stakingReward);
    event StakingAddressSet(address newAddress);

    function initialize(
        uint numberOfFertilizationDaysParam,
        address wombatPoo
    ) public initializer {
        __ERC20_init("WombatDao", "WDAO");
        __Ownable_init();
        numberOfFertilizationDays = numberOfFertilizationDaysParam;
        _wombatPoo = IWombatPoo(wombatPoo);
    }

    function setStakingAddress(address stakingAddress) external onlyOwner {
        _staking = IStaking(stakingAddress);
        emit StakingAddressSet(stakingAddress);
    }

    function setRewardsStartDay(uint timestamp) external onlyOwner {
        require(!rewardsStartDayReached(), "WombatDao: Rewards day already reached!");
        rewardsStartDayTime = timestamp;
        emit RewardsStartDaySet(timestamp);
    }

    function getVotingPower(address user) external view returns (uint) {
        return _staking.getUserBoostedAmountWdao(user);
    }

    function rewardsStartDayReached() public view returns (bool) {
        return rewardsStartDayTime != 0 && block.timestamp > rewardsStartDayTime;
    }

    function collectPendingReward() external {
        uint fertilizationReward = _collectFromFertilization();
        uint stakingReward = _staking.collect(msg.sender);
        uint totalReward = fertilizationReward + stakingReward;

        require(totalReward > 0, "WombatDao: nothing to collect!");

        _mint(msg.sender, totalReward);
        emit WDaoRewardCollected(msg.sender, totalReward, fertilizationReward, stakingReward);
    }

    function _collectFromFertilization() private returns (uint) {
        uint reward = _calculateTotalFertilizationRewardForUser(userFertilizationInfo[msg.sender]);
        // reward can be smaller than collected reward if during fertilization reward for fertilization got changed (e.g. when new staking pool was added)
        uint rewardToCollect = reward > userFertilizationInfo[msg.sender].collectedReward ? reward - userFertilizationInfo[msg.sender].collectedReward : 0;

        userFertilizationInfo[msg.sender].collectedReward += rewardToCollect;
        emit WDaoFertilizationRewardCollected(msg.sender, rewardToCollect, userFertilizationInfo[msg.sender].collectedReward, balanceOf(msg.sender));
        return rewardToCollect;
    }

    /**
     * Fertilization always start the day after fertilize action. It takes full numberOfFertilizationDays.
     * After this period of time full reward can be collected.
     * Example:
     * User deposits on day = 10
     * startDay = 10, endDay = 24.
     * User can get reward after every completed day and the last part of the reward is available on 25th day.
     */
    function fertilize(uint value) external {
        require(value > 0, "WombatDao: WPOO amount must be positive");
        require(_wombatPoo.balanceOf(msg.sender) >= value, "WombatDao: no WPOO available");
        uint currentDay = getDaysSinceRewardsStarted();
        require(currentDay < REWARD_DISTRIBUTION_TOTAL_DAYS, "WombatDao: It is too late to fertilize.");
        require(_wombatPoo.allowance(msg.sender, address(this)) >= value, "WombatDao: fertilize amount exceeds allowance");

        _wombatPoo.transferFrom(msg.sender, address(this), value);

        UserInfo storage userInfo = userFertilizationInfo[msg.sender];
        uint zeroDayReward = userInfo.zeroDayReward;
        uint pendingReward = 0;
        uint currentFertilizationRemainingWpoo = 0;
        uint previousPendingReward = userFertilizationInfo[msg.sender].pendingReward;

        // Case when user adds more WPOO to fertilization
        if (userInfo.amount > 0) {
            uint currentFertilizationStartDay = _getDaysSinceRewardsStarted(userInfo.startTime);
            uint currentFertilizationEndDay = currentFertilizationStartDay + numberOfFertilizationDays;

            // We calculate reward also for passed days and it can be collected immediately
            pendingReward = _calculateTotalFertilizationRewardForUser(userInfo);
            // We calculate zeroDayReward only if at least one day passed since current fertilization started.
            // Otherwise we keep previous value.
            if (currentDay > currentFertilizationStartDay) {
                uint usersRemainingWpooToday = _calculateRemainingWpooForUserFertilizationDay(currentDay - currentFertilizationStartDay, userInfo.amount);
                zeroDayReward = _calculateFertilizationRewardForDaySinceFertilizationStarted(currentDay, usersRemainingWpooToday);
            }
            // When current day is not the last day of current fertilization,
            // then we need to add remaining WPOO from the next day (today + 1) to deposited amount
            // and remove remaining WPOO from total supply for the remaining days (it will be recalculated)
            if (currentDay < currentFertilizationEndDay) {
                uint currentFertilizationNextDay = currentDay - currentFertilizationStartDay + 1;
                currentFertilizationRemainingWpoo = _calculateRemainingWpooForUserFertilizationDay(currentFertilizationNextDay, userInfo.amount);

                // Removing remaining WPOO from total supply, as we handle remaining WPOO using sum of remaining WPOO and new deposit
                for (uint i = currentDay + 1; i <= currentFertilizationEndDay; i++) {
                    uint currentFertilizationRemainingPoo = _calculateRemainingWpooForUserFertilizationDay(i - currentFertilizationStartDay, userInfo.amount);
                    wpooToFertilizeInDay[i] -= currentFertilizationRemainingPoo;
                }
            }
        }

        uint totalValue = value + currentFertilizationRemainingWpoo;
        // Starting from 1, as deposit does not include current day.
        for (uint i = currentDay + 1; i <= currentDay + numberOfFertilizationDays; i++) {
            uint remainingPoo = _calculateRemainingWpooForUserFertilizationDay(i - currentDay, totalValue);
            wpooToFertilizeInDay[i] += remainingPoo;
        }

        userFertilizationInfo[msg.sender].amount = totalValue;
        userFertilizationInfo[msg.sender].startTime = block.timestamp;
        userFertilizationInfo[msg.sender].pendingReward = pendingReward;
        userFertilizationInfo[msg.sender].zeroDayReward = zeroDayReward;
        emit WPooAddedForFertilization(msg.sender, value, currentFertilizationRemainingWpoo, pendingReward, zeroDayReward, previousPendingReward);
    }

    // Days passed since rewardsStartDayTime
    function getDaysSinceRewardsStarted() public view returns (uint) {
        return _getDaysSinceRewardsStarted(block.timestamp);
    }

    function getRemainingWpooAt(address user, uint timestamp) external view returns (uint) {
        UserInfo storage userInfo = userFertilizationInfo[user];
        if (userInfo.amount == 0) {
            return 0;
        }
        uint userFertilizationStartDay = _getDaysSinceRewardsStarted(userInfo.startTime);
        uint currentDay = _getDaysSinceRewardsStarted(timestamp);
        if (userFertilizationStartDay >= currentDay) {
            return 0;
        }
        
        return _calculateRemainingWpooForUserFertilizationDay(currentDay - userFertilizationStartDay, userInfo.amount);
    }

    function getDailyFertilizationReward(uint dayNumber) public view returns (uint)  {
        if (dayNumber > REWARD_DISTRIBUTION_TOTAL_DAYS) {
            return 0;
        }
        // Number of pools + 1 for fertilization rewards
        return DAILY_REWARD / (_staking.poolLength() + 1);
    }

    function getDailyStakingReward(uint timestamp) public view returns (uint)  {
        if (timestamp > getRewardsEndTime()) {
            return 0;
        }
        uint poolLength = _staking.poolLength();
        // Number of pools + 1 for fertilization rewards
        return poolLength * DAILY_REWARD / (poolLength + 1);
    }

    function calculateFertilizationRewardToCollect(address owner) external view returns (uint) {
        UserInfo storage user = userFertilizationInfo[owner];
        uint totalReward = _calculateTotalFertilizationRewardForUser(user);
        // reward can be smaller than collected reward if during fertilization reward for fertilization got changed (e.g. when new staking pool was added)
        return totalReward > user.collectedReward ? totalReward - user.collectedReward : 0;
    }

    function getRewardsEndTime() public view returns (uint) {
        require(rewardsStartDayTime != 0, "WombatDao: Rewards start time not set");
        return rewardsStartDayTime + REWARD_DISTRIBUTION_TOTAL_DAYS * SECONDS_IN_DAY;
    }

    function getCollectedRewardFromFertilization() public view returns (uint) {
        return userFertilizationInfo[msg.sender].collectedReward;
    }

    function _mint(address account, uint amount) override internal {
        require(totalSupply() + amount <= MAX_TOTAL_SUPPLY, "WombatDao: Total supply limit reached!");
        super._mint(account, amount);
    }

    function _calculateTotalFertilizationRewardForUser(UserInfo storage user) private view returns (uint) {
        if (user.startTime == 0) {
            return 0;
        }
        uint startDay = _getDaysSinceRewardsStarted(user.startTime);
        uint todayDay = _getDaysSinceRewardsStarted(block.timestamp);
        if (todayDay == startDay) {
            return user.pendingReward;
        }
        uint reward = 0;
        // startDay never gives any rewards (except the case when zeroDayReward is set)
        // We calculate reward only for days passed (todayDay - 1) and maximum up to numberOfFertilizationDays
        for (uint i = startDay + 1; i <= Math.min(todayDay - 1, startDay + numberOfFertilizationDays); i++) {
            uint userWpooForDay = _calculateRemainingWpooForUserFertilizationDay(i - startDay, user.amount);
            reward += _calculateFertilizationRewardForDaySinceFertilizationStarted(i, userWpooForDay);
        }
        // Adds pending zeroDayReward if zero day passed
        if (todayDay > startDay) {
            reward += user.zeroDayReward;
        }
        return reward + user.pendingReward;
    }

    // Days passed since rewardsStartDayTime for timestamp
    function _getDaysSinceRewardsStarted(uint timestamp) private view returns (uint) {
        require(rewardsStartDayReached(), "WombatDao: Rewards day not reached yet");
        return (timestamp - rewardsStartDayTime) / SECONDS_IN_DAY;
    }

    function _calculateFertilizationRewardForDaySinceFertilizationStarted(uint daySinceFertilizationStarted, uint userWpooForDay) private view returns (uint) {
        if (wpooToFertilizeInDay[daySinceFertilizationStarted] == 0) {
            return 0;
        }
        return getDailyFertilizationReward(daySinceFertilizationStarted) * userWpooForDay / wpooToFertilizeInDay[daySinceFertilizationStarted];
    }

    function _calculateRemainingWpooForUserFertilizationDay(uint userFertilizationDayNumber, uint initialWpooToFertilize) private view returns (uint) {
        if (userFertilizationDayNumber > numberOfFertilizationDays || userFertilizationDayNumber == 0) {
            return 0;
        }
        return initialWpooToFertilize - (initialWpooToFertilize * (userFertilizationDayNumber - 1) / numberOfFertilizationDays);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

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
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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
    uint256[49] private __gap;
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
pragma solidity 0.8.3;

interface IWombatPoo {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

interface IStaking  {
    function collect(address collector) external returns (uint);
    function updateAllPools() external;
    function poolLength() external view returns (uint);
    function getUserBoostedAmountWdao(address user) external view returns (uint);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
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
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

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
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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