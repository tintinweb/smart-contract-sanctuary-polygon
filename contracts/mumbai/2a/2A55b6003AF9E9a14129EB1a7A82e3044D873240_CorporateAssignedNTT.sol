/**
 *Submitted for verification at polygonscan.com on 2023-04-10
*/

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

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IERC165).interfaceId;
  }
}

/// @dev The following events & methods are devised to maximize compatibility with implementations that expect ERC721 contracts
interface IERC721Compatibility {
  /**
   * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
   */
  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
}

/// @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x780e9d63.
/* is ERC721 */ interface IERC721Enumerable {
  /// @notice Count NFTs tracked by this contract
  /// @return A count of valid NFTs tracked by this contract, where each one of
  ///  them has an assigned and queryable owner not equal to the zero address
  function totalSupply() external view returns (uint256);

  /// @notice Enumerate valid NFTs
  /// @dev Throws if `_index` >= `totalSupply()`.
  /// @param _index A counter less than `totalSupply()`
  /// @return The token identifier for the `_index`th NFT,
  ///  (sort order not specified)
  function tokenByIndex(uint256 _index) external view returns (uint256);

  /// @notice Enumerate NFTs assigned to an owner
  /// @dev Throws if `_index` >= `balanceOf(_owner)` or if
  ///  `_owner` is the zero address, representing invalid NFTs.
  /// @param _owner An address where we are interested in NFTs owned by them
  /// @param _index A counter less than `balanceOf(_owner)`
  /// @return The token identifier for the `_index`th NFT assigned to `_owner`,
  ///   (sort order not specified)
  function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}

/// @title Subset of ERC-721 Non-Fungible Token Standard, optional enumeration extension
/// @dev We implement only totalSupply(), as the function is trivial to implement and improves compatibility
/// with applications that interact with IERC721Enumerable
interface IERC721EnumerableSubset {
  /// @notice Count NFTs tracked by this contract
  /// @return A count of valid NFTs tracked by this contract, where each one of
  ///  them has an assigned and queryable owner not equal to the zero address
  function totalSupply() external view returns (uint256);
}

/**
 * @dev IERC4671, as defined in the
 * https://eips.ethereum.org/EIPS/eip-4671[EIP].
 *
 * Note: The EIP is in "Draft" status currently
 */
interface IERC4671 is IERC165 {
  /// Event emitted when a token `tokenId` is minted for `owner`
  event Minted(address owner, uint256 tokenId);

  /// Event emitted when token `tokenId` of `owner` is revoked
  event Revoked(address owner, uint256 tokenId);

  /// @notice Count all tokens assigned to an owner
  /// @param owner Address for whom to query the balance
  /// @return Number of tokens owned by `owner`
  function balanceOf(address owner) external view returns (uint256);

  /// @notice Get owner of a token
  /// @param tokenId Identifier of the token
  /// @return Address of the owner of `tokenId`
  function ownerOf(uint256 tokenId) external view returns (address);

  /// @notice Check if a token hasn't been revoked
  /// @param tokenId Identifier of the token
  /// @return True if the token is valid, false otherwise
  function isValid(uint256 tokenId) external view returns (bool);

  /// @notice Check if an address owns a valid token in the contract
  /// @param owner Address for whom to check the ownership
  /// @return True if `owner` has a valid token, false otherwise
  function hasValid(address owner) external view returns (bool);
}

interface IERC4671Enumerable is IERC4671 {
  /// @return emittedCount Number of tokens emitted
  function emittedCount() external view returns (uint256);

  /// @return holdersCount Number of token holders
  function holdersCount() external view returns (uint256);

  /// @notice Get the tokenId of a token using its position in the owner's list
  /// @param owner Address for whom to get the token
  /// @param index Index of the token
  /// @return tokenId of the token
  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

  /// @notice Get a tokenId by it's index, where 0 <= index < total()
  /// @param index Index of the token
  /// @return tokenId of the token
  function tokenByIndex(uint256 index) external view returns (uint256);
}

/**
 * @dev IERC4671Metadata, as defined in the
 * https://eips.ethereum.org/EIPS/eip-4671[EIP].
 *
 * Note: The EIP is in "Draft" status currently
 */
interface IERC4671Metadata is IERC4671 {
  /// @return Descriptive name of the tokens in this contract
  function name() external view returns (string memory);

  /// @return An abbreviated name of the tokens in this contract
  function symbol() external view returns (string memory);

  /// @notice URI to query to get the token's metadata
  /// @param tokenId Identifier of the token
  /// @return URI for the token
  function tokenURI(uint256 tokenId) external view returns (string memory);
}

/**
 * This interface reflects the fact that only so many tokens can be minted by using a contract
 */
interface ILimitedTokenGenerator {
  /**
   * @notice Reports the maximum number of tokens that may be minted by using this contract
   */
  function getMaxTokenCount() external view returns (uint256);
}

/**
 * Corporate assigned, non-tradeable tokens
 */
interface ICorporateAssignedNTT is
  IERC4671Metadata,
  IERC4671Enumerable,
  ILimitedTokenGenerator,
  IERC721EnumerableSubset,
  IERC721Compatibility
{
  /**
   * @notice Mints a new token for the given owner with the given token URI
   * @param owner Address for whom a new token is being minted
   * @param tokenUri The token URI
   * @return The token ID for the minted token
   */
  function mint(address owner, string calldata tokenUri) external returns (uint256);

  /**
   * @notice Revokes a given token
   * @param tokenId The token ID
   */
  function revoke(uint256 tokenId) external;
}

error CorporateAssignedNTT__NotAValidOwner();
error CorporateAssignedNTT__NotAValidTokenId();
error CorporateAssignedNTT__MustBeContractOwner();
error CorporateAssignedNTT__MaximumAmountOfTokensReached();
error CorporateAssignedNTT__NotAValidURI();
error CorporateAssignedNTT__OwnerIndexOutOfBounds();

/**
 * Corporate assigned, non-tradeable tokens
 */
contract CorporateAssignedNTT is ICorporateAssignedNTT, ERC165 {
  // Token name
  string private constant i_name = "Corporate Assigned NTT"; // TODO: Think if this shouldn't be set in the constructor

  // Token symbol
  string private constant i_symbol = "CA-NTT"; // TODO: Think if this shouldn't be set in the constructor

  // Corporate contract owner
  address private immutable i_contractOwner;

  // Maximum amount of tokens that can be minted using this contract
  uint256 private immutable i_maxTokenCount;

  // This counter is used to automatically assign a new token ID during the minting process
  uint256 private s_tokenCounter;

  // This counter keeps track of the total number of non-revoked tokens
  uint256 private s_nonRevokedTokenCount;

  // This counter keeps track of the total number of owner accounts
  uint256 private s_ownersCounter;

  // Mapping owner address to token count
  mapping(address => uint256) private s_balances;

  // Mapping from token ID to owner address
  mapping(uint256 => address) private s_owners;

  // Mapping from token ID to token URI
  mapping(uint256 => string) private s_uris;

  // Mapping from owner to list of owned token IDs
  mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

  // Mapping from token ID to index of the owner tokens list (Required to achieve O(1) during token revocation)
  mapping(uint256 => uint256) private _ownedTokensIndex;

  constructor(address contractOwner, uint256 maxTokenCount) {
    i_contractOwner = contractOwner;
    i_maxTokenCount = maxTokenCount;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyContractOwner() {
    if (i_contractOwner != msg.sender) {
      revert CorporateAssignedNTT__MustBeContractOwner();
    }
    _;
  }

  /**
   * @dev See {IERC4671Metadata-name}.
   */
  function name() external pure returns (string memory) {
    return i_name;
  }

  /**
   * @dev See {IERC4671Metadata-symbol}.
   */
  function symbol() external pure returns (string memory) {
    return i_symbol;
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view override(ERC165, IERC165) returns (bool) {
    return
      interfaceId == type(IERC4671).interfaceId ||
      interfaceId == type(IERC4671Metadata).interfaceId ||
      interfaceId == type(IERC4671Enumerable).interfaceId ||
      // This contract actually supports IERC721Enumerable due to the addition of IERC721EnumerableSubset
      interfaceId == type(IERC721Enumerable).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
   * @dev See {IERC4671-balanceOf}.
   */
  function balanceOf(address owner) external view returns (uint256) {
    if (owner == address(0)) {
      revert CorporateAssignedNTT__NotAValidOwner();
    }

    return s_balances[owner];
  }

  /**
   * @dev See {IERC4671-ownerOf}.
   */
  function ownerOf(uint256 tokenId) external view returns (address) {
    address owner = s_owners[tokenId];

    if (owner == address(0)) {
      revert CorporateAssignedNTT__NotAValidTokenId();
    }

    return owner;
  }

  /**
   * @dev See {IERC4671-isValid}.
   */
  function isValid(uint256 tokenId) external view returns (bool) {
    return (s_owners[tokenId] != address(0));
  }

  /**
   * @dev See {IERC4671-hasValid}.
   */
  function hasValid(address owner) external view returns (bool) {
    return (s_balances[owner] > 0);
  }

  /**
   * @dev See {IERC4671Metadata-tokenURI}.
   */
  function tokenURI(uint256 tokenId) external view returns (string memory) {
    string memory uri = s_uris[tokenId];

    if (bytes(uri).length <= 0) {
      revert CorporateAssignedNTT__NotAValidTokenId();
    }

    return uri;
  }

  /**
   * @dev Private function to add a token to the ownership-tracking data structures.
   * @param owner address representing the new owner of the given token ID
   * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
   */
  function _addTokenToOwnerEnumeration(address owner, uint256 tokenId) private {
    uint256 length = s_balances[owner];
    _ownedTokens[owner][length] = tokenId;
    _ownedTokensIndex[tokenId] = length;
  }

  /**
   * @dev See {ICorporateAssignedNTT-mint}.
   */
  function mint(address owner, string calldata tokenUri) external onlyContractOwner returns (uint256) {
    if (owner == address(0)) {
      revert CorporateAssignedNTT__NotAValidOwner();
    }

    if (bytes(tokenUri).length <= 0) {
      revert CorporateAssignedNTT__NotAValidURI();
    }

    if (s_tokenCounter >= i_maxTokenCount) {
      revert CorporateAssignedNTT__MaximumAmountOfTokensReached();
    }

    uint256 newTokenId = s_tokenCounter;
    s_tokenCounter += 1;

    _addTokenToOwnerEnumeration(owner, newTokenId);

    s_nonRevokedTokenCount += 1;
    s_balances[owner] += 1;
    s_owners[newTokenId] = owner;
    s_uris[newTokenId] = tokenUri;

    if (s_balances[owner] == 1) {
      s_ownersCounter += 1;
    }

    emit Minted(owner, newTokenId);
    emit Transfer(address(0), owner, newTokenId);

    return newTokenId;
  }

  /**
   * @dev Private function to remove a token from the ownership-tracking data structures.
   * This has O(1) time complexity, but alters the order of the _ownedTokens array.
   * @param owner address representing the previous owner of the given token ID
   * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
   */
  function _removeTokenFromOwnerEnumeration(address owner, uint256 tokenId) private {
    // To prevent a gap in tokens array, we store the last token in the index of the token to delete, and
    // then delete the last slot (swap and pop).

    uint256 lastTokenIndex = s_balances[owner] - 1;
    uint256 tokenIndex = _ownedTokensIndex[tokenId];

    // When the token to delete is the last token, the swap operation is unnecessary
    if (tokenIndex != lastTokenIndex) {
      uint256 lastTokenId = _ownedTokens[owner][lastTokenIndex];

      _ownedTokens[owner][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
      _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
    }

    // This also deletes the contents at the last position of the array
    delete _ownedTokensIndex[tokenId];
    delete _ownedTokens[owner][lastTokenIndex];
  }

  /**
   * @dev See {ICorporateAssignedNTT-revoke}.
   */
  function revoke(uint256 tokenId) external onlyContractOwner {
    address owner = s_owners[tokenId];

    if (owner == address(0)) {
      revert CorporateAssignedNTT__NotAValidTokenId();
    }

    _removeTokenFromOwnerEnumeration(owner, tokenId);

    s_owners[tokenId] = address(0);
    s_uris[tokenId] = "";
    s_balances[owner] -= 1;
    s_nonRevokedTokenCount -= 1;

    if (s_balances[owner] == 0) {
      s_ownersCounter -= 1;
    }

    emit Revoked(owner, tokenId);
  }

  /**
   * @dev See {ILimitedTokenGenerator-getMaxTokenCount}.
   */
  function getMaxTokenCount() external view returns (uint256) {
    return i_maxTokenCount;
  }

  /**
   * @notice Please note that revoked tokens count as being emitted
   * @dev See {IERC4671EnumerableSubset-emittedCount}.
   */
  function emittedCount() external view returns (uint256) {
    return s_tokenCounter;
  }

  /**
   * @notice Please note that only owners with non-revoked tokens count towards this value
   * @dev See {IERC4671EnumerableSubset-emittedCount}.
   */
  function holdersCount() external view returns (uint256) {
    return s_ownersCounter;
  }

  /**
   * @dev See {IERC721EnumerableSubset-totalSupply}
   * @notice Given the description of totalSupply(), for this contract we return the amount of non-revoked tokens in existence
   */
  function totalSupply() external view returns (uint256) {
    return s_nonRevokedTokenCount;
  }

  /**
   * @dev See {IERC4671EnumerableSubset-tokenOfOwnerByIndex}.
   */
  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256) {
    if (owner == address(0)) {
      revert CorporateAssignedNTT__NotAValidOwner();
    }

    if (index >= s_balances[owner]) {
      revert CorporateAssignedNTT__OwnerIndexOutOfBounds();
    }

    return _ownedTokens[owner][index];
  }

  /*
   * @notice Get a tokenId by it's index, where 0 <= index < total()
   * @param index Index of the token
   * @return tokenId of the token
   */
  function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
    return index;
  }
}