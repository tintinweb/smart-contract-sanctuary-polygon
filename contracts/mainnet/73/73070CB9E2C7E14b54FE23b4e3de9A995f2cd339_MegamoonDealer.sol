/**
 *Submitted for verification at polygonscan.com on 2022-08-31
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
    function returnFunds(uint256 _lotteryId, uint256 _amount, uint256 _totalPrize) external;

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

    address public adminAddress;
    address public treasuryAddress; // pending fee will be sent to this address
    address public lotteryAddress; // megamoon lottery;

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

    // uint256 = id (equal to lottery id), use for reward calculation
    mapping (uint256 => LotteryInjectionInfo) public lotteryInjectionInfos; 
    // track users active or inactive for lottery injection next round
    mapping (address => bool) public isActive;

    /* Arrays cost more than mapping */
    address[] private _users;
    // track users should not be duplicated
    mapping (address => bool) private _registered;
    // track user's staked token
    mapping (address => UserInfo) private _userInfo;
    // Keep track of user injection amount for a given lotteryId
    mapping(address => mapping(uint256 => uint256)) private _userInjectionHistory;
    // Keep track of user return amount for a given lotteryId
    mapping(address => mapping(uint256 => uint256)) private _userRewardHistory;

    uint256 public totalPool = 0;
    uint256 public totalAlloc = 0;
    uint256 public pendingAlloc = 0;
    // store the percentage of injection amount
    uint256 public injectPercentage = 2000; // 2000 = 20%, 100 = 1%
    // processing fee will be taken out form the reward every lottery round ends
    uint256 public processingFee = 10; // 10 = 0.1%
    // Only applies within 3 days of staking. Unstaking after 3 days will not include a fee. Timer resets every time you stake new MOON in the pool.
    uint256 public withdrawFee = 500; // 500 = 5%
    uint256 public withdrawFeePeriod = 336 hours; // 14 days

    uint256 public constant MAX_PROCESSING_FEE = 100; // 100 = 1%
    uint256 public constant MAX_WITHDRAW_FEE = 100; // 100 = 1%
    uint256 public constant MAX_WITHDRAW_FEE_PERIOD = 336 hours; // 14 days (1 hour = 3600 blocks)

    event UserAdded(address indexed user);
    event AdminTokenRecovery(address token, uint256 amount);
    event Deposit(address indexed user, uint256 amount, uint256 lastDepositedTime);
    event Withdraw(address indexed user, uint256 amount);
    event UpdateActiveStatus(address indexed user, bool isActive);
    event NewTreasuryAddress(address indexed treasury);
    event TransferFeeToTreasuryAddress(address indexed treasury, uint256 amount);

    // when inject money to each lottery round
    event InjectToLottery(uint256 lotteryId, uint256 amount);
    // when money come back from the lottery after each round end
    event ReturnFunds(uint256 lotteryId, uint256 amount, uint256 totalPrize);

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
     * @notice Called every times when lottery starts
     */
    function injectToLottery(uint256 _lotteryId) external override returns (uint256) {
        require(msg.sender == lotteryAddress, "MegamoonDealer: Only MegamoonLottery");
        require(totalPool > 0, "No dealer available");

        currentLotteryId = _lotteryId;
        nextLotteryId = _lotteryId + 1;
        uint256 injectAmount = totalPool * injectPercentage / 10000;

        if (injectAmount > 0) {
            moonToken.safeTransfer(address(msg.sender), injectAmount);
        }

        totalPool -= injectAmount;

        lotteryInjectionInfos[currentLotteryId] = LotteryInjectionInfo({
            amount: injectAmount,
            returnAmount: 0,
            injectPercentage: injectPercentage
        });

        emit InjectToLottery(_lotteryId, injectAmount);

        return injectAmount;
    }

    /**
     * @notice Called every times when lottery ends
     */
    function returnFunds(uint256 _lotteryId, uint256 _amount, uint256 _totalPrize) external override {
        require(msg.sender == lotteryAddress, "Only MegamoonLottery");

        uint256 userReward = _amount * (10000 - processingFee) / 10000;
        lotteryInjectionInfos[currentLotteryId].returnAmount = userReward;

        uint256 fee = _amount - userReward;
        if (fee > 0) {
            moonToken.safeTransfer(treasuryAddress, fee);
        }

        uint256 pendingAllocReward = pendingAlloc * lotteryInjectionInfos[currentLotteryId].returnAmount / lotteryInjectionInfos[currentLotteryId].amount;
        totalPool += (lotteryInjectionInfos[currentLotteryId].returnAmount - pendingAllocReward);
        totalAlloc += pendingAllocReward;

        currentLotteryId = nextLotteryId;
        pendingAlloc = 0;

        emit TransferFeeToTreasuryAddress(treasuryAddress, fee);
        emit ReturnFunds(_lotteryId, userReward, _totalPrize);
    }

    function setActiveOrInactive(bool _active) external {
        if (isActive[msg.sender] == _active) { return; }

        UserInfo storage user = _userInfo[msg.sender];
        _updateUserProfit();

        if (isActive[msg.sender]) {      
            totalPool -= user.stakingAmount;
            totalAlloc += user.stakingAmount;
            pendingAlloc += user.lockedAmount;
        } else {
            totalAlloc -= user.stakingAmount;
            totalPool += user.stakingAmount;

            if (user.lotteryId == currentLotteryId && user.lotteryId < nextLotteryId) {
                pendingAlloc -= user.lockedAmount;
            }
        }
        isActive[msg.sender] = _active;

        emit UpdateActiveStatus(msg.sender, _active);
    }

    function changeInjectionPercentage(uint256 _number) external onlyOwner {
        require(_number <= 10000, "over limit");
        require(_number > 0, "> 0");

        injectPercentage = _number;
    }

    /**
     * @notice Sets lottery address
     * @dev Only callable by the contract owner.
     */
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
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @param _tokenAmount: the number of token amount to withdraw
     * @dev Only callable by owner.
     */
    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        require(_tokenAddress != address(moonToken), "Cannot be MOON token");

        IERC20(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);

        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
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

    function totalBalance() external view returns (uint256) {
        return totalPool + totalAlloc + pendingAlloc;
    }

    function activeUserCount() external view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < _users.length; i++) {
            if (isActive[_users[i]] && _viewLatestBalance(_users[i]) > 0) {
                count++;
            }
        }
        return count;
    }

    function viewUserInfo(address user) external view returns (uint256, uint256, uint256) {
        uint256 stakingBalance = _viewLatestBalance(user);
        uint256 lockedBalance = _viewLockedBalance(user);
        uint256 lastDepositTime = _userInfo[user].lastDepositedTime;
        return (stakingBalance, lockedBalance, lastDepositTime);
    }

    /**
     * @dev Getter for the address of users count.
     */
    function usersCount() external view returns (uint256) {
        return _users.length;
    }

    function viewUserInfoByLotteryId(uint256 lotteryId, address userAddress) external view returns (uint256, uint256, uint256) {
        if (lotteryId > currentLotteryId) { return (0, 0, 0); }

        UserInfo storage user = _userInfo[userAddress];
        uint256 injectAmount = 0;
        uint256 rewardAmount = 0;
        uint256 percentage = lotteryInjectionInfos[lotteryId].injectPercentage;

        if (user.lotteryId > lotteryId) {
            injectAmount = _userInjectionHistory[userAddress][lotteryId];
            rewardAmount = _userRewardHistory[userAddress][lotteryId];
            return (injectAmount, rewardAmount, percentage);
        }

        if (!isActive[userAddress]) {
            if (user.lotteryId < lotteryId) {
                return (0, 0, 0);
            } else {
                injectAmount = user.lockedAmount;
                rewardAmount = injectAmount * lotteryInjectionInfos[lotteryId].returnAmount / lotteryInjectionInfos[lotteryId].amount;
                return (injectAmount, rewardAmount, percentage);
            }
        }

        if (user.lotteryId == lotteryId) {
            if (user.lockedAmount > 0) {
                injectAmount = user.lockedAmount;
            } else {
                injectAmount = user.stakingAmount * percentage / 10000;
            }
            rewardAmount = injectAmount * lotteryInjectionInfos[lotteryId].returnAmount / lotteryInjectionInfos[lotteryId].amount;
            return (injectAmount, rewardAmount, percentage);
        }

        uint256 latestBalance = user.stakingAmount;
        uint256 userId = user.lotteryId;

        if (user.lockedAmount > 0) {
            latestBalance += user.lockedAmount * lotteryInjectionInfos[userId].returnAmount / lotteryInjectionInfos[userId].amount;
            userId += 1;
        }

        for (userId; userId < lotteryId; userId++) {
            injectAmount = latestBalance * lotteryInjectionInfos[userId].injectPercentage / 10000;
            rewardAmount = injectAmount * lotteryInjectionInfos[userId].returnAmount / lotteryInjectionInfos[userId].amount;

            latestBalance -= injectAmount;
            latestBalance += rewardAmount;
        }

        injectAmount = latestBalance * percentage / 10000;
        rewardAmount = injectAmount * lotteryInjectionInfos[userId].returnAmount / lotteryInjectionInfos[userId].amount;
        return (injectAmount, rewardAmount, percentage);
    }

    /**
     * @notice Deposits funds into the megamoon dealer
     * @dev The deposit when lottery is running will not be count for the reward until next round.
     * @param _amount: number of tokens to deposit (in MOON)
     */
    function deposit(uint _amount) public {
        require (nextLotteryId > 0, 'lottery not available');
        require (_amount > 0, 'amount 0');
        UserInfo storage user = _userInfo[msg.sender];

        moonToken.safeTransferFrom(address(msg.sender), address(this), _amount);

        if (_registered[msg.sender] == false) { 
            _addUser(msg.sender);
            isActive[msg.sender] = true;
            user.lockedAmount = 0;
            user.lotteryId = nextLotteryId;
        } else {
            _updateUserProfit();
        }

        user.stakingAmount += _amount;
        user.lastDepositedTime = block.timestamp;

        if (isActive[msg.sender]) {
            totalPool += _amount;
        } else {
            totalAlloc += _amount;
        }

        emit Deposit(msg.sender, _amount, block.timestamp);
    }

     /**
     * @notice Withdraws funds for a user from megamoon dealer
     */
    function withdraw(uint _amount) public {
        require (_amount > 0, 'amount 0');

        UserInfo storage user = _userInfo[msg.sender];
        _updateUserProfit();

        require (_amount <= user.stakingAmount, 'withdraw not good');

        uint256 withdrawAmount = _amount;
        uint256 currentWithdrawFee = 0;

        if (block.timestamp < user.lastDepositedTime + withdrawFeePeriod) {
            currentWithdrawFee = withdrawAmount * withdrawFee / 10000;

            moonToken.safeTransfer(treasuryAddress, currentWithdrawFee);
            emit TransferFeeToTreasuryAddress(treasuryAddress, currentWithdrawFee);
        }

        uint256 transferAmount = withdrawAmount - currentWithdrawFee;
        moonToken.safeTransfer(address(msg.sender), transferAmount);
        user.stakingAmount -= withdrawAmount;

        if (isActive[msg.sender]) {
            totalPool -= withdrawAmount;
        } else {
            totalAlloc -= withdrawAmount;
        }

        emit Withdraw(msg.sender, withdrawAmount);
    }

    /**
     * @notice Withdraws all funds for a user from megamoon dealer
     */
    function withdrawAll() public {
        UserInfo storage user = _userInfo[msg.sender];
        _updateUserProfit();

        uint256 withdrawAmount = user.stakingAmount;
        uint256 currentWithdrawFee = 0;

        if (block.timestamp < user.lastDepositedTime + withdrawFeePeriod) {
            currentWithdrawFee = withdrawAmount * withdrawFee / 10000;

            moonToken.safeTransfer(treasuryAddress, currentWithdrawFee);
            emit TransferFeeToTreasuryAddress(treasuryAddress, currentWithdrawFee);
        }

        uint256 transferAmount = withdrawAmount - currentWithdrawFee;
        moonToken.safeTransfer(address(msg.sender), transferAmount);
        user.stakingAmount = 0;

        if (isActive[msg.sender]) {
            totalPool -= withdrawAmount;
        } else {
            totalAlloc -= withdrawAmount;
        }
 
        emit Withdraw(msg.sender, withdrawAmount);
    }

    /**
     * @dev Getter for the address of the user number `index`.
     */
    function dealer(uint256 index) public view returns (address) {
        return _users[index];
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

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     */
    function _addUser(address account) private {
        require(account != address(0), "MegamoonDealer: account is the zero address");
        require(_registered[account] == false, "MegamoonDealer: account already exist");

        _users.push(account);
        _registered[account] = true;
        emit UserAdded(account);
    }

    function _updateUserProfit() private {
        UserInfo storage user = _userInfo[msg.sender];

        if (user.lotteryId == nextLotteryId) {
            return;
        }

        if (user.lotteryId == currentLotteryId && user.lockedAmount > 0) {
            return;
        }

        uint256 latestBalance = user.stakingAmount;

        if (!isActive[msg.sender]) {
            if(user.lockedAmount == 0) {
                user.lotteryId = nextLotteryId;
            }

            if(user.lockedAmount > 0 && lotteryInjectionInfos[user.lotteryId].returnAmount > 0) {
                _userInjectionHistory[msg.sender][user.lotteryId] = user.lockedAmount;
                _userRewardHistory[msg.sender][user.lotteryId] = user.lockedAmount * lotteryInjectionInfos[user.lotteryId].returnAmount / lotteryInjectionInfos[user.lotteryId].amount;

                latestBalance += _userRewardHistory[msg.sender][user.lotteryId];
                user.stakingAmount = latestBalance;
                user.lockedAmount = 0;

                user.lotteryId = nextLotteryId;
            }
            return;
        }

        uint256 userId = user.lotteryId;
            
        if (user.lockedAmount > 0) {
            _userInjectionHistory[msg.sender][userId] = user.lockedAmount;
            _userRewardHistory[msg.sender][userId] = user.lockedAmount * lotteryInjectionInfos[userId].returnAmount / lotteryInjectionInfos[userId].amount;
            latestBalance += _userRewardHistory[msg.sender][userId];
            userId += 1;
        }

        for (userId; userId < currentLotteryId; userId++) {
            uint256 injectAmount = latestBalance * lotteryInjectionInfos[userId].injectPercentage / 10000;
            _userInjectionHistory[msg.sender][userId] = injectAmount;
            uint256 rewardAmount = injectAmount * lotteryInjectionInfos[userId].returnAmount / lotteryInjectionInfos[userId].amount;
            _userRewardHistory[msg.sender][userId] = rewardAmount;

            latestBalance -= injectAmount;
            latestBalance += rewardAmount;
        }

        if (currentLotteryId == nextLotteryId || currentLotteryId == 0) { // lottery close
            user.lockedAmount = 0;
            user.stakingAmount = latestBalance;
        } else {
            user.lockedAmount = latestBalance * lotteryInjectionInfos[userId].injectPercentage / 10000;
            user.stakingAmount = latestBalance - user.lockedAmount;
        }
        user.lotteryId = userId; // currentLotteryId
    }

    function _viewLatestBalance(address userAddress) private view returns (uint256) {
        UserInfo storage user = _userInfo[userAddress];
        uint256 userId = user.lotteryId;
        uint256 latestBalance = user.stakingAmount;

        if (user.lockedAmount > 0) {
            latestBalance += user.lockedAmount * lotteryInjectionInfos[userId].returnAmount / lotteryInjectionInfos[userId].amount;
            userId += 1;
        }

        if (!isActive[userAddress]) {
            return latestBalance;
        }

        for (userId; userId < currentLotteryId; userId++) {
            uint256 injectAmount = latestBalance * lotteryInjectionInfos[userId].injectPercentage / 10000;
            uint256 rewardAmount = injectAmount * lotteryInjectionInfos[userId].returnAmount / lotteryInjectionInfos[userId].amount;

            latestBalance -= injectAmount;
            latestBalance += rewardAmount;
        }

        if (currentLotteryId == nextLotteryId) { // ปิดรอบอยู่
            return latestBalance;
        } else {
            uint256 lockedAmount = latestBalance * lotteryInjectionInfos[userId].injectPercentage / 10000;
            return latestBalance - lockedAmount;
        }
    }

    function _viewLockedBalance(address userAddress) private view returns (uint256) {
        if (currentLotteryId == nextLotteryId) {
            return 0;
        }
    
        UserInfo storage user = _userInfo[userAddress];
        uint256 userId = user.lotteryId;
        uint256 latestBalance = user.stakingAmount;

        if (userId == currentLotteryId && user.lockedAmount > 0) {
            return user.lockedAmount;
        }

        if (!isActive[userAddress]) {
            return 0;
        }

        if (user.lotteryId < currentLotteryId) {
            if (user.lockedAmount > 0) {
                latestBalance += user.lockedAmount * lotteryInjectionInfos[userId].returnAmount / lotteryInjectionInfos[userId].amount;
                userId += 1;
            }
            for (userId; userId < currentLotteryId; userId++) {
                uint256 injectAmount = latestBalance * lotteryInjectionInfos[userId].injectPercentage / 10000;
                uint256 rewardAmount = injectAmount * lotteryInjectionInfos[userId].returnAmount / lotteryInjectionInfos[userId].amount;

                latestBalance -= injectAmount;
                latestBalance += rewardAmount;
            }
        }

        return latestBalance * lotteryInjectionInfos[userId].injectPercentage / 10000;
    }
}