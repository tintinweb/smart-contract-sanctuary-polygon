// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// Inheritance
import "./interfaces/ITimelockVault.sol";

/// @title Single asset timelock Vault
/// @author Router Protocol
/// @notice The longer user stake the more APR they receive.

contract TimelockVault is ITimelockVault, ReentrancyGuard {
    using SafeERC20 for IERC20;
    /* ========== STATE VARIABLES ========== */

    struct UserVault {
        uint256 amount;
        uint256 reward;
        uint256 userRewardPerTokenPaid;
        uint256 lockingPeriod;
        uint256 endtime;
        uint256 weight;
    }

    IERC20 public immutable rewardsToken;
    IERC20 public immutable stakingToken;
    uint256 public rewardRate;
    uint256 public rewardPerTokenStored;
    uint256 public maxUserStakeLimit;
    uint256 public maxTotalStakedLimit;

    uint256 public lastUpdated;
    uint256 public penaltyFactor = 20 * 1e6;
    uint256 public maxLock = 10 days;
    uint256 public maxRatio = 2;
    uint256 public totalPenalty;

    address public immutable owner;

    mapping(address => UserVault[]) public userVaults;
    mapping(address => uint256) public userStaked;

    uint256 private _totalSupply;
    uint256 private _totalWeightSupply;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _stakingToken,
        address _rewardsToken,
        uint256 _rewardRate
    ) {
        rewardsToken = IERC20(_rewardsToken);
        stakingToken = IERC20(_stakingToken);
        owner = msg.sender;
        rewardRate = _rewardRate;
        lastUpdated = block.timestamp;
    }

    /* ========== VIEWS ========== */

    /// @notice Returns the total staked amount
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    /// @notice Returns the total weighted supply of staked amount
    function totalWeightSupply() external view returns (uint256) {
        return _totalWeightSupply;
    }

    /// @notice Returns the array of user positions in a vault
    /// @param account address
    function getUserVaultInfo(address account) external view returns (UserVault[] memory) {
        return userVaults[account];
    }

    /// @notice Returns the current reward paid for a staked token
    function rewardPerToken() public view override returns (uint256) {
        if (_totalWeightSupply == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored + (((block.timestamp - lastUpdated) * rewardRate * 1e18) / _totalWeightSupply);
    }

    /// @notice Returns the current unclaimed rewards of a user in provided position
    /// @param account address
    /// @param index of a user's position
    function earned(address account, uint256 index) public view override returns (uint256) {
        UserVault[] memory userVault_ = userVaults[account];
        if (userVault_.length == index) {
            return 0;
        }
        return
            ((userVault_[index].weight * (rewardPerToken() - userVault_[index].userRewardPerTokenPaid)) / 1e18) +
            userVault_[index].reward;
    }

    /// @notice Returns the cumulative rewards of a user in a vault
    /// @param account address
    function calculateAllRewards(address account) external view returns (uint256 rewards) {
        UserVault[] storage userVault_ = userVaults[account];
        uint256 len = userVault_.length;
        for (uint256 i = 0; i < len; i++) {
            rewards += earned(account, i);
        }
    }

    /// @notice Returns the penalty fee for a user to withdraw liquidity prematurely
    /// @param endtime epoch of ending date
    /// @param lockPeriod epoch of number of days
    function calculatePenalty(uint256 endtime, uint256 lockPeriod) public view override returns (uint256) {
        return penaltyFactor - ((penaltyFactor * (lockPeriod - (endtime - block.timestamp))) / lockPeriod);
    }

    /// @notice Returns the weight of user staked amount depends on the time lock frame.
    /// @param lockPeriod epoch of number of days
    function calculateWeightFactor(uint256 lockPeriod) public view override returns (uint256) {
        return ((lockPeriod * maxRatio * 1e18) / maxLock);
    }

    /// @notice Returns all the global states at once
    function getGlobalStates()
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            rewardRate,
            rewardPerTokenStored,
            maxUserStakeLimit,
            maxTotalStakedLimit,
            penaltyFactor,
            maxLock,
            maxRatio
        );
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(uint256 amount, uint256 lockPeriod) external override nonReentrant {
        require(amount > 0, "Cannot stake 0");
        require(_totalSupply + amount < maxTotalStakedLimit, "max User Stake Limit reached");
        require(userStaked[msg.sender] + amount < maxUserStakeLimit, "max User Stake Limit reached");
        require(lockPeriod != 0 && lockPeriod <= maxLock, "Must be < MaxLock");

        (uint256 _earned, uint256 _userRewardPerTokenPaid) = _updateReward(msg.sender, userVaults[msg.sender].length);
        uint256 stakeFactor = (amount * calculateWeightFactor(lockPeriod)) / (1e18);
        UserVault memory userVault_ = UserVault({
            amount: amount,
            lockingPeriod: lockPeriod,
            endtime: lockPeriod + block.timestamp,
            reward: _earned,
            userRewardPerTokenPaid: _userRewardPerTokenPaid,
            weight: stakeFactor
        });
        userVaults[msg.sender].push(userVault_);
        _totalSupply += amount;
        userStaked[msg.sender] += amount;
        _totalWeightSupply += stakeFactor;
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    /// @notice Withdraw staked token after tenure ends
    /// @param index of a caller's position
    function withdraw(uint256 index) public override nonReentrant {
        UserVault storage _userVault = userVaults[msg.sender][index];
        uint256 amount = _userVault.amount;
        require(amount > 0, "Cannot withdraw 0");
        require(block.timestamp >= _userVault.endtime, "Cannot withdraw before lock time");

        (uint256 _earned, uint256 _userRewardPerTokenPaid) = _updateReward(msg.sender, index);
        _userVault.reward = _earned;
        _userVault.userRewardPerTokenPaid = _userRewardPerTokenPaid;

        _totalSupply -= amount;
        _totalWeightSupply -= _userVault.weight;

        _userVault.weight = 0;
        _userVault.amount = 0;
        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    /// @notice Withdraw staked token before tenure ends but need to pay penalty fee
    function withdrawEmergency(uint256 amount, uint256 index) public override nonReentrant {
        require(amount > 0, "Cannot withdraw 0");
        UserVault storage _userVault = userVaults[msg.sender][index];
        (uint256 _earned, uint256 _userRewardPerTokenPaid) = _updateReward(msg.sender, index);
        _userVault.reward = _earned;
        _userVault.userRewardPerTokenPaid = _userRewardPerTokenPaid;

        uint256 penalty = calculatePenalty(_userVault.endtime, _userVault.lockingPeriod);
        uint256 _amount = (amount * (1e8 - penalty)) / 1e8;
        totalPenalty += (amount - _amount);
        _totalSupply -= _amount;
        _totalWeightSupply = _totalWeightSupply - _userVault.weight;
        uint256 weightFactor = _userVault.weight / _userVault.amount;
        _userVault.weight = _userVault.weight - (amount * weightFactor);
        _userVault.amount -= amount;
        stakingToken.safeTransfer(msg.sender, _amount);
        emit Withdrawn(msg.sender, _amount);
    }

    /// @notice Claim the accumulated rewards
    function claimReward(uint256 index) public override nonReentrant {
        UserVault storage _userVault = userVaults[msg.sender][index];
        uint256 reward = _getReward(index, _userVault);
        if (reward > 0) {
            rewardsToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    /// @notice Claim the cumulative rewards of a caller in a vault
    function claimAllRewards() public override nonReentrant {
        UserVault[] storage userVault_ = userVaults[msg.sender];

        uint256 len = userVault_.length;
        uint256 rewards;
        for (uint256 i = 0; i < len; i++) {
            rewards += _getReward(i, userVault_[i]);
            userVault_[i].reward = 0;
        }
        if (rewards > 0) {
            rewardsToken.safeTransfer(msg.sender, rewards);
            emit RewardPaid(msg.sender, rewards);
        }
    }

    function exit(uint256 index) external {
        withdraw(index);
        claimReward(index);
    }

    function _getReward(uint256 index, UserVault storage _userVault) internal returns (uint256) {
        (uint256 _earned, uint256 _userRewardPerTokenPaid) = _updateReward(msg.sender, index);
        _userVault.userRewardPerTokenPaid = _userRewardPerTokenPaid;
        uint256 rewards = _earned;
        _userVault.reward = 0;
        return rewards;
    }

    function _updateReward(address account, uint256 i)
        internal
        returns (uint256 _earned, uint256 _userRewardPerTokenPaid)
    {
        rewardPerTokenStored = rewardPerToken();
        lastUpdated = block.timestamp;

        _earned = earned(account, i);
        _userRewardPerTokenPaid = rewardPerTokenStored;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    //input: 10% -> 10
    function setPenaltyFactor(uint256 factor) external onlyOwner {
        require(factor > 0 && factor < 100, "wrong penalty factor");
        penaltyFactor = factor * 1e6;
    }

    function setMaxRatio(uint256 _ratio) external onlyOwner {
        maxRatio = _ratio;
    }

    function setMaxLock(uint256 _lock) external onlyOwner {
        maxLock = _lock;
    }

    function setMaxUserStakeLimit(uint256 _maxUserStakeLimit) external onlyOwner {
        maxUserStakeLimit = _maxUserStakeLimit;
    }

    function setMaxTotalStakedLimit(uint256 _maxTotalStakedLimit) external onlyOwner {
        maxTotalStakedLimit = _maxTotalStakedLimit;
    }

    function setRewardRate(uint256 _rewardRate) external onlyOwner {
        rewardRate = _rewardRate;
    }

    function withdrawPenalty() external onlyOwner {
        stakingToken.safeTransfer(owner, totalPenalty);
        totalPenalty = 0;
    }

    function rescueFunds(address tokenAddress, address receiver) external onlyOwner {
        require(tokenAddress != address(stakingToken), "TimelockVault: rescue of staking token not allowed");
        IERC20(tokenAddress).transfer(receiver, IERC20(tokenAddress).balanceOf(address(this)));
    }

    /* ========== MODIFIERS ========== */

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not Owner contract");
        _;
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
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

pragma solidity >=0.8.4;

interface ITimelockVault {
    // Views

    function rewardPerToken() external view returns (uint256);

    function earned(address account, uint256 index) external view returns (uint256);

    function calculatePenalty(uint256 endtime, uint256 lockPeriod) external view returns (uint256);

    function calculateWeightFactor(uint256 lockPeriod) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    // Mutative

    function stake(uint256 amount, uint256 lockPeriod) external;

    function withdraw(uint256 index) external;

    function withdrawEmergency(uint256 amount, uint256 index) external;

    function claimReward(uint256 index) external;

    function claimAllRewards() external;

    // function getRewardRestricted(address account) external;

    // function exit() external;
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