/**
 *Submitted for verification at polygonscan.com on 2022-06-07
*/

/**
 *Submitted for verification at polygonscan.com on 2022-06-02
*/

pragma solidity 0.8.6;
pragma experimental ABIEncoderV2;


// SPDX-License-Identifier: MIT
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// solhint-disable-next-line compiler-version
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

interface ITicket {
    //-------------------------------------------------------------------------
    // VIEW FUNCTIONS
    //-------------------------------------------------------------------------

    function getTotalSupply() external view returns (uint256);

    function getNumberOfTickets(uint256 _lotteryID) external view returns (uint256);

    function getTicketNumbers(uint256 _ticketID) external view returns (uint256);

    function getOwnerOfTicket(uint256 _ticketID) external view returns (address);

    function getTicketClaimStatus(uint256 _ticketID) external view returns (bool);

    //-------------------------------------------------------------------------
    // STATE MODIFYING FUNCTIONS
    //-------------------------------------------------------------------------

    function batchMint(
        address _to,
        uint256 _lottoID,
        uint8 _numberOfTickets
    ) external returns (uint256[] memory);

    function claimTicket(uint256 _ticketId, uint256 _lotteryId) external returns (bool);

    function countMatch(
        uint256 _lotteryId,
        uint16[] calldata _winningNumbers
    ) external view returns (uint256[] memory results);
}

interface IBasisAsset {
    function burn(uint256 amount) external;

    function burnFrom(address from, uint256 amount) external;
}


contract Lottery is Initializable {
    // governance
    address public operator;

    // using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    // Represents the status of the lottery
    enum Status {
        NotStarted, // The lottery has not started yet
        Open, // The lottery is open for ticket purchases
        Closed, // The lottery is no longer open for ticket purchases
        Completed // The numbers drawn
    }

    // All the needed info around a lottery
    struct LottoInfo {
        uint256 lotteryID; // ID for lotto
        Status lotteryStatus; // Status for lotto
        uint256 prizePool; // The amount of DARK for prize money
        uint256 startingTimestamp; // Block timestamp for star of lotto
        uint256 closingTimestamp; // Block timestamp for end of entries
        uint256 winningNumber; // The winning numbers
        uint256 totalTickets; // the winners of each prize
    }

    // State variables
    // Instance of DARK token (collateral currency for lotto)
    IERC20 public dark;
    // Storing of the ticket
    ITicket public ticket;

    // Counter for lottery IDs
    uint256 private lotteryIdCounter;

    // precision for all distribution
    uint256 public constant PRECISION = 1e6;
    uint256 public unclaimedPrize;
    address public controller;
    uint256 public costPerTicket; // Cost per ticket in $DARK

    // Max ticket can buy
    uint256 public maxTicketLimit;

    // Lottery ID's to info
    mapping(uint256 => LottoInfo) internal allLotteries;
    uint256 public defaultDuration = 8 hours;

    bool public upgraded = false;

    uint256 public currentSeed = 0;

    // Tax fee
    uint256 public taxFee = 100000; // default 10%
    uint256 public prizeDistributionJackPot = 900000; // default 90%
    uint256 public totalBurn = 0;

    //-------------------------------------------------------------------------
    // EVENTS
    //-------------------------------------------------------------------------

    event NewBatchMint(address indexed minter, uint256[] ticketIDs, uint256 pricePaid);

    event RequestNumbers(uint256 lotteryId, bytes32 requestId);

    event LotteryOpened(uint256 lotteryId, uint256 ticketSupply);

    event LotteryClosed(uint256 lotteryId, uint256 ticketSupply);

    event WinnersDrawn(uint256[] numbers);

    event GovernanceWithdraw(address indexed user, address indexed token, uint256 amount, address indexed to);

    //-------------------------------------------------------------------------
    // MODIFIERS
    //-------------------------------------------------------------------------
    modifier onlyOperator() {
        require(operator == msg.sender, "caller is not the operator");
        _;
    }

    modifier onlyController() {
        require(msg.sender == controller, "Only controller");
        _;
    }

    modifier notContract() {
        require(!address(msg.sender).isContract(), "contract not allowed");
        // solhint-disable-next-line avoid-tx-origin
        require(msg.sender == tx.origin, "proxy contract not allowed");
        _;
    }

    modifier notUpgraded() {
        require(upgraded == false, "This contract was upgraded");
        _;
    }

    function initialize(
        address _dark,
        address _ticket,
        address _operator,
        address _controller,
        uint256 _taxFee,
        uint256 _prizeDistributionJackPot
    ) external initializer {
        require(
            _ticket != address(0) &&
            _dark != address(0),
            "Contracts cannot be 0 address"
        );
        dark = IERC20(_dark);
        ticket = ITicket(_ticket);
        taxFee = _taxFee;
        prizeDistributionJackPot = _prizeDistributionJackPot;
        controller = _controller;
        operator = _operator;
        maxTicketLimit = 100;
    }

    //-------------------------------------------------------------------------
    // VIEW FUNCTIONS
    //-------------------------------------------------------------------------

    function costToBuyTickets(uint256 numberOfTickets) external view returns (uint256 totalCost) {
        // solidity 0.8 auto handle overflow
        uint256 pricePerTicket = costPerTicket;
        totalCost = pricePerTicket * numberOfTickets;
    }

    function getBasicLottoInfo(uint256 lotteryId) external view returns (LottoInfo memory) {
        return (allLotteries[lotteryId]);
    }

    function getCurrentLotto() external view returns (LottoInfo memory) {
        require(lotteryIdCounter > 0, "no lottery created");
        return allLotteries[lotteryIdCounter];
    }

    function getCurrentTotalPrize() public view returns (uint256 totalPrize) {
        totalPrize = dark.balanceOf(address(this)) - unclaimedPrize;
    }

    function _genNextSeed(uint256 _newHash) internal view returns (uint256) {
        return currentSeed ^ _newHash ^ uint256(blockhash(block.number - 1));
    }

    //-------------------------------------------------------------------------
    // STATE MODIFYING FUNCTIONS
    //-------------------------------------------------------------------------

    function autoStartLotto() external onlyController returns (uint256) {
        uint256 startTime;
        uint256 closingTime;
        uint256 currentTime = block.timestamp;
        if (lotteryIdCounter > 0) {
            startTime = allLotteries[lotteryIdCounter].closingTimestamp;
            // check if last closing time is too far ago
            startTime = startTime + defaultDuration < currentTime ? currentTime : startTime;
        } else {
            startTime = currentTime;
        }

        closingTime = startTime + defaultDuration;
        return _createNewLotto(startTime, closingTime);
    }

    //-------------------------------------------------------------------------
    // Restricted Access Functions (onlyOperator)

    /**
     * manually start by admin, by pass auto duration
     */
    function manualStartLotto(uint256 _startingTime, uint256 _closingTime) external onlyController returns (uint256) {
        return _createNewLotto(_startingTime, _closingTime);
    }


    function setController(address _controller) external onlyOperator {
        require(_controller != address(0), "Contracts cannot be 0 address");
        controller = _controller;
    }

    function transferOperator(address newOperator) external onlyOperator {
        require(newOperator != address(0), "Contracts cannot be 0 address");
        operator = newOperator;
    }

    function setTicket(address _ticket) external onlyOperator {
        require(_ticket != address(0), "Contracts cannot be 0 address");
        ticket = ITicket(_ticket);
    }

    function setFee(uint256 _taxFee, uint256 _prizeDistributionJackPot) external onlyOperator {
        require(_taxFee + _prizeDistributionJackPot  == 1000000, " < 100%");
        taxFee = _taxFee;
        prizeDistributionJackPot = _prizeDistributionJackPot;
    }

    function setMaxTicketLimit(uint256 _maxTicketLimit) external onlyOperator {
        require(_maxTicketLimit > 0, ">0");
        maxTicketLimit = _maxTicketLimit;
    }

    function upgradeNewLottoContract(address newLottoContract) external onlyOperator {
        require(
            allLotteries[lotteryIdCounter].lotteryStatus == Status.Completed,
            "Lottery State must be completed into to upgrade"
        );
        require(newLottoContract != address(0), "Invalid contract");
        uint256 _movableAmount = getCurrentTotalPrize();
        upgraded = true;
        dark.safeTransfer(newLottoContract, _movableAmount);
    }

    function setCostPerTicket(uint256 _costPerTicket) external onlyOperator {
        require(_costPerTicket != 0, "Cost cannot be 0");
        costPerTicket = _costPerTicket;
    }

    function updateDefaultDuration(uint256 _duration) external onlyOperator {
        require(_duration > 0, "Duration cannot be 0");
        defaultDuration = _duration;
    }

    function numbersDrawn(
        uint256 lotteryId,
        uint256 _userRandomHash
    ) external onlyController() notUpgraded {
        LottoInfo storage _currLotto = allLotteries[lotteryId];
        if (_currLotto.lotteryStatus == Status.NotStarted) {
            if (_currLotto.startingTimestamp <= block.timestamp) {
                _currLotto.lotteryStatus = Status.Open;
            }
        }        // Checks that the lottery is past the closing block
        require(_currLotto.closingTimestamp <= block.timestamp, "Cannot set winning numbers during lottery");
        // Checks lottery numbers have not already been drawn
        require(_currLotto.lotteryStatus == Status.Open, "Lottery State incorrect for draw");
        // Sets lottery status to closed
        _currLotto.lotteryStatus = Status.Closed;
        // Sets prize pool
        _currLotto.prizePool = getCurrentTotalPrize();
        require(_currLotto.lotteryStatus == Status.Closed, "Draw numbers first");
        currentSeed = _genNextSeed(_userRandomHash);
        uint256 _randomNumber = currentSeed;
        if (_currLotto.totalTickets > 0) {
        _currLotto.winningNumber = _randomNumber % _currLotto.totalTickets + 1;
        } else  _currLotto.winningNumber = 0;
        _currLotto.lotteryStatus = Status.Completed;
        uint256 _totalPrize = (getCurrentTotalPrize() * prizeDistributionJackPot) / PRECISION;

        _addUnclaimedPrize(_totalPrize);

        emit LotteryClosed(lotteryId, ticket.getTotalSupply());
    }

    //-------------------------------------------------------------------------
    // General Access Functions

    function batchBuyLottoTicket(
        uint256 _lotteryId,
        uint8 _numberOfTickets,
        uint256 _userRandomHash
    ) external notContract() notUpgraded {
         // Ensuring the lottery is within a valid time
        uint256 currentTime = block.timestamp;
        LottoInfo storage _currLotto = allLotteries[_lotteryId];
        require(currentTime >= _currLotto.startingTimestamp, "Invalid time for mint:start");
        require(currentTime < _currLotto.closingTimestamp, "Invalid time for mint:end");

        if (_currLotto.lotteryStatus == Status.NotStarted) {
            if (_currLotto.startingTimestamp <= block.timestamp) {
                _currLotto.lotteryStatus = Status.Open;
            }
        }

        require(_currLotto.lotteryStatus == Status.Open, "Lottery not in state for mint");

        uint256 totalCost = this.costToBuyTickets(_numberOfTickets);

        // Batch mints the user their tickets
        uint256[] memory ticketIds =
        ticket.batchMint(msg.sender, _lotteryId, _numberOfTickets);

        _currLotto.totalTickets = _currLotto.totalTickets + _numberOfTickets;

        // Emitting event with all information
        emit NewBatchMint(msg.sender, ticketIds, totalCost);

        // Transfers the required dark to this contract
        dark.safeTransferFrom(msg.sender, address(this), totalCost);

        currentSeed = _genNextSeed(_userRandomHash);
    }

    function claimReward(uint256 _lotteryId, uint256 _tokenId) external notContract() {
        // Checking the lottery is in a valid time for claiming
        require(allLotteries[_lotteryId].closingTimestamp <= block.timestamp, "Wait till end to claim");
        // Checks the lottery winning numbers are available
        require(allLotteries[_lotteryId].lotteryStatus == Status.Completed, "Winning Numbers not chosen yet");
        require(ticket.getOwnerOfTicket(_tokenId) == msg.sender, "Only the owner can claim");
        // Sets the claim of the ticket to true (if claimed, will revert)
        require(ticket.claimTicket(_tokenId, _lotteryId), "Numbers for ticket invalid");
        // Getting the prize amount for those matching tickets
        if (ticket.getTicketNumbers(_tokenId) ==  allLotteries[_lotteryId].winningNumber) {
            uint256 prizeAmount = (allLotteries[_lotteryId].prizePool * prizeDistributionJackPot) / PRECISION;
            _claimPrize(msg.sender, prizeAmount);

        }
    }


    //-------------------------------------------------------------------------
    // INTERNAL FUNCTIONS
    //-------------------------------------------------------------------------
    /**
     * @param   _startingTimestamp The block timestamp for the beginning of the
     *          lottery.
     * @param   _closingTimestamp The block timestamp after which no more tickets
     *          will be sold for the lottery. Note that this timestamp MUST
     *          be after the starting block timestamp.
     */
    function _createNewLotto(uint256 _startingTimestamp, uint256 _closingTimestamp)
    internal
    notUpgraded
    returns (uint256 lotteryId)
    {
        require(_startingTimestamp != 0 && _startingTimestamp < _closingTimestamp, "Timestamps for lottery invalid");
        require(
            lotteryIdCounter == 0 || allLotteries[lotteryIdCounter].lotteryStatus == Status.Completed,
            "current lottery is not completed"
        );
        // Incrementing lottery ID
        lotteryIdCounter = lotteryIdCounter + 1;
        lotteryId = lotteryIdCounter;
        Status lotteryStatus;
        if (_startingTimestamp > block.timestamp) {
            lotteryStatus = Status.NotStarted;
        } else {
            lotteryStatus = Status.Open;
        }

        // Saving data in struct
        LottoInfo memory newLottery =
        LottoInfo(
            lotteryId,
            lotteryStatus,
            0,
            _startingTimestamp,
            _closingTimestamp,
            0,
            0
        );
        allLotteries[lotteryId] = newLottery;

        // Emitting important information around new lottery.
        emit LotteryOpened(lotteryId, ticket.getTotalSupply());
    }


    function _claimPrize(address _winner, uint256 _amount) internal {
        unclaimedPrize = unclaimedPrize - _amount;
        dark.safeTransfer(_winner, _amount);
    }

    function _addUnclaimedPrize(uint256 amount) internal {
        unclaimedPrize = unclaimedPrize + amount;
    }

    function governanceRecoverUnsupported(
        address _token,
        uint256 _amount,
        address _to
    ) external onlyOperator {
        IERC20(_token).safeTransfer(_to, _amount);
        emit GovernanceWithdraw(msg.sender, _token, _amount, _to);
    }
}