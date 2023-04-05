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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal initializer {
        __ERC721Holder_init_unchained();
    }

    function __ERC721Holder_init_unchained() internal initializer {
    }
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
    uint256[50] private __gap;
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

import "./IMissionControlStakeable.sol";

/// @title Interface defining the mission control
/// @dev This defines only essential functionality and not admin functionality
interface IMissionControl {
    error MC__InvalidCoordinates();
    error MC__NotWhitelisted();
    error MC__InvalidSigner();
    error MC__InvalidStreamer();
    error MC__TileNotRented();
    error MC__TilePaused();
    error MC__NoTileContractStaked();
    error MC__InvalidSuperToken();
    error MC__InvalidFlow();
    error MC__TileRentedWithDifferentSuperToken();
    error MC__SenderNotStreamerNorCrosschain();
    error MC__SenderNotTCLockProvider();
    error MC__TileRented();
    error MC__BaseStaked();
    error MC__InvalidPlacement();
    error MC__DuplicateTech();
    error MC__TileEmpty();
    error MC__TopStaked();
    error MC__ZeroRadius();
    error MC__ZeroAddress();

    /**
     * @notice This is a struct which contains information regarding a tile element
     * @param steakeable Address for the stakeable token on the tile
     * @param tokenId Id of the staked token
     * @param nonce Staking nonce
     * @param staked Boolean defining whether the token is actively staked, used as opposed to clearing the previous two on unstaking.
     */
    struct TileElement {
        address stakeable;
        uint256 tokenId;
        uint256 nonce;
    }

    struct TileRentalInfo {
        bool isRented;
        uint256 pausedAt;
        address rentalToken;
    }

    struct TileRequirements {
        uint256 price;
        uint256 tileContractId;
    }

    /**
     * @notice Struct to hold instructions for tile resource collection
     * @param x X-coordinate of tile
     * @param y Y-coordinate of tile
     * @param z Z-coordinate of tile
     */
    struct CollectOrder {
        int256 x;
        int256 y;
        int256 z;
    }

    /**
     * @notice Struct to hold instructions for placing NFTs on tiles
     * @param x X-coordinate of tile
     * @param y Y-coordinate of tile
     * @param z Z-coordinate of tile
     * @param tokenId Token ID of NFT
     * @param tokenAddress Address of NFT, which is presumed to implement the IMissionControlStakeable interface
     */
    struct PlaceOrder {
        CollectOrder order;
        uint256 tokenId;
        address tokenAddress;
    }

    struct HandleTopPlacementArgs {
        int256 x;
        int256 y;
        uint256 tokenId;
        address stakeable;
        uint256 nonce;
        address staker;
    }

    struct RemoveNFTVars {
        uint256 zeroOrOne;
        uint256 tokenId;
        address stakeable;
    }

    struct TotalTileInfo {
        CollectOrder order;
        bool isRented;
        uint256 flowRate;
        address rentalToken;
        int256 timeLeftBottom;
        int256 timeLeftTop1;
        int256 timeLeftTop2;
        TileElement base;
        TileElement top1;
        TileElement top2;
    }

    struct TotalCheckTileInfo {
        CollectOrder order;
        CheckTileOutputs out;
    }

    struct CheckTileInputs {
        address user;
        int256 x;
        int256 y;
        int256 z;
    }

    struct CheckTileOutputs {
        uint256 bottomAmount;
        uint256 bottomId;
        uint256 topAmount1;
        uint256 topId1;
        uint256 topAmount2;
        uint256 topId2;
    }

    struct HandleRaidCollectInputs {
        address defender;
        int256 x;
        int256 y;
    }

    struct HandleRaidCollectVars {
        TileElement tileElement;
        TileRentalInfo tileRentalInfo;
        IMissionControlStakeable iStakeable;
    }

    struct HandleCollectInputs {
        int256 x;
        int256 y;
        int256 z;
        uint256 position;
    }

    struct HandleCollectVars {
        TileElement tileElement;
        TileRentalInfo tileRentalInfo;
    }

    struct UpdateRentTileVars {
        int96 requiredFlow;
        uint256 index;
        uint256 size;
        uint256 removeTileLength;
        TileRentalInfo tile;
        CollectOrder removeTileItem;
        CollectOrder order;
    }

    struct GetAllCheckTileInfoVars {
        uint256 amount;
        uint256 tokenId;
        uint256 count;
        uint256 totalTiles;
        int256 radius;
    }

    struct CollectFromTilesVars {
        uint256 arrayLen;
        uint256[] ids;
        uint256[] amounts;
        uint256 cId;
        uint256 cAmount;
    }

    /**
     * @notice Stakes multiple NFTs on various tiles in one transaction
     * @param _placeOrders Array of structs containing information regarding where to place what
     * @dev Any downside to using structs as an argument?
     */
    function placeNFTs(PlaceOrder[] calldata _placeOrders) external;

    /**
     * @notice Removes multiple NFTs on various tiles in one transaction
     * @param orders Array of structs containing information regarding where to remove something
     * @dev Token id, address are ignored
     */
    function removeNFTs(
        CollectOrder[] memory orders,
        uint256[] memory positions,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    /**
     * @notice Queries a tile regarding the resources which are able to collected from it at the current moment
     * @dev Add support for multiple types of tokens, i.e return would be an array?
     */
    function checkTile(CheckTileInputs memory c) external view returns (CheckTileOutputs memory out);

    /**
     * @notice Collects (mints) tokens from tiles
     * @dev An alternative worth considering would be to have an alternative mint function
     * @param _orders Array containing collect orders
     * @dev Any downside to using structs as an argument?
     */
    function collectFromTiles(
        CollectOrder[] calldata _orders,
        uint256[] memory _positions,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    /**
     * @notice Used to check what a user has staked on a tile
     * @param _user The user whose Mission Control we should check
     * @param _x X-coordinate of tile
     * @param _y Y-coordinate of tile
     * @param _z Z-coordinate of tile
     */
    function checkStakedOnTile(
        address _user,
        int256 _x,
        int256 _y,
        int256 _z
    ) external view returns (TileElement memory _base, TileElement memory _top1, TileElement memory _top2);

    /**
     * @notice Returns when the tile was last updated
     * @param _user The user whose Mission Control we should check
     * @param _x X-coordinate of tile
     * @param _y Y-coordinate of tile
     * @param _z Z-coordinate of tile
     * @return _timestamp The time in blockchain seconds
     */
    function checkLastUpdated(
        address _user,
        int256 _x,
        int256 _y,
        int256 _z,
        uint256 _position
    ) external view returns (uint256 _timestamp);

    /**
     * @notice returns the remaining time until a tile is filled
     * @param _user The user whose Mission Control we should check
     * @param _x X-coordinate of tile
     * @param _y Y-coordinate of tile
     * @param _z Z-coordinate of tile
     */
    function timeLeft(
        address _user,
        int256 _x,
        int256 _y,
        int256 _z
    ) external view returns (int256 _timeLeftBottom, int256 _timeLeftTop1, int256 _timeLeftTop2);

    // user start streaming to the game
    function createRentTiles(
        address supertoken,
        address renter,
        CollectOrder[] memory tiles, // changed to PlaceOrder so that it inclues tokenId and token Address
        int96 flowRate
    ) external;

    // user is streaming and change the rented tiles
    function updateRentTiles(
        address supertoken,
        address renter,
        CollectOrder[] memory addTiles,
        CollectOrder[] memory removeTiles,
        int96 oldFlowRate,
        int96 flowRate
    ) external;

    function toggleTile(address _renter, int256 _x, int256 _y, uint256 rad, bool _shouldPause) external;

    // user stop streaming to the game
    function deleteRentTiles(address supertoken, address renter) external;

    function getAllowedRadius() external view returns (uint256);

    function getTileRentalInfo(address _user, int256 _x, int256 _y) external view returns (TileRentalInfo memory _info);

    function getTileRequirements(int256 _x, int256 _y) external view returns (TileRequirements memory _requirements);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/// @title Interface defining a contract which can be staked upon a "tile" in the mission control
interface IMissionControlStakeable {
    enum Rings {
        Apollo,
        Artemis,
        Chronos,
        Helios
    }

    struct CheckTileInputs {
        uint256 tokenId;
        uint256 localSeed;
        uint256 blockTime;
        uint256 elapsed;
        uint256 ret;
    }

    struct ResourceParams {
        uint tier;
        uint256 resourceEV;
        uint256 resourceId;
        uint256 resourceCap;
        bool isBase;
        bool isRaidable;
        uint256 ring;
    }

    struct ResourceParamOut {
        int256 x;
        int256 y;
        int256 z;
        bool isBase;
        bool isRaidable;
        uint256 resourceEV;
        uint256 resourceId;
        uint256 resourceCap;
    }

    struct RingParams {
        int x;
        int y;
        uint ring;
    }

    struct Request {
        address user;
        uint256 m3tam0dChance;
        uint256 tokenId;
    }
    /**
     * @notice Event emitted when a token is staked
     * @param _userAddress address of the staker
     * @param _stakeable Address to either the IMCStakeable implementation or the possibly the underlying token?
     * @param _tokenId Token id which has been staked
     */
    event TokenClaimed(address _userAddress, address _stakeable, uint256 _tokenId);
    /**
     * @notice Event emitted when a token is unstaked
     * @param _userAddress address of the staker
     * @param _stakeable Address to either the IMCStakeable implementation or the possibly the underlying token?
     * @param _tokenId Token id which has been unstaked
     */
    event TokenReturned(address _userAddress, address _stakeable, uint256 _tokenId);

    /**
     * @notice Event emitted when the mission control is set
     * @param missionControl The address of the mission control
     */
    event MissionControlSet(address missionControl);

    /**
     * @notice Resets the seed of a staked token. A cheaper alternative to onCollect when you do not need the number of harvested tokens
     * @param _userAddress The players address
     * @param _nonce Tile-staking nonce
     */
    function reset(address _userAddress, uint256 _nonce) external;

    /**
     * @notice Function to check the number of tokens ready to be harvested from this tile
     * @param _userAddress The players address
     * @param _nonce Tile-staking nonce
     * @return _amount Number of tokens that can be collected
     * @return _retTokenId The tokenId of the tokens that can be collected
     */
    function checkTile(
        address _userAddress,
        uint256 _nonce,
        uint256 _pausedAt,
        int256 _x,
        int256 _y
    ) external view returns (uint256 _amount, uint256 _retTokenId);

    /**
     * @notice Used to fetch new seed time upon collection some resources
     * @param _userAddress The players address
     * @param _nonce Tile-staking nonce
     * @return _amount Number of tokens that can be collected
     * @return _retTokenId The tokenId of the tokens that can be collected
     * @dev It is vital for this function to update the rng
     */
    function onCollect(
        address _userAddress,
        uint256 _nonce,
        uint256 _pausedAt,
        int256 _x,
        int256 _y
    ) external returns (uint256 _amount, uint256 _retTokenId);

    /**
     * @notice Used to see if the token can be used as the base of a tile, or if it is meant to be staked upon another token
     * @param _tokenId The id of the token
     * @return _isBase Whether this token is a base or not
     */
    function isBase(uint256 _tokenId, int256 _x, int256 _y) external view returns (bool _isBase);

    function isRaidable(uint256 _tokenId, int256 _x, int256 _y) external view returns (bool _isRaidable);

    /**
     * @notice transfers ownership of a token from the player to the stakeable contract
     * @param _currentOwner Address of the current owner
     * @param _tokenId The id of the token
     * @param _nonce Tile-staking nonce
     * @param _underlyingToken todo
     * @param _underlyingTokenId todo
     */
    function onStaked(
        address _currentOwner,
        uint256 _tokenId,
        uint256 _nonce,
        address _underlyingToken,
        uint256 _underlyingTokenId,
        address _besideToken,
        uint256 _besideTokenId,
        uint256 _besideNonce,
        int256 _x,
        int256 _y
    ) external;

    function onResume(address _renter, uint256 _nonce) external;

    /**
     * @notice transfers ownership of a token from the stakeable contract back to the player
     * @param _newOwner Address of the soon-to-be owner
     * @param _nonce Tile-staking nonce
     */
    function onUnstaked(address _newOwner, uint256 _nonce, uint256 _besideNonce) external;

    function checkTimestamp(address _userAddress, uint256 _nonce) external view returns (uint256 _timestamp);

    /**
     * @notice returns the remaining time until a tile is filled
     * @param _userAddress The players address
     * @param _nonce Tile-staking nonce
     * @return _timeLeft The time left, -1 if the time can not be predicted
     */
    // note: removed tokenId as a param. was unused
    function timeLeft(
        address _userAddress,
        uint256 _nonce,
        int256 _x,
        int256 _y
    ) external view returns (int256 _timeLeft);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IMissionControlStakeable.sol";
import "./IMissionControl.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "../libraries/VRFConsumerBaseV2Upgradable.sol";

/// @title Interface for the Rover ERC721 contract
interface IRover {
    function rovers(uint256 tokenId) external view returns (string memory, uint256, uint256, uint256);

    function breakdown(uint256 tokenId, uint256 to) external;
}

interface IM3tam0d {
    function trustedMint(address _to, uint256 _tokenId, uint256 _amount) external;
}

interface IPIXAssetStakeableAdapter {
    function getDroneTier(uint256 _droneId) external returns (uint256);

    function applyBuff(address _user, uint _nonce, bool _applied) external;
}

/**
 * @title Implementation of IMissionControlStakeable to handle ERC721 tokens
 */
contract RoverMCStakeableAdapter is
    IMissionControlStakeable,
    OwnableUpgradeable,
    ERC721HolderUpgradeable,
    VRFConsumerBaseV2Upgradable
{
    struct TokenInfo {
        bool isBase;
        bool isRaidable;
        uint256 resourceEV;
        uint256 resourceId;
        uint256 resourceCap;
    }

    struct OnCollectVars {
        uint256 tokenId;
        uint256 status;
        uint256 localSeed;
        uint256 fromTime;
    }
    event ParametersUpdated(address _stakeable, uint256 _id, uint256 _ev, uint256 _cap, bool _isBase);
    event M3tam0dMinted(address _recipient, uint256 _id, uint256 _amount);

    mapping(uint => mapping(int256 => mapping(int256 => TokenInfo))) public tokenInfo;

    mapping(uint256 => uint256) seeds;
    mapping(address => mapping(uint256 => uint256)) tokenIds;
    uint256 public maxCutoff;
    address public missionControl;
    address public erc721Token;

    VRFCoordinatorV2Interface public COORDINATOR;
    IM3tam0d public m3tam0d;
    uint256 public m3tam0dTokenId;

    bytes32 keyHash;
    uint32 callbackGasLimit;
    uint16 requestConfirmations;
    uint64 subscriptionId;

    address pixAssetAdapter;

    mapping(uint256 => Request) public s_requests;
    mapping(uint256 => mapping(uint256 => TokenInfo)) public tokenInfoByRing;
    mapping(int => mapping(int => uint)) public tileToRing;
    bool public paused;

    /**
     * @notice Initializer for this contract
     */
    function initialize(
        address _vrfCoordinator,
        address _m3tam0d,
        uint256 _m3tam0dTokenId,
        bytes32 _keyHash,
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations,
        uint64 _subscriptionId
    ) external initializer {
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        __VRFConsumerBaseV2_init(_vrfCoordinator);

        keyHash = _keyHash;
        callbackGasLimit = _callbackGasLimit;
        requestConfirmations = _requestConfirmations;
        subscriptionId = _subscriptionId;

        m3tam0d = IM3tam0d(_m3tam0d);
        m3tam0dTokenId = _m3tam0dTokenId;
        maxCutoff = 10 days;
        __Ownable_init();
    }

    /*
    IMissionControlStakeable implementation
    */

    modifier onlyMissionControl() {
        require(msg.sender == missionControl, "MCRover_ADAPTER: Sender not mission control");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "MCRover_ADAPTER: Paused");
        _;
    }

    function setResourceParameters(
        uint _tier,
        uint256 _resourceEV,
        uint256 _resourceId,
        uint256 _resourceCap,
        bool _isBase,
        bool _isRaidable,
        uint256 _ring
    ) public onlyOwner {
        tokenInfoByRing[_tier][_ring].resourceEV = _resourceEV;
        tokenInfoByRing[_tier][_ring].resourceId = _resourceId;
        tokenInfoByRing[_tier][_ring].resourceCap = _resourceCap;
        tokenInfoByRing[_tier][_ring].isBase = _isBase;
        tokenInfoByRing[_tier][_ring].isRaidable = _isRaidable;
        emit ParametersUpdated(address(this), _resourceId, _resourceEV, _resourceCap, _isBase);
    }

    function setResourceParametersBulk(ResourceParams[] memory param) external onlyOwner {
        for (uint i; i < param.length; i++)
            setResourceParameters(
                param[i].tier,
                param[i].resourceEV,
                param[i].resourceId,
                param[i].resourceCap,
                param[i].isBase,
                param[i].isRaidable,
                param[i].ring
            );
    }

    function setRings(RingParams[] memory ringParams) external onlyOwner {
        for (uint i; i < ringParams.length; i++) {
            tileToRing[ringParams[i].x][ringParams[i].y] = ringParams[i].ring;
        }
    }

    function setMissionControl(address _missionControl) external onlyOwner {
        missionControl = _missionControl;
        emit MissionControlSet(_missionControl);
    }

    function setPixAssetAdapter(address _pixAssetAdapter) external onlyOwner {
        pixAssetAdapter = _pixAssetAdapter;
    }

    function setERC721(address _erc721) external onlyOwner {
        require(_erc721 != address(0), "MCRover_ADAPTER: Address Zero");
        erc721Token = _erc721;
    }

    /// @inheritdoc IMissionControlStakeable
    function reset(address _userAddress, uint256 _nonce) external override onlyMissionControl {
        require(seeds[tokenIds[_userAddress][_nonce]] > 0, "MCRover_ADAPTER: No such token staked");
        seeds[tokenIds[_userAddress][_nonce]] = block.timestamp;
    }

    /// @inheritdoc IMissionControlStakeable
    function checkTile(
        address _userAddress,
        uint256 _nonce,
        uint256 _pausedAt,
        int256 _x,
        int256 _y
    ) external view override onlyMissionControl returns (uint256, uint256) {
        (uint256 amount, uint256 id, ) = __checkTile(_userAddress, _nonce, _pausedAt, _x, _y);
        return (amount, id);
    }

    /// @inheritdoc IMissionControlStakeable
    function onCollect(
        address _userAddress,
        uint256 _nonce,
        uint256 _pausedAt,
        int256 _x,
        int256 _y
    ) external override onlyMissionControl whenNotPaused returns (uint256, uint256) {
        OnCollectVars memory vars;

        vars.tokenId = tokenIds[_userAddress][_nonce];
        (, , vars.status, ) = IRover(erc721Token).rovers(vars.tokenId);
        vars.localSeed = seeds[vars.tokenId];
        vars.fromTime = _pausedAt > 0 ? _pausedAt : block.timestamp;
        require(vars.localSeed != 0, "MCRover_ADAPTER: No such token staked");
        if (vars.status == 3) return (0, 7);
        if (vars.fromTime - vars.localSeed < maxCutoff) return (0, 7);

        (uint256 amount, uint256 id, uint256 m3tam0dChance) = __checkTile(_userAddress, _nonce, _pausedAt, _x, _y);
        seeds[vars.tokenId] = vars.fromTime;

        // vrf request random word for m3tam0dChance
        require(keyHash != bytes32(0), "Must have valid key hash");
        uint256 requestId = COORDINATOR.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            1
        );
        s_requests[requestId] = Request({user: _userAddress, m3tam0dChance: m3tam0dChance, tokenId: vars.tokenId});
        return (amount, id);
    }

    /**
     * @notice Function for satisfying randomness requests from minting
     * @param requestId The particular request being serviced
     * @param randomWords Array of the random numbers requested
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        Request memory request = s_requests[requestId];
        (, , uint256 status, ) = IRover(erc721Token).rovers(request.tokenId);
        uint256 randomWord = randomWords[0] % 10_000;
        if (randomWord < request.m3tam0dChance) {
            m3tam0d.trustedMint(request.user, m3tam0dTokenId, 1);
            emit M3tam0dMinted(request.user, m3tam0dTokenId, 1);
        }

        // second random word for rover breakdown
        uint256 randomWord2 = randomWords[0] % 1000;
        if (randomWord2 > 500) {
            IRover(erc721Token).breakdown(request.tokenId, status + 1);
        } else if (randomWord2 == 500) {
            if (status < 2) {
                IRover(erc721Token).breakdown(request.tokenId, status + 2);
            } else {
                IRover(erc721Token).breakdown(request.tokenId, status + 1);
            }
        }
        delete s_requests[requestId];
    }

    /// @inheritdoc IMissionControlStakeable
    function isBase(uint256 _tier, int256 _x, int256 _y) external view override returns (bool) {
        return tokenInfoByRing[_tier][tileToRing[_x][_y]].isBase;
    }

    /// @inheritdoc IMissionControlStakeable
    function isRaidable(uint256 _tier, int256 _x, int256 _y) external view override returns (bool) {
        return tokenInfoByRing[_tier][tileToRing[_x][_y]].isRaidable;
    }

    function _isDroneId(uint256 _besideTokenId) internal pure returns (bool) {
        return (_besideTokenId == 5 || _besideTokenId == 4 || _besideTokenId == 33);
    }

    /// @inheritdoc IMissionControlStakeable
    function onStaked(
        address _currentOwner,
        uint256 _tokenId,
        uint256 _nonce,
        address /* _underlyingToken */,
        uint256 /* _underlyingTokenId */,
        address _besideToken,
        uint256 _besideTokenId,
        uint256 _besideNonce,
        int256 _x,
        int256 _y
    ) external override onlyMissionControl {
        require(tokenIds[_currentOwner][_nonce] == 0, "MCRover_ADAPTER: Invalid nonce");

        bool droneStaked = (_besideToken == pixAssetAdapter && _isDroneId(_besideTokenId));

        require(_besideToken == address(0) || droneStaked, "MCRover_ADAPTER: Rover can be staked only besides drone");

        if (droneStaked) {
            (, uint256 roverRank, , ) = IRover(erc721Token).rovers(_tokenId);
            if (roverRank == IPIXAssetStakeableAdapter(pixAssetAdapter).getDroneTier(_besideTokenId)) {
                IPIXAssetStakeableAdapter(pixAssetAdapter).applyBuff(_currentOwner, _besideNonce, true);
            }
        }

        seeds[_tokenId] = block.timestamp;
        tokenIds[_currentOwner][_nonce] = _tokenId;
        IERC721(erc721Token).safeTransferFrom(_currentOwner, address(this), _tokenId);
        emit TokenClaimed(_currentOwner, address(this), _tokenId);
    }

    function onResume(address _renter, uint256 _nonce) external {
        uint256 tokenId = tokenIds[_renter][_nonce];
        seeds[tokenId] = block.timestamp;
    }

    /// @inheritdoc IMissionControlStakeable
    function onUnstaked(address _newOwner, uint256 _nonce, uint256 _besideNonce) external override onlyMissionControl {
        uint256 _tokenId = tokenIds[_newOwner][_nonce];

        if (_besideNonce != 0) IPIXAssetStakeableAdapter(pixAssetAdapter).applyBuff(_newOwner, _besideNonce, false);

        IERC721(erc721Token).safeTransferFrom(address(this), _newOwner, _tokenId);
        seeds[_tokenId] = 0;
        emit TokenReturned(_newOwner, address(this), _tokenId);
    }

    function __checkTile(
        address _userAddress,
        uint256 _nonce,
        uint256 _pausedAt,
        int256 _x,
        int256 _y
    ) internal view virtual returns (uint256, uint256, uint256) {
        CheckTileInputs memory vars;
        vars.tokenId = tokenIds[_userAddress][_nonce];
        (, uint256 color, , ) = IRover(erc721Token).rovers(vars.tokenId);
        TokenInfo memory _info = tokenInfoByRing[color][tileToRing[_x][_y]];
        if (_info.resourceEV == 0) {
            return (0, _info.resourceId, 0);
        }
        vars.localSeed = seeds[vars.tokenId];
        require(vars.localSeed != 0, "MCRover_ADAPTER: No such token staked");
        (uint256 rate, uint256 m3tam0dChance) = getRoverRate(vars.tokenId, _info.resourceEV);
        vars.blockTime = _pausedAt > 0 ? _pausedAt : block.timestamp;
        vars.elapsed = vars.blockTime - vars.localSeed;

        if (vars.elapsed > maxCutoff) {
            vars.ret = rate;
        } else {
            vars.ret = (rate * vars.elapsed) / maxCutoff;
        }
        return (vars.ret, tokenInfoByRing[color][tileToRing[_x][_y]].resourceId, m3tam0dChance);
    }

    /**
     * @dev returns the amount of waste earned by the rover in a 24 hour period
     * @param tokenId the id of the rover
     * @return rate amount of waste earned by the rover in a 10 day period (max)
     * @return m3tam0dChance chance of getting a m3tam0d out of 10_000
     */
    function getRoverRate(
        uint256 tokenId,
        uint256 resourceEV
    ) public view returns (uint256 rate, uint256 m3tam0dChance) {
        (, uint256 color, uint256 status, ) = IRover(erc721Token).rovers(tokenId);
        if (color == 0) {
            m3tam0dChance = 500;
        } else if (color == 1) {
            m3tam0dChance = 50;
        } else {
            m3tam0dChance = 5;
        }
        rate = resourceEV;
        if (status == 1) {
            rate = (rate * 900) / 1000;
        } else if (status == 2) {
            rate = (rate * 600) / 1000;
        } else if (status == 3) {
            rate = 0;
        }
    }

    function getResourceParams(uint _tier, int _maxRad) external view returns (ResourceParamOut[] memory outParam) {
        uint count;
        outParam = new ResourceParamOut[](18);
        for (int256 x = -_maxRad; x <= _maxRad; x++) {
            for (int256 y = -_maxRad; y <= _maxRad; y++) {
                for (int256 z = -_maxRad; z <= _maxRad; z++) {
                    int256 sum = x + y + z;
                    uint256 rad = (abs(x) + abs(y) + abs(z)) / 2;
                    if (rad == uint(_maxRad) && rad > 0 && sum == 0) {
                        TokenInfo memory info = tokenInfoByRing[_tier][tileToRing[x][y]];
                        outParam[count].x = x;
                        outParam[count].y = y;
                        outParam[count].z = z;
                        outParam[count].isBase = info.isBase;
                        outParam[count].isRaidable = info.isRaidable;
                        outParam[count].resourceEV = info.resourceEV;
                        outParam[count].resourceId = info.resourceId;
                        outParam[count].resourceCap = info.resourceCap;
                        ++count;
                    }
                }
            }
        }
    }

    /// @inheritdoc IMissionControlStakeable
    function checkTimestamp(address _userAddress, uint256 _nonce) external view override returns (uint256 _timestamp) {
        _timestamp = seeds[tokenIds[_userAddress][_nonce]];
    }

    /// @inheritdoc IMissionControlStakeable
    function timeLeft(
        address _userAddress,
        uint256 _nonce,
        int256 /* _x */,
        int256 /* _y */
    ) external view override onlyMissionControl returns (int256) {
        uint256 tokenId = tokenIds[_userAddress][_nonce];
        uint256 localSeed = seeds[tokenId];
        require(localSeed != 0, "MCRover_ADAPTER: No such token staked");
        uint256 completionTime = localSeed + uint256(maxCutoff);
        int256 _timeLeft = int256(completionTime) - int256(block.timestamp);
        return _timeLeft > 0 ? _timeLeft : int256(0);
    }

    /**
     * @notice Verifies that a rover is staked with a particular tier
     * @param _userAddress The address of the user
     * @param _nonce The nonce of the rover
     * @param _tier The required tier of the rover
     * @return true if the rover is staked with the required tier
     */
    function roverStakedWithTier(address _userAddress, uint256 _nonce, uint256 _tier) external view returns (bool) {
        uint256 tokenId = tokenIds[_userAddress][_nonce];
        (, uint256 color, , ) = IRover(erc721Token).rovers(tokenId);
        return color == _tier;
    }

    /** ADMIN FUNCTIONS **/
    /**
     * @notice set keyHash by owner
     */
    function setKeyHash(bytes32 _keyHash) external onlyOwner {
        keyHash = _keyHash;
    }

    /**
     * @notice set callbackGasLimit by owner
     */
    function setCallbackGasLimit(uint32 _callbackGasLimit) external onlyOwner {
        callbackGasLimit = _callbackGasLimit;
    }

    /**
     * @notice set subscriptionId by owner
     */
    function setSubscriptionId(uint64 _subscriptionId) external onlyOwner {
        subscriptionId = _subscriptionId;
    }

    /**
     * @notice set requestConfirmations by owner
     */
    function setRequestConfirmations(uint16 _requestConfirmations) external onlyOwner {
        requestConfirmations = _requestConfirmations;
    }

    /**
     * @notice set maxCutoff by owner
     */
    function setMaxCutoff(uint256 _maxCutoff) external onlyOwner {
        maxCutoff = _maxCutoff;
    }

    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
    }

    /**
     * @notice Calculates the absolute value of an integer
     * @param _value The integer
     * @return Its absolute value
     */
    function abs(int256 _value) private pure returns (uint256) {
        return _value < 0 ? uint256(-_value) : uint256(_value);
    }
}