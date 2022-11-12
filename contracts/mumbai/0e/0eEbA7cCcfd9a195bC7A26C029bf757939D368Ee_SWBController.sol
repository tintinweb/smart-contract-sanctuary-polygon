// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
pragma solidity ^0.8.0;

contract KeeperBase {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./KeeperBase.sol";
import "./interfaces/KeeperCompatibleInterface.sol";

abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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
pragma solidity ^0.8.0;

// import chainlink
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
// import openzeppelin
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// sweetblocks interfaces
import "./SWBControllerInterfaces.sol";
// sweetblock helpers
import "./SWBControllerHelpers.sol";
import "./SWBControllerEvents.sol";

contract SWBController is SWBControllerHelpers, SWBControllerEvents, KeeperCompatibleInterface, VRFConsumerBaseV2, ReentrancyGuard, Ownable {
    address public s_SWBExchangeAddress;
    address public s_SWBTokenAddress;
    address public s_SWBNFTAddress;

    // Splits percs state
    uint public s_HouseShare = 0;
    uint public s_houseSharePerc = 5;
    uint public s_winnersSharePerc = 50;
    uint public s_winnersSWBSharePerc = 15;
    uint public s_losersSharePerc = 30;
    address public s_houseDaoAddress;

    // General state
    uint public s_swb_cost; 
    uint public s_swb_block_interval;
    uint public s_mega_draw_block_interval;
    uint public s_swb_block_current;
    uint public s_mega_draw_block_current;
    uint public s_swb_block_last;
    uint public s_mega_draw_block_last;
    uint256 public s_swb_block_on_draw = 0;
    uint256 public s_swb_block_swap = 0;
    uint256 public s_swb_block_liquidity = 0;
    uint256 public s_swb_collect_interval = 3;
    uint256 public s_swb_buy_block = 10;
    uint private s_last_random_word;

    // MegaDraw state
    address[] public s_MegaDrawers;
    uint public s_MegaDrawHouseShare = 5;
    address public s_MegaDrawLastWinner;

    // SweetBlocks state
    uint public s_minNum = 1;
    uint public s_maxNum = 36;
    mapping(uint => mapping(uint => address[])) public s_swbs; 
    mapping(uint => uint) public s_swb_prize;
    mapping(uint => uint) public s_swb_players;
    mapping(uint => uint) public s_swb_tickets;
    mapping(uint => uint[]) public s_swb_results; // 0 winning number, 1 winners count, 2 losers count
    mapping(uint => uint[]) public s_swb_splits;

    // Players state
    mapping(address => mapping(uint => mapping(uint => uint))) public s_player_swb_number;
    mapping(address => mapping(uint => uint[])) public s_player_swb_numbers;
    mapping(address => mapping(uint => uint)) public s_player_swb_collected;
    mapping(address => mapping(uint => uint)) public s_player_swb_played;
    mapping(address => uint[]) public s_player_swb_played_array;
    mapping(address => uint[]) public s_player_swb_collected_array; 

    // ChainLink Integration State
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 public s_subscriptionId;
    address vrfCoordinator = 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed;
    bytes32 keyHash = 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;
    uint32 callbackGasLimit = 2500000;
    uint16 requestConfirmations = 3;
    uint32 numWords =  1;
    uint256[] public s_randomWords;
    uint256 public s_requestId;
    uint256[] public s_requestIds;

    constructor(address _SWBTokenAddress, address _SWBExchangeAddress, address _SWBNFTAddress, uint _s_swb_block_interval, uint _s_mega_draw_block_interval, uint64 _subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
        s_swb_block_interval = _s_swb_block_interval;
        s_swb_cost = 0.1 * 10**18;
        s_mega_draw_block_interval = s_swb_block_interval*(_s_mega_draw_block_interval+1);
        s_swb_block_current = block.number+s_swb_block_interval;
        s_mega_draw_block_current = block.number+s_mega_draw_block_interval; 
        s_houseDaoAddress = owner();
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_subscriptionId = _subscriptionId;
        s_SWBExchangeAddress = _SWBExchangeAddress;
        s_SWBTokenAddress = _SWBTokenAddress;
        s_SWBNFTAddress = _SWBNFTAddress;
    }

    /**
    * @dev Buy SweetBlocks. Mints 1 SWBDAO for each bought number.
    */

    function buySweetBlock(uint[] calldata _swblocks, uint[] calldata _numbers) external payable nonReentrant {
        require((block.number+s_swb_buy_block) < _swblocks[0], "P0");
        // check if player has sent enough ETH to buy all the numbers
        require(msg.value==s_swb_cost*_numbers.length, "P1");
        //require _blocks.length == _numbers.length
        require(_swblocks.length == _numbers.length, "P2");

        // loop over each number and play it for the sweetblock
        for (uint i = 0; i < _swblocks.length; ++i) {

            //number between 1 and 36
            require(_numbers[i] >= s_minNum && _numbers[i] <= s_maxNum, "P3");
            //player hasn't bought this number for this swb yet
            require(s_player_swb_number[msg.sender][_swblocks[i]][_numbers[i]]==0, "P4");

            s_player_swb_number[msg.sender][_swblocks[i]][_numbers[i]] = 1;
            //update swb jackpot with amount divided by number of swb
            s_swb_prize[_swblocks[i]] += msg.value/_swblocks.length;

            s_player_swb_numbers[msg.sender][_swblocks[i]].push(_numbers[i]);
            s_swb_tickets[_swblocks[i]] += 1;
            if(s_player_swb_played[msg.sender][_swblocks[i]]==0) {
                s_swb_players[_swblocks[i]] += 1;
                s_player_swb_played[msg.sender][_swblocks[i]] = 1;
                s_player_swb_played_array[msg.sender].push(_swblocks[i]);
            }
            s_swbs[_swblocks[i]][_numbers[i]].push(msg.sender);

        }

        ISWBNftInterface(s_SWBNFTAddress).mint(msg.sender,1,_swblocks.length);
        emit PlaySweetBlockEvent(msg.sender, _swblocks, _numbers, msg.value, 0, block.number);
    }

    /**
    * @dev Plays MegaDraw
    */

    function playMegaDraw() external {
        // burn nft    
        burnMegaDrawPass();
        s_MegaDrawers.push(msg.sender);
        emit PlayMegaDrawEvent(msg.sender, s_mega_draw_block_current, block.number);
    }

    /**
    * @dev Burns MegaDraw Pass.
    */

    function burnMegaDrawPass() internal nonReentrant {
        require(IERC1155(s_SWBNFTAddress).balanceOf(msg.sender, 0)>=1,"M4");
        ISWBNftInterface(s_SWBNFTAddress).burn(msg.sender, 0, 1);
    }


    /**
    * @dev Collects rewards.
    */

    function collectSweetBlock(uint[] calldata _swblocks) external nonReentrant {
        uint c0amount = 0;
        uint c1amount = 0;
        uint c2amount = 0;
        uint winning_count = 0;

        // loop over each swblock and check what player is entitled to collect
        for (uint i = 0; i < _swblocks.length; ++i) {
        
        //require swb less than current swb
        require(_swblocks[i] < s_swb_block_current,"C1");
        //require swb collect interval has passed
        require((s_swb_block_current-_swblocks[i]) >= (s_swb_collect_interval*s_swb_block_interval), "C4");
        // check player has played that block
        require(s_player_swb_played[msg.sender][_swblocks[i]]==1,"C2");
        // check player hasn't collected that block
        require(s_player_swb_collected[msg.sender][_swblocks[i]]==0,"C3");

        //update player collections state
        s_player_swb_collected[msg.sender][_swblocks[i]]=1;
        s_player_swb_collected_array[msg.sender].push(_swblocks[i]);

            //check if player has bought the winning number
            if(s_player_swb_number[msg.sender][_swblocks[i]][s_swb_results[_swblocks[i]][0]]==1) {
                // calc MATIC amount
                c0amount += s_swb_splits[_swblocks[i]][1]/s_swb_results[_swblocks[i]][1];
                // calc SWB amount
                c1amount += s_swb_splits[_swblocks[i]][4] / s_swb_results[_swblocks[i]][1];
                winning_count += 1;
            } else {
                // calc LPSWB amount
                c2amount += s_swb_splits[_swblocks[i]][5] / s_swb_results[_swblocks[i]][2];
            }

        }

        //transfer ETH
        payable(msg.sender).transfer(c0amount); 
        // transfer SWB
        ISWBTokenInterface(s_SWBTokenAddress).transfer(msg.sender, c1amount);
        // transfer LPSWB 
        IERC20(s_SWBExchangeAddress).transfer(msg.sender, c2amount);
        // emit collect event
        emit CollectSweetBlockEvent(msg.sender, _swblocks, c0amount, c1amount, c2amount, block.number);
        //mint MegaPassDraw
        if(winning_count>0) {
            ISWBNftInterface(s_SWBNFTAddress).mint(msg.sender,0,winning_count);
        }
    }


    /**
    * @dev Updates Sweet Block block's number.
    */

    function rotateSweetBlock() private {
        s_swb_block_last = s_swb_block_current;
        s_swb_block_current = s_swb_block_current+s_swb_block_interval;
        emit ChangeSweetBlock(s_swb_block_last, s_swb_block_current, block.number);
    }

    /**
    * @dev Updates MegaDraw block's number.
    */

    function rotateMegaDraw() private {
        s_mega_draw_block_last = s_mega_draw_block_current;
        s_mega_draw_block_current = s_swb_block_current+s_mega_draw_block_interval;
        emit ChangeMegaDraw(s_mega_draw_block_last, s_mega_draw_block_current, block.number);
    }
    
    /**
    * @dev Chainlink Automation integration.
    */

    function checkUpkeep(bytes calldata checkData) external view override returns (bool upkeepNeeded, bytes memory performData) {
        if(keccak256(checkData) == keccak256(hex'01')) {
            upkeepNeeded = (block.number >= s_swb_block_current && s_swb_block_on_draw==0);
            performData = checkData;
        }
        // Swap
        if(keccak256(checkData) == keccak256(hex'02')) {
            upkeepNeeded = (s_swb_block_swap != 0);
            performData = checkData;
        }
        // Add Liquidity
        if(keccak256(checkData) == keccak256(hex'03')) {
            upkeepNeeded = (s_swb_block_liquidity != 0);
            performData = checkData;
        }
        // Run MegaDraw
        if(keccak256(checkData) == keccak256(hex'04')) {
            upkeepNeeded = (block.number >= s_mega_draw_block_current);
            performData = checkData;
        }
    }

    /**
    * @dev Chainlink Automation integration.
    */

    function performUpkeep(bytes calldata performData) external override { 
        if(keccak256(performData) == keccak256(hex'01')) {
            if(s_swb_prize[s_swb_block_current]>0 && (block.number >= s_swb_block_current)) {
                // launch VRF
                s_swb_block_on_draw  = s_swb_block_current;
                getRandomness();
            } else if(s_swb_prize[s_swb_block_current]==0 && (block.number >= s_swb_block_current)) {
                rotateSweetBlock();
                s_swb_splits[s_swb_block_last] = [0, 0, 0, 0, 0, 0];
                emit CloseSweetBlockNoPrizeEvent(s_swb_block_last, block.number);
            } 
        }

        if(keccak256(performData) == keccak256(hex'02')) {
            if(s_swb_splits[s_swb_block_swap][2]>0 && s_swb_block_swap!=0) {
                uint amountOfTokens = ISWBExchangeInterface(s_SWBExchangeAddress).getAmountOfTokens(s_swb_splits[s_swb_block_swap][2], ISWBExchangeInterface(s_SWBExchangeAddress).getMaticReserve(), ISWBExchangeInterface(s_SWBExchangeAddress).getSWBReserve() , false);
                require(address(this).balance >= s_swb_splits[s_swb_block_swap][2],"S1");  
                uint amountOfSWB = ISWBExchangeInterface(s_SWBExchangeAddress).maticToSWBToken{value: s_swb_splits[s_swb_block_swap][2]}(amountOfTokens);
                s_swb_splits[s_swb_block_swap][4] = amountOfSWB;
                emit SwapSweetBlockEvent(s_swb_block_last, s_swb_splits[s_swb_block_swap][2], amountOfSWB, block.number);
            } 
            s_swb_block_swap = 0;
        }

        if(keccak256(performData) == keccak256(hex'03')) {
            if(s_swb_splits[s_swb_block_liquidity][3]>0 && s_swb_block_liquidity!=0) {
                uint amountOfSWB = (s_swb_splits[s_swb_block_liquidity][3] * ISWBExchangeInterface(s_SWBExchangeAddress).getSWBReserve()) / ISWBExchangeInterface(s_SWBExchangeAddress).getMaticReserve();
                require(address(this).balance >= s_swb_splits[s_swb_block_liquidity][3],"AD1");
                //require(IERC20(s_SWBTokenAddress).balanceOf(address(this)) >= amountOfSWB,"AD2");
                ISWBTokenInterface(s_SWBTokenAddress).mint(amountOfSWB);
                IERC20(s_SWBTokenAddress).approve(s_SWBExchangeAddress, amountOfSWB);
                uint amountOfLPTokens = ISWBExchangeInterface(s_SWBExchangeAddress).addLiquidity{value: s_swb_splits[s_swb_block_liquidity][3]}(amountOfSWB);
                // set game LPSW36 split
                s_swb_splits[s_swb_block_liquidity][5] = amountOfLPTokens;
                emit AddLiquiditySweetBlockEvent(s_swb_block_last, s_swb_splits[s_swb_block_liquidity][3], amountOfSWB, amountOfLPTokens, block.number);
            } 
            s_swb_block_liquidity = 0;  
        }
        if(keccak256(performData) == keccak256(hex'04')) {
            rotateMegaDraw();
            uint _HouseShare = s_HouseShare;
            uint windex = 0;
            uint winnerHouseShare = 0;
 
            if(s_MegaDrawers.length>0) {
                windex = s_last_random_word % s_MegaDrawers.length;
                winnerHouseShare = (_HouseShare / 100) * s_MegaDrawHouseShare;
                s_HouseShare = 0;
                s_MegaDrawLastWinner = s_MegaDrawers[windex];
                payable(s_MegaDrawers[windex]).transfer(winnerHouseShare);
                s_MegaDrawers = new address[](0);
                payable(s_houseDaoAddress).transfer(_HouseShare-winnerHouseShare);
            } else {
                s_MegaDrawLastWinner = address(this);
                payable(s_houseDaoAddress).transfer(_HouseShare);
            }
            emit CloseMegaDrawEvent(windex, s_MegaDrawLastWinner, winnerHouseShare, (_HouseShare-winnerHouseShare), _HouseShare, 0, block.number);
        }
        /*return true;*/
    }

    /**
    * @dev Triggers Chainlink VRF.
    */

    function getRandomness() private  {
        s_requestId = COORDINATOR.requestRandomWords(
        keyHash,
        s_subscriptionId,
        requestConfirmations,
        callbackGasLimit,
        numWords
        );
        emit RequestRandomnessEvent(s_swb_block_current, block.number);
    }

    /**
    * @dev Callback from Chainlink VRF.
    */

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        s_requestIds.push(requestId);
        s_last_random_word = randomWords[0];
        emit FulfillRandomnessEvent(s_swb_block_current, randomWords[0], block.number);
        if(s_swb_block_on_draw!=0) {
            rotateSweetBlock();
            uint wn = (randomWords[0] % s_maxNum) + 1;
            wn = 1;  // REMOVE AFTER TESTING
            // store sb winning number
            s_swb_results[s_swb_block_last].push(wn);
            // store sb winners count
            s_swb_results[s_swb_block_last].push(s_swbs[s_swb_block_last][wn].length);
            

            // CALC SPLITS IF ANY PRIZE > 0
           if(s_swb_prize[s_swb_block_last]>0) {
              // store sb losers count
                s_swb_results[s_swb_block_last].push(s_swb_players[s_swb_block_last]-s_swb_results[s_swb_block_last][1]);
                // calc splits
                (uint houseShare, uint winnersShare, uint winnersSWBShare, uint losersShare) = splitPrize(s_swb_prize[s_swb_block_last], s_swb_results[s_swb_block_last][1], s_houseSharePerc, s_winnersSharePerc, s_winnersSWBSharePerc, s_losersSharePerc);
        
                // increment HouseShare    
                s_HouseShare += houseShare;
                
                // update values for SWB
                s_swb_splits[s_swb_block_last].push(houseShare);
                s_swb_splits[s_swb_block_last].push(winnersShare);
                s_swb_splits[s_swb_block_last].push(winnersSWBShare);
                s_swb_splits[s_swb_block_last].push(losersShare);
                s_swb_splits[s_swb_block_last].push(0);
                s_swb_splits[s_swb_block_last].push(0);
                
                s_swb_block_on_draw = 0;
                
                //if(winnersSWBShare>0) {
                s_swb_block_swap = s_swb_block_last;
                //}
                
                //if(losersShare>0) {
                s_swb_block_liquidity = s_swb_block_last;
                //}

                // emit close sweet block event
                emit CloseSweetBlockEvent(s_swb_block_last, s_swb_tickets[s_swb_block_last], s_swb_players[s_swb_block_last], s_swb_results[s_swb_block_last][1], s_swb_results[s_swb_block_last][2], s_swb_results[s_swb_block_last][0], houseShare, winnersShare, winnersSWBShare, losersShare, block.number);
            } 
        

        }
    }

    
    /**
    * @dev Updates SweetBlocks jackpot splits.
    */

    /*function changeSWBSplits(uint[] calldata splits) external onlyOwner {
        checkSplits(splits);
        s_houseSharePerc = splits[0];
        s_winnersSharePerc = splits[1];
        s_winnersSWBSharePerc = splits[2];
        s_losersSharePerc = splits[3];
    }*/

    function changeBlockOnDraw(uint256 val) external onlyOwner {
        s_swb_block_on_draw = val;
    }

    function changeBlockSwap(uint256 val) external onlyOwner {
        s_swb_block_swap = val;
    }

    function changeBlockLiquidity(uint256 val) external onlyOwner {
        s_swb_block_liquidity = val;
    }

    /**
    * @dev Gets player's numbers for given SweetBlock.
    */

    function getPlayerSWBNumbers(address _player, uint _swb_number) external view returns(uint[] memory) {
        return s_player_swb_numbers[_player][_swb_number];
    }

    /**
    * @dev Gets player's played sweetblocks.
    */

    function getPlayerSWBPlayed(address _player) external view returns(uint[] memory) {
        return s_player_swb_played_array[_player];
    }

    /**
    * @dev Gets player's collected sweetblocks.
    */

    function getPlayerSWBCollected(address _player) external view returns(uint[] memory) {
        return s_player_swb_collected_array[_player];
    }

    /**
    * @dev Gets SweetBlock's jackpot splits.
    */

    function getSWBSplits(uint _swb_number) external view returns(uint[] memory) {
        return s_swb_splits[_swb_number];
    }

    /**
    * @dev Gets list of MegaDraw players.
    */

    function getMegaDrawers() external view returns(address[] memory){
        return s_MegaDrawers;
    }

    /**
    * @dev Gets SweetBlock's results.
    */

    function getSWBResults(uint _block) external view returns (uint[] memory) {
        return s_swb_results[_block];
    }

    /**
    * @dev Gets SweetBlock's jackpot.
    */

    function getSWBPrize(uint _block) external view returns (uint) {
        return s_swb_prize[_block];
    }

    /**
    * @dev Updates HouseDao address
    */

    /*function updateHouseDaoAddress(address _houseDaoAddress) external onlyOwner {
        s_houseDaoAddress = _houseDaoAddress;
    }*/

    function kill() public onlyOwner { // REMOVE IN PRODUCTION
        selfdestruct(payable(owner()));
    }

    // END UTILS

    receive() external payable {}

    fallback() external payable {}
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract SWBControllerEvents {

//events
    event RequestRandomnessEvent(
        uint indexed swb_number,
        uint block_number
    );

    event FulfillRandomnessEvent(
        uint indexed swb_number,
        uint randomword,
        uint block_number
    );

    event CloseSweetBlockEvent( 
        uint indexed swb_number,
        uint tickets,
        uint players,
        uint winners,
        uint losers,
        uint wn,
        uint houseShare,
        uint winnersShare,
        uint winnersSW36Share,
        uint losersShare,
        uint block_number
        );
    
    event CloseSweetBlockNoPrizeEvent(
        uint indexed swb_number,
        uint indexed block_number
        );

    event PlaySweetBlockEvent(
        address indexed player, 
        uint[] blocks, 
        uint[] numbers, 
        uint amount, 
        uint currency,
        uint indexed block_number
        );

    event CollectSweetBlockEvent(
        address indexed player, 
        uint[] blocks, 
        uint amount0,
        uint amount1,
        uint amount2,  
        uint block_number
        );

    event PlayMegaDrawEvent(
        address indexed player, 
        uint mega_draw,
        uint block_number
        );

    event CloseMegaDrawEvent(
        uint windex,
        address indexed waddress, 
        uint winnerHouseShare, 
        uint houseShare, 
        uint houseSharePre,
        uint currency, 
        uint block_number
        );


    event ChangeSweetBlock(
        uint swb_last, 
        uint swb_current, 
        uint block_number
        );
    
    event ChangeMegaDraw(
        uint megadraw_last,
        uint megadraw_current,  
        uint block_number
        );

    event SwapSweetBlockEvent(
        uint swb_last,
        uint amount_out,
        uint amount_in,
        uint block_number
        );

    event AddLiquiditySweetBlockEvent(
        uint swb_last, 
        uint amount_out_1, 
        uint amount_out_2, 
        uint amount_in, 
        uint block_number
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SWBControllerHelpers {

    /**
    * @dev Calcs jackpot splits.
    */

    function splitPrize(uint _prize, uint _winners_count, uint _houseSharePerc, uint _winnersSharePerc, uint _winnersSWBSharePerc, uint _losersSharePerc) internal pure returns(uint,uint,uint,uint) {
        uint houseShare = (_winners_count>0) ? _prize / 100 * _houseSharePerc : _prize / 100 * 50;
        uint winnersShare = (_winners_count>0) ? _prize / 100 * _winnersSharePerc : 0;
        uint winnersSWBShare = (_winners_count>0) ? _prize / 100 * _winnersSWBSharePerc : 0;
        uint losersShare = (_winners_count>0) ? _prize / 100 * _losersSharePerc : _prize / 100 * 50;
        return (houseShare, winnersShare, winnersSWBShare, losersShare);
    }

    /**
    * @dev Calcs MegaDraw jackpot.
    */

    function calcMegaDraw(uint _megadrawers_length, uint _randomness, uint _HouseShare, uint _MegaDrawHouseShare) internal pure returns(uint, uint) {
        uint windex = (_megadrawers_length>0) ? (_randomness % _megadrawers_length) : 0;
        //address waddress = (_megadrawers_length>0) ?  _megadrawers[windex] : _owner;
        uint winnerHouseShare = (_megadrawers_length>0) ? (_HouseShare / 100) * _MegaDrawHouseShare : 0;
        return (windex, winnerHouseShare);
    }

    /**
    * @dev Checks splits sum to 100.
    */

    function checkSplits(uint[] calldata splits) internal pure {
        require(splits.length==4, "CS1");
        require((splits[0]+splits[1]+splits[2]+splits[3]==100), "C22");
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISWBExchangeInterface {

    function addLiquidity(uint _amount) external payable returns (uint);
    function removeLiquidity(uint _amount) external returns (uint , uint);
    function getAmountOfTokens(uint256 inputAmount, uint256 inputReserve, uint256 outputReserve, bool dir) external view returns (uint256);
    function maticToSWBToken(uint _minSWB) external payable returns (uint);
    function SWBTokenToMatic(uint _SWBSold, uint _minMatic) external returns (uint);
    function getLPSWBTokenBalance() external view returns (uint);
    function claimLPSWBToken(address recipient, uint amount) external;
    function getSWBReserve() external view returns (uint);
    function getMaticReserve() external view returns (uint);
  
}

interface ISWBTokenInterface {
    function mint(uint256 amount) external;
    function balance(address player) external returns(uint);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface ISWBNftInterface {
    
    function mint(address recipient, uint256 amount, uint256 id) external;
    function burn(address recipient, uint256 amount, uint256 id) external;
    function getBalance(uint id) external view returns(uint);
    /*
    ID 1 => MegaDraw pass, if you win you get one - to mint again you need it to burn it - you burn it when you join the MegaDraw
    ID 2 => Dao Membrship pass - mint anytime you play and it used to vote (Quadratic Funding Voting)

    mint
    burn
    balanceOf
    transfer

    */
}