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

// File: contracts/LotteryBase.sol

pragma solidity ^0.8.4;
abstract contract LotteryBase is RandomnessConsumer, GameBase {

    event Deposit(address indexed bettor, uint256 indexed round, uint256 amount, uint256 roundDepositTotal);
    event RoundEndTriggered(uint256 indexed round, bytes32 requestId, uint256 totalPool);
    event RoundEnd(uint256 indexed round, address winner, uint256 totalPool, uint256 randInt);

    event HouseEdgeChanged(uint256 prevValue, uint256 newValue);

    uint256 MAX_UINT_256 = 2**256 - 1;

    /**
     * Represents a single user (address)'s entry in a lottery round.
     */
    struct Entry {
        address entrant;
        uint256 totalDeposit;
    }

    /**
     * Represents a lottery round.  At the end of the round, the entire pool is given to a single winner.
     */
    struct Round {
        Entry[] entries;
        uint256 totalPool;
        uint256 startingBlock;
        uint256 endingBlock;
        uint256 lastRandomnessRequestBlock;
        bytes32 randomnessRequestId;
        bool settled;
        address winner;
    }

    // The total sum of all bets placed.
    uint256 private totalVolume = 0;

    // The minimum round length in blocks.
    uint256 private minBlocksPerRound;

    // The house edge percentage for each bet.  This must be between 0 and 1 (1e8) inclusive.
    uint256 private houseEdgeMantissa = 0;  // 8 decimal places

    // An array of lottery rounds.  The current (active) round is the last item in the array.
    Round[] private rounds;

    // The total profit this contact has aquired from its house edge, since inception.
    uint256 totalContractProfit = 0;

    // Contains a mapping from entrant address to entries index, for the current round.
    mapping(address => uint256) entrantIndices;

    /**
     * @param randomnessProviderIn The randomness provider that is allowed to supply this contract with random ints.
     * @param minBlocksPerRoundIn The minimum length, in blocks, a round can be.
     */
    constructor(RandomnessProvider randomnessProviderIn, uint256 minBlocksPerRoundIn) GameBase(randomnessProviderIn) {
        minBlocksPerRound = minBlocksPerRoundIn;

        // Initialize first round.
        rounds.push();
        Round storage firstRound = rounds[0];
        firstRound.startingBlock = block.number;
        firstRound.endingBlock = block.number + minBlocksPerRoundIn;
    }

    /**
     * Enter the current lottery round by depositing some amount. The chance of winning is weighted by the total
     * amount each player has deposited for the round.  If there is a non-zero house edge, it is taken out of the
     * deposit at this point.
     */
    function deposit(uint256 amount) external payable {
        Round storage currentRound = rounds[rounds.length - 1];

        // Make sure current round is active.
        require(currentRound.randomnessRequestId == bytes32(0), "Current round is no longer active");
        require(!currentRound.settled, "Current round is already settled.");

        _receiveFunds(amount);

        // Check if player already has an entry.
        uint256 entryI = entrantIndices[msg.sender];
        // Take out any house edge necessary.
        uint256 depositAmount = (amount * (1e8 - houseEdgeMantissa)) / 1e8;
        totalContractProfit += (amount * houseEdgeMantissa) / 1e8;
        if (currentRound.entries.length > entryI && currentRound.entries[entryI].entrant == msg.sender) {
            // An entry already exists, update it.
            currentRound.entries[entryI].totalDeposit += depositAmount;
            currentRound.totalPool += depositAmount;
            emit Deposit(msg.sender, rounds.length - 1, depositAmount, currentRound.entries[entryI].totalDeposit);
        } else {
            // Otherwise, add new entry.
            entrantIndices[msg.sender] = currentRound.entries.length;
            currentRound.entries.push(Entry(msg.sender, depositAmount));
            currentRound.totalPool += depositAmount;
            emit Deposit(msg.sender, rounds.length - 1, depositAmount, depositAmount);
        }
        totalVolume += amount;
    }

    /**
     * Trigger the end of a lottery round.  After this is called, no one else can deposit/enter into the current round.
     * Randomness will be requested and the winner will be determined when randomness is received later on.  See receiveRandomInt.
     */
    function triggerRoundEnd() external {
        Round storage currentRound = rounds[rounds.length - 1];

        // Make sure the current round is not already settled.
        require(!currentRound.settled, "Round is already settled.");
        // Make sure current round is over.
        require(currentRound.endingBlock <= block.number, "Current round isn't over");
        // Make sure there are entries.
        require(currentRound.totalPool > 0, "Nothing in the pool.");
        require(currentRound.entries.length > 0, "No entries.");

        // Ensure randomness hasn't been requested before, or enough time has passed since the last randomness
        // request (in case of RandomnessProvider failure).
        require(currentRound.lastRandomnessRequestBlock == 0 || currentRound.lastRandomnessRequestBlock + 1000 < block.number,
                "Randomness has already been requested within the past 1000 blocks.  Wait for settlement or for 1000 blocks to pass.");

        currentRound.randomnessRequestId = getRandomnessProvider().requestRandomness();
        currentRound.lastRandomnessRequestBlock = block.number;
        emit RoundEndTriggered(rounds.length - 1, currentRound.randomnessRequestId, currentRound.totalPool);
    }

    /**
     * Receive generated randomness from the designated randomness provider.  This randomness is used to settle the
     * current round.  A winner is determined and the round's entire pool is transfered to them.
     */
    function receiveRandomInt(bytes32 requestId, uint256 randomInt) external onlyRandomnessProvider {
        uint256 originalRandInt = randomInt;
        Round storage currentRound = rounds[rounds.length - 1];
        require(currentRound.randomnessRequestId == requestId, "Request IDs don't match.");

        // Using random entropy provided, get a random number between 0 (inclusive) and the round's total pool (exclusive).
        // For an unbiased random number in this range, the underlying sample size must be divisble by the total pool amount.
        uint256 sampleSpaceRemainder = (MAX_UINT_256 % currentRound.totalPool) + 1;
        while (randomInt > MAX_UINT_256 - sampleSpaceRemainder) {
            // The random number will be continually "redrawn" until it is inside the required sample space.
            randomInt = uint256(keccak256(abi.encode(randomInt)));
        }
        randomInt = randomInt % currentRound.totalPool;

        // Use this number to choose the winner.
        uint256 winnerI = 0;
        uint256 remaining = randomInt;
        while (remaining > 0 && winnerI < currentRound.entries.length) {
            Entry memory currentEntry = currentRound.entries[winnerI];
            if (remaining >= currentEntry.totalDeposit) {
                remaining -= currentEntry.totalDeposit;
                ++winnerI;
            } else {
                remaining = 0;
            }
        }
        require(winnerI < currentRound.entries.length, "Did not find winner, something is very wrong.");
        address winner = currentRound.entries[winnerI].entrant;

        // Settle the round.
        currentRound.winner = winner;
        _doTransfer(winner, currentRound.totalPool);
        currentRound.settled = true;
        emit RoundEnd(rounds.length - 1, winner, currentRound.totalPool, originalRandInt);

        // Start new round.
        rounds.push();
        Round storage newRound = rounds[rounds.length - 1];
        require(!newRound.settled);
        newRound.startingBlock = block.number;
        newRound.endingBlock = block.number + minBlocksPerRound;
    }

    /**
     * Set the minimum length a lottery round can be.
     * @param minBlocksPerRoundIn The minimum duration in blocks.
     */
    function setMinBlocksPerRound(uint256 minBlocksPerRoundIn) external onlyOwner {
        minBlocksPerRound = minBlocksPerRoundIn;
    }

    /**
     * Sets the house edge for each entry, as a percentage of the deposit.
     * @param mantissa The house edge taken from each deposit expressed as a percentage mantissa (8 decimal places).
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
     * @return minBlocksPerRound The min length a lottery round can be, in blocks.
     */
    function getMinBlocksPerRound() public view returns(uint256) {
        return minBlocksPerRound;
    }

    /**
     * @return prizePool The total prize pool for the current lottery round.
     */
    function getCurrentRoundPool() public view returns(uint256) {
        return rounds[rounds.length - 1].totalPool;
    }

    /**
     * @return roundStart The block the current lottery round started on.
     */
    function getCurrentRoundStart() public view returns(uint256) {
        return rounds[rounds.length - 1].startingBlock;
    }

    /**
     * @return roundEnd The earliest block on which the current lottery round can end.
     *
     * NOTE: To actually end the round, triggerRoundEnd() needs to be called after roundEnd has pasted.
     */
    function getCurrentRoundEnd() public view returns(uint256) {
        return rounds[rounds.length - 1].endingBlock;
    }

    /**
     * @return houseEdgeMantissa The house edge for each deposit.
     */
    function getHouseEdge() public view returns(uint256) {
        return houseEdgeMantissa;
    }

    /**
     * @return totalProfit The total contract profit since inception.
     */
    function getTotalContractProfit() public view returns(uint256) {
        return totalContractProfit;
    }

    /**
     * @return totalDeposit The total amount the given entrant has deposited in the current lottery round.
     */
    function getEntrantsCurrentDeposit(address entrant) public view returns(uint256) {
        uint256 i = entrantIndices[entrant];
        Entry[] memory entries = rounds[rounds.length - 1].entries;
        if (i >= entries.length  || entries[i].entrant != entrant) {
            return 0;
        } else {
            return entries[i].totalDeposit;
        }
    }

    /**
     * @return entries All entries in the current lottery round.
     */
    function getAllCurrentRoundEntries() public view returns(Entry[] memory) {
        return rounds[rounds.length - 1].entries;
    }

    /**
     * @return currentRoundIndex The index of the current round.
     */
    function getCurrentRoundIndex() public view returns(uint256) {
        return rounds.length - 1;
    }

    /**
     * @return currentRound A struct representing the current lottery round.
     */
    function getCurrentRound() public view returns(Round memory) {
        return rounds[rounds.length - 1];
    }

}

// File: contracts/LotteryERC20.sol

pragma solidity ^0.8.4;
contract LotteryERC20 is LotteryBase {
    using SafeERC20 for IERC20;

    IERC20 private token;

    constructor(RandomnessProvider randomnessProviderIn, IERC20 tokenIn, uint256 roundLengthIn)
        LotteryBase(randomnessProviderIn, roundLengthIn) {
        
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

// File: contracts/LotteryUSDC.sol

pragma solidity ^0.8.4;
/**
 * This is the exact same as LotteryERC20, it only exists to make it easier for Truffle to deploy and keep
 * track of duplicate contracts.
 * It is intended to be used for a Lottery where deposits are made in USDC tokens.
 */
contract LotteryUSDC is LotteryERC20 {
    constructor(RandomnessProvider randomnessProviderIn, IERC20 tokenIn, uint256 roundLengthIn)
        LotteryERC20(randomnessProviderIn, tokenIn, roundLengthIn) {

    }
}