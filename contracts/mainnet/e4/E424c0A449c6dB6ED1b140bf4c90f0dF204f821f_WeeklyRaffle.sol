/**
 *Submitted for verification at polygonscan.com on 2023-01-17
*/

// File: @chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol


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

// File: @chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol


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

// File: contracts/helpers/TokenTypes.sol

pragma solidity ^0.8.0;

library TokenTypes{
    uint256  public constant UNKNOWN = 0x0000;
    uint256  public constant ALICE = 0x0001;
    uint256  public constant QUEEN = 0x0002;
    uint256  public constant CARD = 0x0003;
    uint256  public constant CLUBS_OF_RUNNER = 0x0013;
    uint256  public constant DIAMOND_OF_ENERGY = 0x0023;
    uint256  public constant SPADES_OF_MARKER = 0x0033;
    uint256  public constant HEART_OF_ALL_ROUNDER = 0x0043;

}

library VRFRequestStatus {
    uint8 public constant NO_REQUEST =0;
    uint8 public constant PENDING = 1;
    uint8 public constant COMPLETED =2;
}

library AuctionDetails{


    struct BidHistory {
        address bidder;
        uint256 bidAmount;
        uint256 bidtime;
    }


    struct Auction {
        uint256 nftId;
        BidHistory[] bidHistorybyId;
        uint256 bidCounter;
        uint256 startTime;
        uint256 endTime;
        bool isClaimed;
        uint256 highestBid;
        address highestBidder;
    }
}





// File: contracts/interfaces/IWonderGameMinter.sol

pragma solidity ^0.8.0;

interface IWonderGameMinter {
    function mint(address _user, uint256 _numOfTokens) external returns (uint256);
}
// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts/utils/math/Math.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

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
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

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

// File: @openzeppelin/contracts/access/IAccessControl.sol


// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// File: @openzeppelin/contracts/access/AccessControl.sol


// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;





/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// File: contracts/WonderVRFGenerator/WonderVRFAccessControl.sol

pragma solidity ^0.8.0;


abstract contract WonderVRFAccessControl is AccessControl {
    bytes32 internal constant MANAGER_ROLE = 0x241ecf16d79d0f8dbfb92cbc07fe17840425976cf0667f022fe9877caa831b08;

    constructor() {
        _setupRole(MANAGER_ROLE, msg.sender);
    }

}
// File: contracts/WonderVRFGenerator/WonderVRFGeneratorV2.sol

pragma solidity ^0.8.0;




    error SubscriberNotValid();
    error SubscriberNotAuthorized();

abstract contract WonderVRFGeneratorV2 is VRFConsumerBaseV2, WonderVRFAccessControl {
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords, address initiatedBy);

    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists;
    }

    VRFCoordinatorV2Interface COORDINATOR;
    uint64 s_subscriptionId;

    //TODO change while deploy
    //https://docs.chain.link/vrf/v2/subscription/supported-networks
    //mainnet
    address internal VRF_COORDINATOR = 0xAE975071Be8F8eE67addBC1A82488F1C24858067;
    bytes32 internal keyHash= 0xcc294a196eeeb44da2888d17c0625cc88d70d9760a69d58d853ba6581a9ab0cd;
    // //mumbai testnet
    // address internal VRF_COORDINATOR = 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed;
    // bytes32 internal keyHash = 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;

    mapping(uint256 => RequestStatus) public s_requests; /* requestId --> requestStatus */

    // past requests Id.
    uint256[] public requestIds;

    uint16 requestConfirmations = 3;

    uint32 callbackGasLimit = 2500000;



    constructor(uint64 _subscriptionId) VRFConsumerBaseV2(VRF_COORDINATOR) WonderVRFAccessControl(){
        COORDINATOR = VRFCoordinatorV2Interface(VRF_COORDINATOR);
        s_subscriptionId = _subscriptionId;
    }


    function setSubId(uint64 _id) external onlyRole(MANAGER_ROLE){
        s_subscriptionId = _id;
    }

    function requestRandomWords(uint32 _numWords)
    internal
    returns (
        uint256 requestId
    )
    {
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            _numWords
        );
        s_requests[requestId] = RequestStatus({
        fulfilled : false,
        exists : true
        });
        requestIds.push(requestId);
        emit RequestSent(requestId, _numWords);
        return requestId;
    }

    function totalRequests() external view returns (uint256){
        return requestIds.length;
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        require(s_requests[_requestId].exists, "request not found");
        s_requests[_requestId].fulfilled = true;
        emit RequestFulfilled(_requestId, _randomWords, msg.sender);
        processRandomness(_requestId, _randomWords);
    }

    function fulfillRandomWordsManual(uint256 _requestId, uint256[] memory _randomWords) external onlyRole(MANAGER_ROLE)  {
        fulfillRandomWords(_requestId, _randomWords);
    }

    function processRandomness(uint256 _requestId, uint256[] memory _numWords) internal virtual;

    function getRequestStatus(uint256 _requestId) external view returns (bool fulfilled) {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled);
    }
}

// File: contracts/WeeklyRaffle/WeeklyRaffleAccessControl.sol

pragma solidity ^0.8.0;


abstract contract WeeklyRaffleAccessControl is AccessControl {
    bytes32 internal constant OWNER_ROLE =
    0xb19546dff01e856fb3f010c267a7b1c60363cf8a4664e21cc89c26224620214e;
    bytes32 internal constant HANDLER_ROLE =
    0x8ee6ed50dc250dbccf4d86bd88d4956ab55c7de37d1fed5508924b70da11fe8b;

    bool public isPaused;

    modifier whenNotPaused() {
        require(!isPaused, "Weekly raffle is paused");
        _;
    }

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OWNER_ROLE, msg.sender);
        _setupRole(HANDLER_ROLE, msg.sender);
    }

    function pause() public onlyRole(OWNER_ROLE) {
        isPaused = true;
    }

    function unpause() public onlyRole(OWNER_ROLE) {
        isPaused = false;
    }
}

// File: contracts/interfaces/INFTMintInitiator.sol

pragma solidity ^0.8.0;

interface INFTMintInitiator {
    function acknowledgeMint(uint256 _requestId,address _user,uint256[] memory _tokenIds) external;
}
// File: contracts/interfaces/IWonderVRFGenerator.sol

pragma solidity ^0.8.0;

interface IWonderVRFGenerator {
    function requestRandomWords(uint32 _numWords)
        external
        returns (uint256 requestId);
}

// File: contracts/WeeklyRaffle/WeeklyRaffle.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;







contract WeeklyRaffle is WeeklyRaffleAccessControl, INFTMintInitiator, WonderVRFGeneratorV2 {
    IWonderGameMinter nftMinter;

    event WinnerIndicesSelected(
        address _initiatedBy,
        uint256 _weekNumber,
        uint256 _requestId,
        uint256[] _numWords,
        uint256[] _indices
    );
    event WinnerCountUpdate(address _user, uint256 oldCount, uint256 newCount);
    event RaffleRewardMintRequested(address _user, uint256 _requestId);
    event RaffleRewardMintRequestCancelled(address _initiatedBy, address _user, uint256 _requestId);
    event RaffleRewardMinted(uint256 _weekNumber, address _user, uint256[] _tokenIds);
    event WinnerAddressesSet(address _initiatedBy, uint256 _weekNumber, address[] _users);

    struct NFTs {
        address user;
        uint256 tokenId;
    }

    struct User {
        uint256 index;
        address wallet;
    }

    struct VRFRequest {
        uint256[] randomNumbers;
        uint8 status;
    }

    struct WeeklyRaffleConfig {
        bytes32 hash;
        uint256 raffleCount;
        bool hasConfigured;
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256[] indices;
        VRFRequest vrfRequest;
        mapping(uint256 => address) indexToUser;
        mapping(address => uint256) remainingClaimCount;
        mapping(address => uint256) totalCount;
        mapping(address => uint256) inProgressClaimCount;
        NFTs[] tokens;
    }

    struct WeeklyConfigResponse {
        bytes32 hash;
        bool hasConfigured;
        uint256 raffleCount;
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256[] indices;
        NFTs[] tokens;
    }

    struct MintRequest {
        uint256 weekNumber;
        address user;
        uint256 noOfTokens;
        uint256 status;
    }

    mapping(uint256 => WeeklyRaffleConfig) weeklyConfigs; //weekNumber => VRFRequest
    mapping(uint256 => uint256) public requestToWeekNumber; //requestId => weekNumber
    mapping(uint256 => MintRequest) public requestToMint; //requestId => mintRequest

    uint256 public winnerCount;

    constructor(IWonderGameMinter _minter, uint64 _subscriptionId)
        WonderVRFGeneratorV2(_subscriptionId)
        WeeklyRaffleAccessControl()
    {
        nftMinter = _minter;
        WeeklyRaffleConfig storage newWeeklyConfig = weeklyConfigs[5];
        newWeeklyConfig.startTimestamp = 1673438400;
        newWeeklyConfig.endTimestamp = 1674043200;
        winnerCount = 40;
    }

    function setWonderGameMinter(IWonderGameMinter _address) external onlyRole(OWNER_ROLE) {
        nftMinter = _address;
    }

    function migrateWeeklyConfig(
        uint256 _weekNumber,
        WeeklyConfigResponse memory weeklyConfig,
        User[] memory users
    ) external onlyRole(MANAGER_ROLE) {
        WeeklyRaffleConfig storage config = weeklyConfigs[_weekNumber];
        config.hash = weeklyConfig.hash;
        config.hasConfigured = weeklyConfig.hasConfigured;
        config.raffleCount = weeklyConfig.raffleCount;
        config.startTimestamp = weeklyConfig.startTimestamp;
        config.endTimestamp = weeklyConfig.endTimestamp;

        uint256 userCount = users.length;
        //reset all data
        delete config.indices;
        delete config.tokens;
        for (uint256 i; i < userCount; i++) {
            config.remainingClaimCount[users[i].wallet] = 0;
            config.inProgressClaimCount[users[i].wallet] = 0;
            config.totalCount[users[i].wallet] = 0;
        }

        for (uint256 i; i < userCount; i++) {
            User memory user = users[i];
            config.remainingClaimCount[user.wallet]++;
            config.totalCount[user.wallet]++;
            config.indices.push(user.index);
            config.indexToUser[user.index] = user.wallet;
        }

        uint256 length = weeklyConfig.tokens.length;

        for (uint256 i; i < length; i++) {
            config.tokens.push(weeklyConfig.tokens[i]);
            config.remainingClaimCount[weeklyConfig.tokens[i].user]--;
        }
    }

    function getWeeklyConfig(uint256 _weekNumber) external view returns (WeeklyConfigResponse memory) {
        WeeklyRaffleConfig storage config = weeklyConfigs[_weekNumber];
        return
            WeeklyConfigResponse({
                hash: config.hash,
                raffleCount: config.raffleCount,
                startTimestamp: config.startTimestamp,
                endTimestamp: config.endTimestamp,
                indices: config.indices,
                tokens: config.tokens,
                hasConfigured: config.hasConfigured
            });
    }

    function getRemainingCount(uint256 _weekNumber, address _user) external view returns (uint256) {
        return weeklyConfigs[_weekNumber].remainingClaimCount[_user];
    }

    function getTotalCount(uint256 _weekNumber, address _user) public view returns (uint256) {
        return weeklyConfigs[_weekNumber].totalCount[_user];
    }

    function getInProgressCount(uint256 _weekNumber, address _user) external view returns (uint256) {
        return weeklyConfigs[_weekNumber].inProgressClaimCount[_user];
    }

    function getWinners(uint256 _weekNumber) external view returns (User[] memory) {
        WeeklyRaffleConfig storage config = weeklyConfigs[_weekNumber];
        uint256 length = config.indices.length;
        if (length == 0) {
            return new User[](0);
        }
        User[] memory users = new User[](length);
        for (uint256 i = 0; i < length; i++) {
            uint256 index = config.indices[i];
            users[i] = User({index: index, wallet: config.indexToUser[index]});
        }
        return users;
    }

    function drawWeeklyRaffle(
        uint256 _weekNumber,
        bytes32 _hash,
        uint256 _raffleCount
    ) external onlyRole(HANDLER_ROLE) returns (uint256 requestId) {
        WeeklyRaffleConfig storage config = weeklyConfigs[_weekNumber];
        require(config.endTimestamp < block.timestamp, "Week is still active");
        require(
            config.vrfRequest.status == VRFRequestStatus.PENDING ||
                config.vrfRequest.status == VRFRequestStatus.NO_REQUEST,
            "weekly draw already executed"
        );

        requestId = super.requestRandomWords(1);

        config.vrfRequest.randomNumbers = new uint256[](0);

        config.vrfRequest.status = VRFRequestStatus.PENDING;
        config.raffleCount = _raffleCount;
        config.hash = _hash;
        requestToWeekNumber[requestId] = _weekNumber;

        uint256 newWeek = _weekNumber + 1;

        WeeklyRaffleConfig storage newWeeklyConfig = weeklyConfigs[newWeek];
        newWeeklyConfig.startTimestamp = config.startTimestamp + 7 days;
        newWeeklyConfig.endTimestamp = config.endTimestamp + 7 days;

        return requestId;
    }

    function processRandomness(uint256 _requestId, uint256[] memory _numWords) internal override {
        uint256 weekNumber = requestToWeekNumber[_requestId];
        WeeklyRaffleConfig storage config = weeklyConfigs[weekNumber];
        require(config.vrfRequest.status == VRFRequestStatus.PENDING, "request is not pending");

        config.vrfRequest.status = VRFRequestStatus.COMPLETED;
        config.vrfRequest.randomNumbers = _numWords;
        uint256 raffleCount = config.raffleCount;
        bytes32 hash = config.hash;

        uint256 randomNumber = uint256(keccak256(abi.encodePacked(_numWords[0], hash, raffleCount, block.timestamp)));
        uint256 value;
        uint256 count = 0;
        uint256 _max = winnerCount;
        if (raffleCount < winnerCount) {
            _max = raffleCount;
        }

        for (uint256 i = 0; count < _max; i++) {
            value = uint256(keccak256(abi.encodePacked(randomNumber, i))) % raffleCount;
            if (config.indexToUser[value] == address(0)) {
                config.indexToUser[value] = address(this);
                config.indices.push(value);
                count++;
            }
        }

        emit WinnerIndicesSelected(msg.sender, weekNumber, _requestId, _numWords, config.indices);
    }

    function setWinnerCount(uint256 count) external onlyRole(HANDLER_ROLE) {
        winnerCount = count;
        emit WinnerCountUpdate(msg.sender, winnerCount, count);
    }

    function setWinnerAddresses(
        uint256 _weekNumber,
        uint256[] memory _indices,
        address[] memory _users
    ) external onlyRole(HANDLER_ROLE) {
        WeeklyRaffleConfig storage config = weeklyConfigs[_weekNumber];
        require(!config.hasConfigured, "winner already configured");

        for (uint256 i; i < _indices.length; i++) {
            address user = _users[i];
            uint256 index = _indices[i];
            require(config.indexToUser[index] == address(this), "Index not found");
            config.indexToUser[index] = user;
            config.remainingClaimCount[user]++;
            config.totalCount[user]++;
        }
        config.hasConfigured = true;
        emit WinnerAddressesSet(msg.sender, _weekNumber, _users);
    }

    function claim(uint256 _weekNumber, uint256 _count) external {
        require(msg.sender != address(0), "Unauthorized access");
        require(_count != 0, "Claim number cant be zero");
        address caller = msg.sender;
        _claim(caller, _weekNumber, _count);
    }

    function _claim(
        address user,
        uint256 _weekNumber,
        uint256 _count
    ) internal {
        WeeklyRaffleConfig storage config = weeklyConfigs[_weekNumber];
        uint256 nftCounts = config.remainingClaimCount[user];

        require(_count <= 5 && _count <= nftCounts, "Invalid claim count");

        config.remainingClaimCount[user] -= _count;
        config.inProgressClaimCount[user] += _count;

        uint256 requestId = nftMinter.mint(user, _count);
        requestToMint[requestId] = MintRequest({
            weekNumber: _weekNumber,
            user: user,
            noOfTokens: _count,
            status: VRFRequestStatus.PENDING
        });
        emit RaffleRewardMintRequested(user, requestId);
    }

    function resetMintRequest(address _user, uint256 _requestId) external onlyRole(HANDLER_ROLE) {
        MintRequest storage mintRequest = requestToMint[_requestId];

        require(mintRequest.status == VRFRequestStatus.PENDING, "Request not exists or already completed");
        require(mintRequest.user == _user, "User not matched");
        WeeklyRaffleConfig storage config = weeklyConfigs[mintRequest.weekNumber];
        uint256 _count = mintRequest.noOfTokens;

        require(config.inProgressClaimCount[_user] >= _count, "In progress count is less than cancel request");

        config.remainingClaimCount[_user] += _count;
        config.inProgressClaimCount[_user] -= _count;
        requestToMint[_requestId] = MintRequest({
            status: VRFRequestStatus.NO_REQUEST,
            user: address(0),
            weekNumber: 0,
            noOfTokens: 0
        });
        emit RaffleRewardMintRequestCancelled(msg.sender, _user, _requestId);

        _claim(_user, mintRequest.weekNumber, _count);
    }

    function acknowledgeMint(
        uint256 _requestId,
        address _user,
        uint256[] memory _tokenIds
    ) external override {
        require(msg.sender == address(nftMinter), "Unauthorized access");

        MintRequest storage mintRequest = requestToMint[_requestId];
        require(mintRequest.user == _user, "User not matched");

        WeeklyRaffleConfig storage config = weeklyConfigs[mintRequest.weekNumber];
        uint256 tokenCount = _tokenIds.length;

        require(
            tokenCount <= config.inProgressClaimCount[_user] && tokenCount == mintRequest.noOfTokens,
            "Pending claim count is greater than number of tokens"
        );
        config.inProgressClaimCount[_user] -= tokenCount;

        for (uint256 i; i < tokenCount; i++) {
            uint256 tokenId = _tokenIds[i];
            config.tokens.push(NFTs({user: _user, tokenId: tokenId}));
        }
        mintRequest.status = VRFRequestStatus.COMPLETED;
        emit RaffleRewardMinted(mintRequest.weekNumber, _user, _tokenIds);
    }
}