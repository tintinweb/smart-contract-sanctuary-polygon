pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: CC0

// import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "./Counters.sol";
import "./ERC1155.sol";

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

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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

// contract WearablesNFTs is ERC1155, AccessControlEnumerable, ReentrancyGuard {
contract WearablesNFTs is ERC1155, ReentrancyGuard {
  using Counters for Counters.Counter;

  mapping (uint256 => string) private _uris;
  Counters.Counter private _tokenCount;
  string public name = "MetaFactory Wearables";
  string public symbol = unicode"MF🎽s";

  // bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  // bytes32 public constant META_MANAGER_ROLE = keccak256("META_MANAGER_ROLE");

  constructor() ERC1155("Single Metadata URI Is Not Used") {
    // _setupRole(DEFAULT_ADMIN_ROLE, 0x615b044B6Ccb048532bcF99AAdf619d7fdD2Aa01);
  }

  function mint(
    address recipient,
    uint256 amount,
    string memory metadata,
    bytes memory data
  ) public virtual
  nonReentrant
  // onlyRole(MINTER_ROLE)
  {
    _tokenCount.increment();
    uint256 id = _tokenCount.current();
    _mint(recipient, id, amount, data);
    setURI(metadata, id);
  }

  function uri(uint256 tokenId) public view virtual override
  returns (string memory)
  {
    return _uris[tokenId];
  }

  function setURI(string memory newuri, uint256 tokenId) public virtual
  // onlyRole(META_MANAGER_ROLE)
  {
    _uris[tokenId] = newuri;
    emit URI(newuri, tokenId);
  }

  function tokenCount() public view returns (uint256) {
    return _tokenCount.current();
  }

  function distributeSingles(
    address from,
    address[] memory to,
    uint256 id,
    bytes memory data
  ) public virtual {
    require(
      from == _msgSender() || isApprovedForAll(from, _msgSender()),
      "ERC1155: caller is not owner nor approved"
    );
    for (uint256 i = 0; i < to.length; ++i) {
      _safeTransferFrom(from, to[i], id, 1, data);
    }
  }

  // function supportsInterface(bytes4 interfaceId) public view override(ERC1155, AccessControlEnumerable) returns (bool) {
  function supportsInterface(bytes4 interfaceId) public view override(ERC1155) returns (bool) {
    return (
      ERC1155.supportsInterface(interfaceId)
      // || AccessControlEnumerable.supportsInterface(interfaceId)
    );
  }
}