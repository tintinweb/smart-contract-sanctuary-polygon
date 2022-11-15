// SPDX-License-Identifier: None

pragma solidity ^0.8.0;

import {SafeERC20} from "SafeERC20.sol";
import {IERC20} from "IERC20.sol";
import {OwnableUpgradeable} from "OwnableUpgradeable.sol";

contract VotingEscrowNaive is OwnableUpgradeable {
    using SafeERC20 for IERC20;

    struct UserLock {
        uint256 amount;
        uint256 till;
    }

    event CreateLock(
        address indexed provider,
        address indexed account,
        uint256 value,
        uint256 indexed locktime
    );

    event IncreaseLockAmount(
        address indexed provider,
        address indexed account,
        uint256 value
    );

    event IncreaseUnlockTime(
        address indexed account,
        uint256 indexed locktime
    );

    event Withdraw(
        address indexed account,
        uint256 value
    );

    event MinLockTimeSet(uint256 value);
    event MinLockAmountSet(uint256 value);
    event MaxPoolMembersSet(uint256 value);
    event IncreaseAmountDisabledSet(bool value);
    event IncreaseUnlockTimeDisabledSet(bool value);
    event CreateLockDisabledSet(bool value);
    event WithdrawDisabledSet(bool value);
    event ClaimRewardsDisabledSet(bool value);
    event Emergency();
    event WindowRewardReceived(
        uint256 indexed window,
        address indexed token,
        uint256 amount
    );
    event UserRewardsClaimed(
        address indexed user,
        uint256 first_processed_window,
        uint256 last_processed_window,
        uint256 totalRewards_MATIC,
        uint256 totalRewards_BITS
    );

    uint256 public constant MAXTIME = 4 * 360 * 24 * 3600;
    uint256 public constant WINDOW = 30 * 24 * 3600;
    uint256 internal constant ONE = 10**18;
    IERC20 public bits;

    mapping (address => UserLock) public locks;
    uint256 public minLockTime;
    uint256 public minLockAmount;
    uint256 public maxPoolMembers;
    uint256 public poolMembers;


    bool public emergency;
    bool public increase_amount_disabled;
    bool public increase_unlock_time_disabled;
    bool public create_lock_disabled;
    bool public withdraw_disabled;
    bool public claim_rewards_disabled;

    string public name;
    string public symbol;
    string public version;
    uint8 constant public decimals = 18;

    mapping (uint256 /*window*/ => uint256) public windowTotalSupply;
    mapping (address /*user*/ => mapping (uint256 /*window*/ => uint256 /*balance*/)) public userWindowBalance;
    mapping (address /*user*/ => uint256 /*window*/) public userLastClaimedWindow;
    mapping (uint256 /*window*/ => uint256 /*rewardPerToken*/) public windowRewardPerToken_MATIC;
    mapping (uint256 /*window*/ => uint256 /*rewardPerToken*/) public windowRewardPerToken_BITS;
    mapping (address /*user*/ => uint256) public userLastClaimedRewardPerToken_MATIC;
    mapping (address /*user*/ => uint256) public userLastClaimedRewardPerToken_BITS;
//    mapping (uint256 /*window*/ => bool) public stuckWindowRewardClaimed;

    function getWindow(uint256 timestamp) public pure returns(uint256) {
        return timestamp / WINDOW * WINDOW;
    }

    function currentWindow() public view returns(uint256) {
        return getWindow(block.timestamp);
    }

    function enableEmergency() external onlyOwner {
        require(!emergency, "already emergency");
        emergency = true;
        emit Emergency();
    }

    function set_increase_amount_disabled(bool _value) external onlyOwner {
        require(increase_amount_disabled != _value, "not changed");
        increase_amount_disabled = _value;
        emit IncreaseAmountDisabledSet(_value);
    }

    function set_increase_unlock_time_disabled(bool _value) external onlyOwner {
        require(increase_unlock_time_disabled != _value, "not changed");
        increase_unlock_time_disabled = _value;
        emit IncreaseUnlockTimeDisabledSet(_value);
    }

    function set_claim_rewards_disabled(bool _value) external onlyOwner {
        require(claim_rewards_disabled != _value, "not changed");
        claim_rewards_disabled = _value;
        emit ClaimRewardsDisabledSet(_value);
    }

    function set_create_lock_disabled(bool _value) external onlyOwner {
        require(create_lock_disabled != _value, "not changed");
        create_lock_disabled = _value;
        emit CreateLockDisabledSet(_value);
    }

    function set_withdraw_disabled(bool _value) external onlyOwner {
        require(withdraw_disabled != _value, "not changed");
        withdraw_disabled = _value;
        emit WithdrawDisabledSet(_value);
    }

    constructor() {}

    function initialize(
        IERC20 _bits,
        string memory _name,
        string memory _symbol,
        string memory _version,
        uint256 _maxPoolMembers,
        uint256 _minLockAmount,
        uint256 _minLockTime
    ) external initializer {
        __Ownable_init();
        bits = _bits;
        name = _name;
        symbol = _symbol;
        version = _version;
        setMaxPoolMembers(_maxPoolMembers);
        setMinLockAmount(_minLockAmount);
        setMinLockTime(_minLockTime);
    }

    function balanceOf(address account) external view returns(uint256) {
        return userWindowBalance[account][currentWindow()];
    }

    function totalSupply() external view returns(uint256) {
        return windowTotalSupply[currentWindow()];
    }

    function setMinLockTime(uint256 value) public onlyOwner {
        minLockTime = value;
        emit MinLockTimeSet(value);
    }

    function setMinLockAmount(uint256 value) public onlyOwner {
        require(value > 0, "zero value");
        minLockAmount = value;
        emit MinLockAmountSet(value);
    }

    function setMaxPoolMembers(uint256 value) public onlyOwner {
        require(value > 0, "zero value");
        maxPoolMembers = value;
        emit MaxPoolMembersSet(value);
    }

    function create_lock(uint256 amount, uint256 till) external {
        _create_lock(msg.sender, amount, till);
    }

    function create_lock_for(address user, uint256 amount, uint256 till) external onlyOwner {
        _create_lock(user, amount, till);
    }

    function _create_lock(address user, uint256 amount, uint256 till) internal {
        require(!emergency, "emergency");
        require(!create_lock_disabled, "disabled");
        require(locks[user].amount == 0, "already locked");
        require(amount > 0, "zero amount");
        require(amount >= minLockAmount, "small amount");

        till = till / WINDOW * WINDOW;
        uint256 _currentWindow = currentWindow();
        require(till > block.timestamp, "too small till");
        uint256 period = till - block.timestamp;
        require(period >= minLockTime, "too small till");
        require(period <= MAXTIME, "too big till");

        uint256 scaledAmount = amount * period / MAXTIME;

        windowTotalSupply[_currentWindow] += scaledAmount;
        userWindowBalance[user][_currentWindow] = scaledAmount;
        userLastClaimedWindow[user] = _currentWindow;
        userLastClaimedRewardPerToken_MATIC[user] = windowRewardPerToken_MATIC[_currentWindow];
        userLastClaimedRewardPerToken_BITS[user] = windowRewardPerToken_BITS[_currentWindow];

        for (uint256 _window = _currentWindow + WINDOW; _window < till; _window += WINDOW) {
            uint256 _windowScaledAmount = scaledAmount * (till - _window) / period;
            windowTotalSupply[_window] += _windowScaledAmount;
            userWindowBalance[user][_window] = _windowScaledAmount;
        }

        poolMembers += 1;
        require(poolMembers <= maxPoolMembers, "max pool members exceed");
        locks[user] = UserLock(amount, till);
        emit CreateLock({
            provider: msg.sender,
            account: user,
            value: amount,
            locktime: till
        });
        bits.safeTransferFrom(msg.sender, address(this), amount);  // note: transferred from msg.sender
    }

    function increase_unlock_time(uint256 till) external {
        require(!emergency, "emergency");
        require(!increase_unlock_time_disabled, "disabled");
        UserLock memory lock = locks[msg.sender];
        require(lock.amount > 0, "nothing locked");

        till = till / WINDOW * WINDOW;
        require(lock.till > block.timestamp, "expired lock, withdraw first");
        require(till > lock.till, "not increased");

        claim_rewards();

        uint256 _currentWindow = currentWindow();
        require(till > block.timestamp, "too small till");
        uint256 period = till - block.timestamp;
        require(period >= minLockTime, "too small till");
        require(period <= MAXTIME, "too big till");

        uint256 scaledAmount = lock.amount * period / MAXTIME;

        windowTotalSupply[_currentWindow] =
            windowTotalSupply[_currentWindow] - userWindowBalance[msg.sender][_currentWindow] + scaledAmount;
        userWindowBalance[msg.sender][_currentWindow] = scaledAmount;

        // this not need because claim_rewards already called
//        userLastClaimedWindow[msg.sender] = _currentWindow;
//        userLastClaimedRewardPerToken_MATIC[msg.sender] = windowRewardPerToken_MATIC[_currentWindow];
//        userLastClaimedRewardPerToken_BITS[msg.sender] = windowRewardPerToken_BITS[_currentWindow];

        for (uint256 _window = _currentWindow + WINDOW; _window < till; _window += WINDOW) {
            uint256 _windowScaledAmount = scaledAmount * (till - _window) / period;
            windowTotalSupply[_window] =
                windowTotalSupply[_window] - userWindowBalance[msg.sender][_window] + _windowScaledAmount;
            userWindowBalance[msg.sender][_window] = _windowScaledAmount;
        }

        locks[msg.sender].till = till;
        emit IncreaseUnlockTime({
            account: msg.sender,
            locktime: till
        });
    }

    function increase_lock_amount_for(address user, uint256 amount) external onlyOwner {
        _increase_lock_amount(user, amount);
    }

    function increase_lock_amount(uint256 amount) external {
        _increase_lock_amount(msg.sender, amount);
    }

    function _increase_lock_amount(address user, uint256 amount) internal {
        require(!emergency, "emergency");
        require(!increase_amount_disabled, "disabled");
        UserLock memory lock = locks[user];
        require(lock.amount > 0, "nothing locked");
        require(amount > 0, "zero amount");
        require(amount >= minLockAmount, "small amount");
        require(lock.till > block.timestamp, "expired lock, withdraw first");

        uint256 _currentWindow = currentWindow();
        uint256 period = lock.till - block.timestamp;
        require(period >= minLockTime, "too small till");
        require(period <= MAXTIME, "too big till");

        claim_rewards();

        uint256 scaledAmount = amount * period / MAXTIME;

        windowTotalSupply[_currentWindow] += scaledAmount;
        userWindowBalance[user][_currentWindow] += scaledAmount;

        // not need because claim_rewards is already called
//        userLastClaimedWindow[user] = _currentWindow;
//        userLastClaimedRewardPerToken_MATIC[user] = windowRewardPerToken_MATIC[_currentWindow];
//        userLastClaimedRewardPerToken_BITS[user] = windowRewardPerToken_BITS[_currentWindow];

        for (uint256 _window = _currentWindow + WINDOW; _window < lock.till; _window += WINDOW) {
            uint256 _windowScaledAmount = scaledAmount * (lock.till - _window) / period;
            windowTotalSupply[_window] += _windowScaledAmount;
            userWindowBalance[user][_window] += _windowScaledAmount;
        }

        locks[user].amount += amount;
        emit IncreaseLockAmount({
            provider: msg.sender,
            account: user,
            value: amount
        });
        bits.safeTransferFrom(msg.sender, address(this), amount);  // note: transferred from msg.sender
    }

    function withdraw() external {
        UserLock memory lock = locks[msg.sender];
        require(lock.amount != 0, "nothing locked");
        require(block.timestamp >= lock.till, "too early");

        if (emergency) {
            // erase storage
            locks[msg.sender] = UserLock(0, 0);
            userLastClaimedWindow[msg.sender] = 0;
            userLastClaimedRewardPerToken_BITS[msg.sender] = 0;
            userLastClaimedRewardPerToken_MATIC[msg.sender] = 0;
            emit Withdraw(msg.sender, lock.amount);
            bits.safeTransfer(msg.sender, lock.amount);
            return;
        }

        claim_rewards();

        // erase storage
        locks[msg.sender] = UserLock(0, 0);
        userLastClaimedWindow[msg.sender] = 0;
        userLastClaimedRewardPerToken_BITS[msg.sender] = 0;
        userLastClaimedRewardPerToken_MATIC[msg.sender] = 0;
        poolMembers -= 1;

        emit Withdraw(msg.sender, lock.amount);
        bits.safeTransfer(msg.sender, lock.amount);
    }

    function user_claimable_rewards(
        address user
    ) public view returns(
        uint256 totalRewards_MATIC,
        uint256 totalRewards_BITS
    ) {
        UserLock memory lock = locks[user];
        require(lock.amount > 0, "nothing lock");
        uint256 _currentWindow = currentWindow();

        totalRewards_MATIC = 0;
        totalRewards_BITS = 0;
        uint256 _startWindow = userLastClaimedWindow[user];
        for(
            uint256 _processingWindow = _startWindow;
            _processingWindow <= _currentWindow;
            _processingWindow += WINDOW
        ) {
            uint256 _userWindowBalance = userWindowBalance[user][_processingWindow];
            uint256 reward_MATIC;
            uint256 reward_BITS;
            uint256 _windowRewardPerToken_MATIC = windowRewardPerToken_MATIC[_processingWindow];
            uint256 _windowRewardPerToken_BITS = windowRewardPerToken_BITS[_processingWindow];

            if (_processingWindow == _startWindow) {
                uint256 _lastClaimedRewardPerToken_MATIC = userLastClaimedRewardPerToken_MATIC[user];
                uint256 _lastClaimedRewardPerToken_BITS = userLastClaimedRewardPerToken_BITS[user];
                reward_MATIC = _userWindowBalance * (_windowRewardPerToken_MATIC - _lastClaimedRewardPerToken_MATIC) / ONE;
                reward_BITS = _userWindowBalance * (_windowRewardPerToken_BITS - _lastClaimedRewardPerToken_BITS) / ONE;
            } else {
                reward_MATIC = _userWindowBalance * _windowRewardPerToken_MATIC / ONE;
                reward_BITS = _userWindowBalance * _windowRewardPerToken_BITS / ONE;
            }

            totalRewards_MATIC += reward_MATIC;
            totalRewards_BITS += reward_BITS;
        }
    }

    function claim_rewards() public {
        require(!emergency, "emergency");
        require(!claim_rewards_disabled, "disabled");
        (uint256 totalRewards_MATIC, uint256 totalRewards_BITS) = user_claimable_rewards(msg.sender);

        uint256 _currentWindow = currentWindow();
        emit UserRewardsClaimed({
            user: msg.sender,
            first_processed_window: userLastClaimedWindow[msg.sender],
            last_processed_window: _currentWindow,
            totalRewards_MATIC: totalRewards_MATIC,
            totalRewards_BITS: totalRewards_BITS
        });
        userLastClaimedWindow[msg.sender] = _currentWindow;
        userLastClaimedRewardPerToken_MATIC[msg.sender] = windowRewardPerToken_MATIC[_currentWindow];
        userLastClaimedRewardPerToken_BITS[msg.sender] = windowRewardPerToken_BITS[_currentWindow];

        bits.safeTransfer(msg.sender, totalRewards_BITS);
        (bool success, ) = msg.sender.call{value: totalRewards_MATIC}("");
        require(success, "transfer MATIC failed");
    }

//    function claim_stuck_rewards(uint256 _window) external onlyOwner {
//        require(_window < _currentWindow(), "unfinalized window");
//        require(!stuckWindowRewardClaimed[_window], "already claimed");
//        stuckWindowRewardClaimed[_window] = True;
//
//        _windowReward: uint256 = self.window_token_rewards[_window][_token]
//        if _windowReward == 0:
//            log Log1Args("skip _window {0} because _windowReward=0", _window)
//            return
//
//        _avgTotalSupply: uint256 = self._averageTotalSupplyOverWindow(_window)
//        assert _avgTotalSupply == 0, "reward not stuck"
//
//        log StuckWindowRewardClaimed(_window, _token, _windowReward)
//        self.any_transfer(_token, msg.sender, _windowReward)
//    }

    function receiveReward_BITS(uint256 amount) external {
        uint256 _currentWindow = currentWindow();
        uint256 _windowTotalSupply = windowTotalSupply[_currentWindow];
        require(_windowTotalSupply != 0, "no pool members");
        windowRewardPerToken_BITS[_currentWindow] += amount * ONE / _windowTotalSupply;
        emit WindowRewardReceived(_currentWindow, address(bits), amount);
        bits.safeTransferFrom(msg.sender, address(this), amount);
    }

    function receiveReward_MATIC(uint256 amount) external payable {
        uint256 _currentWindow = currentWindow();
        uint256 _windowTotalSupply = windowTotalSupply[_currentWindow];
        require(_windowTotalSupply != 0, "no pool members");
        emit WindowRewardReceived(_currentWindow, address(0), amount);
        windowRewardPerToken_MATIC[_currentWindow] += msg.value * ONE / _windowTotalSupply;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC20.sol";
import "Address.sol";

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

pragma solidity ^0.8.0;

import "ContextUpgradeable.sol";
import "Initializable.sol";

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
import "Initializable.sol";

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