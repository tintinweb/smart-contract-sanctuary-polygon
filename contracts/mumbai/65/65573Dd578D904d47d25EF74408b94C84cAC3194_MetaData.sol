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
    error MetaData_RequestNotInProgress(uint256 tokenId);

    enum NFTStatus {
        INITIAL,
        ARTWORK_REVEALED,
        SCRATCHED,
        PRIZE_REVEALED
    }

    struct TokenMetaData {
        uint256 id;
        uint256 prize;
        uint256 scratchedNum;
        NFTStatus status;
        bool inProgress;
        bool winner;
        bool claimed;
        ArtworkUtils.Artwork artwork;
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

    event MetaData_DuplicateArtwork(
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
error PrizePools_PoolFull(uint256 poolId);

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
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "./interfaces/IPrizePools.sol";
import "./interfaces/IMetaData.sol";
import "./utils/ArtworkUtils.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract MetaData is IMetaData, VRFConsumerBaseV2, Ownable {
    uint16 private constant REQUEST_CONFIRMATIONS = 3;

    uint256 private immutable i_totalSupply;
    bytes32 private immutable i_keyHash;
    uint32 private immutable i_callbackGasLimit;
    uint64 private immutable i_subscriptionId;
    uint256 private immutable i_legendaries;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;

    uint256 private s_revealCount = 0;
    uint256 private s_scratchedOffCount = 0;
    uint256 private s_winnerCount;
    uint256 private s_loserCount;
    uint256[][] private s_artworkWeights;
    uint256[] private s_symmetricHands;
    uint256[][] private s_prizes;
    uint256 public s_legendaryIndex = 1;
    mapping(bytes32 => bool) s_artworkRegistry;
    mapping(uint256 => TokenMetaData) s_tokenMetaData;
    mapping(uint256 => uint256) s_requestIdToTokenId;
    IPrizePools private s_prizePools;

    constructor(
        uint256 totalSupply,
        uint256 winnerCount,
        uint64 subscriptionId,
        bytes32 keyHash,
        uint32 callbackGasLimit,
        address vrfCoordinator,
        uint256[][] memory artworkWeigths,
        uint256[] memory symmetricHands,
        uint256[2][] memory prizes,
        uint256 legendaries
    ) Ownable() VRFConsumerBaseV2(vrfCoordinator) {
        i_totalSupply = totalSupply;
        i_subscriptionId = subscriptionId;
        i_keyHash = keyHash;
        i_callbackGasLimit = callbackGasLimit;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_legendaries = legendaries;

        s_winnerCount = winnerCount;
        s_loserCount = i_totalSupply - winnerCount;
        s_artworkWeights = artworkWeigths;
        s_symmetricHands = symmetricHands;

        s_prizes = prizes;

        emit MetaData_Deployed(block.timestamp);
    }

    function requestNextStepFor(uint256 tokenId) public onlyOwner {
        if (tokenId >= i_totalSupply) {
            revert MetaData_TokenIdOutOfBounds();
        }

        TokenMetaData storage metaData = s_tokenMetaData[tokenId];

        if (metaData.status == NFTStatus.PRIZE_REVEALED) {
            revert MetaData_AlreadyInFinalState();
        }

        if (metaData.inProgress) {
            revert MetaData_RequestAlreadyInProgress(
                tokenId,
                NFTStatus(uint(metaData.status) + 1)
            );
        }

        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            100
        );

        s_tokenMetaData[tokenId].inProgress = true;
        s_requestIdToTokenId[requestId] = tokenId;

        emit MetaData_TokenRequest(tokenId, requestId);
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        uint256 tokenId = s_requestIdToTokenId[requestId];
        TokenMetaData storage metaData = s_tokenMetaData[tokenId];
        NFTStatus status = metaData.status;

        if (!metaData.inProgress) {
            revert MetaData_RequestNotInProgress(tokenId);
        }

        if (status == NFTStatus.INITIAL) {
            revealArtwork(tokenId, metaData, requestId, randomWords);
        } else if (status == NFTStatus.ARTWORK_REVEALED) {
            scratchOff(tokenId, metaData, requestId, randomWords);

            (bool shouldOpenPool, uint256 poolId) = s_prizePools
                .needsToOpenPool(s_scratchedOffCount);

            if (shouldOpenPool) {
                s_prizePools.openPrizePool(poolId, 4 hours);

                emit MetaData_SecondChancePrizePoolOpened(poolId);
            }
        } else if (status == NFTStatus.SCRATCHED && metaData.winner) {
            revealPrize(tokenId, metaData, requestId, randomWords);
        }
    }

    function getPrizes() public view override returns (uint256[][] memory) {
        return s_prizes;
    }

    function setArtworkIPFSUrl(
        uint256 tokenId,
        string memory ipfsUrl
    ) external override onlyOwner {
        s_tokenMetaData[tokenId].artwork.ipfsUrl = ipfsUrl;

        emit MetaData_ArtworkIPFSUrlUpdated(tokenId, ipfsUrl);
    }

    function setClaimed(uint256 tokenId) external override onlyOwner {
        TokenMetaData memory metaData = s_tokenMetaData[tokenId];

        if (
            metaData.status != NFTStatus.PRIZE_REVEALED ||
            !metaData.winner ||
            metaData.prize == 0
        ) {
            revert MetaData_TokenCurrentlyNotClaimable(
                metaData.status,
                metaData.winner,
                metaData.prize
            );
        }

        metaData.claimed = true;
        s_tokenMetaData[tokenId] = metaData;

        emit MetaData_PrizeClaimed(tokenId, metaData.prize);
    }

    function setSecondChanceAddress(
        IPrizePools prizePools
    ) external override onlyOwner {
        s_prizePools = prizePools;
    }

    function getTokenMetaData(
        uint256 tokenId
    ) external view returns (TokenMetaData memory) {
        return s_tokenMetaData[tokenId];
    }

    function queryMetaData(
        uint256[] calldata tokenIds,
        NFTStatus[] calldata statuses
    ) external view returns (TokenMetaData[] memory) {
        uint256 length;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            for (uint256 j = 0; j < statuses.length; j++) {
                if (s_tokenMetaData[tokenIds[i]].status == statuses[j]) {
                    length++;
                }
            }
        }

        TokenMetaData[] memory metaDatas = new TokenMetaData[](length);
        uint256 index = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            for (uint256 j = 0; j < statuses.length; j++) {
                TokenMetaData memory metaData = s_tokenMetaData[tokenIds[i]];

                if (metaData.status == statuses[j]) {
                    metaDatas[index] = metaData;
                    index++;
                }
            }
        }

        return metaDatas;
    }

    function removePrize(uint256 index) private {
        if (index >= s_prizes.length) return;

        for (uint i = index; i < s_prizes.length - 1; i++) {
            s_prizes[i] = s_prizes[i + 1];
        }

        s_prizes.pop();
    }

    function revealArtwork(
        uint256 tokenId,
        TokenMetaData storage metaData,
        uint256 requestId,
        uint256[] memory randomWords
    ) private {
        uint256 revealCount = s_revealCount;
        uint256 legendaryId = s_legendaryIndex;
        ArtworkUtils.Artwork memory artwork;

        uint256 legendaryPeriod = i_totalSupply / i_legendaries;

        if (
            ArtworkUtils.isLegendary(
                revealCount,
                legendaryPeriod,
                legendaryId,
                i_legendaries
            )
        ) {
            artwork = ArtworkUtils.legendaryArtwork(legendaryId);

            s_legendaryIndex = legendaryId + 1;

            emit MetaData_LegendaryDraw(tokenId, legendaryId);
        } else {
            uint256 offset = 0;

            artwork = ArtworkUtils.calculateArtwork(
                randomWords,
                offset,
                s_artworkWeights,
                s_symmetricHands
            );

            if (s_artworkRegistry[artwork.id]) {
                emit MetaData_DuplicateArtwork(tokenId, requestId, artwork.id);

                for (uint256 i = 0; i < randomWords.length; i++) {
                    artwork = ArtworkUtils.calculateArtwork(
                        randomWords,
                        ++offset,
                        s_artworkWeights,
                        s_symmetricHands
                    );

                    if (!s_artworkRegistry[artwork.id]) {
                        break;
                    }
                }
            }
        }

        s_revealCount = revealCount + 1;
        s_artworkRegistry[artwork.id] = true;
        metaData.id = tokenId;
        metaData.artwork = artwork;
        metaData.status = NFTStatus.ARTWORK_REVEALED;
        metaData.inProgress = false;

        emit MetaData_ArtworkRevealed(tokenId, requestId, artwork.id);
    }

    function scratchOff(
        uint256 tokenId,
        TokenMetaData storage metaData,
        uint256 requestId,
        uint256[] memory randomWords
    ) private {
        uint256 winnerCount = s_winnerCount;
        uint256 loserCount = s_loserCount;

        uint256 outcome = randomWords[0] % (winnerCount + loserCount);
        bool isWinner = outcome < winnerCount;
        if (isWinner) {
            metaData.status = NFTStatus.SCRATCHED;
            s_winnerCount = winnerCount - 1;
        } else {
            metaData.status = NFTStatus.PRIZE_REVEALED;
            s_loserCount = loserCount - 1;
        }

        metaData.scratchedNum = ++s_scratchedOffCount;
        metaData.winner = isWinner;
        metaData.inProgress = false;

        emit MetaData_ScratchedOff(
            tokenId,
            requestId,
            metaData.scratchedNum,
            isWinner
        );
    }

    function revealPrize(
        uint256 tokenId,
        TokenMetaData storage metaData,
        uint256 requestId,
        uint256[] memory randomWords
    ) private {
        uint256[] memory weights = new uint256[](s_prizes.length);
        uint256 totalWeight = 0;

        for (uint256 i = 0; i < weights.length; i++) {
            weights[i] = s_prizes[i][1];
            totalWeight += weights[i];
        }

        uint256 prizeIndex = RandomUtils.weightDistributedRandom(
            randomWords[0],
            weights,
            totalWeight,
            true
        );

        uint256 prize = s_prizes[prizeIndex][0];

        s_prizes[prizeIndex][1] -= 1;

        if (s_prizes[prizeIndex][1] == 0) {
            removePrize(prizeIndex);

            emit MetaData_PrizeCategoryExhausted(prize);
        }

        metaData.prize = prize;
        metaData.status = NFTStatus.PRIZE_REVEALED;
        metaData.inProgress = false;

        emit MetaData_PrizeRevealed(tokenId, requestId, metaData.prize);
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

    function initArtwork() public pure returns (Artwork memory) {
        return Artwork(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, "");
    }

    function isLegendary(
        uint256 revealCount,
        uint256 legendaryPeriod,
        uint256 legendaryId,
        uint256 totalLegendaries
    ) external pure returns (bool) {
        return
            revealCount != 0 &&
            revealCount % legendaryPeriod == 0 &&
            legendaryId <= totalLegendaries;
    }

    function legendaryArtwork(
        uint256 legendaryId
    ) public pure returns (Artwork memory) {
        Artwork memory artwork = initArtwork();

        artwork.legendary = legendaryId;
        artwork.id = artworkId(artwork);

        return artwork;
    }

    function calculateArtwork(
        uint256[] memory randomNumbers,
        uint256 offset,
        uint256[][] memory artworkWeights,
        uint256[] memory symmetricPaws
    ) public pure returns (Artwork memory) {
        Artwork memory artwork = initArtwork();

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