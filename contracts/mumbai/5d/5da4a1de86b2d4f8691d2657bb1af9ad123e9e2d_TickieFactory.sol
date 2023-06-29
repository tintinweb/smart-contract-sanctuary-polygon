/**
 *Submitted for verification at polygonscan.com on 2023-06-28
*/

// Sources flattened with hardhat v2.16.0 https://hardhat.org

// File contracts/interfaces/IERC721A.sol

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity 0.8.19;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721A {
  // =============================================================
  //                         TOKEN COUNTERS
  // =============================================================

  function totalMintedClassic() external view returns (uint256);

  function totalMintedInvitations() external view returns (uint256);

  function totalBurned() external view returns (uint256);

  // =============================================================
  //                            IERC721
  // =============================================================

  /**
   * @dev Returns the number of tokens in `owner`'s account.
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
   * @dev Safely transfers `tokenId` token from `from` to `to`,
   * checking first that contract recipients are aware of the ERC721 protocol
   * to prevent tokens from being forever locked.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must exist and be owned by `from`.
   * - If the caller is not `from`, it must be have been allowed to move
   * this token by either {approve} or {setApprovalForAll}.
   * - If `to` refers to a smart contract, it must implement
   * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
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
   * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
   */
  function safeTransferFrom(address from, address to, uint256 tokenId) external;

  /**
   * @dev Transfers `tokenId` from `from` to `to`.
   *
   * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
   * whenever possible.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must be owned by `from`.
   * - If the caller is not `from`, it must be approved to move this token
   * by either {approve} or {setApprovalForAll}.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address from, address to, uint256 tokenId) external;

  /**
   * @dev Gives permission to `to` to transfer `tokenId` token to another account.
   * The approval is cleared when the token is transferred.
   *
   * Only a single account can be approved at a time, so approving the
   * zero address clears previous approvals.
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
   * Operators can call {transferFrom} or {safeTransferFrom}
   * for any token owned by the caller.
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
  function getApproved(
    uint256 tokenId
  ) external view returns (address operator);

  /**
   * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
   *
   * See {setApprovalForAll}.
   */
  function isApprovedForAll(
    address owner,
    address operator
  ) external view returns (bool);

  // =============================================================
  //                        IERC721Metadata
  // =============================================================

  /**
   * @dev Returns the token collection name.
   */
  function name() external view returns (string memory);

  /**
   * @dev Returns the token collection symbol.
   */
  function symbol() external view returns (string memory);

  /**
   * @dev Returns the Uniform Resource Identifier (URI) for the collection.
   */
  function baseURI() external view returns (string memory);

  /**
   * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
   */
  function tokenURI(uint256 tokenId) external view returns (string memory);
}


// File contracts/interfaces/ITickieNFT.sol

// License-Identifier: UNLICENCED
pragma solidity 0.8.19;

// Interfaces
interface ITickieNFT is IERC721A {
  function minter() external view returns (address);

  function initialize(
    bool canTransfer_,
    bool canTransferFromContracts_,
    string memory collectionName_,
    string memory baseURI_
  ) external;
}


// File contracts/interfaces/IMinimalProxy.sol

// License-Identifier: MIT
pragma solidity 0.8.19;

interface IMinimalProxy {
  function refreshImplementation(address newImplementation) external;
}


// File contracts/lib/StorageSlot.sol

// License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 */
library StorageSlot {
  struct AddressSlot {
    address value;
  }

  /**
   * @dev Returns an `AddressSlot` with member `value` located at `slot`.
   */
  function getAddressSlot(
    bytes32 slot
  ) internal pure returns (AddressSlot storage r) {
    assembly {
      r.slot := slot
    }
  }
}


// File contracts/MinimalProxy.sol

// License-Identifier: MIT
pragma solidity 0.8.19;

// Libs
// Interfaces
contract MinimalProxy is IMinimalProxy {
  /**
   * @dev Storage slot with the address of the current implementation.
   * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
   * assigned in the constructor.
   */
  bytes32 internal constant _IMPLEMENTATION_SLOT =
    0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

  /**
   * @dev Storage slot with the admin of the contract.
   * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
   * assigned in the constructor.
   */
  bytes32 internal constant _ADMIN_SLOT =
    0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

  constructor(
    address implementation_,
    bool canTransfer_,
    bool canTransferFromContracts_,
    string memory collectionName_,
    string memory baseURI_
  ) {
    StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = implementation_;
    StorageSlot.getAddressSlot(_ADMIN_SLOT).value = msg.sender;

    // We use 'delegatecall' to avoid string calldata hassle of '_delegate'
    (bool success, ) = implementation_.delegatecall(
      abi.encodeWithSignature(
        "initialize(bool,bool,string,string)",
        canTransfer_,
        canTransferFromContracts_,
        collectionName_,
        baseURI_
      )
    );

    // We want to revert on failure to avoid the deployment of a corrupted implementation
    if (!success) revert FailedToInitialize();
  }

  //======= ERRORS =======//
  //======================//

  // Throws because the called is not an administrator
  error NotAdmin();
  // Throws because the contract failed to initialize properly
  error FailedToInitialize();

  //======= STORAGE =======//
  //=======================//

  /**
   * @dev Returns the current implementation address.
   */
  function _getImplementation() internal view returns (address) {
    return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
  }

  /**
   * @dev Returns the current admin.
   */
  function _getAdmin() internal view returns (address) {
    return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
  }

  //======= PROXY =======//
  //=====================//

  /**
   * @dev Delegates the current call to `implementation`.
   *
   * This function does not return to its internal call site, it will return directly to the external caller.
   */
  function _delegate(address implementation_) internal virtual {
    assembly {
      // Copy msg.data. We take full control of memory in this inline assembly
      // block because it will not return to Solidity code. We overwrite the
      // Solidity scratch pad at memory position 0.
      calldatacopy(0, 0, calldatasize())

      // Call the implementation.
      // out and outsize are 0 because we don't know the size yet.
      let result := delegatecall(
        gas(),
        implementation_,
        0,
        calldatasize(),
        0,
        0
      )

      // Copy the returned data.
      returndatacopy(0, 0, returndatasize())

      switch result
      // delegatecall returns 0 on error.
      case 0 {
        revert(0, returndatasize())
      }
      default {
        return(0, returndatasize())
      }
    }
  }

  /**
   * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
   * function in the contract matches the call data.
   */
  fallback() external payable virtual {
    _delegate(_getImplementation());
  }

  /**
   * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
   * is empty.
   */
  receive() external payable virtual {
    _delegate(_getImplementation());
  }

  //======= ADMIN =======//
  //=====================//

  /*
   * @dev Allows the factory to update the implementation contract of the collection.
   * It is vitaly important to extensively test for storage conflicts when updating the implementation.
   * @param newImplementation Address of the new implementation contract.
   */
  function refreshImplementation(address newImplementation) external {
    if (msg.sender != _getAdmin()) revert NotAdmin();

    StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
  }
}


// File contracts/interfaces/ITickieFactory.sol

// License-Identifier: UNLICENCED
pragma solidity 0.8.19;

interface ITickieFactory {
  function implementation() external view returns (address);
}


// File contracts/Ownable.sol

// License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 */
abstract contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
    _owner = msg.sender;
  }

  //======= ERRORS =======//
  //======================//

  error NotOwner();
  error NewOwnerIsZeroAddress();

  //======= MODIFIERS =======//
  //=========================//

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    if (msg.sender != _owner) revert NotOwner();
    _;
  }

  //======= VIEWS =======//
  //=====================//

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view virtual returns (address) {
    return _owner;
  }

  //======= ADMIN =======//
  //=====================//

  function _setOwner(address newOwner) internal {
    if (newOwner == address(0)) revert NewOwnerIsZeroAddress();
    _owner = newOwner;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public virtual onlyOwner {
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    address oldOwner = _owner;

    _setOwner(newOwner);

    emit OwnershipTransferred(oldOwner, newOwner);
  }
}


// File contracts/TickieFactory.sol

// License-Identifier: UNLICENCED
pragma solidity 0.8.19;

// Addons
// Contracts
// Interfaces
/// @title Tickie NFT collection factory
/// @notice Contract factory that deploys minimal proxies for a Tickie NFT implementation contract
contract TickieFactory is ITickieFactory, Ownable {
  //======= STORAGE =======//
  //=======================//
  // The ID of the next collection to be deployed
  uint256 public nextCollectionId;
  // Maps a collection ID to its deployment address
  mapping(uint256 collectionId => address deployedAt) public collections;
  // The address of the current Tickie NFT implementation contract
  address public implementation;
  // Single wallet authorized to deploy new collections
  address public deployer;

  //======= STRUCTS =======//
  //=======================//

  // The structure for queried collection information
  struct CollectionQuery {
    uint256 id;
    string name;
    string symbol;
    address minter;
    uint256 amountTicketsMinted;
    uint256 amountInvitationsMinted;
    uint256 amountBurned;
    address deployedAt;
    string uri;
  }

  //======= CONSTRUCTOR =======//
  //===========================//

  constructor(address implementation_) {
    implementation = implementation_;
  }

  //======= EVENTS =======//
  //======================//

  /// @dev Emitted when a new collection is created
  event CollectionCreated(
    uint256 indexed collectionId,
    address collectionAddress
  );
  /// @dev Emitted when a new implementation contract has been set
  event NewImplementation(address newImplementation);
  /// @dev Emitted when the implementation contract of a collection is refreshed
  event ImplementationRefreshed(
    uint256 indexed collectionId,
    address indexed collectionAddress,
    address indexed newImplementation
  );

  //======= ERRORS =======//
  //======================//

  /// @dev Thrown when an implementation is required
  error NoImplementationSet();
  /// @dev Thrown when querying data for a non existent collection
  error QueryForNonExistentCollection();
  /// @dev Thrown when a non authorized wallet calls a priviledged function
  error NotOwnerOrDeployer();

  //======= MODIFIERS =======//
  //=========================//

  /*
   * @dev Authenticates the caller
   */
  modifier onlyOwnerOrDeployer() {
    if (msg.sender != owner())
      if (msg.sender != deployer) revert NotOwnerOrDeployer();
    _;
  }

  /*
   * @dev Checks if an implementation contract is configured
   */
  modifier hasImplementation() {
    if (implementation == address(0)) revert NoImplementationSet();
    _;
  }

  //======= VIEWS =======//
  //=====================//

  /*
   * @dev Returns the data of a collection
   * @param collectionId The ID of the collection
   */
  function collectionData(
    uint256 collectionId
  ) public view returns (CollectionQuery memory _collectionData) {
    address deployedAt = collections[collectionId];
    if (deployedAt == address(0)) revert QueryForNonExistentCollection();

    // Create an interface to handle queries to the collection
    ITickieNFT collectionInterface = ITickieNFT(deployedAt);

    _collectionData = CollectionQuery({
      id: collectionId,
      name: collectionInterface.name(),
      symbol: collectionInterface.symbol(),
      minter: collectionInterface.minter(),
      amountTicketsMinted: collectionInterface.totalMintedClassic(),
      amountInvitationsMinted: collectionInterface.totalMintedInvitations(),
      amountBurned: collectionInterface.totalBurned(),
      deployedAt: deployedAt,
      uri: collectionInterface.baseURI()
    });
  }

  /*
   * @dev Returns the data of a all collections
   */
  function allCollectionsData()
    external
    view
    returns (CollectionQuery[] memory)
  {
    CollectionQuery[] memory _collectionsData = new CollectionQuery[](
      nextCollectionId
    );

    for (uint256 i; i < nextCollectionId; i++) {
      _collectionsData[i] = collectionData(i);
    }

    return _collectionsData;
  }

  function allCollections() external view returns (address[] memory) {
    address[] memory _collections = new address[](nextCollectionId);
    for (uint256 i; i < nextCollectionId; i++) {
      _collections[i] = collections[i];
    }
    return _collections;
  }

  //======= DEPLOY =======//
  //======================//

  /*
   * @dev Deploys a new collection
   * @param canTransfer_ Whether token transfers are allowed
   * @param canTransferFromContracts_ Whether token transfers initiated by contracts are allowed
   * @param collectionName The name of the collection
   * @param baseURI The base URI of the collection metadata
   */
  function deployCollection(
    bool canTransfer_,
    bool canTransferFromContracts_,
    string memory collectionName,
    string memory baseURI
  ) external hasImplementation onlyOwnerOrDeployer {
    MinimalProxy deployed = new MinimalProxy(
      implementation,
      canTransfer_,
      canTransferFromContracts_,
      collectionName,
      baseURI
    );

    uint256 collectionId = nextCollectionId;
    nextCollectionId++;

    collections[collectionId] = address(deployed);

    emit CollectionCreated(collectionId, address(deployed));
  }

  //======= ADMIN =======//
  //=====================//

  /*
   * @dev Changes the implementation contract use by future collections
   * @param newImplementation The address of the new implementation contract
   */
  function changeImplementation(address newImplementation) external onlyOwner {
    implementation = newImplementation;
    emit NewImplementation(newImplementation);
  }

  /*
   * @dev Refreshes the implementation contract of deployed collections
   * @param collectionIds The IDs of the collections to refresh
   */
  function refreshImplementations(
    uint256[] calldata collectionIds
  ) external hasImplementation onlyOwner {
    for (uint256 i; i < collectionIds.length; i++) {
      uint256 currentId = collectionIds[i];
      address collectionAddress = collections[currentId];

      IMinimalProxy(collectionAddress).refreshImplementation(implementation);

      emit ImplementationRefreshed(
        currentId,
        collectionAddress,
        implementation
      );
    }
  }

  /*
   * @dev Sets an authorized deployer wallet address
   * @param newDeployer The address of the new deployer
   */
  function changeDeployer(address newDeployer) external onlyOwner {
    deployer = newDeployer;
  }
}