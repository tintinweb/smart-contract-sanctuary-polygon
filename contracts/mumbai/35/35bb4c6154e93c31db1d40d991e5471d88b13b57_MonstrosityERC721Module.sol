// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/utils/Strings.sol";
import "../shared/MonstrosityBase.sol";
import "../shared/ERC165.sol";
import "../interfaces/IERC721.sol";
import "../interfaces/IERC721Metadata.sol";
import "../lib/LibMonstrosityERC721.sol";

contract MonstrosityERC721Module is MonstrosityBase, ERC165, IERC721, IERC721Metadata {
  using Strings for uint256;
  using LibMonstrosityERC721 for ERC721Data;

  string private constant NAME = "MonstrosityNFT";
  string private constant SYMBOL = "MONSTER";
  string private constant URI_SUFFIX = ".json";

  function supportsInterface(bytes4 interfaceId) public view override(ERC165, IERC165) returns (bool) {
    return
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function balanceOf(address owner) public view returns (uint256) {
    require(owner != address(0));
    return _nftData.balances[owner];
  }

  function ownerOf(uint256 tokenId) public view returns (address) {
    address owner = _nftData.owners[tokenId];
    require(owner != address(0));
    return owner;
  }

  function name() external pure returns (string memory) {
    return NAME;
  }

  function symbol() external pure returns (string memory) {
    return SYMBOL;
  }

  function tokenURI(uint256 tokenId) external view returns (string memory) {
    require(_nftData._exists(tokenId));

    string memory baseURI = _nftData.baseUri;
    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), URI_SUFFIX)) : "";
  }

  function setBaseUri(string memory newBaseUri) external onlyOwner {
    _nftData.baseUri = newBaseUri;
  }

  function approve(address to, uint256 tokenId) external {
    address owner = ownerOf(tokenId);
    require(to != owner && (msg.sender == owner || isApprovedForAll(owner, msg.sender)));
    _approve(to, tokenId);
  }

  function getApproved(uint256 tokenId) public view returns (address) {
    require(_nftData._exists(tokenId));
    return _nftData.tokenApprovals[tokenId];
  }

  function setApprovalForAll(address operator, bool approved) external {
    require(msg.sender != operator);
    _nftData.operatorApprovals[msg.sender][operator] = approved;
    emit ApprovalForAll(msg.sender, operator, approved);
  }

  function isApprovedForAll(address owner, address operator) public view returns (bool) {
    return _nftData.operatorApprovals[owner][operator];
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public {
    // can't transfer if in battle
    require(_gameData.monsters[tokenId].inBattle == 0 && _isApprovedOrOwner(msg.sender, tokenId));
    _transfer(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public {
    safeTransferFrom(from, to, tokenId, "");
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) public {
    transferFrom(from, to, tokenId);
    require(LibMonstrosityERC721._checkOnERC721Received(from, to, tokenId, _data));
  }

  function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
    require(_nftData._exists(tokenId));
    address owner = ownerOf(tokenId);
    return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
  }

  function _transfer(
    address from,
    address to,
    uint256 tokenId
  ) internal {
    require(ownerOf(tokenId) == from && to != address(0));

    // _beforeTokenTransfer(from, to, tokenId);

    // Clear approvals from the previous owner
    _approve(address(0), tokenId);

    _nftData.balances[from] -= 1;
    _nftData.balances[to] += 1;
    _nftData.owners[tokenId] = to;

    emit Transfer(from, to, tokenId, "");

    // _afterTokenTransfer(from, to, tokenId);
  }

  function _approve(address to, uint256 tokenId) internal {
    _nftData.tokenApprovals[tokenId] = to;
    emit Approval(ownerOf(tokenId), to, tokenId);
  }

  function totalSupply() external view returns (uint256) {
    return _nftData.supply;
  }

  /// @dev Returns all NFTs in the given wallet
  function getTokenIDsInWallet(address walletAddress) external view returns (uint256[] memory _tokenIds) {
    uint256 addressTokenCount = balanceOf(walletAddress);
    _tokenIds = new uint256[](addressTokenCount);

    uint256 currentSupply = _nftData.supply;
    uint256 currentTokenId = 1;
    uint256 tokenIndex;

    while (tokenIndex < addressTokenCount && currentTokenId <= currentSupply) {
      if (ownerOf(currentTokenId) == walletAddress) {
        _tokenIds[tokenIndex] = currentTokenId;
        tokenIndex += 1;
      }

      currentTokenId += 1;
    }
  }

  function transferPrincess() external payable {
    // unlock princess and transfer to owner
    _approve(msg.sender, 1);
    safeTransferFrom(address(this), msg.sender, 1);
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

pragma solidity ^0.8.10;

import "../shared/MonstrosityGameStructs.sol";
import "../shared/ERC721DataStruct.sol";

abstract contract MonstrosityBase {
  address internal _owner;
  address internal _withdrawalAddress;
  uint256 internal _status;
  ERC721Data internal _nftData;
  GameData internal _gameData;
  mapping(bytes4 => address) internal _ds;

  // @todo SET THIS BEFORE DEPLOYMENT!!!!!!!!!!
  uint256 internal constant MINT_PRICE = 0.01 ether;
  uint256 internal constant MINT_PRICE_DISCOUNT = 75;
  uint256 internal constant MINT_PERCENT_PRIZE = 60;
  uint256 internal constant TRAIT_POINT_PRICE = 0.0025 ether;
  uint96 internal constant _NOT_ENTERED = 1;
  uint96 internal constant _ENTERED = 2;
  uint64 internal constant MAP_SIZE = 120;

  constructor() {
    _status = _NOT_ENTERED;
    _owner = msg.sender;
  }

  modifier onlyOwner() {
    require(_owner == msg.sender, "ERR_NOT_OWNER");
    _;
  }

  modifier nonReentrant() {
    // On the first call to nonReentrant, _notEntered will be true
    require(_status != _ENTERED, "ERR_REEANTRANCY");

    // Any calls to nonReentrant after this point will fail
    _status = _ENTERED;

    _;

    // By storing the original value once again, a refund is triggered (see
    // https://eips.ethereum.org/EIPS/eip-2200)
    _status = _NOT_ENTERED;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.10;

import "../interfaces/IERC165.sol";

abstract contract ERC165 is IERC165 {
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IERC165).interfaceId;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.10;

import "./IERC165.sol";
import "./IERC721TransferEvent.sol";

interface IERC721 is IERC165, IERC721TransferEvent {
  event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
  event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

  function balanceOf(address owner) external view returns (uint256 balance);

  function ownerOf(uint256 tokenId) external view returns (address owner);

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  function approve(address to, uint256 tokenId) external;

  function getApproved(uint256 tokenId) external view returns (address operator);

  function setApprovalForAll(address operator, bool _approved) external;

  function isApprovedForAll(address owner, address operator) external view returns (bool);

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes calldata data
  ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.10;

import "./IERC721.sol";

interface IERC721Metadata is IERC721 {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "../shared/MonstrosityGameStructs.sol";
import "../shared/ERC721DataStruct.sol";
import "../interfaces/IERC721Receiver.sol";

library LibMonstrosityERC721 {
  function _exists(ERC721Data storage _nftData, uint256 tokenId) internal view returns (bool) {
    return _nftData.owners[tokenId] != address(0);
  }

  function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) internal returns (bool) {
    if (to.code.length <= 0) {
      return true;
    }

    try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
      return retval == IERC721Receiver.onERC721Received.selector;
    } catch (bytes memory reason) {
      if (reason.length == 0) {
        revert("ERR_NON_IMPLEMENTER");
      } else {
        assembly {
          revert(add(32, reason), mload(reason))
        }
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10 <0.9.0;

enum GameStage {
  Preparation,
  Recruitment,
  InitialCampaign,
  Recovery,
  FinalCampaign,
  Princess
}

struct Monster {
  uint256 id;
  uint256 location;
  uint64[4] traits; // 0: armor, 1: speed, 2: stamina, 3: agility
  uint64 totalTraits;
  uint64 potions;
  uint64 hp;
  uint64 inBattle;
}

struct BattleInfo {
  uint128 timestamp;
  uint128 location;
  uint64 id;
  uint64 area;
  uint32[4] opponentTraits;
}

struct Pools {
  uint256 prize;
  uint256 fees;
  uint256 dev;
}

struct GameData {
  uint256 startTime;
  /// @dev current campaign (0: initial, 1: final)
  uint64 campaign;
  /// @dev number of monsters ever entered to the game (not supply!)
  uint64 totalMonsters;
  /// @dev the total amount of trait points from all monsters
  uint128 traitPoints;
  /// @dev the count of the monsters IN the game (!= supply()!!!), one for each campaign
  uint128[2] monsterCount;
  uint128[2] killedMonsters;
  /// @dev save attributes for each monster (tokenId => monsterData)
  mapping(uint256 => Monster) monsters;
  /// @dev monster to location mapping (locationId => tokenId)
  mapping(uint256 => uint256) monsterLocations;
  /// @dev random location allocation cache
  mapping(uint256 => uint256) monsterLocationCache;
  mapping(uint256 => uint256) winners;
  /// @dev stores the list of monsters in the current battle
  uint128[] monstersInBattle;
  /// @dev current battle information
  BattleInfo currentBattle;
  Pools pools;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

struct ERC721Data {
  uint256 supply;
  // URI prefix
  string baseUri;
  // Mapping from token ID to owner address
  mapping(uint256 => address) owners;
  // Mapping owner address to token count
  mapping(address => uint256) balances;
  // Mapping from token ID to approved address
  mapping(uint256 => address) tokenApprovals;
  // Mapping from owner to operator approvals
  mapping(address => mapping(address => bool)) operatorApprovals;
  // Merkle Tree roots
  mapping(uint256 => bytes32) merkleRoot;
  // whitelist mint count
  mapping(uint256 => mapping(address => uint256)) whitelistMints;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.10;

interface IERC165 {
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IERC721TransferEvent {
  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId, bytes32 name);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.10;

interface IERC721Receiver {
  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external returns (bytes4);
}