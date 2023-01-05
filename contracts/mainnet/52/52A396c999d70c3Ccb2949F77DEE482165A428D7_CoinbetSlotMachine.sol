// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ICoinbetGame.sol";
import "./interfaces/ICoinbetHousePool.sol";
import "./VRFv2Consumer.sol";

contract CoinbetSlotMachine is ICoinbetGame, VRFv2Consumer, Ownable, Pausable {
    using Address for address;

    struct Bet {
        address player;
        uint88 amount;
        bool isSettled;
        uint128 blockNumber;
        uint128 winAmount;
    }

    /* ========== STATE VARIABLES ========== */

    uint256 public minBetAmount;
    uint256 public maxBetAmount;
    uint256 public protocolFeeBps;
    uint256 public coinbetTokenFeeWaiverThreshold;

    ICoinbetHousePool public housePool;
    IERC20 public immutable coinbetToken;

    // mapping requestId => Bet
    mapping(uint256 => Bet) public userBets;

    uint8[6] public rewardMultipliers = [40, 30, 20, 15, 10, 5];

    /// @notice Checks if the bet amount is valid before slot machine spin.
    /// @param betAmount The bet amount.
    modifier onlyValidBet(uint256 betAmount) {
        require(
            _msgSender() == tx.origin,
            "Coinbet Slot Machine: Msg sender should be original caller"
        );
        require(
            minBetAmount <= betAmount && betAmount <= maxBetAmount,
            "Coinbet Slot Machine: Invalid bet amount"
        );
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor(
        uint256 _minBetAmount,
        uint256 _maxBetAmount,
        uint256 _coinbetTokenFeeWaiverThreshold,
        uint256 _protocolFeeBps,
        uint64 _subscriptionId,
        bytes32 _keyHash,
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations,
        uint32 _numWords,
        address _vrfCordinator,
        address _housePool,
        address _coinbetTokenAddress
    )
        VRFv2Consumer(
            _subscriptionId,
            _keyHash,
            _callbackGasLimit,
            _requestConfirmations,
            _numWords,
            _vrfCordinator
        )
    {
        minBetAmount = _minBetAmount;
        maxBetAmount = _maxBetAmount;
        protocolFeeBps = _protocolFeeBps;
        coinbetTokenFeeWaiverThreshold = _coinbetTokenFeeWaiverThreshold;

        housePool = ICoinbetHousePool(_housePool);
        coinbetToken = IERC20(_coinbetTokenAddress);
    }

    /* ========== VIEWS ========== */

    /// TODO: Add different battle-tested logic for reward calculation
    /// @notice Calculates the current reward, based on the rollPrice and random values returned from Chainlink.
    /// @param spinAmount The roll price.
    /// @param randomWords Array of random numbers fulfilled.
    function calculateWinAmount(
        uint256 spinAmount,
        uint256[] memory randomWords
    )
        internal
        view
        returns (
            uint256 firstReelResult,
            uint256 secondReelResult,
            uint256 thirdReelResult,
            uint256 winAmount
        )
    {
        firstReelResult = expandRandomNumber(randomWords[0]);
        secondReelResult = expandRandomNumber(randomWords[1]);
        thirdReelResult = expandRandomNumber(randomWords[2]);

        // Calculate rewards based on the derived combination
        if (
            firstReelResult == 6 &&
            secondReelResult == 6 &&
            thirdReelResult == 6
        ) {
            winAmount = spinAmount * rewardMultipliers[0];
        } else if (
            firstReelResult == 5 &&
            secondReelResult == 5 &&
            thirdReelResult == 5
        ) {
            winAmount = spinAmount * rewardMultipliers[1];
        } else if (
            firstReelResult == 4 &&
            secondReelResult == 4 &&
            thirdReelResult == 4
        ) {
            winAmount = spinAmount * rewardMultipliers[2];
        } else if (
            firstReelResult == 3 &&
            secondReelResult == 3 &&
            thirdReelResult == 3
        ) {
            winAmount = spinAmount * rewardMultipliers[3];
        } else if (
            firstReelResult == 2 &&
            secondReelResult == 2 &&
            thirdReelResult == 2
        ) {
            winAmount = spinAmount * rewardMultipliers[4];
        } else if (
            firstReelResult == 1 &&
            secondReelResult == 1 &&
            thirdReelResult == 1
        ) {
            winAmount = spinAmount * rewardMultipliers[5];
        } else if (
            (firstReelResult == secondReelResult) ||
            (firstReelResult == thirdReelResult) ||
            (secondReelResult == thirdReelResult)
        ) {
            winAmount = spinAmount;
        } else {
            winAmount = 0;
        }
    }

    function expandRandomNumber(uint256 randomValue)
        internal
        pure
        returns (uint256 expandedValue)
    {
        // Expand random number
        expandedValue = (randomValue % 6) + 1;
    }

    /// @notice Calculates the protocol fee. If the player holds a certain amount of $CFI tokens
    /// the protocol fee is waived. The minimum amount coinbet tokens is set in the constructor
    /// @param _betAmount The bet amount
    /// @param _protocolFeeBps The protocol fee in basis points
    /// @param _player The address of the player
    function calculateProtocolFee(
        uint256 _betAmount,
        uint256 _protocolFeeBps,
        address _player
    ) internal view returns (uint256 protocolFee) {
        uint256 coinbetTokenBalance = coinbetToken.balanceOf(_player);
        if (coinbetTokenBalance >= coinbetTokenFeeWaiverThreshold) {
            protocolFee = 0;
        } else {
            protocolFee = (_protocolFeeBps * _betAmount) / 10000;
        }
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /// @notice Executes a slot machine roll by player, who has enough balance.
    function coinbet() external payable whenNotPaused onlyValidBet(msg.value) {
        uint256 betAmount = msg.value;
        uint256 protocolFee = calculateProtocolFee(
            betAmount,
            protocolFeeBps,
            _msgSender()
        );
        uint256 requestId = requestRandomWords();

        userBets[requestId].player = _msgSender();
        userBets[requestId].amount = uint88(betAmount);
        userBets[requestId].blockNumber = uint128(block.number);

        emit BetPlaced(betAmount, requestId, _msgSender());

        housePool.placeBet{value: betAmount}(
            protocolFee,
            _msgSender(),
            (betAmount * rewardMultipliers[0])
        );
    }

    /// @notice Updates the min bet amount for playing.
    /// @param newMinBetAmount The new min bet amount.
    function updateMinBetAmount(uint256 newMinBetAmount) external onlyOwner {
        minBetAmount = newMinBetAmount;

        emit MinBetAmountUpdated(newMinBetAmount);
    }

    /// @notice Updates the max bet amount for playing.
    /// @param newMaxBetAmount The new max bet amount.
    function updateMaxBetAmount(uint256 newMaxBetAmount) external onlyOwner {
        maxBetAmount = newMaxBetAmount;

        emit MaxBetAmountUpdated(newMaxBetAmount);
    }

    /// @notice Updates the roll fee deducted on every roll.
    /// @param newProtocolFeeBps The new roll fee in basis points.
    function updateProtocolFeeBps(uint256 newProtocolFeeBps)
        external
        onlyOwner
    {
        protocolFeeBps = newProtocolFeeBps;

        emit ProtocolFeeUpdated(newProtocolFeeBps);
    }

    /// @notice Updates the house pool address
    /// @param newHousePoolAddress The new house pool address.
    function updateHousePoolAddress(address newHousePoolAddress)
        external
        onlyOwner
    {
        require(
            newHousePoolAddress != address(0),
            "Coinbet Slot Machine: Cannot set address zero"
        );
        housePool = ICoinbetHousePool(newHousePoolAddress);

        emit HousePoolUpdated(newHousePoolAddress);
    }

    /// @notice Pauses the contract.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Updates the threshold of CFI token a player should have.
    /// @param newThreshold The new threshold amount in CFI tokens.
    function updateCoinbetTokenFeeWaiverThreshold(uint256 newThreshold)
        external
        onlyOwner
    {
        coinbetTokenFeeWaiverThreshold = newThreshold;

        emit CoinbetTokenFeeWaiverThresholdUpdated(newThreshold);
    }

    /// @notice Requests randomness from Chainlink. Called inside coinbet.
    /// Assumes the subscription is funded sufficiently.
    function requestRandomWords() internal returns (uint256 _userRequestId) {
        _userRequestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
    }

    /// @notice Callback function, executed by Chainlink's VRF Coordinator contract.
    /// @param requestId The respective request id.
    /// @param randomWords Array of random numbers fulfilled.
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        settleBet(requestId, randomWords);
    }

    /// @notice Settles the pending bet.
    /// @param requestId The respective request id.
    /// @param randomWords Array of random numbers fulfilled.
    function settleBet(uint256 requestId, uint256[] memory randomWords)
        internal
    {
        // Get the bet which will be settled
        Bet storage bet = userBets[requestId];

        // Get the spin price
        uint256 betAmount = bet.amount;

        // Calculate protocol fee
        uint256 protocolFee = calculateProtocolFee(
            betAmount,
            protocolFeeBps,
            bet.player
        );

        // Calculate the win amount if any
        (
            uint256 firstReel,
            uint256 secondReel,
            uint256 thirdReel,
            uint256 winAmount
        ) = calculateWinAmount((betAmount - protocolFee), randomWords);

        // Store the win amount in the struct
        bet.winAmount = uint128(winAmount);

        // Check if there is enough liquidity to payout the pending bet or if bet is already settled
        if (bet.isSettled || housePool.poolBalance() < winAmount) {
            return;
        }

        bet.isSettled = true;

        emit BetSettled(
            firstReel,
            secondReel,
            thirdReel,
            winAmount,
            requestId,
            bet.player
        );

        housePool.settleBet(
            winAmount,
            bet.player,
            (bet.amount * rewardMultipliers[0])
        );
    }

    /// @notice Refunds non payed bet in case VRF callback has reverted.
    /// @param requestId The respective request id.
    function refundBet(uint256 requestId) external {
        // Get the bet which will be settled
        Bet storage bet = userBets[requestId];

        // Get the spin price
        uint256 betAmount = bet.amount;

        // Calculate protocol fee
        uint256 protocolFee = calculateProtocolFee(
            betAmount,
            protocolFeeBps,
            bet.player
        );

        // Calculate the win amount if any
        uint256 winAmount = betAmount - protocolFee;

        // Check if there is enough liquidity to payout the pending bet or if bet is already settled
        require(
            winAmount > 0,
            "Coinbet Slot Machine: Amount should be greater than zero"
        );
        require(!bet.isSettled, "Coinbet Slots: Bet is already settled");
        require(
            block.number > bet.blockNumber + 43200,
            "Coinbet Slot Machine: Try requesting a refund later"
        );
        require(
            housePool.poolBalance() >= winAmount,
            "Coinbet Slot Machine: Insufficient liqudity to payout bet"
        );

        bet.winAmount = uint128(winAmount);
        bet.isSettled = true;

        emit BetRefunded(winAmount, requestId, bet.player);

        housePool.settleBet(
            winAmount,
            bet.player,
            bet.amount * rewardMultipliers[0]
        );
    }

    /* ========== EVENTS ========== */

    event MinBetAmountUpdated(uint256 newMinBetAmount);
    event MaxBetAmountUpdated(uint256 newMaxBetAmount);
    event ProtocolFeeUpdated(uint256 newProtocolFeeBps);
    event HousePoolUpdated(address newHousePoolAddress);
    event CoinbetTokenFeeWaiverThresholdUpdated(uint256 newThreshold);
    event BetPlaced(uint256 betAmount, uint256 requestId, address player);
    event BetRefunded(uint256 betAmount, uint256 requestId, address player);
    event BetSettled(uint256 firstReel, uint256 secondReel, uint256 thirdReel, uint256 winAmount, uint256 requestId, address player);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
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

// SPDX-License-Identifier: MIT
// An example of a consumer contract that relies on a subscription for funding.
pragma solidity 0.8.17;

interface ICoinbetGame{
    function coinbet() external payable;
}

// SPDX-License-Identifier: MIT
// An example of a consumer contract that relies on a subscription for funding.
pragma solidity 0.8.17;

interface ICoinbetHousePool {
    function addRewardsLiquidity() external payable returns (uint256 liquidity);

    function poolBalance() external returns (uint256);

    function availableFundsForPayroll() external returns (uint256);

    function placeBet(
        uint256 protocolFee,
        address player,
        uint256 maxWinnableAmount
    ) external payable;

    function settleBet(
        uint256 winAmount,
        address player,
        uint256 maxWinnableAmount
    ) external;

    function removeRewardsLiquidity(uint256 liquidity)
        external
        returns (uint256 amount);
}

// SPDX-License-Identifier: MIT
// An example of a consumer contract that relies on a subscription for funding.
pragma solidity 0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

abstract contract VRFv2Consumer is VRFConsumerBaseV2 {
    VRFCoordinatorV2Interface immutable COORDINATOR;

    // Your subscription ID.
    uint64 immutable s_subscriptionId;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    bytes32 immutable keyHash;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 immutable callbackGasLimit;

    // The default is 3, but you can set this higher.
    uint16 immutable requestConfirmations;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 immutable numWords;

    constructor(
        uint64 _subscriptionId,
        bytes32 _keyHash,
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations,
        uint32 _numWords,
        address vrfCoordinator
    ) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_subscriptionId = _subscriptionId;
        keyHash = _keyHash;
        callbackGasLimit = _callbackGasLimit;
        requestConfirmations = _requestConfirmations;
        numWords = _numWords;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}