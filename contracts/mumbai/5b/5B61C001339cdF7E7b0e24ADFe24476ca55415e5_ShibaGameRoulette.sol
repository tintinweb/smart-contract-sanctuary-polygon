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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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
pragma solidity ^0.8.0;

interface IShibaBank {
    function playerCredits(address _wallet) external view returns (uint256);

    function spendCredits(
        address _wallet,
        uint256 _amount,
        bool _cheat
    ) external;

    function winCredits(
        address _wallet,
        uint256 _amount,
        uint256 _betAmount
    ) external;

    function loseCredits(uint256 _betAmount) external;

    function hasProfits() external view returns (bool);

    function distributeProfits() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library RouletteLibrary {
    enum BetType {
        Straight,
        Split,
        Corner,
        Street,
        DoubleStreet,
        Row,
        Dozen,
        Low,
        High,
        Even,
        Odd,
        Red,
        Black,
        Five
    }

    function validateInputNumbers(uint8 a, uint8 b)
        internal
        pure
        returns (bool)
    {
        return a <= 37 && b >= a && b <= 37;
    }

    function validateBetNumbers(
        uint256[38] memory _numberBets,
        uint8 _length,
        uint256 _amount,
        BetType _betType,
        uint8 a,
        uint8 b
    ) internal pure returns (bool valid, uint256[38] memory numberBets) {
        uint256 multiplier = 360 / _length;
        uint256 prize = (_amount * multiplier) / 10;
        if (!validateInputNumbers(a, b)) {
            return (false, _numberBets);
        } else if (_betType == BetType.Straight) {
            _numberBets[a] += prize;
            return (a == b, numberBets = _numberBets);
        } else if (_betType == BetType.Split) {
            _numberBets[a] += prize;
            _numberBets[b] += prize;
            return (
                b == a + 1 ||
                    b == a + 3 ||
                    (a == 0 && b == 2) ||
                    (a == 2 && b == 37) ||
                    (a == 3 && b == 37),
                numberBets = _numberBets
            );
        } else if (_betType == BetType.Corner) {
            _numberBets[a] += prize;
            _numberBets[a + 1] += prize;
            _numberBets[a + 3] += prize;
            _numberBets[a + 4] += prize;
            return (b == a + 4, numberBets = _numberBets);
        } else if (_betType == BetType.Street) {
            _numberBets[a] += prize;
            _numberBets[a + 1] += prize;
            _numberBets[b] += prize;
            return (
                b == a + 2 || (a == 2 && b == 37),
                numberBets = _numberBets
            );
        } else if (_betType == BetType.DoubleStreet) {
            _numberBets[a] += prize;
            _numberBets[a + 1] += prize;
            _numberBets[a + 2] += prize;
            _numberBets[a + 3] += prize;
            _numberBets[a + 4] += prize;
            _numberBets[a + 5] += prize;
            return (b == a + 5, numberBets = _numberBets);
        } else if (_betType == BetType.Row) {
            _numberBets[a] += prize;
            _numberBets[a + 3] += prize;
            _numberBets[a + 6] += prize;
            _numberBets[a + 9] += prize;
            _numberBets[a + 12] += prize;
            _numberBets[a + 15] += prize;
            _numberBets[a + 18] += prize;
            _numberBets[a + 21] += prize;
            _numberBets[a + 24] += prize;
            _numberBets[a + 27] += prize;
            _numberBets[a + 30] += prize;
            _numberBets[a + 33] += prize;
            return (
                (a == 1 && b == 34) ||
                    (a == 2 && b == 35) ||
                    (a == 3 && b == 36),
                numberBets = _numberBets
            );
        } else if (_betType == BetType.Dozen) {
            _numberBets[a] += prize;
            _numberBets[a + 1] += prize;
            _numberBets[a + 2] += prize;
            _numberBets[a + 3] += prize;
            _numberBets[a + 4] += prize;
            _numberBets[a + 5] += prize;
            _numberBets[a + 6] += prize;
            _numberBets[a + 7] += prize;
            _numberBets[a + 8] += prize;
            _numberBets[a + 9] += prize;
            _numberBets[a + 10] += prize;
            _numberBets[a + 11] += prize;
            return (
                (a == 1 && b == 12) ||
                    (a == 13 && b == 24) ||
                    (a == 25 && b == 36),
                numberBets = _numberBets
            );
        } else if (_betType == BetType.Low || _betType == BetType.High) {
            _numberBets[a] += prize;
            _numberBets[a + 1] += prize;
            _numberBets[a + 2] += prize;
            _numberBets[a + 3] += prize;
            _numberBets[a + 4] += prize;
            _numberBets[a + 5] += prize;
            _numberBets[a + 6] += prize;
            _numberBets[a + 7] += prize;
            _numberBets[a + 8] += prize;
            _numberBets[a + 9] += prize;
            _numberBets[a + 10] += prize;
            _numberBets[a + 11] += prize;
            _numberBets[a + 12] += prize;
            _numberBets[a + 13] += prize;
            _numberBets[a + 14] += prize;
            _numberBets[a + 15] += prize;
            _numberBets[a + 16] += prize;
            _numberBets[a + 17] += prize;
            return (
                (
                    _betType == BetType.Low
                        ? a == 1 && b == 18
                        : a == 19 && b == 36
                ),
                numberBets = _numberBets
            );
        } else if (_betType == BetType.Even) {
            _numberBets[2] += prize;
            _numberBets[4] += prize;
            _numberBets[6] += prize;
            _numberBets[8] += prize;
            _numberBets[10] += prize;
            _numberBets[12] += prize;
            _numberBets[14] += prize;
            _numberBets[16] += prize;
            _numberBets[18] += prize;
            _numberBets[20] += prize;
            _numberBets[22] += prize;
            _numberBets[24] += prize;
            _numberBets[26] += prize;
            _numberBets[28] += prize;
            _numberBets[30] += prize;
            _numberBets[32] += prize;
            _numberBets[34] += prize;
            _numberBets[36] += prize;
            return (a % 2 == 0 && b % 2 == 0, numberBets = _numberBets);
        } else if (_betType == BetType.Odd) {
            _numberBets[1] += prize;
            _numberBets[3] += prize;
            _numberBets[5] += prize;
            _numberBets[7] += prize;
            _numberBets[9] += prize;
            _numberBets[11] += prize;
            _numberBets[13] += prize;
            _numberBets[15] += prize;
            _numberBets[17] += prize;
            _numberBets[19] += prize;
            _numberBets[21] += prize;
            _numberBets[23] += prize;
            _numberBets[25] += prize;
            _numberBets[27] += prize;
            _numberBets[29] += prize;
            _numberBets[31] += prize;
            _numberBets[33] += prize;
            _numberBets[35] += prize;
            return (a % 2 == 1 && b % 2 == 1, numberBets = _numberBets);
        } else if (_betType == BetType.Red) {
            _numberBets[1] += prize;
            _numberBets[3] += prize;
            _numberBets[5] += prize;
            _numberBets[7] += prize;
            _numberBets[9] += prize;
            _numberBets[12] += prize;
            _numberBets[14] += prize;
            _numberBets[16] += prize;
            _numberBets[18] += prize;
            _numberBets[19] += prize;
            _numberBets[21] += prize;
            _numberBets[23] += prize;
            _numberBets[25] += prize;
            _numberBets[27] += prize;
            _numberBets[30] += prize;
            _numberBets[32] += prize;
            _numberBets[34] += prize;
            _numberBets[36] += prize;
            return (a == 1 && b == 36, numberBets = _numberBets);
        } else if (_betType == BetType.Black) {
            _numberBets[2] += prize;
            _numberBets[4] += prize;
            _numberBets[6] += prize;
            _numberBets[8] += prize;
            _numberBets[10] += prize;
            _numberBets[11] += prize;
            _numberBets[13] += prize;
            _numberBets[15] += prize;
            _numberBets[17] += prize;
            _numberBets[20] += prize;
            _numberBets[22] += prize;
            _numberBets[24] += prize;
            _numberBets[26] += prize;
            _numberBets[28] += prize;
            _numberBets[29] += prize;
            _numberBets[31] += prize;
            _numberBets[33] += prize;
            _numberBets[35] += prize;
            return (a == 2 && b == 35, numberBets = _numberBets);
        } else if (_betType == BetType.Five) {
            _numberBets[0] += prize;
            _numberBets[1] += prize;
            _numberBets[2] += prize;
            _numberBets[3] += prize;
            _numberBets[37] += prize;
            return (a == 0 && b == 37, numberBets = _numberBets);
        } else {
            return (false, _numberBets);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "./libraries/RouletteLibrary.sol";
import "./interfaces/IShibaBank.sol";

contract ShibaGameRoulette is
    VRFConsumerBaseV2,
    Ownable,
    ReentrancyGuard,
    Pausable
{
    //---------- Contracts ----------//
    VRFCoordinatorV2Interface private COORDINATOR;
    IShibaBank public immutable BANK;

    //---------- Variables ----------//
    uint64 private subscriptionId;
    uint256 public minAmount;
    bytes32 private keyHash;
    uint32 private callbackGasLimit;
    uint32 public betsLimit;
    uint8[14] private numbersLengthBets = [
        1,
        2,
        4,
        3,
        6,
        12,
        12,
        18,
        18,
        18,
        18,
        18,
        18,
        5
    ];

    //---------- Storage -----------//
    struct Bet {
        address player;
        uint256 amount;
        uint256[38] prize;
    }

    struct PlayBet {
        uint256 amount;
        uint8[2] numbers;
        RouletteLibrary.BetType betType;
    }

    mapping(uint256 => Bet) internal BETS;

    //---------- Events -----------//
    event NewBet(
        uint256 indexed id,
        address player,
        uint256 amount,
        PlayBet[] bets
    );
    event BetFilled(uint256 indexed id, uint256 prize, uint256 winNumber);

    //---------- Constructor ----------//
    constructor(
        uint64 _subscriptionId,
        address vrfCoordinator,
        bytes32 _keyHash,
        address _bank
    ) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        subscriptionId = _subscriptionId;
        keyHash = _keyHash;
        BANK = IShibaBank(_bank);
        minAmount = 500 ether;
        callbackGasLimit = 1500000;
        betsLimit = 25;
    }

    //----------- Internal Functions -----------//
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        require(BETS[requestId].amount > 0, "Wrong requestId");

        uint32 winNumber = uint32(randomWords[0] % 38);
        uint256 prize = BETS[requestId].prize[winNumber];
        if (prize > 0) {
            BANK.winCredits(
                BETS[requestId].player,
                prize,
                BETS[requestId].amount
            );
        } else {
            BANK.loseCredits(BETS[requestId].amount);
        }
        delete BETS[requestId];
        emit BetFilled(requestId, prize, winNumber);
    }

    function _haveCheats(uint8[14] memory _repeats)
        internal
        pure
        returns (bool)
    {
        if (_repeats[5] >= 3 || _repeats[6] >= 3) {
            return true;
        }
        if (
            _repeats[7] + _repeats[8] >= 2 ||
            _repeats[9] + _repeats[10] >= 2 ||
            _repeats[11] + _repeats[12] >= 2
        ) {
            return true;
        }
        return _repeats[4] >= 6;
    }

    //----------- External Functions -----------//
    function getBet(uint256 _id) external view returns (Bet memory) {
        return BETS[_id];
    }

    function checkBets(PlayBet[] memory bets)
        public
        view
        returns (
            bool valid,
            uint256 totalAmount,
            bool cheat,
            uint256[38] memory formatBets
        )
    {
        uint8[14] memory repeats;
        uint256[38] memory numberBets;
        uint256 total;
        for (uint256 i = 0; i < bets.length; i++) {
            PlayBet memory b = bets[i];
            if (b.amount < minAmount) {
                return (false, 0, true, numberBets);
            }
            if (
                b.amount > minAmount * 5 * numbersLengthBets[uint256(b.betType)]
            ) {
                return (false, 0, true, numberBets);
            }
            (bool _valid, uint256[38] memory _numberBets) = RouletteLibrary
                .validateBetNumbers(
                    numberBets,
                    numbersLengthBets[uint256(b.betType)],
                    b.amount,
                    b.betType,
                    b.numbers[0],
                    b.numbers[1]
                );
            if (!_valid) {
                return (false, 0, true, numberBets);
            }
            numberBets = _numberBets;
            total += b.amount;
            repeats[uint256(b.betType)] += 1;
        }
        return (true, total, _haveCheats(repeats), numberBets);
    }

    function playBet(PlayBet[] calldata myBets)
        external
        nonReentrant
        whenNotPaused
        returns (uint256 requestId)
    {
        require(
            myBets.length > 0 && myBets.length <= betsLimit,
            "Bets out of bounds"
        );

        (
            bool valid,
            uint256 totalAmount,
            bool cheat,
            uint256[38] memory formatBets
        ) = checkBets(myBets);

        require(valid, "Invalid bets");
        BANK.spendCredits(_msgSender(), totalAmount, cheat);

        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            subscriptionId,
            3,
            callbackGasLimit,
            1
        );
        Bet storage b = BETS[requestId];
        b.player = _msgSender();
        b.amount = totalAmount;
        b.prize = formatBets;
        emit NewBet(requestId, _msgSender(), totalAmount, myBets);
    }

    function forceBet(uint256 _id) external onlyOwner {
        require(BETS[_id].amount > 0, "Wrong requestId");
        uint256 newRequestId = COORDINATOR.requestRandomWords(
            keyHash,
            subscriptionId,
            3,
            callbackGasLimit,
            1
        );
        BETS[newRequestId] = BETS[_id];
        delete BETS[_id];
        PlayBet[] memory myBets;
        emit NewBet(
            newRequestId,
            BETS[newRequestId].player,
            BETS[newRequestId].amount,
            myBets
        );
    }

    function setSubscriptionId(uint64 _id) external onlyOwner {
        require(_id > 0, "invalid id");
        subscriptionId = _id;
    }

    function setBetsLimit(uint32 _limit) external onlyOwner {
        require(_limit >= 18 && _limit <= 50, "invalid limit");
        betsLimit = _limit;
    }

    function setCallbackGasLimit(uint32 _limit) external onlyOwner {
        require(_limit >= 300000);
        callbackGasLimit = _limit;
    }

    function setKeyHash(bytes32 _key) external onlyOwner {
        require(_key != 0);
        keyHash = _key;
    }

    function setMinAmount(uint256 _amount) external onlyOwner {
        require(_amount >= 1 ether, "Amount too low");
        minAmount = _amount;
    }

    /**
     * @notice Function for pause and unpause the contract.
     */
    function togglePause() external onlyOwner {
        paused() ? _unpause() : _pause();
    }
}