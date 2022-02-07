// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';
import '@openzeppelin/contracts/interfaces/IERC165.sol';

contract GrainyHeroes is IERC165, IERC721, IERC721Metadata, IERC721Enumerable {
  using Strings for uint256;
  address payable contractOwner;
  uint256 public constant COST_TO_MINT = 0.05 ether;
  uint256 public maxHeroes = 5;
  uint256 public amountMintedHeroes = 0;
  mapping(address => uint256) private _balances;
  mapping(uint256 => address) private _owners;
  mapping(uint256 => address) private _approvals;
  mapping(address => mapping(address => bool)) private _operators;
  string private _baseURI;

  constructor() {
    contractOwner = payable(msg.sender);
  }

  function mintHero() external payable {
    require(COST_TO_MINT <= msg.value);
    amountMintedHeroes += 1;
    uint256 tokenId = amountMintedHeroes;
    require(amountMintedHeroes <= maxHeroes);
    _balances[msg.sender] += 1;
    _owners[tokenId] = msg.sender;
    emit Transfer(address(0), msg.sender, tokenId);
  }

  function withdraw() external {
    require(msg.sender == contractOwner);
    uint256 balance = address(this).balance;
    (bool sent,) = contractOwner.call{value: balance}("");
    require(sent);
  }

  /* IERC20 */

  function balanceOf(address owner) public view override returns (uint256 balance) {
    balance = _balances[owner];
  }

  function ownerOf(uint256 tokenId) public view override returns (address owner) {
    //require(_exists(tokenId), "Owner query for nonexistent token");

    owner = _owners[tokenId];
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) external override {
    transferFrom(from, to, tokenId);
    //require(
    //  _checkOnERC721Received(from, to, tokenId, ''),
    //  'Transfer to non ERC721Receiver implementer'
    //);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external override {
    transferFrom(from, to, tokenId);
    //require(
    //  _checkOnERC721Received(from, to, tokenId, data),
    //  'Transfer to non ERC721Receiver implementer'
    //);
  }

  function transferFrom(address from, address to, uint256 tokenId) public override {
    bool isApprovedOrOwner = (
      msg.sender == from ||
      msg.sender == getApproved(tokenId) ||
      isApprovedForAll(from, msg.sender));
    require(isApprovedOrOwner, "Caller is not owner nor approved");

    _balances[from] -= 1;
    _balances[to] += 1;
    _owners[tokenId] = to;
    approve(address(0), tokenId);
    emit Transfer(from, to, tokenId); 
  }

  function approve(address to, uint256 tokenId) public override {
    address owner = ownerOf(tokenId);
    require(msg.sender == owner || isApprovedForAll(owner, msg.sender),
      "Caller is not owner nor approved for all");
    _approvals[tokenId] = to;
    emit Approval(owner, to,  tokenId);
  }

  function getApproved(uint256 tokenId) public view override returns(address operator) {
    operator = _approvals[tokenId];
  }

  function setApprovalForAll(address operator, bool approved) external override {
    _operators[msg.sender][operator] = approved;
    emit ApprovalForAll(msg.sender, operator, approved);
  }

  function isApprovedForAll(address owner, address operator) public view override returns(bool) {
    return _operators[owner][operator];
  } 

  /* Enumerable */
  
  function totalSupply() public view override returns (uint256) {
    return amountMintedHeroes;
  }

  function tokenByIndex(uint256 index) external view override returns (uint256) {
    return index;
  }


  function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
      require(index < balanceOf(owner), 'ERC721A: owner index out of bounds');
      uint256 numMintedSoFar = totalSupply();
      uint256 tokenIdsIdx;
      address currOwnershipAddr;

      // Counter overflow is impossible as the loop breaks when uint256 i is equal to another uint256 numMintedSoFar.
      unchecked {
          for (uint256 i; i < numMintedSoFar; i++) {
              if (_owners[i] != address(0)) {
                  currOwnershipAddr = _owners[i];
              }
              if (currOwnershipAddr == owner) {
                  if (tokenIdsIdx == index) {
                      return i;
                  }
                  tokenIdsIdx++;
              }
          }
      }

      revert('ERC721A: unable to get token of owner by index');
  }

  /* Metadata */

  function name() external view override returns (string memory _name) {
    return "Grainy Heroes";
  }

  function symbol() external view override returns (string memory _symbol) {
    return "GH";
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
      // require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');

      return bytes(_baseURI).length != 0 ? string(abi.encodePacked(_baseURI, tokenId.toString())) : '';
  }

  function setBaseURI(string calldata uri) external {
      _baseURI = uri;
  }

  /* ERC-165 */

  function supportsInterface(bytes4 interfaceId) public override view returns (bool) {
      return
          interfaceId == type(IERC721).interfaceId ||
          interfaceId == type(IERC721Metadata).interfaceId ||
          interfaceId == type(IERC721Enumerable).interfaceId;
  }

  /* TODO: Remove on production. Only for dev env. */

  function devDestroy() public {
    selfdestruct(contractOwner);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

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