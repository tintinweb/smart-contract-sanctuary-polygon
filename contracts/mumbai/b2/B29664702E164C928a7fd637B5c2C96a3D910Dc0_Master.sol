/**
 *Submitted for verification at polygonscan.com on 2022-12-14
*/

// File: User.sol


pragma solidity ^0.8.0;

contract User {

               /**
     * @dev estruct for creating user and updating user. 
     */
    struct signUpDetails {
        string[] roles;
        string logoImageUri;
        string bannerImageUri;
        string profileName;
        string description;
        address walletAddress;
        address parentDistributorAddress;
        string twitterUri;
        string youtubeUri;
        string facebookUri;
        string email;
    }

    mapping(address => signUpDetails) private signedDetails;
    address[] public profileAddresses;

               /**
     * @dev event for CreateProfile. 
     */
    event CreateProfile(
        string logoImageUri,
        string bannerIamgeUri,
        address walletAddress,
        string profileName,
        string description,
        string[] roles,
        string email
    );

           /**
     * @dev event for UpdateProfile. 
     */
    event UpdateProfile(
        string logoImageUri,
        string bannerIamgeUri,
        string profileName,
        string description,
        string[] roles,
        string twitterUri,
        string youtubeUri,
        string facebookUri,
        string email,
        address walletAddress
    );

    
               /**
     * @dev event for DeleteProfile. 
     */
    event DeleteProfile(address user, string isSuccess);


    /**
     * @dev creatng a profile for new user. 
     * //_parentDistributorAddress of the wallet address
     * //_roles roles of the player
     * //_logoImageUri _logoImageUri of the player
     * _bannerImageUri _bannerImageUri of the player
     * _profileName  _profileName of the player
     * _description _description of the player
     * walletAddress  walletAddress of the player
     * _email _email of the player
     */
    function createProfile(
        address _parentDistributorAddress,
        string[] memory _roles,
        string memory _logoImageUri,
        string memory _bannerImageUri,
        string memory _profileName,
        string memory _description,
        address walletAddress,
        string memory _email
    ) public {
        signUpDetails storage details = signedDetails[walletAddress];
        details.logoImageUri = _logoImageUri;
        details.bannerImageUri = _bannerImageUri;
        details.profileName = _profileName;
        details.description = _description;
        details.roles = _roles;
        details.parentDistributorAddress = _parentDistributorAddress;
        details.walletAddress = walletAddress;
        details.email = _email;
        emit CreateProfile(
            _logoImageUri,
            _bannerImageUri,
            walletAddress,
            _profileName,
            _description,
            _roles,
            _email
        );
        profileAddresses.push(walletAddress);
    }

     /**
     * @dev editing profile of current user
     * //_roles roles of the player
     * //_logoImageUri _logoImageUri of the player
     * _bannerImageUri _bannerImageUri of the player
     * _profileName  _profileName of the player
     * _description _description of the player
     * facebook  facebook url  of the player
     * _twitterUri  _twitterUri url  of the player
     * _youtubeUri  _youtubeUri url  of the player
     * _email _email of the player
     */
    function editProfile(
        string[] memory _roles,
        string memory _logoImageUri,
        string memory _bannerImageUri,
        string memory _profileName,
        string memory _description,
        string memory _twitterUri,
        string memory _facebookUri,
        string memory _youtubeUri,
        string memory _email
    ) public {
        require(
            signedDetails[msg.sender].walletAddress != address(0),
            "No Account Created!"
        );
        signUpDetails storage details = signedDetails[msg.sender];

        if (bytes(_logoImageUri).length != bytes("").length) {
            details.logoImageUri = _logoImageUri;
        }
        if (bytes(_bannerImageUri).length != bytes("").length) {
            details.bannerImageUri = _bannerImageUri;
        }
        if (bytes(_profileName).length != bytes("").length) {
            details.profileName = _profileName;
        }
        if (bytes(_description).length != bytes("").length) {
            details.description = _description;
        }
        if (bytes(_twitterUri).length != bytes("").length) {
            details.twitterUri = _twitterUri;
        }
        if (bytes(_youtubeUri).length != bytes("").length) {
            details.youtubeUri = _youtubeUri;
        }
        if (bytes(_facebookUri).length != bytes("").length) {
            details.facebookUri = _facebookUri;
        }
        if (bytes(_email).length != bytes("").length) {
            details.email =_email;
        }
        details.roles = _roles;
        emit UpdateProfile(
            _logoImageUri,
            _bannerImageUri,
            _profileName,
            _description,
            _roles,
            _twitterUri,
            _youtubeUri,
            _facebookUri,
             _email,   
            msg.sender
        );
    }


     /**
     * @dev deleting the speific  the profile . 
     */
    function deleteProfile() public {
        require(
            signedDetails[msg.sender].walletAddress != address(0),
            "No Account Created!"
        );
        delete signedDetails[msg.sender];
        findAndDelete(msg.sender);
        emit DeleteProfile(msg.sender, "User Profile Deleted");
    }

    /**
     * @dev getting the userdetails by providing the wallet address. 
     */
    function getUserDetails(address userAddress)
        public
        view
        returns (
            string memory logoUri,
            string memory bannerUri,
            string memory profileName,
            string memory profileDescription,
            string[] memory rolesGot,
            address walletAddress,
            address parentDistributorAddress,
            string memory twitterUri,
            string memory youtubeUri,
            string memory facebookUri,
            string memory email
        )
    {
        signUpDetails memory details = signedDetails[userAddress];
        return (
            details.logoImageUri,
            details.bannerImageUri,
            details.profileName,
            details.description,
            details.roles,
            details.walletAddress,
            details.parentDistributorAddress,
            details.twitterUri,
            details.youtubeUri,
            details.facebookUri,
            details.email
        );
    }


      /**
     * @dev userExists if user is been present it returs true else false
     */
    function userExists(address user) public  view returns (bool) {
        for (uint256 i = 0; i < profileAddresses.length; i++) {
            if (profileAddresses[i] == user) {
                return true;
            }
        }
        return false;
    }

    function findAndDelete(address user) internal {
        uint256 elementPosition;
        for (uint256 i = 0; i < profileAddresses.length; i++) {
            if (profileAddresses[i] == user) {
                elementPosition = i;
                for (uint256 j = i; j < profileAddresses.length - 1; j++) {
                    profileAddresses[j] = profileAddresses[j + 1];
                    profileAddresses.pop();
                }
            }
        }
    }
}

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

// File: ICreateGame.sol


pragma solidity ^0.8.15;

interface ICreateGame {

   struct OtherDetails {
        address userAddress;
        address adminAddress;
        address oracleAddress;
        address LOTPAddress;
        address creatorAddress;
        address sponsorAddress;
   }

    struct TicketDetails {
        uint256 ticketId;
        bool usedTicket;
        bool isWinning;
        bool isClaimed;
        address ticketOwner;
        uint256 winningAmount;
        uint256 outcomeResult;
    }

    struct Comment {
        uint256[] unixTime;
        address commenterAddress;
        string[] comment;
    }

    struct Rating {
        uint256 unixTime;
        address ratingAddress;
        uint256 rating;
    }

    function getTicketDetails(uint256 Id)
        external
        view
        returns (
            uint256 ticketId,
            bool usedTicket,
            bool isWinning,
            bool isClaimed,
            address ticketOwner
        );
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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// File: @openzeppelin/contracts/token/ERC721/ERC721.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;








/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256, /* firstTokenId */
        uint256 batchSize
    ) internal virtual {
        if (batchSize > 1) {
            if (from != address(0)) {
                _balances[from] -= batchSize;
            }
            if (to != address(0)) {
                _balances[to] += batchSize;
            }
        }
    }

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}
}

// File: @openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;


/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// File: @openzeppelin/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: IBase.sol


pragma solidity ^0.8.15;

interface IBase {

    struct GameDetails {
        string  name;
        string  description;
        string  details;
        string[] gameThumbnails;
        uint256 numberOfTickets;
        uint256 priceOfTickets;
        uint256[] outcomes;
        uint256[] payouts;
        bool isSponsored;
        uint256[] playedTickets;
    }
   
}

// File: IMaster.sol


pragma solidity ^0.8.15;

interface IMaster is IBase {

             /**
     * @dev GameCreated Creating a event
     */
    event GameCreated(
        address creatorAddress,
        address gameAddress,
        string name,
        string description,
        string details,
        string[] gameThumbnails,
        uint256 numberOfTickets,
        uint256 priceOfTickets,
        uint256[] payouts,
        uint256[] outcomes
    );

             /**
     * @dev BuyTicket Creating a event
     */
    event BuyTicket(
        uint256 indexed ticketId,
        address indexed gameAddress,
        address indexed ticketOwner,
        uint256 ticketsSold,
        uint256 ticketsUnsold,
        uint256 winningAmount,
        bool isWin,
        uint256 rng

    );

                /**
     * @dev SponsorGame Creating a event
     */
    event SponsorGame(
        address indexed gameAddress,
        address indexed sponsorAddress,                    
        uint256 indexed amountToVault,
        uint256  time
    );


                /**
     * @dev GiftTicket Creating a event
     */
        event GiftTicket(
        address indexed gameAddress,
        address indexed toAddress,
        uint256 indexed ticketId
    );

                /**
     * @dev CancelSponsorGame Creating a event
     */
            event CancelSponsorGame(
        address indexed gameAddress,
        address indexed sponsorAddress,
        uint256 indexed amountToVault,
        uint256   creatorCommission
    );

                /**
     * @dev withdrawSponsorGame Creating a event
     */
        event withdrawSponsorGame(
        address indexed gameAddress,
        address indexed sponsorAddress,
        uint256  creatorAmountToVault,
         uint256 balance
    );



                     /**
     * @dev ClaimPrize Creating a event
     */
    event ClaimPrize(
        address indexed gameAddress,
        uint256 indexed ticketId,
        uint256 winningAmount
    );


                /**
     * @dev AddCommentAndRating Creating a event
     */
    event AddCommentAndRating(
        address gameAddress,
        address commenterAddress,
        string comment,
        uint256 time,
        uint256 indexed rating
    );

   



                   /**
     * @dev emitBuyAndPlay function to buyandplay game
     */

    function emitBuyAndPlay(
        uint256 ticketId,
        address gameAddress,
        address ticketOwner,
        uint256 ticketsSold,
        uint256 ticketsUnsold,
        uint256 winningAmount,
        bool isWin,
        uint256 rng
    ) external;


   
                   /**
     * @dev emitSponsorGame function to buyandplay game
     */
    function emitSponsorGame(
        address gameAddress,
        address sponsorAddress,
        uint256 amountToVault,
        uint256 time
    ) external;


                   /**
     * @dev emitSponsorGame function to buyandplay game
     */
        function emitGiftTicket(
        address gameAddress,
        address toAddress,
        uint256 ticketID
    ) external;


                   /**
     * @dev emitCancelSponsorGame function to buyandplay game
     */
        function emitCancelSponsorGame(
        address  gameAddresss,
        address  sponsorAddresss, 
        uint256  amountToVaults,
        uint256  creatorCommission
    ) external;


                   /**
     * @dev emitCancelSponsorGame function to buyandplay game
     */
        function  emitwithdrawSponsorGame(
        address  gameAddress,
        address  sponsorAddress,
        uint256 creatorAmountToVault,
        uint256  balance
    )external;

 
                   /**
     * @dev emitClaimPrize function to buyandplay game
     */
    function emitClaimPrize(
        address gameAddress,
        uint256 ticketId,
        uint256 winningAmount
    ) external;


                   /**
     * @dev emitAddCommentAndRating function to buyandplay game
     */
    function emitAddCommentAndRating(
        address gameAddress,
        address commenterAddress,
        string memory comment,
        uint256 time,
        uint256 rating
    ) external;


                   /**
     * @dev getGameDetails function to buyandplay game
     */
    function getGameDetails(address gameAddress)
        external
        view
        returns (
            string memory name,
            uint256 numberOfTickets,
            uint256 priceOfTickets,
            uint256[] memory outcomes,
            uint256[] memory payouts,
            uint256[] memory playedTickets
        );

                   /**
     * @dev createGame function to buyandplay game
     */
        function createGame(
        address creatorAddress,
        string memory name,
        string memory description,
        string memory details,
        string[] memory gameThumbnails,
        uint256 numberOfTickets,
        uint256 priceOfTickets,
        uint256[] memory outcomes,
        uint256[] memory payouts
    )external returns  (address) ;
}

// File: VRFv2Consumer.sol


// An example of a consumer contract that relies on a subscription for funding.
// https://vrf.chain.link/mumbai/1237
// https://vrf.chain.link/rinkeby/9883
pragma solidity ^0.8.7;





contract VRFv2Consumer is VRFConsumerBaseV2 {

    uint256[] initial;

    struct GameDetails {
        string name;
        uint256 numberOfTickets;
        uint256[] playedTickets;
        uint256[] randomNumbers;
    }

    mapping(address => GameDetails) public gameDetails;
    
    address[] public gameAddresses;

    VRFCoordinatorV2Interface COORDINATOR;
    // Your subscription ID.
    uint64 s_subscriptionId;
    // Polygon coordinator. For other networks,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    //address vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab; // rinkeby testnet
    address vrfCoordinator = 0xAE975071Be8F8eE67addBC1A82488F1C24858067; //polygon testnet
    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    //bytes32 keyHash = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc; // rinkeby testnet
    bytes32 keyHash = 0xcc294a196eeeb44da2888d17c0625cc88d70d9760a69d58d853ba6581a9ab0cd; //polygon testnet
    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 callbackGasLimit = 100000;
    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;
    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 numWords = 1;
    uint256[] public s_randomWords;
    uint256 public s_requestId;


    constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_subscriptionId = subscriptionId;
    }

    function getRandomsData(address gameAddr) public view returns(uint256[] memory) {
        return gameDetails[gameAddr].randomNumbers;
    }

    // Assumes the subscription is funded sufficiently.
    function requestRandomWords() internal returns (uint256){
        // Will revert if subscription is not set and funded.
        return COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        ); 
    }

 
    function checkExist(address gameAddress) internal returns(uint256) {

        uint256 random = (requestRandomWords() % gameDetails[gameAddress].numberOfTickets) + 1; 

         return random; // 2
    }

    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        s_randomWords = randomWords;
    }

    function getRandom(
        address adminAddress,
        address gameAddress,
        uint256 ticketId
    ) public returns (uint256) {
        (
           /* uint256 ticketId */,
            bool usedTicket ,
           /* bool isWinning */,
           /* bool isClaimed */,
           /* address ticketOwner */
        ) = ICreateGame(gameAddress).getTicketDetails(ticketId);
        require(usedTicket != true, "You already played the game"); //
               
        _storeData(adminAddress, gameAddress);
        return checkExist(gameAddress);  // 2 
    }

    function _storeData(address adminAddress, address gameAddress) internal {
        (
        string memory name,
        uint256 numberOfTickets,
       /* uint256 priceOfTickets */, 
       /* uint256[] memory outcomes */,
       /* uint256[] memory payouts */,
        uint256[] memory playedTickets
        ) = IMaster(adminAddress).getGameDetails(gameAddress);

        gameDetails[gameAddress] = GameDetails(
             name,
             numberOfTickets,
             playedTickets,
             initial
        );

        gameAddresses.push(gameAddress);
    }

}
// File: CreateGame.sol


pragma solidity ^0.8.15;




// import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";







contract CreateGame is ICreateGame, IBase, ERC721, Ownable, ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    uint256 private constant LOTP_SHARE = 20;
    uint256 private constant SPONSOR_SHARE = 80;
    uint256 private constant CREATOR_SHARE = 10;

    uint256[] initial;
    string[] private role = ["PLAYER"];

    //Constant variables
    uint256 ticketCounter = 0;
    uint256 ticketsCount = 0;
    uint256 startTime;
    uint256 endTime;
    uint256 startTimeBuy;
    uint256 endTimeBuy;
    // uint256 fourteenDays = 1209600;
    uint256 fourteenDays = 100;
    uint256 counting = 0;
    uint256 public valueCounting = 0;
    uint256 public setValueCounting = 0;
    uint256 private comissionLotpPercentage;
    address private comissionerLotpAddresses;
    uint256 private comissionSponsorPercentage;
    address private comissionerSponsorAddresses;
    uint256 private comissionCreatorPercentage;
    address private comissionerCreatorAddresses;
    address[] private commentedAddress;
    address[] private ratedAddress;
    uint256[] public _randomNumber;
    uint256[] public getAllRandomNumber;
    address tokenAddresss;

    //Mapping the variables
    mapping(address => Rating) public ratingDetails;
    mapping(address => Comment) public commentDetails;
    mapping(address => uint256) private comissionPercentages;
    mapping(uint256 => TicketDetails) public ticketData;
    mapping(uint256 => uint256) public outcomePayout;
    string[] gameThumbnail;
    GameDetails public gameDetails;
    OtherDetails public otherDetails;

    modifier sponsored() {
        require(
            gameDetails.isSponsored == true,
            "This game is not sponsored yet."
        );
        _;
    }

    modifier ticketsMinter() {
        if (ticketCounter == gameDetails.numberOfTickets) {
            revert("Sorry, all tickets are sold.");
        }
        _;
    }

    /**
     * @dev constructor of the creating game
     */

    constructor(
        address[] memory addresses, //Sequences of address Oracle Lotp creator Master contract Address and User
        string memory name,
        string memory description,
        string memory details,
        string[] memory gameThumbnails,
        uint256 numberOfTickets,
        uint256 priceOfTickets,
        uint256[] memory outcomes,
        uint256[] memory payouts,
        address tokenAddress
    ) ERC721(name, "LOP") {
        require(msg.sender == addresses[2], "Creator is not caller");
        gameDetails = GameDetails(
            name,
            description,
            details,
            gameThumbnails,
            numberOfTickets,
            priceOfTickets,
            outcomes,
            payouts,
            false,
            initial
        );
        //addresses[0] Oracle Address
        //addresses[1] LOTP Address
        //addresses[2] Creator Address
        //addresses[3] Master Contract Address
        //addresses[4] User Contract Address
        otherDetails = OtherDetails(
            addresses[4],
            addresses[3],
            addresses[0],
            addresses[1],
            addresses[2],
            address(0) //Sponsor Address intinally passing empty address
        );

        tokenAddresss = tokenAddress;

        for (uint256 i = 1; i <= numberOfTickets; i++) {
            _randomNumber.push(i);
        }

        otherDetails.userAddress = addresses[4];
        otherDetails.adminAddress = addresses[3];

        comissionerLotpAddresses = otherDetails.LOTPAddress;
        comissionLotpPercentage = LOTP_SHARE;

        comissionerCreatorAddresses = otherDetails.creatorAddress;
        comissionCreatorPercentage = CREATOR_SHARE;

        for (uint256 i = 0; i < gameDetails.outcomes.length; i++) {
            outcomePayout[gameDetails.outcomes[i]] = gameDetails.payouts[i];
        }

        gameThumbnail = gameThumbnails;

        IMaster(addresses[3]).createGame(
            addresses[2],
            name,
            description,
            details,
            gameThumbnails,
            numberOfTickets,
            priceOfTickets,
            outcomes,
            payouts
        );
    }

    /**
     * @dev buying the ticket of the game and playing 
     @param amount amount of the game given by creating  a game contract address 
     */
    function buy(
        uint256 amount,
        uint256 tickets
    ) external sponsored ticketsMinter {
        // require(tickets <= 10, "You can't buy more than 10 tickets at a time ");
        for (uint256 j = 0; j < tickets; j++) {
            uint256 ticketId = _tokenIdCounter.current();
            _tokenIdCounter.increment();

            require(
                gameDetails.priceOfTickets == amount,
                "The ticket price is invalid."
            );

            if (
                User(otherDetails.userAddress).userExists(msg.sender) == false
            ) {
                User(otherDetails.userAddress).createProfile(
                    address(0),
                    role,
                    "",
                    "",
                    "",
                    "",
                    msg.sender,
                    ""
                );
            }

            _safeMint(otherDetails.LOTPAddress, ticketId);
            _setTokenURI(ticketId, gameThumbnail[0]);
            _safeTransfer(otherDetails.LOTPAddress, msg.sender, ticketId, "");

            ticketData[ticketId] = TicketDetails(
                ticketId,
                false,
                false,
                false,
                msg.sender,
                0,
                0
            );

            _erc20TokenTransferFrom(
                tokenAddresss,
                msg.sender,
                address(this),
                amount
            );

            startTimeBuy = block.timestamp;
            endTimeBuy = startTimeBuy + fourteenDays;

            ticketCounter += 1;
            ticketsCount += 1;

            uint256 randomNumber = VRFv2Consumer(otherDetails.oracleAddress)
                .getRandom(otherDetails.adminAddress, address(this), ticketId);

            uint256 randomIndex = randomNumber % (_randomNumber.length);

            uint256 resultNumber = _randomNumber[randomIndex];

            _randomNumber[randomIndex] = _randomNumber[
                _randomNumber.length - 1
            ];

            _randomNumber.pop();

            ticketData[ticketId].outcomeResult = resultNumber;

            for (uint256 i = 0; i < gameDetails.outcomes.length; i++) {
                if (i == 0) {
                    if (gameDetails.outcomes[i] >= resultNumber) {
                        ticketData[ticketId].winningAmount = outcomePayout[
                            gameDetails.outcomes[i]
                        ];
                        break;
                    } else {
                        continue;
                    }
                } else {
                    if (
                        (gameDetails.outcomes[i - 1] + 1) <= resultNumber &&
                        gameDetails.outcomes[i] >= resultNumber
                    ) {
                        ticketData[ticketId].winningAmount = outcomePayout[
                            gameDetails.outcomes[i]
                        ];
                        break;
                    }
                }
            }
            getAllRandomNumber.push(resultNumber);

            playGame(ticketId);

            IMaster(otherDetails.adminAddress).emitBuyAndPlay(
                ticketId,
                address(this),
                msg.sender,
                ticketCounter,
                gameDetails.numberOfTickets - ticketCounter,
                ticketData[ticketId].winningAmount,
                ticketData[ticketId].isWinning,
                ticketData[ticketId].outcomeResult
            );
        }
    }

    /**
     * @dev Playig the game this function is been merged with buy function
     * @param ticketId ticketid of the game
     */
    function playGame(uint256 ticketId) internal {
        require(
            ticketData[ticketId].ticketOwner == msg.sender,
            "Sorry, you're not the owner of this game ticket."
        );
        require(
            ticketData[ticketId].usedTicket == false,
            "You've already played the game."
        );

        if (ticketData[ticketId].winningAmount > 0) {
            ticketData[ticketId].isWinning = true;
        } else {
            ticketData[ticketId].isWinning = false;
        }

        ticketData[ticketId].usedTicket = true;

        gameDetails.playedTickets.push(ticketData[ticketId].outcomeResult);
    }

    /**
     * @dev fecting thew sponser amount has been provided by the admin.
     * @return returns the amount has been provided by contract creation
     */
    function getSponsoringAmount() public view returns (uint256) {
        uint256 sponsoredAmount = 0;

        for (uint256 i = 0; i < gameDetails.outcomes.length; i++) {
            if (i == 0) {
                sponsoredAmount += (outcomePayout[gameDetails.outcomes[i]] *
                    gameDetails.outcomes[i]);
            } else {
                uint256 range = gameDetails.outcomes[i] -
                    gameDetails.outcomes[i - 1];
                sponsoredAmount +=
                    ((outcomePayout[gameDetails.outcomes[i]]) *
                        range *
                        2250000) /
                    10 ** 6;
            }
        }

        return sponsoredAmount;
    }

    /**
     * @dev canceling the sponsorShip and returing the left over amount to sponsor  and returning the ownership to creator Address
     */
    function cancelSponsorship() public {
        uint256 _commisionCreator;
        uint256 balance;
        require(
            block.timestamp > endTime,
            "You can't cancel sponsorship for now"
        ); //sponsoring time
        require(
            block.timestamp > endTimeBuy,
            "You can't cancel sponsorship for now "
        );

        uint256 calculatingCreatorCommission = SoldTicketCount() *
            gameDetails.priceOfTickets;

        address _commisionerCreatorAddress = comissionerCreatorAddresses;
        _commisionCreator = ((calculatingCreatorCommission *
            comissionCreatorPercentage) / 100);
        _erc20TokenTransfer(
            tokenAddresss,
            _commisionerCreatorAddress,
            _commisionCreator
        );

        _erc20TokenTransfer(
            tokenAddresss,
            otherDetails.sponsorAddress,
            getSponsoringAmount()
        );
        uint256 balanceRemaning = IERC20(tokenAddresss).balanceOf(
            address(this)
        );

        address _commisionerAddress = comissionerLotpAddresses;
        uint256 _commision = ((comissionLotpPercentage * balanceRemaning) /
            100);
        _erc20TokenTransfer(tokenAddresss, _commisionerAddress, _commision);

        address _commisionerSponsorAddress = comissionerSponsorAddresses;
        balance = IERC20(tokenAddresss).balanceOf(address(this));
        _erc20TokenTransfer(tokenAddresss, _commisionerSponsorAddress, balance);

        gameDetails.isSponsored = false;
        ticketsCount = 0;
        transferOwnership(otherDetails.creatorAddress);
        IMaster(otherDetails.adminAddress).emitCancelSponsorGame(
            address(this),
            otherDetails.sponsorAddress,
            balance,
            _commisionCreator
        );
        comissionerSponsorAddresses = address(0);
        otherDetails.sponsorAddress = otherDetails.creatorAddress;
    }

    /**
     * @dev Withdraw the amount when all ticket is been withdraw
     */
    function withDraw() public {
        uint256 balance;
        uint256 _commisionCreator;
        require(getUnSoldTicketCount() == 0, "Ticket has not been sold"); //All tickets has not been sold

        require(checkBalance(tokenAddresss) > 0, "No balance left");
        address ownerVerifier = owner();
        require(ownerVerifier == msg.sender, "Your not owner");

        for (uint256 i = 0; i <= getSoldTicketCount(); i++) {
            if (ticketData[i].isWinning == true) {
                require(
                    ticketData[i].isClaimed == true,
                    "User has not claimed his amount"
                );
            }
        }
        uint256 calculatingCreatorCommission = SoldTicketCount() *
            gameDetails.priceOfTickets;

        address _commisionerCreatorAddress = comissionerCreatorAddresses;
        _commisionCreator = ((calculatingCreatorCommission *
            comissionCreatorPercentage) / 100);
        _erc20TokenTransfer(
            tokenAddresss,
            _commisionerCreatorAddress,
            _commisionCreator
        );

        _erc20TokenTransfer(
            tokenAddresss,
            otherDetails.sponsorAddress,
            getSponsoringAmount()
        );
        uint256 balanceRemaning = IERC20(tokenAddresss).balanceOf(
            address(this)
        );

        address _commisionerAddress = comissionerLotpAddresses;
        uint256 _commision = ((comissionLotpPercentage * balanceRemaning) /
            100);
        _erc20TokenTransfer(tokenAddresss, _commisionerAddress, _commision);

        address _commisionerSponsorAddress = comissionerSponsorAddresses;
        balance = IERC20(tokenAddresss).balanceOf(address(this));
        _erc20TokenTransfer(tokenAddresss, _commisionerSponsorAddress, balance);

        ticketsCount = 0;
        IMaster(otherDetails.adminAddress).emitwithdrawSponsorGame(
            address(this),
            otherDetails.sponsorAddress,
            _commisionCreator,
            balance
        );
    }

    /**
     * @dev Sponsoring the game to the sppnsor  address and transfering the ownership
     * @param sponsorAddress sponsor address
     */
    function sponsorGame(address sponsorAddress) external {
        require(
            comissionerSponsorAddresses == address(0),
            "Game is been already sponsored"
        );
        if (gameDetails.numberOfTickets > 500) {
            for (
                uint256 i = valueCounting + 1;
                i <= gameDetails.numberOfTickets;
                i++
            ) {
                _randomNumber.push(i);
                setValueCounting + 1;
            }
        }

        require(sponsorAddress == msg.sender, "You can't Sponsor to others");
        uint256 amountToVault = getSponsoringAmount();

        // Adding sponsor
        comissionerSponsorAddresses = sponsorAddress;
        comissionSponsorPercentage = SPONSOR_SHARE;

        otherDetails.sponsorAddress = sponsorAddress;

        _erc20TokenTransferFrom(
            tokenAddresss,
            msg.sender,
            address(this),
            amountToVault
        );

        _transferOwnership(sponsorAddress);
        startTime = block.timestamp;
        endTime = startTime + fourteenDays;

        gameDetails.isSponsored = true;
        IMaster(otherDetails.adminAddress).emitSponsorGame(
            address(this),
            sponsorAddress,
            amountToVault,
            startTime
        );
    }

    /**
     * @dev claiming the winning price if the ticket has been won
     * @param ticketId  ticketid in array formate
     */
    function claimPrize(uint256 ticketId) external {
        require(
            ticketData[ticketId].isClaimed == false,
            "Prize amount already claimed for this game."
        );
        require(
            ticketData[ticketId].isWinning == true,
            "Sorry, you did not win this time."
        );
        require(
            ticketData[ticketId].ticketOwner == msg.sender,
            "Only the ticket owner can claim the prize."
        );

        _erc20TokenTransfer(
            tokenAddresss,
            msg.sender,
            ticketData[ticketId].winningAmount
        );

        ticketData[ticketId].isClaimed = true;

        IMaster(otherDetails.adminAddress).emitClaimPrize(
            address(this),
            ticketId,
            ticketData[ticketId].winningAmount
        );
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {}

    /**
     * @dev delete the token
     */
    function _burn(
        uint256 tokenId
    ) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function checkBalance(
        address tokenAddress
    ) internal view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function getTicketDetails(
        uint256 Id
    )
        public
        view
        returns (
            uint256 ticketId,
            bool usedTicket,
            bool isWinning,
            bool isClaimed,
            address ticketOwner
        )
    {
        return (
            ticketData[Id].ticketId,
            ticketData[Id].usedTicket,
            ticketData[Id].isWinning,
            ticketData[Id].isClaimed,
            ticketData[Id].ticketOwner
        );
    }

    /**
     * @dev coommenting and rating the game only once can be done
     * @param comment  comment for the game in string dormate
     * @param rating rating the gae between 1 to 5 in uint
     */

    function addComments(string memory comment, uint8 rating) public {
        bool isPurchasedOwner;
        for (uint256 i = 0; i < ticketCounter; i++) {
            if (ticketData[i].ticketOwner == msg.sender) {
                isPurchasedOwner = true;
            }
        }
        require(isPurchasedOwner, "Only a ticket purchased address can rate!");

        bool isAlreadyCommented = commentDetails[msg.sender].commenterAddress ==
            msg.sender
            ? true
            : false;
        require(!isAlreadyCommented, "You've already Commented this game.");
        if (!isAlreadyCommented) {
            Comment storage details = commentDetails[msg.sender];
            details.commenterAddress = msg.sender;
            details.comment.push(comment);
            details.unixTime.push(block.timestamp);

            commentedAddress.push(msg.sender);
            addRatings(rating);
            IMaster(otherDetails.adminAddress).emitAddCommentAndRating(
                address(this),
                msg.sender,
                comment,
                block.timestamp,
                rating
            );

            return;
        }
    }

    /**
     * @dev Getting specific store comment.
     */
    function getSpecificComments(
        address commenterAddress
    ) public view returns (Comment memory) {
        return commentDetails[commenterAddress];
    }

    /**
     * @dev get All the comments done by the users who bought the ticket
     */
    function getAllComments() public view returns (Comment[] memory) {
        Comment[] memory id = new Comment[](commentedAddress.length);
        for (uint256 i = 0; i < commentedAddress.length; i++) {
            Comment storage comments = commentDetails[commentedAddress[i]];
            id[i] = comments;
        }
        return id;
    }

    function addRatings(uint8 rating) internal {
        require(
            ratingDetails[msg.sender].ratingAddress != msg.sender,
            "You've already rated this game."
        );
        require(
            rating == 1 ||
                rating == 2 ||
                rating == 3 ||
                rating == 4 ||
                rating == 5,
            "Rating can be provided from 1 to 5"
        );
        ratingDetails[msg.sender] = Rating(block.timestamp, msg.sender, rating);
        ratedAddress.push(msg.sender);
    }

    // /**
    // @dev GET Specific Rating provided from a particular address \
    // @param  ratingAddress address of the user
    // */
    function getSpecificRating(
        address ratingAddress
    ) public view returns (Rating memory) {
        return ratingDetails[ratingAddress];
    }

    // /**
    //    @dev GET Overall Rating
    // */
    function getRating() public view returns (uint256) {
        uint256 ratingScore;
        for (uint256 i = 0; i < ratedAddress.length; i++) {
            Rating storage ratings = ratingDetails[ratedAddress[i]];
            ratingScore += ratings.rating;
        }
        if (ratingScore == 0) {
            return ratingScore;
        }
        return (ratingScore / (ratedAddress.length));
    }

    function array_push() public view returns (uint256[] memory) {
        return getAllRandomNumber;
    }

    /**
     * @dev function for get sold ticket count
     */
    function getSoldTicketCount() public view returns (uint256) {
        return ticketCounter;
    }

    /**
     * @dev function for sold ticket count
     */
    function SoldTicketCount() public view returns (uint256) {
        return ticketsCount;
    }

    /**
     * @dev function for unsold ticket count
     */
    function getUnSoldTicketCount() public view returns (uint256) {
        return gameDetails.numberOfTickets - ticketCounter;
    }

    /**
     * @dev function for get game outcomes
     */
    function getGameOutcomes() public view returns (uint256[] memory) {
        return gameDetails.outcomes;
    }

    /**
     * @dev function for game payout
     */
    function getGamePayout() public view returns (uint256[] memory) {
        return gameDetails.payouts;
    }

    /**
     * @dev function for transferFrom token
     */
    function _erc20TokenTransferFrom(
        address tokenAddress,
        address from,
        address to,
        uint256 amt
    ) internal {
        IERC20(tokenAddress).transferFrom(from, to, amt);
    }

    /**
     * @dev function for transfer token
     */
    function _erc20TokenTransfer(
        address tokenAddress,
        address to,
        uint256 amt
    ) internal {
        IERC20(tokenAddress).transfer(to, amt);
    }
}

// File: Master.sol


pragma solidity ^0.8.15;



contract Master is IBase, IMaster {
    address owner;
    uint256[] initial;

    
//Mapping the variables
    mapping(address => address[]) public ownedGames;
    mapping(address => GameDetails) public gameDetails;

     /**
     * @dev creating a game contract address
     * @param creatorAddress Address of the owner
     * @param name of the game 
     * @param description  of the game address
     * @param details  of the game address
     * @param gameThumbnails  of the game address
     * @param numberOfTickets number Of Tickets you need to mint in game address
     * @param priceOfTickets  in usdc
     * @param outcomes  of the game address
     * @param payouts  of the game address
     */
    function createGame(
        address creatorAddress,
        string memory name,
        string memory description,
        string memory details,
        string[] memory gameThumbnails,
        uint256 numberOfTickets,
        uint256 priceOfTickets,
        uint256[] memory outcomes,
        uint256[] memory payouts
    )override  public returns (address) {
       
        ownedGames[creatorAddress].push(msg.sender);
        gameDetails[msg.sender] = GameDetails(
            name,
            description,
            details,
            gameThumbnails,
            numberOfTickets,
            priceOfTickets,
            outcomes,
            payouts,
            false,
            initial
        );
        emit GameCreated(
            creatorAddress,
            msg.sender,
            name,
            description,
            details,
            gameThumbnails,
            numberOfTickets,
            priceOfTickets,
            payouts,
            outcomes
        );
        return msg.sender;
    }


         /**
     * @dev getGameDetails of the 
     * @param gameAddress returns  name , numberoftickets , priceftickets,outcomes,payouts,playedtickets
     */
    function getGameDetails(address gameAddress)
        public
        view
        returns (
            string memory name,
            uint256 numberOfTickets,
            uint256 priceOfTickets,
            uint256[] memory outcomes,
            uint256[] memory payouts,
            uint256[] memory playedTickets
        )
    {
        return (
            gameDetails[gameAddress].name,
            gameDetails[gameAddress].numberOfTickets,
            gameDetails[gameAddress].priceOfTickets,
            gameDetails[gameAddress].outcomes,
            gameDetails[gameAddress].payouts,
            gameDetails[gameAddress].playedTickets
        );
    }

                 

      /**
     * @dev event for emitbuyplay. 
     */
    function emitBuyAndPlay(
        uint256 ticketId,
        address gameAddress,
        address ticketOwner,
        uint256 ticketsSold,
        uint256 ticketsUnsold,
        uint256 winningAmount,
        bool isWin,
        uint256 rng
    ) external {
        emit BuyTicket(
            ticketId,
            gameAddress,
            ticketOwner,
            ticketsSold,
            ticketsUnsold,
            winningAmount,
            isWin,
            rng
        );
    }
  
          /**
     * @dev event for emitSponsorGame. 
     */
        function emitSponsorGame(
        address gameAddress,
        address sponsorAddress,
        uint256 amountToVault,
        uint256 time
    ) external {
        emit SponsorGame(gameAddress, sponsorAddress, amountToVault, time);
    }

          /**
     * @dev event for emitGiftTicket. 
     */
        function emitGiftTicket(
        address gameAddress,
        address to,
        uint256 ticketId
    ) external {
        emit GiftTicket(gameAddress, to, ticketId);
    }


       /**
     * @dev event for emitCancelSponsorGame. 
     */
   function emitCancelSponsorGame(
        address gameAddress,
        address sponsorAddress,
        uint256 amountToVault,
        uint256 creatorCommission
    ) external {
        emit CancelSponsorGame(gameAddress, sponsorAddress, amountToVault,creatorCommission);
    }

           /**
     * @dev event for emitwithdrawSponsorGame. 
     */
     function emitwithdrawSponsorGame(
        address gameAddress,
        address sponsorAddress,
        uint256 creatorAmountToVault,
         uint256 balance
    ) external {
        emit withdrawSponsorGame(gameAddress, sponsorAddress, creatorAmountToVault,balance);
    }

    
           /**
     * @dev event for emitClaimPrize. 
     */
    function emitClaimPrize(
        address gameAddress,
        uint256 ticketId,
        uint256 winningAmount
    ) external {
        emit ClaimPrize(gameAddress, ticketId, winningAmount);
    }

           /**
     * @dev event for emitAddCommentAndRating. 
     */
    function emitAddCommentAndRating(
        address gameAddress,
        address commenterAddress,
        string memory comment,
        uint256 time,
        uint256 rating
    ) public {
        emit AddCommentAndRating(
            gameAddress,
            commenterAddress,
            comment,
            time,
            rating
        );
    }
}