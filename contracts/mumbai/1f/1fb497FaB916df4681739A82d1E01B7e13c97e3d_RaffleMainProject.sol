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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
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
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
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
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
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
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
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
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

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
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
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

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ----------------------------------------------------------------------------
// DateTime Library v2.0
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018-2019. The MIT Licence.
// ----------------------------------------------------------------------------

library DateTime {
    uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint256 constant SECONDS_PER_HOUR = 60 * 60;
    uint256 constant SECONDS_PER_MINUTE = 60;
    int256 constant OFFSET19700101 = 2440588;

    uint256 constant DOW_MON = 1;
    uint256 constant DOW_TUE = 2;
    uint256 constant DOW_WED = 3;
    uint256 constant DOW_THU = 4;
    uint256 constant DOW_FRI = 5;
    uint256 constant DOW_SAT = 6;
    uint256 constant DOW_SUN = 7;

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    function _daysFromDate(uint256 year, uint256 month, uint256 day) internal pure returns (uint256 _days) {
        require(year >= 1970);
        int256 _year = int256(year);
        int256 _month = int256(month);
        int256 _day = int256(day);

        int256 __days = _day - 32075 + (1461 * (_year + 4800 + (_month - 14) / 12)) / 4
            + (367 * (_month - 2 - ((_month - 14) / 12) * 12)) / 12
            - (3 * ((_year + 4900 + (_month - 14) / 12) / 100)) / 4 - OFFSET19700101;

        _days = uint256(__days);
    }

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(uint256 _days) internal pure returns (uint256 year, uint256 month, uint256 day) {
        unchecked {
            int256 __days = int256(_days);

            int256 L = __days + 68569 + OFFSET19700101;
            int256 N = (4 * L) / 146097;
            L = L - (146097 * N + 3) / 4;
            int256 _year = (4000 * (L + 1)) / 1461001;
            L = L - (1461 * _year) / 4 + 31;
            int256 _month = (80 * L) / 2447;
            int256 _day = L - (2447 * _month) / 80;
            L = _month / 11;
            _month = _month + 2 - 12 * L;
            _year = 100 * (N - 49) + _year + L;

            year = uint256(_year);
            month = uint256(_month);
            day = uint256(_day);
        }
    }

    function timestampFromDate(uint256 year, uint256 month, uint256 day) internal pure returns (uint256 timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }

    function timestampFromDateTime(
        uint256 year,
        uint256 month,
        uint256 day,
        uint256 hour,
        uint256 minute,
        uint256 second
    )
        internal
        pure
        returns (uint256 timestamp)
    {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR
            + minute * SECONDS_PER_MINUTE + second;
    }

    function timestampToDate(uint256 timestamp) internal pure returns (uint256 year, uint256 month, uint256 day) {
        unchecked {
            (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        }
    }

    function timestampToDateTime(uint256 timestamp)
        internal
        pure
        returns (uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second)
    {
        unchecked {
            (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
            uint256 secs = timestamp % SECONDS_PER_DAY;
            hour = secs / SECONDS_PER_HOUR;
            secs = secs % SECONDS_PER_HOUR;
            minute = secs / SECONDS_PER_MINUTE;
            second = secs % SECONDS_PER_MINUTE;
        }
    }

    function isValidDate(uint256 year, uint256 month, uint256 day) internal pure returns (bool valid) {
        if (year >= 1970 && month > 0 && month <= 12) {
            uint256 daysInMonth = _getDaysInMonth(year, month);
            if (day > 0 && day <= daysInMonth) {
                valid = true;
            }
        }
    }

    function isValidDateTime(uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second)
        internal
        pure
        returns (bool valid)
    {
        if (isValidDate(year, month, day)) {
            if (hour < 24 && minute < 60 && second < 60) {
                valid = true;
            }
        }
    }

    function isLeapYear(uint256 timestamp) internal pure returns (bool leapYear) {
        (uint256 year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }

    function _isLeapYear(uint256 year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }

    function isWeekDay(uint256 timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }

    function isWeekEnd(uint256 timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
    }

    function getDaysInMonth(uint256 timestamp) internal pure returns (uint256 daysInMonth) {
        (uint256 year, uint256 month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }

    function _getDaysInMonth(uint256 year, uint256 month) internal pure returns (uint256 daysInMonth) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }

    // 1 = Monday, 7 = Sunday
    function getDayOfWeek(uint256 timestamp) internal pure returns (uint256 dayOfWeek) {
        uint256 _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = ((_days + 3) % 7) + 1;
    }

    function getYear(uint256 timestamp) internal pure returns (uint256 year) {
        (year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getMonth(uint256 timestamp) internal pure returns (uint256 month) {
        (, month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getDay(uint256 timestamp) internal pure returns (uint256 day) {
        (,, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getHour(uint256 timestamp) internal pure returns (uint256 hour) {
        uint256 secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }

    function getMinute(uint256 timestamp) internal pure returns (uint256 minute) {
        uint256 secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }

    function getSecond(uint256 timestamp) internal pure returns (uint256 second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    function addYears(uint256 timestamp, uint256 _years) internal pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year += _years;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
        require(newTimestamp >= timestamp);
    }

    function addMonths(uint256 timestamp, uint256 _months) internal pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        month += _months;
        year += (month - 1) / 12;
        month = ((month - 1) % 12) + 1;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
        require(newTimestamp >= timestamp);
    }

    function addDays(uint256 timestamp, uint256 _days) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }

    function addHours(uint256 timestamp, uint256 _hours) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }

    function addMinutes(uint256 timestamp, uint256 _minutes) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }

    function addSeconds(uint256 timestamp, uint256 _seconds) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

    function subYears(uint256 timestamp, uint256 _years) internal pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year -= _years;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
        require(newTimestamp <= timestamp);
    }

    function subMonths(uint256 timestamp, uint256 _months) internal pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint256 yearMonth = year * 12 + (month - 1) - _months;
        year = yearMonth / 12;
        month = (yearMonth % 12) + 1;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
        require(newTimestamp <= timestamp);
    }

    function subDays(uint256 timestamp, uint256 _days) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }

    function subHours(uint256 timestamp, uint256 _hours) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp);
    }

    function subMinutes(uint256 timestamp, uint256 _minutes) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp);
    }

    function subSeconds(uint256 timestamp, uint256 _seconds) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp);
    }

    function diffYears(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _years) {
        require(fromTimestamp <= toTimestamp);
        (uint256 fromYear,,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint256 toYear,,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }

    function diffMonths(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _months) {
        require(fromTimestamp <= toTimestamp);
        (uint256 fromYear, uint256 fromMonth,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint256 toYear, uint256 toMonth,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }

    function diffDays(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }

    function diffHours(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _hours) {
        require(fromTimestamp <= toTimestamp);
        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }

    function diffMinutes(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _minutes) {
        require(fromTimestamp <= toTimestamp);
        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }

    function diffSeconds(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _seconds) {
        require(fromTimestamp <= toTimestamp);
        _seconds = toTimestamp - fromTimestamp;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./RaffleVRF.sol";
import "./DateTime.sol";

error AdminNotFound();
error RoleCantBeEmpty();
error CommissionMustNotExceed100();
error InvalidAdminAddress();
error AdminDoesNotExist();
error InsufficientBalanceForCommissions();
error NoAdminsAvailable();
error RaffleAlreadyLocked();
error Raffle_InvalidAmountOfTickets();
error Raffle_InvalidAmountInWei();
error RefundAlreadyRequested();
error RefundAlreadyClaimed();
error NoRefundAvailable();


/**
 * @title Raffle Main Project
 * @dev 
 * @
 */

contract RaffleMainProject is RaffleVRF{

    using DateTime for uint256;
    using Strings for uint256;

    /* State Variables */
    //Owner address
    address public immutable owner;
    //RaffleVRF address
    address private raffleVRFAddress;
    
    /* Time control variables */    
    //Starting raffle time stamp
    uint256 private lastTimeStamp;
    //Time when raffle will be closed
    uint256 private raffleClosing;

    /* Payable variables */
    //Adm payment
    uint256 private amountToWithdraw;
    // Refund addresses
    address private refundWallet;
    //If true, refund already claimed
    bool private claimed;
    //Emercency variable
    bool private emergencyState;

    /* Raffle Variables */
    //
    uint256 public entranceFee = defaultEntranceFee;
    uint256 public prize = defaultPrize;
    uint256 public softcap = defaultSoftcap;
    //Default
    uint256 private defaultEntranceFee = 0.01 ether;
    uint256 private defaultPrize = 1 ether;
    uint256 private defaultSoftcap = 1 ether;
    //Others
    //Total number of entries
    uint256 public totalEntries;
    //Raffle Identifier
    uint256 public raffleId;
    //Counter to reallocation system
    uint private ticketReallocationCounter;
    //Address of the most recent raffle winner
    address public winner;
    //Raffle VRF variable
    RaffleVRF private raffleVRF;
    
    /* Struct */
    // Struct to s_administration mapping
    struct ADMINS{
        address payable wallet;
        string name;
        string role;
        uint256 commission;
        bool isAdmin;
    }
    // Struct to Refund System
    struct RefundRequest{
        uint256 refundAmount;
        bool claimed;
    }
    //Struct realocation
    struct TicketReallocation {
        address participant;
        uint256 ticketCount;
        uint256 refundAmount;
        uint256 raffleId;
    }

    /* Array */
    //Storage for Admins Info
    address[] private adminAddresses;
    //Array of players who bought tickets
    address[] internal players;
    //Array of players for random selection
    address[] internal playerSelector;

    /* Mapping */
    //Storage for Admins Info
    mapping (address => ADMINS) private s_administration;
    // Mapping to store the count of entries per address
    mapping(address => uint256) public entryCounts;
    // Storage for participants refund
    mapping(address => RefundRequest) private refundRequests;
    //Storage for recent Winners
    mapping (uint256 => address payable) public recentWinners;
    //Storage to transfer tickets
    mapping(uint256 => TicketReallocation) public ticketReallocationInfo;

    /* Events */
    event AdminADD(address _wallet);
    event AdminUpdated();
    event AdminRemoved();
    event BalanceWithdrawn(address admin, uint amountToWithdraw);
    event RaffleLocked();
    event RaffleCleared();
    event TicketsReallocatedToNextRaffle(address participant, uint256 ticketCount, uint256 raffleId);
    event RaffeStarted();
    event RafflePrizeSet(uint prize);
    event NewTicketBought(address player);
    event ContractReseted();
    event CalculatingRafflePrize();
    event RaffleCanceled();
    event WinnerPaid(address winner, uint256 prize);
    event RefundClaimed(address participant, uint256 amountToRefund);
    event TicketsReallocated(address participant, uint256 ticketCount, uint256 refundAmount, uint256 nextRaffleId);

    /* Enum to RaffleStages */
    enum RaffleStage{
        Closed, //0
        Open, //1
        Canceled, //2
        Calculating, //3
        Emergency //4
    }

    RaffleStage private stage = RaffleStage.Closed;

    /* CONSTRUCTOR */
    constructor(address vrfCoordinatorV2, bytes32 keyHash, uint64 subscriptionId, uint32 callbackGasLimit, address _raffleVRFAddress)
                RaffleVRF(vrfCoordinatorV2, keyHash, subscriptionId, callbackGasLimit){
        owner = msg.sender;
        stage = RaffleStage.Closed;
        raffleVRFAddress = _raffleVRFAddress;
    }

    /* ADMINISTRATIVE FUNCTIONS */    
    /**
    * @dev Add a new admin to the administration list.
    * @param _wallet The wallet address of the new admin.
    * @param _name The name of the new admin.
    * @param _role The role of the new admin.
    * @param _commission The commission rate for the new admin.
    */
    function addAdmin(address payable _wallet, string memory _name, string memory _role, uint _commission) public onlyOwner isAtStage(RaffleStage.Closed) {
        s_administration[_wallet] = ADMINS({
            wallet: _wallet,
            name: _name,
            role: _role,
            commission: _commission,
            isAdmin: true
        });

        require(_wallet != address(0), "WalletCantBeNull");
        require(bytes(_name).length != 0, "NameCantBeNull");
        require(bytes(_role).length != 0, "RoleCantBeNull");
        require(_commission != 0, "CommissionCantBeNull");

        adminAddresses.push(_wallet);
        emit AdminADD(_wallet);
    }

    //Shows the list of Admins
    function getAdmins() public view returns(ADMINS[] memory){
        uint256 numAdmins = adminAddresses.length;
        ADMINS[] memory admins = new ADMINS[](numAdmins);

        for (uint256 i = 0; i < numAdmins; i++) {
            address adminWallet = adminAddresses[i];
            admins[i] = s_administration[adminWallet];
        }
        return admins;
    }

    /**
    * @dev Update the information of an admin.
    * @param _wallet The wallet address of the admin to update.
    * @param _role The updated role of the admin.
    * @param _commission The updated commission rate for the admin.
    */
    function updateAdmin(address _wallet, string memory _role, uint256 _commission) public onlyOwner isAtStage(RaffleStage.Closed) {
        if (!s_administration[_wallet].isAdmin) {revert AdminNotFound();}
        if (bytes(_role).length == 0) {revert RoleCantBeEmpty();}
        if (_commission > 100) {revert CommissionMustNotExceed100();}

        s_administration[_wallet].role = _role;
        s_administration[_wallet].commission = _commission;

        emit AdminUpdated();
    }

    /**
    * @dev Remove an admin from the administration list.
    * @param _wallet The wallet address of the admin to remove.
    */
    function removeAdmin(address _wallet) public onlyOwner isAtStage(RaffleStage.Closed) {
        if (_wallet == address(0)) {revert InvalidAdminAddress();}
        if (!s_administration[_wallet].isAdmin) {revert AdminDoesNotExist();}

        delete s_administration[_wallet];

        emit AdminRemoved();
    }

    /**
    * @dev Withdraw the contract balance and distribute it among admins based on their commission rates.
    */
    function withdrawBalance() safetyLock isAtStage(RaffleStage.Closed) public onlyAdmins {
        if (amountToWithdraw == 0) {revert InsufficientBalanceForCommissions();}
        
        uint256 totalBalance = address(this).balance;
        uint256 totalCommission = 0;

        if (adminAddresses.length == 0) {revert NoAdminsAvailable();}
        
        for (uint256 i = 0; i < adminAddresses.length; i++) {
            address payable admin = payable(adminAddresses[i]);
            totalCommission = totalCommission.add(s_administration[admin].commission);
        }
        
        for (uint256 i = 0; i < adminAddresses.length; i++) {
            address payable admin = payable(adminAddresses[i]);
            uint256 adminCommission = s_administration[admin].commission;
            amountToWithdraw = totalBalance.mul(adminCommission).div(totalCommission);
            
            admin.transfer(amountToWithdraw);
            
            emit BalanceWithdrawn(admin, amountToWithdraw);
        }
    }
    /**
    * @dev Lock the raffle.
    * Only admins can call this function to lock the raffle.
    * Once locked, certain functions will not be executable.
    */
    function lockRaffle() public onlyAdmins {
        if (stage == RaffleStage.Emergency) {revert RaffleAlreadyLocked();}
        else {emergencyState = true;
                emit RaffleLocked();
        }
    }
    
    /**
    * @dev Resume the raffle.
    * Only admins can call this function to resume the raffle after it has been paused.
    * Once resumed, all functions can be executed again.
    */
    function unlockRaffle() public onlyOwner {
        if (emergencyState) {
            emergencyState = false;
            emit RaffleCleared();
        }
    }

    /* RAFFLE FUNCTIONS */
    /**
    * @dev Create a new raffle with updated fees, prize, and closing time.
    * @param feeToUpdate The updated entrance fee for the raffle.
    * @param newPrize The updated prize for the raffle.
    * @param newSoftcap The updated softcap for the raffle.
    * @param timeToClose The time duration for the raffle to close.
    */
    function createRaffle(uint256 feeToUpdate, uint256 newPrize, uint256 newSoftcap, uint256 timeToClose) safetyLock isAtStage(RaffleStage.Closed) public onlyAdmins{       
        raffleId++;
        lastTimeStamp = block.timestamp;

        if (feeToUpdate != defaultEntranceFee) {entranceFee = feeToUpdate;}
        if (newSoftcap != defaultSoftcap) {softcap = newSoftcap;}
        if (newPrize != defaultPrize) {prize = newPrize;}        

        raffleClosing = lastTimeStamp + timeToClose;
        require (timeToClose != 0, "Closing time must be set!");

        for (uint256 i = 0; i < ticketReallocationCounter; i++) {
            TicketReallocation storage reallocation = ticketReallocationInfo[i];

            if (reallocation.raffleId == raffleId) {
                entryCounts[reallocation.participant] += reallocation.ticketCount;

                emit TicketsReallocatedToNextRaffle(reallocation.participant, reallocation.ticketCount, raffleId);
            }
        }
        updateStage(RaffleStage.Open);

        emit RaffeStarted();
        emit RafflePrizeSet(prize);
    }

    /**
    * @dev Buy raffle tickets.
    * @param numberOfTickets The number of tickets to buy.
    */
    using SafeMath for uint256;
    function buyTicket(uint256 numberOfTickets) public payable safetyLock isAtStage(RaffleStage.Open) {
    require(block.timestamp < raffleClosing, "Check the closing time!");
        
        if(numberOfTickets <= 0){revert Raffle_InvalidAmountOfTickets();}
        uint256 totalPayment = entranceFee.mul(numberOfTickets);
        if (msg.value != totalPayment) {revert Raffle_InvalidAmountInWei();}

        entryCounts[msg.sender] = entryCounts[msg.sender].add(numberOfTickets);
        totalEntries = totalEntries.add(numberOfTickets);

        if (!isPlayer(msg.sender)) {players.push(msg.sender);}
        
        for (uint256 i = 0; i < numberOfTickets; i++) {playerSelector.push(msg.sender);}

        emit NewTicketBought(msg.sender);
    }

    //Validates if the buyer is already in players array
    function isPlayer(address participant) private view returns (bool) {
        for (uint256 i = 0; i < players.length; i++) {
            if (players[i] == participant) {
                return true;
            }
        }
        return false;
    }

    function performDraw() public onlyAdmins safetyLock isAtStage(RaffleStage.Calculating) returns (uint256) {
    // ... outras verificações e lógica

    // Chama a função requestRandomWords do contrato RaffleVRF
    uint256 requestId = raffleVRF.requestRandomWords();

    // Retorna o ID da solicitação para que o resultado do sorteio possa ser obtido posteriormente
        return requestId;
    }

    function getDrawResult(uint256 requestId) public view onlyAdmins safetyLock isAtStage(RaffleStage.Calculating) returns (uint256) {
    // Chama a função getDrawResult do contrato RaffleVRF, passando o tamanho do array playerSelector
    
        return raffleVRF.getDrawResult(requestId, playerSelector.length);
    }

    /**
    * @dev Reset the contract by clearing player-related arrays and resetting ticket-related variables.
    */
    function resetContract() public onlyAdmins safetyLock isAtStage(RaffleStage.Closed) {
        delete playerSelector;
        delete players;
        totalEntries = 0;
        entranceFee = defaultEntranceFee;
        prize = defaultPrize;
        softcap = defaultSoftcap;

        emit ContractReseted();
    }

    /* TIME CONVERTER FUNCTIONS - OpenZeppelin */

    // Function to convert a uint256 value to a string
    function uint256ToString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    // Function to left pad a string with zeros
    function padLeft(string memory value, uint256 length) internal pure returns (string memory) {
        require(bytes(value).length <= length, "Value is too long");
        bytes memory result = new bytes(length);
        uint256 padding = length - bytes(value).length;
        assembly {
            let source := add(value, 0x20)
            let target := add(result, padding)
            for { } gt(padding, 0) { padding := sub(padding, 1) } {
                mstore8(target, 0x30) // ASCII code for '0'
                target := add(target, 1)
            }
            mstore(target, mload(source))
        }
        return string(result);
    }  

    // Function to format the date and time as a string
    // Function to format the date and time as a string
    function formatDateTime(uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second) internal pure returns (string memory) {
        return string(abi.encodePacked(
            uint256ToString(year),
            "-",
            padLeft(uint256ToString(month), 2),
            "-",
            padLeft(uint256ToString(day), 2),
            " ",
            padLeft(uint256ToString(hour), 2),
            ":",
            padLeft(uint256ToString(minute), 2),
            ":",
            padLeft(uint256ToString(second), 2)
        ));
    }

    /* COMMOM FUNCTIONS */
    // Returns the opening time of the raffle
    function openingTime() public view isAtStage(RaffleStage.Open) returns (string memory) {
        (uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second) = DateTime.timestampToDateTime(lastTimeStamp);
        return formatDateTime(year, month, day, hour, minute, second);
    }

    // Block.timeStamp now
    function timeStampNow() public view isAtStage(RaffleStage.Open) returns (string memory) {
        (uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second) = DateTime.timestampToDateTime(block.timestamp);
        return formatDateTime(year, month, day, hour, minute, second);
    }

    // Returns the raffle closing time.
    function closingTime() public isAtStage(RaffleStage.Open) returns (string memory) {
        if (block.timestamp > raffleClosing) {
            if (address(this).balance >= prize) {
                updateStage(RaffleStage.Calculating);
                emit CalculatingRafflePrize();
            } else {
                updateStage(RaffleStage.Canceled);
                emit RaffleCanceled();
            }
        }
        (uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second) = DateTime.timestampToDateTime(raffleClosing);
        return formatDateTime(year, month, day, hour, minute, second);
    }

    //Return raffle stage
    function getRaffleStage() public view isAtStage(RaffleStage.Open) returns (string memory) {
    if (stage == RaffleStage.Closed) {return "Closed";}
        else if (stage == RaffleStage.Open) {return "Open";}
        else if (stage == RaffleStage.Canceled) {return "Canceled";}
        else if (stage == RaffleStage.Calculating) {return "Calculating";}
        else if (stage == RaffleStage.Emergency) {return "Emergency";}
        else {return "Unknown";}
    }

    //Return players array
    function getPlayers() public view returns (address[] memory) {
        return players;
    }

    //Return contract balance
    function getBalance() internal view safetyLock returns(uint){
        return address(this).balance;
    }

    // Return the prize listed to the current Raffle
    function rafflePrize() public view isAtStage(RaffleStage.Open) returns(uint){
        return prize;
    }

    //Updating Stages
    function updateStage(RaffleStage _stage) private {
        stage = _stage;
    }

    

    /* PAY WINNER FUNCTION */
    /**
    * @dev Pay the raffle winner.
    */
    function payWinner() public onlyAdmins safetyLock isAtStage(RaffleStage.Calculating) {
        require(winner != address(0), "No winner selected");

        uint256 prizeAmount = prize;

        if (prizeAmount > 0) {
            recentWinners[raffleId] = payable(winner);
            (bool success, ) = payable(winner).call{value: prizeAmount}("");
            require(success, "Transfer failed");

            emit WinnerPaid(winner, prizeAmount);
        }
        else {recentWinners[raffleId] = payable(address(0));}
    }

    /* REFUND FUNCTIONS */
    /**
    * @dev Request a refund for the participant in case of a canceled raffle.
    */
    function requestRefund() public safetyLock isAtStage(RaffleStage.Canceled) {
        if (refundRequests[msg.sender].refundAmount != 0) {revert RefundAlreadyRequested();}

        if (refundRequests[msg.sender].claimed) {revert RefundAlreadyClaimed();}

        uint256 refundAmount = calculateRefundAmount(msg.sender);
        if (refundAmount == 0) {revert NoRefundAvailable();}

        refundRequests[msg.sender].refundAmount = refundAmount;
    }

    // Search for the total spend with Raffle Tickets
    function calculateRefundAmount(address participant) internal view safetyLock isAtStage(RaffleStage.Canceled) returns (uint256) {
        uint256 totalAmountSpent = 0;

        for (uint256 i = 0; i < players.length; i++) {
            address player = players[i];
            uint256 numberOfTickets = entryCounts[player];
            if (player == participant && numberOfTickets > 0) {totalAmountSpent = totalAmountSpent.add(numberOfTickets.mul(entranceFee));}
        }
        return totalAmountSpent;
    }

    /**
    * @dev Claim the refund amount for a participant.
    */
    function claimRefund() public safetyLock isAtStage(RaffleStage.Canceled){
        if (refundRequests[msg.sender].refundAmount == 0) {revert NoRefundAvailable();}

        if (refundRequests[msg.sender].claimed) {revert RefundAlreadyClaimed();
        }

        uint256 amountToRefund = refundRequests[msg.sender].refundAmount;
        refundRequests[msg.sender].refundAmount = 0;
        refundRequests[msg.sender].claimed = true;

        payable(msg.sender).transfer(amountToRefund);
    }

    /**
    * @dev Refund all participants who did not claim their refunds before the refund deadline.
    */
    function refundAllForgottenParticipants() public onlyAdmins safetyLock isAtStage(RaffleStage.Canceled) {
        for (uint256 i = 0; i < players.length; i++) {
            address participant = players[i];

            if (refundRequests[participant].refundAmount > 0 && !refundRequests[participant].claimed) {
                uint256 amountToRefund = refundRequests[participant].refundAmount;
                refundRequests[participant].refundAmount = 0;
                refundRequests[participant].claimed = true;

                (bool success, ) = payable(participant).call{value: amountToRefund}("");
                require(success, "Transfer failed");

                emit RefundClaimed(participant, amountToRefund);
            }
        }
    }

    /**
    * @dev Reallocate tickets to the next raffle for participants who did not request a refund.
    * @param nextRaffleId The ID of the next raffle to reallocate tickets.
    */
    function reallocateTicketsToNextRaffle(uint256 nextRaffleId) public onlyAdmins safetyLock isAtStage(RaffleStage.Canceled) {
        for (uint256 i = 0; i < players.length; i++) {
            address participant = players[i];

            if (refundRequests[participant].refundAmount > 0 && !refundRequests[participant].claimed) {
                uint256 ticketCount = entryCounts[participant];
                uint256 refundAmount = refundRequests[participant].refundAmount;

                uint256 reallocationIndex = ticketReallocationCounter;
                ticketReallocationInfo[reallocationIndex] = TicketReallocation(participant, ticketCount, refundAmount, nextRaffleId);
                ticketReallocationCounter++;

                emit TicketsReallocated(participant, ticketCount, refundAmount, nextRaffleId);
            }
        }
    }

    /* MODIFIERS */
    //onlyOwner
    modifier onlyOwner {
        require(msg.sender == owner, "Only the owner can call this function!") ;
        _;
    }
    //onlyAdmins
    modifier onlyAdmins {
        require(s_administration[msg.sender].isAdmin, "Only admin and owner can call this function!");
        _;
    }
    //Stage validation
    modifier isAtStage(RaffleStage _stage){
        require(stage == _stage, "Not at correct stage!");
        _;
    }
    /**
    * @dev Modifier that checks if the raffle is not paused before executing the function.
    * The owner can still execute transactions even during the paused period.
    */
    modifier safetyLock() {
        require(!emergencyState || msg.sender == owner, "Raffle is LOCKED");
        _;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

error RaffleUpkeepNotNeeded();
error RaffleIsLocked();
error RaffleUnlocked();

contract RaffleVRF is VRFConsumerBaseV2{

/* Chainlink VRF Tools*/
    uint64 private immutable s_subscriptionId;
    uint[] public requestIds;
    uint public lastRequestId;
    bytes32 private immutable keyHash;
    uint32 private  immutable callbackGasLimit;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;

    struct RequestStatus {
        bool fulfilled;
        bool exists;
        uint256[] randomWords;
    }

    mapping(uint256 => RequestStatus) public s_requests;

    VRFCoordinatorV2Interface private immutable COORDINATOR;

    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);
    event RequestedRaffleWinner(uint256 requestId);

    constructor(address vrfCoordinatorV2, bytes32 i_keyHash, uint64 subscriptionId, uint32 i_callbackGasLimit) VRFConsumerBaseV2(vrfCoordinatorV2){
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        keyHash = i_keyHash;
        s_subscriptionId = subscriptionId;
        callbackGasLimit = i_callbackGasLimit;      
    }

    /* VRF FUNCTIONS */
    /**
    * @dev Request random words from the VRF coordinator to determine the raffle winner.
    * @return requestId The ID of the random word request.
    */
    function requestRandomWords() external returns (uint256 requestId){
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        s_requests[requestId] = RequestStatus({
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId;
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        require(s_requests[_requestId].exists, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;

        uint256 indexOfWinner = _randomWords[0];

        emit RequestFulfilled(_requestId, _randomWords);
    }

    function getDrawResult(uint256 requestId, uint256 playerSelectorLength) public view returns (uint256) {
        require(s_requests[requestId].fulfilled, "Request not fulfilled");

        uint256[] memory randomWords = s_requests[requestId].randomWords;
        uint256 winner = randomWords[0] % playerSelectorLength;

        return winner;
    }

    function getRequestStatus(uint256 _requestId) external view returns (bool fulfilled, uint256[] memory randomWords) {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }


}