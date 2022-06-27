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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/BitMaps.sol)
pragma solidity ^0.8.0;

/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, providing the keys are sequential.
 * Largelly inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 */
library BitMaps {
    struct BitMap {
        mapping(uint256 => uint256) _data;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(BitMap storage bitmap, uint256 index) internal view returns (bool) {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        return bitmap._data[bucket] & mask != 0;
    }

    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    function setTo(
        BitMap storage bitmap,
        uint256 index,
        bool value
    ) internal {
        if (value) {
            set(bitmap, index);
        } else {
            unset(bitmap, index);
        }
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] |= mask;
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] &= ~mask;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "../interfaces/IREDDIES.sol";
import "../interfaces/IBootcampPlayer.sol";

struct GameTime {
  uint128 start;
  uint128 end;
}

// @notice abstract scaffolding for bootcamp challenges
abstract contract Game is Ownable, Pausable {

  using BitMaps for BitMaps.BitMap;

  // @dev track the other important contracts
  IREDDIES public reddies;
  IBootcampPlayer public bootcampPlayer;

  // @notice the start and end times of the game
  GameTime public gameTime;

  // @notice emitted when the game time is set
  event Scheduled(uint256 start, uint256 end);

  // @notice bitmap tracking whether players have participated in the challenge
  BitMaps.BitMap internal _played;

  // @notice mapping of "helper" contracts who can bypass the contract check
  mapping(address => bool) public helpers;
  
  constructor(address _bootcampPlayer, address _reddies) {
      reddies = IREDDIES(_reddies);
      bootcampPlayer = IBootcampPlayer(_bootcampPlayer);
      _pause();
  }

  /**
  * @dev identifies whether a token has participated in the RiskyGame
  * @param tokenId the tokenId to check
  */
  function played(uint256 tokenId) public view virtual returns(bool) {
    return _played.get(tokenId);
  }

  /**
  * @dev enables owner to pause / unpause minting
  * @param _bPaused the flag to pause or unpause
  */
  function setPaused(bool _bPaused) external onlyOwner {
      if (_bPaused) _pause();
      else _unpause();
  }

  // @notice set the start and end time of the game
  function setGameTime(GameTime calldata _gameTime) public onlyOwner {
    gameTime = _gameTime;
    emit Scheduled(_gameTime.start, _gameTime.end);
  }

  // @notice set the start and end time of the game
  function setHelper(address _helper, bool status) public onlyOwner {
    helpers[_helper] = status;
  }

  // @notice ensure an action is mid-game
  modifier duringGame() {
    require(block.timestamp >= gameTime.start && block.timestamp <= gameTime.end, "Game: inactive");
    _;
  }

  // @notice ensure an action is not from a smart contract, outside a 
  modifier originCheck() {
    require(msg.sender == tx.origin || helpers[msg.sender], "Game: cannot play from contract");
    _;
  }

}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./Game.sol";
import "./PenaltyQueue.sol";
import '../utils/VRF.sol';

// @notice Penalty kick contract using Chainlink VRF
contract Penalties is Game, VRF{

  using PenaltyQueue for PenaltyQueue.Queue;

  uint8 public currentRound = 1;

  uint256[] public goalPayouts = [30 ether, 75 ether, 143 ether, 244 ether, 396 ether];

  function rounds() public view returns(uint256) {
    return goalPayouts.length;
  }

  bool public pending = false;
  uint256 public constant period = 10 minutes;

  uint32 public baseRate = 58982; // ~90% base rate chance of scoring

  event TookAPenalty(address indexed holder, uint16 tokenId, PenaltyQueue.Choice choice, uint8 round, bool onTarget);
  event GafferDive(uint8 round, PenaltyQueue.Choice choice);
  event Revealed(address holder, uint16 tokenId, uint8 rounds, uint256 reward);

  PenaltyQueue.Queue public queue;

  mapping(uint8 => PenaltyQueue.Choice) public gafferChoices;

  constructor(uint64 _subscriptionId, address _vrfCoordinator, bytes32 _keyHash, address _bootcampPlayer, address _reddies)
  VRF(_subscriptionId, _vrfCoordinator, _keyHash) Game(_bootcampPlayer,_reddies){
  }

  function revealTime(uint256 _round) public view returns(uint256) {
    return gameTime.start + (_round * period);
  }

  function requestRandomWords() external {
      require(block.timestamp > revealTime(currentRound), "ROUND NOT OVER");
      require(currentRound <= rounds(), "SHOOTOUT OVER");
      require(!pending, "REQUESTED ALREADY");
      pending = true;
      COORDINATOR.requestRandomWords(
        keyHash,
        s_subscriptionId,
        requestConfirmations,
        callbackGasLimit,
        numWords
      );
  }

  function fulfillRandomWords(uint256, uint256[] memory randomWords) internal override {
      pending = false;
      uint choice = randomWords[0] % 3;
      gafferDives(PenaltyQueue.Choice(choice));
  }

  function ownerFufillRandomWords() external onlyOwner{
      pending = false;
      uint choice = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % 3;
      gafferDives(PenaltyQueue.Choice(choice));
  }

  function gafferDives(PenaltyQueue.Choice choice) public {
    require(block.timestamp > revealTime(currentRound), "ROUND NOT OVER");
    require(currentRound <= rounds(), "SHOOTOUT OVER");
    gafferChoices[currentRound] = choice;
    emit GafferDive(currentRound, choice);
    currentRound = currentRound + 1;
  }

  function takePenalty(uint16[] calldata tokenIds, PenaltyQueue.Choice choice) public duringGame whenNotPaused originCheck {
    require(currentRound <= rounds(), "SHOOTOUT OVER");
    for (uint256 i = 0; i < tokenIds.length; i++) {
      uint16 tokenId = tokenIds[i]; 
      bool onTarget = tokenOdds(tokenId) > uint16(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), tokenIds[i]))));
      require(bootcampPlayer.ownerOf(tokenId) == msg.sender, "NOT YOUR TOKEN");
      if(!queue.played(tokenId)) {
        require(bootcampPlayer.hasStats(tokenId), "NOT GAME READY");
        queue.pushBack(PenaltyQueue.Penalty(tokenId, currentRound, choice, onTarget, 0));
      } else {
        PenaltyQueue.Penalty storage penalty = queue.tokenPenalty(tokenId);
        require(penalty.onTarget, "MISSED THE TARGET");
        require(penalty.choice != gafferChoices[penalty.round], "GAFFER SAVED");
        require(currentRound > penalty.round, "ALREADY PLAYED");
        queue.newChoice(PenaltyQueue.Penalty(tokenId, currentRound, choice, onTarget, penalty.priorGoals + 1));
      }
      emit TookAPenalty(msg.sender, tokenId, choice, currentRound, onTarget);
    }
  }

  function played(uint256 tokenId) public override view returns (bool) {
    return queue.played(uint16(tokenId));
  }

    // @notice helper max function
  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  function payouts() public view returns(uint256) {
    return queue.length();
  }

  // @notice reveal as many as possible up to an amount
  function payout(uint256 amount) public {
    require(currentRound > rounds(), "SHOOTOUT ONGOING");
    require(payouts() > 0, "ALL PAID OUT");
    uint256 loops = min(amount, queue.length());
    for (uint256 i = 0; i < loops; i++) {
      PenaltyQueue.Penalty memory penalty = queue.popFront();
      uint256 reward;
      address holder = bootcampPlayer.ownerOf(penalty.tokenId);
      if(penalty.onTarget && penalty.choice != gafferChoices[penalty.round]) {
        reward = goalPayouts[penalty.priorGoals]; // not + 1 because it's zero indexed
        reddies.mint(holder, reward);
      }
      emit Revealed(holder, penalty.tokenId, penalty.priorGoals + 1, reward);
    }
  }

  function attributeBoost(uint256 tokenId) public view returns (uint32) {
      Stats memory stats = bootcampPlayer.getPlayerStats(tokenId);
      return uint32(uint256(stats.finishing) * 1966); // 1000 extra chances per finishing point (will exceed maxUint16)
  }

  function traitBoost(uint256 tokenId) public view returns (uint32) {
      Metadata memory metadata = bootcampPlayer.getPlayerMetadata(tokenId);
      bool penaltyBoost = metadata.quirks == 23 || metadata.playerType == 2 || metadata.quirks == 13 || metadata.quirks == 17 || metadata.quirks == 21;
      return penaltyBoost ? 10000 : 0;
  }

    // @notice view function to get the odds for a given token
  function tokenOdds(uint256 tokenId) public view virtual returns (uint32 odds) {
    odds = baseRate;
    odds += traitBoost(tokenId);
    odds += attributeBoost(tokenId);
  }

}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

// @notice abstract scaffolding for Simple Risky Games
library PenaltyQueue {

  enum Choice {
        Left,
        Middle,
        Right
    }

  struct Penalty {
        uint16 tokenId;
        uint8 round;
        Choice choice;
        bool onTarget; // We could maybe not store missed penalties, but that makes liveness checks complicated
        uint8 priorGoals;
        }

  struct Queue {
        uint16 _begin; // There will only ever be maximum one entry per token, so this type works
        uint16 _end;
        mapping(uint16 => Penalty) _data;
        mapping(uint16 => uint16) _lookupPlusOne; // Naming it this to be explicit what this is -> +1 is to allow check for non zero
        }

    function played(Queue storage deque, uint16 tokenId) internal view returns (bool) {
        return deque._lookupPlusOne[tokenId] > 0;
    }

    function tokenPenalty(Queue storage deque, uint16 tokenId) internal view returns (Penalty storage value) {
        uint16 lookup = deque._lookupPlusOne[tokenId] - 1;
        value = deque._data[lookup];
    }

    function front(Queue storage deque) internal view returns (Penalty storage value) {
        uint16 frontIndex = deque._begin;
        return deque._data[frontIndex];
    }

    function pushBack(Queue storage deque, Penalty memory value) internal {
        uint16 backIndex = deque._end;
        deque._lookupPlusOne[value.tokenId] = backIndex + 1; // Adding 1 here so we can check for existence
        deque._data[backIndex] = value;
        unchecked {
            deque._end = backIndex + 1;
        }
    }

    function newChoice(Queue storage deque, Penalty memory value) internal {
        uint16 lookup = deque._lookupPlusOne[value.tokenId] - 1;
        deque._data[lookup] = value;
    }

    function length(Queue storage deque) internal view returns (uint16) {
        // The interface preserves the invariant that begin <= end so we assume this will not overflow.
        // We also assume there are at most int256.max items in the queue.
        unchecked {
            return deque._end - deque._begin;
        }
    }

    function popFront(Queue storage deque) internal returns (Penalty memory penalty) {
        uint16 frontIndex = deque._begin;
        penalty = deque._data[frontIndex];
        delete deque._data[frontIndex];
        unchecked {
            deque._begin = frontIndex + 1;
        }
    }

}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../types/BootcampTypes.sol";

interface IBootcampPlayer is IERC721 {

    /**
     * @dev returns the player stats
     */
    function getPlayerStats(uint256 tokenId)
        external
        view
        returns (Stats memory);

    /**
     * @dev returns the player stats
     */
    function getBatchPlayerStats(uint32[] calldata tokenIds)
        external
        view
        returns (Stats[] memory stats);

    /**
     * @dev returns the player stats
     */
    function getPlayerMetadata(uint256 tokenId)
        external
        view
        returns (Metadata memory);

    /**
     * @dev returns the player stats
     */
    function getBatchPlayerMetadata(uint32[] calldata tokenIds)
        external
        view
        returns (Metadata[] memory stats);

    /**
     * @dev returns the player stats
     */
    function hasStats(uint256 tokenId)
        external
        view
        returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IREDDIES {
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
     * mints $REDDIES to a recipient
     * @param to the recipient of the $REDDIES
     * @param amount the amount of $REDDIES to mint
     */
    function mint(address to, uint256 amount) external;

    /**
     * burns $REDDIES from a holder
     * @param from the holder of the $REDDIES
     * @param amount the amount of $REDDIES to burn
     */
    function burn(address from, uint256 amount) external;
}

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

struct Metadata {
    uint16 playerType;
    uint16 skillLevel;
    uint16 quirks;
    bool pet;
}

struct Stats {
    uint8 passing;
    uint8 finishing;
    uint8 tackling;
    uint8 teamwork;
    uint8 creativity;
    uint8 pace;
    uint8 strength;
    uint8 kit;
    uint8 boots;
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import '@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol';
import '@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol';
import '@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol';

abstract contract VRF is VRFConsumerBaseV2{

  VRFCoordinatorV2Interface public COORDINATOR;
  uint64 s_subscriptionId;
  bytes32 keyHash;
  uint32 callbackGasLimit = 200000;
  uint16 requestConfirmations = 3;
  uint32 numWords = 1;

  constructor(uint64 _subscriptionId, address _vrfCoordinator, bytes32 _keyHash)
  VRFConsumerBaseV2(_vrfCoordinator){
    COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
    keyHash = _keyHash;
    s_subscriptionId = _subscriptionId;
  }

}