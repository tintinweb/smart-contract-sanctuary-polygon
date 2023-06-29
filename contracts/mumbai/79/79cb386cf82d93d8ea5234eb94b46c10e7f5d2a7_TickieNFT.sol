/**
 *Submitted for verification at polygonscan.com on 2023-06-28
*/

// Sources flattened with hardhat v2.16.0 https://hardhat.org

// File contracts/interfaces/IERC2612Permit.sol

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @dev Interface of the ERC2612 standard as defined in the EIP.
 *
 * Adds the {permit} method, which can be used to change one's
 * {IERC20-allowance} without having to send a transaction, by signing a
 * message. This allows users to spend tokens without having to hold Ether.
 *
 * See https://eips.ethereum.org/EIPS/eip-2612.
 */
interface IERC2612Permit {
  /**
   * @dev Returns the current ERC2612 nonce for `owner`. This value must be
   * included whenever a signature is generated for {permit}.
   *
   * Every successful call to {permit} increases ``owner``'s nonce by one. This
   * prevents a signature from being used multiple times.
   */
  function nonces(address owner) external view returns (uint256);
}


// File contracts/ERC2612Permit.sol

// License-Identifier: MIT
pragma solidity 0.8.19;

// Interfaces
/**
 * @dev Extension of {ERC721} that allows token holders to use their tokens
 * without sending any transactions by setting {IERC721-allowance} with a
 * signature using the {permit} method, and then spend them via
 * {IERC721-transferFrom}.
 *
 * The {permit} signature mechanism conforms to the {IERC2612Permit} interface.
 */
abstract contract ERC2612Permit is IERC2612Permit {
  mapping(address _account => uint256 _nonce) private _nonces;

  // Mapping of ChainID to domain separators. This is a very gas efficient way
  // to not recalculate the domain separator on every call, while still
  // automatically detecting ChainID changes.
  mapping(uint256 => bytes32) public domainSeparators;
  string private _tokenName;

  function _initializeERC721Permit(string memory tokenName_) internal {
    _tokenName = tokenName_;
    _updateDomainSeparator();
  }

  error ERC2612InvalidValueS();
  error ERC2612InvalidValueV();
  error ERC2612InvalidSignature();
  error ERC2612ExpiredPermitDeadline();

  /**
   * @dev Sets `amount` as the allowance of `spender` over `owner`'s tokens,
   * given `owner`'s signed approval.
   *
   * IMPORTANT: The same issues {IERC20-approve} has related to transaction
   * ordering also apply here.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `owner` cannot be the zero address.
   * - `spender` cannot be the zero address.
   * - `deadline` must be a timestamp in the future.
   * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
   * over the EIP712-formatted function arguments.
   * - the signature must use ``owner``'s current nonce (see {nonces}).
   *
   * For more information on the signature format, see the
   * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
   * section].
   */
  function _isValidPermit(
    address owner,
    address spender,
    uint256 tokenId,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) internal returns (bool) {
    if (deadline < block.timestamp) revert ERC2612ExpiredPermitDeadline();

    // Assembly for more efficiently computing:
    // bytes32 hashStruct = keccak256(
    //     abi.encode(
    //         _PERMIT_TYPEHASH,
    //         owner,
    //         spender,
    //         tokenId,
    //         _nonces[owner],
    //         deadline
    //     )
    // );

    bytes32 hashStruct;
    uint256 nonce = _nonces[owner];

    assembly {
      // Load free memory pointer
      let memPtr := mload(64)

      // keccak256("Permit(address owner,address spender,uint256 tokenId,uint256 nonce,uint256 deadline)")
      mstore(
        memPtr,
        0x48d39b37a35214940203bbbd4f383519797769b13d936f387d89430afef27688
      )
      mstore(add(memPtr, 32), owner)
      mstore(add(memPtr, 64), spender)
      mstore(add(memPtr, 96), tokenId)
      mstore(add(memPtr, 128), nonce)
      mstore(add(memPtr, 160), deadline)

      hashStruct := keccak256(memPtr, 192)
    }

    bytes32 eip712DomainHash = _domainSeparator();

    // Assembly for more efficient computing:
    // bytes32 hash = keccak256(
    //     abi.encodePacked(uint16(0x1901), eip712DomainHash, hashStruct)
    // );

    bytes32 hash;

    assembly {
      // Load free memory pointer
      let memPtr := mload(64)

      mstore(
        memPtr,
        0x1901000000000000000000000000000000000000000000000000000000000000
      ) // EIP191 header
      mstore(add(memPtr, 2), eip712DomainHash) // EIP712 domain hash
      mstore(add(memPtr, 34), hashStruct) // Hash of struct

      hash := keccak256(memPtr, 66)
    }

    address signer = _recover(hash, v, r, s);

    _nonces[owner]++;

    return signer == owner;
  }

  /**
   * @dev See {IERC2612Permit-nonces}.
   */
  function nonces(address owner) public view override returns (uint256) {
    return _nonces[owner];
  }

  function _updateDomainSeparator() private returns (bytes32) {
    uint256 chainID = getChainId();

    // no need for assembly, running very rarely
    bytes32 newDomainSeparator = keccak256(
      abi.encode(
        keccak256(
          "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        ),
        keccak256(bytes(_tokenName)), // Token ticker
        keccak256(bytes("1")), // Version
        chainID,
        address(this)
      )
    );

    domainSeparators[chainID] = newDomainSeparator;

    return newDomainSeparator;
  }

  // Returns the domain separator, updating it if chainID changes
  function _domainSeparator() private returns (bytes32) {
    bytes32 domainSeparator = domainSeparators[getChainId()];

    if (domainSeparator != 0x00) {
      return domainSeparator;
    }

    return _updateDomainSeparator();
  }

  function getChainId() public view returns (uint256 chainID) {
    assembly {
      chainID := chainid()
    }
  }

  function _recover(
    bytes32 hash,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) internal pure returns (address) {
    // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
    // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
    // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
    // signatures from current libraries generate a unique signature with an s-value in the lower half order.
    //
    // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
    // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
    // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
    // these malleable signatures as well.
    if (
      uint256(s) >
      0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
    ) {
      revert ERC2612InvalidValueS();
    }

    if (v != 27 && v != 28) {
      revert ERC2612InvalidValueV();
    }

    // If the signature is valid (and not malleable), return the signer address
    address signer = ecrecover(hash, v, r, s);
    if (signer == address(0)) revert ERC2612InvalidSignature();

    return signer;
  }
}


// File contracts/interfaces/IERC721A.sol

// License-Identifier: MIT
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


// File contracts/interfaces/IERC721Receiver.sol

// License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @dev Interface of ERC721 token receiver.
 */
interface IERC721Receiver {
  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external returns (bytes4);
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


// File contracts/ERC721A.sol

// License-Identifier: MIT
pragma solidity 0.8.19;

// Addons
// Interfaces
/**
 * @title ERC721A
 *
 * @dev Implementation of the [ERC721](https://eips.ethereum.org/EIPS/eip-721)
 * Non-Fungible Token Standard, including the Metadata extension.
 * Optimized for lower gas during batch mints.
 *
 * Token IDs are minted in sequential order (e.g. 0, 1, 2, 3, ...)
 *
 * Assumptions:
 *
 * - An owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 * - The maximum token ID cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is IERC721A, Ownable {
  // =============================================================
  //                           CONSTANTS
  // =============================================================

  // The bit position of `startTimestamp` in packed ownership.
  uint256 private constant _BITPOS_START_TIMESTAMP = 160;

  // The bit mask of the `burned` bit in packed ownership.
  uint256 private constant _BITMASK_BURNED = 1 << 224;

  // The bit position of the `nextInitialized` bit in packed ownership.
  uint256 private constant _BITPOS_NEXT_INITIALIZED = 225;

  // The bit mask of the `nextInitialized` bit in packed ownership.
  uint256 private constant _BITMASK_NEXT_INITIALIZED = 1 << 225;

  // The bit position of `extraData` in packed ownership.
  uint256 private constant _BITPOS_EXTRA_DATA = 232;

  // The mask of the lower 160 bits for addresses.
  uint256 private constant _BITMASK_ADDRESS = (1 << 160) - 1;

  // The `Transfer` event signature is given by:
  // `keccak256(bytes("Transfer(address,address,uint256)"))`.
  bytes32 private constant _TRANSFER_EVENT_SIGNATURE =
    0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

  uint256 internal constant _INVITATION_START_INDEX = 1_000_000;

  // =============================================================
  //                            STORAGE
  // =============================================================

  // The total amount of tokens minted in the contract and next token ID to be minted.
  uint256 public totalMintedClassic;

  // The total amount of tokens minted in the contract and next token ID to be minted.
  uint256 public totalMintedInvitations;

  // The number of tokens burned.
  uint256 public totalBurned;

  // Token name
  string public name;

  // Token symbol
  string public symbol;

  // Token URL path or base
  /// @dev Private since the URI can be a path with base in the factory
  string internal _baseURI;

  // Mapping from token ID to ownership details
  // An empty struct value does not necessarily mean the token is unowned.
  // See {_packedOwnershipOf} implementation for details.
  //
  // Bits Layout:
  // - [0..159]   `addr`
  // - [160..223] `startTimestamp`
  // - [224]      `burned`
  // - [225]      `nextInitialized`
  // - [232..255] `extraData`
  mapping(uint256 => uint256) private _packedOwnerships;

  // Mapping owner address to balance.
  mapping(address => uint256) private _balances;

  // Mapping from token ID to approved address.
  mapping(uint256 => address) private _tokenApprovals;

  // Mapping from owner to operator approvals
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  // =============================================================
  //                         INITIALIZATION
  // =============================================================

  function _initializeERC721A(
    string memory name_,
    string memory baseURI_
  ) internal {
    name = name_;
    symbol = "TICKIE NFT";
    _baseURI = baseURI_;
  }

  // =============================================================
  //                            ERRORS
  // =============================================================

  /// @dev The caller must own the token or be an approved operator.
  error ApprovalCallerNotOwnerNorApproved();
  /// @dev The token does not exist.
  error ApprovalQueryForNonexistentToken();
  /// @dev Cannot mint to the zero address.
  error MintToZeroAddress();
  /// @dev The quantity of tokens minted must be more than zero.
  error MintZeroQuantity();
  /// @dev The token does not exist.
  error OwnerQueryForNonexistentToken();
  /// @dev The caller must own the token or be an approved operator.
  error TransferCallerNotOwnerNorApproved();
  /// @dev The token must be owned by `from`.
  error TransferFromIncorrectOwner();
  /// @dev Cannot safely transfer to a contract that does not implement the  ERC721Receiver interface.
  error TransferToNonERC721ReceiverImplementer();
  /// @dev ERC721 Receiver returned an invalid response.
  error ReceiverRevert();
  /// @dev Cannot transfer to the zero address.
  error TransferToZeroAddress();
  /// @dev The token does not exist.
  error URIQueryForNonexistentToken();

  // =============================================================
  //                            EVENTS
  // =============================================================

  /**
   * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
   */
  event Transfer(
    address indexed from,
    address indexed to,
    uint256 indexed tokenId
  );

  /**
   * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
   */
  event Approval(
    address indexed owner,
    address indexed approved,
    uint256 indexed tokenId
  );

  /**
   * @dev Emitted when `owner` enables or disables
   * (`approved`) `operator` to manage all of its assets.
   */
  event ApprovalForAll(
    address indexed owner,
    address indexed operator,
    bool approved
  );

  // =============================================================
  //                   TOKEN COUNTING OPERATIONS
  // =============================================================

  function totalMinted() public view returns (uint256) {
    // Counter overflow is near impossible
    unchecked {
      return totalMintedClassic + totalMintedInvitations;
    }
  }

  function getStartIndex() public view returns (uint256) {
    return totalMintedClassic;
  }

  function getStartIndexInvitations() public view returns (uint256) {
    return totalMintedInvitations + _INVITATION_START_INDEX;
  }

  // =============================================================
  //                    ADDRESS DATA OPERATIONS
  // =============================================================

  /**
   * @dev Returns the number of tokens in `owner`'s account.
   */
  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

  // =============================================================
  //                            IERC165
  // =============================================================

  /**
   * @dev Returns true if this contract implements the interface defined by
   * `interfaceId`. See the corresponding
   * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
   * to learn more about how these ids are created.
   *
   * This function call must use less than 30000 gas.
   */
  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual returns (bool) {
    // The interface IDs are constants representing the first 4 bytes
    // of the XOR of all function selectors in the interface.
    // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
    // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
    return
      interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
      interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
      interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
  }

  // =============================================================
  //                        IERC721Metadata
  // =============================================================

  /**
   * @dev Sets the Uniform Resource Identifier (URI) for the collection.
   */
  function _setBaseURI(string memory baseURI_) internal virtual {
    _baseURI = baseURI_;
  }

  /**
   * @dev Returns the base Uniform Resource Identifier (URI) for the collection.
   */
  function baseURI() external view returns (string memory) {
    return _baseURI;
  }

  /**
   * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
   * Base URI is kept in factory to avoid multiple collection updates
   */
  function tokenURI(
    uint256 tokenId
  ) public view virtual returns (string memory) {
    if (!exists(tokenId)) revert URIQueryForNonexistentToken();

    return string(abi.encodePacked(_baseURI, _toString(tokenId)));
  }

  // =============================================================
  //                     OWNERSHIPS OPERATIONS
  // =============================================================

  /**
   * @dev Returns the owner of the `tokenId` token.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function ownerOf(uint256 tokenId) public view returns (address) {
    return address(uint160(_packedOwnershipOf(tokenId)));
  }

  /**
   * Returns the packed ownership data of `tokenId`.
   */
  function _packedOwnershipOf(uint256 tokenId) private view returns (uint256) {
    uint256 curr = tokenId;

    unchecked {
      if (curr < totalMinted()) {
        uint256 packed = _packedOwnerships[curr];
        // If not burned.
        if (packed & _BITMASK_BURNED == 0) {
          // Invariant:
          // There will always be an initialized ownership slot
          // (i.e. `ownership.addr != address(0) && ownership.burned == false`)
          // before an unintialized ownership slot
          // (i.e. `ownership.addr == address(0) && ownership.burned == false`)
          // Hence, `curr` will not underflow.
          //
          // We can directly compare the packed value.
          // If the address is zero, packed will be zero.
          while (packed == 0) {
            packed = _packedOwnerships[--curr];
          }
          return packed;
        }
      }
    }
    revert OwnerQueryForNonexistentToken();
  }

  /**
   * @dev Packs ownership data into a single uint256.
   */
  function _packOwnershipData(
    address owner,
    uint256 flags
  ) private view returns (uint256 result) {
    assembly {
      // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
      owner := and(owner, _BITMASK_ADDRESS)
      // `owner | (block.timestamp << _BITPOS_START_TIMESTAMP) | flags`.
      result := or(owner, or(shl(_BITPOS_START_TIMESTAMP, timestamp()), flags))
    }
  }

  /**
   * @dev Returns the `nextInitialized` flag set if `quantity` equals 1.
   */
  function _nextInitializedFlag(
    uint256 quantity
  ) private pure returns (uint256 result) {
    // For branchless setting of the `nextInitialized` flag.
    assembly {
      // `(quantity == 1) << _BITPOS_NEXT_INITIALIZED`.
      result := shl(_BITPOS_NEXT_INITIALIZED, eq(quantity, 1))
    }
  }

  // =============================================================
  //                      APPROVAL OPERATIONS
  // =============================================================

  function _approve(address to, uint256 tokenId) internal {
    _tokenApprovals[tokenId] = to;
    emit Approval(ownerOf(tokenId), to, tokenId);
  }

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
  function approve(address to, uint256 tokenId) external {
    address owner = ownerOf(tokenId);

    if (msg.sender != owner)
      if (!isApprovedForAll(owner, msg.sender))
        revert ApprovalCallerNotOwnerNorApproved();

    _approve(to, tokenId);
  }

  /**
   * @dev Returns the account approved for `tokenId` token.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function getApproved(uint256 tokenId) external view returns (address) {
    if (!exists(tokenId)) revert ApprovalQueryForNonexistentToken();

    return _tokenApprovals[tokenId];
  }

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
  function setApprovalForAll(address operator, bool approved) external {
    _operatorApprovals[msg.sender][operator] = approved;
    emit ApprovalForAll(msg.sender, operator, approved);
  }

  /**
   * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
   *
   * See {setApprovalForAll}.
   */
  function isApprovedForAll(
    address owner,
    address operator
  ) public view returns (bool) {
    return _operatorApprovals[owner][operator];
  }

  /**
   * @dev Returns whether `tokenId` exists.
   *
   * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
   *
   * Tokens start existing when they are minted. See {_mint}.
   */
  function exists(uint256 tokenId) public view returns (bool) {
    return
      tokenId < totalMinted() && // If within bounds,
      _packedOwnerships[tokenId] & _BITMASK_BURNED == 0; // and not burned.
  }

  /**
   * @dev Returns whether `msgSender` is equal to `approvedAddress` or `owner`.
   */
  function _isSenderApprovedOrOwner(
    address approvedAddress,
    address owner,
    address msgSender
  ) private pure returns (bool result) {
    assembly {
      // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
      owner := and(owner, _BITMASK_ADDRESS)
      // Mask `msgSender` to the lower 160 bits, in case the upper bits somehow aren't clean.
      msgSender := and(msgSender, _BITMASK_ADDRESS)
      // `msgSender == owner || msgSender == approvedAddress`.
      result := or(eq(msgSender, owner), eq(msgSender, approvedAddress))
    }
  }

  // =============================================================
  //                      TRANSFER OPERATIONS
  // =============================================================

  function _transferFrom(address from, address to, uint256 tokenId) internal {
    uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

    if (address(uint160(prevOwnershipPacked)) != from)
      revert TransferFromIncorrectOwner();

    // Clear approvals from the previous owner.
    delete _tokenApprovals[tokenId];

    _beforeTokenTransfer(from, to, tokenId);

    // Underflow of the sender's balance is impossible because we check for
    // ownership above and the recipient's balance can't realistically overflow.
    // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
    unchecked {
      // We can directly increment and decrement the balances.
      --_balances[from];
      ++_balances[to];

      // Updates:
      // - `address` to the next owner.
      // - `startTimestamp` to the timestamp of transfering.
      // - `burned` to `false`.
      // - `nextInitialized` to `true`.
      _packedOwnerships[tokenId] = _packOwnershipData(
        to,
        _BITMASK_NEXT_INITIALIZED |
          _nextExtraData(from, to, prevOwnershipPacked)
      );

      // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
      if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
        uint256 nextTokenId = tokenId + 1;
        // If the next slot's address is zero and not burned (i.e. packed value is zero).
        if (_packedOwnerships[nextTokenId] == 0) {
          // If the next slot is within bounds.
          if (nextTokenId != totalMinted()) {
            // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
            _packedOwnerships[nextTokenId] = prevOwnershipPacked;
          }
        }
      }
    }

    emit Transfer(from, to, tokenId);
  }

  /**
   * @dev Transfers `tokenId` from `from` to `to`.
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
  function transferFrom(address from, address to, uint256 tokenId) public {
    address approvedAddress = _tokenApprovals[tokenId];

    // The nested ifs save around 20+ gas over a compound boolean condition.
    if (!_isSenderApprovedOrOwner(approvedAddress, from, msg.sender))
      if (!isApprovedForAll(from, msg.sender))
        revert TransferCallerNotOwnerNorApproved();

    if (to == address(0)) revert TransferToZeroAddress();

    _transferFrom(from, to, tokenId);
  }

  /**
   * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external {
    safeTransferFrom(from, to, tokenId, "");
  }

  /**
   * @dev Safely transfers `tokenId` token from `from` to `to`.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must exist and be owned by `from`.
   * - If the caller is not `from`, it must be approved to move this token
   * by either {approve} or {setApprovalForAll}.
   * - If `to` refers to a smart contract, it must implement
   * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) public {
    transferFrom(from, to, tokenId);
    if (to.code.length != 0)
      if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
        revert TransferToNonERC721ReceiverImplementer();
      }
  }

  /**
   * @dev Hook that is called before a set of serially-ordered token IDs
   * are about to be transferred. This includes minting.
   * And also called before burning one token.
   *
   * `startTokenId` - the first token ID to be transferred.
   * `quantity` - the amount to be transferred.
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
   * transferred to `to`.
   * - When `from` is zero, `tokenId` will be minted for `to`.
   * - When `to` is zero, `tokenId` will be burned by `from`.
   * - `from` and `to` are never both zero.
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 startTokenId
  ) internal virtual {}

  function _beforeMintTokenTransfer(
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual {}

  /**
   * @dev Private function to invoke {IERC721Receiver-onERC721Received} on a target contract.
   *
   * `from` - Previous owner of the given token ID.
   * `to` - Target address that will receive the token.
   * `tokenId` - Token ID to be transferred.
   * `_data` - Optional data to send along with the call.
   *
   * Returns whether the call correctly returned the expected magic value.
   */
  function _checkContractOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) private returns (bool) {
    try
      IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data)
    returns (bytes4 retval) {
      return retval == IERC721Receiver(to).onERC721Received.selector;
    } catch (bytes memory reason) {
      if (reason.length == 0) {
        revert TransferToNonERC721ReceiverImplementer();
      } else {
        revert ReceiverRevert();
      }
    }
  }

  // =============================================================
  //                        MINT OPERATIONS
  // =============================================================

  /**
   * @dev Mints `quantity` tokens and transfers them to `to`.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - `quantity` must be greater than 0.
   *
   * Emits a {Transfer} event for each mint.
   */
  function _mint(address to, uint256 startTokenId, uint256 quantity) internal {
    if (quantity == 0) revert MintZeroQuantity();

    _beforeMintTokenTransfer(to, startTokenId, quantity);

    // Overflows are incredibly unrealistic.
    // `balance` and `numberMinted` have a maximum limit of 2**64.
    // `tokenId` has a maximum limit of 2**256.
    unchecked {
      // We can directly add to the `balance`.
      _balances[to] += quantity;

      // Updates:
      // - `address` to the owner.
      // - `startTimestamp` to the timestamp of minting.
      // - `burned` to `false`.
      // - `nextInitialized` to `quantity == 1`.
      _packedOwnerships[startTokenId] = _packOwnershipData(
        to,
        _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
      );

      uint256 toMasked;
      uint256 end = startTokenId + quantity;

      // Use assembly to loop and emit the `Transfer` event for gas savings.
      // The duplicated `log4` removes an extra check and reduces stack juggling.
      // The assembly, together with the surrounding Solidity code, have been
      // delicately arranged to nudge the compiler into producing optimized opcodes.
      assembly {
        // Mask `to` to the lower 160 bits, in case the upper bits somehow aren't clean.
        toMasked := and(to, _BITMASK_ADDRESS)
        // Emit the `Transfer` event.
        log4(
          0, // Start of data (0, since no data).
          0, // End of data (0, since no data).
          _TRANSFER_EVENT_SIGNATURE, // Signature.
          0, // `address(0)`.
          toMasked, // `to`.
          startTokenId // `tokenId`.
        )

        // The `iszero(eq(,))` check ensures that large values of `quantity`
        // that overflows uint256 will make the loop run out of gas.
        // The compiler will optimize the `iszero` away for performance.
        for {
          let tokenId := add(startTokenId, 1)
        } iszero(eq(tokenId, end)) {
          tokenId := add(tokenId, 1)
        } {
          // Emit the `Transfer` event. Similar to above.
          log4(0, 0, _TRANSFER_EVENT_SIGNATURE, 0, toMasked, tokenId)
        }
      }
      if (toMasked == 0) revert MintToZeroAddress();

      if (_INVITATION_START_INDEX <= startTokenId) {
        totalMintedInvitations += quantity;
      } else {
        totalMintedClassic += quantity;
      }
    }
  }

  // =============================================================
  //                        BURN OPERATIONS
  // =============================================================

  /**
   * @dev Equivalent to `_burn(tokenId, true)`.
   */
  function burn(uint256 tokenId) external {
    _burn(tokenId, true);
  }

  /**
   * @dev Destroys `tokenId`.
   * The approval is cleared when the token is burned.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   *
   * Emits a {Transfer} event.
   */
  function _burn(uint256 tokenId, bool approvalCheck) internal {
    uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

    address from = address(uint160(prevOwnershipPacked));

    address approvedAddress = _tokenApprovals[tokenId];

    if (approvalCheck) {
      // The nested ifs save around 20+ gas over a compound boolean condition.
      if (!_isSenderApprovedOrOwner(approvedAddress, from, msg.sender))
        if (!isApprovedForAll(from, msg.sender))
          revert TransferCallerNotOwnerNorApproved();
    }

    _beforeTokenTransfer(from, address(0), tokenId);

    // Clear approvals from the previous owner.
    if (approvedAddress != address(0)) {
      delete _tokenApprovals[tokenId];
    }

    // Underflow of the sender's balance is impossible because we check for
    // ownership above and the recipient's balance can't realistically overflow.
    // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
    unchecked {
      // We can directly decrement the balance, and increment the number burned.
      _balances[from] -= 1;

      // Updates:
      // - `address` to the last owner.
      // - `startTimestamp` to the timestamp of burning.
      // - `burned` to `true`.
      // - `nextInitialized` to `true`.
      _packedOwnerships[tokenId] = _packOwnershipData(
        from,
        (_BITMASK_BURNED | _BITMASK_NEXT_INITIALIZED) |
          _nextExtraData(from, address(0), prevOwnershipPacked)
      );

      // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
      if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
        uint256 nextTokenId = tokenId + 1;
        // If the next slot's address is zero and not burned (i.e. packed value is zero).
        if (_packedOwnerships[nextTokenId] == 0) {
          // If the next slot is within bounds.
          if (nextTokenId != totalMinted()) {
            // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
            _packedOwnerships[nextTokenId] = prevOwnershipPacked;
          }
        }
      }
    }

    emit Transfer(from, address(0), tokenId);

    // Overflow not possible, as totalBurned cannot be exceed totalMinted() times.
    unchecked {
      totalBurned++;
    }
  }

  // =============================================================
  //                     EXTRA DATA OPERATIONS
  // =============================================================

  /**
   * @dev Returns the next extra data for the packed ownership data.
   * The returned result is shifted into position.
   */
  function _nextExtraData(
    address,
    address,
    uint256 prevOwnershipPacked
  ) private pure returns (uint256) {
    return
      uint256(uint24(prevOwnershipPacked >> _BITPOS_EXTRA_DATA)) <<
      _BITPOS_EXTRA_DATA;
  }

  // =============================================================
  //                       OTHER OPERATIONS
  // =============================================================

  /**
   * @dev Converts a uint256 to its ASCII string decimal representation.
   */
  function _toString(uint256 value) internal pure returns (string memory str) {
    assembly {
      // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
      // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
      // We will need 1 word for the trailing zeros padding, 1 word for the length,
      // and 3 words for a maximum of 78 digits. Total: 5 * 0x20 = 0xa0.
      let m := add(mload(0x40), 0xa0)
      // Update the free memory pointer to allocate.
      mstore(0x40, m)
      // Assign the `str` to the end.
      str := sub(m, 0x20)
      // Zeroize the slot after the string.
      mstore(str, 0)

      // Cache the end of the memory to calculate the length later.
      let end := str

      // We write the string from rightmost digit to leftmost digit.
      // The following is essentially a do-while loop that also handles the zero case.
      // prettier-ignore
      for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

      let length := sub(end, str)
      // Move the pointer 32 bytes leftwards to make room for the length.
      str := sub(str, 0x20)
      // Store the length.
      mstore(str, length)
    }
  }
}


// File contracts/interfaces/IERC165.sol

// License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity 0.8.19;

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


// File contracts/interfaces/IERC721Enumerable.sol

// License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;
/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721A {
  /**
   * @dev Returns the total amount of tokens stored by the contract.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
   * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
   */
  function tokenOfOwnerByIndex(
    address owner,
    uint256 index
  ) external view returns (uint256);

  /**
   * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
   * Use along with {totalSupply} to enumerate all tokens.
   */
  function tokenByIndex(uint256 index) external view returns (uint256);
}


// File contracts/ERC721Enumerable.sol

// License-Identifier: MIT
pragma solidity ^0.8.18;

// Parent contracts
// Interfaces
/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is IERC721Enumerable, ERC721A {
  // Mapping from owner to list of owned token IDs
  mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

  // Mapping from token ID to index of the owner tokens list
  mapping(uint256 => uint256) private _ownedTokensIndex;

  // Array with all token ids, used for enumeration
  uint256[] private _allTokens;

  // Mapping from token id to position in the allTokens array
  mapping(uint256 => uint256) private _allTokensIndex;

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override(ERC721A) returns (bool) {
    return
      interfaceId == type(IERC721Enumerable).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
   * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
   */
  function tokenOfOwnerByIndex(
    address owner,
    uint256 index
  ) public view virtual override returns (uint256) {
    require(
      index < ERC721A.balanceOf(owner),
      "ERC721Enumerable: owner index out of bounds"
    );
    return _ownedTokens[owner][index];
  }

  /**
   * @dev See {IERC721Enumerable-totalSupply}.
   */
  function totalSupply() public view returns (uint256) {
    return _allTokens.length;
  }

  /**
   * @dev See {IERC721Enumerable-tokenByIndex}.
   */
  function tokenByIndex(
    uint256 index
  ) public view virtual override returns (uint256) {
    require(
      index < totalSupply(),
      "ERC721Enumerable: global index out of bounds"
    );
    return _allTokens[index];
  }

  /**
   * @dev See {ERC721-_beforeTokenTransfer}.
   * @dev The only transfer with a batch size greater than 1 is minting where tokens IDs are consecutive.
   */
  function _beforeMintTokenTransfer(
    address to,
    uint256 firstTokenId,
    uint256 batchSize
  ) internal virtual override(ERC721A) {
    uint256 length = ERC721A.balanceOf(to);

    for (uint256 i; i < batchSize; i++) {
      uint256 tokenId = firstTokenId + i;
      _addTokenToAllTokensEnumeration(tokenId);

      _ownedTokens[to][length + i] = tokenId;
      _ownedTokensIndex[tokenId] = length + i;
    }
  }

  /**
   * @dev See {ERC721-_beforeTokenTransfer}.
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override(ERC721A) {
    if (from == address(0)) {
      _addTokenToAllTokensEnumeration(tokenId);
    } else if (from != to) {
      _removeTokenFromOwnerEnumeration(from, tokenId);
    }
    if (to == address(0)) {
      _removeTokenFromAllTokensEnumeration(tokenId);
    } else if (to != from) {
      _addTokenToOwnerEnumeration(to, tokenId);
    }
  }

  /**
   * @dev Private function to add a token to this extension's ownership-tracking data structures.
   * @param to address representing the new owner of the given token ID
   * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
   */
  function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
    uint256 length = ERC721A.balanceOf(to);
    _ownedTokens[to][length] = tokenId;
    _ownedTokensIndex[tokenId] = length;
  }

  /**
   * @dev Private function to add a token to this extension's token tracking data structures.
   * @param tokenId uint256 ID of the token to be added to the tokens list
   */
  function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
    _allTokensIndex[tokenId] = _allTokens.length;
    _allTokens.push(tokenId);
  }

  /**
   * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
   * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
   * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
   * This has O(1) time complexity, but alters the order of the _ownedTokens array.
   * @param from address representing the previous owner of the given token ID
   * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
   */
  function _removeTokenFromOwnerEnumeration(
    address from,
    uint256 tokenId
  ) private {
    // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
    // then delete the last slot (swap and pop).

    uint256 lastTokenIndex = ERC721A.balanceOf(from) - 1;
    uint256 tokenIndex = _ownedTokensIndex[tokenId];

    // When the token to delete is the last token, the swap operation is unnecessary
    if (tokenIndex != lastTokenIndex) {
      uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

      _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
      _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
    }

    // This also deletes the contents at the last position of the array
    delete _ownedTokensIndex[tokenId];
    delete _ownedTokens[from][lastTokenIndex];
  }

  /**
   * @dev Private function to remove a token from this extension's token tracking data structures.
   * This has O(1) time complexity, but alters the order of the _allTokens array.
   * @param tokenId uint256 ID of the token to be removed from the tokens list
   */
  function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
    // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
    // then delete the last slot (swap and pop).

    uint256 lastTokenIndex = _allTokens.length - 1;
    uint256 tokenIndex = _allTokensIndex[tokenId];

    // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
    // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
    // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
    uint256 lastTokenId = _allTokens[lastTokenIndex];

    _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
    _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

    // This also deletes the contents at the last position of the array
    delete _allTokensIndex[tokenId];
    _allTokens.pop();
  }
}


// File contracts/interfaces/IERC721Royalty.sol

// License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity 0.8.19;
/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC721Royalty is IERC165 {
  /**
   * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
   * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
   */
  function royaltyInfo(
    uint256 tokenId,
    uint256 salePrice
  ) external view returns (address receiver, uint256 royaltyAmount);
}


// File contracts/ERC721Royalty.sol

// License-Identifier: MIT
pragma solidity ^0.8.0;

// Interfaces
/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10_000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 */
contract ERC721Royalty is IERC721Royalty {
  uint256 private _royaltyFee;
  address private _royaltyReceiver;

  //======= ERRORS =======//
  //======================//

  error RoyaltyFeeExceedsSalesPrice();
  error RoyaltyReceiverZeroAddress();

  //======= VIEWS =======//
  //=====================//

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override(IERC165) returns (bool) {
    return interfaceId == type(IERC721Royalty).interfaceId;
  }

  /**
   * @inheritdoc IERC721Royalty
   */
  function royaltyInfo(
    uint256,
    uint256 _salePrice
  ) public view override returns (address, uint256) {
    uint256 royaltyAmount = (_salePrice * _royaltyFee) / _feeDenominator();

    return (_royaltyReceiver, royaltyAmount);
  }

  /**
   * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
   * fraction of the sale price. Defaults to 10 000 = 100% so fees are expressed in basis points, but may be customized by an
   * override.
   */
  function _feeDenominator() internal pure returns (uint96) {
    return 10_000;
  }

  //======= ADMIN =======//
  //=====================//

  /**
   * @dev Sets the royalty information that all ids in this contract will default to.
   *
   * Requirements:
   *
   * - `receiver` cannot be the zero address.
   * - `feeNumerator` cannot be greater than the fee denominator.
   */
  function _setDefaultRoyalty(
    address royaltyReceiver_,
    uint96 royaltyFee_
  ) internal {
    if (royaltyReceiver_ == address(0)) revert RoyaltyReceiverZeroAddress();
    if (_feeDenominator() <= royaltyFee_) revert RoyaltyFeeExceedsSalesPrice();

    _royaltyReceiver = royaltyReceiver_;
    _royaltyFee = royaltyFee_;
  }
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


// File contracts/OnlyDelegateCall.sol

// License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title Prevents direct call to a contract
/// @notice Base contract that provides a modifier for preventing direct call to methods in a child contract
abstract contract OnlyDelegateCall {
  error OnlyDelegateCallAllowed();

  /// @dev The original address of this contract
  address private immutable original;

  constructor() {
    // Immutables are computed in the init code of the contract, and then inlined into the deployed bytecode.
    // In other words, this variable won't change when it's checked at runtime.
    original = address(this);
  }

  /// @dev Private method is used instead of inlining into modifier because modifiers are copied into each method,
  ///     and the use of immutable means the address bytes are copied in every place the modifier is used.
  function checkDelegateCall() private view {
    if (address(this) == original) revert OnlyDelegateCallAllowed();
  }

  /// @notice Prevents direct call into the modified method
  modifier onlyDelegateCall() {
    checkDelegateCall();
    _;
  }
}


// File contracts/TickieNFT.sol

// License-Identifier: UNLICENCED
pragma solidity 0.8.19;

// Addons
// Parent Contracts
// Interfaces
/// @title Tickie NFT collection contract
/// @notice This contract serves as an implementation for the Tickie NFT factory contract
contract TickieNFT is
  ITickieNFT,
  Ownable,
  ERC721Enumerable,
  ERC2612Permit,
  ERC721Royalty,
  OnlyDelegateCall
{
  //======= STORAGE =======//
  //=======================//
  // Single wallet authorized to mint tickets
  address public minter;
  // Whether ticket transfers are currently allowed
  bool public canTransfer;
  // Whether ticket transfers initiated by contracts are currently allowed
  bool public canTransferFromContracts;
  // Token URI used a placeholder before the collection reveal
  string public placeHolderTokenURI;
  // The timestamp from which the placeholder URI will be ignored
  uint256 public revealTimestamp;
  // Hash of the collection metadata authenticating the token ordering
  bytes32 public originHash;
  // Saves initialization state of the collection
  bool public isInitialized;

  //======= INITIALIZE =======//
  //==========================//

  /*
   * @dev Configures the collection when it is initialized by the proxy
   * @param canTransfer_ Whether ticket transfers are currently allowed
   * @param canTransferFromContracts_ Whether ticket transfers initiated by contracts are currently allowed
   * @param collectionName_ The name of the collection
   * @param baseURI_ The base URI of the collection
   *
   * We want to block direct initialization with `onlyDelegateCall` to prevent implementation takeover
   *
   */
  function initialize(
    bool canTransfer_,
    bool canTransferFromContracts_,
    string memory collectionName_,
    string memory baseURI_
  ) external onlyDelegateCall {
    if (isInitialized) revert ContractAlreadyInitialized();
    isInitialized = true;

    canTransfer = canTransfer_;
    canTransferFromContracts = canTransferFromContracts_;

    // We want the wallet calling the factory to be the owner
    // Safe since only the deployer wallet calling the factory can be tx.origin
    Ownable._setOwner(tx.origin);

    ERC721A._initializeERC721A(collectionName_, baseURI_);
    ERC2612Permit._initializeERC721Permit(collectionName_);
  }

  //======= EVENTS =======//
  //======================//

  /// @dev Emitted when the origin hash has been set
  event OriginHashSet(bytes32 originHash);
  /// @dev Emitted when a minter wallet is set
  event MinterUpdated(address indexed oldMinter, address indexed newMinter);
  /// @dev Emitted when transfer authorizations are changes
  event TransferAuthorisationsUpdated(bool fromWallet, bool fromContract);

  //======= ERRORS =======//
  //======================//

  /// @dev Throws when trying to initialize the contract again
  error ContractAlreadyInitialized();
  /// @dev Thrown when a non authorized wallet calls a priviledged function
  error NotOwnerOrMinter();
  /// @dev Thrown when the signature fails or does not resolve to token owner
  error InvalidPermit();
  /// @dev Thrown when the length of arguments do not correspond
  error ArgumentLengthMismatch();
  /// @dev Thrown when trying to transfer while it is not authorized
  error TransfersCurrentlyUnauthorized();
  /// @dev Thrown when trying to transfer from a contract while it is not authorized
  error ContractTransfersCurrentlyUnauthorized();
  /// @dev Thrown when the origin hash is already set
  error OriginHashIsAlreadySet();
  /// @dev Thrown when trying to configure impossible transfer authorizations
  error CannotAllowTransferFromContractsOnly();

  //======= MODIFIERS =======//
  //=========================//

  /*
   * @dev Authenticates the caller
   */
  modifier onlyOwnerOrMinter() {
    if (msg.sender != owner())
      if (msg.sender != minter) revert NotOwnerOrMinter();
    _;
  }

  /*
   * @dev Allows transfer dependant actions to be performed when transfer are not allowed
   */
  modifier authorizationPassthrough() {
    if (!canTransfer) {
      canTransfer = true;
      _;
      canTransfer = false;
    } else {
      _;
    }
  }

  //======= VIEWS =======//
  //=====================//

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(
    bytes4 interfaceId
  ) public view override(ERC721Enumerable, ERC721Royalty) returns (bool) {
    // ERC721Enumerable calls ERC721A 'supportsInterface' through 'super'
    return
      ERC721Enumerable.supportsInterface(interfaceId) ||
      ERC721Royalty.supportsInterface(interfaceId);
  }

  //======= OVERRIDES =======//
  //=========================//

  /*
   * @dev Overrides the ERC721Enumerable hook to check if transfers are currently allowed
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721Enumerable) {
    if (!canTransferFromContracts && msg.sender != tx.origin)
      revert ContractTransfersCurrentlyUnauthorized();
    if (!canTransfer) revert TransfersCurrentlyUnauthorized();

    super._beforeTokenTransfer(from, to, tokenId);
  }

  /*
   * @dev Overrides the ERC721A function to display the placeholder URI
   */
  function tokenURI(
    uint256 tokenId
  ) public view override(ERC721A, IERC721A) returns (string memory) {
    if (bytes(placeHolderTokenURI).length != 0)
      if (block.timestamp < revealTimestamp)
        if (ERC721A.exists(tokenId)) return placeHolderTokenURI;

    return ERC721A.tokenURI(tokenId);
  }

  //======= MINT =======//
  //====================//

  /*
   * @dev Mints tickets to a single recipient
   * @param to The address to mint the ticket to
   * @param quantity The quantity of tickets to mint
   */
  function mintTickets(
    address to,
    uint256 quantity
  ) external onlyOwnerOrMinter authorizationPassthrough {
    ERC721A._mint(to, ERC721A.getStartIndex(), quantity);
  }

  /*
   * @dev Mints tickets to multiple recipients
   * @param to The address to mint the ticket to
   * @param quantity The quantity of tickets to mint
   */
  function mintMulti(
    address[] memory to,
    uint256[] memory quantity
  ) external onlyOwnerOrMinter authorizationPassthrough {
    if (to.length != quantity.length) revert ArgumentLengthMismatch();

    for (uint256 i; i < to.length; i++) {
      ERC721A._mint(to[i], ERC721A.getStartIndex(), quantity[i]);
    }
  }

  /*
   * @dev Mints invitation tickets to a single recipient
   * @param to The address to mint the ticket to
   * @param quantity The quantity of tickets to mint
   */
  function mintInvitationTicket(
    address to,
    uint256 quantity
  ) external onlyOwnerOrMinter authorizationPassthrough {
    ERC721A._mint(to, ERC721A.getStartIndexInvitations(), quantity);
  }

  //======= TOKEN MANAGEMENT =======//
  //================================//

  /*
   * @dev Destroys tickets
   * @param tokenIds The ids of the tickets to burn
   */
  function refundTickets(
    uint256[] calldata tokenIds
  ) external onlyOwnerOrMinter authorizationPassthrough {
    for (uint256 i; i < tokenIds.length; i++) {
      ERC721A._burn(tokenIds[i], false);
    }
  }

  /*
   * @dev Retransfer tickets to a single recipient
   * @param tokenIds The ids of the tickets to transfer
   * @param to The address to transfer the tickets to
   */
  function saveTickets(
    uint256[] calldata tokenIds,
    address to
  ) external onlyOwnerOrMinter authorizationPassthrough {
    for (uint256 i; i < tokenIds.length; i++) {
      ERC721A._approve(address(this), tokenIds[i]);
      address owner = ERC721A.ownerOf(tokenIds[i]);
      ERC721A._transferFrom(owner, to, tokenIds[i]);
    }
  }

  //======= PERMIT =======//
  //======================//

  /*
   * @dev Allow sponsored transfers of tickets using a permit signature
   * @param from The address to transfer the tickets from
   * @param to The address to transfer the tickets to
   * @param spender The collection proxy address handling the transfer
   * @param tokenId The id of the ticket to transfer
   * @param deadline The deadline timestamp of the permit
   * @param v The v value of the permit signature
   * @param r The r value of the permit signature
   * @param s The s value of the permit signature
   */
  function transferFromWithPermit(
    address from,
    address to,
    uint256 tokenId,
    address spender,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    bool isValid = ERC2612Permit._isValidPermit(
      from,
      spender,
      tokenId,
      deadline,
      v,
      r,
      s
    );

    if (!isValid) revert InvalidPermit();
    ERC721A._approve(spender, tokenId);
    ERC721A._transferFrom(from, to, tokenId);
  }

  //======= REVEAL =======//
  //======================//

  /*
   * @dev Sets a placeholder URI for metadata to display before a reveal
   * @param placeHolderTokenURI_ The metadata URI
   * @param revealTimestamp_ The timestamp of the reveal
   *
   * @note Setting a very high value for the reveal timestamp allows for manual reveal timing
   *
   */
  function setPlaceholderURI(
    string memory placeHolderTokenURI_,
    uint256 revealTimestamp_
  ) external onlyOwner {
    placeHolderTokenURI = placeHolderTokenURI_;
    revealTimestamp = revealTimestamp_;
  }

  //======= ORIGIN HASH =======//
  //===========================//

  /*
   * Set the hash of the collection metadata to authenticate the token sequence
   * @param originHash_ The hash of the collection metadata
   */
  function setOriginHash(bytes32 originHash_) external onlyOwner {
    if (originHash != 0x0) revert OriginHashIsAlreadySet();

    originHash = originHash_;
    emit OriginHashSet(originHash_);
  }

  //======= ROYALTY =======//
  //=======================//

  /*
   * @dev Sets the royalty config for the collection
   * @param royaltyReceiver_ The address to receive royalties
   * @param royaltyFee_ The fee to be paid as a percentage of the sale price
   */
  function setRoyaltyConfig(
    address royaltyReceiver_,
    uint96 royaltyFee_
  ) external onlyOwner {
    ERC721Royalty._setDefaultRoyalty(royaltyReceiver_, royaltyFee_);
  }

  //======= ADMIN =======//
  //=====================//

  /*
   * @dev Sets the transfer authorisations for the collection
   * @param fromWallet Whether transfers from wallets are allowed
   * @param fromContract_ Whether transfers from contracts are allowed
   */
  function setTransferAuthorisation(
    bool fromWallet,
    bool fromContract
  ) external onlyOwner {
    if (!fromWallet && fromContract)
      revert CannotAllowTransferFromContractsOnly();

    canTransfer = fromWallet;
    canTransferFromContracts = fromContract;

    emit TransferAuthorisationsUpdated(fromWallet, fromContract);
  }

  /*
   * @dev Sets a wallet with minting privileges
   * @param minter_ The address of the minter
   */
  function setMinter(address minter_) external onlyOwner {
    address oldMinter = minter;
    minter = minter_;

    emit MinterUpdated(oldMinter, minter_);
  }

  /**
   * @dev Sets the base Uniform Resource Identifier (URI) for the collection
   * @param baseURI_ The base URI to be used for the collection
   */
  function setBaseURI(string memory baseURI_) external onlyOwner {
    ERC721A._setBaseURI(baseURI_);
  }
}