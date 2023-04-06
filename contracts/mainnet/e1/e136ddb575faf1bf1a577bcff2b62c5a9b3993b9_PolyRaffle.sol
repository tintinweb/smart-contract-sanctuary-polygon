/**
 *Submitted for verification at polygonscan.com on 2023-04-05
*/

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

// File: @openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
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

// File: @chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol


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

// File: @chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol

interface KeeperCompatibleInterface {
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

/**
 * @notice This is a deprecated interface. Please use AutomationCompatibleInterface directly.
 */
pragma solidity ^0.8.0;


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

// File: contracts/Raffler.sol


pragma solidity ^0.8.11;








interface IRaffleRakeCalculator {
    function getRakeForRaffle(uint256 raffleId, address creator) external view returns (uint32);
}
/// @title Rafflr!
/// @author Smitty
/// @notice A contract letting users sell raffle tickets for their NFTs
contract PolyRaffle is VRFConsumerBaseV2, KeeperCompatibleInterface, Ownable, ERC721Holder {

    enum RaffleState {
        NONEXISTENT,
        OPEN,
        CALCULATING,
        CLOSED
    }

    struct RaffleInfo {
        uint32 ticketMax;
        uint32 ticketCurrent;
        address creator;
        RaffleState state;
        address winner;
        uint256 raffleId;
        uint256 endTime;
        uint256 startTime;
        address nftContract;
        uint256 nftId;
        uint256 ticketPrice;
    }

    struct TicketRange {
        address entrant;
        uint32 from;
        uint32 to;
    }

    event RaffleStarted(address indexed creator, address indexed nftContract, uint256 nftId, uint256 indexed endTime, uint256 raffleId, uint256 ticketPrice, uint32 ticketMax, address gateNft);
    event WinnerPicked(address indexed winner, uint256 indexed raffleId);
    event RaffleEnter(address indexed player, uint256 indexed raffleId, uint32 indexed ticketCount);
    event RequestedRaffleWinner(uint256 indexed requestId, uint256 indexed raffleToClose);
    event RaffleClosed(uint256 indexed raffleId);

    VRFCoordinatorV2Interface private vrfCoordinator;
    uint16 private _requestConfirmations = 3;
    uint32 private constant NUM_WORDS = 1;
    uint32 private _callbackGasLimit;
    bytes32 private _gasLane;
    uint64 private _subscriptionId;

    /// @notice minimum length a raffle can last
    uint256 public minRaffleLength = 86400;
    /// @notice maximum length a raffle can last
    uint256 public maxRaffleLength = 86400 * 7;

    /// @notice upkeep checks will search all raffles created within this timeframe;
    /// @dev set separately from maxRaffleLength in case we change max length later
    uint256 public upkeepLookbackTime = 86400 * 7;

    /// @notice minimum allowed ticket price
    uint256 public minTicketPrice = .1 ether;

    /// @notice ticket prices must be a multiple of this
    uint256 public ticketMultiple = .01 ether;

    /// @notice maximum allowed ticket price
    uint256 public maxTicketPrice = 100 ether;

    /// @notice maximum allowed ticket amount
    uint32 public maxTicketAmount = 10000;

    /// @notice minimum allowed ticket amount
    uint32 public minTicketAmount = 10;

    /// @notice address to receive team's raffle sale percentage
    address public teamAddress = 0x8cD2B80bacC54A309522B2208A9094d716879468;

    /// @notice address of the rake calculator
    address public raffleRakeCalculator;

    /// @notice global switch to disallow raffle creation
    bool public openForRaffles = true;

    /// @notice incrementing counter for the current raffleId
    uint256 public currentRaffleId;

    /// @notice raffle info structs mapped by raffleId
    mapping(uint256 => RaffleInfo) public raffleById;

    /// @notice raffle ids mapped by VRF request ID
    /// @dev keeps track of which request was for which raffle, so they can be fulfilled
    mapping(uint256 => uint256) public raffleByRequestId;

    /// @notice Keeps track of the ticket numbers entrants own in each raffle
    mapping(uint256 => TicketRange[]) public ticketRangeByRaffle;

    /// @notice contracts that are not allowed to be raffled
    mapping(address => bool) public blacklist;

    /// @notice contracts that are allowed to be raffled
    mapping(address => bool) public whitelist;

    /// @notice Keeps track of token gated raffles
    mapping(uint256 => address) public tokenGateByRaffle;

    bool public useWhitelist = false;

    /// @dev contracts are not allowed to enter/create raffles
    modifier isEOA() {
        require(tx.origin == msg.sender);
        _;
    }

    /// @notice so the contract can be funded in case of emergency
    receive() external payable {}

    /// @dev constructor
    constructor(
        address vrfCoordinatorV2,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        _gasLane = gasLane;
        _subscriptionId = subscriptionId;
        _callbackGasLimit = callbackGasLimit;
    }

    function _createRaffle(
        address nftContract,
        uint256 nftId,
        uint256 endTime,
        uint256 ticketPrice,
        uint32 ticketMax
    ) internal {
        require(openForRaffles, "Raffles are closed");
        require(!blacklist[nftContract], "NFT blacklisted");
        if( useWhitelist ) {
            require(whitelist[nftContract], "NFT not whitelisted");
        }
        _validateRaffleParameters(endTime, ticketPrice, ticketMax);

        IERC721 nft = IERC721(nftContract);
        nft.transferFrom(msg.sender, address(this), nftId);
        currentRaffleId++;

        RaffleInfo memory ri;
        ri.nftContract = nftContract;
        ri.nftId = nftId;
        ri.endTime = endTime;
        ri.startTime = block.timestamp;
        ri.ticketPrice = ticketPrice;
        ri.ticketMax = ticketMax;
        ri.creator = msg.sender;
        ri.state = RaffleState.OPEN;
        ri.raffleId = currentRaffleId;

        raffleById[currentRaffleId] = ri;
    }

    /// @notice creates a new raffle
    /// @dev Requires permission to access the NFT to be raffled (transfers it to contract)
    function createRaffle(
        address nftContract,
        uint256 nftId,
        uint256 endTime,
        uint256 ticketPrice,
        uint32 ticketMax
    ) external isEOA {
        _createRaffle(nftContract, nftId, endTime, ticketPrice, ticketMax);
        emit RaffleStarted(msg.sender, nftContract, nftId, endTime, currentRaffleId, ticketPrice, ticketMax, address(0));
    }

    /// @notice creates a new token-gated raffle
    /// @dev Requires permission to access the NFT to be raffled (transfers it to contract)
    function createGatedRaffle(
        address nftContract,
        uint256 nftId,
        uint256 endTime,
        uint256 ticketPrice,
        uint32 ticketMax,
        address gatingNft
    ) external isEOA {
        _createRaffle(nftContract, nftId, endTime, ticketPrice, ticketMax);
        tokenGateByRaffle[currentRaffleId] = gatingNft;
        emit RaffleStarted(msg.sender, nftContract, nftId, endTime, currentRaffleId, ticketPrice, ticketMax, gatingNft);
    }


    /// @notice enters the sender into a raffle with ticketCount tickets
    function enterRaffle(uint256 raffleId, uint32 ticketCount) external payable isEOA {
        RaffleInfo storage ri = raffleById[raffleId];
        require(block.timestamp < ri.endTime, "Too late to enter");
        require(msg.value >= ri.ticketPrice * ticketCount, "Not enough AVAX");
        require(ri.state == RaffleState.OPEN, "Not open");
        require(ri.ticketCurrent + ticketCount <= ri.ticketMax, "No tickets left");
        if( tokenGateByRaffle[raffleId] != address(0) ) {
            IERC721 nft = IERC721(tokenGateByRaffle[raffleId]);
            require(nft.balanceOf(msg.sender) > 0, "Raffle is gated!");
        }
        TicketRange memory ticketRange;
        ticketRange.entrant = msg.sender;
        ticketRange.from = ri.ticketCurrent;
        ticketRange.to = ri.ticketCurrent + ticketCount-1;
        ri.ticketCurrent+= ticketCount;
        ticketRangeByRaffle[raffleId].push(ticketRange);

        emit RaffleEnter(msg.sender, raffleId, ticketCount);
    }

    /// @notice Allows raffle creator to cancel a raffle if no tickets were bought
    function cancelRaffle(uint256 raffleId) external isEOA {
        RaffleInfo storage ri = raffleById[raffleId];
        address creator = ri.creator;
        require(msg.sender == creator, "Did not create this");
        require(ri.ticketCurrent < 1, "Tickets already sold");
        ri.state = RaffleState.CLOSED;
        IERC721 nft = IERC721(ri.nftContract);
        nft.transferFrom(address(this), creator, ri.nftId);
        emit RaffleClosed(raffleId);
    }

    /** ========= Validation/Utils ======= */

    /// @dev validates that a raffle's endTime, ticketPrice, and ticketMax are within limits
    function _validateRaffleParameters(
        uint256 endTime,
        uint256 ticketPrice,
        uint256 ticketMax
    ) private view {
        require(endTime - block.timestamp >= minRaffleLength, "Raffle too short");
        require(endTime - block.timestamp <= maxRaffleLength, "Raffle too long");
        require(ticketPrice >= minTicketPrice, "Ticket price too low");
        require(ticketPrice <= maxTicketPrice, "Ticket price too low");
        require(ticketPrice % ticketMultiple == 0, "Bad price fidelity");
        require(ticketMax >= minTicketAmount, "Too few tickets");
        require(ticketMax <= maxTicketAmount, "Too many tickets");
    }

    /// @dev Validates that a raffle is open and past it's end time
    function _isRaffleReadyToClose( RaffleInfo memory ri) private view returns (bool) {
        bool isOpen = ri.state == RaffleState.OPEN;
        bool isTimeToClose = ri.endTime <= block.timestamp || ri.ticketCurrent >= ri.ticketMax;
        return isOpen && isTimeToClose;
    }

    /// @dev Given a raffleId and a winning ticket, finds the owner of the ticket with a binary search
    function _getWinnerFromRaffleAndIndex( uint256 raffleId, uint256 ticketIndex ) private view returns (address) {
        RaffleInfo memory ri = raffleById[raffleId];
        require(ticketIndex < ri.ticketCurrent, "Index doesn't exist");

        TicketRange[] memory ranges = ticketRangeByRaffle[raffleId];

        uint256 totalTicketRanges = ranges.length;

        require(ranges[0].from == 0);
        require(ranges[totalTicketRanges - 1].to == ri.ticketCurrent - 1);

        uint256 low = 0;
        uint256 high = totalTicketRanges - 1;
        uint256 mid = (low + high) / 2;
        address ownerAddress;

        while (ownerAddress == address(0)) {
            mid = (low + high) / 2;
            TicketRange memory range = ranges[mid];
            if (range.to < ticketIndex) {
                low = mid + 1;
            } else if (range.from > ticketIndex) {
                high = mid - 1;
            } else {
                ownerAddress = range.entrant;
            }
        }

        return ownerAddress;
    }

    /** ========= Chainlink integration ======= */

    /// @notice Checks to see if there's a raffle that requires upkeep (ending)
    /// @dev Starting from most recent raffle, moves back until it finds one that is past endTime or started longer than upkeepLookbackTime ago
    /// @dev Also returns the raffleId encoded to be sent to the performUpkeep function 
    function checkUpkeep(bytes memory /*checkData*/) public view override returns (bool upkeepNeeded, bytes memory performData) {
        upkeepNeeded = false;
        uint i = currentRaffleId;
        uint curTime = block.timestamp;
        RaffleInfo memory ri = raffleById[i];
        while( i > 0 && curTime < ri.startTime + upkeepLookbackTime ) {
            if( _isRaffleReadyToClose(ri) ) {
                return (true, abi.encode(i));
            }
            i--;
            ri = raffleById[i];
        }
        return (false, "");
    }

    /// @notice Called by chainlink keeper to close a raffle
    /// @dev takes an abi encoded raffleId to close and sends out a VRF request
    function performUpkeep(bytes calldata performData) external override {
        uint256 raffleToClose = abi.decode(performData, (uint256));
        require(raffleToClose <= currentRaffleId, "Open raffle doesn't exist");
        RaffleInfo storage ri = raffleById[raffleToClose];
        require(_isRaffleReadyToClose(ri), "Raffle not ready");

        ri.state = RaffleState.CALCULATING;
        uint256 requestId = vrfCoordinator.requestRandomWords(
            _gasLane,
            _subscriptionId,
            _requestConfirmations,
            _callbackGasLimit,
            NUM_WORDS
        );
        emit RequestedRaffleWinner(requestId, raffleToClose);
        raffleByRequestId[requestId] = raffleToClose;
    }

    /// @notice receives the random number from VRF and picks a winner, closing the raffle
    /// @dev Transfers NFT to the winner, sends funds to creator/team. Auto refunds the NFT if no entries
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        uint256 raffleId = raffleByRequestId[requestId];
        RaffleInfo storage ri = raffleById[raffleId];
        IERC721 nft = IERC721(ri.nftContract);
        if( ticketRangeByRaffle[raffleId].length == 0) {
            nft.transferFrom(address(this), ri.creator, ri.nftId);
            ri.state = RaffleState.CLOSED;
            emit RaffleClosed(raffleId);
            return;
        }
        uint256 indexOfWinner = randomWords[0] % ri.ticketCurrent;

        ri.winner = _getWinnerFromRaffleAndIndex(raffleId, indexOfWinner);

        uint256 prize = ri.ticketCurrent * ri.ticketPrice;
        ri.state = RaffleState.CLOSED;
        nft.transferFrom(address(this), ri.winner, ri.nftId);

        IRaffleRakeCalculator rakeCalculator = IRaffleRakeCalculator(raffleRakeCalculator);
        uint256 rake = rakeCalculator.getRakeForRaffle(raffleId, ri.creator);

        (bool success, ) = payable(ri.creator).call{value: prize * (10000 - rake) / 10000}("");
        require(success);
        (success, ) = payable(teamAddress).call{value: (prize * rake) / 10000}("");
        require(success);

        emit WinnerPicked(ri.winner, raffleId);
    }


    /*** ========= IN CASE OF EMERGENCY ============== */

    /// @notice Returns given NFT to contract owner in case of emergency
    function rescueToken(address nftContract, uint256 nftId) external onlyOwner {
        IERC721 nft = IERC721(nftContract);
        nft.transferFrom(address(this), msg.sender, nftId);
    }

    /// @notice withdraws AVAX to contract owner in case of emergency
    function rescueAvax(uint256 amount) external onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success);
    }

    /// @notice triggers VRF process for a given raffle in case of emergency
    function forceRequestWinner(uint256 raffleId) external onlyOwner {
        RaffleInfo storage ri = raffleById[raffleId];
        require(ri.state != RaffleState.CLOSED, "already closed");
        ri.state = RaffleState.CALCULATING;
        uint256 requestId = vrfCoordinator.requestRandomWords(
            _gasLane,
            _subscriptionId,
            _requestConfirmations,
            _callbackGasLimit,
            NUM_WORDS
        );
        raffleByRequestId[requestId] = raffleId;
        emit RequestedRaffleWinner(requestId, raffleId);
    }

    /// @notice sends NFT back to raffle creator, refunds all entrants in case of emergency
    function fullRefundRaffle(uint256 raffleId) external onlyOwner {
        RaffleInfo storage ri = raffleById[raffleId];
        ri.state = RaffleState.CLOSED;
        
        // Return NFT to creator of raffle
        IERC721 nft = IERC721(ri.nftContract);
        nft.transferFrom(address(this), ri.creator, ri.nftId);

        TicketRange[] memory ranges = ticketRangeByRaffle[raffleId];
        uint256 totalTicketRanges = ranges.length;
        bool success;
        // Refund all ticket purchasers
        for( uint i = 0; i < totalTicketRanges; i++ ) {
            TicketRange memory range = ranges[i];
            (success, ) = payable(range.entrant).call{value: (range.to - range.from + 1)*ri.ticketPrice}("");
            require(success);
        }

        emit RaffleClosed(raffleId);
    }

    /*** ======= Getters/Setters ======= ***/

    function getRaffleInfo(uint256 raffleId) public view returns (RaffleInfo memory) {
        return raffleById[raffleId];
    }

    function getTicketRangeFromRaffle(uint256 raffleId) public view returns (TicketRange[] memory) {
        return ticketRangeByRaffle[raffleId];
    }

    function getManyRaffleInfo(uint256[] memory raffleIds) public view returns (RaffleInfo[] memory) {
        RaffleInfo[] memory ret = new RaffleInfo[](raffleIds.length);
        uint raffleIdLength = raffleIds.length;
        for( uint i = 0; i < raffleIdLength; ++i ) {
            ret[i] = raffleById[raffleIds[i]];
        }

        return ret;
    }

    function setMinRaffleLength(uint256 length) external onlyOwner {
        minRaffleLength = length;
    }

    function setMaxRaffleLength(uint256 length) external onlyOwner {
        maxRaffleLength = length;
    }

    function setUpkeepLookbackTime(uint256 length) external onlyOwner {
        upkeepLookbackTime = length;
    }

    function setTicketMultiple(uint256 multiple) external onlyOwner {
        ticketMultiple = multiple;
    }

    function setMinTicketPrice(uint256 price) external onlyOwner {
        minTicketPrice = price;
    }

    function setMaxTicketPrice(uint256 price) external onlyOwner {
        maxTicketPrice = price;
    }

    function setMaxTicketAmount(uint32 amount) external onlyOwner {
        maxTicketAmount = amount;
    }

    function setMinTicketAmount(uint32 amount) external onlyOwner {
        minTicketAmount = amount;
    }

    function getNumWords() public pure returns (uint256) {
        return NUM_WORDS;
    }

    function getRequestConfirmations() public view returns (uint16) {
        return _requestConfirmations;
    }

    function setRequestConfirmations(uint16 requestConfirmations) public onlyOwner {
        _requestConfirmations = requestConfirmations;
    }

    function getGasLane() public view returns (bytes32) {
        return _gasLane;
    }

    function setGasLane(bytes32 gasLane) public onlyOwner {
        _gasLane = gasLane;
    }

    function getSubscriptionId() public view returns (uint64) {
        return _subscriptionId;
    }

    function setSubscriptionId(uint64 subscriptionId) public onlyOwner {
        _subscriptionId = subscriptionId;
    }

    function getCallbackGasLimit() public view returns (uint32) {
        return _callbackGasLimit;
    }

    function setCallbackGasLimit(uint32 callbackGasLimit) public onlyOwner {
        _callbackGasLimit = callbackGasLimit;
    }

    function setRaffleRakeCalculator(address _raffleRakeCalculator) public onlyOwner {
        raffleRakeCalculator = _raffleRakeCalculator;
    }

    function setTeamAddress(address teamAddress_) public onlyOwner {
        teamAddress = teamAddress_;
    }

    function setOpenForRaffles(bool openForRaffles_) public onlyOwner {
        openForRaffles = openForRaffles_;
    }

    function setCurrentRaffleId(uint256 raffleId) external onlyOwner {
        currentRaffleId = raffleId;
    }

    function setUseWhitelist(bool useWhitelist_) public onlyOwner {
        useWhitelist = useWhitelist_;
    }

    function addWhitelist(address[] memory _addressList) external onlyOwner {
		require(_addressList.length > 0, "Error: list is empty");

		for (uint256 i = 0; i < _addressList.length; i++) {
			whitelist[_addressList[i]] = true;
		}
	}

	function removeWhitelist(address[] memory addressList) external onlyOwner {
		require(addressList.length > 0, "Error: list is empty");
		for (uint256 i = 0; i < addressList.length; i++) {
			whitelist[addressList[i]] = false;
		}
	}
    
    function addBlacklist(address[] memory _addressList) external onlyOwner {
		require(_addressList.length > 0, "Error: list is empty");

		for (uint256 i = 0; i < _addressList.length; i++) {
			blacklist[_addressList[i]] = true;
		}
	}

	function removeBlacklist(address[] memory addressList) external onlyOwner {
		require(addressList.length > 0, "Error: list is empty");
		for (uint256 i = 0; i < addressList.length; i++) {
			blacklist[addressList[i]] = false;
		}
	}
}