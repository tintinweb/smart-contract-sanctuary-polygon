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

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

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
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

/**
 * @title Roulether
 * @notice Roulether v3, extended with ChainLink VRF v2 for a provably fair and verifiable random draws
 *
 * Created with <3
 */
contract Roulether is VRFConsumerBaseV2, ReentrancyGuard, Ownable {
	/***************
    STATE
	***************/
	VRFCoordinatorV2Interface immutable COORDINATOR;

	// Max gas price to bump to.
	bytes32 keyHash;
	// Callback gas limit
	uint32 callbackGasLimit = 500000;
	// Request confirmations
	uint16 requestConfirmations = 3;

	// Storage parameters
	uint64 public subscriptionId;

	// Number of equiprobable outcomes in a game:
	uint constant MAX_MODULO = 100;

	// Modulos below MAX_MASK_MODULO are checked against a bit mask, allowing betting on specific outcomes.
	// For example in a dice roll (modolo = 6),

	// 000001 mask means betting on 1. 000001 converted from binary to decimal becomes 1.
	// 101000 mask means betting on 4 and 6. 101000 converted from binary to decimal becomes 40.
	// The specific value is dictated by the fact that 256-bit intermediate
	// multiplication result allows implementing population count efficiently
	// for numbers that are up to 42 bits, and 40 is the highest multiple of
	// eight below 42.
	uint constant MAX_MASK_MODULO = 40;

	// This is a check on bet mask overflow. Maximum mask is equivalent to number of possible binary outcomes for maximum modulo.
	uint constant MAX_BET_MASK = 2 ** MAX_MASK_MODULO;

	// These are constants taht make O(1) population count in placeBet possible.
	uint constant POPCNT_MULT = 0x0000000000002000000000100000000008000000000400000000020000000001;
	uint constant POPCNT_MASK = 0x0001041041041041041041041041041041041041041041041041041041041041;
	uint constant POPCNT_MODULO = 0x3F;

	// Sum of all historical deposits and withdrawals. Used for calculating profitability. Profit = Balance - accDeposits + accWithdrawals
	uint public accDeposits;
	uint public accWithdrawals;

	// House edge on win
	uint public houseEdgePercent = 1;

	// In addition to house edge, wealth tax is added every time the bet amount exceeds a multiple of a threshold.
	// For example, if wealthTaxIncrementThreshold = 150 ether,
	// A bet amount of 150 ether will have a wealth tax of 1% in addition to house edge.
	// A bet amount of 300 ether will have a wealth tax of 2% in addition to house edge.
	uint public wealthTaxIncrementThreshold = 150 ether;
	uint public wealthTaxIncrementPercent = 1;

	// The minimum and maximum bets
	uint public minBetAmount = 1 ether;
	uint public maxBetAmount = 100 ether;

	// max bet profit. Used to cap bets against dynamic odds.
	uint public maxProfit = 3000 ether;

	// Funds that are locked in potentially winning bets. Prevents contract from committing to new bets that it cannot pay out.
	uint public lockedInBets;

	// Availability of the game
	bool public ready;

	// Info of each bet.
	struct Bet {
		// Wager amount in wei.
		uint256 amount;
		// Modulo of a game.
		uint8 modulo;
		// Number of winning outcomes, used to compute winning payment (* modulo/rollUnder),
		// and used instead of mask for games with modulo > MAX_MASK_MODULO.
		uint8 rollUnder;
		// Bit mask representing winning bet outcomes (see MAX_MASK_MODULO comment).
		uint40 mask;
		// Block number of placeBet tx.
		uint256 placeBlockNumber;
		// Address of a user, used to pay out winning bets.
		address user;
		// Status of bet settlement.
		bool isSettled;
		// Outcome of bet.
		uint256 outcome;
		// Win amount.
		uint256 winAmount;
		// Random number used to settle bet.
		uint256 randomNumber;
	}

	// Store Number of bets
	uint public betsCount;

	// Mapping requestId returned by Chainlink VRF to bet Id
	mapping(uint256 => uint256) public betMap; /* requestId */ /* betId */
	// Mapping bet Id to Request
	mapping(uint256 => Bet) public bets; /* betId */ /* Request */

	/***************
    EVENTS
    ***************/
	/**
	 * @notice Emitted when a user request to play
	 * @param betId Id for the bet
	 * @param requestId Id for the Chainlink request
	 * @param user Address of the user
	 */
	event BetPlaced(uint indexed betId, uint indexed requestId, address indexed user);

	/**
	 * @notice Emitted when ChainLink responds back with the random number and when the bet is settled.
	 * @param betId Id for the bet
	 * @param user Address of the user
	 * @param amount Amount of the bet
	 * @param modulo Modulo of the bet
	 * @param rollUnder Rollunder of the bet
	 * @param mask Mask of the bet
	 * @param outcome Outcome of the bet
	 * @param winAmount Wina mount of the bet
	 */
	event BetSettled(
		uint indexed betId,
		address indexed user,
		uint amount,
		uint8 indexed modulo,
		uint8 rollUnder,
		uint40 mask,
		uint outcome,
		uint winAmount
	);

	/**
	 * @notice Emitted when user gets the refund
	 * @param requestId Id for the request
	 * @param user Address of the user
	 */
	event BetRefunded(uint256 indexed requestId, address user);

	/**
	 * @notice Constructor inherits ERRC721 and VRFConsumerBaseV2
	 *
	 * @param _vrfCoordinator VRF Coordinator address
	 * @param _keyHash The gas lane to use, which specifies the maximum gas price to bump to
	 * @param _subscriptionId The subscription ID that this contract uses for funding VRF requests
	 */
	constructor(address _vrfCoordinator, bytes32 _keyHash, uint64 _subscriptionId) VRFConsumerBaseV2(_vrfCoordinator) {
		COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
		keyHash = _keyHash;
		subscriptionId = _subscriptionId;
	}

	/// @notice Fallback payable function used to top up the bank roll.
	fallback() external payable {
		accDeposits += msg.value;
	}

	/// @notice Fallback payable function used to top up the bank roll.
	receive() external payable {
		accDeposits += msg.value;
	}

	/**
	 * @notice Settle the randomly draw through ChainLink VRF callback
	 * @param requestId ChainLink VRF request Id for the request
	 * @param randomWords Provably fair and verifiable random number
	 */
	function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
		// Get the pending request
		settleBet(requestId, randomWords[0]);
	}

	/***************
    Game methods
    ***************/

	/// @notice See Vault balance.
	function balance() external view returns (uint) {
		return address(this).balance;
	}

	/// @notice Place bet
	function placeBet(uint betMask, uint modulo) external payable nonReentrant {
		require(ready, "Game not available");
		// Validate input data.
		uint amount = msg.value;
		require(modulo > 1 && modulo <= MAX_MODULO, "Modulo should be within range");
		require(amount >= minBetAmount && amount <= maxBetAmount, "Bet amount should be within range");
		require(betMask > 0 && betMask < MAX_BET_MASK, "Mask should be within range.");

		uint rollUnder;
		uint mask;

		if (modulo <= MAX_MASK_MODULO) {
			// Small modulo games can specify exact bet outcomes via bit mask.
			// rollUnder is a number of 1 bits in this mask (population count).
			// This magic looking formula is an efficient way to compute population
			// count on EVM for numbers below 2**40.
			rollUnder = ((betMask * POPCNT_MULT) & POPCNT_MASK) % POPCNT_MODULO;
			mask = betMask;
		} else {
			// Larger modulos games specify the right edge of half-open interval of winning bet outcomes.
			require(betMask > 0 && betMask <= modulo, "High modulo range, betMask larger than modulo.");
			rollUnder = betMask;
		}

		// Winning amount.
		uint possibleWinAmount = getBetWinAmount(amount, modulo, rollUnder);

		// Enforce max profit limit. Bet will not be placed if condition is not met.
		require(possibleWinAmount <= amount + maxProfit, "maxProfit limit violation.");

		// Check whether contract has enough funds to accept this bet.
		require(
			lockedInBets + possibleWinAmount <= address(this).balance,
			"Unable to accept bet due to insufficient funds"
		);

		// Update lock funds.
		lockedInBets += possibleWinAmount;

		// Store bet in bet list
		bets[betsCount] = Bet({
			amount: amount,
			modulo: uint8(modulo),
			rollUnder: uint8(rollUnder),
			mask: uint40(mask),
			placeBlockNumber: block.number,
			user: msg.sender,
			isSettled: false,
			outcome: 0,
			winAmount: 0,
			randomNumber: 0
		});

		// Request random number from Chainlink VRF.
		// Request random tokenId from ChainLink VRF
		uint256 requestId = COORDINATOR.requestRandomWords(
			keyHash,
			subscriptionId,
			requestConfirmations,
			callbackGasLimit,
			1
		);

		// Map requestId to bet ID
		betMap[requestId] = betsCount;

		// Record bet in event logs
		emit BetPlaced(betsCount, requestId, msg.sender);

		betsCount++;
	}

	/// @notice Settle Bet.
	/// @dev Function can only be called by fulfillRandomness function, which in turn can only be called by Chainlink VRF.
	function settleBet(uint256 requestId, uint randomNumber) internal nonReentrant {
		uint betId = betMap[requestId];
		Bet storage bet = bets[betId];
		uint amount = bet.amount;

		// Validation check
		require(amount > 0, "Bet does not exist."); // Check that bet exists
		require(bet.isSettled == false, "Bet is settled already"); // Check that bet is not settled yet

		// Fetch bet parameters into local variables (to save gas).
		uint modulo = bet.modulo;
		uint rollUnder = bet.rollUnder;
		address user = bet.user;

		// Do a roll by taking a modulo of random number.
		uint outcome = randomNumber % modulo;

		// Win amount if user wins this bet
		uint possibleWinAmount = getBetWinAmount(amount, modulo, rollUnder);

		// Actual win amount by user
		uint winAmount = 0;

		// Determine dice outcome.
		if (modulo <= MAX_MASK_MODULO) {
			// For small modulo games, check the outcome against a bit mask.
			if ((2 ** outcome) & bet.mask != 0) {
				winAmount = possibleWinAmount;
			}
		} else {
			// For larger modulos, check inclusion into half-open interval.
			if (outcome < rollUnder) {
				winAmount = possibleWinAmount;
			}
		}

		// Record bet settlement in event log.
		emit BetSettled(betId, user, amount, uint8(modulo), uint8(rollUnder), bet.mask, outcome, winAmount);

		// Unlock possibleWinAmount from lockedInBets, regardless of the outcome.
		lockedInBets -= possibleWinAmount;

		// Update bet records
		bet.isSettled = true;
		bet.winAmount = winAmount;
		bet.randomNumber = randomNumber;
		bet.outcome = outcome;

		// Send win amount to user.
		if (winAmount > 0) {
			payable(user).transfer(winAmount);
		}
	}

	/// @notice Refund bet
	/// @dev Refund the bet in extremely unlikely scenario it was not settled by Chainlink VRF.
	function refundBet(uint betId) external payable nonReentrant {
		Bet storage bet = bets[betId];
		uint amount = bet.amount;

		// Validation check
		require(amount > 0, "Bet does not exist."); // Check that bet exists
		require(bet.isSettled == false, "Bet is settled already."); // Check that bet is still open
		require(block.number > bet.placeBlockNumber + 20, "Wait before requesting refund");

		uint possibleWinAmount = getBetWinAmount(amount, bet.modulo, bet.rollUnder);

		// Unlock possibleWinAmount from lockedInBets, regardless of the outcome.
		lockedInBets -= possibleWinAmount;

		// Update bet records
		bet.isSettled = true;
		bet.winAmount = amount;

		// Send the refund.
		payable(bet.user).transfer(amount);

		// Record refund in event logs
		emit BetRefunded(betId, bet.user);
	}

	/***************
    Game Helpers
	***************/

	/// @notice Get bet's possible win amount
	function getBetWinAmount(uint amount, uint modulo, uint rollUnder) private view returns (uint winAmount) {
		require(0 < rollUnder && rollUnder <= modulo, "Win probability out of range.");
		uint wealthTaxPercentage = (amount / wealthTaxIncrementThreshold) * wealthTaxIncrementPercent;
		uint houseEdge = (amount * (houseEdgePercent + wealthTaxPercentage)) / 100;
		winAmount = ((amount - houseEdge) * modulo) / rollUnder;
	}

	/***************
    Game Settings
	***************/

	/// @notice Set min bet amount. minBetAmount should be large enough such that its house edge fee can cover the Chainlink oracle fee.
	function setMinBetAmount(uint _minBetAmount) external onlyOwner {
		minBetAmount = _minBetAmount;
	}

	/// @notice Set max bet amount.
	function setMaxBetAmount(uint _maxBetAmount) external onlyOwner {
		require(_maxBetAmount < 5000000 ether, "maxBetAmount must be a sane number");
		maxBetAmount = _maxBetAmount;
	}

	/// @notice Set max bet reward. Setting this to zero effectively disables betting.
	function setMaxProfit(uint _maxProfit) external onlyOwner {
		require(_maxProfit < 50000000 ether, "maxProfit must be a sane number");
		maxProfit = _maxProfit;
	}

	/// @notice Set house edge
	function setHouseEdge(uint _houseEdgePercent) external onlyOwner {
		require(_houseEdgePercent >= 0 && _houseEdgePercent <= 100, "House edge percentage is invalid");
		houseEdgePercent = _houseEdgePercent;
	}

	/// @notice Set wealth tax percentage to be added to house edge percent. Setting this to zero effectively disables wealth tax.
	function setWealthTaxIncrementPercent(uint _wealthTaxIncrementPercent) external onlyOwner {
		wealthTaxIncrementPercent = _wealthTaxIncrementPercent;
	}

	/// @notice Set threshold to trigger wealth tax.
	function setWealthTaxIncrementThreshold(uint _wealthTaxIncrementThreshold) external onlyOwner {
		wealthTaxIncrementThreshold = _wealthTaxIncrementThreshold;
	}

	/***************
    Owner methods
	***************/

	/// @dev Toggle the status of the game
	function toggleStatus(bool _ready) external onlyOwner {
		ready = _ready;
	}

	/// @notice Withdraw ETH from this contract
	function withdraw(uint withdrawAmount) external onlyOwner {
		require(withdrawAmount <= address(this).balance, "Withdrawal amount larger than balance.");
		require(
			withdrawAmount <= address(this).balance - lockedInBets,
			"Withdrawal amount larger than balance minus lockedInBets"
		);
		payable(msg.sender).transfer(withdrawAmount);
		accWithdrawals += withdrawAmount;
	}

	/// @notice Withdraw ERC20 tokens
	/// @dev Withdraws any ERC20 that landed on the contract
	function withdrawERC20(address token_address) external onlyOwner {
		IERC20(token_address).transfer(owner(), IERC20(token_address).balanceOf(address(this)));
	}

	/***************
    Chainlink VRF settings
	***************/

	/// @notice Handle the ChainLink VRF subscription specs
	function handleSubscription(
		uint64 _subscriptionId,
		bytes32 _keyHash,
		uint32 _callbackGasLimit,
		uint16 _requestConfirmations
	) external onlyOwner {
		subscriptionId = _subscriptionId;
		keyHash = _keyHash;
		callbackGasLimit = _callbackGasLimit;
		requestConfirmations = _requestConfirmations;
	}
}