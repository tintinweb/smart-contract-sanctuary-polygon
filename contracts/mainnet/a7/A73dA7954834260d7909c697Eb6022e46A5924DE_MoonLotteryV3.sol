/**
 *Submitted for verification at polygonscan.com on 2023-05-19
*/

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

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
     * @notice Buy tickets for the current lottery
     * @param _lotteryId: lotteryId
     * @param _ticketNumbers: array of ticket numbers between 1,000,000 and 1,999,999
     * @dev Callable by users
     */
    function buyTickets(
        uint256 _lotteryId,
        uint32[] calldata _ticketNumbers
    ) external;

    /**
     * @notice Claim a set of winning tickets for a lottery
     * @param _lotteryIds: lottery id
     * @param _ticketIds: array of ticket ids
     * @param _brackets: array of brackets for the ticket ids
     * @dev Callable by users only, not contract!
     */
    function claimTickets(
        uint256[] calldata _lotteryIds,
        uint256[][] calldata _ticketIds,
        uint32[][] calldata _brackets
    ) external;

    /**
     * @notice Close lottery
     * @param _lotteryId: lottery id
     * @dev Callable by operator
     */
    function closeLottery(uint256 _lotteryId) external;

    /**
     * @notice Draw the final number, calculate reward in MOON per group, and make lottery claimable
     * @param _lotteryId: lottery id
     * @dev Callable by operator
     */
    function drawFinalNumberAndMakeLotteryClaimable(
        uint256 _lotteryId
    ) external;

    /**
     * @notice Start the lottery
     * @dev Callable by operator
     * @param _endTime: endTime of the lottery
     * @param _priceTicketInMoon: ticket price in MOON
     * @param _discountPerTicket: discount price per ticket in MOON
     */
    function startLottery(
        uint256 _endTime,
        uint256 _priceTicketInMoon,
        uint256 _discountPerTicket,
        uint256 _rewardPrize
    ) external;

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

interface IRandomNumberGenerator {
    /**
     * Requests randomness from a user-provided seed
     */
    function getRandomNumber() external;

    /**
     * View latest lotteryId numbers
     */
    function viewLatestLotteryId() external view returns (uint256);

    /**
     * Views random result
     */
    function viewRandomResult() external view returns (FinalNumber memory);
}

interface IValidator {
    function checkMegamoonWallet(address _user) external view returns (bool);
}

interface IReferral {
    function hasReferrer(address addr) external view returns (bool);

    function addAchievementPoint(
        address _user,
        uint256 _point
    ) external returns (uint256);

    function registReferral(
        address _user,
        address _referral,
        bool _shareBenefit
    ) external returns (bool);

    function payReferralBonus(address _user, uint256 _amount) external;
}

struct FinalNumber {
    uint32 bonus;
    uint32 match6;
    uint32 matchFirst;
    uint32 matchLast1;
    uint32 matchLast2;
    uint32 matchLast3;
    uint32 matchLast4;
    uint32 match2;
}

pragma abicoder v2;

/** @title Moon Lottery.
 * @notice It is a contract for a lottery system using
 * randomness provided externally.
 */
contract MoonLotteryV3 is ReentrancyGuard, IMoonLottery, Ownable {
    using SafeERC20 for IERC20;

    IERC20 internal moonToken;
    IMoonDealer internal dealer;
    IReferral internal referral;
    IRandomNumberGenerator public randomGenerator;

    address public operatorAddress;
    address public daoAddress;
    address public treasuryAddress;
    address public dealerAddress;
    address public referralAddress;
    address public validator;

    uint256 public currentLotteryId;

    uint256 private constant MIN_LENGTH_LOTTERY = 5 minutes; // 5 minutes
    uint256 private constant MAX_LENGTH_LOTTERY = 366 days + 5 minutes; // 1 year
    uint32 private constant SUM_SLOT_SIZE = 26; // 50m+
    uint32 private constant SUM_SLOT = 0x3FFFFFF; // 2^26 - 1 = 67,108,863
    uint32 private constant COUNT_SLOT_SIZE = 23; // 5m+
    uint32 private constant COUNT_SLOT = 0x7FFFFF; // 2^23 - 1 = 8,388,608
    uint32 private constant TICKET_SLOT_SIZE = 25;
    uint32 private constant TICKET_SLOT = 0x1FFFFFF; // 2^25 - 1 = 33,554,431
    uint32 private constant MAX_TICKET_SLOT = 5000000; // 5m
    uint16 private constant MAX_DEALER_BONUS = 3000; //5000 = 50%, 3000 = 30% (Back to dealer)
    uint16 private constant MAX_FEE = 2000; // 2000 = 20%
    uint16 private constant MAX_REFERRAL_BONUS = 5000; // 5000 = 50%
    uint16 private constant MAX_DAO_FUND = 10000; // 10000 = 100% (max = no leftover for treasury)

    uint128 public maxNumberTicketsPerBuyOrClaim = 300;
    uint128 public maxPriceTicketInMoon = 100000000;
    uint128 public minPriceTicketInMoon = 1000000;
    uint32 public feePercent = 550; // collect 5.5% from ticket sold
    uint32 public referralBonus = 3000; // 30% from fee collected amount
    uint32 public daoPercent = 5000; // 50% from fee collected minus referral amount
    uint32 public minimumBulk = 10;

    // 0 = match 6 + bonus 				1,000,000
    // 1 = match 6						300,000
    // 2 = match first 3 + bonus		1,000
    // 3 = match first 3				300
    // 4 = match last 3 				300
    // 5 = match any first 3 + bonus	150
    // 6 = match any first 3 			100
    // 7 = match last 2				    100
    uint32[] public rewardsPerBracket = [
        1000000,
        300000,
        1000,
        300,
        300,
        150,
        100,
        100
    ];

    enum Status {
        Pending,
        Open,
        Close,
        Claimable
    }

    struct Lottery {
        Status status;
        uint256 startTime;
        uint256 endTime;
        uint256 priceTicketInMoon;
        uint256 discountPerTicket;
        uint256 rewardPrize;
        uint256 jackpotPrize;
        uint256[8] moonPerBracket;
        uint256[8] winnersPerBracket;
        uint256 feeCollectedInMoon;
        uint256 amountCollectedInMoon;
        FinalNumber finalNumber;
    }

    // Mapping are cheaper than arrays
    mapping(uint256 => Lottery) internal _lotteries;

    // Keeps track of number of ticket per unique combination for each lotteryId
    mapping(uint256 => mapping(uint256 => uint256))
        internal _numberTicketsPerLotteryId;
    mapping(uint256 => mapping(uint256 => uint256))
        internal _numberTickets2PerLotteryId;

    // Keep track of user total tickets for the lotteryId [user][lotteryId]
    mapping(address => mapping(uint256 => uint256)) internal _userTicketCount;

    // Keep track of user tickets for a given lotteryId [user][lotteryId][slot] = 10 tickets
    mapping(address => mapping(uint256 => mapping(uint256 => uint256)))
        internal _userTicketsPerLotteryId;

    // Keep track of ticket claimed: [user][lotteryId][ticketId] = true/false
    mapping(address => mapping(uint256 => mapping(uint256 => bool)))
        internal _ticketClaimed;

    modifier onlyMegamoonUser() {
        require(
            IValidator(validator).checkMegamoonWallet(msg.sender),
            "not megamoon wallet"
        );
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operatorAddress, "Not operator");
        _;
    }

    event TokenRecovery(address token, uint256 amount);
    event LotteryClose(uint256 indexed lotteryId);
    event LotteryOpen(
        uint256 indexed lotteryId,
        uint256 startTime,
        uint256 endTime,
        uint256 priceTicketInMoon,
        uint256 discountPerTicket,
        uint256 prize,
        uint256 injectedAmount
    );
    event LotteryNumberDrawn(
        uint256 indexed lotteryId,
        FinalNumber finalNumber
    );

    event NewOperatorAddress(address operator);
    event NewRandomGenerator(address indexed randomGenerator);
    event NewReferral(address refferal);
    event NewReferralBonus(uint256 bonusRate);
    event NewMinAndMaxTicketPriceInMoon(
        uint256 minPriceTicketInMoon,
        uint256 maxPriceTicketInMoon
    );
    event NewMaxNumberTicketsPerBuyOrClaim(uint256 maxNumberTickets);
    event NewMinimumBulk(uint32 number);
    event NewDaoPercent(uint32 dao);
    event NewFeePercent(uint32 percent);
    event NewRewardsPerBracket(uint32[] brackets);

    event TicketsPurchase(
        address indexed buyer,
        uint256 indexed lotteryId,
        uint256 numberTickets
    );
    event TicketsClaim(
        address indexed claimer,
        uint256 amount,
        uint256 indexed lotteryId,
        uint256 numberTickets
    );

    /**
     * @notice Constructor
     * @dev RandomNumberGenerator must be deployed prior to this contract
     * @param _randomGeneratorAddress: address of the RandomGenerator contract used to work with ChainLink VRF
     * @param _moonTokenAddress: address of the MOON token
     */
    constructor(
        address _moonTokenAddress,
        address _randomGeneratorAddress,
        address _dealerAddress,
        address _operatorAddress,
        address _daoAddress,
        address _treasuryAddress,
        address _referral,
        address _validator
    ) {
        moonToken = IERC20(_moonTokenAddress);
        randomGenerator = IRandomNumberGenerator(_randomGeneratorAddress);
        dealerAddress = _dealerAddress;
        operatorAddress = _operatorAddress;
        daoAddress = _daoAddress;
        treasuryAddress = _treasuryAddress;
        dealer = IMoonDealer(dealerAddress);
        referralAddress = _referral;
        referral = IReferral(referralAddress);
        validator = _validator;
    }

    /**
     * @notice Buy tickets for the current lottery
     * @param _lotteryId: lotteryId
     * @param _ticketNumbers: array of ticket numbers between 1,000,000 and 1,999,999
     * @dev Callable by users
     */
    function buyTickets(
        uint256 _lotteryId,
        uint32[] calldata _ticketNumbers
    ) external override onlyMegamoonUser nonReentrant {
        require(_ticketNumbers.length != 0, "No ticket specified");
        require(
            _ticketNumbers.length <= maxNumberTicketsPerBuyOrClaim,
            "Too many tickets"
        );
        require(
            _lotteries[_lotteryId].status == Status.Open,
            "Lottery is not open"
        );
        require(
            block.timestamp < _lotteries[_lotteryId].endTime,
            "Lottery is over"
        );

        uint256 ticketCost;
        if (_ticketNumbers.length < minimumBulk) {
            // Calculate number of MOON to this contract
            ticketCost =
                _lotteries[_lotteryId].priceTicketInMoon *
                _ticketNumbers.length;
        } else {
            ticketCost =
                (_lotteries[_lotteryId].priceTicketInMoon -
                    _lotteries[_lotteryId].discountPerTicket) *
                _ticketNumbers.length;
        }

        // Transfer moon tokens to this contract
        moonToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            ticketCost
        );

        uint256 feeCollected = (ticketCost * feePercent) / 10000;

        // Increment the total amount collected for the lottery round
        _lotteries[_lotteryId].amountCollectedInMoon += (ticketCost -
            feeCollected);

        referral.addAchievementPoint(msg.sender, _ticketNumbers.length);

        if (referral.hasReferrer(msg.sender)) {
            uint256 bonusForReferrer;

            bonusForReferrer = (feeCollected * referralBonus) / 10000;
            referral.payReferralBonus(msg.sender, bonusForReferrer);

            moonToken.safeTransfer(referralAddress, bonusForReferrer);

            feeCollected -= bonusForReferrer;
        }

        _lotteries[_lotteryId].feeCollectedInMoon += feeCollected;

        // Prepare for user tickets memorize
        uint256 storageNumber = _userTicketCount[msg.sender][_lotteryId];
        uint256 startIndex = storageNumber % 10;
        storageNumber = storageNumber / 10;
        uint256 totalStorage = ((_ticketNumbers.length + startIndex) / 10) + 1;
        uint256[] memory newUserTickets = new uint256[](totalStorage);

        for (uint256 i = 0; i < _ticketNumbers.length; ++i) {
            require(
                (_ticketNumbers[i] >= 10000000) &&
                    (_ticketNumbers[i] <= 19999999),
                "Outside range"
            );
            uint256 ticketCount = (uint256(1) <<
                (((_ticketNumbers[i] % 10) * COUNT_SLOT_SIZE) +
                    SUM_SLOT_SIZE)) + 1; // SLOT_SIZE binary digits per number 0 - 9

            if (
                (_numberTicketsPerLotteryId[_lotteryId][
                    _ticketNumbers[i] / 10
                ] >> ticketCount) &
                    0x1FFFFFF <=
                MAX_TICKET_SLOT
            ) {
                // 1,XXX,XXX = [9,8,7,6,5,4,3,2,1,0,SUM]
                _numberTicketsPerLotteryId[_lotteryId][
                    _ticketNumbers[i] / 10
                ] += ticketCount;
                // 1XXX = [9,8,7,6,5,4,3,2,1,0,SUM]
                _numberTicketsPerLotteryId[_lotteryId][
                    ((_ticketNumbers[i] / 10) % 1000) + 1000
                ] += ticketCount;
                // 1XXX = SUM
                _numberTickets2PerLotteryId[_lotteryId][
                    (_ticketNumbers[i] / 10000)
                ] += 1;
            }

            newUserTickets[(i + startIndex) / 10] +=
                uint256(_ticketNumbers[i]) <<
                (((i + startIndex) % 10) * TICKET_SLOT_SIZE);
        }

        // memo user tickets to cold storage
        for (uint256 j = 0; j < totalStorage; ++j) {
            _userTicketsPerLotteryId[msg.sender][_lotteryId][
                storageNumber + j
            ] += newUserTickets[j];
        }

        _userTicketCount[msg.sender][_lotteryId] += _ticketNumbers.length;

        emit TicketsPurchase(msg.sender, _lotteryId, _ticketNumbers.length);
    }

    /**
     * @notice Claim a set of winning tickets for a lottery
     * @param _lotteryIds: lottery id
     * @param _ticketIds: array of ticket ids
     * @param _brackets: array of brackets for the ticket ids
     * @dev Callable by users only, not contract!
     */
    function claimTickets(
        uint256[] calldata _lotteryIds,
        uint256[][] calldata _ticketIds,
        uint32[][] calldata _brackets
    ) external override onlyMegamoonUser nonReentrant {
        require(
            _lotteryIds.length == _ticketIds.length &&
                _ticketIds.length == _brackets.length,
            "Not same length"
        );
        require(
            _lotteryIds.length <= maxNumberTicketsPerBuyOrClaim,
            "Too many tickets"
        );

        // Initializes the rewardInMoonToTransfer
        uint256 rewardInMoonToTransfer;
        for (uint256 i = 0; i < _lotteryIds.length; ++i) {
            uint256 currentRoundReward;
            require(
                _lotteries[_lotteryIds[i]].status == Status.Claimable,
                "Lottery not claimable"
            );
            require(_ticketIds[i].length != 0, "Length must be > 0");
            require(
                _ticketIds[i].length == _brackets[i].length,
                "Not same length"
            );

            for (uint256 j = 0; j < _ticketIds[i].length; ++j) {
                require(_brackets[i][j] < 8, "Bracket is out of range"); // Must be 0 -> 5
                require(
                    _userTicketCount[msg.sender][_lotteryIds[i]] >
                        _ticketIds[i][j],
                    "TicketId is too high"
                );
                require(
                    _ticketClaimed[msg.sender][_lotteryIds[i]][
                        _ticketIds[i][j]
                    ] == false,
                    "Ticket was claimed"
                );

                uint256 rewardForTicketId = _calculateRewardsForTicketId(
                    msg.sender,
                    _lotteryIds[i],
                    _ticketIds[i][j],
                    _brackets[i][j]
                );

                require(rewardForTicketId != 0, "no reward for this ticket");

                // Update the lottery ticket claimed status to true
                _ticketClaimed[msg.sender][_lotteryIds[i]][
                    _ticketIds[i][j]
                ] = true;

                currentRoundReward += rewardForTicketId;
            }

            emit TicketsClaim(
                msg.sender,
                currentRoundReward,
                _lotteryIds[i],
                _ticketIds[i].length
            );

            rewardInMoonToTransfer += currentRoundReward;
        }

        // Transfer money to msg.sender
        moonToken.safeTransfer(msg.sender, rewardInMoonToTransfer);
    }

    /**
     * @notice Draw the final number, calculate reward in MOON per group, and make lottery claimable
     * @param _lotteryId: lottery id
     * @dev Callable by operator
     */
    function drawFinalNumberAndMakeLotteryClaimable(
        uint256 _lotteryId
    ) external override onlyOperator nonReentrant {
        require(
            _lotteries[_lotteryId].status == Status.Close,
            "Lottery not close"
        );
        require(
            block.timestamp > _lotteries[_lotteryId].endTime,
            "Lottery not over"
        );
        require(
            _lotteryId == randomGenerator.viewLatestLotteryId(),
            "Numbers not drawn"
        );
        // Calculate the finalNumber based on the randomResult generated by ChainLink's fallback
        FinalNumber memory finalNumber = randomGenerator.viewRandomResult();

        // Initializes the amount to withdraw to dealer
        uint256 amountToWithdraw;
        uint256 amountToShareToWinners = _lotteries[_lotteryId]
            .amountCollectedInMoon;

        // uint256[] memory winnerCount = new uint256[](8);
        uint256[] memory winnerCount = _countWinner(_lotteryId, finalNumber);
        _lotteries[_lotteryId].winnersPerBracket = [
            winnerCount[0],
            winnerCount[1],
            winnerCount[2],
            winnerCount[3],
            winnerCount[4],
            winnerCount[5],
            winnerCount[6],
            winnerCount[7]
        ];

        uint256 rewards = _calculateReward(_lotteryId);
        uint256 feeLeftOver;

        if (rewards < amountToShareToWinners) {
            for (uint256 i = 0; i < 8; ++i) {
                if (_lotteries[_lotteryId].winnersPerBracket[i] > 0) {
                    _lotteries[_lotteryId].moonPerBracket[i] =
                        rewardsPerBracket[i] *
                        _lotteries[_lotteryId].rewardPrize;
                }
            }
            amountToWithdraw = amountToShareToWinners - rewards;
        } else {
            uint256 sumRewards;
            for (uint256 i = 0; i < 8; ++i) {
                if (_lotteries[_lotteryId].winnersPerBracket[i] > 0) {
                    _lotteries[_lotteryId].moonPerBracket[i] =
                        (rewardsPerBracket[i] *
                            _lotteries[_lotteryId].rewardPrize *
                            amountToShareToWinners) /
                        rewards;
                    sumRewards +=
                        _lotteries[_lotteryId].moonPerBracket[i] *
                        _lotteries[_lotteryId].winnersPerBracket[i];
                }
            }
            // a few chance of some tiny remaining from fraction
            if (amountToShareToWinners > sumRewards) {
                feeLeftOver = amountToShareToWinners - sumRewards;
            }
        }
        // Update internal statuses for lottery
        _lotteries[_lotteryId].finalNumber = finalNumber;
        _lotteries[_lotteryId].status = Status.Claimable;
        // Transfer MOON for dao fund
        uint256 daoAmount = (_lotteries[_lotteryId].feeCollectedInMoon *
            daoPercent) / 10000;
        if (daoAmount > 0 || feeLeftOver > 0) {
            moonToken.safeTransfer(daoAddress, daoAmount + feeLeftOver);
        }
        if (_lotteries[_lotteryId].feeCollectedInMoon - daoAmount > 0) {
            moonToken.safeTransfer(
                treasuryAddress,
                _lotteries[_lotteryId].feeCollectedInMoon - daoAmount
            );
        }
        // Transfer MOON to dealer
        if (amountToWithdraw > 0) {
            moonToken.safeTransfer(dealerAddress, amountToWithdraw);
        }
        dealer.returnFunds(
            currentLotteryId,
            amountToWithdraw,
            _lotteries[_lotteryId].amountCollectedInMoon
        );
        emit LotteryNumberDrawn(
            currentLotteryId,
            _lotteries[_lotteryId].finalNumber
        );
    }

    /**
     * @notice Start the lottery
     * @dev Callable by operator
     * @param _endTime: endTime of the lottery
     * @param _priceTicketInMoon: price of a ticket in MOON -> 3980000
     # @param _discountPerTicket: discount of a ticket -> 210000
     */
    function startLottery(
        uint256 _endTime,
        uint256 _priceTicketInMoon,
        uint256 _discountPerTicket,
        uint256 _rewardPrize
    ) external override onlyOperator {
        require(
            (currentLotteryId == 0) ||
                (_lotteries[currentLotteryId].status == Status.Claimable),
            "Not time to start lottery"
        );
        require(
            ((_endTime - block.timestamp) > MIN_LENGTH_LOTTERY) &&
                ((_endTime - block.timestamp) < MAX_LENGTH_LOTTERY),
            "Lottery time is outside of range"
        );
        require(
            (_priceTicketInMoon >= minPriceTicketInMoon) &&
                (_priceTicketInMoon <= maxPriceTicketInMoon),
            "Ticket price is outside of limits"
        );
        require(
            _discountPerTicket < _priceTicketInMoon,
            "Invalid number, discount over price"
        );
        currentLotteryId++;
        uint256 injectAmount = dealer.injectToLottery(currentLotteryId);
        uint256[8] memory initialArray;
        FinalNumber memory initialFinalNumber;

        _lotteries[currentLotteryId] = Lottery({
            status: Status.Open,
            startTime: block.timestamp,
            endTime: _endTime,
            priceTicketInMoon: _priceTicketInMoon,
            discountPerTicket: _discountPerTicket,
            rewardPrize: _rewardPrize,
            jackpotPrize: 0,
            moonPerBracket: initialArray,
            winnersPerBracket: initialArray,
            feeCollectedInMoon: 0,
            amountCollectedInMoon: injectAmount,
            finalNumber: initialFinalNumber
        });

        emit LotteryOpen(
            currentLotteryId,
            block.timestamp,
            _endTime,
            _priceTicketInMoon,
            _discountPerTicket,
            _rewardPrize,
            injectAmount
        );
    }

    /**
     * @notice Close lottery
     * @param _lotteryId: lottery id
     * @dev Callable by operator
     */
    function closeLottery(
        uint256 _lotteryId
    ) external override onlyOperator nonReentrant {
        require(
            _lotteries[_lotteryId].status == Status.Open,
            "Lottery not open"
        );
        require(
            block.timestamp > _lotteries[_lotteryId].endTime,
            "Lottery not over"
        );

        _lotteries[_lotteryId].status = Status.Close;

        // Request a random number from the generator based on a seed
        randomGenerator.getRandomNumber();

        emit LotteryClose(_lotteryId);
    }

    function registReferral(
        address _referrer,
        bool _shareBenefit
    ) external onlyMegamoonUser returns (bool) {
        return referral.registReferral(msg.sender, _referrer, _shareBenefit);
    }

    /**
     * @notice Change the random generator
     * @dev The calls to functions are used to verify the new generator implements them properly.
     * It is necessary to wait for the VRF response before starting a round.
     * Callable only by the contract owner
     * @param _randomGeneratorAddress: address of the random generator
     */
    function changeRandomGenerator(
        address _randomGeneratorAddress
    ) external onlyOwner {
        require(
            _lotteries[currentLotteryId].status == Status.Claimable,
            "Lottery not in claimable"
        );

        // Request a random number from the generator based on a seed
        IRandomNumberGenerator(_randomGeneratorAddress).getRandomNumber();

        // Calculate the finalNumber based on the randomResult generated by ChainLink's fallback
        IRandomNumberGenerator(_randomGeneratorAddress).viewRandomResult();

        randomGenerator = IRandomNumberGenerator(_randomGeneratorAddress);

        emit NewRandomGenerator(_randomGeneratorAddress);
    }

    /**
     * @notice It allows the owner to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @param _tokenAmount: the number of token amount to withdraw
     * @dev Only callable by owner.
    //  */
    function recoverWrongTokens(
        address _tokenAddress,
        uint256 _tokenAmount
    ) external onlyOwner {
        require(_tokenAddress != address(moonToken), "Cannot be MOON token");

        IERC20(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);

        emit TokenRecovery(_tokenAddress, _tokenAmount);
    }

    /**
     * @notice Set MOON price ticket upper/lower limit
     * @dev Only callable by owner
     * @param _minPriceTicketInMoon: minimum price of a ticket in MOON
     * @param _maxPriceTicketInMoon: maximum price of a ticket in MOON
     */
    function setMinAndMaxTicketPriceInMoon(
        uint128 _minPriceTicketInMoon,
        uint128 _maxPriceTicketInMoon
    ) external onlyOwner {
        require(
            _minPriceTicketInMoon <= _maxPriceTicketInMoon,
            "minPrice must be < maxPrice"
        );

        minPriceTicketInMoon = _minPriceTicketInMoon;
        maxPriceTicketInMoon = _maxPriceTicketInMoon;

        emit NewMinAndMaxTicketPriceInMoon(
            minPriceTicketInMoon,
            maxPriceTicketInMoon
        );
    }

    /**
     * @notice Set max number of tickets
     * @dev Only callable by owner
     */
    function setMaxNumberTicketsPerBuy(
        uint128 _maxNumberTicketsPerBuy
    ) external onlyOwner {
        require(_maxNumberTicketsPerBuy != 0, "Must be > 0");

        maxNumberTicketsPerBuyOrClaim = _maxNumberTicketsPerBuy;

        emit NewMaxNumberTicketsPerBuyOrClaim(maxNumberTicketsPerBuyOrClaim);
    }

    /**
     * @notice Set new number for referral bonus
     * @dev Only callable by owner
     */
    function setReferralBonus(uint32 _referralBonus) external onlyOwner {
        require(_referralBonus != 0, "Must be > 0");
        require(_referralBonus < MAX_REFERRAL_BONUS, "Referral bonus too high");
        referralBonus = _referralBonus;

        emit NewReferralBonus(_referralBonus);
    }

    function setReferral(address _referral) external onlyOwner {
        require(_referral != address(0));

        referralAddress = _referral;
        referral = IReferral(referralAddress);

        emit NewReferral(referralAddress);
    }

    function setDaoPercent(uint32 _percent) external onlyOwner {
        require(_percent != 0, "Must be > 0");
        require(_percent < MAX_DAO_FUND, "Percent too high");
        daoPercent = _percent;

        emit NewDaoPercent(_percent);
    }

    /**
     * @notice Set the number of minimum tickets that will get a discount
     */
    function setMinimumBulk(uint32 _number) external onlyOwner {
        require(
            _number > 0 && _number < maxNumberTicketsPerBuyOrClaim,
            "invalid number"
        );

        minimumBulk = _number;

        emit NewMinimumBulk(minimumBulk);
    }

    function setFee(uint32 _percent) external onlyOwner {
        require(_percent > 0 && _percent <= MAX_FEE, "Invalid number");

        feePercent = _percent;

        emit NewFeePercent(_percent);
    }

    function setRewardsPerBracket(
        uint32[] calldata _brackets
    ) external onlyOwner {
        require(_brackets.length == 8, "Require length = 8");

        for (uint256 i = 0; i < 8; i = unsafe_inc(i)) {
            require(_brackets[i] < 2 ** 32, "Number too high");
            rewardsPerBracket[i] = _brackets[i];
        }

        emit NewRewardsPerBracket(_brackets);
    }

    /**
     * @notice Set operator addresse
     * @dev Only callable by owner
     * @param _operatorAddress: address of the operator
     */
    function setOperatorAddress(address _operatorAddress) external onlyOwner {
        require(_operatorAddress != address(0), "Cannot be zero address");

        operatorAddress = _operatorAddress;

        emit NewOperatorAddress(_operatorAddress);
    }

    function viewCurrentLotteryId() external view override returns (uint256) {
        return currentLotteryId;
    }

    /**
     * @notice View lottery info
     * @param _lotteryId: lottery id
     */
    function viewLottery(
        uint256 _lotteryId
    ) external view returns (Lottery memory) {
        return _lotteries[_lotteryId];
    }

    /**
     * @notice View moon token address
     * @dev this function is required in case that the contract will use megamoon referral
     */
    function viewMoonTokenAddress() external view returns (address) {
        return address(moonToken);
    }

    /**
     * @notice View minimum bulk for ticket discount
     */
    function viewMinimumBulk() external view returns (uint256) {
        return minimumBulk;
    }

    /**
     * @notice View rewards for a given ticket, providing a bracket, and lottery id
     * @dev Computations are mostly offchain. This is used to verify a ticket!
     * @param _lotteryId: lottery id
     * @param _ticketId: ticket id
     * @param _bracket: bracket for the ticketId to verify the claim and calculate rewards
     */
    function viewRewardsForTicketId(
        address _user,
        uint256 _lotteryId,
        uint256 _ticketId,
        uint32 _bracket
    ) external view returns (uint256) {
        // Check lottery is in claimable status and ticketId is within the range
        if (
            _lotteries[_lotteryId].status != Status.Claimable &&
            _ticketId >= _userTicketCount[_user][_lotteryId]
        ) {
            return 0;
        }

        return
            _calculateRewardsForTicketId(
                _user,
                _lotteryId,
                _ticketId,
                _bracket
            );
    }

    function checkRewardBracket(
        uint256 _lotteryId,
        uint256 _ticketNumber
    ) external view returns (uint256) {
        return _checkRewardBracket(_lotteryId, _ticketNumber);
    }

    /**
     * @notice View user ticket ids, numbers, and statuses of user for a given lottery
     * @param _user: user address
     * @param _lotteryId: lottery id
     * @param _cursor: cursor to start where to retrieve the tickets
     * @param _size: the number of tickets to retrieve
     */
    function viewUserInfoForLotteryId(
        address _user,
        uint256 _lotteryId,
        uint256 _cursor,
        uint256 _size
    )
        external
        view
        returns (uint256[] memory, uint256[] memory, bool[] memory, uint256)
    {
        uint256 length;

        if (_size > (_userTicketCount[_user][_lotteryId] - _cursor)) {
            length = _userTicketCount[_user][_lotteryId] - _cursor;
        } else {
            length = _size;
        }

        uint256[] memory lotteryTicketIds = new uint256[](length);
        uint256[] memory ticketNumbers = new uint256[](length);
        bool[] memory ticketStatuses = new bool[](length);

        for (uint256 i = 0; i < length; i++) {
            uint256 id = i + _cursor;
            lotteryTicketIds[i] = id;
            ticketNumbers[i] = _viewTicketNumber(_user, _lotteryId, id);
            ticketStatuses[i] = _ticketClaimed[_user][_lotteryId][id];
        }

        return (
            lotteryTicketIds,
            ticketNumbers,
            ticketStatuses,
            _cursor + length
        );
    }

    function _calculateReward(
        uint256 _lotteryId
    ) private view returns (uint256) {
        uint256 rewards;
        for (uint256 i = 0; i < 8; ++i) {
            rewards +=
                _lotteries[_lotteryId].winnersPerBracket[i] *
                rewardsPerBracket[i] *
                _lotteries[_lotteryId].rewardPrize;
        }
        return rewards;
    }

    function _countWinner(
        uint256 _lotteryId,
        FinalNumber memory finalNumber
    ) private view returns (uint256[] memory) {
        uint256[] memory rawWinnerCount = new uint256[](19);
        uint256[] memory winnerCount = new uint256[](14);
        uint256[] memory finalWinnerCount = new uint256[](8);

        uint256 bonusLocation = ((finalNumber.bonus - 10) * COUNT_SLOT_SIZE) +
            SUM_SLOT_SIZE;
        uint256 storageValue;
        // [jackpot, match6+bonus, matchFirst3+bonus, matchFirst3, matchLast3,
        //  matchAny3+bonus, matchAny3, match2]

        // --- COUNT MATCH JACKPOT AND MATCH 6 ---
        storageValue = _numberTicketsPerLotteryId[_lotteryId][
            finalNumber.match6
        ];

        rawWinnerCount[0] = (storageValue >> bonusLocation) & COUNT_SLOT;
        rawWinnerCount[1] = (storageValue & SUM_SLOT);

        finalWinnerCount[0] = rawWinnerCount[0];
        finalWinnerCount[1] = rawWinnerCount[1] - rawWinnerCount[0];

        // --- MATCH FIRST 3 DIGITS -------
        storageValue = _numberTicketsPerLotteryId[_lotteryId][
            finalNumber.matchFirst
        ];

        rawWinnerCount[2] = (storageValue >> bonusLocation) & COUNT_SLOT;
        rawWinnerCount[3] = storageValue & SUM_SLOT;

        finalWinnerCount[2] = rawWinnerCount[2];
        finalWinnerCount[3] = rawWinnerCount[3];

        if (finalNumber.matchFirst % 1000 == finalNumber.match6 % 1000) {
            finalWinnerCount[2] -= rawWinnerCount[0];
            finalWinnerCount[3] -= rawWinnerCount[1];
        }
        finalWinnerCount[3] -= finalWinnerCount[2];

        // MATCH LAST 3
        uint32[4] memory matchLast = [
            finalNumber.matchLast1,
            finalNumber.matchLast2,
            finalNumber.matchLast3,
            finalNumber.matchLast4
        ];

        for (uint256 i = 0; i < 4; ++i) {
            rawWinnerCount[i + 4] = _numberTickets2PerLotteryId[_lotteryId][
                matchLast[i]
            ];
            winnerCount[i] = rawWinnerCount[i + 4];
            if (matchLast[i] == finalNumber.match6 / 1000) {
                winnerCount[i] -= rawWinnerCount[1];
            }
            uint256 compareNumber = (matchLast[i] * 1000) +
                (finalNumber.matchFirst - 1000);
            storageValue = _numberTicketsPerLotteryId[_lotteryId][
                compareNumber
            ];
            if (storageValue > 0 && compareNumber != finalNumber.match6) {
                winnerCount[i] -= storageValue & SUM_SLOT;
            }
        }

        finalWinnerCount[4] =
            winnerCount[0] +
            winnerCount[1] +
            winnerCount[2] +
            winnerCount[3];

        // --- MATCH ANY FIRST 3 DIGITS ---
        uint256[] memory matchAny = _getMatchAnyNumbers(finalNumber.matchFirst);

        for (uint256 i = 0; i < matchAny.length; ++i) {
            uint256 index = i * 2;
            storageValue = _numberTicketsPerLotteryId[_lotteryId][
                1000 + matchAny[i]
            ];
            if (storageValue > 0) {
                rawWinnerCount[index + 8] =
                    (storageValue >> bonusLocation) &
                    COUNT_SLOT;
                rawWinnerCount[index + 9] = storageValue & SUM_SLOT;

                winnerCount[index + 4] = rawWinnerCount[index + 8];
                winnerCount[index + 5] = rawWinnerCount[index + 9];

                if (matchAny[i] == finalNumber.match6 % 1000) {
                    winnerCount[index + 4] -= rawWinnerCount[0];
                    winnerCount[index + 5] -= rawWinnerCount[1];
                }

                for (uint256 j = 0; j < 4; ++j) {
                    if (rawWinnerCount[j + 4] > 0) {
                        uint256 compareNumber = (matchLast[j] * 1000) +
                            matchAny[i];
                        storageValue = _numberTicketsPerLotteryId[_lotteryId][
                            compareNumber
                        ];
                        if (compareNumber != finalNumber.match6) {
                            winnerCount[index] -=
                                (storageValue >> bonusLocation) &
                                COUNT_SLOT;
                            winnerCount[index + 1] -= storageValue & SUM_SLOT;
                        }
                    }
                }
                winnerCount[index + 5] -= winnerCount[index + 4];
                finalWinnerCount[5] += winnerCount[index + 4];
                finalWinnerCount[6] += winnerCount[index + 5];
            }
        }

        // MATCH 2
        for (uint256 i = 0; i < 10; ++i) {
            rawWinnerCount[18] += _numberTickets2PerLotteryId[_lotteryId][
                finalNumber.match2 * 10 + i
            ];
        }
        finalWinnerCount[7] = rawWinnerCount[18];

        if (finalNumber.match2 == finalNumber.match6 / 10000) {
            finalWinnerCount[7] -= rawWinnerCount[1];
        }

        // check match 2 with match first
        for (uint256 i = 0; i < 10; ++i) {
            uint256 compareNumber = finalNumber.match2 * 10 + i;
            uint256 storageNumber = (compareNumber * 1000) +
                (finalNumber.matchFirst - 1000);
            if (storageNumber != finalNumber.match6) {
                storageValue = _numberTicketsPerLotteryId[_lotteryId][
                    storageNumber
                ];
                if (storageValue > 0) {
                    finalWinnerCount[7] -= storageValue & SUM_SLOT;
                }
            }
        }

        // check match 2 with match last * 4
        for (uint256 i = 0; i < 4; ++i) {
            if (finalNumber.match2 == (matchLast[i] / 10)) {
                finalWinnerCount[7] -= winnerCount[i];
            }
        }

        // check match 2 with match any first
        for (uint256 i = 0; i < 10; ++i) {
            uint256 compareNumber = finalNumber.match2 * 10 + i;
            storageValue = 0;

            if (
                compareNumber != matchLast[0] &&
                compareNumber != matchLast[1] &&
                compareNumber != matchLast[2] &&
                compareNumber != matchLast[3]
            ) {
                // check match any
                for (uint256 j = 0; j < matchAny.length; ++j) {
                    uint256 storageNumber = (compareNumber * 1000) +
                        matchAny[j];
                    if (storageNumber != finalNumber.match6) {
                        storageValue = _numberTicketsPerLotteryId[_lotteryId][
                            storageNumber
                        ];
                        if (storageValue > 0) {
                            finalWinnerCount[7] -= storageValue & SUM_SLOT;
                        }
                    }
                }
            }
        }

        return finalWinnerCount;
    }

    function _viewTicketNumber(
        address _user,
        uint256 _lotteryId,
        uint256 _id
    ) private view returns (uint256) {
        return
            (_userTicketsPerLotteryId[_user][_lotteryId][_id / 10] >>
                ((_id % 10) * 25)) & TICKET_SLOT;
    }

    /**
     * @dev This function will use only last 3 digits of the initialNumber
     */
    function _getMatchAnyNumbers(
        uint256 initialNumber
    ) private pure returns (uint256[] memory) {
        uint256[3] memory digit = [
            (initialNumber / 100) % 10,
            (initialNumber / 10) % 10,
            initialNumber % 10
        ];

        uint256[] memory matchAny = new uint256[](5);
        matchAny[0] = (digit[0] * 100) + (digit[2] * 10) + digit[1];
        matchAny[1] = (digit[1] * 100) + (digit[0] * 10) + digit[2];
        matchAny[2] = (digit[1] * 100) + (digit[2] * 10) + digit[0];
        matchAny[3] = (digit[2] * 100) + (digit[0] * 10) + digit[1];
        matchAny[4] = (digit[2] * 100) + (digit[1] * 10) + digit[0];

        uint256 length;
        bool[] memory dup = new bool[](5);

        for (uint256 i = 0; i < 5; ++i) {
            if (matchAny[i] == (initialNumber - 1000)) {
                dup[i] = true;
            } else {
                for (uint256 j = 0; j < i; ++j) {
                    if (matchAny[i] == matchAny[j]) {
                        dup[i] = true;
                    }
                }
            }
            if (!dup[i]) {
                ++length;
            }
        }

        uint256[] memory result = new uint256[](length);
        length = 0;
        for (uint256 i = 0; i < 5; ++i) {
            if (!dup[i]) {
                result[length] = matchAny[i];
                ++length;
            }
        }
        return result;
    }

    /**
     * @notice Calculate rewards for a given ticket
     * @param _lotteryId: lottery id
     * @param _ticketId: ticket id
     * @param _bracket: bracket for the ticketId to verify the claim and calculate rewards
     */
    function _calculateRewardsForTicketId(
        address _user,
        uint256 _lotteryId,
        uint256 _ticketId,
        uint256 _bracket
    ) internal view returns (uint256) {
        uint256 userNumber = _viewTicketNumber(_user, _lotteryId, _ticketId);
        // Apply transformation to verify the claim provided by the user is true
        if (_checkRewardBracket(_lotteryId, userNumber) == _bracket) {
            return _lotteries[_lotteryId].moonPerBracket[_bracket];
        }
        return 0;
    }

    function _checkRewardBracket(
        uint256 _lotteryId,
        uint256 _ticketNumber
    ) internal view returns (uint256) {
        FinalNumber memory finalNumber = _lotteries[_lotteryId].finalNumber;
        bool bonusMatched = (_ticketNumber % 10 == finalNumber.bonus - 10);

        // Match 6 (+ Bonus)
        if (_ticketNumber / 10 == finalNumber.match6) {
            return bonusMatched ? 0 : 1;
        }

        // Match Last 3 (+ Bonus) => 1XXX---- == 1XXX
        if (((_ticketNumber / 10) % 1000) + 1000 == finalNumber.matchFirst) {
            return bonusMatched ? 2 : 3;
        }

        // Match Last 3
        uint256 matchingNumber = _ticketNumber / 10000; // 1XXX----
        if (
            matchingNumber == finalNumber.matchLast1 ||
            matchingNumber == finalNumber.matchLast2 ||
            matchingNumber == finalNumber.matchLast3 ||
            matchingNumber == finalNumber.matchLast4
        ) {
            return 4;
        }

        uint256[] memory matchAny = _getMatchAnyNumbers(finalNumber.matchFirst);

        // Match Any Last 3 (+ Bonus)
        matchingNumber = (_ticketNumber / 10) % 1000;
        for (uint256 i = 0; i < matchAny.length; ++i) {
            if (matchingNumber == matchAny[i]) {
                return bonusMatched ? 5 : 6;
            }
        }

        // Match 2 => 1XX-----
        if (_ticketNumber / 100000 == finalNumber.match2) {
            return 7;
        }

        return 8; // Not Match
    }

    function unsafe_inc(uint256 x) private pure returns (uint256) {
        unchecked {
            return x + 1;
        }
    }
}