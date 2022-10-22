// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC165.sol";
import "./ICorporateAssignedNTT.sol";

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
}