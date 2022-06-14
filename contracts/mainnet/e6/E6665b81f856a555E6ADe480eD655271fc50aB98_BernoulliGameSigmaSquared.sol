/**
 *Submitted for verification at polygonscan.com on 2022-06-13
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// File: @openzeppelin/contracts/utils/Address.sol

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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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

// File: contracts/interfaces/RandomnessProvider.sol

pragma solidity ^0.8.0;

interface RandomnessProvider {
    /**
     * Requests randomness.
     * @return requestID An ID associated with the randomness request.
     */
    function requestRandomness() external returns(bytes32);
}

// File: contracts/interfaces/SigmaGameRewards.sol

pragma solidity ^0.8.0;

/**
 * An interface implemented by contracts that give rewards to game users based on their activity.
 * This provides a standard interfacts for game contracts to report user activity.
 */
interface SigmaGameRewards {
    function recordWin(address bettor, uint256 betAmount, uint256 winAmount, bytes32 requestId) external;

    function recordLoss(address bettor, uint256 betAmount, bytes32 requestId) external;
}

// File: contracts/GameBase.sol

pragma solidity ^0.8.4;
/**
 * The base contract for all gambling games.  This contains any logic that can be shared across all games.
 */
abstract contract GameBase is Ownable {
    
    event RandomnessProviderChanged(address prevProvider, address newProvider);
    event GameRewardsChanged(address prevRewards, address newRewards);

    modifier onlyRandomnessProvider {
        require(
            msg.sender == address(randomnessProvider),
            "Only the designated randomness provider can call this function."
        );
        _;
    }

    RandomnessProvider private randomnessProvider;
    SigmaGameRewards private rewardsContract;

    constructor(RandomnessProvider randomnessProviderIn) {
        randomnessProvider = randomnessProviderIn;
    }

    /**
     * Sets the designated randomness provider.  This is the only contract/account allowed to provide randomness
     * used in the game.
     * WARNING: This should only ever be changed with extreme care, as it affects the integrity of the game.
     * @param randomnessProviderIn The address of the new randomness provider.
     */
    function setRandomnessProvider(RandomnessProvider randomnessProviderIn) external onlyOwner {
        emit RandomnessProviderChanged(address(randomnessProvider), address(randomnessProviderIn));
        randomnessProvider = randomnessProviderIn;
    }

    /**
     * Sets the rewards contract that wins and losses are reported to.
     * @param rewardsIn The address of the rewards contracts (or the zero address if nothing should be reported).
     */
    function setGameRewards(SigmaGameRewards rewardsIn) external onlyOwner {
        emit GameRewardsChanged(address(rewardsContract), address(rewardsIn));
        rewardsContract = rewardsIn;
    }

    /**
     * @return randomnessProvider The current randomness provider.  This is the only contract/address allowed to provided randomness to the game.
     */
    function getRandomnessProvider() public view returns(RandomnessProvider) {
        return randomnessProvider;
    }

    /**
     * @return rewardsContract The current rewards contract where losses and wins are reported to.
     */
    function getGameRewards() public view returns(SigmaGameRewards) {
        return rewardsContract;
    }
    

    /**
     * Called internally to transfer funds from the contract to some recepient.  This should be overriden by children
     * and send either an ERC20 token or the native chain token.
     * @param recepient The address to receive the funds.
     * @param amount The amount to send.
     */
    function _doTransfer(address recepient, uint256 amount) virtual internal;

    /**
     * Called internally when the contract should receive funds from a user.  This should be overriden by children
     * contracts and either initiate a ERC20 transfer, or ensure the caller has provided the needed native token.
     */
    function _receiveFunds(uint256 amount) virtual internal;

    /**
     * @return The current contract's balance (current unsettled bets not included).
     */
    function getContractBalance() virtual public view returns(uint256);

}

// File: contracts/interfaces/RandomnessConsumer.sol

pragma solidity ^0.8.0;

interface RandomnessConsumer {
    function receiveRandomInt(bytes32 requestID, uint256 randomInt) external;
}

// File: contracts/BernoulliGameBase.sol

pragma solidity ^0.8.0;
/**
 * The base contract for all Bernoulli games.  This contains all the shared common logic.
 * 
 * A Bernoulli game is one in which a player bets on a Bernoulli random variable.  As such, there are two possible
 * outcomes: a win or a loss.  The user can place a bet and specify an amount and a multiplier.  When the bet is
 * settled, the result will either be a win and they'll recieve amount * multiplier or a loss and they won't get anything.
 * The probability of a win depends on the set house edge.
 *
 * Example: Player bets amount 2, with multiplier 2x.  There is a 0 house edge.
 * Outcomes: 50% win (player recieves 4), 50% loss (player recieves nothing).
 *
 * Multipliers, house edge, and other percentage type variable are specified as integer mantissas, with 8 decimal places.
 * e.g. 1e8 => 100%, 5e7 => 50%
 */
abstract contract BernoulliGameBase is RandomnessConsumer, GameBase {

    event BetReceived(address indexed bettor, uint256 amount, uint256 multiplier);
    event BetAccepted(address indexed bettor, uint256 amount, uint256 multiplier, bytes32 requestId);
    event BetLost(address indexed bettor, uint256 betAmount, uint256 multiplier, bytes32 requestId, uint128 randInt);
    event BetWon(address indexed bettor, uint256 betAmount, uint256 multiplier, uint256 winAmount, bytes32 requestId, uint128 randInt);

    event HouseEdgeChanged(uint256 prevValue, uint256 newValue);
    event MaxLossMantissaChanged(uint256 prevValue, uint256 newValue);
    event MinBetChanged(uint256 prevValue, uint256 newValue);

    uint256 MAX_UINT_128 = 2**128 - 1;

    struct Bet {
        address bettor;
        uint256 amount;
        uint256 multiplier; // 8 decimal places
        uint256 blockNumber;
        bool settled;
        bool outcome; // true for win, false for loss.
    }

    Bet[] private placedBets;

    // Maps request IDs (from randomness provider) to bet indices.
    mapping(bytes32 => uint256) private requestIdMap;

    // The total sum of all bets placed.
    uint256 private totalVolume = 0;

    uint256 private numActiveBets = 0;

    // The expected house edge percentage for each bet.  This must be between 0 and 1 (1e8), inclusive.
    uint256 private houseEdgeMantissa = 0;      // 8 decimal places

    // The maximum percentage of the contracts balance that can be lost in a single bet.
    uint256 private maxLossMantissa;   // 8 decimal places

    // The min bet allowed.
    uint256 private minBet;

    // The amount of this contract's funds currently at risk from unsettled bets that have been placed.
    uint256 private atRisk = 0;

    // The total profit (or loss if negative) this contract has made since inception.
    int256 private totalContractProfit = 0;

    constructor (RandomnessProvider randomnessProviderIn)
        GameBase(randomnessProviderIn) {

    }

    /**
     * Place a bet.  If the bet is won, the sender receives amount * multiplier back.
     * If the bet is lost, nothing is recieved.  Bets will be settled later on when randomness is received.
     * @param amount the amount to bet.
     * @param multiplier the multiplier to use.  This has 8 decimal places.
     * @return requestId The request ID associated with the bet.
     */
    function placeBet(uint256 amount, uint256 multiplier) payable external returns(bytes32) {
        emit BetReceived(msg.sender, amount, multiplier);
        require(multiplier > 1e8, "The multiplier must be greater than 1 (1e8 mantissa)");
        _receiveFunds(amount);
        // Apply risk checks.
        _applyRiskChecks(amount, multiplier);

        // Request randomness.
        bytes32 requestId = getRandomnessProvider().requestRandomness();

        // Keep track of request ID => bettor mapping.
        requestIdMap[requestId] = placedBets.length;

        // Add bet to list.
        atRisk += ((amount * multiplier) / 1e8);
        placedBets.push(Bet(msg.sender, amount, multiplier, block.number, false, false));
        emit BetAccepted(msg.sender, amount, multiplier, requestId);

        totalVolume += amount;
        ++numActiveBets;

        return requestId;
    }


    /**
     * Receive generated randomness from the designated randomness provider.  Extreme care needs to be taken to ensure
     * the randomness provider is trusted/secure and is truly random.  This is controlled by the contract owner.
     * The corresponding bet is settled using the provided randomness.
     * @param randomInt The provided random uint256.
     */
    function receiveRandomInt(bytes32 requestId, uint256 randomInt) external onlyRandomnessProvider {
        // Use the random int to the settle the corresponding bet.
        uint256 betId = requestIdMap[requestId];
        Bet memory currentBet = placedBets[betId];
        require(!currentBet.settled, "The current bet should never be settled already, something's really wrong.");
        require(!currentBet.outcome, "The current bet should never have a win outcome before it's settled, something's really wrong.");
        uint128 currentRandomInt = uint128(randomInt);
        // probability = (1 / multiplier)
        uint256 probability = ((MAX_UINT_128 + 1) * (1e8 - houseEdgeMantissa)) / currentBet.multiplier; // scaled between 0 and max uint128
        uint256 winAmount = (currentBet.amount * currentBet.multiplier) / 1e8;
        if (currentRandomInt < uint128(probability)) {
            // The bet was won.
            // Transfer the winnings.
            _doTransfer(currentBet.bettor, winAmount);
            // Record the outcome.
            placedBets[betId].outcome = true;
            require(placedBets[betId].outcome);
            emit BetWon(currentBet.bettor, currentBet.amount, currentBet.multiplier, winAmount, requestId, currentRandomInt);
            // Report win to the rewards contract if necessary.
            if (address(getGameRewards()) != address(0)) {
                getGameRewards().recordWin(currentBet.bettor, currentBet.amount, winAmount, requestId);
            }
            // Keep track of total contract profit.
            totalContractProfit -= int256(winAmount - currentBet.amount);
        } else {
            // The bet was lost.
            // Nothing needs to be transfered as the contract already has the original amount bet.
            emit BetLost(currentBet.bettor, currentBet.amount, currentBet.multiplier, requestId, currentRandomInt);
            // Report loss to the rewards contract if necessary.
            if (address(getGameRewards()) != address(0)) {
                getGameRewards().recordLoss(currentBet.bettor, currentBet.amount, requestId);
            }
            // Keep track of total contract profit.
            totalContractProfit += int256(currentBet.amount);
        }
        placedBets[betId].settled = true;
        atRisk -= winAmount;
        --numActiveBets;
    }

    /**
     * Used to get the original bet back if the bet is never settled for some reason.
     */
    function refundBet(bytes32 requestId) external {
        uint256 betId = requestIdMap[requestId];
        require(block.number - placedBets[betId].blockNumber > 1000, "Must wait at least 1000 blocks before you can refund a bet.");
        require(!placedBets[betId].settled, "Bet is already settled.");
        placedBets[betId].settled = true;
        uint256 winAmount = (placedBets[betId].amount * placedBets[betId].multiplier) / 1e8;
        atRisk -= winAmount;
        --numActiveBets;
        _doTransfer(placedBets[betId].bettor, placedBets[betId].amount);
    }

    /**
     * Sets the max possible loss allowed, as a percentage of the contracts current balance.
     * @param mantissa The max possible loss allowed expressed as a percentage mantissa (8 decimal places).
     */
    function setMaxLossMantissa(uint256 mantissa) external onlyOwner {
        emit MaxLossMantissaChanged(houseEdgeMantissa, mantissa);
        maxLossMantissa = mantissa;
    }

    /**
     * Sets the min bet allowed.
     */
    function setMinBet(uint256 minBetIn) external onlyOwner {
        emit MinBetChanged(minBet, minBetIn);
        minBet = minBetIn;
    }

    /**
     * Sets the house edge for each bet, as a percentage of each bet.
     * @param mantissa The house edge for each bet expressed as a percentage mantissa (8 decimal places).
     */
    function setHouseEdge(uint256 mantissa) external onlyOwner {
        require(mantissa <= 1e8);
        emit HouseEdgeChanged(houseEdgeMantissa, mantissa);
        houseEdgeMantissa = mantissa;
    }

    /**
     * Withdraws funds from the game's balance, and sends to the owner.
     */
    function withdraw(uint256 amount) external onlyOwner {
        _doTransfer(owner(), amount);
    }

    /**
     * @return totalVolume The total sum of all bets placed.
     */
    function getTotalVolume() public view returns(uint256) {
        return totalVolume;
    }

    /**
     * @return numActiveBets The current number of active bets waiting to be settled.
     * These bets are waiting for a random integer to be provided before they are settled.
     */
    function getNumActiveBets() public view returns(uint256) {
        return numActiveBets;
    }

    /**
     * @return placedBets An array of all bets placed throughout this contracts history.
     */
    function getPlacedBets() public view returns(Bet[] memory) {
        return placedBets;
    }

    /**
     * @return houseEdgeMantissa The house edge for each bet.
     */
    function getHouseEdge() public view returns(uint256) {
        return houseEdgeMantissa;
    }

    /**
     * @return maxLossMantissa The max loss allowed, as a percentage of the contract's current balance.
     */
    function getMaxLossMantissa() public view returns(uint256) {
        return maxLossMantissa;
    }

    /**
     * @return minBet The minimum bet allowed.
     */
    function getMinBet() public view returns(uint256) {
        return minBet;
    }

    /**
     * @return totalAtRisk The total amount currently at risk, from unsettled bets.
     */
    function getTotalAtRisk() public view returns(uint256) {
        return atRisk;
    }

    /**
     * @return totalProfit The total contract profit since inception (negative for loss).
     */
    function getTotalContractProfit() public view returns(int256) {
        return totalContractProfit;
    }

    /**
     * Used to apply risk checks to an incoming bet.
     * This ensures the contract has sufficient funds to fulfill all wins in the worst-case scenario, and ensures
     * the possible win amount is not greater than the max allowable loss (percentage of contract's funds).
     */
    function _applyRiskChecks(uint256 amount, uint256 multiplier) internal view {
        require(amount >= minBet, "Bet is below minimum allowed.");
        // Ensure loss isn't greater than maximum allowed.
        // (you have to subtract the bet amount, because it was already transfered at this point)
        require(((amount * (multiplier - 1e8)) / 1e8) <= (((getContractBalance() - amount - atRisk) * maxLossMantissa) / 1e8), "Max possible win is too high.");
        // Ensure the contract has sufficient funds.
        require(((amount * multiplier) / 1e8) < (getContractBalance() - atRisk), "Insufficient contract funds.");
    }
}

// File: contracts/BernoulliGameERC20.sol

pragma solidity ^0.8.0;
/**
 * Extends the BernoulliGameBase contract to implement a Bernoulli game for ERC20 tokens.
 */
contract BernoulliGameERC20 is BernoulliGameBase {
    using SafeERC20 for IERC20;

    IERC20 private token;

    constructor(RandomnessProvider randomnessProviderIn, IERC20 tokenIn) BernoulliGameBase(randomnessProviderIn) {
        token = tokenIn;
    }

    function getTokenAddress() public view returns(IERC20) {
        return token;
    }

    function _doTransfer(address recepient, uint256 amount) override internal {
        token.safeTransfer(recepient, amount);
    }

    function _receiveFunds(uint256 amount) override internal {
        token.safeTransferFrom(msg.sender, address(this), amount);
    }

    function getContractBalance() override public view returns(uint256) {
        return token.balanceOf(address(this));
    }
}

// File: contracts/BernoulliGameSigmaSquared.sol

pragma solidity ^0.8.0;
/**
 * This is the exact same as BernoulliGameERC20, it only exists to make it easier for Truffle to deploy and keep
 * track of duplicate contracts.
 * It is intended to be used for a Bernoulli game where bets are placed with Sigma Squared.
 */
contract BernoulliGameSigmaSquared is BernoulliGameERC20 {
    constructor(RandomnessProvider randomnessProviderIn, IERC20 tokenIn)
        BernoulliGameERC20(randomnessProviderIn, tokenIn) {

    }
}