/**
 *Submitted for verification at polygonscan.com on 2022-04-05
*/

/**
 *Submitted for verification at polygonscan.com on 2022-02-21
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
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

pragma solidity ^0.8.0;


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

pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

interface IERC721 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

pragma solidity ^0.8.0;
pragma abicoder v2;

/**
 * @title PancakePredictionV2
 */
contract DegenZonePredictionV2 is  ReentrancyGuard {
    using SafeERC20 for IERC20;

    AggregatorV3Interface public oracle= AggregatorV3Interface(0x0715A7794a1dc8e42615F059dD6e406A6594651A);

    IERC721 public y = IERC721(0x955a1F50eaE250F1341dD08b3D4E0C89861332Ec);  //define NFT token

    bool public genesisLockOnce = false;
    bool public genesisStartOnce = false;

    address public adminAddress; // address of the admin
    address public operatorAddress; // address of the operator

    uint80 public totalRounds = 0;

    uint256 public tierPercentage; // percentage of each tier

    uint256 public bufferSeconds; // number of seconds for valid execution of a prediction round
    uint256 public intervalSeconds; // interval in seconds between two prediction rounds

    uint256 public minBetAmount; // minimum betting amount (denominated in wei)
    uint256 public treasuryFee = 0; // treasury rate (e.g. 20 = 2%, 10 = 1%)
    uint256 public NFTfee = 10; // NFTfee rate (e.g. 20 = 2%, 10 = 1%)

    uint256 public treasuryAmount; // treasury amount that was not claimed
    uint256 public NFTbear;
    uint256 public NFTbull;
    int256 public borderAmount = 20;
    uint256 public tokenId = 0;

    uint256 public roundId = 0;

    address public owner = address(0x0);
    address public admin = address(0x0);

    uint256 public currentEpoch; // current epoch for prediction round

    uint256 public oracleLatestRoundId; // converted from uint80 (Chainlink)

    uint256 public constant MAX_TREASURY_FEE = 100; // 10%

    mapping(uint256 => mapping(address => BetInfo)) public ledger;
    mapping(uint256 => Round) public rounds;
    mapping(address => uint256[]) public userRounds;
    mapping (address=>uint256) public totalWon;

    enum Position {
        Bull,
        Bear,
        BullZone1,
        BullZone2,
        BullDegenZone,
        BearZone1,
        BearZone2,
        BearDegenZone
    }

    struct Round {
        uint256 startTimestamp;
        uint256 lockTimestamp;
        uint256 closeTimestamp;
        int256 lockPrice;
        int256 closePrice;
        AmountInfo AmountInfo;
        int256 borderAmount;
    }

    struct AmountInfo{
        uint256 totalAmount;
        uint256 bullAmount;
        uint256 bearAmount;
        uint256 bullZone1Amount;
        uint256 bullZone2Amount;
        uint256 bullDegenZoneAmount;
        uint256 bearZone1Amount;
        uint256 bearZone2Amount;
        uint256 bearDegenZoneAmount;
    }

    struct BetInfo {
        Position position;
        uint256 amount;
        uint8 betType;
        bool claimed; // default false
    }

    event BetBear(address indexed sender, uint256 indexed epoch, uint256 amount);
    event BetBull(address indexed sender, uint256 indexed epoch, uint256 amount);
    event Claim(address indexed sender, uint256 indexed epoch, uint256 amount);
    event EndRound(uint256 indexed epoch, uint256 indexed roundId, int256 price);
    event LockRound(uint256 indexed epoch, uint256 indexed roundId, int256 price);

    event NewAdminAddress(address admin);
    event NewBufferAndIntervalSeconds(uint256 bufferSeconds, uint256 intervalSeconds);
    event NewMinBetAmount(uint256 indexed epoch, uint256 minBetAmount);
    event NewTreasuryFee(uint256 indexed epoch, uint256 treasuryFee);
    event NewOperatorAddress(address operator);
    event NewOracle(address oracle);
    event NewOracleUpdateAllowance(uint256 oracleUpdateAllowance);

    event Pause(uint256 indexed epoch);
    event RewardsCalculated(
        uint256 indexed epoch,
        uint256 rewardBaseCalAmount,
        uint256 rewardAmount,
        uint256 treasuryAmount
    );

    event StartRound(uint256 indexed epoch);
    event TokenRecovery(address indexed token, uint256 amount);
    event TreasuryClaim(uint256 amount);
    event Unpause(uint256 indexed epoch);

    constructor(uint256 interval){
        intervalSeconds = interval;
        owner = msg.sender;
        admin = msg.sender;
    }

    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    function checkOraclePrice() public view returns (int256)
    {
        (, int256 price,, ,) = oracle.latestRoundData();

        return price;
    }
    
    function genesisStart() public{
        Round memory round = rounds[roundId];
        round.startTimestamp = block.timestamp;
        rounds[roundId] = round;
    }

    function setAdmin(address _admin) public{
        require (msg.sender == owner,"Not authorized.");
        admin = _admin;
    }

    function checkPrice() public view returns(int256){
        int256 price = checkOraclePrice();

        return price;
    }


    function executeRound(int256 price) public {
        require( rounds[roundId].startTimestamp + intervalSeconds <= block.timestamp, "Appropriate interval hasn't passed.");
        require( msg.sender == admin,"Not authorized.");
        //int256 price = checkOraclePrice();

        rounds[roundId].lockTimestamp = block.timestamp;
        rounds[roundId].lockPrice = price;

        if (roundId>0){
            rounds[roundId-1].closeTimestamp = block.timestamp;
            rounds[roundId-1].closePrice = price;
        }

        rounds[roundId+1].startTimestamp = block.timestamp;
        rounds[roundId+1].borderAmount = borderAmount;

        roundId = roundId + 1;
    }

    function isBettable() public view returns(bool){
        if (rounds[roundId].startTimestamp != 0  && block.timestamp > rounds[roundId].startTimestamp )
            return true;
        return false;
    }

    function betBull() public payable nonReentrant notContract{
        uint256 epoch = roundId;
        require (isBettable() == true, "Round not bettable");
        require(msg.value > minBetAmount,"Bet Amount too low");
        require(ledger[epoch][msg.sender].amount == 0, "You already placed a bet this round");

        uint256 betAmount = msg.value;
        rounds[epoch].AmountInfo.totalAmount += betAmount;
        rounds[epoch].AmountInfo.bullAmount += betAmount;

        ledger[epoch][msg.sender].amount = betAmount;
        ledger[epoch][msg.sender].position = Position.Bull;
        ledger[epoch][msg.sender].betType = 1;

        userRounds[msg.sender].push(epoch);
    }

    function betBear() public payable nonReentrant notContract{
        uint256 epoch = roundId;
        require (isBettable() == true, "Round not bettable");
        require(msg.value > minBetAmount,"Bet Amount too low");
        require(ledger[epoch][msg.sender].amount == 0, "You already placed a bet this round");

        uint256 betAmount = msg.value;
        rounds[epoch].AmountInfo.totalAmount += betAmount;
        rounds[epoch].AmountInfo.bearAmount += betAmount;

        ledger[epoch][msg.sender].amount = betAmount;
        ledger[epoch][msg.sender].position = Position.Bear;
        ledger[epoch][msg.sender].betType = 1;
        userRounds[msg.sender].push(epoch);
    }

    function betZoneBull(uint8 betType) public payable nonReentrant notContract {
        uint256 epoch = roundId;
        require (isBettable() == true, "Round not bettable");
        require(msg.value > minBetAmount,"Bet Amount too low");
        require(ledger[epoch][msg.sender].amount == 0, "You already placed a bet this round");
        uint256 betAmount = msg.value;
        rounds[epoch].AmountInfo.totalAmount += betAmount;
        ledger[epoch][msg.sender].amount = betAmount;
        ledger[epoch][msg.sender].betType = 2;

        //zone 1
        if (betType == 1){
            ledger[epoch][msg.sender].position = Position.BullZone1;
            rounds[epoch].AmountInfo.bullZone1Amount += betAmount;
        }
        //zone2
        if (betType ==2){
            ledger[epoch][msg.sender].position = Position.BullZone2;
            rounds[epoch].AmountInfo.bullZone2Amount += betAmount;
        }
        //degenZone
        if (betType == 3){
            ledger[epoch][msg.sender].position = Position.BullDegenZone;
            rounds[epoch].AmountInfo.bullDegenZoneAmount += betAmount;
        }
    }

    function betZoneBear(uint8 betType) public payable nonReentrant notContract {
        uint256 epoch = roundId;
        require (isBettable() == true, "Round not bettable");
        require(msg.value > minBetAmount,"Bet Amount too low");
        require(ledger[epoch][msg.sender].amount == 0, "You already placed a bet this round");
        uint256 betAmount = msg.value;
        rounds[epoch].AmountInfo.totalAmount += betAmount;
        ledger[epoch][msg.sender].amount = betAmount;
        ledger[epoch][msg.sender].betType = 2;

        //zone 1
        if (betType == 1){
            ledger[epoch][msg.sender].position = Position.BearZone1;
            rounds[epoch].AmountInfo.bearZone1Amount += betAmount;
        }
        //zone2
        if (betType ==2){
            ledger[epoch][msg.sender].position = Position.BearZone2;
            rounds[epoch].AmountInfo.bearZone2Amount += betAmount;
        }
        //degenZone
        if (betType == 3){
            ledger[epoch][msg.sender].position = Position.BearDegenZone;
            rounds[epoch].AmountInfo.bearDegenZoneAmount += betAmount;
        }
    }

    function claimNFTBull() public nonReentrant notContract{
        require(y.ownerOf(tokenId) == msg.sender,"Not allowed to claim");
        _safeTransferMatic(msg.sender, NFTbull);
        NFTbull = 0;
    }

    function claimNFTBear() public nonReentrant notContract{
        require(y.ownerOf(tokenId + 1) == msg.sender,"Not allowed to claim");
        _safeTransferMatic(msg.sender, NFTbear);
        NFTbear = 0;
    }


    function claim(uint256 epoch) public nonReentrant notContract{
        require(ledger[epoch][msg.sender].amount>0,"Invalid bet amount.");
        require(ledger[epoch][msg.sender].claimed == false,"You already claimed your reward.");

        uint256 reward;
        uint256 treasuryReward;
        uint256 NFTreward;  

        if (ledger[epoch][msg.sender].betType == 1){
            ///up/down bet
            uint256 fullAmount = rounds[epoch].AmountInfo.bullAmount + rounds[epoch].AmountInfo.bearAmount;

            if (rounds[epoch].closePrice > rounds[epoch].lockPrice ){
                //bull win
                require(ledger[epoch][msg.sender].position == Position.Bull,"Your bet lost");
                reward = ledger[epoch][msg.sender].amount * fullAmount / rounds[epoch].AmountInfo.bullAmount;
                treasuryReward = reward * treasuryFee / 1000;
                NFTreward =  reward * NFTfee / 1000;

                reward = reward - treasuryReward - NFTreward;
                NFTbull += NFTreward;
                treasuryAmount += treasuryReward;

                ledger[epoch][msg.sender].claimed = true;
                totalWon[msg.sender] += reward;
                _safeTransferMatic(msg.sender,reward);
            }

            if (rounds[epoch].closePrice < rounds[epoch].lockPrice ){
                //bear win
                require(ledger[epoch][msg.sender].position == Position.Bear, "Your bet lost");
                reward = ledger[epoch][msg.sender].amount * fullAmount / rounds[epoch].AmountInfo.bearAmount;
                treasuryReward = reward * treasuryFee / 1000;
                NFTreward =  reward * NFTfee / 1000;

                reward = reward - treasuryReward - NFTreward;
                NFTbear += NFTreward;
                treasuryAmount += treasuryReward;

                ledger[epoch][msg.sender].claimed = true;
                totalWon[msg.sender] += reward;
                _safeTransferMatic(msg.sender,reward);
            }

        }

        if (ledger[epoch][msg.sender].betType == 2){
            ///zones betting
            reward = getRewardAmount(epoch);
            treasuryReward = reward * treasuryFee / 1000;
            NFTreward =  reward * NFTfee / 1000;

            reward = reward - treasuryReward - NFTreward;
            treasuryAmount += treasuryReward;
            ledger[epoch][msg.sender].claimed = true;
            totalWon[msg.sender] += reward;
            _safeTransferMatic(msg.sender,reward);

            //bulls won
            if (rounds[epoch].lockPrice>rounds[epoch].closePrice){
                NFTbull += NFTreward;
            }
            if (rounds[epoch].lockPrice<rounds[epoch].closePrice){
                NFTbull += NFTreward;
            }
        }


    }

    function getRewardAmount(uint256 epoch) public view returns (uint256){
        uint256 reward;

        if (ledger[epoch][msg.sender].claimed == true)
            return 0;

        if (ledger[epoch][msg.sender].betType == 1){
            ///up/down bet
            uint256 fullAmount = rounds[epoch].AmountInfo.bullAmount + rounds[epoch].AmountInfo.bearAmount;

            if (rounds[epoch].closePrice > rounds[epoch].lockPrice ){
                //bull win

                if (ledger[epoch][msg.sender].position == Position.Bull)
                    reward = ledger[epoch][msg.sender].amount * fullAmount / rounds[epoch].AmountInfo.bullAmount ;
                else 
                    reward = 0;
                return reward;
            }

            if (rounds[epoch].closePrice < rounds[epoch].lockPrice ){
                //bear win
                if (ledger[epoch][msg.sender].position == Position.Bear)
                    reward = ledger[epoch][msg.sender].amount * fullAmount / rounds[epoch].AmountInfo.bearAmount ;
                else
                    reward = 0;

                return reward;

            }
        }

        if (ledger[epoch][msg.sender].betType == 2){
            ///zones betting
            
            uint256 fullAmount = rounds[epoch].AmountInfo.bearZone1Amount + rounds[epoch].AmountInfo.bearZone2Amount + rounds[epoch].AmountInfo.bearDegenZoneAmount + 
                                 rounds[epoch].AmountInfo.bullZone1Amount + rounds[epoch].AmountInfo.bullZone2Amount + rounds[epoch].AmountInfo.bullDegenZoneAmount   ;

            //bullZone win
            //zone 1 wins, zone2, degenZone refunded
            if (rounds[epoch].closePrice > rounds[epoch].lockPrice && rounds[epoch].closePrice <= rounds[epoch].lockPrice + rounds[epoch].borderAmount ){
                fullAmount = fullAmount - rounds[epoch].AmountInfo.bullZone2Amount - rounds[epoch].AmountInfo.bullDegenZoneAmount ;

                if (ledger[epoch][msg.sender].position == Position.BullZone1){
                    return ledger[epoch][msg.sender].amount * fullAmount / rounds[epoch].AmountInfo.bullZone1Amount ;
                }

                if (ledger[epoch][msg.sender].position == Position.BullZone2 || ledger[epoch][msg.sender].position == Position.BullDegenZone){
                    return ledger[epoch][msg.sender].amount;
                }
                return 0;
            }

            //zone 2 wins, degenZone refunded
            if (rounds[epoch].closePrice > rounds[epoch].lockPrice + rounds[epoch].borderAmount && rounds[epoch].closePrice <= rounds[epoch].lockPrice + 2 * rounds[epoch].borderAmount ){
                fullAmount = fullAmount - rounds[epoch].AmountInfo.bullDegenZoneAmount ;
                if (ledger[epoch][msg.sender].position == Position.BullZone2){
                    return ledger[epoch][msg.sender].amount * fullAmount / rounds[epoch].AmountInfo.bullZone2Amount  ;
                }
                if (ledger[epoch][msg.sender].position == Position.BullZone2){
                    return ledger[epoch][msg.sender].amount;
                }
                return 0;
            }

            //degenZone wins
            if (rounds[epoch].closePrice > rounds[epoch].lockPrice + 2 * rounds[epoch].borderAmount){
                if (ledger[epoch][msg.sender].position == Position.BullDegenZone){
                    return ledger[epoch][msg.sender].amount * fullAmount / rounds[epoch].AmountInfo.bullDegenZoneAmount ;
                }
                return 0;
            }

            //bearZone win
            //zone 1 wins, zone2, degenZone refunded
            if (rounds[epoch].closePrice < rounds[epoch].lockPrice && rounds[epoch].closePrice >= rounds[epoch].lockPrice - rounds[epoch].borderAmount ){
                fullAmount = fullAmount - rounds[epoch].AmountInfo.bearZone2Amount - rounds[epoch].AmountInfo.bearDegenZoneAmount ;

                if (ledger[epoch][msg.sender].position == Position.BearZone1){
                    return ledger[epoch][msg.sender].amount * fullAmount / rounds[epoch].AmountInfo.bearZone1Amount ;
                }

                if (ledger[epoch][msg.sender].position == Position.BearZone2 || ledger[epoch][msg.sender].position == Position.BearDegenZone){
                    return ledger[epoch][msg.sender].amount;
                }
                return 0;
            }

            //zone 2 wins, degenZone refunded
            if (rounds[epoch].closePrice < rounds[epoch].lockPrice - rounds[epoch].borderAmount && rounds[epoch].closePrice >= rounds[epoch].lockPrice - 2 * rounds[epoch].borderAmount ){
                fullAmount = fullAmount - rounds[epoch].AmountInfo.bearDegenZoneAmount ;
                if (ledger[epoch][msg.sender].position == Position.BearZone2){
                    return ledger[epoch][msg.sender].amount * fullAmount / rounds[epoch].AmountInfo.bearZone2Amount ;
                }
                if (ledger[epoch][msg.sender].position == Position.BearZone2){
                    return ledger[epoch][msg.sender].amount;
                }
                return 0;
            }

            //degenZone wins
            if (rounds[epoch].closePrice < rounds[epoch].lockPrice - 2 * rounds[epoch].borderAmount){
                if (ledger[epoch][msg.sender].position == Position.BearDegenZone){
                    return ledger[epoch][msg.sender].amount * fullAmount / rounds[epoch].AmountInfo.bearDegenZoneAmount;
                }
                return 0;
            }
        }

        return reward;
    }

    function claimTreasury () public{
        require(msg.sender ==owner, "Not authorized");
        payable(owner).transfer(treasuryAmount);
        treasuryAmount = 0;
    }

    function setTreasuryFee(uint256 _treasuryFee) public{
        require(msg.sender ==owner, "Not authorized");
        treasuryFee = _treasuryFee;
    }

    function setBorderAmount (int256 _borderAmount) public{
        require(msg.sender == owner,"Not authorized");
        borderAmount = _borderAmount;
    }

    function withdrawStuckWei(uint256 _balance) public{
        require(msg.sender == owner, "Not authorized");
        payable(owner).transfer(_balance);
    }

    function setTokenId(uint256 _tokenId) public{
        require(msg.sender == owner,"Not authorized");
        tokenId = _tokenId;
    }

    function setNFTfee(uint256 _fee) public{
        require(msg.sender== owner,"Not authorized");
        NFTfee = _fee;
    }

    function _isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function _safeTransferMatic(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}("");
        require(success, "TransferHelper: MATIC_TRANSFER_FAILED");
    }

    function recoverToken(address _token, uint256 _amount) external  {
        require(msg.sender == owner,"Not authorized");
        IERC20(_token).safeTransfer(address(msg.sender), _amount);
        emit TokenRecovery(_token, _amount);
    }

    receive() external payable {}
}