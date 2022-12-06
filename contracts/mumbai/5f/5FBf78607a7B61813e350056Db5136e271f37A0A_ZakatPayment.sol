/**
 *Submitted for verification at polygonscan.com on 2022-12-05
*/

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
    bool public isMaintaining = false;

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

    function UpdateMaintaining(bool _isMaintaining) public onlyOwner {
        isMaintaining = _isMaintaining;
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
        }
    }

    function Kill() public onlyOwner {
        selfdestruct(owner);
    }
}

// File: contracts/ZakatBasic.sol

pragma solidity 0.6.6;

contract ZakatBasic is BasicAccessControl {
    struct ZakatRecord {
        uint256 amount;
        bool doner;
        uint256 recievedAt;
    }

    struct ZakatApproval {
        uint256 requested;
        uint256 requestId;
        bool doner;
    }

    struct ZakatEligible {
        uint256 amount;
        bool eligible;
        bool doner;
        Duration duration;
    }

    enum Duration {
        Every_Month,
        Half_A_Year,
        Every_Year
    }

    uint256 public decimal = 18;

    function setDecimal(uint256 _decimal) external onlyOwner {
        decimal = _decimal;
    }

    event Withdraw(address _from, address _to, uint256 _amount);
    event Deposite(address _from, address _to, uint256 _amount);
}

// File: contracts/ZakatOracle.sol

pragma solidity 0.6.6;

contract ZakatOracle is BasicAccessControl {
    uint256 zktsInEth = 0;
    // ZKT price per dollar
    uint256 public zktPrice = 0;
    // ETH price per dollar
    uint256 public ethPrice = 0;

    uint256 zktCap = 0;
    uint256 ethCap = 0;
    uint256 zktMaxCap = 0;
    uint256 ethMaxCap = 0;

    constructor() public {
        ethMaxCap = 1 * 10**18;
        zktMaxCap = 1 * 10**18;
    }

    /**
        @param _amount: uint256 => Amount in ETH 
        @return Price in ZKT
        Disctiption: Pass 1 ETH get value in ZKT
    */
    function getZktRatesFromEth(uint256 _amount)
        public
        view
        returns (uint256)
    {
        uint256 ethP = ethPrice * _amount;
        uint256 zktP = zktPrice * 10**18;

        uint256 rate = ethP / zktP;
        if (rate <= 0) {
            rate = (ethP * 10**18) / zktP;
            rate = (rate < ethCap) ? ethCap : rate;
            return rate;
        }
        rate = rate * 10**18;
        rate = (rate < ethCap) ? ethCap : rate;

        return rate;
    }

    /**
        @param _amount: uint256 => Amount in ZKT 
        @return Price in ETH
        Disctiption: Pass 1 ZKT get value in ETH
    */
    function getEthRatesFromZkt(uint256 _amount)
        public
        view
        returns (uint256)
    {
        uint256 zktP = zktPrice * _amount;
        uint256 ethP = ethPrice * 10**18;

        uint256 rate = zktP / ethP;
        if (rate <= 0) {
            rate = (zktP * 10**18) / ethP;
            rate = (rate < zktCap) ? zktCap : rate;
            return rate;
        }
        rate = (rate < zktCap) ? zktCap : rate;

        return rate;
    }

    function updatePrices(uint256 _zktPrice, uint256 _ethPrice)
        external
        onlyModerators
    {
        if (_zktPrice < zktCap) zktPrice = _zktPrice;
        if (_ethPrice < ethCap) ethPrice = _ethPrice;

        ethPrice = _ethPrice;
        zktPrice = _zktPrice;
    }

    function setCapZkt(uint256 _zktCap) external onlyModerators {
        require(_zktCap < zktMaxCap, "Cannot put cap lesser than 0");
        zktCap = _zktCap;
    }

    function setCapEth(uint256 _ethCap) external onlyModerators {
        require(_ethCap <= ethMaxCap, "Cannot put cap lesser than 0");
        ethCap = _ethCap;
    }

    function setMaxCapZkt(uint256 _zktMaxCap) external onlyOwner {
        zktMaxCap = _zktMaxCap;
    }

    function setMaxCapEth(uint256 _ethMaxCap) external onlyOwner {
        ethMaxCap = _ethMaxCap;
    }
}

// File: contracts/ZakatData.sol

pragma solidity 0.6.6;

contract ZakatData is ZakatBasic {
    mapping(address => ZakatEligible) eligible;

    function setEligible(
        address _person,
        uint256 _amount,
        bool _eligible,
        bool _doner,
        Duration _duration
    ) external onlyModerators {
        uint256 duration = uint256(_duration);
        require(duration >= 0 && duration < 3, "Invalid emum value.");
        ZakatEligible storage zktEligible = eligible[_person];
        zktEligible.amount = _amount;
        zktEligible.eligible = _eligible;
        zktEligible.doner = _doner;
        zktEligible.duration = _duration;
    }

    function getEligible(address _doner)
        public
        view
        returns (ZakatEligible memory)
    {
        return eligible[_doner];
    }

    function removeEligible(address _person) external onlyModerators {
        delete eligible[_person];
    }
}

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
        assembly { size := extcodesize(account) }
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
        (bool success, ) = recipient.call{ value: amount }("");
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/ZakatRequest.sol

pragma solidity 0.6.6;



contract ZakatRequest is BasicAccessControl, ZakatBasic {
    using SafeERC20 for IERC20;

    event Approve(
        address _person,
        bool _doner,
        bool _approved,
        uint256 requestId
    ); //01420103057026

    mapping(address => ZakatApproval) public requests;
    address[] public requestIds;
    uint256 public MAX_REQUESTS = 10000;
    uint256 minRequestAmount = 1;
    uint256 maxRequestAmount = 1 * 10**22;

    function setMaxRequest(uint256 _maxRequest) external onlyOwner {
        MAX_REQUESTS = _maxRequest;
    }

    function setRequestAmount(
        uint256 _minRequestAmount,
        uint256 _maxRequestAmount
    ) external onlyOwner {
        require(
            _maxRequestAmount > _minRequestAmount && _minRequestAmount > 0,
            "Invalid requested amount settings"
        );
        minRequestAmount = _minRequestAmount;
        maxRequestAmount = _maxRequestAmount;
    }

    function getApprovalAddress(uint256 _requestId)
        public
        view
        returns (address)
    {
        require(
            _requestId >= 0 && _requestId < requestIds.length,
            "Invalid request id in get approve"
        );
        return requestIds[_requestId];
    }

    function getApprovalData(address _approvalAddress)
        public
        view
        returns (ZakatApproval memory)
    {
        require(_approvalAddress != address(0), "Approval address not valid");
        return requests[_approvalAddress];
    }

    function sendRequest(bool _doner, uint256 _amount) external {
        require(
            requestIds.length < MAX_REQUESTS,
            "Request limit exceeded try sometime later"
        );
        ZakatApproval storage zktApprove = requests[msgSender()];
        require(zktApprove.requestId == 0, "Request already initiated");
        requestIds.push(msgSender());
        zktApprove.requested = _amount;
        zktApprove.requestId = requestIds.length;
        zktApprove.doner = _doner;
    }

    function updateRequest(bool _doner, uint256 _amount) external {
        require(
            _amount > minRequestAmount && _amount < maxRequestAmount,
            "Invalid amount"
        );
        ZakatApproval storage zktApprove = requests[msgSender()];
        zktApprove.requested = _amount;
        zktApprove.doner = _doner;
    }

    function setApprove(uint256 _requestId, bool _approve)
        external
        onlyModerators
    {
        require(
            requestIds.length > 0 && _requestId < requestIds.length,
            "Invalid request Id"
        );
        address requester = requestIds[_requestId];

        ZakatApproval memory zktApprove = requests[requester];

        if (zktApprove.requestId != _requestId) {
            address anotherRequester = requestIds[zktApprove.requestId];
            requestIds[zktApprove.requestId] = requester;
            requestIds[_requestId] = anotherRequester;
            requester = anotherRequester;
            zktApprove = requests[requester];
        }
        require(
            zktApprove.requested > minRequestAmount &&
                zktApprove.requested < maxRequestAmount,
            "Request does not exists for this user"
        );
        delete requests[requester];
        requestIds[_requestId] = requestIds[requestIds.length - 1];
        requestIds.pop();
        emit Approve(
            requester,
            zktApprove.doner,
            _approve,
            zktApprove.requestId
        );
    }
}

// File: contracts/ZakatPayment.sol

pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;






contract ZakatPayment is BasicAccessControl, ZakatBasic {
    using SafeERC20 for IERC20;

    event Accepted(address _person, uint256 _amount, uint256 _time);
    event Donated(address _person, uint256 _amount, uint256 _time);

    mapping(address => mapping(uint256 => ZakatRecord)) records;
    mapping(address => uint256) recordsCount;

    IERC20 public zkt;
    address public zktOracleContract;
    address public zktRequestContract;
    address public verifyAddress;
    address public zktDataContract;
    uint16[] duration = [30, 182, 1];
    bytes constant SIG_PREFIX = "\x19Ethereum Signed Message:\n32";

    constructor(
        address _zkt,
        address _zktOracleContract,
        address _zktRequestContract,
        address _zktDataContract
    ) public {
        zkt = IERC20(_zkt);
        zktOracleContract = _zktOracleContract;
        zktDataContract = _zktDataContract;
        zktRequestContract = _zktRequestContract;
    }

    function setContract(
        address _zkt,
        address _zktOracleContract,
        address _zktRequestContract,
        address _zktDataContract
    ) external onlyModerators {
        zkt = IERC20(_zkt);
        zktOracleContract = _zktOracleContract;
        zktDataContract = _zktDataContract;
        zktRequestContract = _zktRequestContract;
    }

    function setApprovedEligiblity(
        uint256 _approvedId,
        bool _approve,
        Duration _duration
    ) external onlyModerators {
        ZakatData zktData = ZakatData(zktDataContract);
        ZakatRequest zktRequest = ZakatRequest(zktRequestContract);
        address approvalAddress = zktRequest.getApprovalAddress(
            _approvedId - 1
        );
        ZakatApproval memory approval = zktRequest.getApprovalData(
            approvalAddress
        );

        zktRequest.setApprove(approval.requestId - 1, _approve);

        zktData.setEligible(
            approvalAddress,
            approval.requested,
            _approve,
            approval.doner,
            _duration
        );
    }

    function depositeZKT(uint256 _amount) external isActive {
        address person = msgSender();

        ZakatData zktData = ZakatData(zktDataContract);
        ZakatEligible memory eligible = zktData.getEligible(person);
        require(
            eligible.eligible == true && eligible.doner == true,
            "Doner may not be registered"
        );

        uint256 recordCount = recordsCount[person];

        ZakatRecord memory zktRecords = records[person][recordCount];
        // if (zktRecords.recievedAt == 0) {
        uint256 lastDonated = zktRecords.recievedAt +
            duration[uint8(eligible.duration)];
        require(now > lastDonated, "Zakat already sent for duration");
        //        }

        ZakatOracle zktOracle = ZakatOracle(zktOracleContract);
        uint256 amount = zktOracle.getZktRatesFromEth(_amount);
        require(amount > 0 && amount < eligible.amount, "Invalid amount");

        ZakatRecord memory record = records[person][recordCount];
        record.amount = amount;
        record.recievedAt = now;
        record.doner = true;

        records[person][recordCount] = record;
        recordsCount[person]++;

        zkt.safeTransfer(address(this), amount);
        emit Accepted(person, amount, record.recievedAt);
    }

    function withdrawZKT(uint256 _amount) external isActive {
        address person = msgSender();
        ZakatData zktData = ZakatData(zktDataContract);
        ZakatEligible memory eligible = zktData.getEligible(person);
        require(
            eligible.eligible == true && eligible.doner == false,
            "Receiver may not be registered"
        );

        uint256 recordCount = recordsCount[person];

        ZakatRecord memory zktRecords = records[person][recordCount];

        require(zktRecords.recievedAt == 0, "Zakat already sent received");

        ZakatOracle zktOracle = ZakatOracle(zktOracleContract);
        uint256 amount = zktOracle.getZktRatesFromEth(_amount);
        require(amount > 0 && amount < eligible.amount, "Invalid amount");

        zkt.safeTransfer(person, amount);
        emit Donated(person, zktRecords.amount, zktRecords.recievedAt);
    }

    function depositeZKT_Matic() external payable isActive {
        address person = msgSender();

        ZakatData zktData = ZakatData(zktDataContract);
        ZakatEligible memory eligible = zktData.getEligible(person);
        require(
            eligible.eligible == true && eligible.doner == true,
            "Doner may not be registered"
        );

        uint256 recordCount = recordsCount[person];

        ZakatRecord memory zktRecords = records[person][recordCount];
        // if (zktRecords.recievedAt == 0) {
        uint256 lastDonated = zktRecords.recievedAt +
            duration[uint8(eligible.duration)];
        require(now > lastDonated, "Zakat already sent for duration");
        //        }

        uint256 amount = msg.value;
        require(amount > 0 && amount < eligible.amount, "Invalid amount");

        ZakatRecord memory record = records[person][recordCount];
        record.amount = amount;
        record.recievedAt = now;
        record.doner = true;

        records[person][recordCount] = record;
        recordsCount[person]++;

        emit Accepted(person, amount, record.recievedAt);
    }

    function withdrawZKT_Matic() external payable isActive {
        address person = msgSender();
        ZakatData zktData = ZakatData(zktDataContract);
        ZakatEligible memory eligible = zktData.getEligible(person);
        require(
            eligible.eligible == true && eligible.doner == false,
            "Receiver may not be registered"
        );

        uint256 recordCount = recordsCount[person];

        ZakatRecord memory zktRecords = records[person][recordCount];

        require(zktRecords.recievedAt == 0, "Zakat already sent received");
        uint256 amount = msg.value;
        require(amount > 0 && amount < eligible.amount, "Invalid amount");

        emit Donated(person, zktRecords.amount, zktRecords.recievedAt);
    }
}