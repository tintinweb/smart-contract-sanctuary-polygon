/**
 *Submitted for verification at polygonscan.com on 2022-11-12
*/

// File: interfaces/IDominationGame.sol


pragma solidity 0.8.17;

enum GameStage {
    Submit,
    Reveal,
    Resolve,
    PendingWithdrawals,
    Finished
}

struct Player {
    address addr;
    address nftAddress;
    uint256 tokenId;
    uint256 balance;
    uint256 lastMoveTimestamp;
    uint256 allianceId;
    uint256 hp;
    uint256 attack;
    uint256 x;
    uint256 y;
    bytes32 pendingMoveCommitment;
    bytes pendingMove;
    bool inJail;
}

struct Alliance {
    address admin;
    uint256 id;
    uint256 activeMembersCount; // if in Jail, not active
    uint256 membersCount;
    uint256 maxMembers;
    uint256 totalBalance; // used for calc cut of spoils in win condition
    string name;
}

struct JailCell {
    uint256 x;
    uint256 y;
}

interface IDominationGame {
    error LoserTriedWithdraw();
    error OnlyWinningAllianceMember();

    event AttemptJailBreak(address indexed who, uint256 x, uint256 y);
    event AllianceCreated(address indexed admin, uint256 indexed allianceId, string name);
    event AllianceMemberJoined(uint256 indexed allianceId, address indexed player);
    event AllianceMemberLeft(uint256 indexed allianceId,address indexed player);
    event BadMovePenalty(uint256 indexed turn, address indexed player, bytes details);
    event BattleCommenced(address indexed player1, address indexed defender);
    event BattleFinished(address indexed winner, uint256 indexed spoils);
    event BattleStalemate(uint256 indexed attackerHp, uint256 indexed defenderHp);
    event CheckingWinCondition(uint256 indexed activeAlliancesCount, uint256 indexed  activePlayersCount);
    event Constructed(address indexed owner, uint64 indexed subscriptionId, uint256 indexed _gameStartTimestamp);
    event DamageDealt(address indexed by, address indexed to, uint256 indexed amount);
    event GameStartDelayed(uint256 indexed newStartTimeStamp);
    event GameFinished(uint256 indexed turn, uint256 indexed winningTeamTotalSpoils);
    event Fallback(uint256 indexed value, uint256 indexed gasLeft);
    event Jail(address indexed who, uint256 indexed inmatesCount);
    event JailBreak(address indexed who, uint256 newInmatesCount);
    event Joined(address indexed addr);
    event Move(address indexed who, uint newX, uint newY);
    event NewGameStage(GameStage indexed newGameStage, uint256 indexed turn);
    event NftConfiscated(address indexed who, address indexed nftAddress, uint256 indexed tokenId);
    event NoReveal(address indexed who, uint256 indexed turn);
    event NoSubmit(address indexed who, uint256 indexed turn);
    event Received(uint256 indexed value, uint256 indexed gasLeft);
    event Rest(address indexed who, uint256 indexed x, uint256 indexed y);
    event ReturnedRandomness(uint256[] randomWords);
    event Revealed(address indexed addr, uint256 indexed turn, bytes32 nonce, bytes data);
    event RolledDice(uint256 indexed turn, uint256 indexed vrf_request_id);
    event SkipInmateTurn(address indexed who, uint256 indexed turn);
    event Submitted(address indexed addr, uint256 indexed turn, bytes32 commitment);
    event TurnStarted(uint256 indexed turn, uint256 timestamp);
    event UpkeepCheck(uint256 indexed currentTimestamp, uint256 indexed lastUpkeepTimestamp, bool indexed upkeepNeeded);
    event WinnerPlayer(address indexed winner);
    event WinnerAlliance(uint indexed allianceId);
    event WinnerWithdrawSpoils(address indexed winner, uint256 indexed spoils);
    
    function alliances(uint256 allianceId) external view returns (address, uint256, uint256, uint256, uint256, uint256, string memory);
    function connect(uint256 tokenId, address byoNft) external payable;
    function createAlliance(address player, uint256 maxMembers, string calldata name) external;
    function currentTurn() external view returns (uint256);
    function currentTurnStartTimestamp() view external returns (uint256);
    function gameStarted() view external returns (bool);
    function gameStage() view external returns (GameStage);
    function interval() view external returns (uint256);
    function joinAlliance(address player, uint256 allianceId, uint8 v, bytes32 r, bytes32 s) external;
    function move(address player, int8 direction) external;
    function nextAvailableAllianceId() view external returns (uint256);
    function players(address player) view external returns (address, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, bytes32, bytes memory, bool);
    function spoils(address who) external returns (uint256);
    function submit(uint256 turn, bytes32 commitment) external;
    function reveal(uint256 turn, bytes32 nonce, bytes calldata data) external;
    function withdrawWinnerAlliance() external;
    function withdrawWinnerPlayer() external;
    function winnerAllianceId() external view returns (uint256);
}



// File: https://github.com/smartcontractkit/chainlink-brownie-contracts/contracts/src/v0.8/VRFConsumerBaseV2.sol


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

// File: https://github.com/smartcontractkit/chainlink-brownie-contracts/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol


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

// File: https://github.com/smartcontractkit/chainlink-brownie-contracts/contracts/src/v0.8/interfaces/LinkTokenInterface.sol


pragma solidity ^0.8.0;

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

// File: https://github.com/smartcontractkit/chainlink-brownie-contracts/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol


pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// File: https://github.com/smartcontractkit/chainlink-brownie-contracts/contracts/src/v0.8/AutomationBase.sol


pragma solidity ^0.8.0;

contract AutomationBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// File: https://github.com/smartcontractkit/chainlink-brownie-contracts/contracts/src/v0.8/AutomationCompatible.sol


pragma solidity ^0.8.0;



abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/contracts/utils/math/Math.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;


/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;


/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/contracts/utils/structs/EnumerableMap.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableMap.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableMap.js.

pragma solidity ^0.8.0;


/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * The following map types are supported:
 *
 * - `uint256 -> address` (`UintToAddressMap`) since v3.0.0
 * - `address -> uint256` (`AddressToUintMap`) since v4.6.0
 * - `bytes32 -> bytes32` (`Bytes32ToBytes32Map`) since v4.6.0
 * - `uint256 -> uint256` (`UintToUintMap`) since v4.7.0
 * - `bytes32 -> uint256` (`Bytes32ToUintMap`) since v4.7.0
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableMap, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableMap.
 * ====
 */
library EnumerableMap {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct Bytes32ToBytes32Map {
        // Storage of keys
        EnumerableSet.Bytes32Set _keys;
        mapping(bytes32 => bytes32) _values;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        bytes32 value
    ) internal returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToBytes32Map storage map, bytes32 key) internal returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool) {
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function length(Bytes32ToBytes32Map storage map) internal view returns (uint256) {
        return map._keys.length();
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToBytes32Map storage map, uint256 index) internal view returns (bytes32, bytes32) {
        bytes32 key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool, bytes32) {
        bytes32 value = map._values[key];
        if (value == bytes32(0)) {
            return (contains(map, key), bytes32(0));
        } else {
            return (true, value);
        }
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), "EnumerableMap: nonexistent key");
        return value;
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), errorMessage);
        return value;
    }

    // UintToUintMap

    struct UintToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToUintMap storage map,
        uint256 key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToUintMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToUintMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToUintMap storage map, uint256 index) internal view returns (uint256, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(UintToUintMap storage map, uint256 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToUintMap storage map, uint256 key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(key)));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToUintMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(key), errorMessage));
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToAddressMap storage map,
        uint256 key,
        address value
    ) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToAddressMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key), errorMessage))));
    }

    // AddressToUintMap

    struct AddressToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        AddressToUintMap storage map,
        address key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, bytes32(uint256(uint160(key))), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(AddressToUintMap storage map, address key) internal returns (bool) {
        return remove(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(AddressToUintMap storage map, address key) internal view returns (bool) {
        return contains(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(AddressToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressToUintMap storage map, uint256 index) internal view returns (address, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (address(uint160(uint256(key))), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(AddressToUintMap storage map, address key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(uint256(uint160(key))));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(AddressToUintMap storage map, address key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        AddressToUintMap storage map,
        address key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key))), errorMessage));
    }

    // Bytes32ToUintMap

    struct Bytes32ToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToUintMap storage map,
        bytes32 key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, key, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToUintMap storage map, bytes32 key) internal returns (bool) {
        return remove(map._inner, key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool) {
        return contains(map._inner, key);
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(Bytes32ToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToUintMap storage map, uint256 index) internal view returns (bytes32, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (key, uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, key);
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToUintMap storage map, bytes32 key) internal view returns (uint256) {
        return uint256(get(map._inner, key));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        Bytes32ToUintMap storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, key, errorMessage));
    }
}

// File: DominationGame.sol


pragma solidity 0.8.17;










contract DominationGame is IERC721Receiver, AutomationCompatible, VRFConsumerBaseV2, IDominationGame {
     using EnumerableMap for EnumerableMap.UintToAddressMap;
    using EnumerableMap for EnumerableMap.AddressToUintMap;
    // TODO: get rid of this in favor of governance
    address public admin;
    JailCell public jailCell;
    mapping(address => Player) public players;
    mapping(uint256 => mapping(uint256 => address)) public playingField;
    mapping(uint256 => Alliance) public alliances;
    mapping(uint256 => address[]) public allianceMembers;
    EnumerableMap.UintToAddressMap internal allianceAdmins;
    EnumerableMap.UintToAddressMap private activePlayers;
    mapping(address => uint256) public spoils;

    // Keepers
    uint256 public interval;
    uint256 public lastUpkeepTimestamp;
    uint256 public gameStartTimestamp;
    bool public gameStarted;
    bool public gameEnded;

    // VRF
    VRFCoordinatorV2Interface immutable COORDINATOR;
    LinkTokenInterface immutable LINKTOKEN;
    address internal vrf_owner;
    uint256 internal randomness;
    uint256 public vrf_requestId;
    bytes32 immutable vrf_keyHash;
    uint16 immutable vrf_requestConfirmations = 3;
    uint32 immutable vrf_callbackGasLimit = 500_000;
    uint32 immutable vrf_numWords = 1;
    uint64 internal vrf_subscriptionId;

    // Game
    uint256 public currentTurn;
    uint256 public currentTurnStartTimestamp;
    uint256 public constant maxPlayers = 100;
    uint256 public activePlayersCount;
    uint256 public activeAlliancesCount;
    uint256 public winningTeamSpoils;
    uint256 public nextAvailableRow; // TODO make random to prevent position sniping...?
    uint256 public nextAvailableCol;
    uint256 public winnerAllianceId;
    uint256 public fieldSize;
    uint256 internal nextInmateId;
    uint256 internal inmatesCount;
    uint256 public nextAvailableAllianceId = 1; // start at 1 because 0 means you ain't joined one yet
    address public winnerPlayer;
    address[] public inmates = new address[](maxPlayers);
    
    GameStage public gameStage;
    
    modifier onlyGame() {
        require(msg.sender == address(this), "Only callable by game contract");
        _;
    }

    modifier onlyOwnerAndSelf() {
        require(msg.sender == vrf_owner || msg.sender == address(this));
        _;
    }

    modifier onlyWinningAllianceMember() {
        require(winnerAllianceId != 0, "Only call this if an alliance has won.");
        
        address[] memory winners = allianceMembers[winnerAllianceId];

        bool winnerFound = false;

        for(uint i = 0; i < winners.length; i++) {
            if (winners[i] == msg.sender) {
                winnerFound = true;
            }
        }
        
        if (winnerFound) {
            _;
        }  else {
            revert OnlyWinningAllianceMember();
        }
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this");
        _;
    }

    modifier onlyWinner() {
        if (winnerPlayer == address(this)) {
            require(msg.sender == admin, "Only admin can withdraw if game was the ultimate winner.");
        } else {
            require(msg.sender == winnerPlayer, "Only winner can call this");
        }
        _;
    }

    modifier onlyViaSubmitReveal() {
        require(msg.sender == address(this), "Only via submit/reveal");
        _;
    }

    constructor(uint256 updateInterval) VRFConsumerBaseV2(0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed) {
        // FIXME with governance
        admin = msg.sender;
        fieldSize = maxPlayers; // also the max players

        // VRF
        COORDINATOR = VRFCoordinatorV2Interface(0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed);
        LINKTOKEN = LinkTokenInterface(0x326C977E6efc84E512bB9C30f76E30c160eD06FB);
        vrf_keyHash = 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;
        vrf_owner = msg.sender;
        vrf_subscriptionId = 1374;

        // Keeper
        interval = updateInterval;
        lastUpkeepTimestamp = block.timestamp;
        gameStartTimestamp = block.timestamp + updateInterval * 2;

        emit Constructed(vrf_owner, vrf_subscriptionId, gameStartTimestamp);
    }

    function connect(uint256 tokenId, address byoNft) external payable {
        require(currentTurn == 0, "Already started");
        require(spoils[msg.sender] == 0, "Already joined");
        require(players[msg.sender].addr == address(0), "Already joined");
        require(activePlayersCount < maxPlayers, "Already at max players");
        // Your share of the spoils if you win as part of an alliance are proportional to how much you paid to connect.
        require(msg.value > 0, "Send some eth");

        // Verify Ownership
        uint256 nftBalance = IERC721(byoNft).balanceOf(msg.sender);
        require(nftBalance > 0, "You dont own this NFT you liar");

        // Approve for confiscation if misbehave during game
        IERC721(byoNft).setApprovalForAll(address(this), true);

        Player memory player = Player({
            addr: msg.sender,
            nftAddress: byoNft,
            balance: msg.value, // balance can be used to buy items/powerups in the marketplace
            tokenId: tokenId,
            lastMoveTimestamp: block.timestamp,
            allianceId: 0,
            hp: 1000,
            attack: 10,
            x: nextAvailableCol,
            y: nextAvailableRow,
            pendingMoveCommitment: bytes32(0),
            pendingMove: "",
            inJail: false
        });

        playingField[nextAvailableRow][nextAvailableCol] = msg.sender;
        spoils[msg.sender] = msg.value;
        players[msg.sender] = player;
        activePlayers.set(activePlayersCount + 1, msg.sender);

        activePlayersCount += 1;
        nextAvailableCol = (nextAvailableCol + 2) % fieldSize;
        nextAvailableRow = nextAvailableCol == 0 ? nextAvailableRow + 1 : nextAvailableRow;

        emit Joined(msg.sender);
    }

    function start() public {
        require(currentTurn == 0, "Already started");
        require(activePlayersCount > 1, "Not enough players");
        require(randomness != 0, "Need randomness for jail cell");

        currentTurn = 1;
        currentTurnStartTimestamp = block.timestamp;
        gameStarted = true;
        gameStage = GameStage.Submit;
        emit NewGameStage(GameStage.Submit, currentTurn);

        jailCell = JailCell({ x: randomness / 1e75, y: randomness % 99 });

        emit TurnStarted(currentTurn, currentTurnStartTimestamp);
    }

    function submit(uint256 turn, bytes32 commitment) external {
        require(currentTurn > 0, "Not started");
        require(turn == currentTurn, "Stale tx");
        // submit stage is interval set by deployer
        require(gameStage == GameStage.Submit, "Only callable during the Submit Game Stage");

        players[msg.sender].pendingMoveCommitment = commitment;

        emit Submitted(msg.sender, currentTurn, commitment);
    }

    function reveal(
        uint256 turn,
        bytes32 nonce,
        bytes calldata data
    ) external {
        require(turn == currentTurn, "Stale tx");
        require(gameStage == GameStage.Reveal, "Only callable during the Reveal Game Stage");

        bytes32 commitment = players[msg.sender].pendingMoveCommitment;
        bytes32 proof = keccak256(abi.encodePacked(turn, nonce, data));

        require(commitment == proof, "No cheating");

        players[msg.sender].pendingMove = data;

        emit Revealed(msg.sender, currentTurn, nonce, data);
    }

    // (-1, 1) = (up, down)
    // (-2, 2) = (left, right)
    function move(address player, int8 direction) external onlyViaSubmitReveal {
        Player storage invader = players[player];
        uint256 newX = invader.x;
        uint256 newY = invader.y;

        for (int8 i = -2; i <= 2; i++) {
            if (i == 0) { continue; }
            if (direction == i) {
                if (direction > 0) { // down, right
                    newX = direction == 2 ? uint(int(invader.x) + direction - 1) % fieldSize : invader.x;
                    newY = direction == 1 ? uint(int(invader.y) + direction) % fieldSize : invader.y;
                    require(
                        direction == 2
                            ? newX <= fieldSize
                            : newY <= fieldSize
                        );
                } else { // up, left
                    newX = direction == -2 ? uint(int(invader.x) + direction + 1)  % fieldSize : invader.x;
                    newY = direction == -1 ? uint(int(invader.y) + direction) % fieldSize: invader.y;
                    require( 
                        direction == 1
                            ? newX >= 0
                            : newY >= 0
                    );
                }
                break;
            }
        }

        address currentOccupant = playingField[newX][newY];
        if (newX == jailCell.x && newY == jailCell.y) {
            emit AttemptJailBreak(msg.sender, jailCell.x, jailCell.y);
            _jailbreak(msg.sender);
        }

        if (_checkIfCanAttack(invader.addr, currentOccupant)) {
            _battle(player, currentOccupant);
        } else {
            playingField[invader.x][invader.y] = address(0);
            invader.x = newX;
            invader.y = newY;
        }

        playingField[invader.x][invader.y] = player;
        emit Move(invader.addr, invader.x, invader.y);        
    }

    function rest(address player) external onlyViaSubmitReveal {
        players[player].hp += 2;
        emit Rest(players[player].addr, players[player].x, players[player].y);
    }

    function createAlliance(address player, uint256 maxMembers, string calldata name) external onlyViaSubmitReveal {
        require(players[player].allianceId == 0, "Already in alliance");

        players[player].allianceId = nextAvailableAllianceId;
        allianceAdmins.set(nextAvailableAllianceId, player);

        Alliance memory newAlliance = Alliance({
            admin: player,
            id: nextAvailableAllianceId,
            activeMembersCount: 1,
            membersCount: 1,
            maxMembers: maxMembers,
            totalBalance: players[player].balance,
            name: name
        });
        if (allianceMembers[nextAvailableAllianceId].length > 0) {
            allianceMembers[nextAvailableAllianceId].push(player);
        } else {
            allianceMembers[nextAvailableAllianceId] = [player];
        }
        alliances[nextAvailableAllianceId] = newAlliance;
        nextAvailableAllianceId += 1;
        activeAlliancesCount += 1;

        emit AllianceCreated(player, nextAvailableAllianceId, name);
    }

    function joinAlliance(
        address player,
        uint256 allianceId,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external onlyViaSubmitReveal {

        // Admin must sign the application off-chain. Applications are per-move based, so the player
        // can't reuse the application from the previous move
        bytes memory application = abi.encodePacked(currentTurn, allianceId);

        bytes32 hash = keccak256(application);
        // address admin = ECDSA.recover(hash, signature
        address allianceAdmin = ecrecover(hash, v, r, s);

        require(allianceAdmins.get(allianceId) == allianceAdmin, "Not signed by admin");
        players[player].allianceId = allianceId;
        
        Alliance memory alliance = alliances[allianceId];
        
        require(alliance.membersCount < alliance.maxMembers - 1, "Cannot exceed max members count.");

        alliances[allianceId].activeMembersCount += 1;
        alliances[allianceId].membersCount += 1;
        alliances[allianceId].totalBalance += players[player].balance;
        if (allianceMembers[allianceId].length > 0) {
            allianceMembers[allianceId].push(player);
        } else {
            allianceMembers[allianceId] = [player];
        }

        emit AllianceMemberJoined(players[player].allianceId, player);
    }

    function leaveAlliance(address player) external onlyViaSubmitReveal {
        uint256 allianceId = players[player].allianceId;
        require(allianceId != 0, "Not in alliance");
        require(player != allianceAdmins.get(players[player].allianceId), "Admin canot leave alliance");

        players[player].allianceId = 0;
        
        for (uint256 i = 0; i < alliances[allianceId].membersCount; i++) {
            if (allianceMembers[allianceId][i] == player) {
                delete allianceMembers[i];
            }
        }

        alliances[allianceId].membersCount -= 1;
        alliances[allianceId].activeMembersCount -= 1;
        alliances[allianceId].totalBalance -= players[player].balance;

        if (alliances[allianceId].membersCount <= 1) {
            _destroyAlliance(allianceId);
        }

        emit AllianceMemberLeft(allianceId, player);
    }
    
    function withdrawWinnerAlliance() onlyWinningAllianceMember external {
        uint256 winningAllianceTotalBalance = alliances[winnerAllianceId].totalBalance;
        uint256 withdrawerBalance = players[msg.sender].balance;
        uint256 myCut = (withdrawerBalance * winningTeamSpoils) / winningAllianceTotalBalance;

        (bool sent, ) = msg.sender.call{ value: myCut }("");

        require(sent, "Failed to withdraw spoils");

        gameStage = GameStage.Finished;
        emit GameFinished(currentTurn, winningTeamSpoils);
    }

    function withdrawWinnerPlayer() onlyWinner external {
        if (winnerPlayer == address(this) || winnerPlayer == address(admin)) {
            (bool sent, ) = winnerPlayer.call{ value: address(this).balance }("");
            require(sent, "Failed to withdraw winnings");
        }

        (bool sent, ) = winnerPlayer.call{ value: spoils[winnerPlayer] }("");
        require(sent, "Failed to withdraw winnings");
        spoils[winnerPlayer] = 0;
        emit WinnerWithdrawSpoils(winnerPlayer, spoils[winnerPlayer]);
        gameStage = GameStage.Finished;
        emit GameFinished(currentTurn, winningTeamSpoils);
    }

    /**** Internal Functions *****/
    function _handleBattleLoser(address _loser, address _winner) internal {
        Player storage loser = players[_loser];
        Player storage winner = players[_winner];

        // Winner moves into Loser's old spot
        winner.x = loser.x;
        winner.y = loser.y;
        playingField[winner.x][winner.y] = winner.addr;

        // Loser vacates current position and then moves to jail 
        playingField[loser.x][loser.y] = address(0);
        _sendToJail(loser.addr);

        // Winner takes Loser's spoils
        spoils[winner.addr] += spoils[loser.addr];
        spoils[loser.addr] = 0;
        
        // Case: Winner was in an Alliance
        if (winner.allianceId != 0) {
            Alliance storage attackerAlliance = alliances[winner.allianceId];
            attackerAlliance.totalBalance += spoils[loser.addr];
        }

        // Case: Loser was not in an Alliance
        if (loser.allianceId == 0) {
            _checkWinCondition();
        } else { 
            // Case: Loser was in an Alliance
            
             // Also will need to leave the alliance cuz ded
            Alliance storage loserAlliance = alliances[loser.allianceId];
            loserAlliance.totalBalance -= spoils[loser.addr];
            loserAlliance.membersCount -= 1;
            loserAlliance.activeMembersCount -= 1;
            loser.allianceId = 0;

            if (loserAlliance.membersCount <= 1) {
                // if you're down to one member, ain't no alliance left
                _destroyAlliance(loser.allianceId);
            }

            _checkWinCondition();
        }
    }

    function _destroyAlliance(uint256 allianceId) internal {
    // if you're down to one member, ain't no alliance left
        activeAlliancesCount -= 1;
        delete alliances[allianceId];
        allianceAdmins.set(allianceId, address(0));
    }

    // If one player remains, they get the spoils
    // If no one remains, the contract gets the spoils
    function _declareWinner(address who) internal {
        winnerPlayer = who;
        emit WinnerPlayer(who);
        gameStarted = false;
        gameStage = GameStage.PendingWithdrawals;
        emit NewGameStage(GameStage.PendingWithdrawals, currentTurn);
    }
    
    // If an alliance won
    function _declareWinner(uint256 _winnerAllianceId) internal {
        winnerAllianceId = _winnerAllianceId;
        emit WinnerAlliance(_winnerAllianceId);
        _calcWinningAllianceSpoils();
        gameStarted = false;
        gameStage = GameStage.PendingWithdrawals;
        emit NewGameStage(GameStage.PendingWithdrawals, currentTurn);
    }

    function _checkWinCondition() internal {
        emit CheckingWinCondition(activeAlliancesCount, activePlayersCount);

        if (activeAlliancesCount == 1) {
            for (uint256 i = 1; i <= nextAvailableAllianceId; i++) {
                if (alliances[i].activeMembersCount == activePlayersCount) {
                    _declareWinner(alliances[i].id);
                    break;
                }
            }
        } else {
            address who;
            if (activePlayersCount == 1) {
                for (uint256 i = 1; i < activePlayersCount; i++) {
                    if (activePlayers.get(i) != address(0)) {
                        who = activePlayers.get(i);
                        break;
                    }
                }
            } else if (activePlayersCount == 0) {
                who = address(this);
            }
            if (who != address(0)) {
                _declareWinner(who);
            }
        }
    }

    function _calcWinningAllianceSpoils() internal {
        require(winnerAllianceId != 0);
        
        address[] memory winners = allianceMembers[winnerAllianceId];

        uint256 totalSpoils = 0;

        for (uint256 i = 0; i < winners.length; i++) {
            totalSpoils += spoils[winners[i]];
        }

        winningTeamSpoils = totalSpoils;
    }

    function _jailbreak(address breakerOuter) internal {
        // if it's greater than threshold everybody get out, including non alliance members
        if (randomness % 99 > 50) {
            for (uint256 i = 0; i < inmates.length; i++) {
                address inmate = inmates[i];
                if (inmate != address(0)) {
                    _freeFromJail(inmate, i);
                }
            }
            inmates = new address[](maxPlayers); // everyone broke free so just reset
        } else {
            // if lower then roller gets jailed as well lol
            _sendToJail(breakerOuter);
        }
    }

    // N.b right now the scope is to just free if somebody lands on the cell and rolls a good number.
    // could be fun to make an option for a player to bribe (pay some amount to free just alliance members)
    function _freeFromJail(address playerAddress, uint256 inmateIndex) internal {
        Player storage player = players[playerAddress];

        player.hp = 50;
        player.x = jailCell.x;
        player.y = jailCell.y;
        player.inJail = false;
        activePlayersCount += 1;

        delete inmates[inmateIndex];
        inmatesCount -= 1;

        if (player.allianceId != 0) {
            Alliance storage alliance = alliances[player.allianceId];
            alliance.activeMembersCount += 1;
        }

        emit JailBreak(player.addr, inmatesCount);
    }

    // N.B. only external/public functions have a .selector so change visibiltiy or call it another way.
    function _sendToJail(address playerAddress) public onlyGame {
        Player storage player = players[playerAddress];

        player.hp = 0;
        player.x = jailCell.x;
        player.y = jailCell.y;
        player.inJail = true;
        activePlayersCount -= 1;
        inmates[nextInmateId] = player.addr;
        nextInmateId += 1;
        inmatesCount += 1;

        if (player.allianceId != 0) {
            Alliance storage alliance = alliances[player.allianceId];
            alliance.activeMembersCount -= 1;
        }

        emit Jail(player.addr, inmatesCount);
    }

    function _checkIfCanAttack(address meAddr, address otherGuyAddr) internal view returns (bool) {
        Player memory me = players[meAddr];
        Player memory otherGuy = players[otherGuyAddr];

        if (otherGuyAddr == address(0)) { // other guy is address(0)
            return false;
        } else if (otherGuy.allianceId == 0) { // other guy not in an alliance
            return true;
        } else if (me.allianceId == otherGuy.allianceId) { // we're in the same alliance
            return false;
        } else if (otherGuy.allianceId != me.allianceId) { // the other guy is in some alliance but we're not in the same alliance
            return true;
        } else {
            return false;
        }
    }

    /**
        @param attackerAddr the player who initiates the battle by caling move() into the defender's space
        @param defenderAddr the player who just called rest() minding his own business, or just was unfortunate in the move order, i.e. PlayerA and PlayerB both move to Cell{1,3} but if PlayerA is there first, he will have to defend.

        In reality they both attack each other but the attacker will go first.
     */
    function _battle(address attackerAddr, address defenderAddr) internal {
        require(attackerAddr != defenderAddr, "Cannot fight yourself");

        Player memory attacker = players[attackerAddr];
        Player memory defender = players[defenderAddr];

        require(attacker.allianceId == 0 || defender.allianceId == 0 || attacker.allianceId != defender.allianceId, "Allies do not fight");

        emit BattleCommenced(attackerAddr, defenderAddr);

        // take randomness, multiply it against attack to get what % of total attack damange is done to opponent's hp, make it at least 1
        uint256 effectiveDamage1 = (attacker.attack / (randomness % 99)) + 1;
        uint256 effectiveDamage2 = (defender.attack / (randomness % 99)) + 1;

        // Attacker goes first. There is an importance of who goes first, because if both have an effective damage enough to kill the other, the one who strikes first would win.
       if (int(defender.hp) - int(effectiveDamage1) <= 0) {
            _handleBattleLoser(defender.addr, attacker.addr);
        } else if (int(attacker.hp) - int(effectiveDamage2) <= 0) {
            _handleBattleLoser(attacker.addr, defender.addr);
        } else {
            attacker.hp -= effectiveDamage2;
            defender.hp -= effectiveDamage1;
            emit BattleStalemate(attacker.hp, defender.hp);
        }

        if (attacker.inJail == false) {
            playingField[attacker.x][attacker.y] = attacker.addr;
        }

        if (defender.inJail == false) {
            playingField[defender.x][defender.y] = defender.addr;
        }

        emit DamageDealt(attacker.addr, defender.addr, effectiveDamage1);
        emit DamageDealt(defender.addr, attacker.addr, effectiveDamage2);
    }


    // Callbacks
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        require(vrf_requestId == requestId);

        randomness = randomWords[0];
        vrf_requestId = 0;
        emit ReturnedRandomness(randomWords);
    }

    function requestRandomWords() public {
        
        // Will revert if subscription is not set and funded.
        vrf_requestId = COORDINATOR.requestRandomWords(
        vrf_keyHash,
        vrf_subscriptionId,
        vrf_requestConfirmations,
        vrf_callbackGasLimit,
        vrf_numWords
        );
        emit RolledDice(vrf_requestId, currentTurn + 1);
    }

    function setSubscriptionId(uint64 subId) public onlyOwnerAndSelf {
        vrf_subscriptionId = subId;
    }

    function setOwner(address owner) public onlyOwnerAndSelf {
        vrf_owner = owner;
    }

    function checkUpkeep(bytes calldata) external view override returns (bool, bytes memory performData) {
        performData = bytes("");
        bool upkeepNeeded = (block.timestamp - lastUpkeepTimestamp) >= interval && gameStage != GameStage.Finished && gameStage != GameStage.PendingWithdrawals;

        if (upkeepNeeded) {
            address[] memory playersWithPendingMoves = new address[](activePlayersCount);
            bytes[] memory pendingMoveCalls = new bytes[](activePlayersCount);
            bytes[] memory confiscationCalls = new bytes[](activePlayersCount);
            bytes[] memory sendToJailCalls = new bytes[](activePlayersCount);

            for (uint256 i = 1; i <= activePlayersCount; i++) {
                Player memory player = players[activePlayers.get(i)];

                if (!player.inJail) {
                    playersWithPendingMoves[i - 1] = player.addr;
                }
                // If player straight up didn't submit then confiscate their NFT and send to jail
                if (player.pendingMoveCommitment == bytes32(0)) {
                    // emit NoSubmit(player.addr, currentTurn);
                    
                    confiscationCalls[i - 1] = abi.encodeWithSelector(
                        bytes4(
                            keccak256(
                                bytes("safeTransferFrom(address,address,uint256,bytes)"))), player.addr, address(this), player.tokenId, "");

                    sendToJailCalls[i - 1] = abi.encodeWithSelector(
                        bytes4(
                            keccak256(
                                bytes("_sendToJail(address)"))), player.addr);

                    continue;
                } else if (player.pendingMoveCommitment != bytes32(0) && player.pendingMove.length == 0) { // If player submitted but forgot to reveal, move them to jail
                    sendToJailCalls[i - 1] = abi.encodeWithSelector(
                                bytes4(
                                    keccak256(
                                        bytes("_sendToJail(address)"))), player.addr);

                    // if you are in jail but your alliance wins, you still get a cut of the spoils
                    continue;
                }

                pendingMoveCalls[i - 1] = player.pendingMove;
            }

            performData = abi.encode(playersWithPendingMoves, pendingMoveCalls, confiscationCalls, sendToJailCalls);
        }

        return (upkeepNeeded, performData);
    }

    function performUpkeep(bytes calldata performData) external override {
        if (gameStarted) {
            _checkWinCondition();
            if (gameStage == GameStage.Submit) {
                gameStage = GameStage.Reveal;
                emit NewGameStage(GameStage.Reveal, currentTurn);
            } else if (gameStage == GameStage.Reveal) {
                gameStage = GameStage.Resolve;
                emit NewGameStage(GameStage.Resolve, currentTurn);

                require(randomness != 0, "Roll the die first");

                (address[] memory playersWithPendingMoves, bytes[] memory pendingMoveCalls, bytes[] memory confiscationCalls,bytes[] memory sendToJailCalls) = abi.decode(performData, (address[], bytes[],  bytes[], bytes[]));

                for (uint256 i = 1; i <= playersWithPendingMoves.length; i++) {
                    Player memory player = players[activePlayers.get(i)];

                    if (keccak256(pendingMoveCalls[i - 1]) != keccak256(bytes(""))) {
                        (bool success, bytes memory err) = address(this).call(pendingMoveCalls[i - 1]);

                        if (!success) {
                            // Player submitted a bad move
                            if (int(player.balance - 0.05 ether) >= 0) {
                                player.balance -= 0.05 ether;
                                spoils[player.addr] = player.balance;
                                emit BadMovePenalty(currentTurn, player.addr, err);
                            } else {
                                player.balance = 0;
                                spoils[player.addr] = player.balance;
                                _sendToJail(player.addr);
                                _checkWinCondition();
                            }
                        }
                    }
                    
                    if (keccak256(confiscationCalls[i - 1]) != keccak256(bytes(""))) {
                        (bool success, ) = address(player.nftAddress).call(confiscationCalls[i - 1]);

                        if (success) {
                            emit NoSubmit(player.addr, currentTurn);
                            emit NftConfiscated(player.addr, player.nftAddress, player.tokenId);
                        }    
                    }

                    if (keccak256(sendToJailCalls[i - 1]) != keccak256(bytes(""))) {
                        (bool success, ) = address(this).call(sendToJailCalls[i - 1]);

                        if (success) {
                            emit NoReveal(player.addr, currentTurn);
                        }
                    }
                    
                    if (playersWithPendingMoves[i - 1] != address(0)) {
                        players[playersWithPendingMoves[i - 1]].pendingMove = "";
                        players[playersWithPendingMoves[i - 1]].pendingMoveCommitment = bytes32(0);
                    }   
                }
                
                currentTurn += 1;
                currentTurnStartTimestamp = block.timestamp;
                emit TurnStarted(currentTurn, currentTurnStartTimestamp);
            } else if (gameStage == GameStage.Resolve) {
                gameStage = GameStage.Submit;
                emit NewGameStage(GameStage.Submit, currentTurn);
            }
        } else {
            // check if max players or game start time reached
            if (activePlayersCount == maxPlayers || gameStartTimestamp <= block.timestamp) {
                if (activePlayersCount >= 2) {
                    start();
                } else {
                    requestRandomWords();
                    // not enough people joined then keep pushing it back till the day comes ㅠㅠ
                    gameStartTimestamp = block.timestamp + interval;
                    emit GameStartDelayed(gameStartTimestamp);
                }
            }
        }
        lastUpkeepTimestamp = block.timestamp;
    }

    // Fallback function must be declared as external.
    fallback() external payable {
        // send / transfer (forwards 2300 gas to this fallback function)
        // call (forwards all of the gas)
        emit Fallback(msg.value, gasleft());
    }

    receive() external payable {
        // custom function code
        emit Received(msg.value, gasleft());
    }

    function onERC721Received(
        address, 
        address, 
        uint256, 
        bytes calldata
    ) external pure returns(bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}