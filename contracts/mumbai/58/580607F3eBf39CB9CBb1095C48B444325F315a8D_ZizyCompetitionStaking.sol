// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "../utils/IERC20.sol";
import "./ICompetitionFactory.sol";

// @dev We building sth big. Stay tuned!
contract ZizyCompetitionStaking is OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    // Structs
    struct Snapshot {
        uint256 balance;
        uint256 prevSnapshotBalance;
        bool _exist;
    }

    struct Period {
        uint256 firstSnapshotId;
        uint256 lastSnapshotId;
        bool isOver;
        bool _exist;
    }

    struct ActivityDetails {
        uint256 lastSnapshotId;
        uint256 lastActivityBalance;
        bool _exist;
    }

    struct PeriodStakeAverage {
        uint256 average;
        bool _calculated;
    }

    // Smart burn supply limit
    uint256 constant SMART_BURN_SUPPLY_LIMIT = 250_000_000_000_000_00;

    // Stake token address [Zizy]
    IERC20Upgradeable public stakeToken;

    // Competition factory contract
    address public competitionFactory;

    // Stake fee percentage
    uint8 public stakeFeePercentage;

    // Fee receiver address
    address public feeAddress;

    // Current period number
    uint256 public currentPeriod;

    // Current snapshot id
    uint256 private snapshotId;

    // Total staked token balance
    uint256 public totalStaked;

    // Cooling off delay time
    uint256 public coolingDelay;

    // Coolest delay for unstake
    uint256 public coolestDelay;

    // Cooling off percentage
    uint8 public coolingPercentage;

    // Smart burn token amount
    uint256 public smartBurned;

    // Stake balances for address
    mapping(address => uint256) private balances;
    // Account => SnapshotID => Snapshot
    mapping(address => mapping(uint256 => Snapshot)) private snapshots;
    // Account activity details
    mapping(address => ActivityDetails) private activityDetails;
    // Periods
    mapping(uint256 => Period) private periods;
    // Period staking averages
    mapping(address => mapping(uint256 => PeriodStakeAverage)) private averages;
    // Total staked snapshot
    mapping(uint256 => uint256) public totalStakedSnapshot;

    // Events
    event StakeFeePercentageUpdated(uint8 newPercentage);
    event StakeFeeReceived(uint256 amount, uint256 snapshotId, uint256 periodId);
    event UnStakeFeeReceived(uint256 amount, uint256 snapshotId, uint256 periodId);
    event SnapshotCreated(uint256 id, uint256 periodId);
    event Stake(address account, uint256 amount, uint256 fee, uint256 snapshotId, uint256 periodId);
    event UnStake(address account, uint256 amount, uint256 snapshotId, uint256 periodId);
    event CoolingOffSettingsUpdated(uint8 percentage, uint8 coolingDay, uint8 coolestDay);
    event SmartBurn(uint256 totalSupply, uint256 burnAmount, uint256 snapshotId, uint256 periodId);

    // Modifiers
    modifier onlyCallFromFactory() {
        require(_msgSender() == competitionFactory, "Only call from factory");
        _;
    }

    modifier whenFeeAddressExist() {
        require(feeAddress != address(0), "Fee address should be defined");
        _;
    }

    modifier whenPeriodExist() {
        uint256 periodId = currentPeriod;
        require(periodId > 0 && periods[periodId]._exist == true, "There is no period exist");
        _;
    }

    modifier whenCurrentPeriodInBuyStage() {
        uint ts = block.timestamp;
        (uint start, uint end, uint ticketBuyStart, uint ticketBuyEnd, , , bool exist) = _getPeriod(currentPeriod);
        require(exist == true, "Period does not exist");
        require(_isInRange(ts, start, end) && _isInRange(ts, ticketBuyStart, ticketBuyEnd), "Currently not in the range that can be calculated");
        _;
    }

    // Initializer
    function initialize(address stakeToken_, address feeReceiver_) external initializer {
        require(stakeToken_ != address(0), "Contract address can not be zero");

        __Ownable_init();

        stakeFeePercentage = 2;
        currentPeriod = 0;
        snapshotId = 0;
        coolingDelay = 15 * 24 * 60 * 60;
        coolestDelay = 15 * 24 * 60 * 60;
        coolingPercentage = 15;
        smartBurned = 0;

        stakeToken = IERC20Upgradeable(stakeToken_);
        feeAddress = feeReceiver_;
    }

    // Get snapshot ID
    function getSnapshotId() public view returns (uint) {
        return snapshotId;
    }

    // Update un-stake cooling off settings
    function updateCoolingOffSettings(uint8 percentage_, uint8 coolingDay_, uint8 coolestDay_) external onlyOwner {
        require(percentage_ >= 0 && percentage_ <= 100, "Percentage should be in 0-100 range");
        coolingPercentage = percentage_;
        coolingDelay = (uint256(coolingDay_) * 24 * 60 * 60);
        coolestDelay = (uint256(coolestDay_) * 24 * 60 * 60);
        emit CoolingOffSettingsUpdated(percentage_, coolingDay_, coolestDay_);
    }

    // Get activity details for account
    function getActivityDetails(address account) external view returns (ActivityDetails memory) {
        return activityDetails[account];
    }

    // Get snapshot
    function getSnapshot(address account, uint256 snapshotId_) external view returns (Snapshot memory) {
        return snapshots[account][snapshotId_];
    }

    // Get period
    function getPeriod(uint256 periodId_) external view returns (Period memory) {
        return periods[periodId_];
    }

    // Get period snapshot range
    function getPeriodSnapshotRange(uint256 periodId) external view returns (uint, uint) {
        Period memory period = periods[periodId];
        require(period._exist == true, "Period does not exist");

        uint min = period.firstSnapshotId;
        uint max = (period.lastSnapshotId == 0 ? snapshotId : period.lastSnapshotId);

        return (min, max);
    }

    // BalanceOf - Account
    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    // Increase snapshot counter
    function _snapshot() internal {
        uint256 currentSnapshot = snapshotId;
        snapshotId++;
        totalStakedSnapshot[currentSnapshot] = totalStaked;
        emit SnapshotCreated(currentSnapshot, currentPeriod);
    }

    // Check number is in range
    function _isInRange(uint number, uint min, uint max) internal pure returns (bool) {
        require(min <= max, "Min can not be higher than max");
        return (number >= min && number <= max);
    }

    // Take snapshot
    function snapshot() external onlyOwner {
        uint256 periodId = currentPeriod;
        (, , , , , , bool exist) = _getPeriod(periodId);

        require(exist == true, "No active period exist");

        _snapshot();
    }

    // Set period number
    function setPeriodId(uint256 period) external onlyCallFromFactory returns (uint256) {
        uint256 prevPeriod = currentPeriod;
        uint256 currentSnapshot = snapshotId;
        currentPeriod = period;

        if (periods[prevPeriod]._exist == true) {
            // Set last snapshot of previous period
            periods[prevPeriod].lastSnapshotId = currentSnapshot;
            periods[prevPeriod].isOver = true;
        }

        _snapshot();

        periods[period] = Period(snapshotId, 0, false, true);

        return period;
    }

    // Set competition factory contract address
    function setCompetitionFactory(address competitionFactory_) external onlyOwner {
        require(address(competitionFactory_) != address(0), "Competition factory address can not be zero");
        competitionFactory = competitionFactory_;
    }

    // Set stake fee percentage ratio between 0 and 100
    function setStakeFeePercentage(uint8 stakeFeePercentage_) external onlyOwner {
        require(stakeFeePercentage_ >= 0 && stakeFeePercentage_ < 100, "Fee percentage is not within limits");
        stakeFeePercentage = stakeFeePercentage_;
        emit StakeFeePercentageUpdated(stakeFeePercentage_);
    }

    // Set stake fee address
    function setFeeAddress(address feeAddress_) external onlyOwner {
        require(feeAddress_ != address(0), "Fee address can not be zero");
        feeAddress = feeAddress_;
    }

    // Update account details
    function updateDetails(address account, uint256 previousBalance, uint256 currentBalance) internal {
        uint256 currentSnapshotId = snapshotId;
        ActivityDetails storage details = activityDetails[account];
        Snapshot storage currentSnapshot = snapshots[account][currentSnapshotId];

        // Update current snapshot balance
        currentSnapshot.balance = currentBalance;
        if (currentSnapshot._exist == false) {
            currentSnapshot.prevSnapshotBalance = previousBalance;
            currentSnapshot._exist = true;
        }

        // Update account details
        details.lastSnapshotId = currentSnapshotId;
        details.lastActivityBalance = currentBalance;
        if (details._exist == false) {
            details._exist = true;
        }
    }

    // Stake tokens
    function stake(uint256 amount_) external whenPeriodExist whenFeeAddressExist {
        IERC20Upgradeable token = stakeToken;
        uint256 currentBalance = balanceOf(_msgSender());
        uint256 currentSnapshot = snapshotId;
        uint256 periodId = currentPeriod;
        require(amount_ <= token.balanceOf(_msgSender()), "Insufficient balance");
        require(amount_ <= token.allowance(_msgSender(), address(this)), "Insufficient allowance amount for stake");

        // Transfer tokens from callee to contract
        token.safeTransferFrom(_msgSender(), address(this), amount_);

        // Calculate fee [(A * P) / 100]
        uint256 stakeFee = (amount_ * stakeFeePercentage) / 100;
        // Stake amount [A - C]
        uint256 stakeAmount = amount_ - stakeFee;

        // Increase caller balance
        balances[_msgSender()] += stakeAmount;

        // Send stake fee to receiver address if exist
        if (stakeFee > 0) {
            token.safeTransfer(address(feeAddress), stakeFee);
            emit StakeFeeReceived(stakeFee, currentSnapshot, periodId);
        }

        totalStaked += stakeAmount;

        // Update account details
        updateDetails(_msgSender(), currentBalance, balanceOf(_msgSender()));
        // Emit Stake Event
        emit Stake(_msgSender(), stakeAmount, stakeFee, currentSnapshot, periodId);
    }

    // Get period from factory
    function _getPeriod(uint256 periodId_) internal view returns (uint, uint, uint, uint, uint16, bool, bool) {
        return ICompetitionFactory(competitionFactory).getPeriod(periodId_);
    }

    // Calculate un-stake free amount / cooling off fee amount
    function calculateUnStakeAmounts(uint requestAmount_) public view returns (uint, uint) {
        (uint startTime, , , , , , bool exist) = _getPeriod(currentPeriod);
        uint timestamp = block.timestamp;
        uint CD = coolingDelay;
        uint CSD = coolestDelay;
        uint percentage = coolingPercentage;

        uint fee_ = 0;
        uint amount_ = requestAmount_;

        // Unstake all if period does not exist or cooling delays isn't defined
        if (!exist || (CD == 0 && CSD == 0)) {
            return (fee_, amount_);
        }

        if (timestamp < (startTime + CSD) || startTime >= timestamp) {
            // In coolest period
            fee_ = (requestAmount_ * percentage) / 100;
            amount_ = requestAmount_ - fee_;
        } else if (timestamp >= (startTime + CSD) && timestamp <= (startTime + CSD + CD)) {
            // In cooling period
            uint LCB = (requestAmount_ * percentage) / 100;
            uint RF = ((timestamp - (startTime + CSD)) * LCB / CD);

            amount_ = (requestAmount_ - (LCB - RF));
            fee_ = requestAmount_ - amount_;
        } else {
            // Account can unstake his all balance
            fee_ = 0;
            amount_ = requestAmount_;
        }

        return (fee_, amount_);
    }

    // Un-stake tokens
    function unStake(uint256 amount_) external whenFeeAddressExist {
        uint256 currentBalance = balanceOf(_msgSender());
        uint256 currentSnapshot = snapshotId;
        uint256 periodId = currentPeriod;
        require(amount_ <= currentBalance, "Insufficient balance for unstake");
        require(amount_ > 0, "Amount should higher than zero");

        IERC20Upgradeable token = stakeToken;

        balances[_msgSender()] = balances[_msgSender()].sub(amount_);
        (uint fee, uint free) = calculateUnStakeAmounts(amount_);

        // Update account details
        updateDetails(_msgSender(), currentBalance, balanceOf(_msgSender()));

        totalStaked -= amount_;

        // Distribute fee receiver & smart burn
        if (fee > 0) {
            _distributeFee(fee, currentSnapshot, periodId);
        }

        // Transfer free tokens to user
        token.safeTransfer(_msgSender(), free);

        // Emit UnStake Event
        emit UnStake(_msgSender(), amount_, currentSnapshot, periodId);
    }

    // Burn half of tokens, send remainings
    function _distributeFee(uint256 amount, uint256 snapshotId_, uint256 periodId) internal {
        IERC20Upgradeable tokenSafe = stakeToken;
        IERC20 token = IERC20(address(stakeToken));
        uint256 supply = token.totalSupply();

        uint256 burnAmount = amount / 2;
        uint256 leftAmount = amount - burnAmount;

        if ((supply - burnAmount) < SMART_BURN_SUPPLY_LIMIT) {
            burnAmount = (supply % SMART_BURN_SUPPLY_LIMIT);
            leftAmount = amount - burnAmount;
        }

        _smartBurn(token, supply, burnAmount, snapshotId_, periodId);
        _feeTransfer(tokenSafe, leftAmount, snapshotId_, periodId);
    }

    // Transfer token to receiver with given amount
    function _feeTransfer(IERC20Upgradeable token, uint256 amount, uint256 snapshotId_, uint256 periodId) internal {
        if (amount <= 0) {
            return;
        }

        token.safeTransfer(address(feeAddress), amount);
        emit UnStakeFeeReceived(amount, snapshotId_, periodId);
    }

    // Burn given token with given amount
    function _smartBurn(IERC20 token, uint256 supply, uint256 burnAmount, uint256 snapshotId_, uint256 periodId) internal {
        if (burnAmount <= 0) {
            return;
        }

        token.burn(burnAmount);
        smartBurned += burnAmount;

        emit SmartBurn((supply - burnAmount), burnAmount, snapshotId_, periodId);
    }

    // Get period stake average information
    function _getPeriodStakeAverage(address account, uint256 periodId) internal view returns (uint256, bool) {
        PeriodStakeAverage memory avg = averages[account][periodId];
        return (avg.average, avg._calculated);
    }

    // Get period stake average information
    function getPeriodStakeAverage(address account, uint256 periodId) external view returns (uint256, bool) {
        return _getPeriodStakeAverage(account, periodId);
    }

    // Get snapshot average (Using on stake rewards)
    function getSnapshotAverage(address account, uint256 min, uint256 max) public view returns (uint) {
        uint currentSnapshot = snapshotId;

        require(min <= max, "Max should be equal or higher than max");
        require(max <= currentSnapshot, "Max should be equal or lower than current snapshot");

        ActivityDetails memory details = activityDetails[account];

        // If account hasn't stake activity after `min` snapshot, return last activity balance
        if (details.lastSnapshotId <= min) {
            return details.lastActivityBalance;
        }

        uint stakeSum = 0;
        uint unknownCounter = 0;
        uint lastBalance = 0;
        bool shift = false;

        // Get sum of snapshot stakes
        for (uint i = min; i <= max; ++i) {
            Snapshot memory shot = snapshots[account][i];

            if (shot._exist == false) {
                // Snapshot data does not exist
                if (shift == false) {
                    unknownCounter++;
                } else {
                    stakeSum += (unknownCounter + 1) * lastBalance;
                    unknownCounter = 0;
                }
            } else {
                // Snapshot data is exist
                lastBalance = shot.balance;
                stakeSum += lastBalance;
            }
        }

        if (unknownCounter > 0) {
            // Scan any stake activity from max to currentSnapshotId
            for (uint i = (max + 1); i <= currentSnapshot; ++i) {
                Snapshot memory shot = snapshots[account][i];
                if (shot._exist == true) {
                    stakeSum += (unknownCounter * shot.prevSnapshotBalance);
                    unknownCounter = 0;
                    break;
                }
            }

            // If never activity found until `scanMax`, then average = balanceOf()
            stakeSum += (unknownCounter * balanceOf(account));
            unknownCounter = 0;
        }

        return (stakeSum / (max - min + 1));
    }

    // Get period snapshot average with min/max range
    function getPeriodSnapshotsAverage(address account, uint256 periodId, uint256 min, uint256 max) external view returns (uint256, bool) {
        require(min <= max, "Min should be higher");
        uint256 currentSnapshotId = snapshotId;
        Period memory period = periods[periodId];
        PeriodStakeAverage memory avg = averages[account][periodId];

        // Return if current period average isn't calculated
        if (avg._calculated == false) {
            return (0, false);
        }

        uint maxSnapshot = (period.lastSnapshotId == 0 ? currentSnapshotId : period.lastSnapshotId);

        require(max <= maxSnapshot, "Range max should be lower than current snapshot or period last snapshot");
        require(min >= period.firstSnapshotId && min <= maxSnapshot, "Range min should be higher period first snapshot id");

        uint total = 0;
        uint sCount = (max - min + 1);

        // If the period average is calculated, all storage variables will be filled.
        for (uint i = min; i <= max; ++i) {
            total += snapshots[account][i].balance;
        }

        return ((total / sCount), true);
    }

    // Calculate period stake average for account
    function calculatePeriodStakeAverage() public whenPeriodExist whenCurrentPeriodInBuyStage {
        uint256 periodId = currentPeriod;
        (, bool calculated) = _getPeriodStakeAverage(_msgSender(), periodId);

        require(calculated == false, "Already calculated");

        uint256 total = 0;

        Period memory _period = periods[periodId];

        uint256 shotBalance = 0;
        uint256 nextIB = 0;
        bool shift = false;
        uint256 firstSnapshot = _period.firstSnapshotId;
        uint256 lastSnapshot = snapshotId;

        for (uint i = lastSnapshot; i >= firstSnapshot; --i) {
            Snapshot memory shot = snapshots[_msgSender()][i];

            // Update snapshot balance
            if (i == lastSnapshot) {
                shotBalance = balances[_msgSender()];
            } else if (shot._exist == true) {
                shotBalance = shot.balance;
                nextIB = shot.prevSnapshotBalance;
                shift = true;
            } else {
                if (shift) {
                    shotBalance = nextIB;
                    nextIB = 0;
                    shift = false;
                }
            }

            total += shotBalance;
            shot.balance = shotBalance;
            shot._exist = true;

            snapshots[_msgSender()][i] = shot;
        }

        averages[_msgSender()][periodId] = PeriodStakeAverage((total / (lastSnapshot - firstSnapshot + 1)), true);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) external;

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
    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface ICompetitionFactory {
    function totalPeriodCount() external view returns (uint);
    function totalCompetitionCount() external view returns (uint);
    function createCompetitionPeriod(uint newPeriodId, uint startTime_, uint endTime_, uint ticketBuyStart_, uint ticketBuyEnd_) external returns (uint256);
    function updateCompetitionPeriod(uint periodId_, uint startTime_, uint endTime_, uint ticketBuyStart_, uint ticketBuyEnd_) external returns (bool);
    function getCompetitionIdWithIndex(uint256 periodId, uint index) external view returns (uint);
    function getPeriod(uint256 periodId) external view returns (uint, uint, uint, uint, uint16, bool, bool);
    function getAllocation(address account, uint256 periodId, uint256 competitionId) external view returns (uint32, uint32, bool);
    function getPeriodEndTime(uint256 periodId) external view returns (uint);
    function hasParticipation(address account_, uint256 periodId_) external view returns (bool);
    function isCompetitionSettingsDefined(uint256 periodId, uint256 competitionId) external view returns (bool);
    function getPeriodCompetition(uint256 periodId, uint16 competitionId) external view returns (address, bool);
    function getPeriodCompetitionCount(uint256 periodId) external view returns (uint);
    function pauseCompetitionTransfer(uint256 periodId, uint16 competitionId) external;
    function unpauseCompetitionTransfer(uint256 periodId, uint16 competitionId) external;
    function setCompetitionBaseURI(uint256 periodId, uint16 competitionId, string memory baseUri_) external;
    function setCompetitionDescription(uint256 periodId, uint16 competitionId, string memory description_) external;
    function totalSupplyOfCompetition(uint256 periodId, uint16 competitionId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}