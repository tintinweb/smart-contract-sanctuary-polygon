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

    /**
    * @notice This is a struct which contains information regarding a tile element
    * @param steakeable Address for the stakeable token on the tile
    * @param tokenId Id of the staked token
    * @param nonce Staking nonce
    * @param staked Boolean defining whether the token is actively staked, used as opposed to clearing the previous two on unstaking.
    */
    struct TileElement {
        address stakeable;
        uint tokenId;
        uint nonce;
    }

    /**
    * @notice Struct to hold instructions for tile resource collection
    * @param x X-coordinate of tile
    * @param y Y-coordinate of tile
    * @param z Z-coordinate of tile
    */
    struct CollectOrder {
        int x;
        int y;
        int z;
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
        int x;
        int y;
        int z;
        uint tokenId;
        address tokenAddress;
    }

    /**
    * @notice Stakes an NFT on a tile
    * @param _x X-coordinate of tile
    * @param _y Y-coordinate of tile
    * @param _z Z-coordinate of tile
    * @param _tokenId Token ID of NFT
    * @param _tokenAddress Address of NFT, which is presumed to implement the IMissionControlStakeable interface
    */
    function placeNFT(int _x, int _y, int _z, uint _tokenId, address _tokenAddress) external;

    /**
    * @notice Stakes multiple NFTs on various tiles in one transaction
    * @param _placeOrders Array of structs containing information regarding where to place what
    * @dev Any downside to using structs as an argument?
    */
    function placeNFTs(PlaceOrder[] calldata _placeOrders) external;


    /**
    * @notice Unstakes an NFT from a tile
    * @param _x X-coordinate of tile
    * @param _y Y-coordinate of tile
    * @param _z Z-coordinate of tile
    */
    function removeNFT(int _x, int _y, int _z) external;

    /**
    * @notice Removes multiple NFTs on various tiles in one transaction
    * @param _placeOrders Array of structs containing information regarding where to remove something
    * @dev Token id, address are ignored
    */
    function removeNFTs(PlaceOrder[] memory _placeOrders) external;

    /**
      * @notice Queries a tile regarding the resources which are able to collected from it at the current moment
    * @dev Add support for multiple types of tokens, i.e return would be an array?
    * @param _user User address
    * @param _x X-coordinate of tile
    * @param _y Y-coordinate of tile
    * @param _z Z-coordinate of tile
   * @return uint Number of tokens that can be collected
   * @return uint Token identifier for token to be collected
    */
    function checkTile(address _user, int _x, int _y, int _z) external view returns (uint, uint);

    /**
    * @notice Collects (mints) tokens from tiles
    * @dev An alternative worth considering would be to have an alternative mint function
    * @param _orders Array containing collect orders
    * @dev Any downside to using structs as an argument?
    */
    function collectFromTiles(CollectOrder[] calldata _orders,
        uint8 _v,
        bytes32 _r,
        bytes32 _s) external;


    /**
    * @notice Used to check what a user has staked on a tile
    * @param _user The user whose Mission Control we should check
    * @param _x X-coordinate of tile
    * @param _y Y-coordinate of tile
    * @param _z Z-coordinate of tile
    */
    function checkStakedOnTile(address _user, int _x, int _y, int _z) external view returns (TileElement memory _base, TileElement memory _top);

    /**
    * @notice Returns when the tile was last updated
    * @param _user The user whose Mission Control we should check
    * @param _x X-coordinate of tile
    * @param _y Y-coordinate of tile
    * @param _z Z-coordinate of tile
    * @return _timestamp The time in blockchain seconds
    */
    function checkLastUpdated(address _user, int _x, int _y, int _z) external view returns (uint _timestamp);

    /**
    * @notice Notifies the contract that a user has been raided
    * @param _defender Address of the player being raided
    * @param _timestamp The timestamp the signature was written
    * @param _raidId The raid id
    * @param _orders Collect orders denoting which tiles we should wipe the waste from
    * @param _v Sig
    * @param _r Sig
    * @param _s Sig
    */
    function notifyRaided(
        address _defender,
        uint256 _timestamp,
        uint256 _raidId,
        CollectOrder[] calldata _orders,
        uint8 _v,
        bytes32 _r,
        bytes32 _s) external;

    /**
    * @notice returns the remaining time until a tile is filled
    * @param _user The user whose Mission Control we should check
    * @param _x X-coordinate of tile
    * @param _y Y-coordinate of tile
    * @param _z Z-coordinate of tile
    * @return _timeLeft The time left, -1 if the time can not be predicted
    */
    function timeLeft(address _user, int _x, int _y, int _z) external view returns (int _timeLeft);


}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


/// @title Interface defining a contract which can be staked upon a "tile" in the mission control
interface IMissionControlStakeable {

    /**
    * @notice Event emitted when a token is staked
    * @param _userAddress address of the staker
    * @param _stakeable Address to either the IMCStakeable implementation or the possibly the underlying token?
    * @param _tokenId Token id which has been staked
    */
    event TokenClaimed(address _userAddress, address _stakeable, uint _tokenId);
    /**
    * @notice Event emitted when a token is unstaked
    * @param _userAddress address of the staker
    * @param _stakeable Address to either the IMCStakeable implementation or the possibly the underlying token?
    * @param _tokenId Token id which has been unstaked
    */
    event TokenReturned(address _userAddress, address _stakeable, uint _tokenId);

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
    function reset(address _userAddress, uint _nonce) external;

    /**
    * @notice Function to check the number of tokens ready to be harvested from this tile
    * @param _userAddress The players address
    * @param _nonce Tile-staking nonce
    * @return _amount Number of tokens that can be collected
    * @return _retTokenId The tokenId of the tokens that can be collected
    */
    function checkTile(address _userAddress, uint _nonce) external view returns (uint _amount, uint _retTokenId);

    /**
    * @notice Used to fetch new seed time upon collection some resources
    * @param _userAddress The players address
    * @param _nonce Tile-staking nonce
    * @return _amount Number of tokens that can be collected
    * @return _retTokenId The tokenId of the tokens that can be collected
    * @dev It is vital for this function to update the rng
    */
    function onCollect(address _userAddress, uint _nonce) external returns (uint _amount, uint _retTokenId);

    /**
    * @notice Used to see if the token can be used as the base of a tile, or if it is meant to be staked upon another token
    * @param _tokenId The id of the token
    * @return _isBase Whether this token is a base or not
    */
    function isBase(uint _tokenId) view external returns (bool _isBase);

    function isRaidable(uint _tokenId) view external returns (bool _isRaidable);

    /**
    * @notice transfers ownership of a token from the player to the stakeable contract
    * @param _currentOwner Address of the current owner
    * @param _tokenId The id of the token
    * @param _nonce Tile-staking nonce
    * @param _underlyingToken todo
    * @param _underlyingTokenId todo
    */
    function onStaked(address _currentOwner, uint _tokenId, uint _nonce, address _underlyingToken, uint _underlyingTokenId) external;


    /**
    * @notice transfers ownership of a token from the stakeable contract back to the player
    * @param _newOwner Address of the soon-to-be owner
    * @param _nonce Tile-staking nonce
    */
    function onUnstaked(address _newOwner, uint _nonce) external;

    function checkTimestamp(address _userAddress, uint _nonce) external view returns (uint _timestamp);

    /**
    * @notice returns the remaining time until a tile is filled
    * @param _userAddress The players address
    * @param _nonce Tile-staking nonce
    * @param _tokenId id of the token. Not used for now
    * @return _timeLeft The time left, -1 if the time can not be predicted
    */
    function timeLeft(address _userAddress, uint _nonce, uint _tokenId) external view returns(int _timeLeft);

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

error Rover__NotOracle();

/// @title Interface for the Rover ERC721 contract
interface IRover {
    function rovers(uint256 tokenId)
        external
        view
        returns (
            string memory,
            uint256,
            uint256,
            uint256
        );
}

interface IM3tam0d {
    function trustedMint(
        address _to,
        uint256 _tokenId,
        uint256 _amount
    ) external;
}

/**
 * @title Implementation of IMissionControlStakeable to handle ERC721 tokens
 */
contract RoverMCStakeableAdapter is IMissionControlStakeable, OwnableUpgradeable, ERC721HolderUpgradeable, VRFConsumerBaseV2Upgradable {
    event ParametersUpdated(address _stakeable, uint256 _id, uint256 _ev, bool _isBase);

    mapping(uint256 => uint256) seeds;
    mapping(address => mapping(uint256 => uint256)) tokenIds;
    uint256 public resourceId;
    int256 public maxCutoff;
    address missionControl;
    address erc721Token;

    VRFCoordinatorV2Interface public COORDINATOR;
    IM3tam0d m3tam0d;
    uint256 m3tam0dTokenId;

    bytes32 keyHash;
    uint32 callbackGasLimit;
    uint16 requestConfirmations;
    uint64 subscriptionId;

    bool isBaseVal;

    struct Request {
        address user;
        uint256 m3tam0dChance;
    }
    mapping(uint256 => Request) public s_requests;

    /**
     * @notice Initializer for this contract
     * @param _resourceId Identifier for the token that this wrapper generates
     */
    function initialize(
        uint256 _resourceId,
        bool _isBase,
        address _vrfCoordinator,
        address _m3tam0d,
        uint256 _m3tam0dTokenId,
        bytes32 _keyHash,
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations,
        uint64 _subscriptionId
    ) external initializer {
        resourceId = _resourceId;
        isBaseVal = _isBase;

        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        __VRFConsumerBaseV2_init(_vrfCoordinator);

        keyHash = _keyHash;
        callbackGasLimit = _callbackGasLimit;
        requestConfirmations = _requestConfirmations;
        subscriptionId = _subscriptionId;

        m3tam0d = IM3tam0d(_m3tam0d);
        m3tam0dTokenId = _m3tam0dTokenId;
        __update_cutoff();
        __Ownable_init();
    }

    function __update_cutoff() private {
        maxCutoff = 10 days;
    }

    /*
    IMissionControlStakeable implementation
    */

    modifier onlyMissionControl() {
        require(msg.sender == missionControl, "MCRover_ADAPTER: Sender not mission control");
        _;
    }

    function setResourceParameters(uint256 _resourceId, bool _isBase) external onlyOwner {
        resourceId = _resourceId;
        isBaseVal = _isBase;
        __update_cutoff();
        emit ParametersUpdated(address(this), resourceId, 0, isBaseVal);
    }

    function setMissionControl(address _missionControl) external onlyOwner {
        missionControl = _missionControl;
        emit MissionControlSet(_missionControl);
    }

    function setERC721(address _erc721) external onlyOwner {
        require(erc721Token == address(0), "MCRover_ADAPTER: ERC721 already set");
        erc721Token = _erc721;
    }

    /// @inheritdoc IMissionControlStakeable
    function reset(address _userAddress, uint256 _nonce) external override onlyMissionControl {
        require(seeds[tokenIds[_userAddress][_nonce]] > 0, "MCRover_ADAPTER: No such token staked");
        seeds[tokenIds[_userAddress][_nonce]] = block.timestamp;
    }

    /// @inheritdoc IMissionControlStakeable
    function checkTile(address _userAddress, uint256 _nonce) external view override onlyMissionControl returns (uint256, uint256) {
        (uint256 amount, uint256 id, ) = __checkTile(tokenIds[_userAddress][_nonce]);
        return (amount, id);
    }

    /// @inheritdoc IMissionControlStakeable
    function onCollect(address _userAddress, uint256 _nonce) external override onlyMissionControl returns (uint256, uint256) {
        uint256 tokenId = tokenIds[_userAddress][_nonce];
        (uint256 amount, uint256 id, uint256 m3tam0dChance) = __checkTile(tokenId);
        seeds[tokenId] = block.timestamp;

        // vrf request random word for m3tam0dChance
        require(keyHash != bytes32(0), "Must have valid key hash");
        uint256 requestId = COORDINATOR.requestRandomWords(keyHash, subscriptionId, requestConfirmations, callbackGasLimit, 1);
        s_requests[requestId] = Request({user: _userAddress, m3tam0dChance: m3tam0dChance});
        return (amount, id);
    }

    /**
     * @notice Function for satisfying randomness requests from minting
     * @param requestId The particular request being serviced
     * @param randomWords Array of the random numbers requested
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        Request memory request = s_requests[requestId];
        uint256 randomWord = randomWords[0] % 10_000;
        if (randomWord < request.m3tam0dChance) {
            m3tam0d.trustedMint(request.user, m3tam0dTokenId, 1);
        }
        delete s_requests[requestId];
    }

    /// @inheritdoc IMissionControlStakeable
    function isBase(uint256 _tokenId) external view override returns (bool) {
        return isBaseVal;
    }

    /// @inheritdoc IMissionControlStakeable
    function isRaidable(uint256 _tokenId) external view override returns (bool _isRaidable) {
        _isRaidable = true;
    }

    /// @inheritdoc IMissionControlStakeable
    function onStaked(
        address _currentOwner,
        uint256 _tokenId,
        uint256 _nonce,
        address _underlyingToken,
        uint256 _underlyingTokenId
    ) external override onlyMissionControl {
        require(tokenIds[_currentOwner][_nonce] == 0, "MCRover_ADAPTER: Invalid nonce");
        IERC721(erc721Token).safeTransferFrom(_currentOwner, address(this), _tokenId);
        seeds[_tokenId] = block.timestamp;
        tokenIds[_currentOwner][_nonce] = _tokenId;
        emit TokenClaimed(_currentOwner, address(this), _tokenId);
    }

    /// @inheritdoc IMissionControlStakeable
    function onUnstaked(address _newOwner, uint256 _nonce) external override onlyMissionControl {
        uint256 _tokenId = tokenIds[_newOwner][_nonce];
        IERC721(erc721Token).safeTransferFrom(address(this), _newOwner, _tokenId);
        seeds[_tokenId] = 0;
        emit TokenReturned(_newOwner, address(this), _tokenId);
    }

    function __checkTile(uint256 tokenId)
        internal
        view
        virtual
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 localSeed = seeds[tokenId];
        (uint256 rate, uint256 m3tam0dChance) = getRoverRate(tokenId);
        require(localSeed != 0, "MCRover_ADAPTER: No such token staked");
        uint256 ret = (rate * (block.timestamp - localSeed)) / 1 days;
        uint256 resourceCap = 10 * rate;
        if (ret > resourceCap) {
            ret = resourceCap;
        }
        return (ret, resourceId, m3tam0dChance);
    }

    /**
     * @dev returns the amount of waste earned by the rover in a 24 hour period
     * @param tokenId the id of the rover
     * @return rate amount of waste earned by the rover in a 24 hour period
     * @return m3tam0dChance chance of getting a m3tam0d out of 10_000
     */
    function getRoverRate(uint256 tokenId) public view returns (uint256 rate, uint256 m3tam0dChance) {
        (, uint256 color, uint256 status, ) = IRover(erc721Token).rovers(tokenId);
        if (color == 0) {
            rate = 30e18;
            m3tam0dChance = 500;
        } else if (color == 1) {
            rate = 20e18;
            m3tam0dChance = 50;
        } else {
            rate = 16e18;
            m3tam0dChance = 5;
        }
        if (status == 1) {
            rate = (rate * 90) / 100;
        } else if (status == 2) {
            rate = (rate * 60) / 100;
        } else if (status == 3) {
            rate = 0;
        }
    }

    /// @inheritdoc IMissionControlStakeable
    function checkTimestamp(address _userAddress, uint256 _nonce) external view override onlyMissionControl returns (uint256 _timestamp) {
        _timestamp = seeds[tokenIds[_userAddress][_nonce]];
    }

    /// @inheritdoc IMissionControlStakeable
    function timeLeft(
        address _userAddress,
        uint256 _nonce,
        uint256 _tokenId
    ) external view override onlyMissionControl returns (int256) {
        uint256 localSeed = seeds[_tokenId];
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
    function roverStakedWithTier(
        address _userAddress,
        uint256 _nonce,
        uint256 _tier
    ) external view returns (bool) {
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
}