// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract HollandStakingContract is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    enum StakingPeriod {
        StakingPeriodInvalid,
        StakingPeriodMonth,
        StakingPeriod2Months,
        StakingPeriodYear,
        StakingPeriod2Years,
        StakingPeriod3Years,
        StakingPeriod4Years,
        StakingPeriod5Years
    }

    struct Deposit {
        uint256 amount;
        uint256 startTime;
        StakingPeriod stakingPeriod;
        uint256 rewardsClaimed;
        uint256 lastRewardsClaimTimestamp;
    }

    struct Account {
        uint256 indecesBitmap;
        Deposit[] stakingDeposits;
    }

    uint256 constant internal durationMonth = 30 days;
    uint256 constant internal duration2Months = 60 days;
    uint256 constant internal durationYear = 365 days;
    uint256 constant internal duration2Years = durationYear * 2;
    uint256 constant internal duration3Years = durationYear * 3;
    uint256 constant internal duration4Years = durationYear * 4;
    uint256 constant internal duration5Years = durationYear * 5;

    uint constant public rewardsClamingCooldown = 7 days;

    uint256 public remainingRewardsAmount;

    IERC20 public token;
    uint32 public abortStakingPenaltyPercents;
    uint256 public totalPenalty;
    uint32[8] public stakingRewardPercents;
    mapping(address => Account) public accounts;

    event DepositCreate(address account, uint256 index, uint256 amount, StakingPeriod stakingPeriod);
    event RewardWithdraw(address account, uint256 index, uint256 reward);
    event DepositWithdraw(address account, uint256 index);
    event AddRewards(uint256 amount);

    constructor(IERC20 token_,
            uint32 abortStakingPenaltyPercents_,
            uint32 stakingMonthRewardPercents_,
            uint32 staking2MonthsRewardPercents_,
            uint32 stakingYearRewardPercents_,
            uint32 staking2YearsRewardPercents_,
            uint32 staking3YearsRewardPercents_,
            uint32 staking4YearsRewardPercents_,
            uint32 staking5YearsRewardPercents_)
    {
        require(address(token_) != address(0), "Zero address");
        token = token_;
        abortStakingPenaltyPercents = abortStakingPenaltyPercents_;
        stakingRewardPercents[uint(StakingPeriod.StakingPeriodInvalid)] = 0;
        stakingRewardPercents[uint(StakingPeriod.StakingPeriodMonth)] = stakingMonthRewardPercents_;
        stakingRewardPercents[uint(StakingPeriod.StakingPeriod2Months)] = staking2MonthsRewardPercents_;
        stakingRewardPercents[uint(StakingPeriod.StakingPeriodYear)] = stakingYearRewardPercents_;
        stakingRewardPercents[uint(StakingPeriod.StakingPeriod2Years)] = staking2YearsRewardPercents_;
        stakingRewardPercents[uint(StakingPeriod.StakingPeriod3Years)] = staking3YearsRewardPercents_;
        stakingRewardPercents[uint(StakingPeriod.StakingPeriod4Years)] = staking4YearsRewardPercents_;
        stakingRewardPercents[uint(StakingPeriod.StakingPeriod5Years)] = staking5YearsRewardPercents_;
    }


    function getDepositIndices(address account) external view returns(uint256 indecesBitmap) {
        require(account != address(0), "Zero address");
        indecesBitmap = accounts[account].indecesBitmap;
    }

    function getDepositInfo(address account, uint256 index) public view returns (uint256 amount, uint256 startTime, StakingPeriod period, uint256 lastRewardsClaimTimestamp, uint256 rewardsAmount) {
        require(account != address(0), "Zero address");
        require((accounts[account].indecesBitmap & (1 << index)) != 0, "No deposit at this slot");
        amount = accounts[account].stakingDeposits[index].amount;
        startTime = accounts[account].stakingDeposits[index].startTime;
        period = accounts[account].stakingDeposits[index].stakingPeriod;
        lastRewardsClaimTimestamp = accounts[account].stakingDeposits[index].lastRewardsClaimTimestamp;
        uint256 rewards = calculateRewardsAmount(accounts[account].stakingDeposits[index]);
        rewardsAmount = rewards > remainingRewardsAmount ? remainingRewardsAmount : rewards;
    }

    function addRewards(uint256 amount) external onlyOwner {
        token.safeTransferFrom(msg.sender, address(this), amount);
        remainingRewardsAmount += amount;
        emit AddRewards(amount);
    }

    function withdrawPenalty(uint256 amount) external onlyOwner {
        require(totalPenalty >= amount, "Insufficient penalty amount");
        totalPenalty -= amount;
        token.safeTransfer(msg.sender, amount);
    }

    function createDeposit(uint256 amount, StakingPeriod stakingPeriod) external nonReentrant returns(uint256) {
        require(accounts[msg.sender].indecesBitmap != ~uint256(0), "No free slots for deposit");
        require(stakingPeriod > StakingPeriod.StakingPeriodInvalid && stakingPeriod <= StakingPeriod.StakingPeriod5Years, "Invalid staking period");

        token.safeTransferFrom(msg.sender, address(this), amount);

        Deposit memory deposit = Deposit(amount, block.timestamp, stakingPeriod, 0, block.timestamp);

        // try to find free slot in deposits array
        bool slotFound = false;
        for (uint256 i = 0; i < accounts[msg.sender].stakingDeposits.length; i++) {
            // index is contain deposit entry, go next
            if ((accounts[msg.sender].indecesBitmap & (1 << i)) != 0) {
                continue;
            }
            else {
                slotFound = true;
                accounts[msg.sender].stakingDeposits[i] = deposit;
                // set index flag
                accounts[msg.sender].indecesBitmap |= 1 << i;
                emit DepositCreate(msg.sender, i, amount, stakingPeriod);
                return i;
            }
        }
        if (!slotFound) {
            accounts[msg.sender].stakingDeposits.push(deposit);
            // set index flag
            uint256 index = accounts[msg.sender].stakingDeposits.length - 1;
            accounts[msg.sender].indecesBitmap |= 1 << index;
            slotFound = true;
            emit DepositCreate(msg.sender, index, amount, stakingPeriod);
            return index;
        }
    }

    function getDurationByStakingPeriod(StakingPeriod period) internal pure returns (uint256) {
        if (period == StakingPeriod.StakingPeriodMonth) {
            return durationMonth;
        }
        else if (period == StakingPeriod.StakingPeriod2Months) {
            return duration2Months;
        }
        else if (period == StakingPeriod.StakingPeriodYear) {
            return durationYear;
        }
        else if (period == StakingPeriod.StakingPeriod2Years) {
            return duration2Years;
        }
        else if (period == StakingPeriod.StakingPeriod3Years) {
            return duration3Years;
        }
        else if (period == StakingPeriod.StakingPeriod4Years) {
            return duration4Years;
        }
        else if (period == StakingPeriod.StakingPeriod5Years) {
            return duration5Years;
        }
        else {
            return ~uint256(0);
        }
    }

    function getReachedStakingPeriod(uint256 stakingDuration) internal pure returns (StakingPeriod) {
        if (stakingDuration >= duration5Years) {
            return StakingPeriod.StakingPeriod5Years;
        }
        else if (stakingDuration >= duration4Years) {
            return StakingPeriod.StakingPeriod4Years;
        }
        else if (stakingDuration >= duration3Years) {
            return StakingPeriod.StakingPeriod3Years;
        }
        else if (stakingDuration >= duration2Years) {
            return StakingPeriod.StakingPeriod2Years;
        }
        else if (stakingDuration >= durationYear) {
            return StakingPeriod.StakingPeriodYear;
        }
        else if (stakingDuration >= duration2Months) {
            return StakingPeriod.StakingPeriod2Months;
        }
        else if (stakingDuration >= durationMonth) {
            return StakingPeriod.StakingPeriodMonth;
        }
        else {
            return StakingPeriod.StakingPeriodInvalid;
        }
    }

    function calculateRewardsAmount(Deposit memory deposit) internal view returns (uint256 amount) {
        bool targetPeriodIsReached = (block.timestamp - deposit.startTime) >= getDurationByStakingPeriod(deposit.stakingPeriod);
        uint stakingDays = (block.timestamp - deposit.startTime) / 1 days;
        StakingPeriod reachedPeriod;
        if (targetPeriodIsReached) {
            reachedPeriod = deposit.stakingPeriod;
        }
        else {
            reachedPeriod = getReachedStakingPeriod(block.timestamp - deposit.startTime);
        }
        if (reachedPeriod == StakingPeriod.StakingPeriodInvalid) {
            amount = 0;
        }
        else {
            amount = (deposit.amount * stakingRewardPercents[uint(reachedPeriod)] * stakingDays) / (getDurationByStakingPeriod(reachedPeriod) / 1 days) / 100;
            amount = amount > deposit.rewardsClaimed ? amount - deposit.rewardsClaimed : 0;
        }
    }

    function withdrawRewards(uint256 index) external {
        require(remainingRewardsAmount > 0, "No more rewards");
        require((accounts[msg.sender].indecesBitmap & (1 << index)) != 0, "No deposit at this slot");
        require(block.timestamp - accounts[msg.sender].stakingDeposits[index].lastRewardsClaimTimestamp >= rewardsClamingCooldown, 
                "Must wait cooldown since last reward claiming");

        uint256 rewardsAmount = calculateRewardsAmount(accounts[msg.sender].stakingDeposits[index]);

        require(rewardsAmount > 0, "No rewards available");

        if (rewardsAmount > remainingRewardsAmount) {
            rewardsAmount = remainingRewardsAmount;
        }

        remainingRewardsAmount -= rewardsAmount;
        accounts[msg.sender].stakingDeposits[index].rewardsClaimed += rewardsAmount;
        accounts[msg.sender].stakingDeposits[index].lastRewardsClaimTimestamp = block.timestamp;

        token.safeTransfer(msg.sender, rewardsAmount);
        emit RewardWithdraw(msg.sender, index, rewardsAmount);
    }

    function withdrawDeposit(uint256 index) external {
        require((accounts[msg.sender].indecesBitmap & (1 << index)) != 0, "No deposit at this slot");
        bool targetPeriodIsReached = (block.timestamp - accounts[msg.sender].stakingDeposits[index].startTime) >= getDurationByStakingPeriod(accounts[msg.sender].stakingDeposits[index].stakingPeriod);
        uint256 rewardsAmount = calculateRewardsAmount(accounts[msg.sender].stakingDeposits[index]);

        if (rewardsAmount > remainingRewardsAmount) {
            rewardsAmount = remainingRewardsAmount;
        }

        uint256 amount = accounts[msg.sender].stakingDeposits[index].amount + rewardsAmount;
        if (!targetPeriodIsReached && (remainingRewardsAmount != 0)) {
            uint256 penalty = accounts[msg.sender].stakingDeposits[index].amount * abortStakingPenaltyPercents / 100;
            amount -= penalty;
            totalPenalty += penalty;
        }

        remainingRewardsAmount -= rewardsAmount;

        accounts[msg.sender].indecesBitmap &= ~(1 << index);
        token.safeTransfer(msg.sender, amount);
        emit DepositWithdraw(msg.sender, index);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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