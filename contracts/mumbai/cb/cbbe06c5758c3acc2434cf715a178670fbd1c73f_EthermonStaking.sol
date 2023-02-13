/**
 *Submitted for verification at polygonscan.com on 2023-02-13
*/

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
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
     *
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
     *
     * - Subtraction cannot overflow.
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
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

// File: openzeppelin-solidity/contracts/utils/Address.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
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

// File: openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
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
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
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
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        _callOptionalReturn(
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

// File: contracts/Context.sol

pragma solidity 0.6.6;

contract Context {
    function msgSender() internal view returns (address payable sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }
}

// File: contracts/BasicAccessControl.sol

pragma solidity 0.6.6;

contract BasicAccessControl is Context {
    address payable public owner;
    // address[] public moderators;
    uint16 public totalModerators = 0;
    mapping(address => bool) public moderators;
    bool public isMaintaining = true;

    constructor() public {
        owner = msgSender();
    }

    modifier onlyOwner() {
        require(msgSender() == owner);
        _;
    }

    modifier onlyModerators() {
        require(msgSender() == owner || moderators[msgSender()] == true);
        _;
    }

    modifier isActive() {
        require(!isMaintaining);
        _;
    }

    function ChangeOwner(address payable _newOwner) public onlyOwner {
        if (_newOwner != address(0)) {
            owner = _newOwner;
        }
    }

    function AddModerator(address _newModerator) public onlyOwner {
        if (moderators[_newModerator] == false) {
            moderators[_newModerator] = true;
            totalModerators += 1;
        } else {
            delete moderators[_newModerator];
            totalModerators -= 1;
        }
    }

    function UpdateMaintaining(bool _isMaintaining) public onlyOwner {
        isMaintaining = _isMaintaining;
    }

    function Kill() public onlyOwner {
        selfdestruct(owner);
    }
}

// File: contracts/EthermonStakingBasic.sol

pragma solidity 0.6.6;

contract EthermonStakingBasic is BasicAccessControl {
    struct TokenData {
        uint256 endTime;
        uint256 lastCalled;
        uint16 level;
        uint8 validTeam;
        uint256 teamPower;
        uint256 balance;
        uint16 badge;
        address owner;
        uint64[] monId;
        uint32[] classId;
        uint256 lockId;
        uint256 pfpId;
        uint256 emons;
        Duration duration;
    }

    enum Duration {
        Days_30,
        Days_60,
        Days_90,
        Days_120,
        Days_180,
        Days_365
    }

    uint256 public decimal = 18;

    event TeamPowerLog(uint256 power);

    function setDecimal(uint256 _decimal) external onlyModerators {
        decimal = _decimal;
    }
}

// File: contracts/EthermonStaking.sol

pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;

interface EthermonStakingInterface {
    function miscData(uint256 _index) external returns (uint256);

    function setMiscData(uint256 _index, uint256 _value) external;

    function addTokenData(bytes calldata _data) external;

    function getTokenDataTup(uint256 _lockId)
        external
        returns (EthermonStakingBasic.TokenData memory);

    function removeTokenData(EthermonStakingBasic.TokenData calldata) external;

    function updateTokenReward(
        bytes calldata _data,
        uint256 _timeElapsed,
        uint256 _lastCalled
    ) external;

    function updateTokenData(bytes calldata _data) external;

    function getMonStaker(address _owner, uint64 _monId)
        external
        returns (bool);

    function getPfpStaker(address _owner, uint256 _pfpId)
        external
        returns (bool);

    function setMonStaker(address _owner, uint64 _monId) external;

    function setPfpStaker(address _owner, uint256 _pfpId) external;

    function removeMonStaker(address _owner, uint64 _monId) external;

    function removePfpStaker(address _owner, uint256 _pfpId) external;
}

interface EthermonWeightInterface {
    function getClassWeight(uint32 _classId)
        external
        view
        returns (uint256 weight);
}

contract EthermonStaking is EthermonStakingBasic {
    using SafeERC20 for IERC20;

    struct DepositeToken {
        Duration _day;
        uint256 _amount;
        uint64[] _monId;
        uint32[] _classId;
        uint64 _pfpId;
        uint16 _level;
        uint16 _badgeAdvantage;
    }

    event Deposite(
        address _owner,
        uint256 _lockId,
        uint256 _pfpId,
        uint64[] _monId,
        uint256 _emons
    );

    mapping(uint256 => uint8) public pfpsAdvantage;
    uint16[] public daysToStake = [1, 7, 14, 30, 60, 90];
    uint16[] public daysAdvantage = [60, 65, 70, 80, 90, 100];

    uint256 public maxDepositeValue = 100000 * 10**decimal;
    uint256 public minDepositeValue = 1000 * 10**decimal;
    uint256 public maxStakingTime = 0;
    uint256 public depositeContractEmons;
    uint256 public maxMonCap = 1;
    uint8 public defaultBadgeWeight = 35;
    uint256 public withdrawCapMultiplier = 5;
    uint8 private rewardsCap = 100;
    uint8 public defaultPFPAdvantage = 1;

    address public verifyAddress;
    address public stakingDataContract;
    address public ethermonWeightContract;
    IERC20 public emon;

    bool public allowBadge = true;
    uint256 public activeStakers = 0;
    uint256 public Counter = 0;
    bytes constant SIG_PREFIX = "\x19Ethereum Signed Message:\n32";

    constructor(
        address _stakingDataContract,
        address _ethermonWeightContract,
        address _oldStakingContract,
        address _emon
    ) public {
        stakingDataContract = _stakingDataContract;
        ethermonWeightContract = _ethermonWeightContract;
        maxStakingTime = now + (daysToStake[0] * 1 days);
        emon = IERC20(_emon);
        if (_oldStakingContract != address(0)) {
            EthermonStaking oldStaking = EthermonStaking(_oldStakingContract);
            Counter = oldStaking.Counter();
            emon.safeTransferFrom(
                _oldStakingContract,
                address(this),
                oldStaking.getBalance()
            );
        }
    }

    function setPFPAdvantage(uint256 _pfpId, uint8 _advantage)
        external
        onlyModerators
    {
        require(
            _pfpId > 0 && _advantage > 0,
            "PFP ID or Advantage provided is wrong"
        );
        pfpsAdvantage[_pfpId] = _advantage;
    }

    function setDefaultPFPAdvantage(uint8 _defaultPFPAdvantage)
        external
        onlyModerators
    {
        require(_defaultPFPAdvantage > 0, "Advantage provided is wrong");
        defaultPFPAdvantage = _defaultPFPAdvantage;
    }

    function updateDaysArray(uint16[] calldata _daysToStake)
        external
        onlyModerators
    {
        require(_daysToStake.length < 11, "Invalid index");
        if (_daysToStake.length < daysToStake.length) {
            for (uint256 index = 0; index < daysToStake.length; index++) {
                if (index >= (_daysToStake.length - 2)) {
                    daysToStake.pop();
                    continue;
                }
                daysToStake[index] = _daysToStake[index];
            }
        } else {
            for (uint256 index = 0; index < _daysToStake.length; index++) {
                if (index >= daysToStake.length) {
                    daysToStake.push(_daysToStake[index]);
                    continue;
                }
                daysToStake[index] = _daysToStake[index];
            }
        }
    }

    function updateDaysAdvantageArray(uint16[] calldata _daysAdvantage)
        external
        onlyModerators
    {
        require(_daysAdvantage.length < 11, "Invalid index");
        if (_daysAdvantage.length < daysAdvantage.length) {
            for (uint256 index = 0; index < daysAdvantage.length; index++) {
                if (index >= (_daysAdvantage.length - 2)) {
                    daysAdvantage.pop();
                    continue;
                }
                daysAdvantage[index] = _daysAdvantage[index];
            }
        } else {
            for (uint256 index = 0; index < _daysAdvantage.length; index++) {
                if (index >= daysAdvantage.length) {
                    daysAdvantage.push(_daysAdvantage[index]);
                    continue;
                }
                daysAdvantage[index] = _daysAdvantage[index];
            }
        }
    }

    function setMaxMonCap(uint256 _maxMonCap) external onlyModerators {
        maxMonCap = _maxMonCap;
    }

    function toggleAllowBadge() external onlyOwner {
        allowBadge = !allowBadge;
    }

    function setVerifyAddress(address _verifyAddress) external onlyOwner {
        verifyAddress = _verifyAddress;
    }

    function setContracts(
        address _stakingDataContract,
        address _ethermonWeightContract,
        address _emon
    ) public onlyModerators {
        stakingDataContract = _stakingDataContract;
        ethermonWeightContract = _ethermonWeightContract;
        emon = IERC20(_emon);
    }

    function setWithdrawCapMultiplier(uint256 _withdrawCapMultiplier)
        public
        onlyModerators
    {
        withdrawCapMultiplier = _withdrawCapMultiplier;
    }

    function setDepositeValues(
        uint256 _minDepositeValue,
        uint256 _maxDepositeValue
    ) public onlyModerators {
        minDepositeValue = _minDepositeValue;
        maxDepositeValue = _maxDepositeValue;
    }

    function setDefaultBadge(uint8 _defaultBadgeWeight)
        external
        onlyModerators
    {
        defaultBadgeWeight = _defaultBadgeWeight;
    }

    function changeRewardCap(uint8 _rewardCap) external onlyModerators {
        require(_rewardCap > 0, "Invlaid reward cap value");
        rewardsCap = _rewardCap;
    }

    function depositeTokens(
        bytes32 _r,
        bytes32 _s,
        uint8 _v,
        uint256 _nonce1,
        uint256 _nonce2,
        DepositeToken calldata depositeData
    ) external isActive {
        uint256 currentTime = now;
        address owner = msgSender();

        require(
            (depositeData._monId.length <= maxMonCap &&
                depositeData._classId.length <= maxMonCap) &&
                (depositeData._monId.length > 0 &&
                    depositeData._classId.length > 0),
            "Mons limit exceed"
        );
        require(
            maxStakingTime > currentTime &&
                ((maxStakingTime -
                    (currentTime +
                        daysToStake[uint8(depositeData._day)] *
                        1 days)) /
                    1 days >=
                    daysToStake[0]),
            "Date is too high for staking"
        );

        require(owner == tx.origin, "Invalid address");

        require(
            depositeData._monId.length == depositeData._classId.length,
            "Mon ID and Class ID length should match"
        );

        bytes32 hashValue = keccak256(
            abi.encodePacked(
                owner,
                depositeData._day,
                depositeData._amount,
                depositeData._monId,
                depositeData._classId,
                depositeData._pfpId,
                depositeData._level,
                depositeData._badgeAdvantage,
                _nonce1,
                _nonce2
            )
        );

        require(
            (getVerifyAddress(owner, hashValue, _v, _r, _s) == verifyAddress),
            "Not verified"
        );

        EthermonStakingInterface stakingData = EthermonStakingInterface(
            stakingDataContract
        );

        uint256 balance = emon.balanceOf(owner);
        require(
            balance >= minDepositeValue &&
                depositeData._amount >= minDepositeValue &&
                depositeData._amount <= maxDepositeValue,
            "Balance is not valid"
        );
        TokenData memory data;

        require(data.owner == address(0), "Token already exists");
        require(
            !stakingData.getPfpStaker(owner, depositeData._pfpId),
            "PFP already staked"
        );

        for (uint256 i = 0; i < depositeData._monId.length; i++) {
            require(
                !stakingData.getMonStaker(owner, depositeData._monId[i]),
                "Mon already staked"
            );
        }

        uint8 pfpAdvantage = pfpsAdvantage[depositeData._pfpId] +
            defaultPFPAdvantage;

        data.owner = owner;
        data.emons = depositeData._amount;
        data.monId = depositeData._monId;
        data.pfpId = depositeData._pfpId;
        data.classId = depositeData._classId;

        data.lastCalled = currentTime;
        data.duration = depositeData._day;
        data.endTime =
            currentTime +
            (daysToStake[uint8(depositeData._day)] * 1 days);

        data.badge = allowBadge
            ? depositeData._badgeAdvantage
            : defaultBadgeWeight;
        data.level = depositeData._level;
        data.validTeam = 1;

        data.teamPower +=
            (data.emons / 10**decimal) *
            data.level *
            getSumWeight(data.classId, data.monId) *
            daysAdvantage[uint8(data.duration)] *
            pfpAdvantage *
            data.badge;

        data.balance = 0;
        Counter++;
        data.lockId = Counter;
        bytes memory output = abi.encode(data);
        uint256 newSumTeamPower = stakingData.miscData(1);
        uint256 totalStaked = stakingData.miscData(3);
        newSumTeamPower += data.teamPower;
        totalStaked += data.emons;

        stakingData.setMiscData(1, newSumTeamPower);
        stakingData.setMiscData(3, totalStaked);
        stakingData.addTokenData(output);

        activeStakers++;
        emon.safeTransferFrom(msgSender(), address(this), data.emons);

        // only update new sumteampower for first staker after that only update sumteampower when update till last token is completed(Look UpdateTokens()).
        if (activeStakers <= 1) {
            stakingData.setMiscData(0, newSumTeamPower);
            stakingData.setMiscData(
                2,
                (totalStaked * stakingData.miscData(4)) / (365 * 24)
            );
        } else emit TeamPowerLog(stakingData.miscData(0));

        stakingData.setPfpStaker(owner, data.pfpId);
        for (uint256 i = 0; i < data.monId.length; i++)
            stakingData.setMonStaker(owner, data.monId[i]);

        emit Deposite(
            data.owner,
            data.lockId,
            data.pfpId,
            data.monId,
            data.emons
        );
    }

    function updateTokens(
        uint256 _lockId,
        uint16 _level,
        uint8 _validTeam,
        bool _updateSumTeamPower
    ) external onlyModerators {
        EthermonStakingInterface stakingData = EthermonStakingInterface(
            stakingDataContract
        );

        uint256 currentTime = now;

        TokenData memory data = stakingData.getTokenDataTup(_lockId);

        require(
            data.owner != address(0) && data.monId.length > 0 && _level > 0,
            "Data is not valid"
        );

        if (data.lastCalled >= data.endTime) return;

        data.validTeam = _validTeam;

        //TODO: Will upgrade teampower and sumteampower with level upgrade in _V2
        data.level = _level;

        uint256 sumTeamPower = stakingData.miscData(0);
        sumTeamPower = (sumTeamPower > 1) ? sumTeamPower - 1 : 1;

        uint256 newSumTeamPower = stakingData.miscData(1);

        // Cap for if teamPower > sumTeamPower then reward dispatched alot.
        if (data.teamPower > sumTeamPower && newSumTeamPower > sumTeamPower)
            sumTeamPower = newSumTeamPower;
        if (data.teamPower > sumTeamPower) sumTeamPower += data.teamPower;

        uint256 timeElapsed = (currentTime - data.lastCalled) / 1 hours;
        uint256 emonPerPeriod = stakingData.miscData(2);
        uint256 lastCalled = data.lastCalled;
        uint256 totalStaked = stakingData.miscData(3);

        if (currentTime >= data.endTime) {
            if (timeElapsed > 0) {
                timeElapsed =
                    timeElapsed -
                    ((currentTime - data.endTime) / 1 hours);
            }
            data.lastCalled = currentTime;

            if (newSumTeamPower > data.teamPower)
                newSumTeamPower -= data.teamPower;
            if (totalStaked >= data.emons) totalStaked -= data.emons;

            stakingData.setMiscData(1, newSumTeamPower);
            stakingData.setMiscData(3, totalStaked);

            if (activeStakers > 0) activeStakers--;
        }
        if (timeElapsed > 0) data.lastCalled = currentTime;

        uint256 hourlyEmon = ((data.teamPower * 10**decimal) / sumTeamPower) *
            emonPerPeriod *
            timeElapsed *
            data.validTeam;

        data.balance = data.balance + (hourlyEmon / 10**18);
        bytes memory encoded = abi.encode(data);

        stakingData.updateTokenReward(encoded, timeElapsed, lastCalled);
        // 10 / 11
        if (_updateSumTeamPower) {
            //data.lockId >= Counter -> Passing this check from backend so there is no conflict with upcoming staker.
            stakingData.setMiscData(0, newSumTeamPower);
            stakingData.setMiscData(
                2,
                (totalStaked * stakingData.miscData(4)) / (365 * 24)
            );
        }
    }

    function getSumWeight(uint32[] memory _classIds, uint64[] memory _monIds)
        public
        view
        returns (uint256)
    {
        uint256 rarityWeight = 0;
        EthermonWeightInterface weightData = EthermonWeightInterface(
            ethermonWeightContract
        );
        for (uint256 i = 0; i < _classIds.length; i++) {
            require(
                _classIds[i] > 0 && _monIds[i] > 0,
                "Invlid Class or Mon ID"
            );

            rarityWeight += weightData.getClassWeight(_classIds[i]);
        }
        return rarityWeight;
    }

    function setMaxStakingTime(Duration _duration) external onlyModerators {
        maxStakingTime = now + ((daysToStake[(uint8)(_duration)] + 1) * 1 days);
    }

    function withdrawRewards(uint256 _lockId) external {
        EthermonStakingInterface stakingData = EthermonStakingInterface(
            stakingDataContract
        );
        uint256 currentTime = now;

        TokenData memory data = stakingData.getTokenDataTup(_lockId);
        require(currentTime >= data.endTime, "Time remaining to unstake");
        require(data.owner == msgSender(), "Wrong lockId");

        uint256 timeElapsed = (currentTime - data.lastCalled) / (1 hours);

        require(rewardsCap > 0, "Reward cap reached max capacity");
        uint256 totalStaked = stakingData.miscData(3);
        uint256 newSumTeamPower = stakingData.miscData(1);

        uint256 pfpId = data.pfpId;
        uint64[] memory monId = data.monId;

        if (data.lastCalled < data.endTime) {
            // 6 - (7 - 3) => 6 - 4 = 2
            if (timeElapsed > 0)
                timeElapsed =
                    timeElapsed -
                    ((currentTime - data.endTime) / 1 hours);

            uint256 sumTeamPower = stakingData.miscData(0);
            sumTeamPower = (sumTeamPower > 1) ? sumTeamPower - 1 : 1;

            // Cap for if teamPower > sumTeamPower then reward dispatched alot.
            if (data.teamPower > sumTeamPower && newSumTeamPower > sumTeamPower)
                sumTeamPower = newSumTeamPower;
            if (data.teamPower > sumTeamPower) sumTeamPower += data.teamPower;

            uint256 emonPerPeriod = stakingData.miscData(2);

            uint256 hourlyEmon = ((data.teamPower * 10**decimal) /
                sumTeamPower) *
                emonPerPeriod *
                timeElapsed *
                data.validTeam;

            data.balance = data.balance + (hourlyEmon / 10**18);

            data.lastCalled = currentTime;

            if (newSumTeamPower > data.teamPower)
                newSumTeamPower -= data.teamPower;
            if (totalStaked >= data.emons) totalStaked -= data.emons;

            stakingData.setMiscData(1, newSumTeamPower);
            stakingData.setMiscData(3, totalStaked);

            if (activeStakers > 0) activeStakers--;
        }
        uint256 emonsBalance = data.emons;
        // Throw error when somebody tries to withdraw more than 5x of principal
        data.emons += data.balance;

        // withdraw - totalstaked   =  res
        // 1000 - 10000 = 9000
        uint256 depositedBalance = emon.balanceOf(address(this));

        require(
            depositeContractEmons > data.balance,
            "Not enough EMONs within the contract"
        );

        require(
            depositedBalance >= data.emons &&
                withdrawCapMultiplier > 0 &&
                data.emons < (emonsBalance * withdrawCapMultiplier),
            "Contract donot have emons to dispatch"
        );

        emon.safeTransfer(data.owner, data.emons);
        stakingData.removeTokenData(data);
        rewardsCap--;
        depositeContractEmons -= data.balance;

        if (activeStakers <= 1) {
            stakingData.setMiscData(0, newSumTeamPower);
            stakingData.setMiscData(
                2,
                (totalStaked * stakingData.miscData(4)) / (365 * 24)
            );
        }

        stakingData.removePfpStaker(msgSender(), pfpId);

        for (uint256 i = 0; i < monId.length; i++)
            stakingData.removeMonStaker(msgSender(), monId[i]);
    }

    function updateStakingData(
        uint256 _lockId,
        bytes32 _r,
        bytes32 _s,
        uint8 _v,
        uint256 _nonce1,
        uint256 _nonce2,
        DepositeToken calldata _depositeToken
    ) external isActive {
        uint256 currentTime = now;

        require(
            _depositeToken._monId.length <= maxMonCap &&
                _depositeToken._classId.length <= maxMonCap,
            "Mons limit exceed"
        );

        require(
            _depositeToken._monId.length == _depositeToken._classId.length,
            "Mon ID and Class ID length should match"
        );

        address owner = msgSender();
        require(owner == tx.origin, "Invalid address");

        bytes32 hashValue = keccak256(
            abi.encodePacked(
                owner,
                _depositeToken._day,
                _depositeToken._amount,
                _depositeToken._monId,
                _depositeToken._classId,
                _depositeToken._pfpId,
                _depositeToken._level,
                _depositeToken._badgeAdvantage,
                _nonce1,
                _nonce2
            )
        );

        require(
            (getVerifyAddress(owner, hashValue, _v, _r, _s) == verifyAddress),
            "Not verified"
        );

        EthermonStakingInterface stakingData = EthermonStakingInterface(
            stakingDataContract
        );

        TokenData memory data = stakingData.getTokenDataTup(_lockId);

        require(data.owner != address(0), "Staking data does not exists");
        require(data.owner == owner, "Unauthorized staker");
        require(data.endTime > currentTime, "Staking time ended");

        uint256 totalStaked = stakingData.miscData(3);

        if (_depositeToken._amount > 0) {
            require(
                emon.balanceOf(msgSender()) > _depositeToken._amount,
                "Insufficient amount to update"
            );
            data.emons += _depositeToken._amount;
            totalStaked += _depositeToken._amount;
        }
        if (_depositeToken._pfpId != data.pfpId) {
            require(
                !stakingData.getPfpStaker(owner, _depositeToken._pfpId),
                "PFP already staked"
            );
            stakingData.removePfpStaker(owner, data.pfpId);
            data.pfpId = _depositeToken._pfpId;
            stakingData.setPfpStaker(owner, data.pfpId);
        }

        for (uint256 i = 0; i < _depositeToken._monId.length; i++) {
            if (_depositeToken._monId[i] != data.monId[i]) {
                require(
                    !stakingData.getMonStaker(owner, _depositeToken._monId[i]),
                    "Mon already staked"
                );
                stakingData.removeMonStaker(owner, data.monId[i]);
                data.monId[i] = _depositeToken._monId[i];
                stakingData.setMonStaker(owner, data.monId[i]);
            }
        }
        //uint256 sumTeamPower = stakingData.NewSumTeamPower();
        uint256 sumTeamPower = stakingData.miscData(1);
        if (sumTeamPower > data.teamPower) sumTeamPower -= data.teamPower;

        data.classId = _depositeToken._classId;
        data.level = _depositeToken._level;
        data.validTeam = (_depositeToken._monId.length > 0 &&
            _depositeToken._classId.length > 0)
            ? 1
            : 0;

        data.badge = allowBadge
            ? _depositeToken._badgeAdvantage
            : defaultBadgeWeight;

        uint256 timeElapsed = (currentTime - data.lastCalled) / (1 hours);

        if (timeElapsed > 0) {
            // data.balance = data.balance + (hourlyEmon / 10**18);
            uint256 teamPower = data.teamPower * 10**decimal;
            uint256 hourlyEmon = (teamPower / (stakingData.miscData(0) - 1)) *
                stakingData.miscData(2) *
                timeElapsed *
                data.validTeam;

            data.balance = data.balance + (hourlyEmon / 10**18);
            data.lastCalled = currentTime;
        }

        if (_depositeToken._day > data.duration) {
            uint256 updatedTime = currentTime +
                (daysToStake[uint8(_depositeToken._day)] * 1 days);

            uint256 remainingTime = data.endTime - data.lastCalled;
            //New end time.
            uint256 endTime = remainingTime + updatedTime;

            //What ever left after subtrating from maxTime should be >= 30
            require(
                maxStakingTime > endTime &&
                    ((maxStakingTime - endTime) / 1 days) >= daysToStake[0],
                "Date is too high for staking"
            );

            data.endTime = endTime;
            data.duration = _depositeToken._day;
        }

        uint8 pfpAdvantage = pfpsAdvantage[data.pfpId] + defaultPFPAdvantage;

        data.teamPower =
            (data.emons / 10**decimal) *
            data.level *
            getSumWeight(data.classId, data.monId) *
            daysAdvantage[uint8(data.duration)] *
            pfpAdvantage *
            data.validTeam *
            data.badge;

        data.lastCalled = currentTime;
        sumTeamPower += data.teamPower;

        stakingData.setMiscData(1, sumTeamPower);
        stakingData.setMiscData(3, totalStaked);
        bytes memory encoded = abi.encode(data);
        stakingData.updateTokenData(encoded);
    }

    function depositeEmons(uint256 _amount) external onlyModerators {
        require(
            _amount > 0 && _amount <= emon.balanceOf(msgSender()),
            "Invalid amount"
        );
        emon.safeTransferFrom(msgSender(), address(this), _amount);
        depositeContractEmons += _amount;
    }

    function withdrawEmon(address _sendTo) external onlyModerators {
        require(depositeContractEmons > 0, "Deposited EMON is 0");
        emon.safeTransfer(_sendTo, depositeContractEmons);
        depositeContractEmons = 0;
    }

    function getBalance() public view returns (uint256) {
        return emon.balanceOf(address(this));
    }

    function getVerifyAddress(
        address sender,
        bytes32 _token,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public pure returns (address) {
        bytes32 hashValue = keccak256(abi.encodePacked(sender, _token));
        bytes32 prefixedHash = keccak256(
            abi.encodePacked(SIG_PREFIX, hashValue)
        );
        return ecrecover(prefixedHash, _v, _r, _s);
    }

    function getMessageHash(
        address _sender,
        uint256 nonce1,
        uint256 nonce2,
        DepositeToken memory _depositeToken
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _sender,
                    _depositeToken._day,
                    _depositeToken._amount,
                    _depositeToken._monId,
                    _depositeToken._classId,
                    _depositeToken._pfpId,
                    _depositeToken._level,
                    _depositeToken._badgeAdvantage,
                    nonce1,
                    nonce2
                )
            );
    }

    function getVerifySignature(address sender, bytes32 _token)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(sender, _token));
    }
}