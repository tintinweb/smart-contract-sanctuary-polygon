/**
 *Submitted for verification at polygonscan.com on 2023-06-30
*/

pragma solidity =0.5.6;

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(
        address account
    ) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(
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
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

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
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        callOptionalReturn(
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
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

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

interface IStakingRewards {
    // Views
    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function getRewardForDuration() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    // Mutative

    function stake(uint256 amount, address people) external;

    function withdraw(uint256 amount, address people) external;

    function getReward(address people) external returns (uint256);

    function exit(address people) external returns (uint256);

    function notifyRewardAmount(uint256 reward) external;

    function claimUSDT(address people, uint256 reward) external;
}

contract MTDOGE is Ownable {
    using SafeMath for uint256;
    using Math for uint256;
    using SafeERC20 for IERC20;
    IStakingRewards public _usdtStakingContract;
    /* ========== STATE VARIABLES ========== */
    uint public startTime;
    IERC20 public _stakingToken;
    IERC20 public _usdtToken;
    // immutables
    uint256 public backfallPeopleNum;
    uint256 public maxBackFallNum = 50;
    uint256 public nowBackfallIndex;
    address public usdt = address(0xc2132D05D31c914a87C6611C10748AEb04B58e8F);
    address public whiteAddress =
        address(0xA5C42C4F76D7d91AC94a4a500667ccaa0a1cCd38);
    address private receivingAddress =
        address(0x20cD0E84afB94920923bbF28E61E151A4cdDA0c1);
    uint256 public USDTNum = 100 * 10 ** 6;
    uint256 public minStakingNum = 300000 * 10 ** 6;
    uint256 public stakingRate = 128;
    uint256 public redirectInviteRate = 500;
    uint256 public inviteTokenRate = 50;
    uint256 public whiteWhoringDayToken = 10000 * 10 ** 6;
    uint256 public whiteWhoringTime = 120 days;
    uint public depth = 20;
    uint public fee = 3000;
    uint256 public backFallNum = 100000 * 10 ** 6;
    uint256 public miniInvNum = 3;
    bool public startStake = false;
    mapping(address => bool) public needCount;
    struct WhiteWhoring {
        uint256 startTime;
        uint256 lastTime;
        uint256 rewardAmount;
        uint256 inviteAmount;
        uint256 claimedAmount;
        uint256 claimedInviteAmount;
    }

    struct Staking {
        uint256 lastTime;
        uint256 rewardAmount;
        uint256 inviteAmount;
        uint256 claimedAmount;
        uint256 claimedInviteAmount;
        uint256 stakingAmount;
        uint256 leftStakingAmount;
        uint256 allStakeAmount;
        uint256 childNum;
        uint256 redrectNum;
    }

    struct LeftAndRight {
        address left;
        address right;
    }

    struct AddressInfo {
        address needCountAddress;
        uint count;
        bool hasSetLeaderAddress;
        address leaderAddress;
        address[] redirectInviteAddresses;
        uint256 feeAmount;
        uint nowLen;
        WhiteWhoring whiteWhoring;
        Staking staking;
        LeftAndRight leftAndRight;
    }

    mapping(address => AddressInfo) addressInfo;
    bool private _notEntered = true;
    address[] public stakedAddresses;
    mapping(address => bool) public backfallPeopleMap;
    address[] public whiteWhoringedAddresses;
    mapping(address => bool) public notHasWhiteWhoring;
    mapping(address => bool) public blackList;
    mapping(address => bool) public leadersList;
    bool public startSanhu = false;
    bool public closeWhiteWhoring = false;

    modifier mustSetLeader() {
        AddressInfo memory addressInfoObj = addressInfo[msg.sender];
        require(
            addressInfoObj.hasSetLeaderAddress || msg.sender == whiteAddress,
            "MTDOGE: NOT SET LEADER"
        );
        _;
    }

    modifier mustNoSetLeader() {
        AddressInfo memory addressInfoObj = addressInfo[msg.sender];
        require(!addressInfoObj.hasSetLeaderAddress, "MTDOGE: IS SET LEADER");
        _;
    }

    modifier isStart() {
        require(block.timestamp >= startTime, "not start");
        _;
    }

    modifier isStartStake() {
        require(startStake, "not start");
        _;
    }

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }

    constructor(address token, uint _startTime) public Ownable() {
        require(
            _startTime >= block.timestamp,
            "MTDOGE::constructor: genesis too soon"
        );
        startTime = _startTime;
        _usdtToken = IERC20(usdt);
        _stakingToken = IERC20(token);
    }

    function initUSDT(address usdtStaking) public onlyOwner {
        _usdtStakingContract = IStakingRewards(address(usdtStaking));
        _usdtStakingContract.notifyRewardAmount(0);
    }

    function _stake(uint256 amount) private {
        _usdtStakingContract.stake(amount, msg.sender);
    }

    function _withdraw(uint256 amount) private {
        _usdtStakingContract.withdraw(amount, msg.sender);
    }

    function _getReward() private returns (uint256) {
        uint256 amount = _usdtStakingContract.getReward(msg.sender);
        return amount;
    }

    function getEarned(address account) public view returns (uint256) {
        return _usdtStakingContract.earned(account);
    }

    function addRewardAmount(uint256 amount) public onlyOwner {
        IERC20(usdt).safeTransfer(address(_usdtStakingContract), amount);
        _usdtStakingContract.notifyRewardAmount(amount);
    }

    function _backfallOnePeople(address leaderAddress) private {
        address ad;
        ad = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            backfallPeopleNum,
                            leaderAddress,
                            block.timestamp
                        )
                    )
                )
            )
        );
        AddressInfo storage whInfoObj = addressInfo[whiteAddress];
        AddressInfo storage addressInfoObj = addressInfo[ad];
        addressInfoObj.hasSetLeaderAddress = true;
        addressInfoObj.leaderAddress = leaderAddress;
        AddressInfo storage nowBlackFallObj = addressInfo[
            whiteWhoringedAddresses[nowBackfallIndex]
        ];
        if (nowBlackFallObj.leftAndRight.left == address(0)) {
            nowBlackFallObj.leftAndRight.left = ad;
        } else {
            nowBlackFallObj.leftAndRight.right = ad;
            nowBackfallIndex += 1;
        }

        uint256 nowTime = block.timestamp;
        addressInfoObj.whiteWhoring.startTime = nowTime;
        addressInfoObj.whiteWhoring.lastTime = nowTime;
        addressInfoObj.nowLen = whiteWhoringedAddresses.length + 1;
        if (addressInfoObj.nowLen > 3) {
            uint256 _i;
            if (addressInfoObj.nowLen & 1 == 0) {
                _i = addressInfoObj.nowLen / 2;
            } else {
                _i = (addressInfoObj.nowLen - 1) / 2;
            }
            if (_i & 1 == 0) {
                updateWhiteWhoringUpAddressInfo(_i / 2, 0);
            } else {
                updateWhiteWhoringUpAddressInfo((_i - 1) / 2, 0);
            }
        }
        whInfoObj.redirectInviteAddresses.push(ad);
        backfallPeopleMap[ad] = true;
        whiteWhoringedAddresses.push(ad);
    }

    //// WhiteWhoring view

    function getAddressWhiteWhoringInfo(
        address account
    )
        public
        view
        returns (
            bool,
            uint256,
            uint256,
            uint256,
            uint,
            address[] memory,
            address,
            uint256
        )
    {
        AddressInfo memory addressInfoObj = addressInfo[account];
        return (
            addressInfoObj.whiteWhoring.startTime != 0,
            getWhiteWhoringRewardAmount(account),
            getWhiteWhoringNoClaimedRewardAmount(account),
            addressInfoObj.whiteWhoring.startTime,
            getBackfallRewardNum(account),
            addressInfoObj.redirectInviteAddresses,
            addressInfoObj.leaderAddress,
            whiteWhoringTime
        );
    }

    function getWhiteWhoringRewardAmount(
        address account
    ) public view returns (uint256) {
        AddressInfo memory addressInfoObj = addressInfo[account];
        (uint256 num, uint256 _rate) = getWhiteWhoringLasttimeReward(account);
        uint256 exNum = num.mul(_rate).div(10000);
        return
            addressInfoObj.whiteWhoring.rewardAmount.add(exNum).add(num).add(
                addressInfoObj.whiteWhoring.inviteAmount
            );
    }

    function getWhiteWhoringLasttimeReward(
        address account
    ) private view returns (uint256, uint256) {
        AddressInfo memory addressInfoObj = addressInfo[account];
        if (
            addressInfoObj.whiteWhoring.startTime == 0 ||
            notHasWhiteWhoring[account]
        ) {
            return (0, 0);
        }
        uint256 ts = block.timestamp.sub(addressInfoObj.whiteWhoring.lastTime);
        if (
            block.timestamp - addressInfoObj.whiteWhoring.startTime >
            whiteWhoringTime
        ) {
            uint d = addressInfoObj.whiteWhoring.startTime.add(
                whiteWhoringTime
            );
            if (addressInfoObj.whiteWhoring.lastTime > d) {
                ts = 0;
            } else {
                ts = d.sub(addressInfoObj.whiteWhoring.lastTime);
            }
        }

        uint256 num;
        if (addressInfoObj.redirectInviteAddresses.length >= miniInvNum) {
            num = getBackfallRewardNum(account);
        }
        uint256 _rate = num.mul(inviteTokenRate).add(
            addressInfoObj.redirectInviteAddresses.length.mul(
                redirectInviteRate
            )
        );
        return (whiteWhoringDayToken.mul(ts).div(1 days), _rate);
    }

    function getBackfallRewardNum(address account) private view returns (uint) {
        AddressInfo memory addressInfoObj = addressInfo[account];
        uint256 n = whiteWhoringedAddresses.length;
        uint256 m = addressInfoObj.nowLen;
        if (m == 0) {
            return 0;
        }
        uint times;
        uint256 left = 2 * m;
        uint256 right = 2 * m + 1;
        uint256 num = 1;
        uint256 ans = 1;
        while (right <= n && times < depth) {
            num = num * 2;
            times += 1;
            ans += num;
            left = 2 * left;
            right = 2 * right + 1;
        }

        if (times == depth) {
            if (ans <= 3) {
                return 0;
            }
            return ans - 3;
        }

        if (left <= n) {
            ans += n - left + 1;
        }
        if (ans <= 3) {
            return 0;
        }
        return ans - 3;
    }

    function getRedirectInviteAddressInfo(
        address account
    ) public view returns (address[] memory) {
        AddressInfo memory addressInfoObj = addressInfo[account];
        return addressInfoObj.redirectInviteAddresses;
    }

    function getWhiteWhoringNoClaimedRewardAmount(
        address account
    ) public view returns (uint256) {
        return
            getWhiteWhoringRewardAmount(account)
                .sub(addressInfo[account].whiteWhoring.claimedAmount)
                .sub(addressInfo[account].whiteWhoring.claimedInviteAmount);
    }

    // staking view
    function getAddressStakingInfo(
        address account
    ) public view returns (uint256, uint256, uint256, uint256, uint256) {
        AddressInfo memory addressInfoObj = addressInfo[account];
        (uint256 baseNum, uint256 redirectNum) = getStakingLasttimeRewardAmount(
            account
        );
        uint256 amount = baseNum.add(redirectNum);
        return (
            addressInfoObj.staking.stakingAmount,
            addressInfoObj.staking.leftStakingAmount,
            amount,
            amount.sub(addressInfoObj.staking.claimedAmount).sub(
                addressInfoObj.staking.claimedInviteAmount
            ),
            addressInfoObj.staking.allStakeAmount
        );
    }

    function getStakingLasttimeRewardAmount(
        address account
    ) private view returns (uint256, uint256) {
        AddressInfo memory addressInfoObj = addressInfo[account];
        if (addressInfoObj.staking.lastTime == 0) {
            return (0, 0);
        }
        uint256 ts = block.timestamp.sub(addressInfoObj.staking.lastTime);
        uint256 stakingAmount = addressInfoObj.staking.stakingAmount;
        uint256 num1;
        uint256 num2;
        if (
            stakingAmount + addressInfoObj.staking.leftStakingAmount >=
            minStakingNum
        ) {
            if (addressInfoObj.redirectInviteAddresses.length >= miniInvNum) {
                num1 =
                    (((((addressInfoObj.staking.childNum * ts) / 1 days) *
                        stakingRate) / 10000) * inviteTokenRate) /
                    10000;
            }

            num2 =
                (((((addressInfoObj.staking.redrectNum * ts) / 1 days) *
                    stakingRate) / 10000) * redirectInviteRate) /
                10000;
        }

        return (
            addressInfoObj.staking.rewardAmount.add(
                stakingAmount.mul(ts).div(1 days).mul(stakingRate).div(10000)
            ),
            addressInfoObj.staking.inviteAmount.add(num1).add(num2)
        );
    }

    function claimWhiteWhoringReward()
        public
        nonReentrant
        isStart
        mustSetLeader
    {
        AddressInfo storage addressInfObj = addressInfo[msg.sender];
        (uint256 _num, uint256 _rate) = getWhiteWhoringLasttimeReward(
            msg.sender
        );
        uint256 exNum = _num.mul(_rate).div(10000);
        uint256 allBaseRewardAmount = addressInfObj
            .whiteWhoring
            .rewardAmount
            .add(_num);
        uint256 allInviteRewardAmount = addressInfObj
            .whiteWhoring
            .inviteAmount
            .add(exNum);
        uint256 baseNum = allBaseRewardAmount.sub(
            addressInfObj.whiteWhoring.claimedAmount
        );
        uint256 inviteNum = allInviteRewardAmount.sub(
            addressInfObj.whiteWhoring.claimedInviteAmount
        );
        uint256 _backFallNum = inviteNum.mul(fee).div(10000);
        uint256 tranferNum = inviteNum.sub(_backFallNum).add(baseNum);
        if (blackList[msg.sender]) {
            _stakingToken.safeTransfer(msg.sender, baseNum);
        } else {
            _stakingToken.safeTransfer(msg.sender, tranferNum);
        }

        addressInfObj.whiteWhoring.rewardAmount = allBaseRewardAmount;
        addressInfObj.whiteWhoring.inviteAmount = allInviteRewardAmount;
        addressInfObj.whiteWhoring.lastTime = block.timestamp;
        addressInfObj.whiteWhoring.claimedAmount = allBaseRewardAmount;
        addressInfObj.whiteWhoring.claimedInviteAmount = allInviteRewardAmount;
        uint256 _feeAmount = addressInfObj.feeAmount.add(_backFallNum);
        uint _times = maxBackFallNum.min(_feeAmount / backFallNum);
        for (uint256 index = 0; index < _times; index++) {
            _backfallOnePeople(msg.sender);
        }
        if (_times > 0) {
            backfallPeopleNum += _times;
        }
        addressInfObj.feeAmount = _feeAmount.sub(backFallNum.mul(_times));
    }

    function updateWhiteWhoringUpAddressInfo(
        uint nowLen,
        uint nowDeep
    ) private {
        if (nowDeep >= depth - 1) {
            return;
        }
        if (!backfallPeopleMap[whiteWhoringedAddresses[nowLen - 1]]) {
            AddressInfo storage leaderAddressInfoObj = addressInfo[
                whiteWhoringedAddresses[nowLen - 1]
            ];
            if (leaderAddressInfoObj.whiteWhoring.lastTime != block.timestamp) {
                (uint256 num, uint256 _rate) = getWhiteWhoringLasttimeReward(
                    whiteWhoringedAddresses[nowLen - 1]
                );
                leaderAddressInfoObj
                    .whiteWhoring
                    .rewardAmount = leaderAddressInfoObj
                    .whiteWhoring
                    .rewardAmount
                    .add(num);
                leaderAddressInfoObj
                    .whiteWhoring
                    .inviteAmount = leaderAddressInfoObj
                    .whiteWhoring
                    .inviteAmount
                    .add(num.mul(_rate).div(1000));
                leaderAddressInfoObj.whiteWhoring.lastTime = block.timestamp;
            }
        }

        if (nowLen > 1) {
            if (nowLen & 1 == 0) {
                updateWhiteWhoringUpAddressInfo(nowLen.div(2), nowDeep + 1);
            } else {
                updateWhiteWhoringUpAddressInfo(
                    (nowLen - 1).div(2),
                    nowDeep + 1
                );
            }
        }
    }

    function _updateStakingUpAddressInfo(
        address account,
        bool isAdd,
        uint256 amount,
        bool isRedirect
    ) private {
        AddressInfo storage leaderAddressInfoObj = addressInfo[account];
        if (leaderAddressInfoObj.staking.lastTime > 0) {
            (
                uint256 baseNum,
                uint256 redirectNum
            ) = getStakingLasttimeRewardAmount(account);

            leaderAddressInfoObj.staking.rewardAmount = baseNum;
            leaderAddressInfoObj.staking.inviteAmount = redirectNum;
        }

        if (isRedirect) {
            if (isAdd) {
                leaderAddressInfoObj.staking.redrectNum = leaderAddressInfoObj
                    .staking
                    .redrectNum
                    .add(amount);
            } else {
                leaderAddressInfoObj.staking.redrectNum = leaderAddressInfoObj
                    .staking
                    .redrectNum
                    .sub(amount);
            }
        } else {
            if (isAdd) {
                leaderAddressInfoObj.staking.childNum = leaderAddressInfoObj
                    .staking
                    .childNum
                    .add(amount);
            } else {
                leaderAddressInfoObj.staking.childNum = leaderAddressInfoObj
                    .staking
                    .childNum
                    .sub(amount);
            }
        }
        if (leaderAddressInfoObj.staking.lastTime > 0) {
            leaderAddressInfoObj.staking.lastTime = block.timestamp;
        }
    }

    function updateStakingUpAddressInfo(
        uint nowLen,
        uint nowDeep,
        uint256 amount,
        bool isAdd
    ) private {
        if (nowDeep >= depth - 1) {
            return;
        }
        _updateStakingUpAddressInfo(
            whiteWhoringedAddresses[nowLen - 1],
            isAdd,
            amount,
            false
        );

        if (nowLen > 1) {
            if (nowLen & 1 == 0) {
                updateStakingUpAddressInfo(
                    nowLen.div(2),
                    nowDeep + 1,
                    amount,
                    isAdd
                );
            } else {
                updateStakingUpAddressInfo(
                    (nowLen - 1).div(2),
                    nowDeep + 1,
                    amount,
                    isAdd
                );
            }
        }
    }

    function bindLeaderAddress(
        address leaderAddress
    ) public nonReentrant isStart mustNoSetLeader {
        require(!closeWhiteWhoring, "MTDOGE: closeWhiteWhoring");
        _usdtToken.transferFrom(msg.sender, receivingAddress, USDTNum);
        _bindLeaderAddress(msg.sender, leaderAddress);
    }

    function bindAdmin(
        address add,
        address leader
    ) public nonReentrant onlyOwner {
        _bindLeaderAddress(add, leader);
    }

    function _bindLeaderAddress(
        address nowAddress,
        address leaderAddress
    ) internal {
        require(
            leaderAddress != address(0) && leaderAddress != nowAddress,
            "MTDOGE: leaderAddress is address(0)"
        );
        require(startSanhu || leadersList[nowAddress], "not leader address");
        AddressInfo storage leaderAddressInfoObj = addressInfo[leaderAddress];
        require(
            leaderAddressInfoObj.whiteWhoring.startTime > 0 ||
                leaderAddress == whiteAddress,
            "MTDOGE: leaderAddress is not initWhiteWhoring"
        );
        if (needCount[leaderAddressInfoObj.needCountAddress]) {
            AddressInfo storage llld = addressInfo[
                leaderAddressInfoObj.needCountAddress
            ];
            llld.count = llld.count.add(1);
        }
        (uint256 num, uint256 _rate) = getWhiteWhoringLasttimeReward(
            leaderAddress
        );
        leaderAddressInfoObj.whiteWhoring.rewardAmount = leaderAddressInfoObj
            .whiteWhoring
            .rewardAmount
            .add(num);
        leaderAddressInfoObj.whiteWhoring.inviteAmount = leaderAddressInfoObj
            .whiteWhoring
            .inviteAmount
            .add(num.mul(_rate).div(10000));
        leaderAddressInfoObj.whiteWhoring.lastTime = block.timestamp;

        (uint256 baseNum, uint256 redirectNum) = getStakingLasttimeRewardAmount(
            leaderAddress
        );
        leaderAddressInfoObj.staking.rewardAmount = baseNum;
        leaderAddressInfoObj.staking.inviteAmount = redirectNum;
        leaderAddressInfoObj.staking.lastTime = block.timestamp;

        AddressInfo storage addressInfoObj = addressInfo[nowAddress];
        addressInfoObj.hasSetLeaderAddress = true;
        addressInfoObj.leaderAddress = leaderAddress;
        if (leaderAddress != whiteAddress) {
            AddressInfo storage nowBlackFallObj = addressInfo[
                whiteWhoringedAddresses[nowBackfallIndex]
            ];
            if (nowBlackFallObj.leftAndRight.left == address(0)) {
                nowBlackFallObj.leftAndRight.left = nowAddress;
            } else {
                nowBlackFallObj.leftAndRight.right = nowAddress;
                nowBackfallIndex += 1;
            }
        }

        require(
            addressInfoObj.whiteWhoring.startTime == 0,
            "MTDOGE: WhiteWhoring is init"
        );
        uint256 nowTime = block.timestamp;
        addressInfoObj.whiteWhoring.startTime = nowTime;
        addressInfoObj.whiteWhoring.lastTime = nowTime;
        addressInfoObj.nowLen = whiteWhoringedAddresses.length + 1;
        if (closeWhiteWhoring) {
            notHasWhiteWhoring[nowAddress] = true;
        }
        if (addressInfoObj.nowLen > 3) {
            uint256 _i;
            if (addressInfoObj.nowLen & 1 == 0) {
                _i = addressInfoObj.nowLen / 2;
            } else {
                _i = (addressInfoObj.nowLen - 1) / 2;
            }

            if (_i & 1 == 0) {
                updateWhiteWhoringUpAddressInfo(_i / 2, 0);
            } else {
                updateWhiteWhoringUpAddressInfo((_i - 1) / 2, 0);
            }
        }
        leaderAddressInfoObj.redirectInviteAddresses.push(nowAddress);
        whiteWhoringedAddresses.push(nowAddress);
    }

    function stake(
        uint256 amount,
        address leader
    ) public nonReentrant isStart isStartStake {
        AddressInfo storage addressInfoObj = addressInfo[msg.sender];
        if (!addressInfoObj.hasSetLeaderAddress) {
            if (amount >= minStakingNum) {
                if (leader == address(0)) {
                    leader = whiteAddress;
                }
                notHasWhiteWhoring[msg.sender] = true;
                AddressInfo memory leaderAddressInfoObj = addressInfo[leader];
                if (leaderAddressInfoObj.whiteWhoring.startTime == 0) {
                    leader = whiteAddress;
                }
                _bindLeaderAddress(msg.sender, leader);
            } else {
                revert("MTDOGE: amount is less than minStakingNum");
            }
        }

        uint256 nowTime = block.timestamp;
        if (addressInfoObj.staking.lastTime == 0) {
            stakedAddresses.push(msg.sender);
        } else {
            (
                uint256 baseNum,
                uint256 redirectNum
            ) = getStakingLasttimeRewardAmount(msg.sender);
            addressInfoObj.staking.rewardAmount = baseNum;
            addressInfoObj.staking.inviteAmount = redirectNum;
        }
        _stakingToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            amount
        );
        uint256 leftNum = amount.div(2);
        uint256 rightNum = amount.sub(leftNum);
        addressInfoObj.staking.stakingAmount = addressInfoObj
            .staking
            .stakingAmount
            .add(rightNum);
        addressInfoObj.staking.leftStakingAmount = addressInfoObj
            .staking
            .leftStakingAmount
            .add(leftNum);
        addressInfoObj.staking.allStakeAmount = addressInfoObj
            .staking
            .allStakeAmount
            .add(amount);
        addressInfoObj.staking.lastTime = nowTime;

        if (addressInfoObj.nowLen > 3) {
            uint256 _i;
            if (addressInfoObj.nowLen & 1 == 0) {
                _i = addressInfoObj.nowLen / 2;
            } else {
                _i = (addressInfoObj.nowLen - 1) / 2;
            }
            if (_i & 1 == 0) {
                updateStakingUpAddressInfo(_i / 2, 0, rightNum, true);
            } else {
                updateStakingUpAddressInfo((_i - 1) / 2, 0, rightNum, true);
            }
        }

        _updateStakingUpAddressInfo(
            addressInfoObj.leaderAddress,
            true,
            rightNum,
            true
        );

        _stake(leftNum);
    }

    function claimStakingReward() public nonReentrant isStart mustSetLeader {
        AddressInfo storage addressInfoObj = addressInfo[msg.sender];
        if (addressInfoObj.staking.lastTime == 0) {
            return;
        }
        (
            uint256 _baseNum,
            uint256 redirectNum
        ) = getStakingLasttimeRewardAmount(msg.sender);

        uint256 baseNum = _baseNum.sub(addressInfoObj.staking.claimedAmount);
        uint256 inviteNum = redirectNum.sub(
            addressInfoObj.staking.claimedInviteAmount
        );
        uint256 _backFallNum = inviteNum.mul(fee).div(10000);
        uint256 tranferNum = inviteNum.sub(_backFallNum).add(baseNum);
        if (blackList[msg.sender]) {
            _stakingToken.safeTransfer(msg.sender, baseNum);
        } else {
            _stakingToken.safeTransfer(msg.sender, tranferNum);
        }

        addressInfoObj.staking.claimedAmount = _baseNum;
        addressInfoObj.staking.claimedInviteAmount = redirectNum;
        uint256 _feeAmount = addressInfoObj.feeAmount.add(_backFallNum);
        uint _times = maxBackFallNum.min(_feeAmount / backFallNum);
        for (uint256 index = 0; index < _times; index++) {
            _backfallOnePeople(msg.sender);
        }
        if (_times > 0) {
            backfallPeopleNum += _times;
        }
        addressInfoObj.feeAmount = _feeAmount.sub(backFallNum.mul(_times));
    }

    function claimLeftReward() public nonReentrant isStart mustSetLeader {
        _getReward();
    }

    function withdraw(
        uint256 amount
    ) public nonReentrant isStart mustSetLeader {
        AddressInfo storage addressInfoObj = addressInfo[msg.sender];
        uint256 leftNum = amount.div(2);
        uint256 rightNum = amount.sub(leftNum);
        require(addressInfoObj.staking.stakingAmount > rightNum);
        uint256 nowTime = block.timestamp;

        (uint256 baseNum, uint256 redirectNum) = getStakingLasttimeRewardAmount(
            msg.sender
        );
        addressInfoObj.staking.rewardAmount = baseNum;
        addressInfoObj.staking.inviteAmount = redirectNum;
        _stakingToken.safeTransfer(msg.sender, rightNum);
        addressInfoObj.staking.stakingAmount = addressInfoObj
            .staking
            .stakingAmount
            .sub(rightNum);
        addressInfoObj.staking.leftStakingAmount = addressInfoObj
            .staking
            .leftStakingAmount
            .sub(leftNum);
        addressInfoObj.staking.lastTime = nowTime;
        if (addressInfoObj.nowLen > 3) {
            uint256 _i;
            if (addressInfoObj.nowLen & 1 == 0) {
                _i = addressInfoObj.nowLen / 2;
            } else {
                _i = (addressInfoObj.nowLen - 1) / 2;
            }

            if (_i & 1 == 0) {
                updateStakingUpAddressInfo(_i / 2, 0, rightNum, false);
            } else {
                updateStakingUpAddressInfo((_i - 1) / 2, 0, rightNum, false);
            }
        }

        _updateStakingUpAddressInfo(
            addressInfoObj.leaderAddress,
            false,
            rightNum,
            true
        );

        _withdraw(leftNum);
    }

    function getStakedAddress() public view returns (address[] memory) {
        return stakedAddresses;
    }

    function getWhiteWhoringedAddresses()
        public
        view
        returns (address[] memory)
    {
        return whiteWhoringedAddresses;
    }

    // update param
    function updateMinStakingNum(uint256 _minStakingNum) public onlyOwner {
        minStakingNum = _minStakingNum;
    }

    function updateStakingRate(uint256 _stakingRate) public onlyOwner {
        stakingRate = _stakingRate;
    }

    function updateInviteTokenRate(uint256 _inviteTokenRate) public onlyOwner {
        inviteTokenRate = _inviteTokenRate;
    }

    function updateActiveWhiteWhoringNum(uint256 _bnbNum) public onlyOwner {
        USDTNum = _bnbNum;
    }

    function updateMaxBackFallNum(uint256 _maxBackFallNum) public onlyOwner {
        maxBackFallNum = _maxBackFallNum;
    }

    function updateRedirectInviteRate(
        uint256 _redirectInviteRate
    ) public onlyOwner {
        redirectInviteRate = _redirectInviteRate;
    }

    function updateStartTime(uint256 _startTime) public onlyOwner {
        startTime = _startTime;
    }

    function updateCloseWhiteWhoring(bool _closeWhiteWhoring) public onlyOwner {
        closeWhiteWhoring = _closeWhiteWhoring;
    }

    function updateDepth(uint _depth) public onlyOwner {
        depth = _depth;
    }

    function updateBlackList(
        address[] memory accounts,
        bool v
    ) public onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            blackList[accounts[i]] = v;
        }
    }

    function updateFee(uint _fee) public onlyOwner {
        fee = _fee;
    }

    function updateBackFallNum(uint256 _backFallNum) public onlyOwner {
        backFallNum = _backFallNum;
    }

    function updateWhiteWhoringDayToken(
        uint256 _whiteWhoringDayToken
    ) public onlyOwner {
        whiteWhoringDayToken = _whiteWhoringDayToken;
    }

    function updateWhiteAddress(address account) public onlyOwner {
        whiteAddress = account;
    }

    // update startSanhu
    function updateStartSanhu(bool _startSanhu) public onlyOwner {
        startSanhu = _startSanhu;
    }

    // update startStake
    function updateStartStake(bool _startStake) public onlyOwner {
        startStake = _startStake;
    }

    // update leadersList
    function updateLeadersList(
        address[] memory accounts,
        bool v
    ) public onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            leadersList[accounts[i]] = v;
        }
    }

    function claimAdmin(
        address payable account,
        uint256 _usdt,
        uint256 _token,
        uint256 _bnb
    ) public onlyOwner {
        if (_usdt > 0) {
            _usdtToken.safeTransfer(account, _usdt);
        }
        if (_token > 0) {
            _stakingToken.safeTransfer(account, _token);
        }
        if (_bnb > 0) {
            account.transfer(_bnb);
        }
    }

    function claimUSDT(address account, uint256 _usdt) public onlyOwner {
        _usdtStakingContract.claimUSDT(account, _usdt);
    }

    function setNeetCount(address a, bool v) public onlyOwner {
        needCount[a] = v;
        AddressInfo storage llld = addressInfo[a];
        llld.needCountAddress = a;
    }

    function updateR(address a) public onlyOwner {
        receivingAddress = a;
    }

    function updateWhiteWhoringTime(
        uint256 _whiteWhoringTime
    ) public onlyOwner {
        whiteWhoringTime = _whiteWhoringTime;
    }

    function updateMiniInvNum(uint256 _miniInvNum) public onlyOwner {
        miniInvNum = _miniInvNum;
    }

    function getCount(address a) public view returns (uint256) {
        return addressInfo[a].count;
    }
}