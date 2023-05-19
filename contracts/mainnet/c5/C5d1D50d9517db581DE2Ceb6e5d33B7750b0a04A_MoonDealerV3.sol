/**
 *Submitted for verification at polygonscan.com on 2023-05-19
*/

pragma solidity ^0.8.0;

// SPDX-License-Identifier: LGPL-3.0-only

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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data
    ) internal view returns (bytes memory) {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
    function functionDelegateCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SafeERC20: decreased allowance below zero"
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
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

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

/*
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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

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
     * by making the `nonReentrant` function external, and make it call a
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

interface IMoonLottery {
    /**
     * @notice View current lottery id
     */
    function viewCurrentLotteryId() external returns (uint256);
}

interface IMoonDealer {
    /**
     * @notice call returnFunds after the lottery round ends to update the reward amount for users
     */
    function returnFunds(
        uint256 _lotteryId,
        uint256 _amount,
        uint256 _totalPrize
    ) external;

    /**
     * @notice call injectToLottery when the lottery round starts to inject tokens from dealers
     */
    function injectToLottery(uint256 _lotteryId) external returns (uint256);
}

interface IValidator {
    function checkMegamoonWallet(address _user) external view returns (bool);
}

contract MoonDealerV3 is ReentrancyGuard, Ownable, IMoonDealer {
    using SafeERC20 for IERC20;

    IERC20 public moonToken;
    IMoonLottery private lottery;

    /* Arrays cost more than mapping */
    mapping(uint256 => address) private _users; // start from index 0 to userIndex

    // user information
    mapping(address => uint256) private _staking;
    mapping(address => uint256) private _alloc;
    mapping(address => uint256) private _roundId;
    mapping(address => uint256) private _lastDepositedTime;
    mapping(address => uint32) private _injectPercent;

    mapping(uint256 => uint256) private _lotteryInjectAmountByRound;
    mapping(uint256 => uint256) private _lotteryReturnAmountByRound;

    uint256 private constant MAX_PROCESSING_FEE = 3000; // 3000 = 30%
    uint256 private constant MAX_WITHDRAW_FEE = 2000; // 2000 = 20%
    uint256 private constant MAX_WITHDRAW_FEE_PERIOD = 744 hours; // 31 days (1 hour = 3600 blocks)
    uint256 private constant MAX_MINIMUM_DEPOSIT = 30000000; // 30
    uint256 private constant MAX_MINIMUM_WITHDRAW = 30000000; // 30
    uint256 private constant RESERVE_DIGITS = 10000000000;

    address public treasuryAddress; // pending fee will be sent to this address
    address public lotteryAddress; // moon lottery;
    address public validator;

    uint256 public currentLotteryId;
    uint256 public userIndex;
    uint256 public minimumDeposit = 10000000; // 10
    uint256 public minimumWithdraw = 10000000; // 10
    uint256 public withdrawFeePeriod = 168 hours; // 7 days
    uint256 public floatFee;

    // processing fee will be taken out form the reward every lottery round ends
    uint32 public processingFee = 0; // 0 = no processing fee, 10 = 0.1%
    // unstaking after withdraw fee period will not include a fee. Timer resets every time you stake new MOON in the pool.
    uint32 public withdrawFee = 500; // 500 = 5%

    bool public isLotteryClose;

    mapping(uint32 => uint256) public pool; // [0-100]
    mapping(uint32 => uint256) public pendingAlloc; // [0-100]

    event UserAdded(address indexed user);
    event AdminTokenRecovery(address token, uint256 amount);
    event Deposit(
        address indexed user,
        uint256 amount,
        uint256 lastDepositedTime
    );
    event Withdraw(address indexed user, uint256 amount);
    event UpdatePercentage(address indexed user, uint32 percent);
    event TransferFeeToTreasuryAddress(
        address indexed treasury,
        uint256 amount
    );

    // when inject money to each lottery round
    event InjectToLottery(uint256 indexed lotteryId, uint256 amount);
    // when money come back from the lottery after each round end
    event ReturnFunds(
        uint256 indexed lotteryId,
        uint256 amount,
        uint256 totalPrize
    );

    event NewProcessingFee(uint32 processingFee);
    event NewWithfrawFee(uint32 withdrawFee);
    event NewWithfrawFeePeriod(uint256 withdrawFeePeriod);
    event NewMinimumDeposit(uint256 number);
    event NewMinimumWithdraw(uint256 number);

    modifier onlyMegamoonUser() {
        require(
            IValidator(validator).checkMegamoonWallet(msg.sender),
            "not megamoon wallet"
        );
        _;
    }

    /**
     * @notice Constructor
     * @param _moonToken: MOON token contract
     * @param _treasury: address of the treasury (collects fees)
     */
    constructor(IERC20 _moonToken, address _treasury, address _validator) {
        moonToken = _moonToken;
        treasuryAddress = _treasury;
        validator = _validator;
        isLotteryClose = true;
    }

    /**
     * @notice Called every times when lottery starts
     */
    function injectToLottery(
        uint256 _lotteryId
    ) external override nonReentrant returns (uint256) {
        require(msg.sender == lotteryAddress, "MoonDealer: Only MoonLottery");

        uint256 injectAmount;
        uint256 newPendingAlloc;

        for (uint32 i = 1; i <= 100; i = unsafe_inc_32(i)) {
            if (pool[i] != 0) {
                newPendingAlloc = (pool[i] * i) / 100;
                injectAmount += newPendingAlloc;
                pendingAlloc[i] = newPendingAlloc;
                pool[i] -= newPendingAlloc;
            }
        }

        require(injectAmount > 0, "No dealer available");

        _lotteryInjectAmountByRound[_lotteryId] = injectAmount;

        injectAmount /= RESERVE_DIGITS;

        moonToken.safeTransfer(address(msg.sender), injectAmount);

        currentLotteryId = _lotteryId;
        isLotteryClose = false;

        emit InjectToLottery(_lotteryId, injectAmount);

        return injectAmount;
    }

    /**
     * @notice Called every times when lottery ends
     */
    function returnFunds(
        uint256 _lotteryId,
        uint256 _amount,
        uint256 _totalPrize
    ) external override nonReentrant {
        require(msg.sender == lotteryAddress, "Only MoonLottery");
        require(_lotteryId == currentLotteryId, "Not current lottery round");

        uint256 amount = (_amount * RESERVE_DIGITS) +
            (_lotteryInjectAmountByRound[_lotteryId] % RESERVE_DIGITS);
        uint256 fee = (amount * processingFee) / 10000;
        uint256 apxTurnOver = amount - fee;
        uint256 turnOver;
        uint256 turnOverbyRound;

        for (uint32 i = 0; i <= 100; i = unsafe_inc_32(i)) {
            if (pendingAlloc[i] != 0) {
                turnOverbyRound =
                    (pendingAlloc[i] * apxTurnOver) /
                    _lotteryInjectAmountByRound[_lotteryId];
                pendingAlloc[i] = 0;
                pool[i] += turnOverbyRound;
                turnOver += turnOverbyRound;
            }
        }

        _lotteryReturnAmountByRound[_lotteryId] = turnOver;

        fee = (amount - turnOver) + floatFee;

        if (fee % RESERVE_DIGITS > 0) {
            floatFee = fee % RESERVE_DIGITS;
        }

        uint256 transferFee = fee / RESERVE_DIGITS;

        if (transferFee > 0) {
            moonToken.safeTransfer(treasuryAddress, transferFee);
            emit TransferFeeToTreasuryAddress(treasuryAddress, transferFee);
        }

        ++currentLotteryId;
        isLotteryClose = true;

        emit ReturnFunds(_lotteryId, turnOver / RESERVE_DIGITS, _totalPrize);
    }

    /**
     * @notice Sets lottery address
     * @dev Only callable by the contract owner.
     */
    function setLotteryAddress(address _lotteryAddress) external onlyOwner {
        require(currentLotteryId == 0, "Lottery address already set");

        lotteryAddress = _lotteryAddress;
        lottery = IMoonLottery(lotteryAddress);
        currentLotteryId = 1;
        isLotteryClose = true;
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @param _tokenAmount: the number of token amount to withdraw
     * @dev Only callable by owner.
     */
    function recoverWrongTokens(
        address _tokenAddress,
        uint256 _tokenAmount
    ) external onlyOwner {
        require(_tokenAddress != address(moonToken), "Cannot be MOON token");

        IERC20(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);

        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }

    /**
     * @notice It allows the system to reduce user transaction size to prevent transaction gas over limit
     * @dev Only callable by owner and doesn't effect the user balance.
     */
    function updateUserHistory(address user) external onlyOwner {
        _updateUserProfit(user);
    }

    /**
     * @notice Sets processing fee
     * @dev Only callable by the contract admin.
     */
    function setProcessingFee(uint32 _processingFee) external onlyOwner {
        require(
            _processingFee <= MAX_PROCESSING_FEE,
            "processing fee over limit"
        );
        processingFee = _processingFee;

        emit NewProcessingFee(processingFee);
    }

    /**
     * @notice Sets withdraw fee
     * @dev Only callable by the contract admin.
     */
    function setWithdrawFee(uint32 _withdrawFee) external onlyOwner {
        require(_withdrawFee <= MAX_WITHDRAW_FEE, "withdraw fee over limit");
        withdrawFee = _withdrawFee;

        emit NewWithfrawFee(withdrawFee);
    }

    /**
     * @notice Sets withdraw fee period
     * @dev Only callable by the contract admin.
     */
    function setWithdrawFeePeriod(
        uint256 _withdrawFeePeriod
    ) external onlyOwner {
        require(
            _withdrawFeePeriod <= MAX_WITHDRAW_FEE_PERIOD,
            "withdraw period over limit"
        );
        withdrawFeePeriod = _withdrawFeePeriod;

        emit NewWithfrawFeePeriod(withdrawFeePeriod);
    }

    function setMinimumDeposit(uint256 _number) external onlyOwner {
        require(_number <= MAX_MINIMUM_DEPOSIT, "invalid number");

        minimumDeposit = _number;

        emit NewMinimumDeposit(_number);
    }

    function setMinimumWithdraw(uint256 _number) external onlyOwner {
        require(_number <= MAX_MINIMUM_WITHDRAW, "invalid number");

        minimumWithdraw = _number;

        emit NewMinimumWithdraw(_number);
    }

    function viewUserRawInfo(
        address user
    )
        external
        view
        onlyOwner
        returns (uint256, uint256, uint256, uint256, uint256)
    {
        (uint256 currentStaking, uint256 currentLocked) = _viewUserBalance(
            user
        );
        return (
            currentStaking,
            currentLocked,
            _staking[user],
            _alloc[user],
            _roundId[user]
        );
    }

    function viewPool()
        external
        view
        onlyOwner
        returns (uint256[] memory pools, uint256 totalPool)
    {
        pools = new uint256[](101);
        for (uint32 i = 0; i <= 100; ++i) {
            pools[i] = pool[i];
            totalPool += pool[i];
        }
        return (pools, totalPool);
    }

    function totalBalance() external view returns (uint256 balance) {
        for (uint32 i = 0; i <= 100; ++i) {
            balance += pool[i];
        }
        return balance / RESERVE_DIGITS;
    }

    function activeUserCount() external view returns (uint256 count) {
        for (uint256 i = 0; i < userIndex; ++i) {
            (uint256 balance, uint256 alloc) = _viewUserBalance(_users[i]);
            if (_injectPercent[_users[i]] > 0 && (balance > 0 || alloc > 0)) {
                ++count;
            }
        }
        return count;
    }

    function viewLotteryInjectionInfo(
        uint256 lotteryId
    ) external view returns (uint256 injectAmount, uint256 returnAmount) {
        return (
            _lotteryInjectAmountByRound[lotteryId],
            _lotteryReturnAmountByRound[lotteryId]
        );
    }

    function viewUserInfo(
        address user
    ) external view returns (uint256, uint256, uint256, uint32) {
        (uint256 stakingBalance, uint256 lockedBalance) = _viewUserBalance(
            user
        );
        uint256 lastDepositTime = _lastDepositedTime[user];
        uint32 percent = _injectPercent[user];

        return (
            stakingBalance / RESERVE_DIGITS,
            lockedBalance / RESERVE_DIGITS,
            lastDepositTime,
            percent
        );
    }

    function depositWithPercentage(
        uint256 _amount,
        uint32 _percent
    ) external onlyMegamoonUser nonReentrant {
        _setPercentage(_percent);
        _deposit(_amount);
    }

    function setPercentage(
        uint32 _percent
    ) external onlyMegamoonUser nonReentrant {
        _setPercentage(_percent);
    }

    /**
     * @notice Deposits funds into the moon dealer
     * @dev The deposit when lottery is running will not be count for the reward until next round.
     * @param _amount: number of tokens to deposit (in MOON)
     */
    function deposit(uint256 _amount) external onlyMegamoonUser nonReentrant {
        _deposit(_amount);
    }

    /**
     * @notice Withdraws funds for a user from moon dealer
     */
    function withdraw(uint256 _amount) external onlyMegamoonUser nonReentrant {
        _updateUserProfit(msg.sender);
        _withdraw(_amount);
    }

    /**
     * @notice Withdraws all funds for a user from moon dealer
     */
    function withdrawAll() external onlyMegamoonUser nonReentrant {
        // Need to update user profit first to get the accurate user's latest balance
        _updateUserProfit(msg.sender);
        _withdraw(_staking[msg.sender] / RESERVE_DIGITS);
    }

    /**
     * @dev Getter for the address of the user number `index`.
     */
    function dealer(uint256 index) public view returns (address) {
        return _users[index];
    }

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     */
    function _addUser(address account) private {
        require(
            account != address(0),
            "MoonDealer: account is the zero address"
        );

        _users[userIndex] = account;
        ++userIndex;

        emit UserAdded(account);
    }

    function _updateUserProfit(address user) private {
        uint256 nextLotteryId = isLotteryClose
            ? currentLotteryId
            : currentLotteryId + 1;

        (_staking[user], _alloc[user]) = _viewUserBalance(user);

        if (_alloc[user] == 0) {
            _roundId[user] = nextLotteryId;
        } else {
            _roundId[user] = currentLotteryId;
        }
    }

    function _viewUserBalance(
        address userAddress
    ) private view returns (uint256, uint256) {
        address user = userAddress;

        uint32 userPercent = _injectPercent[user];
        uint256 userLatestId = _roundId[user];
        uint256 userAlloc = _alloc[user];

        uint256 nextLotteryId = isLotteryClose
            ? currentLotteryId
            : currentLotteryId + 1;

        if (userLatestId == nextLotteryId) {
            // deposit/ withdraw for next round
            return (_staking[user], _alloc[user]);
        }

        if (userLatestId == currentLotteryId && userAlloc > 0) {
            // current round and locked amount was calculated
            return (_staking[user], _alloc[user]);
        }

        if (userPercent == 0 && userAlloc == 0) {
            // new deposit, never go into any round
            return (_staking[user], _alloc[user]);
        }

        uint256 userBalance = _staking[user];
        uint256 injectAmount;
        uint256 returnAmount;
        uint256 newAlloc;

        if (userAlloc > 0) {
            returnAmount =
                (userAlloc * _lotteryReturnAmountByRound[userLatestId]) /
                _lotteryInjectAmountByRound[userLatestId];

            userBalance += returnAmount;
            userLatestId += 1;
        }

        for (userLatestId; userLatestId < currentLotteryId; ++userLatestId) {
            injectAmount = (userBalance * userPercent) / 100;
            returnAmount =
                (injectAmount * _lotteryReturnAmountByRound[userLatestId]) /
                _lotteryInjectAmountByRound[userLatestId];

            userBalance = (userBalance + returnAmount) - injectAmount;
        }

        if (isLotteryClose || currentLotteryId == 0) {
            // lottery close
            newAlloc = 0;
        } else {
            newAlloc = (userBalance * userPercent) / 100;
            userBalance -= newAlloc;
        }

        return (userBalance, newAlloc);
    }

    function _setPercentage(uint32 _percent) private {
        address user = msg.sender;

        require(_injectPercent[user] != _percent, "already set");

        if (_lastDepositedTime[user] == 0) {
            _injectPercent[user] = _percent;
            return;
        }

        _updateUserProfit(user);

        uint32 current = _injectPercent[user];

        if (_alloc[user] > 0) {
            pendingAlloc[current] -= _alloc[user];
            pendingAlloc[_percent] += _alloc[user];
        }

        pool[current] -= _staking[user];
        pool[_percent] += _staking[user];
        _injectPercent[user] = _percent;

        emit UpdatePercentage(user, _percent);
    }

    function _deposit(uint256 _amount) private {
        require(lotteryAddress != address(0), "lottery not available");
        require(_amount >= minimumDeposit, "amount too low");

        address user = msg.sender;
        uint32 _percent = _injectPercent[user];

        moonToken.safeTransferFrom(user, address(this), _amount);

        if (_lastDepositedTime[user] == 0) {
            _addUser(user);
            _roundId[user] = isLotteryClose
                ? currentLotteryId
                : currentLotteryId + 1;
        } else {
            _updateUserProfit(user);
        }

        _staking[user] += (_amount * RESERVE_DIGITS);
        pool[_percent] += _amount * RESERVE_DIGITS;

        _lastDepositedTime[user] = block.timestamp;

        emit Deposit(user, _amount, block.timestamp);
    }

    function _withdraw(uint256 _amount) private {
        address _user = msg.sender;

        require(_amount >= minimumWithdraw, "amount too low");
        require(_amount <= _staking[_user], "bad withdraw");

        uint32 _percent = _injectPercent[_user];
        uint256 _currentWithdrawFee;

        if (
            (withdrawFee > 0 && withdrawFeePeriod > 0) &&
            block.timestamp < _lastDepositedTime[_user] + withdrawFeePeriod
        ) {
            _currentWithdrawFee = (_amount * withdrawFee) / 10000;

            moonToken.safeTransfer(treasuryAddress, _currentWithdrawFee);

            emit TransferFeeToTreasuryAddress(
                treasuryAddress,
                _currentWithdrawFee
            );
        }

        uint256 _transferAmount = _amount - _currentWithdrawFee;

        moonToken.safeTransfer(_user, _transferAmount);

        _staking[_user] -= (_amount * RESERVE_DIGITS);
        pool[_percent] -= (_amount * RESERVE_DIGITS);

        emit Withdraw(_user, _amount);
    }

    function unsafe_inc_32(uint32 x) private pure returns (uint32) {
        unchecked {
            return x + 1;
        }
    }

    function unsafe_inc(uint256 x) private pure returns (uint256) {
        unchecked {
            return x + 1;
        }
    }
}