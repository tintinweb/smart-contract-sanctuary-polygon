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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "../utils/ArtworkUtils.sol";
import "../interfaces/IPrizePools.sol";

interface IMetaData {
    error MetaData_TokenIdOutOfBounds();
    error MetaData_AlreadyInFinalState();
    error MetaData_RequestAlreadyInProgress(uint256 tokenId, NFTStatus status);
    error MetaData_OnlyAllowedForCoordinator();
    error MetaData_TokenCurrentlyNotClaimable(
        NFTStatus status,
        bool winner,
        uint256 prize
    );

    enum NFTStatus {
        INITIAL,
        ARTWORK_REVEALED,
        SCRATCHED,
        PRIZE_REVEALED
    }

    struct TokenMetaData {
        bool inProgress;
        NFTStatus status;
        ArtworkUtils.Artwork artwork;
        bool winner;
        uint256 prize;
        bool claimed;
        uint256 scratchedNum;
    }

    event MetaData_Deployed(uint256 indexed at);

    event MetaData_TokenRequest(
        uint256 indexed tokenId,
        uint256 indexed requestId
    );

    event MetaData_ArtworkRevealed(
        uint256 indexed tokenId,
        uint256 indexed requestId,
        bytes32 indexed artworkId
    );

    event MetaData_LegendaryDraw(
        uint256 indexed tokenId,
        uint256 indexed legendaryId
    );

    event MetaData_ScratchedOff(
        uint256 indexed tokenId,
        uint256 indexed requestId,
        uint256 indexed scratchedOffNum,
        bool winner
    );

    event MetaData_PrizeRevealed(
        uint256 indexed tokenId,
        uint256 indexed requestId,
        uint256 indexed prize
    );

    event MetaData_ArtworkIPFSUrlUpdated(
        uint256 indexed tokenId,
        string indexed ipfsUrl
    );

    event MetaData_SecondChancePrizePoolOpened(uint256 indexed poolId);

    event MetaData_PrizeCategoryExhausted(uint256 indexed prize);

    event MetaData_PrizeClaimed(uint256 indexed tokenId, uint256 indexed prize);

    function requestNextStepFor(uint256 tokenId) external;

    function getTokenMetaData(
        uint256 tokenId
    ) external view returns (TokenMetaData memory);

    function setSecondChanceAddress(IPrizePools secondChance) external;

    function getPrizes() external view returns (uint256[][] memory);

    function setArtworkIPFSUrl(uint256 tokenId, string memory ipfsUrl) external;

    function setClaimed(uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

error PrizePools_PrizePoolNotFound(uint256 id);
error PrizePools_UpkeepNotNecessary();
error PrizePools_PoolNotOpen(uint256 id);
error PrizePools_PoolNotReadyForRaffle(uint256 remainingTime);
error PrizePools_Unauthorized();
error PrizePools_RaffleTokenCountMismatch(uint256 poolId);
error PrizePools_UserAlreadyRegisteredIn(uint256 poolId);
error PrizePools_PoolClosedForRegistration(uint256 poolId);

interface IPrizePools {
    struct Winner {
        address user;
        uint256 prize;
    }

    struct TokenValidity {
        uint256 tokenId;
        bool eligible;
    }

    struct PrizePool {
        uint16 id;
        uint32 opensAt;
        uint32 openUntil;
        bool isOpen;
        bool isPaid;
        string name;
        address[] registeredUsers;
        address[] winners;
        uint256[] prizes;
        uint16[][] userEntryChunks;
    }

    struct PoolChunk {
        uint16 poolId;
        uint16 iteration;
        uint16 size;
    }

    event PrizePools_PoolCreated(
        string indexed name,
        uint256 indexed poolId,
        uint256 indexed opensAt
    );

    event PrizePools_PoolOpened(
        uint256 indexed poolId,
        uint256 indexed openUntil
    );
    event PrizePools_RaffleInitiated(
        uint256 indexed poolId,
        uint256 indexed requestId
    );

    event PrizePools_RaffleResults(
        uint256 indexed poolId,
        address[] indexed winners
    );

    event PrizePools_UserRegisteredIntoPool(
        address indexed user,
        uint256 indexed poolId
    );

    function openPrizePool(uint256 id, uint32 openForSeconds) external;

    function registerUser(uint256 poolId, address user) external;

    function getPrizePools() external view returns (PrizePool[] memory);

    function needsToOpenPool(
        uint256 scratchedOffCount
    ) external view returns (bool, uint256);

    function calculateEntries(
        uint16 numOfScratchedTickets
    ) external pure returns (uint16);

    function validateEligibleTokenIds(
        uint256[] calldata tokenIds
    ) external view returns (TokenValidity[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "./interfaces/IMetaData.sol";
import "./interfaces/IPrizePools.sol";
import "./utils/RandomUtils.sol";
import "./utils/ArrayUtils.sol";

contract PrizePools is IPrizePools, VRFConsumerBaseV2, Ownable {
    using UintArrayUtils for uint16[];

    uint16 private constant REQUEST_CONFIRMATIONS = 3;

    bytes32 private immutable i_keyHash;
    uint32 private immutable i_callbackGasLimit;
    uint64 private immutable i_subscriptionId;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;

    IMetaData private immutable i_metaData;

    mapping(uint256 => bytes) private s_poolOpenings;
    mapping(uint256 => PoolChunk) private s_requestIdToPoolChunk;

    mapping(address => mapping(uint256 => bool)) private s_userCursor;
    mapping(address => mapping(uint256 => bool)) private s_winnerCursor;

    PrizePool[] private s_pools;

    constructor(
        // VRF Requirements
        uint64 subscriptionId,
        bytes32 keyHash,
        uint32 callbackGasLimit,
        address vrfCoordinator,
        // VRF Requirements
        IMetaData metaData,
        uint16[] memory prizePoolsPoolOpenings,
        uint256[][] memory prizePoolsPrizes
    ) Ownable() VRFConsumerBaseV2(vrfCoordinator) {
        i_subscriptionId = subscriptionId;
        i_keyHash = keyHash;
        i_callbackGasLimit = callbackGasLimit;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_metaData = metaData;

        uint256 salt = 1337;

        unchecked {
            for (uint256 id = 0; id < prizePoolsPoolOpenings.length; id++) {
                addPrizePool(
                    string.concat("SecondChance #", Strings.toString(id)),
                    prizePoolsPoolOpenings[id],
                    prizePoolsPrizes[id]
                );

                s_poolOpenings[prizePoolsPoolOpenings[id]] = abi.encodePacked(
                    id,
                    salt
                );
            }
        }
    }

    function addPrizePool(
        string memory name,
        uint32 opensAt,
        uint256[] memory prizes
    ) public onlyOwner {
        PrizePool memory pool = createPrizePool(
            uint16(s_pools.length),
            opensAt,
            prizes,
            name
        );

        s_pools.push(pool);

        emit PrizePools_PoolCreated(pool.name, pool.id, pool.opensAt);
    }

    function openPrizePool(
        uint256 poolId,
        uint32 openForSeconds
    ) external override {
        if (poolId > s_pools.length - 1) {
            revert PrizePools_PrizePoolNotFound(poolId);
        }

        if (msg.sender != address(i_metaData) && msg.sender != owner()) {
            revert PrizePools_Unauthorized();
        }

        PrizePool memory pool = s_pools[poolId];

        pool.isOpen = true;
        pool.openUntil = uint32(block.timestamp) + openForSeconds;

        s_pools[poolId] = pool;

        emit PrizePools_PoolOpened(poolId, pool.openUntil);
    }

    function registerUser(
        uint256 poolId,
        address user
    ) external override onlyOwner {
        if (poolId > s_pools.length - 1) {
            revert PrizePools_PrizePoolNotFound(poolId);
        }

        if (!s_pools[poolId].isOpen) {
            revert PrizePools_PoolNotOpen(poolId);
        }

        if (s_userCursor[user][poolId] == true) {
            revert PrizePools_UserAlreadyRegisteredIn(poolId);
        }

        if (s_pools[poolId].openUntil < block.timestamp) {
            revert PrizePools_PoolClosedForRegistration(poolId);
        }

        s_pools[poolId].registeredUsers.push(user);
        s_userCursor[user][poolId] = true;

        emit PrizePools_UserRegisteredIntoPool(user, poolId);
    }

    function initiateRaffle(uint16 poolId, uint8[] memory numOfTokens) public {
        if (msg.sender != owner() && msg.sender != address(i_vrfCoordinator)) {
            revert PrizePools_Unauthorized();
        }

        if (!s_pools[poolId].isOpen) {
            revert PrizePools_PoolNotOpen(poolId);
        }

        if (s_pools[poolId].openUntil > block.timestamp) {
            revert PrizePools_PoolNotReadyForRaffle(
                s_pools[poolId].openUntil - block.timestamp
            );
        }

        if (s_pools[poolId].registeredUsers.length != numOfTokens.length) {
            revert PrizePools_RaffleTokenCountMismatch(poolId);
        }

        s_pools[poolId].isOpen = false;

        uint16 chunkSize = uint16(
            numOfTokens.length / s_pools[poolId].prizes.length
        );

        uint16[] memory userEntries = new uint16[](
            s_pools[poolId].registeredUsers.length
        );

        unchecked {
            for (uint256 i = 0; i < numOfTokens.length; i++) {
                userEntries[i] = calculateEntries(uint16(numOfTokens[i]));
            }
        }

        unchecked {
            for (uint256 i = 0; i < s_pools[poolId].prizes.length; i++) {
                uint256 chunkStart = chunkSize * i;
                uint256 chunkEnd = chunkStart + chunkSize;

                if (
                    i == s_pools[poolId].prizes.length - 1 &&
                    chunkEnd < userEntries.length
                ) {
                    chunkEnd = userEntries.length;
                }

                s_pools[poolId].userEntryChunks.push(
                    userEntries.slice(chunkStart, chunkEnd)
                );
            }
        }

        initiateVRF(poolId, 0, chunkSize);
    }

    function initiateVRF(
        uint16 poolId,
        uint16 iteration,
        uint16 chunkSize
    ) internal {
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            10
        );

        s_requestIdToPoolChunk[requestId] = PoolChunk(
            poolId,
            iteration,
            chunkSize
        );

        emit PrizePools_RaffleInitiated(poolId, requestId);
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        uint256 offset = 0;
        PoolChunk memory chunk = s_requestIdToPoolChunk[requestId];

        uint32 totalEntries = uint32(
            s_pools[chunk.poolId].userEntryChunks[chunk.iteration].sum()
        );

        uint256 winnerIndex = RandomUtils.weightDistributedRandom(
            randomWords[offset],
            s_pools[chunk.poolId].userEntryChunks[chunk.iteration],
            totalEntries,
            true
        );

        address winner = s_pools[chunk.poolId].registeredUsers[
            chunk.iteration * chunk.size + winnerIndex
        ];

        while (s_winnerCursor[winner][chunk.poolId]) {
            offset++;

            winnerIndex = RandomUtils.weightDistributedRandom(
                randomWords[offset],
                s_pools[chunk.poolId].userEntryChunks[chunk.iteration],
                totalEntries,
                true
            );

            winner = s_pools[chunk.poolId].registeredUsers[
                chunk.iteration * chunk.size + winnerIndex
            ];
        }

        s_pools[chunk.poolId].winners.push(winner);
        s_winnerCursor[winner][chunk.poolId] = true;

        if (
            s_pools[chunk.poolId].winners.length <
            s_pools[chunk.poolId].prizes.length
        ) {
            initiateVRF(chunk.poolId, ++chunk.iteration, chunk.size);
        } else {
            s_pools[chunk.poolId].winners = RandomUtils.shuffle(
                s_pools[chunk.poolId].winners,
                randomWords[0]
            );

            emit PrizePools_RaffleResults(
                chunk.poolId,
                s_pools[chunk.poolId].winners
            );
        }
    }

    function setPaid(uint256 poolId) external onlyOwner {
        s_pools[poolId].isPaid = true;
    }

    function calculateEntries(
        uint16 numOfScratchedTickets
    ) public pure override returns (uint16) {
        if (numOfScratchedTickets >= 1 && numOfScratchedTickets < 5) {
            return numOfScratchedTickets * 10;
        }

        if (numOfScratchedTickets >= 5 && numOfScratchedTickets < 10) {
            return numOfScratchedTickets * 15;
        }

        if (numOfScratchedTickets >= 10 && numOfScratchedTickets < 15) {
            return numOfScratchedTickets * 20;
        }

        if (numOfScratchedTickets >= 15 && numOfScratchedTickets < 20) {
            return numOfScratchedTickets * 25;
        }

        if (numOfScratchedTickets >= 20 && numOfScratchedTickets < 25) {
            return numOfScratchedTickets * 30;
        }

        if (numOfScratchedTickets >= 25 && numOfScratchedTickets < 30) {
            return numOfScratchedTickets * 35;
        }

        if (numOfScratchedTickets >= 30) {
            return 1200;
        }

        return 0;
    }

    function needsToOpenPool(
        uint256 scratchedOffCount
    ) external view override returns (bool, uint256) {
        bytes memory empty = new bytes(0);
        if (keccak256(s_poolOpenings[scratchedOffCount]) == keccak256(empty)) {
            return (false, 0);
        }

        (uint256 id, ) = abi.decode(
            s_poolOpenings[scratchedOffCount],
            (uint256, uint256)
        );

        return (true, id);
    }

    function validateEligibleTokenIds(
        uint256[] calldata tokenIds
    ) public view override returns (TokenValidity[] memory) {
        TokenValidity[] memory tokenValidity = new TokenValidity[](
            tokenIds.length
        );
        unchecked {
            for (uint256 i = 0; i < tokenIds.length; i++) {
                IMetaData.TokenMetaData memory metadata = i_metaData
                    .getTokenMetaData(tokenIds[i]);

                tokenValidity[i] = TokenValidity(
                    tokenIds[i],
                    metadata.status == IMetaData.NFTStatus.PRIZE_REVEALED &&
                        metadata.winner == false
                );
            }
        }

        return tokenValidity;
    }

    function getPrizePools() external view returns (PrizePool[] memory) {
        return s_pools;
    }

    function getWinners(
        uint256 poolId
    ) external view returns (Winner[] memory) {
        address[] memory winnerAddresses = s_pools[poolId].winners;
        uint256[] memory prizes = s_pools[poolId].prizes;

        Winner[] memory winners = new Winner[](winnerAddresses.length);

        unchecked {
            for (uint256 i = 0; i < winners.length; i++) {
                winners[i] = Winner(winnerAddresses[i], prizes[i]);
            }
        }

        return winners;
    }

    function createPrizePool(
        uint16 id,
        uint32 opensAt,
        uint256[] memory prizes,
        string memory name
    ) internal pure returns (PrizePool memory) {
        address[] memory users;
        uint16[][] memory entries;
        address[] memory winners;

        PrizePool memory pool = PrizePool({
            id: id,
            opensAt: opensAt,
            openUntil: 0,
            isOpen: false,
            isPaid: false,
            name: name,
            registeredUsers: users,
            winners: winners,
            prizes: prizes,
            userEntryChunks: entries
        });

        return pool;
    }
}

// SPDX-License-Identifier:MIT
pragma solidity ^0.8.17;

library AddressArrayUtils {
    function contains(
        address[] memory array,
        address addr
    ) public pure returns (bool) {
        unchecked {
            for (uint256 i = 0; i < array.length; ) {
                if (array[i++] == addr) return true;
            }

            return false;
        }
    }
}

library StringArrayUtils {
    function contains(
        string[] memory array,
        string memory str
    ) public pure returns (bool) {
        unchecked {
            for (uint256 i = 0; i < array.length; ) {
                if (keccak256(bytes(array[i++])) == keccak256(bytes(str)))
                    return true;
            }

            return false;
        }
    }
}

library UintArrayUtils {
    function contains(uint[] memory array, uint n) public pure returns (bool) {
        unchecked {
            for (uint256 i = 0; i < array.length; ) {
                if (array[i++] == n) return true;
            }

            return false;
        }
    }

    function sum(uint256[] memory array) public pure returns (uint256) {
        unchecked {
            uint256 result = 0;
            for (uint256 i = 0; i < array.length; i++) {
                result += array[i];
            }

            return result;
        }
    }

    function sum(uint16[] memory array) public pure returns (uint256) {
        unchecked {
            uint256 result = 0;
            for (uint256 i = 0; i < array.length; i++) {
                result += array[i];
            }

            return result;
        }
    }

    function slice(
        uint16[] memory array,
        uint256 from,
        uint256 to
    ) public pure returns (uint16[] memory) {
        uint16[] memory slicedArr = new uint16[](to - from);

        unchecked {
            for (uint256 i = 0; i < to - from; i++) {
                slicedArr[i] = array[i + from];
            }
        }

        return slicedArr;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./RandomUtils.sol";
import "./ArrayUtils.sol";

library ArtworkUtils {
    using UintArrayUtils for uint256[];

    uint256 private constant TOTAL_WEIGHT = 10000;

    enum ArtworkAtom {
        BACKGROUND,
        BODY,
        COLLAR,
        FACE,
        HEADWEAR,
        ITEM,
        PAWS,
        PILLOW,
        TICKET
    }

    struct Artwork {
        bytes32 id;
        uint256 background;
        uint256 body;
        uint256 collar;
        uint256 face;
        uint256 paws;
        uint256 headwear;
        uint256 item;
        uint256 pillow;
        uint256 ticket;
        uint256 legendary;
        string ipfsUrl;
    }

    function isLegendary(
        uint256 revealCount,
        uint256 legendaryRoll,
        uint256 legendaryId,
        uint256 totalLegendaries
    ) external pure returns (bool) {
        return legendaryRoll <= revealCount && legendaryId <= totalLegendaries;
    }

    function legendaryArtwork(
        uint256 legendaryId
    ) public pure returns (Artwork memory) {
        Artwork memory artwork = Artwork(
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            legendaryId,
            ""
        );

        artwork.id = artworkId(artwork);

        return artwork;
    }

    function calculateArtwork(
        uint256[] memory randomNumbers,
        uint256 offset,
        uint256[][] memory artworkWeights,
        uint256[] memory symmetricPaws
    ) public pure returns (Artwork memory) {
        Artwork memory artwork = Artwork(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, "");

        artwork.background = RandomUtils.weightDistributedRandom(
            randomNumbers[0 + offset],
            artworkWeights[uint(ArtworkAtom.BACKGROUND)],
            TOTAL_WEIGHT,
            false
        );
        artwork.body = RandomUtils.weightDistributedRandom(
            randomNumbers[1 + offset],
            artworkWeights[uint(ArtworkAtom.BODY)],
            TOTAL_WEIGHT,
            false
        );
        artwork.collar = RandomUtils.weightDistributedRandom(
            randomNumbers[2 + offset],
            artworkWeights[uint(ArtworkAtom.COLLAR)],
            TOTAL_WEIGHT,
            false
        );
        artwork.face = RandomUtils.weightDistributedRandom(
            randomNumbers[3 + offset],
            artworkWeights[uint(ArtworkAtom.FACE)],
            TOTAL_WEIGHT,
            false
        );

        artwork.headwear = RandomUtils.weightDistributedRandom(
            randomNumbers[5 + offset],
            artworkWeights[uint(ArtworkAtom.HEADWEAR)],
            TOTAL_WEIGHT,
            true
        );

        artwork.paws = RandomUtils.weightDistributedRandom(
            randomNumbers[4 + offset],
            artworkWeights[uint(ArtworkAtom.PAWS)],
            TOTAL_WEIGHT,
            false
        );

        artwork.pillow = RandomUtils.weightDistributedRandom(
            randomNumbers[6 + offset],
            artworkWeights[uint(ArtworkAtom.PILLOW)],
            TOTAL_WEIGHT,
            true
        );
        artwork.ticket = RandomUtils.weightDistributedRandom(
            randomNumbers[7 + offset],
            artworkWeights[uint(ArtworkAtom.TICKET)],
            TOTAL_WEIGHT,
            false
        );

        // defined in relation to hands
        if (!symmetricPaws.contains(artwork.paws)) {
            artwork.item = RandomUtils.weightDistributedRandom(
                randomNumbers[8 + offset],
                artworkWeights[uint(ArtworkAtom.ITEM)],
                TOTAL_WEIGHT,
                true
            );
        }

        artwork.id = artworkId(artwork);

        return artwork;
    }

    function artworkId(Artwork memory artwork) internal pure returns (bytes32) {
        artwork.id = keccak256(
            abi.encodePacked(
                artwork.background,
                artwork.body,
                artwork.collar,
                artwork.face,
                artwork.paws,
                artwork.headwear,
                artwork.item,
                artwork.pillow,
                artwork.ticket,
                artwork.legendary
            )
        );

        return artwork.id;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library RandomUtils {
    function evenlyDistributedRandom(
        uint256 randomNumber,
        uint256 totalOptions,
        bool fromZero
    ) public pure returns (uint256) {
        uint256 result = randomNumber % totalOptions;

        return fromZero ? result : result + 1;
    }

    function weightDistributedRandom(
        uint256 randomNumber,
        uint256[] memory weights,
        uint256 totalWeight,
        bool fromZero
    ) public pure returns (uint256) {
        uint256 result;

        uint256 weighed = randomNumber % totalWeight;
        uint256 currentWeight = 0;
        uint256 length = weights.length;

        unchecked {
            for (uint i = 0; i < length; i++) {
                currentWeight = currentWeight + weights[i];
                if (weighed < currentWeight) {
                    result = i;

                    break;
                }
            }
        }

        return fromZero ? result : result + 1;
    }

    function weightDistributedRandom(
        uint256 randomNumber,
        uint16[] memory weights,
        uint256 totalWeight,
        bool fromZero
    ) public pure returns (uint256) {
        uint256 result;

        uint256 weighed = randomNumber % totalWeight;
        uint256 currentWeight = 0;
        uint256 length = weights.length;

        unchecked {
            for (uint i = 0; i < length; i++) {
                currentWeight = currentWeight + weights[i];
                if (weighed < currentWeight) {
                    result = i;

                    break;
                }
            }
        }

        return fromZero ? result : result + 1;
    }

    function shuffle(
        address[] memory array,
        uint256 randomNumber
    ) public pure returns (address[] memory) {
        for (uint256 i = 0; i < array.length; i++) {
            uint256 n = i +
                (uint256(keccak256(abi.encodePacked(randomNumber))) %
                    (array.length - i));
            address temp = array[n];
            array[n] = array[i];
            array[i] = temp;
        }

        return array;
    }
}