/**
 *Submitted for verification at polygonscan.com on 2023-05-24
*/

//SPDX-License-Identifier: MIT

pragma solidity ^ 0.8.7;

interface IERC20 {

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
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
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender =_msgSender();
        _owner = msgSender;
        _previousOwner = msgSender;
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }
}

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

interface VRFV2WrapperInterface {
  /**
   * @return the request ID of the most recent VRF V2 request made by this wrapper. This should only
   * be relied option within the same transaction that the request was made.
   */
  function lastRequestId() external view returns (uint256);

  /**
   * @notice Calculates the price of a VRF request with the given callbackGasLimit at the current
   * @notice block.
   *
   * @dev This function relies on the transaction gas price which is not automatically set during
   * @dev simulation. To estimate the price at a specific gas price, use the estimatePrice function.
   *
   * @param _callbackGasLimit is the gas limit used to estimate the price.
   */
  function calculateRequestPrice(uint32 _callbackGasLimit) external view returns (uint256);

  /**
   * @notice Estimates the price of a VRF request with a specific gas limit and gas price.
   *
   * @dev This is a convenience function that can be called in simulation to better understand
   * @dev pricing.
   *
   * @param _callbackGasLimit is the gas limit used to estimate the price.
   * @param _requestGasPriceWei is the gas price in wei used for the estimation.
   */
  function estimateRequestPrice(uint32 _callbackGasLimit, uint256 _requestGasPriceWei) external view returns (uint256);
}

/** *******************************************************************************
 * @notice Interface for contracts using VRF randomness through the VRF V2 wrapper
 * ********************************************************************************
 * @dev PURPOSE
 *
 * @dev Create VRF V2 requests without the need for subscription management. Rather than creating
 * @dev and funding a VRF V2 subscription, a user can use this wrapper to create one off requests,
 * @dev paying up front rather than at fulfillment.
 *
 * @dev Since the price is determined using the gas price of the request transaction rather than
 * @dev the fulfillment transaction, the wrapper charges an additional premium on callback gas
 * @dev usage, in addition to some extra overhead costs associated with the VRFV2Wrapper contract.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFV2WrapperConsumerBase. The consumer must be funded
 * @dev with enough LINK to make the request, otherwise requests will revert. To request randomness,
 * @dev call the 'requestRandomness' function with the desired VRF parameters. This function handles
 * @dev paying for the request based on the current pricing.
 *
 * @dev Consumers must implement the fullfillRandomWords function, which will be called during
 * @dev fulfillment with the randomness result.
 */
abstract contract VRFV2WrapperConsumerBase {
  LinkTokenInterface internal immutable LINK;
  VRFV2WrapperInterface internal immutable VRF_V2_WRAPPER;

  /**
   * @param _link is the address of LinkToken
   * @param _vrfV2Wrapper is the address of the VRFV2Wrapper contract
   */
  constructor(address _link, address _vrfV2Wrapper) {
    LINK = LinkTokenInterface(_link);
    VRF_V2_WRAPPER = VRFV2WrapperInterface(_vrfV2Wrapper);
  }

  /**
   * @dev Requests randomness from the VRF V2 wrapper.
   *
   * @param _callbackGasLimit is the gas limit that should be used when calling the consumer's
   *        fulfillRandomWords function.
   * @param _requestConfirmations is the number of confirmations to wait before fulfilling the
   *        request. A higher number of confirmations increases security by reducing the likelihood
   *        that a chain re-org changes a published randomness outcome.
   * @param _numWords is the number of random words to request.
   *
   * @return requestId is the VRF V2 request ID of the newly created randomness request.
   */
  function requestRandomness(
    uint32 _callbackGasLimit,
    uint16 _requestConfirmations,
    uint32 _numWords
  ) internal returns (uint256 requestId) {
    LINK.transferAndCall(
      address(VRF_V2_WRAPPER),
      VRF_V2_WRAPPER.calculateRequestPrice(_callbackGasLimit),
      abi.encode(_callbackGasLimit, _requestConfirmations, _numWords)
    );
    return VRF_V2_WRAPPER.lastRequestId();
  }

  /**
   * @notice fulfillRandomWords handles the VRF V2 wrapper response. The consuming contract must
   * @notice implement it.
   *
   * @param _requestId is the VRF V2 request ID.
   * @param _randomWords is the randomness result.
   */
  function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal virtual;

  function rawFulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) external {
    require(msg.sender == address(VRF_V2_WRAPPER), "only VRF V2 wrapper can fulfill");
    fulfillRandomWords(_requestId, _randomWords);
  }
}


contract LotteryContract is VRFV2WrapperConsumerBase, Context, Ownable {
    using SafeMath for uint256;
    using SafeMath for uint16;
    using SafeMath for uint8;

    uint256 public entryFee = 180000000;
    uint256 public projectFee = 5; // project fee percent
    address public feeReceiver;
    uint256 public round; // lottery round
    uint256 public lastRound; // lottery last round
    uint256[] public allRounds;
    uint256 public winnerPercent = 1;
    mapping(uint256 => uint256) public numberOfWinnersInRound;
    mapping(uint256 => address[]) public allRoundWinners;

    //enum 
    enum EthMode {ON, OFF} // entry mode for lottery is eth by default if set off then entry mode becomes token

    EthMode public entryMode = EthMode.OFF; // default payment type mode

    IERC20 public token; // address should not be 0 while in token payment mode

    // events
    event Entered(uint256 _round, string ticket, address indexed wallet);
    event RoundStarted(uint256 _round, uint256 _lastRound, uint256 _entryFee);


    // structs
    struct Round {
        uint256 round;
        bool started;
        bool finished;
        address[] winners;
        uint256 winningAmountEach;
    }

    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(
        uint256 requestId,
        uint256[] randomWords,
        uint256 payment
    );

    struct RequestStatus {
        uint256 paid; // amount paid in link
        bool fulfilled; // whether the request has been successfully fulfilled
        uint256[] randomWords;
        address[] winners;
    }

    mapping(uint256 => RequestStatus) public s_requests;

    mapping(uint256 => Round) public roundStatus;

    mapping(uint256 => string[]) public ticketsOfRound;
    mapping(uint256 => string[]) ticketsToProcess;
    mapping(string => mapping(uint256 => bool)) public ticketEntry; // check if ticket is already used for this round ticket -> round -> bool
    
    // past requests Id.
    uint256[] public requestIds;
    uint256 public lastRequestId;
    mapping(uint256 => uint256) public requestIdOfRound;
    mapping(uint256 => mapping(string => address)) public ownerOfTicket;
    mapping(address => mapping(uint256 => string[])) ticketsOfOwner;
    mapping(uint256 => mapping(string => uint256)) ticketIndex;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 callbackGasLimit = 5000000;
    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    // Address LINK
    address linkAddress = 0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06;
    // address WRAPPER
    address wrapperAddress = 0x699d428ee890d55D56d5FC6e26290f3247A762bd;


    modifier onlyRoundValid(uint256 r) {
        Round memory _round = roundStatus[r];
        require(_round.started,"round has not been started yet");
        require(!_round.finished,"round has already finished");
        require(requestIdOfRound[r] == 0, "already requested for randomness");
        _;
    }

    modifier onlyRoundComplete(uint256 r) {
        Round memory _round = roundStatus[r];
        if(round != 0) {
            require(_round.started, "round has not started yet.");
            require(_round.finished, "round has not finished yet.");
        }
        _;
    }

    constructor(
        address _tokenAddress,
        address _feeReceiver
    ) VRFV2WrapperConsumerBase(linkAddress,wrapperAddress) {
        feeReceiver = _feeReceiver;
        token = IERC20(_tokenAddress);
    }

    receive() external payable {}

    function enter (
        string[] memory tickets,
        uint256 _round
    ) external payable onlyRoundValid(_round) {
        uint256 tAmountRequired = tickets.length.mul(entryFee);
        _preValidateEntry(tAmountRequired);
        _takeFee(tAmountRequired);
        for(uint256 i; i < tickets.length; i++) 
        {
            require(!ticketEntry[tickets[i]][_round], "ticket has already been sold");
            ticketEntry[tickets[i]][_round] = true;
            ticketIndex[round][tickets[i]] = ticketsOfRound[round].length;
            ticketsOfRound[round].push(tickets[i]);
            ticketsOfOwner[_msgSender()][round].push(tickets[i]);
            ownerOfTicket[_round][tickets[i]] = _msgSender();
            ticketsToProcess[round].push(tickets[i]);
            emit Entered(_round, tickets[i], _msgSender());

        }    
    }

    function _preValidateEntry(
        uint256 _amount
    ) internal {
        if(entryMode == EthMode.ON) {
            require(msg.value == _amount, "eth amount is less than total required entry fee!");
        }

        if(entryMode == EthMode.OFF) {
            token.transferFrom(_msgSender(), address(this), _amount);
        }

        this;
    }

    function requestRandomWords() external onlyOwner returns(uint256 requestId)
    {
        uint256 numberOfWinners = ticketsToProcess[round].length.mul(winnerPercent).div(10**2);
        
        if(numberOfWinners == 0) {
            numberOfWinners = ticketsToProcess[round].length;
        }
        
        numberOfWinnersInRound[round] = numberOfWinners;

        requestId = requestRandomness(
            callbackGasLimit,
            requestConfirmations,
            uint32(numberOfWinners)
        );




        s_requests[requestId] = RequestStatus({
            paid: VRF_V2_WRAPPER.calculateRequestPrice(callbackGasLimit),
            randomWords: new uint256[](numberOfWinners),
            fulfilled: false,
            winners: new address[](numberOfWinners)
        });

        requestIds.push(requestId);
        lastRequestId = requestId;
        requestIdOfRound[round] = requestId;
        emit RequestSent(requestId, uint32(numberOfWinners));
        return requestId;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].paid > 0, "request not found");
        
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;

        for(uint256 i; i < numberOfWinnersInRound[round]; i++) {
            address winner = generateWinners(_randomWords[i]);
            _updateTicketsToProcess(winner);
            allRoundWinners[round].push(winner);
        }

        _distributeWinning(allRoundWinners[round], round);

        _startNextRound(entryFee);

        emit RequestFulfilled(
            _requestId,
            _randomWords,
            s_requests[_requestId].paid
        );
    }

    /**
     * @dev start the next lottery round incase not started automatically on fullfiling randomness 
    */
    function startNextRound(
        uint256 _entryFee
    ) external onlyOwner onlyRoundComplete(round){
        _startNextRound(_entryFee);
    }

    function _startNextRound(
        uint256 _entryFee
    ) internal {
        uint256 nextRound = round+1;
        Round memory _newRound = roundStatus[nextRound];
        _newRound.round = nextRound;
        _newRound.started = true;
        roundStatus[nextRound] = _newRound;
        lastRound = round;
        round = nextRound;
        entryFee = _entryFee;
        allRounds.push(round);
        emit RoundStarted(round, lastRound, _entryFee);
    }

    /**
     * @dev set payment mode to ETH type
    */
    function setEntryModeETH() external onlyOwner{
        entryMode = EthMode.ON;
    }

    /**
     * @dev set the entry mode to token type, token address shold not be 0 address 
     */
    function setEntryModeToken() external onlyOwner{
        require(address(token) != address(0), "entry mode switch with 0 token address");
        entryMode = EthMode.OFF;
    }

    event UpdatedTokenAddress(address indexed _tokenAddress);
    /**
     * @dev update token address needed to change payment type from ETH to TOKEN
    */
    function updateTokenAddress(
        address _tokenAddress
    ) external onlyOwner{
        token = IERC20(_tokenAddress);
        emit UpdatedTokenAddress(_tokenAddress);
    }


    event Distributed(address[] winners, uint256 _round);

    function _distributeWinning(
        address[] memory winners,
        uint256 _r
    ) internal {
        Round memory _round = roundStatus[_r];
        uint256 _amount;
        if(entryMode == EthMode.ON){
            _amount = address(this).balance;
        }
        if(entryMode == EthMode.OFF) {
            _amount = token.balanceOf(address(this));
        }
        
        uint256 distAmount = _amount.div(winners.length);

        if(entryMode == EthMode.ON && distAmount != 0){
            for(uint256 i; i < winners.length; i++) {
                payable(winners[i]).transfer(distAmount);
            } 
        }
        if(entryMode == EthMode.OFF && distAmount != 0) {
            for(uint256 i; i < winners.length; i++) {
                token.transfer(winners[i], distAmount);
            }
        }
        
        _round.finished = true;
        _round.started = true;
        _round.winners = winners;
        _round.winningAmountEach = distAmount;
        roundStatus[_r] = _round;
        emit Distributed(winners, _r);
    }

    function generateWinners(
        uint256 _randomNum
    ) public view returns(address) {
        uint256 index = _randomNum % ticketsToProcess[round].length;
        string memory _ticket = ticketsToProcess[round][index];
        address _winner = ownerOfTicket[round][_ticket];
        return _winner;
    }

    function _takeFee(
        uint256 _tAmount
    ) internal {
        uint256 _feeAmount = _tAmount.mul(projectFee).div(10**2);
        if(_feeAmount != 0 && entryMode == EthMode.ON){
            (bool success, ) = payable(feeReceiver).call{value: _feeAmount}("");
            require(success, "unable to send fee");
        }

        if(_feeAmount != 0 && entryMode == EthMode.OFF) {
            require(token.transfer(feeReceiver, _feeAmount), "unable to send fee");
        }
    }

    function _updateTicketsToProcess(
        address _winner
    ) internal {
        string[] memory _ticketsOfOwner = ticketsOfOwner[_winner][round];
        for(uint256 i; i < _ticketsOfOwner.length; i++) {
            uint256 _index = ticketIndex[round][_ticketsOfOwner[i]];
            uint256 _IOE = ticketsToProcess[round].length - 1; //index at the end of array
            string memory _TOE = ticketsToProcess[round][_IOE]; // ticket at the end of array
            ticketsToProcess[round][_index] = _TOE;
            ticketIndex[round][_TOE] = _index;
            ticketsToProcess[round].pop();
        }

    } 


    function listTickets(
        uint256 _round
    ) external view returns(string[] memory){
        return ticketsOfRound[_round];
    }

    function listTicketsOfOwner(
        address _owner,
        uint256 _round
    )external view returns(string[] memory){
        return ticketsOfOwner[_owner][_round];
    }

    event UpdatedEntryFee(uint256 _entryFee);

    /**
     * @dev update round entry fee
    */
    function updateEntryFee(
        uint256 _entryFee
    ) external onlyOwner {
        entryFee = _entryFee;
        emit UpdatedEntryFee(_entryFee);
    }

    event UpdatedProjectFee(uint256 _projectFee);
    
    /**
     *@dev update project fee in percentage
    */
    function updateProjectFee(
        uint256 _projectFee
    ) external onlyOwner{
        projectFee = _projectFee;
        emit UpdatedProjectFee(_projectFee);
    }

    event UpdatedFeeReceiver(address indexed _feeReceiver);

    /**
     * @dev update project fee receiver address
    */
    function updateFeeReceiver(
        address _feeReceiver
    ) external onlyOwner {
        feeReceiver = _feeReceiver;
        emit UpdatedFeeReceiver(_feeReceiver);
    }

    event UpdatedLinkDetails(address _link, address _wrapper, uint32 _gasLimit);

    /**
     * @dev update link details
    */
    function updateLinkDetails(
        address _link, 
        address _wrapper, 
        uint32 _gasLimit
    ) external onlyOwner {
        linkAddress = _link;
        wrapperAddress = _wrapper;
        callbackGasLimit = _gasLimit;
        emit UpdatedLinkDetails(_link, _wrapper, _gasLimit);
    }

    event UpdateWinningPercent(uint256 _newWinningPercent);
    function updateWinningPercent(
        uint256 _newWinningPercent
    ) external onlyOwner {
        winnerPercent = _newWinningPercent;
        emit UpdateWinningPercent(_newWinningPercent);
    }

}