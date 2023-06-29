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
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract VRFConsumerBaseV2Upgradable is Initializable {
    error OnlyCoordinatorCanFulfill(address have, address want);
    address private vrfCoordinator;

    /**
     * @param _vrfCoordinator address of VRFCoordinator contract
     */
    function __VRFConsumerBaseV2_init(address _vrfCoordinator) internal initializer {
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/// @title Interface for the Lucky cat raffle 3.0
interface ICatRaffle_3_0 {
    error ICatRaffle_3_0__InvalidId(uint256 _raffleId);
    error ICatRaffle_3_0__InvalidInputs();
    error ICatRaffle_3_0__InvalidUserEntries();
    error ICatRaffle_3_0__InvalidStartTime(uint256 _invalidStart);
    error ICatRaffle_3_0__NotDrawable(uint256 _raffleId);
    error ICatRaffle_3_0__IsDrawn(uint256 _raffleId);
    error ICatRaffle_3_0__NoRewards(address _address);
    error ICatRaffle_3_0__ValueError(string _message);
    error ICatRaffle_3_0__NotPausable(uint256 _raffleId);
    error ICatRaffle_3_0__Unauthorized();
    error ICatRaffle_3_0__InvalidRaffle(uint256 _raffleId);
    error ICatRaffle_3_0__Paused(uint256 _raffleId);
    error ICatRaffle_3_0__ZeroEntries();
    error ICatRaffle_3_0__AlreadyClaimed();
    error ICatRaffle_3_0__RaffleNotDrawn();
    error ICatRaffle_3_0__TicketNotFound(
        uint256 _ticket,
        uint256 _totalEntries,
        uint256 _totalPrizes
    );
    error ICatRaffle_3_0__TotalEntriesExceeded();
    error ICatRaffle_3_0__NotEnoughEntries();
    error ICatRaffle_3_0__MaxEntriesPerUserExceeded();
    error ICatRaffle_3_0__RaffleNotStartedYet();

    error ICatRaffle_3_0__InvalidTicketId(uint256 ticketId);
    error ICatRaffle_3_0__MismatchedPrizeLengths();
    error ICatRaffle_3_0__InvalidUserEntryLimits(uint256 userMinEntries, uint256 userMaxEntries);
    error ICatRaffle_3_0__ZeroUserEntries(uint256 userMinEntries, uint256 userMaxEntries);
    error ICatRaffle_3_0__UserMaxExceedsTotal(uint256 userMaxEntries, uint256 totalEntries);
    error ICatRaffle_3_0__UserMinExceedsTotal(uint256 userMinEntries, uint256 totalEntries);
    error ICatRaffle_3_0__ZeroTotalEntries();

    /**
     * @notice Event emitted when a player has entered a raffle.
     * @param _raffleId The id of the raffle.
     * @param _player The address of the player who entered the raffle.
     */
    event RaffleEntered(uint256 _raffleId, address _player);
    /**
     * @notice Event emitted when winners are drawn for a raffle.
     * @param _raffleId The id of the raffle.
     */
    event RaffleDrawn(uint256 _raffleId);
    /**
     * @notice Event emitted when a player has claimed raffle rewards.
     * @param _player The address of the player who entered the raffle.
     */
    event RaffleClaimed(address _player);
    /**
     * @notice Event emitted when a raffle has been registered.
     * @param _raffleId The id of the raffle.
     */
    event RaffleRegistered(uint256 _raffleId);
    /**
     * @notice Event emitted when a raffle has been updated.
     * @param _raffleId The id of the raffle.
     */
    event RaffleUpdated(uint256 _raffleId);
    /**
     * @notice Event emitted when a raffle has been paused.
     * @param _raffleId The id of the raffle.
     * @param _isPaused is true when raffle is paused and false when not.
     */
    event RaffleSetPaused(uint256 _raffleId, bool _isPaused);
    /**
     * @notice Event emitted when a raffle has been deleted.
     * @param _raffleId The id of the raffle.
     */
    event RaffleDeleted(uint256 _raffleId);

    enum PrizeType {
        ERC721,
        ERC1155
    }

    struct Raffle {
        uint256 ticketId;
        address prizeAddress;
        PrizeType prizeType;
        uint256[] prizeIds;
        uint256[] prizeAmounts;
        uint256 totalPrizes;
        uint256 totalEntries;
        uint256 userMinEntries;
        uint256 userMaxEntries;
        uint256 startTime;
        uint256 duration;
        address raffleTreasury;
        bool paused;
        bool isDrawn;
        uint raffleId;
        uint entries;
    }

    struct RaffleInput {
        uint256 ticketId;
        address prizeAddress;
        PrizeType prizeType;
        uint256[] prizeIds;
        uint256[] prizeAmounts;
        uint256 totalPrizes;
        uint256 totalEntries;
        uint256 userMinEntries;
        uint256 userMaxEntries;
        uint256 startTime;
        uint256 duration;
        address raffleTreasury;
    }

    /**
     * @notice Used for a user to enter a raffle.
     * @param _raffleId The ID of the raffle to enter.
     * @param _numTickets The number of tickets to enter the raffle with.
     *
     * @dev Requires that the raffle has not been drawn, is not paused, is valid and has started.
     * Also requires that the number of tickets is not zero, does not exceed the total entries,
     * and is not less than the minimum entries per user. Additionally, it requires that the total number
     * of tickets per user does not exceed the maximum entries per user.
     *
     * throws ICatRaffle_3_0__IsDrawn when the raffle has already been drawn.
     * throws ICatRaffle_3_0__InvalidRaffle when raffleId doesn't exist or when raffle is already finished.
     * throws ICatRaffle_3_0__Paused when the raffle is currently paused.
     * throws ICatRaffle_3_0__ZeroEntries when zero tickets are entered.
     * throws ICatRaffle_3_0__TotalEntriesExceeded when the total entries would be exceeded by the ticket purchase.
     * throws ICatRaffle_3_0__NotEnoughEntries when the number of tickets entered is less than the minimum entries per user.
     * throws ICatRaffle_3_0__MaxEntriesPerUserExceeded when the total number of tickets per user would exceed the maximum entries per user.
     * throws ICatRaffle_3_0__RaffleNotStartedYet when the raffle has not yet started.
     *
     * emit RaffleEntered upon successful raffle entry.
     */
    function enterRaffle(uint256 _raffleId, uint256 _numTickets) external;

    /**
     * @notice Draws winners for a given raffle, callable only by the contract's governor.
     * @param _raffleId The ID of the raffle to draw winners from.
     * @return _requestId The ID of the request to the random number generator.
     *
     * @dev Requires that the raffle exists, has finished and not already been drawn.
     * If there are entries in the raffle, it requests random words from the Chainlink coordinator,
     * and links the request ID to the raffle ID.
     *
     * throws ICatRaffle_3_0__InvalidRaffle when the raffleId doesn't exist.
     * throws ICatRaffle_3_0__NotDrawable when the raffle is not finished yet.
     * throws ICatRaffle_3_0__IsDrawn when all the winners have already been drawn.
     *
     * emit RaffleDrawn upon successful drawing of the raffle.
     */

    function drawWinners(uint256 _raffleId) external returns (uint256 _requestId);

    /**
     * @notice Allows a user to claim their rewards from finished raffles.
     * @param _raffleId The ID of the raffle from which to claim rewards.
     * @param _prizeIds An array of prize IDs to claim.
     *
     * @dev Iterates through each prize ID provided, checking if it has already been claimed
     * and if the raffle has been drawn. If these conditions are met, the prize is awarded to the winner.
     *
     * throws ICatRaffle_3_0__AlreadyClaimed if a prize has already been claimed.
     * throws ICatRaffle_3_0__RaffleNotDrawn if the raffle has not yet been drawn.
     *
     * emit RaffleClaimed for each successful claim of a prize, with the winning address as parameter.
     */
    function claimRewards(uint256 _raffleId, uint256[] memory _prizeIds) external;

    /**
     * @notice Admin register a new raffle with desired parameters.
     * @param _raffle RaffleInput struct with desired input parameters.
     *
     * Throws ICatRaffle_3_0__InvalidTicketId when ticketId isn't recognized.
     * Throws ICatRaffle_3_0__MismatchedPrizeLengths when the number of prize IDs doesn't match the number of prize amounts.
     * Throws ICatRaffle_3_0__InvalidUserEntryLimits when userMinEntries is higher than userMaxEntries.
     * Throws ICatRaffle_3_0__ZeroUserEntries when either userMinEntries or userMaxEntries is zero.
     * Throws ICatRaffle_3_0__UserMaxExceedsTotal when userMaxEntries are higher than totalEntries.
     * Throws ICatRaffle_3_0__UserMinExceedsTotal when userMinEntries is higher than totalEntries.
     * Throws ICatRaffle_3_0__ZeroTotalEntries when totalEntries is zero.
     *
     * It automatically assigns a new raffle ID, and creates a new raffle with the provided input parameters, which is stored in the 'raffles' mapping.
     * It also safely transfers the prize assets from the sender to the raffle treasury.
     *
     * Emits a RaffleRegistered event containing the new raffle ID.
     */
    function registerRaffle(RaffleInput memory _raffle) external returns (uint256 _raffleId);

    /**
     * @notice Updates an active raffle with new parameters.
     * @param _raffleId ID of the raffle to be updated.
     * @param _raffle RaffleInput struct with desired input parameters.
     *
     * Throws ICatRaffle_3_0__InvalidTicketId when ticketId isn't 16, 17, or 18.
     * Throws ICatRaffle_3_0__MismatchedPrizeLengths when the number of prize IDs doesn't match the number of prize amounts.
     * Throws ICatRaffle_3_0__InvalidUserEntryLimits when userMinEntries is higher than userMaxEntries.
     * Throws ICatRaffle_3_0__ZeroUserEntries when either userMinEntries or userMaxEntries is zero.
     * Throws ICatRaffle_3_0__UserMaxExceedsTotal when userMaxEntries are higher than totalEntries.
     * Throws ICatRaffle_3_0__UserMinExceedsTotal when userMinEntries is higher than totalEntries.
     * Throws ICatRaffle_3_0__ZeroTotalEntries when totalEntries is zero.
     * Throws ICatRaffle_3_0__InvalidRaffle when the start time of the raffle is zero.
     *
     * Updates the raffle with the provided parameters and emits a RaffleUpdated event containing the updated raffle ID.
     */
    function updateRaffle(uint256 _raffleId, RaffleInput memory _raffle) external;

    /**
     * @notice Used to set the paused status of a raffle.
     * @param _raffleId ID of the raffle whose pause status should be changed.
     * @param _isPaused Boolean flag used for pausing (true) or unpausing (false) a raffle.
     *
     * Throws ICatRaffle_3_0__InvalidRaffle when the raffle identified by _raffleId does not exist (start time of the raffle is zero).
     *
     * Sets the pause status of the raffle to the provided value and emits a RaffleSetPaused event containing the raffle ID and the new paused status.
     */
    function setPaused(uint256 _raffleId, bool _isPaused) external;

    /**
     * @notice Deletes the specified raffle. If tickets have already been entered, they must be manually reimbursed.
     * @param _raffleId The ID of the raffle that should be deleted.
     *
     * Throws ICatRaffle_3_0__InvalidRaffle when the raffle identified by _raffleId does not exist (start time of the raffle is zero).
     *
     * Deletes the raffle from the "raffles" mapping and emits a RaffleDeleted event with the ID of the deleted raffle.
     */
    function deleteRaffle(uint256 _raffleId) external;

    /**
     * @notice Retrieves details for the specified raffle.
     * @param _raffleId The ID of the raffle to retrieve.
     * @return raffle The Raffle struct associated with the given _raffleId. If no such raffle exists, returns a default Raffle struct.
     */
    function getRaffle(uint256 _raffleId) external view returns (Raffle memory raffle);

    /**
     * @notice Retrieves a list of all active raffles. A raffle is considered active if the current time is between its start time and end time.
     * @return raffles An array of Raffle structs, each representing an active raffle. If no active raffles exist, returns an empty array.
     */
    function getActiveRaffles() external view returns (Raffle[] memory raffles);

    /**
     * @notice Get list of all past raffles. Past raffle is defined as one where the current time is greater than the sum of its start time and duration.
     * @return _pastRaffles List of past raffles.
     */
    function getPastRaffles() external view returns (Raffle[] memory);

    /**
     * @notice Get a list of all upcoming raffles. An upcoming raffle is defined as one where the current time is less than its start time.
     * @return _upcomingRaffles List of upcoming raffles.
     */
    function getUpcomingRaffles() external view returns (Raffle[] memory);

    /**
     * @notice Checks if a draw can be performed on the raffle. A draw can be performed if the raffle has started, the current time is past the end of the raffle, and the raffle has not already been drawn.
     * @param _raffleId The id of the raffle to be checked.
     * @return _canDraw Returns true if a draw can be performed on the raffle, and false otherwise.
     */
    function canDraw(uint256 _raffleId) external view returns (bool _canDraw);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/// @title Interface for the Lucky cat raffle 3.0
/// @dev Quasi duplicate interface exist as IPIXCatRaffle.sol
interface IRaffleTreasury {
    function givePrize(
        address _winner,
        address _prize,
        uint256 _prizeId,
        uint256 _prizeAmount
    ) external;

    function giveBatchPrize(address[] memory winners, uint256 prizeId) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/VRFConsumerBaseV2Upgradable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

import "./ICatRaffle_3_0.sol";
import "./IRaffleTreasury.sol";

import "../mission_control/IAssetManager.sol";

contract LuckyCatRaffleV3 is
    ICatRaffle_3_0,
    VRFConsumerBaseV2Upgradable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    /* ========== STATE VARIABLES ========== */

    uint256 public raffleId;
    mapping(uint256 => Raffle) public raffles;
    mapping(uint256 => uint256) public raffleSeed;
    mapping(address => mapping(uint256 => uint256)) public userRaffleEntries;
    mapping(uint256 => bool) public raffleDrawn;
    mapping(uint256 => uint256) private drawRequest;

    mapping(uint256 => uint256) public multiplier;
    mapping(uint256 => uint256) public shifter;

    mapping(uint256 => mapping(uint256 => bool)) public claimed;

    IERC1155 public landmark;
    IERC1155 public ticket;

    IRaffleTreasury public erc721Treasury;
    IRaffleTreasury public erc1155Treasury;

    uint64 public subscriptionId;
    bytes32 public keyHash;
    uint32 public callbackGasLimit;
    uint16 public requestConfirmations;
    VRFCoordinatorV2Interface public COORDINATOR;

    mapping(address => bool) public moderators;
    mapping(uint256 => uint256[]) public cumulativeEntries;
    mapping(uint256 => mapping(uint256 => address)) public userAtIndex;

    modifier onlyGov() {
        if (msg.sender != owner() && !moderators[msg.sender]) revert ICatRaffle_3_0__Unauthorized();
        _;
    }

    /* ========== INITIALIZER ========== */

    function initialize(
        address _landmark,
        address _ticket,
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint64 _subscriptionId
    ) external initializer {
        require(_landmark != address(0), "invalid landmark");
        require(_ticket != address(0), "invalid ticket");

        landmark = IERC1155(_landmark);
        ticket = IERC1155(_ticket);

        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        keyHash = _keyHash;
        subscriptionId = _subscriptionId;

        callbackGasLimit = 2000000;
        requestConfirmations = 3;

        moderators[msg.sender] = true;

        __Ownable_init();
        __VRFConsumerBaseV2_init(_vrfCoordinator);
    }

    /// @inheritdoc ICatRaffle_3_0
    function enterRaffle(uint256 _raffleId, uint256 _numTickets) external {
        if (raffleDrawn[_raffleId]) revert ICatRaffle_3_0__IsDrawn(_raffleId);
        if (raffles[_raffleId].startTime == 0) revert ICatRaffle_3_0__InvalidRaffle(_raffleId);
        if (raffles[_raffleId].startTime + raffles[_raffleId].duration < block.timestamp)
            revert ICatRaffle_3_0__InvalidRaffle(_raffleId);
        if (raffles[_raffleId].paused) revert ICatRaffle_3_0__Paused(_raffleId);
        if (_numTickets == 0) revert ICatRaffle_3_0__ZeroEntries();
        if (raffles[_raffleId].entries + _numTickets > raffles[_raffleId].totalEntries)
            revert ICatRaffle_3_0__TotalEntriesExceeded();
        if (_numTickets < raffles[_raffleId].userMinEntries)
            revert ICatRaffle_3_0__NotEnoughEntries();
        if (
            userRaffleEntries[msg.sender][_raffleId] + _numTickets >
            raffles[_raffleId].userMaxEntries
        ) revert ICatRaffle_3_0__MaxEntriesPerUserExceeded();
        if (block.timestamp < raffles[_raffleId].startTime)
            revert ICatRaffle_3_0__RaffleNotStartedYet();

        Raffle storage _raffle = raffles[_raffleId];

        cumulativeEntries[_raffleId].push(raffles[_raffleId].entries + _numTickets);
        userAtIndex[_raffleId][cumulativeEntries[_raffleId].length - 1] = msg.sender;

        unchecked {
            userRaffleEntries[msg.sender][_raffleId] += _numTickets;
            raffles[_raffleId].entries += _numTickets;
        }

        IAssetManager(address(ticket)).trustedBurn(msg.sender, _raffle.ticketId, _numTickets);
        emit RaffleEntered(_raffleId, msg.sender);
    }

    /// @inheritdoc ICatRaffle_3_0
    function drawWinners(uint256 _raffleId) external onlyGov returns (uint256 _requestId) {
        if (raffles[_raffleId].startTime == 0) revert ICatRaffle_3_0__InvalidRaffle(_raffleId);
        if (block.timestamp < raffles[_raffleId].startTime + raffles[_raffleId].duration)
            revert ICatRaffle_3_0__NotDrawable(_raffleId);
        if (raffleDrawn[_raffleId]) revert ICatRaffle_3_0__IsDrawn(_raffleId);

        raffles[_raffleId].isDrawn = true;

        if (raffles[_raffleId].entries > 0) {
            require(keyHash != bytes32(0), "Must have valid key hash");

            _requestId = COORDINATOR.requestRandomWords(
                keyHash,
                subscriptionId,
                requestConfirmations,
                callbackGasLimit,
                uint32(1)
            );

            drawRequest[_requestId] = _raffleId;
            emit RaffleDrawn(_raffleId);
        }
    }

    /// @inheritdoc ICatRaffle_3_0
    function claimRewards(uint256 _raffleId, uint256[] memory _prizeIds) external {
        if (!raffleDrawn[_raffleId]) revert ICatRaffle_3_0__RaffleNotDrawn();
        for (uint i; i < _prizeIds.length; i++) {
            if (!claimed[_raffleId][_prizeIds[i]]){
                address winningAddress = getWinningAddress(_raffleId, _prizeIds[i]);

                _givePrize(winningAddress, _raffleId);
                claimed[_raffleId][_prizeIds[i]] = true;

                emit RaffleClaimed(winningAddress);
            }
        }
    }

    function _givePrize(address _player, uint256 _raffleId) internal {
        Raffle memory raffle = raffles[_raffleId];

        for (uint256 i; i < raffle.prizeIds.length; i++) {
            IRaffleTreasury(raffle.raffleTreasury).givePrize(
                _player,
                raffle.prizeAddress,
                raffle.prizeIds[i],
                raffle.prizeAmounts[i]
            );
        }
    }

    /// @inheritdoc ICatRaffle_3_0
    function registerRaffle(RaffleInput calldata r) external onlyGov returns (uint256 _raffleId) {
        if (r.ticketId != 16 && r.ticketId != 17 && r.ticketId != 18)
            revert ICatRaffle_3_0__InvalidTicketId(r.ticketId);
        if (r.prizeIds.length != r.prizeAmounts.length)
            revert ICatRaffle_3_0__MismatchedPrizeLengths();
        if (r.userMinEntries > r.userMaxEntries)
            revert ICatRaffle_3_0__InvalidUserEntryLimits(r.userMinEntries, r.userMaxEntries);
        if (r.userMinEntries == 0)
            revert ICatRaffle_3_0__ZeroUserEntries(r.userMinEntries, r.userMaxEntries);
        if (r.userMaxEntries == 0)
            revert ICatRaffle_3_0__ZeroUserEntries(r.userMinEntries, r.userMaxEntries);
        if (r.userMaxEntries > r.totalEntries)
            revert ICatRaffle_3_0__UserMaxExceedsTotal(r.userMaxEntries, r.totalEntries);
        if (r.userMinEntries > r.totalEntries)
            revert ICatRaffle_3_0__UserMinExceedsTotal(r.userMinEntries, r.totalEntries);
        if (r.totalEntries == 0) revert ICatRaffle_3_0__ZeroTotalEntries();

        unchecked {
            _raffleId = ++raffleId;
        }

        raffles[_raffleId] = Raffle({
            ticketId: r.ticketId,
            prizeAddress: r.prizeAddress,
            prizeType: r.prizeType,
            prizeIds: r.prizeIds,
            prizeAmounts: r.prizeAmounts,
            totalPrizes: r.totalPrizes,
            totalEntries: r.totalEntries,
            userMinEntries: r.userMinEntries,
            userMaxEntries: r.userMaxEntries,
            startTime: r.startTime == 0 ? block.timestamp : r.startTime,
            duration: r.duration,
            raffleTreasury: r.raffleTreasury,
            paused: true,
            isDrawn: false,
            raffleId: _raffleId,
            entries: 0
        });

        for (uint256 i; i < r.prizeIds.length; i++) {
            if (r.prizeType == ICatRaffle_3_0.PrizeType.ERC721) {
                IERC721(r.prizeAddress).safeTransferFrom(
                    msg.sender,
                    address(erc721Treasury),
                    r.prizeIds[i]
                );
            }
            if (r.prizeType == ICatRaffle_3_0.PrizeType.ERC1155) {
                IERC1155(r.prizeAddress).safeTransferFrom(
                    msg.sender,
                    address(erc1155Treasury),
                    r.prizeIds[i],
                    r.prizeAmounts[i] * r.totalPrizes,
                    ""
                );
            }
        }

        emit RaffleRegistered(_raffleId);
    }

    /// @inheritdoc ICatRaffle_3_0
    function updateRaffle(uint256 _raffleId, RaffleInput memory r) external onlyGov {
        if (r.ticketId != 16 && r.ticketId != 17 && r.ticketId != 18)
            revert ICatRaffle_3_0__InvalidTicketId(r.ticketId);
        if (r.prizeIds.length != r.prizeAmounts.length)
            revert ICatRaffle_3_0__MismatchedPrizeLengths();
        if (r.userMinEntries > r.userMaxEntries)
            revert ICatRaffle_3_0__InvalidUserEntryLimits(r.userMinEntries, r.userMaxEntries);
        if (r.userMinEntries == 0)
            revert ICatRaffle_3_0__ZeroUserEntries(r.userMinEntries, r.userMaxEntries);
        if (r.userMaxEntries == 0)
            revert ICatRaffle_3_0__ZeroUserEntries(r.userMinEntries, r.userMaxEntries);
        if (r.userMaxEntries > r.totalEntries)
            revert ICatRaffle_3_0__UserMaxExceedsTotal(r.userMaxEntries, r.totalEntries);
        if (r.userMinEntries > r.totalEntries)
            revert ICatRaffle_3_0__UserMinExceedsTotal(r.userMinEntries, r.totalEntries);
        if (r.totalEntries == 0) revert ICatRaffle_3_0__ZeroTotalEntries();
        if (raffles[_raffleId].startTime == 0) revert ICatRaffle_3_0__InvalidRaffle(_raffleId);

        Raffle storage _raffle = raffles[_raffleId];

        _raffle.ticketId = r.ticketId;
        _raffle.prizeAddress = r.prizeAddress;
        _raffle.prizeType = r.prizeType;
        _raffle.prizeIds = r.prizeIds;
        _raffle.prizeAmounts = r.prizeAmounts;
        _raffle.totalPrizes = r.totalPrizes;
        _raffle.totalEntries = r.totalEntries;
        _raffle.userMinEntries = r.userMinEntries;
        _raffle.userMaxEntries = r.userMaxEntries;
        _raffle.startTime = r.startTime;
        _raffle.duration = r.duration;
        _raffle.raffleTreasury = r.raffleTreasury;

        emit RaffleUpdated(_raffleId);
    }

    /// @inheritdoc ICatRaffle_3_0
    function setPaused(uint256 _raffleId, bool _isPaused) external onlyGov {
        if (raffles[_raffleId].startTime == 0) revert ICatRaffle_3_0__InvalidRaffle(_raffleId);

        raffles[_raffleId].paused = _isPaused;
        emit RaffleSetPaused(_raffleId, _isPaused);
    }

    function setERC721Treasury(address _treasury) external onlyGov {
        erc721Treasury = IRaffleTreasury(_treasury);
    }

    function setERC1155Treasury(address _treasury) external onlyGov {
        erc1155Treasury = IRaffleTreasury(_treasury);
    }

    function setKeyHash(bytes32 _keyHash) external onlyGov {
        keyHash = _keyHash;
    }

    function setSubscriptionId(uint64 _subscriptionId) external onlyGov {
        subscriptionId = _subscriptionId;
    }

    function setCallbackGasLimit(uint32 _callbackGasLimit) external onlyGov {
        callbackGasLimit = _callbackGasLimit;
    }

    function setRequestConfirmations(uint16 _requestConfirmations) external onlyGov {
        requestConfirmations = _requestConfirmations;
    }

    function setCOORDINATOR(VRFCoordinatorV2Interface _coordinator) external onlyGov {
        COORDINATOR = _coordinator;
    }

    /// @inheritdoc ICatRaffle_3_0
    function deleteRaffle(uint256 _raffleId) external onlyGov {
        if (raffles[_raffleId].startTime == 0) revert ICatRaffle_3_0__InvalidRaffle(_raffleId);

        delete raffles[_raffleId];
        emit RaffleDeleted(_raffleId);
    }

    /// @inheritdoc ICatRaffle_3_0
    function getRaffle(uint256 _raffleId) external view returns (Raffle memory raffle) {
        return raffles[_raffleId];
    }

    /// @inheritdoc ICatRaffle_3_0
    function getActiveRaffles() external view returns (Raffle[] memory _activeRaffles) {
        uint size;
        uint activeRaffleCount;
        for (uint256 i = 1; i <= raffleId; i++) {
            if (
                block.timestamp > raffles[i].startTime &&
                block.timestamp < (raffles[i].startTime + raffles[i].duration)
            ) size++;
        }

        _activeRaffles = new Raffle[](size);
        for (uint256 i = 1; i <= raffleId; i++) {
            if (
                block.timestamp > raffles[i].startTime &&
                block.timestamp < (raffles[i].startTime + raffles[i].duration)
            ) {
                _activeRaffles[activeRaffleCount] = raffles[i];
                ++activeRaffleCount;
            }
        }
    }

    /// @inheritdoc ICatRaffle_3_0
    function getPastRaffles() external view returns (Raffle[] memory _pastRaffles) {
        uint size;
        uint pastRaffleCount;
        for (uint256 i = 1; i <= raffleId; i++) {
            if (block.timestamp > raffles[i].startTime + raffles[i].duration) size++;
        }

        _pastRaffles = new Raffle[](size);
        for (uint256 i = 1; i <= raffleId; i++) {
            if (block.timestamp > raffles[i].startTime + raffles[i].duration) {
                _pastRaffles[pastRaffleCount] = raffles[i];
                ++pastRaffleCount;
            }
        }
    }

    /// @inheritdoc ICatRaffle_3_0
    function getUpcomingRaffles() external view returns (Raffle[] memory _upcomingRaffles) {
        uint size;
        uint upcomingRaffleCount;
        for (uint256 i = 1; i <= raffleId; i++) {
            if (block.timestamp < raffles[i].startTime) size++;
        }

        _upcomingRaffles = new Raffle[](size);
        for (uint256 i = 1; i <= raffleId; i++) {
            if (block.timestamp < raffles[i].startTime) {
                _upcomingRaffles[upcomingRaffleCount] = raffles[i];
                ++upcomingRaffleCount;
            }
        }
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        uint256 _raffleId = drawRequest[requestId];
        raffleSeed[_raffleId] = randomWords[0];
        raffleDrawn[_raffleId] = true;

        multiplier[_raffleId] =
            (raffles[_raffleId].entries / 2) +
            (uint256(keccak256(abi.encode(randomWords[0], 1))) % (raffles[_raffleId].entries / 2));

        while (gcd(multiplier[_raffleId], raffles[_raffleId].entries) != 1) multiplier[_raffleId]++;

        shifter[_raffleId] =
            uint256(keccak256(abi.encode(randomWords[0], 2))) %
            raffles[_raffleId].entries;
    }

    function getWinningAddress(uint256 _raffleId, uint256 _prizeId) public view returns (address) {
        if (!raffleDrawn[_raffleId]) revert ICatRaffle_3_0__RaffleNotDrawn();
        Raffle memory _raffle = raffles[_raffleId];

        uint256 N = raffles[_raffleId].entries;
        uint256 K = _raffle.totalPrizes;

        if (K > N) K = N;
        if (_prizeId >= K) return address(0);

        uint256 denseIndex = _prizeId * (N / K);

        uint256 winningTicket = (denseIndex * multiplier[_raffleId] + shifter[_raffleId]) %
            raffles[_raffleId].entries;

        int256 winnerIndex = binarySearch(cumulativeEntries[_raffleId], winningTicket + 1);

        if (winnerIndex == -1) revert ICatRaffle_3_0__TicketNotFound(winningTicket, N, K);
        return userAtIndex[_raffleId][uint256(winnerIndex)];
    }

    function getAllWinningAddresses(uint256 _raffleId) public view returns (address[] memory) {
        address[] memory winningAddresses = new address[](raffles[_raffleId].totalPrizes);

        for (uint256 i; i < winningAddresses.length; i++) {
            winningAddresses[i] = getWinningAddress(_raffleId, i);
        }
        return winningAddresses;
    }

    function getCumulativeEntries(uint _raffleId) external view returns (uint[] memory) {
        return cumulativeEntries[_raffleId];
    }

    /// @inheritdoc ICatRaffle_3_0
    function canDraw(uint256 _raffleId) external view returns (bool _canDraw) {
        if (raffles[_raffleId].startTime == 0) return false;
        if (raffles[_raffleId].startTime + raffles[_raffleId].duration > block.timestamp)
            return false;
        if (raffleDrawn[_raffleId]) return false;

        _canDraw = true;
    }

    function setTicket(address _ticket) external onlyGov {
        require(_ticket != address(0), "LUCKY_CAT: ADDRESS_ZERO");
        ticket = IERC1155(_ticket);
    }

    function setModerator(address _mod, bool _isMod) external onlyOwner {
        moderators[_mod] = _isMod;
    }

    function setUserAtIndex(uint256 _raffleId, uint256[] calldata _index, address[] calldata _players) external onlyOwner {
        for (uint256 i; i < _players.length; i++) {
            userAtIndex[_raffleId][_index[i]] = _players[i];
        }
    }

    function gcd(uint256 a, uint256 b) public pure returns (uint256) {
        // If a is 0, the GCD is b.
        if (a == 0) {
            return b;
        }

        // While b is not 0, keep checking the remainder of a divided by b, and assign the value of b to a,
        // and the remainder of a divided by b to b.
        while (b != 0) {
            uint256 r = a % b;
            a = b;
            b = r;
        }

        // When b is 0, the GCD is a.
        return a;
    }

    function binarySearch(uint256[] memory arr, uint256 target) private pure returns (int256) {
        int256 left = 0;
        int256 right = int256(arr.length) - 1;
        int256 mid;

        while (left <= right) {
            mid = left + (right - left) / 2;

            if (arr[uint256(mid)] == target) {
                return mid;
            } else if (arr[uint256(mid)] < target) {
                left = mid + 1;
            } else {
                right = mid - 1;
            }
        }

        if (left == 0 && arr[0] > target) {
            return 0;
        }

        return left;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/// @title Contract responsible for minting rewards and burning payment in the context of the mission control
interface IAssetManager {
    enum AssetIds {
        UNUSED_0, // 0, unused
        GoldBadge, //1
        SilverBadge, //2
        BronzeBadge, // 3
        GenesisDrone, //4
        PiercerDrone, // 5
        YSpaceShare, //6
        Waste, //7
        AstroCredit, // 8
        Blueprint, // 9
        BioModOutlier, // 10
        BioModCommon, //11
        BioModUncommon, // 12
        BioModRare, // 13
        BioModLegendary, // 14
        LootCrate, // 15
        TicketRegular, // 16
        TicketPremium, //17
        TicketGold, // 18
        FacilityOutlier, // 19
        FacilityCommon, // 20
        FacilityUncommon, // 21
        FacilityRare, //22
        FacilityLegendary, // 23,
        Energy, // 24
        LuckyCatShare, // 25,
        GravityGradeShare, // 26
        NetEmpireShare, //27
        NewLandsShare, // 28
        HaveBlueShare, //29
        GlobalWasteSystemsShare, // 30
        EternaLabShare // 31
    }

    /**
     * @notice Used to mint tokens by trusted contracts
     * @param _to Recipient of newly minted tokens
     * @param _tokenId Id of newly minted tokens
     * @param _amount Number of tokens to mint
     */
    function trustedMint(
        address _to,
        uint256 _tokenId,
        uint256 _amount
    ) external;

    /**
     * @notice Used to mint tokens by trusted contracts
     * @param _to Recipient of newly minted tokens
     * @param _tokenIds Ids of newly minted tokens
     * @param _amounts Number of tokens to mint
     */
    function trustedBatchMint(
        address _to,
        uint256[] calldata _tokenIds,
        uint256[] calldata _amounts
    ) external;

    /**
     * @notice Used to burn tokens by trusted contracts
     * @param _from Address to burn tokens from
     * @param _tokenId Id of to-be-burnt tokens
     * @param _amount Number of tokens to burn
     */
    function trustedBurn(
        address _from,
        uint256 _tokenId,
        uint256 _amount
    ) external;

    /**
     * @notice Used to burn tokens by trusted contracts
     * @param _from Address to burn tokens from
     * @param _tokenIds Ids of to-be-burnt tokens
     * @param _amounts Number of tokens to burn
     */
    function trustedBatchBurn(
        address _from,
        uint256[] calldata _tokenIds,
        uint256[] calldata _amounts
    ) external;
}