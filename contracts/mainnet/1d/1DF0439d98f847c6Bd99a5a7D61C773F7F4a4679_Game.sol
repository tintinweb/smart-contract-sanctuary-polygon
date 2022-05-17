/**
 *Submitted for verification at polygonscan.com on 2022-05-17
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
}

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: gemManager.sol


pragma solidity ^0.8.7;








interface IMEMBER {
    function userBets(address _user) external view returns (uint256);

    function userScore(address _user) external view returns (uint256);

    function addScore(uint256 score, address account)
        external
        returns (uint256);

    function subScore(uint256 score, address account)
        external
        returns (uint256);
}

interface IGEM {
    function totalSupply() external view returns (uint256);

    function setGemURI(uint256 gemId, string memory tokenURI)
        external
        returns (bool);

    function mintGem(address player, string memory tokenURI)
        external
        returns (uint256);

    function burnGem(uint256 gemId) external returns (bool);
}

abstract contract GameRole is Context {
    address private _owner;
    uint256 private _games;

    mapping(address => bool) private _isGame;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event GameAdded(address indexed newGame);
    event GameRemoved(address indexed removedGame);

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
     * @dev Return True if address is a game.
     */
    function isGame(address who) public view returns (bool) {
        return _isGame[who];
    }

    /**
     * @dev Return total number of games.
     */
    function games() public view returns (uint256) {
        return _games;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "GameRole: caller is not the owner");
        _;
    }

    /**
     * @dev Throws if called by any account other than the game.
     */
    modifier onlyGame() {
        require(_isGame[_msgSender()], "GameRole: caller is not a game");
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
        require(
            newOwner != address(0),
            "GameRole: new owner is the zero address"
        );
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

    /**
     * @dev Add a new account (`newGame`) as a game.
     * Can only be called by the current owner.
     */
    function addGame(address newGame) public onlyOwner {
        require(
            newGame != address(0),
            "GameRole: new game is the zero address"
        );
        require(!_isGame[newGame], "GameRole: this address is game");
        emit GameAdded(newGame);
        _isGame[newGame] = true;
        _games += 1;
    }

    /**
     * @dev Remove a game (`game`).
     * Can only be called by the current owner.
     */
    function removeGame(address game) public onlyOwner {
        require(_isGame[game], "GameRole: this address is not game");
        emit GameRemoved(game);
        _isGame[game] = false;
        _games -= 1;
    }
}

abstract contract RandomNumber is GameRole, VRFConsumerBaseV2 {
    VRFCoordinatorV2Interface COORDINATOR;

    // Polygon main net
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    address vrfCoordinator = 0xAE975071Be8F8eE67addBC1A82488F1C24858067;
    bytes32 keyHash = 0xcc294a196eeeb44da2888d17c0625cc88d70d9760a69d58d853ba6581a9ab0cd;
    uint64 public subscriptionId = 27;

    // Mumbai
    // address vrfCoordinator = 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed;
    // bytes32 keyHash =
    //     0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;
    // // Storage parameters
    // uint64 public subscriptionId = 176;

    // A reasonable default is 100000, but this value could be different
    // on other networks.
    uint32 callbackGasLimit = 1000000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 5;

    constructor() VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    }

    // Assumes the subscription is funded sufficiently.
    function getRandomNumber(uint32 numWords)
        internal
        returns (uint256 requestId)
    {
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        return requestId;
    }
}

abstract contract GameBase is RandomNumber, ReentrancyGuard {
    using SafeMath for uint256;
    using Strings for address;
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _userIds;

    struct User {
        uint256 id;
        uint256 referral;
        uint256 airdropped;
        uint256 referees;
        uint256 redeemed;
    }

    struct Gem {
        address maker;
        uint256 id;
        uint256 birth;
        uint256 level;
        uint256 color;
        bool isLevelFixed;
        bool isColorFixed;
        bool isSettled;
    }

    string internal _name;
    uint256 internal _redeemPrice;
    uint256 internal _airdropNum;
    uint256 internal _airdropMax;
    bool internal _gameIsLive = false;

    IMEMBER internal _member;
    IGEM internal _gem;

    mapping(uint256 => address) internal _ids;
    mapping(address => User) internal _users;
    mapping(uint256 => Gem) internal _gems;

    // Events
    event GemRedeemed(address indexed user, uint256 gemId);
    event GemSettled(address indexed user, uint256 gemId, string uri);
    event AirdropClaimed(
        address indexed user,
        address indexed referral,
        uint256 gemId
    );

    // Modifiers
    modifier onlyLive() {
        require(_gameIsLive, "ERR: game is not live");
        _;
    }

    // View
    function name() external view returns (string memory) {
        return _name;
    }

    function totalUser() external view returns (uint256) {
        return _userIds.current();
    }

    function userDetail(address _user) public view returns (User memory) {
        return _users[_user];
    }

    function idExist(uint256 _user) public view returns (bool) {
        return _ids[_user] != address(0);
    }

    function userId(address _user) public view returns (uint256) {
        return _users[_user].id;
    }

    function userDetailById(uint256 _user) public view returns (User memory) {
        return _users[_ids[_user]];
    }

    function userClaimed(address _user) public view returns (uint256) {
        return _users[_user].airdropped;
    }

    function userReferral(address _user) public view returns (uint256) {
        return _users[_user].referral;
    }

    function redeemPrice() public view returns (uint256) {
        return _redeemPrice;
    }

    function airdropInfo() public view returns (uint256, uint256) {
        return (_airdropNum, _airdropMax);
    }

    // Setter

    function toggleGameIsLive() external onlyOwner {
        _gameIsLive = !_gameIsLive;
    }

    function setMembership(address _contract) external onlyOwner {
        _member = IMEMBER(_contract);
    }

    function setGem(address _contract) external onlyOwner {
        _gem = IGEM(_contract);
    }

    function setAirdropNum() external onlyOwner {
        _airdropNum++;
    }

    function setAirdropMax(uint256 _value) external onlyOwner {
        _redeemPrice = _value;
    }

    function setRedeemPrice(uint256 _value) external onlyOwner {
        _redeemPrice = _value;
    }

    // Methods
    function redeemGem() external onlyLive nonReentrant returns (uint256) {
        _subScore(_redeemPrice, _msgSender());
        uint256 requestId = getRandomNumber(3);
        uint256 gemId = _gem.mintGem(_msgSender(), "");

        Gem memory gem = Gem({
            maker: _msgSender(),
            id: gemId,
            birth: block.number,
            level: uint256(0),
            color: uint256(0),
            isLevelFixed: false,
            isColorFixed: false,
            isSettled: false
        });

        _gems[requestId] = gem;
        _users[_msgSender()].redeemed++;

        emit GemRedeemed(_msgSender(), gemId);

        return gemId;
    }

    function redeemColorGem(uint256 _color)
        external
        onlyLive
        nonReentrant
        returns (uint256)
    {
        require(_color < 6, "ERR: Invalid color");

        _subScore(_redeemPrice * 2, _msgSender());
        uint256 requestId = getRandomNumber(3);
        uint256 gemId = _gem.mintGem(_msgSender(), "");

        Gem memory gem = Gem({
            maker: _msgSender(),
            id: gemId,
            birth: block.number,
            level: uint256(0),
            color: _color,
            isLevelFixed: false,
            isColorFixed: true,
            isSettled: false
        });

        _gems[requestId] = gem;
        _users[_msgSender()].redeemed++;

        emit GemRedeemed(_msgSender(), gemId);

        return gemId;
    }

    function claimAirdrop(uint256 _referral)
        external
        onlyLive
        nonReentrant
        returns (uint256)
    {
        require(
            userClaimed(_msgSender()) < _airdropNum,
            "ERR: Already claimed"
        );

        _users[_msgSender()].airdropped = _airdropNum;
        uint256 requestId = getRandomNumber(3);
        uint256 gemId = _gem.mintGem(_msgSender(), "");

        Gem memory gem = Gem({
            maker: _msgSender(),
            id: gemId,
            birth: block.number,
            level: _airdropMax,
            color: uint256(0),
            isLevelFixed: true,
            isColorFixed: false,
            isSettled: false
        });

        _gems[requestId] = gem;

        _newUser(_msgSender(), _referral);

        if (userId(_msgSender()) > uint256(0)) {
            emit AirdropClaimed(
                _msgSender(),
                _ids[_users[_msgSender()].referral],
                gemId
            );
        } else {
            if (idExist(_referral)) {
                _newUser(_msgSender(), _referral);
                _addScore(_redeemPrice / 2, _ids[_referral]);
                emit AirdropClaimed(_msgSender(), _ids[_referral], gemId);
            } else {
                _newUser(_msgSender(), uint256(1));
                emit AirdropClaimed(_msgSender(), _ids[1], gemId);
            }
        }

        return gemId;
    }

    // Internal
    function _gemLevel(uint256 randomness) internal pure returns (uint256) {
        uint256 level = 0;
        for (uint256 i = 0; i < 16; i++) {
            randomness /= 10;
            if (randomness % 2 == 0) {
                level = i;
                break;
            }
        }
        return level;
    }

    function _newUser(address _user, uint256 _referral)
        internal
        returns (uint256)
    {
        _userIds.increment();

        User memory user = User({
            id: _userIds.current(),
            referral: _referral,
            airdropped: uint256(0),
            referees: uint256(0),
            redeemed: uint256(0)
        });

        _ids[_userIds.current()] = _user;
        _users[_user] = user;
        _users[_ids[_referral]].referees++;

        return _userIds.current();
    }

    function _addScore(uint256 _value, address _user) internal {
        _member.addScore(_value, _user);
    }

    function _subScore(uint256 _value, address _user) internal {
        _member.subScore(_value, _user);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
        nonReentrant
    {
        Gem storage gem = _gems[requestId];
        require(gem.id > 0, "Gem does not exist");
        require(gem.isSettled == false, "Gem is settled already");

        gem.isSettled = true;

        uint256 getLevel = _gemLevel(randomWords[2]);
        if (gem.isLevelFixed) {
            gem.level = getLevel > gem.level ? gem.level : getLevel;
        } else {
            gem.level = getLevel;
        }

        if (!gem.isColorFixed) {
            gem.color = randomWords[1] % 6;
        }

        string memory uri = string(
            abi.encodePacked(
                "{",
                '"name": "gem"',
                ", ",
                '"maker": "',
                Strings.toHexString(uint256(uint160(gem.maker)), 20),
                '", ',
                '"birth": ',
                gem.birth.toString(),
                ", ",
                '"level": ',
                gem.level.toString(),
                ", ",
                '"color": ',
                gem.color.toString(),
                ", ",
                '"properties": "',
                randomWords[0].toHexString(),
                '"}'
            )
        );

        _gem.setGemURI(gem.id, uri);

        emit GemSettled(gem.maker, gem.id, uri);
    }
}

contract Game is GameBase {
    constructor(address gem, address member) {
        _name = "Gem Manager - crystal.network";
        _gem = IGEM(gem);
        _member = IMEMBER(member);
        _airdropNum = uint256(1);
        _airdropMax = uint256(3);
        _redeemPrice = uint256(10000);
        _gameIsLive = true;
    }
}