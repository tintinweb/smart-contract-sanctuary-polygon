// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Strings.sol';

interface IERC721 {
  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
  event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
  event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

  function balanceOf(address owner) external view returns (uint256 balance);
  function ownerOf(uint256 tokenId) external view returns (address owner);
  function safeTransferFrom(address from, address to, uint256 tokenId) external;
  function transferFrom(address from, address to, uint256 tokenId) external;
  function approve(address to, uint256 tokenId) external;
  function getApproved(uint256 tokenId) external view returns(address operator);
  function setApprovalForAll(address operator, bool approved) external;
  function isApprovedForAll(address owner, address operator) external view returns(bool approved);
  function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

contract GrainyHeroes is IERC721 {
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
  
  function totalSupply() public view returns (uint256) {
    return amountMintedHeroes;
  }

  function tokenByIndex(uint256 index) external view returns (uint256) {
    return index;
  }


  function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
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

  function name() external view returns (string memory _name) {
    return "Grainy Heroes";
  }

  function symbol() external view returns (string memory _symbol) {
    return "GH";
  }

  function tokenURI(uint256 tokenId) public view returns (string memory) {
      // require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');

      return bytes(_baseURI).length != 0 ? string(abi.encodePacked(_baseURI, tokenId.toString())) : '';
  }

  function setBaseURI(string calldata uri) external {
      _baseURI = uri;
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