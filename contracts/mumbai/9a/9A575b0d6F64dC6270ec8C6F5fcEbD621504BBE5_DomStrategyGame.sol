/**
 *Submitted for verification at polygonscan.com on 2022-10-24
*/

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

// File: Domination.sol


pragma solidity 0.8.17;








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
    uint256 membersCount;
    uint256 maxMembers;
    uint256 totalBalance; // used for calc cut of spoils in win condition
    string name;
}

struct JailCell {
    uint256 x;
    uint256 y;
}

enum GameStage {
    Submit,
    Reveal,
    Resolve
}

contract DomStrategyGame is IERC721Receiver, AutomationCompatible, VRFConsumerBaseV2 {
    JailCell public jailCell;
    mapping(address => Player) public players;
    mapping(uint256 => Alliance) public alliances;
    mapping(uint256 => address[]) public allianceMembers;
    mapping(uint256 => address) public allianceAdmins;
    mapping(address => uint256) public spoils;
    mapping(uint256 => mapping(uint256 => address)) public playingField;

    // bring your own NFT kinda
    // BAYC, Sappy Seal, Pudgy Penguins, Azuki, Doodles
    // address[] allowedNFTs = [
    //     0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D, 0x364C828eE171616a39897688A831c2499aD972ec, 0xBd3531dA5CF5857e7CfAA92426877b022e612cf8, 0xED5AF388653567Af2F388E6224dC7C4b3241C544, 0x8a90CAb2b38dba80c64b7734e58Ee1dB38B8992e
    // ];

    // Keepers
    uint256 public interval;
    uint256 public lastUpkeepTimestamp;
    uint256 public gameStartTimestamp;
    bool public gameStarted;
    bool public isFirstUpkeep = true;

    // VRF
    VRFCoordinatorV2Interface immutable COORDINATOR;
    LinkTokenInterface immutable LINKTOKEN;
    address public vrf_owner;
    uint256 public randomness;
    uint256 public vrf_requestId;
    bytes32 immutable vrf_keyHash;
    uint16 immutable vrf_requestConfirmations = 3;
    uint32 immutable vrf_callbackGasLimit = 2_500_000;
    uint32 immutable vrf_numWords = 3;
    uint64 public vrf_subscriptionId;

    // Game
    uint256 public currentTurn;
    uint256 public currentTurnStartTimestamp;
    uint256 public constant maxPlayers = 100;
    uint256 public activePlayersCount;
    uint256 public activeAlliances;
    uint256 public winningTeamSpoils;
    uint256 public nextAvailableRow = 0;// TODO make random to prevent position sniping...?
    uint256 public nextAvailableCol = 0;
    uint256 public winnerAllianceId;
    uint256 public fieldSize;
    uint256 internal nextInmateId = 0;
    uint256 internal inmatesCount = 0;
    uint256 nextAvailableAllianceId = 1; // start at 1 because 0 means you ain't joined one yet
    address public winnerPlayer;
    address[] public inmates = new address[](maxPlayers);
    address[] activePlayers;
    
    GameStage public gameStage;

    error LoserTriedWithdraw();
    error OnlyWinningAllianceMember();

    event ReturnedRandomness(uint256[] randomWords);
    event Constructed(address indexed owner, uint64 indexed subscriptionId, uint256 indexed _gameStartTimestamp);
    event Joined(address indexed addr);
    event TurnStarted(uint256 indexed turn, uint256 timestamp);
    event Submitted(
        address indexed addr,
        uint256 indexed turn,
        bytes32 commitment
    );
    event Revealed(
        address indexed addr,
        uint256 indexed turn,
        bytes32 nonce,
        bytes data
    );
    event BadMovePenalty(
        uint256 indexed turn,
        address indexed player,
        bytes details
    );
    event NoReveal(
        address indexed who,
        uint256 indexed turn
    );
    event NoSubmit(
        address indexed who,
        uint256 indexed turn
    );
    event AllianceCreated(
        address indexed admin,
        uint256 indexed allianceId,
        string name
    );
    event AllianceMemberJoined(
        uint256 indexed allianceId,
        address indexed player
    );
    event AllianceMemberLeft(
        uint256 indexed allianceId,
        address indexed player
    );
    event FirstUpkeep();
    event UpkeepCheck(uint256 indexed currentTimestamp, uint256 indexed lastUpkeepTimestamp, bool indexed upkeepNeeded);
    event BattleCommenced(address indexed player1, address indexed defender);
    event BattleFinished(address indexed winner, uint256 indexed spoils);
    event DamageDealt(address indexed by, address indexed to, uint256 indexed amount);
    event Move(address indexed who, uint newX, uint newY);
    event NftConfiscated(address indexed who, address indexed nftAddress, uint256 indexed tokenId);
    event WinnerPlayer(address indexed winner);
    event WinnerAlliance(uint indexed allianceId);
    event WinnerWithdrawSpoils(address indexed winner, uint256 indexed spoils);
    event Jail(address indexed who, uint256 indexed inmatesCount);
    event AttemptJailBreak(address indexed who, uint256 x, uint256 y);
    event JailBreak(address indexed who, uint256 newInmatesCount);
    event GameStartDelayed(uint256 indexed newStartTimeStamp);
    event SkipInmateTurn(address indexed who, uint256 indexed turn);
    event RolledDice(uint256 indexed turn, uint256 indexed vrf_request_id);
    event NewGameStage(GameStage indexed newGameStage);

    constructor(
        uint256 updateInterval) VRFConsumerBaseV2(0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed) 
    payable {
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
        gameStartTimestamp = block.timestamp + updateInterval;

        emit Constructed(vrf_owner, vrf_subscriptionId, gameStartTimestamp);
    }

    function connect(uint256 tokenId, address byoNft) external payable {
        require(currentTurn == 0, "Already started");
        require(spoils[msg.sender] == 0, "Already joined");
        require(players[msg.sender].addr == address(0), "Already joined");
        // Your share of the spoils if you win as part of an alliance are proportional to how much you paid to connect.
        require(msg.value > 0, "Send some eth");

        // N.B. for now just verify ownership, later maybe put it up as collateral as the spoils, instead of the ETH balance.
        // prove ownership of one of the NFTs in the allowList
        uint256 nftBalance = IERC721(byoNft).balanceOf(msg.sender);
        require(nftBalance > 0, "You dont own this NFT you liar");

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
        activePlayers.push(msg.sender);
        // every independent player initially gets counted as an alliance, when they join or leave  or die, retally
        activeAlliances += 1;
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

        jailCell = JailCell({ x: randomness / 1e75, y: randomness % 99});

        emit TurnStarted(currentTurn, currentTurnStartTimestamp);
    }

    function submit(uint256 turn, bytes32 commitment) external {
        require(currentTurn > 0, "Not started");
        require(turn == currentTurn, "Stale tx");
        // submit stage is interval set by deployer
        require(block.timestamp <= currentTurnStartTimestamp + interval, "Submit stage has passed.");

        players[msg.sender].pendingMoveCommitment = commitment;

        emit Submitted(msg.sender, currentTurn, commitment);
    }

    function reveal(
        uint256 turn,
        bytes32 nonce,
        bytes calldata data
    ) external {
        require(turn == currentTurn, "Stale tx");
        // then another interval for the reveal stage
        require(block.timestamp > currentTurnStartTimestamp + interval, "Reveal Stage has not started yet");
        require(block.timestamp < currentTurnStartTimestamp + interval * 2, "Reveal Stage has passed");

        bytes32 commitment = players[msg.sender].pendingMoveCommitment;
        bytes32 proof = keccak256(abi.encodePacked(turn, nonce, data));

        // console.log("=== commitment ===");
        // console.logBytes32(commitment);

        // console.log("=== proof ===");
        // console.logBytes32(proof);

        require(commitment == proof, "No cheating");

        players[msg.sender].pendingMove = data;

        emit Revealed(msg.sender, currentTurn, nonce, data);
    }

    // The turns are processed in random order. The contract offloads sorting the players
    // list off-chain to save gas
    function resolve() internal {
        require(randomness != 0, "Roll the die first");
        require(block.timestamp > currentTurnStartTimestamp + interval);

        if (currentTurn % 5 == 0) {
            fieldSize -= 2;
        }

        // TODO: this will exceed block gas limit eventually, need to split `resolve` in a way that it can be called incrementally
        // TODO: don't start at 0 every time, use vrf or some heuristic
        for (uint256 i = 0; i < activePlayersCount; i++) {
            address addr = activePlayers[i];

            Player storage player = players[addr];

            // If you're in jail you no longer get to do shit. Just hope somebody breaks you out.
            if (player.inJail) {
                emit SkipInmateTurn(player.addr, currentTurn);
                continue;
            }
            
            // If player straight up didn't submit then confiscate their NFT and send to jail
            if (player.pendingMoveCommitment == bytes32(0)) {
                emit NoSubmit(player.addr, currentTurn);

                IERC721(player.nftAddress).safeTransferFrom(player.addr, address(this), player.tokenId);

                emit NftConfiscated(player.addr, player.nftAddress, player.tokenId);

                sendToJail(player.addr);
                continue;
            } else if (player.pendingMoveCommitment != bytes32(0) && player.pendingMove.length == 0) { // If player submitted but forgot to reveal, move them to jail
                emit NoReveal(player.addr, currentTurn);
                sendToJail(player.addr);
                // if you are in jail but your alliance wins, you still get a cut of the spoils
                continue;
            }

            (bool success, bytes memory err) = address(this).call(player.pendingMove);

            if (!success) {
                // Player submitted a bad move
                if (int(player.balance - 0.05 ether) >= 0) {
                    player.balance -= 0.05 ether;
                    spoils[player.addr] == player.balance;
                    emit BadMovePenalty(currentTurn, player.addr, err);
                } else {
                    sendToJail(player.addr);
                }
            }

            // Outside the field, apply storm damage
            if (player.x > fieldSize || player.y > fieldSize) {
                if (int(player.hp - 10) >= 0) {
                    player.hp -= 10;
                    emit DamageDealt(address(this), player.addr, 10);
                } else {
                    // if he dies, spoils just get added to the total winningTeamSpoils and he goes to jail
                    winningTeamSpoils += spoils[player.addr];
                    sendToJail(player.addr);
                }
            }

            player.pendingMove = "";
            player.pendingMoveCommitment = bytes32(0);
        }

        randomness = 0;
        currentTurn += 1;
        currentTurnStartTimestamp = block.timestamp;

        emit TurnStarted(currentTurn, currentTurnStartTimestamp);
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

        if (checkIfCanAttack(invader.addr, currentOccupant)) {
            _battle(player, currentOccupant);
        } else {
            playingField[invader.x][invader.y] = address(0);
            invader.x = newX;
            invader.y = newY;
        }
        // TODO: Change order after
        emit Move(invader.addr, invader.x, invader.y);
        playingField[invader.x][invader.y] = player;
        
    }

    function rest(address player) external onlyViaSubmitReveal {
        players[player].hp += 2;
    }

    function createAlliance(address player, uint256 maxMembers, string calldata name) external onlyViaSubmitReveal {
        require(players[player].allianceId == 0, "Already in alliance");

        players[player].allianceId = nextAvailableAllianceId;
        allianceAdmins[nextAvailableAllianceId] = player;

        Alliance memory newAlliance = Alliance({
            admin: player,
            id: nextAvailableAllianceId,
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
        address admin = ecrecover(hash, v, r, s);

        require(allianceAdmins[allianceId] == admin, "Not signed by admin");
        players[player].allianceId = allianceId;
        
        Alliance memory alliance = alliances[allianceId];
        
        require(alliance.membersCount < alliance.maxMembers - 1, "Cannot exceed max members count.");

        alliances[allianceId].membersCount += 1;
        alliances[allianceId].totalBalance += players[player].balance;
        if (allianceMembers[allianceId].length > 0) {
            allianceMembers[allianceId].push(player);
        } else {
            allianceMembers[allianceId] = [player];
        }
        
        activeAlliances -= 1;

        emit AllianceMemberJoined(players[player].allianceId, player);
    }

    function leaveAlliance(address player) external onlyViaSubmitReveal {
        uint256 allianceId = players[player].allianceId;
        require(allianceId != 0, "Not in alliance");
        require(player != allianceAdmins[players[player].allianceId], "Admin canot leave alliance");

        players[player].allianceId = 0;
        
        for (uint256 i = 0; i < alliances[allianceId].membersCount; i++) {
            if (allianceMembers[allianceId][i] == player) {
                delete allianceMembers[i];
            }
        }

        alliances[allianceId].membersCount -= 1;
        alliances[allianceId].totalBalance -= players[player].balance;
        activeAlliances += 1;

        emit AllianceMemberLeft(allianceId, player);
    }
    
    function withdrawWinnerAlliance() onlyWinningAllianceMember external {
        uint256 winningAllianceTotalBalance = alliances[winnerAllianceId].totalBalance;
        uint256 withdrawerBalance = players[msg.sender].balance;
        uint256 myCut = (withdrawerBalance * winningTeamSpoils) / winningAllianceTotalBalance;

        (bool sent, ) = msg.sender.call{ value: myCut }("");

        require(sent, "Failed to withdraw spoils");
    }

    function withdrawWinnerPlayer() onlyWinner external {
        (bool sent, ) = winnerPlayer.call{ value: spoils[winnerPlayer] }("");
        require(sent, "Failed to withdraw winnings");
        spoils[winnerPlayer] = 0;
        emit WinnerWithdrawSpoils(winnerPlayer, spoils[winnerPlayer]);
    }

    /**** Internal Functions *****/

    function calcWinningAllianceSpoils() internal {
        require(winnerAllianceId != 0);
        
        address[] memory winners = allianceMembers[winnerAllianceId];

        uint256 totalSpoils = 0;

        for (uint256 i = 0; i < winners.length; i++) {
            totalSpoils += spoils[winners[i]];
        }

        winningTeamSpoils = totalSpoils;
    }

    function checkIfCanAttack(address meAddr, address otherGuyAddr) internal view returns (bool) {
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

        Player storage attacker = players[attackerAddr];
        Player storage defender = players[defenderAddr];

        require(attacker.allianceId == 0 || defender.allianceId == 0 || attacker.allianceId != defender.allianceId, "Allies do not fight");

        emit BattleCommenced(attackerAddr, defenderAddr);

        // take randomness, multiply it against attack to get what % of total attack damange is done to opponent's hp, make it at least 1
        uint256 effectiveDamage1 = (attacker.attack / (randomness % 99)) + 1;
        uint256 effectiveDamage2 = (defender.attack / (randomness % 99)) + 1;

        // Attacker goes first. There is an importance of who goes first, because if both have an effective damage enough to kill the other, the one who strikes first would win.
       if (int(defender.hp) - int(effectiveDamage1) <= 0) {// Case 2: player 2 lost
            // console.log("Attacker won");
            // Attacker moves to Defender's old spot
            attacker.x = defender.x;
            attacker.y = defender.y;
            playingField[attacker.x][attacker.y] = attacker.addr;

            // Defender vacates current position
            playingField[defender.x][defender.y] = address(0);
            // And then moves to jail
            sendToJail(defender.addr);

            // attacker takes defender's spoils
            spoils[attacker.addr] += spoils[defender.addr];
            spoils[defender.addr] = 0;
            
            // If Winner was in an Alliance
            if (attacker.allianceId != 0) {
                Alliance storage attackerAlliance = alliances[attacker.allianceId];
                attackerAlliance.totalBalance += spoils[defender.addr];
            }
                
            // If Loser was in an Alliance
            if (defender.allianceId != 0) {
                // Also will need to leave the alliance cuz ded
                Alliance storage defenderAlliance = alliances[defender.allianceId];
                defenderAlliance.totalBalance -= spoils[defender.addr];
                defenderAlliance.membersCount -= 1;
                defender.allianceId = 0;

                if (defenderAlliance.membersCount == 1) {
                    // if you're down to one member, ain't no alliance left
                    activeAlliances -= 1;
                    activePlayersCount -= 1;
                }

                // console.log("Defender was in an alliance: ", activeAlliances);

                if (activeAlliances == 1) {
                    winnerAllianceId = defenderAlliance.id;
                    calcWinningAllianceSpoils();
                    emit WinnerAlliance(winnerAllianceId);
                }
            } else {
                activePlayersCount -= 1;
                activeAlliances -= 1;

                Alliance storage attackerAlliance = alliances[attacker.allianceId];
                // console.log("Defender was NOT in an alliance: ", activeAlliances);
                if (activePlayersCount == 1) {
                    // win condition
                    winnerPlayer = attacker.addr;
                    emit WinnerPlayer(winnerPlayer);
                }

                if (activeAlliances == 1) {
                    winnerAllianceId = attackerAlliance.id;
                    calcWinningAllianceSpoils();
                    emit WinnerAlliance(winnerAllianceId);
                }
            }
        } else if (int(attacker.hp) - int(effectiveDamage2) <= 0) {
            // console.log("Defender won");
            // Defender remains where he is, Attack goes to jail

            // Attacker vacates current position
            playingField[attacker.x][attacker.y] = address(0);
            // And moves to jail
            sendToJail(attacker.addr);

            // Defender takes Attacker's spoils
            spoils[defender.addr] += spoils[attacker.addr];
            spoils[attacker.addr] = 0;

            // If Defender was in an Alliance
            if (defender.allianceId != 0) {
                Alliance storage defenderAlliance = alliances[defender.allianceId];
                defenderAlliance.totalBalance += spoils[attacker.addr];
            }

            // if Attacker was in an alliance
            if (attacker.allianceId != 0) {
                // Also will need to leave the alliance cuz ded
                Alliance storage attackerAlliance = alliances[attacker.allianceId];

                attackerAlliance.totalBalance -= spoils[attacker.addr];
                attackerAlliance.membersCount -= 1;
                attacker.allianceId = 0;

                if (attackerAlliance.membersCount == 1) {
                    // if you're down to one member, ain't no alliance left
                    activeAlliances -= 1;
                    activePlayersCount -= 1;
                }

                if (activeAlliances == 1) {
                    winnerAllianceId = attackerAlliance.id;
                    calcWinningAllianceSpoils();
                    emit WinnerAlliance(winnerAllianceId);
                }
            } else {
                activePlayersCount -= 1;

                if (activePlayersCount == 1) {
                    // win condition
                    winnerPlayer = defender.addr;
                    emit WinnerPlayer(winnerPlayer);
                }
            }
        } else {
            // console.log("Neither lost");
            attacker.hp -= effectiveDamage2;
            defender.hp -= effectiveDamage1;
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

    function _jailbreak(address breakerOuter) internal {
        // if it's greater than threshold everybody get out, including non alliance members
        if (randomness % 99 > 50) {
            for (uint256 i = 0; i < inmates.length; i++) {
                address inmate = inmates[i];
                if (inmate != address(0)) {
                    freeFromJail(inmate, i);
                }
            }
            inmates = new address[](maxPlayers); // everyone broke free so just reset
        } else {
            // if lower then roller gets jailed as well lol
            sendToJail(breakerOuter);
        }
    }

    // N.b right now the scope is to just free if somebody lands on the cell and rolls a good number.
    // could be fun to make an option for a player to bribe (pay some amount to free just alliance members)
    function freeFromJail(address playerAddress, uint256 inmateIndex) internal {
        Player storage player = players[playerAddress];

        player.hp = 50;
        player.x = jailCell.x;
        player.y = jailCell.y;
        player.inJail = false;

        delete inmates[inmateIndex];
        inmatesCount -= 1;

        emit JailBreak(player.addr, inmatesCount);
    }

    // TODO: Make internal 
    function sendToJail(address playerAddress) public {
        Player storage player = players[playerAddress];

        player.hp = 0;
        player.x = jailCell.x;
        player.y = jailCell.y;
        player.inJail = true;
        inmates[nextInmateId] = player.addr;
        nextInmateId += 1;
        inmatesCount += 1;

        emit Jail(player.addr, inmatesCount);
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

    function requestRandomWords() public onlyOwnerAndSelf {
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

    modifier onlyWinner() {
        if(msg.sender != winnerPlayer) {
            revert LoserTriedWithdraw();
        }
        _;
    }

    modifier onlyViaSubmitReveal() {
        require(msg.sender == address(this), "Only via submit/reveal");
        _;
    }

    function setSubscriptionId(uint64 subId) public onlyOwnerAndSelf {
        vrf_subscriptionId = subId;
    }

    function setOwner(address owner) public onlyOwnerAndSelf {
        vrf_owner = owner;
    }

     function checkUpkeep(bytes memory) public returns (bool, bytes memory) {
        bool upkeepNeeded = (block.timestamp - lastUpkeepTimestamp) >= interval;
        emit UpkeepCheck(block.timestamp, lastUpkeepTimestamp, upkeepNeeded);
        bytes memory performData = bytes("");

        return (upkeepNeeded, performData);
    }

    function performUpkeep(bytes calldata) external {
        if (isFirstUpkeep) {
            requestRandomWords();
            isFirstUpkeep = false;
            emit FirstUpkeep();
        }
        if (gameStarted) {
            (bool upkeepNeeded,) = checkUpkeep("");
            require(upkeepNeeded, "Time interval not met.");

            if (gameStage == GameStage.Submit) {
                gameStage = GameStage.Reveal;
                emit NewGameStage(GameStage.Reveal);
                requestRandomWords();
            } else if (gameStage == GameStage.Reveal) {
                gameStage = GameStage.Resolve;
                emit NewGameStage(GameStage.Resolve);
                resolve();
            } else if (gameStage == GameStage.Resolve) {
                gameStage = GameStage.Submit;
                emit NewGameStage(GameStage.Submit);
            }
        } else {
            // check if max players or game start time reached
            if (activePlayersCount == maxPlayers || gameStartTimestamp <= block.timestamp) {
                if (activePlayersCount >= 2) {
                    start();
                } else {
                    // not enough people joined then keep pushing it back till the day comes ㅠㅠ
                    gameStartTimestamp += interval;
                    emit GameStartDelayed(gameStartTimestamp);
                }
            }
        }
        lastUpkeepTimestamp = block.timestamp;
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