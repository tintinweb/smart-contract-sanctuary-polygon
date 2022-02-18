/**
 *Submitted for verification at polygonscan.com on 2022-02-18
*/

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

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
        // solhint-disable-next-line no-inline-assembly
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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
        // solhint-disable-next-line max-line-length
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
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
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
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


interface IMegamoonLottery {
    /**
     * @notice View current lottery id
     */
    function viewCurrentLotteryId() external returns (uint256);
}

interface IMegamoonDealer {
    /**
     * @notice call returnFunds after the lottery round ends to update the reward amount for users
     */
    function returnFunds(uint256 _lotteryId, uint256 _amount) external;

    /**
     * @notice call injectToLottery when the lottery round starts to inject tokens from dealers
     */
    function injectToLottery(uint256 _lotteryId) external returns (uint256);
}

contract MegamoonDealer is Ownable, IMegamoonDealer {
    using SafeERC20 for IERC20;
    
    IERC20 public moonToken;
    IMegamoonLottery public lottery;

    uint256 public currentLotteryId;
    uint256 public nextLotteryId;

    // use for emergency withdraw (doesn't have this feature yet)
    address public adminAddress;
    // pending fee will be sent to this address
    address public treasuryAddress;
    // megamoon lottery;
    address public lotteryAddress;

    /**
     * @notice Constructor
     * @param _moonToken: MOON token contract
     * @param _admin: address of the admin
     * @param _treasury: address of the treasury (collects fees)
     */
    constructor(
        IERC20 _moonToken,
        address _admin,
        address _treasury
    ) {
        moonToken = _moonToken;
        adminAddress = _admin;
        treasuryAddress = _treasury;
    }

    struct UserInfo {
        uint256 stakingAmount;
        uint256 lockedAmount;
        uint256 lotteryId;
        uint256 lastDepositedTime; // keeps track of deposited time for potential penalty
    }

    struct LotteryInjectionInfo {
        uint256 amount;
        uint256 returnAmount;
        uint256 injectPercentage;
    }

    /* Mapping are cheaper than arrays */
    // uint256 = id (equal to lottery id), use for reward calculation
    mapping (uint256 => LotteryInjectionInfo) public lotteryInjectionInfos;
    // track user's staked token
    mapping (address => UserInfo) public userInfo;
    // count how many dealers
    mapping (uint256 => address) public poolUsers;

    // store the number of users in pool
    uint256 public latestPoolUser;
    // store the percentage of injection amount
    uint256 public injectPercentage = 2000; // 2000 = 20%, 100 = 1%
    // store fee amount took from user and send this amount to the tresury address
    uint256 public pendingFee = 0;
    // processing fee will be taken out form the reward every lottery round ends
    uint256 public processingFee = 10; // 10 = 0.1%
    // Only applies within 3 days of staking. Unstaking after 3 days will not include a fee. Timer resets every time you stake new MOON in the pool.
    uint256 public withdrawFee = 500; // 500 = 5%
    uint256 public withdrawFeePeriod = 336 hours; // 14 days

    uint256 public constant MAX_PROCESSING_FEE = 100; // 100 = 1%
    uint256 public constant MAX_WITHDRAW_FEE = 100; // 100 = 1%
    uint256 public constant MAX_WITHDRAW_FEE_PERIOD = 336 hours; // 14 days (1 hour = 3600 blocks)

    event Deposit(address indexed user, uint256 amount, uint256 lastDepositedTime);
    event Withdraw(address indexed user, uint256 amount);
    event NewTreasuryAddress(address indexed treasury);
    event TransferFeeToTreasuryAddress(address indexed treasury, uint256 amount);

    // when inject money to each lottery round
    event InjectToLottery(uint256 lotteryId, uint256 amount);
    // when money come back from the lottery after each round end
    event ReturnFunds(uint256 lotteryId, uint256 amount);

    /**
     * @notice Checks if the msg.sender is the admin address
     */
    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "admin: wut?");
        _;
    }

    /**
     * @notice Checks if the msg.sender is a contract or a proxy
     */
    modifier notContract() {
        require(!_isContract(msg.sender), "contract not allowed");
        require(msg.sender == tx.origin, "proxy contract not allowed");
        _;
    }

    /**
     * @notice Deposits funds into the megamoon dealer
     * @dev The deposit when lottery is running will not be count for the reward until next round.
     * @param _amount: number of tokens to deposit (in MOON)
     */
    function deposit(uint _amount) public {
        require (nextLotteryId > 0, 'lottery not available');
        require (_amount > 0, 'amount 0');
        UserInfo storage user = userInfo[msg.sender];

        moonToken.safeTransferFrom(address(msg.sender), address(this), _amount);

        if (user.lotteryId == 0) { addLotteryUser(msg.sender); }
        
        user.stakingAmount += _amount;
        user.lastDepositedTime = block.timestamp;

        emit Deposit(msg.sender, _amount, block.timestamp);
    }

     /**
     * @notice Withdraws funds for a user from megamoon dealer
     */
    function withdraw(uint _amount) public {
        UserInfo storage user = userInfo[msg.sender];
        require (_amount > 0, 'amount 0');
        require (_amount <= user.stakingAmount, 'withdraw not good');

        uint256 withdrawAmount = _amount;

        if (block.timestamp < user.lastDepositedTime + withdrawFeePeriod) {
            uint256 currentWithdrawFee = withdrawAmount * withdrawFee / 10000;

            moonToken.safeTransfer(treasuryAddress, currentWithdrawFee);
            emit TransferFeeToTreasuryAddress(treasuryAddress, currentWithdrawFee);

            withdrawAmount -= currentWithdrawFee;
        }

        moonToken.safeTransfer(address(msg.sender), withdrawAmount);
        user.stakingAmount -= withdrawAmount;

        emit Withdraw(msg.sender, withdrawAmount);
    }

    /**
     * @notice Withdraws all funds for a user from megamoon dealer
     */
    function withdrawAll() public {
        UserInfo storage user = userInfo[msg.sender];

        withdraw(user.stakingAmount);
    }

    function updatePool(uint256 lotteryId) private {
        for ( uint256 i = 0; i < latestPoolUser; i++ ) {
            UserInfo storage user = userInfo[poolUsers[i]];
            user.lockedAmount = user.stakingAmount * injectPercentage / 10000;
            user.stakingAmount -= user.lockedAmount;
            user.lotteryId = nextLotteryId;
        }
        nextLotteryId = lotteryId + 1;
    }

    function addLotteryUser(address userAddress) private {
        poolUsers[latestPoolUser] = userAddress;
        latestPoolUser++;
    }

    function totalBalance() external view returns (uint256) {
        return moonToken.balanceOf(address(this));
    }

    function changeInjectionPercentage(uint256 number) external onlyOwner {
        require(number <= 10000, "over limit");
        require(number > 0, "> 0");

        injectPercentage = number;
    }

    function injectToLottery(uint256 _lotteryId) external override returns (uint256) {
        require(msg.sender == lotteryAddress, "Only MegamoonLottery");

        currentLotteryId = lottery.viewCurrentLotteryId();
        updatePool(currentLotteryId);
        require(moonToken.balanceOf(address(this)) > 0, 'transfer failed');
        uint256 availableAmount = moonToken.balanceOf(address(this)) - pendingFee;
        uint256 injectAmount = availableAmount * injectPercentage / 10000;
        moonToken.safeTransfer(address(msg.sender), injectAmount);

        lotteryInjectionInfos[currentLotteryId] = LotteryInjectionInfo({
            amount: injectAmount,
            returnAmount: 0,
            injectPercentage: injectPercentage
        });

        emit InjectToLottery(_lotteryId, injectAmount);

        return injectAmount;
    }
    
    function returnFunds(uint256 _lotteryId, uint256 _amount) external override {
        // require (_amount > 0, 'amount 0');
        require(msg.sender == lotteryAddress, "Only MegamoonLottery");

        lotteryInjectionInfos[currentLotteryId].returnAmount = _amount;
        currentLotteryId++;
        
        uint256 sumUserReward = 0;

        for ( uint256 i = 0; i < latestPoolUser; i++ ) {
            UserInfo storage user = userInfo[poolUsers[i]];
            if (user.lockedAmount > 0) {
                uint256 reward = viewPendingReward(user.lockedAmount, user.lotteryId);
                uint256 userReward = reward * (10000 - processingFee) / 10000;
                sumUserReward += userReward;
                user.stakingAmount += userReward;
                user.lockedAmount = 0;
            }
        }

        pendingFee += (_amount - sumUserReward);

        if(treasuryAddress != address(0x0)) {
            moonToken.safeTransfer(treasuryAddress, pendingFee);
            emit TransferFeeToTreasuryAddress(treasuryAddress, pendingFee);

            pendingFee = 0;
        }

        emit ReturnFunds(_lotteryId, _amount);
    }

    function viewPendingReward(uint256 _amount, uint256 _lotteryId) public view returns (uint256) {
        uint256 reward;
        for (uint256 i = _lotteryId; i < currentLotteryId; i++) {
            reward = _amount * lotteryInjectionInfos[i].returnAmount / lotteryInjectionInfos[i].amount;
        }

        return reward;
    }

    function setLotteryAddress(address _lotteryAddress) external onlyOwner {
        lotteryAddress = _lotteryAddress;
        lottery = IMegamoonLottery(lotteryAddress);
        currentLotteryId = lottery.viewCurrentLotteryId();
        nextLotteryId = 1;
    }

    /**
     * @notice Sets treasury address
     * @dev Only callable by the contract owner.
     */
    function setTreasuryAddress(address _treasuryAddress) external onlyOwner {
        require(_treasuryAddress != address(0), "Cannot be zero address");

        treasuryAddress = _treasuryAddress;

        emit NewTreasuryAddress(_treasuryAddress);
    }
    /**
     * @notice Sets admin address
     * @dev Only callable by the contract owner.
     */
    function setAdmin(address _adminAddress) external onlyAdmin {
        require(_adminAddress != address(0), "Cannot be zero address");
        adminAddress = _adminAddress;
    }

    /**
     * @notice Sets processing fee
     * @dev Only callable by the contract admin.
     */
    function setPerformanceFee(uint256 _performanceFee) external onlyAdmin {
        require(_performanceFee <= MAX_PROCESSING_FEE, "performanceFee cannot be more than MAX_PERFORMANCE_FEE");
        processingFee = _performanceFee;
    }

    /**
     * @notice Sets withdraw fee
     * @dev Only callable by the contract admin.
     */
    function setWithdrawFee(uint256 _withdrawFee) external onlyAdmin {
        require(_withdrawFee <= MAX_WITHDRAW_FEE, "withdrawFee cannot be more than MAX_WITHDRAW_FEE");
        withdrawFee = _withdrawFee;
    }

    /**
     * @notice Sets withdraw fee period
     * @dev Only callable by the contract admin.
     */
    function setWithdrawFeePeriod(uint256 _withdrawFeePeriod) external onlyAdmin {
        require(
            _withdrawFeePeriod <= MAX_WITHDRAW_FEE_PERIOD,
            "withdrawFeePeriod cannot be more than MAX_WITHDRAW_FEE_PERIOD"
        );
        withdrawFeePeriod = _withdrawFeePeriod;
    }

    /**
     * @notice Checks if address is a contract
     * @dev It prevents contract from being targetted
     */
    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
}