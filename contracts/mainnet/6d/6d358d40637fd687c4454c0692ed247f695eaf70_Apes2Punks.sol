// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Base64.sol";
import "./Apes5.sol";
import "./Apes4.sol";
import "./Apes3.sol";
import "./Apes2.sol";
import "./Apes1.sol";
contract Apes2Punks is ERC721Enumerable, Ownable {
  using Strings for uint256;

   struct Ape { 
      string name;
      string description;
      string num1;
      string num2;
      string num3;
      string num4;
      string num5;
      string num6;
      uint256 timestamp;
   }
   
   mapping (uint256 => Ape) public apes;
   uint256 public cost = 1 ether;
   
   constructor() ERC721("Apes 2 Punks", "A2P") {}

  // public
  function mint() public payable {
    uint256 supply = totalSupply();
    
    Ape memory newApe = Ape(
        string(abi.encodePacked('Apes 2 Punks #', uint256(supply + 1).toString())), 
        "Apes 2 Punks are dynamic, on-chain generated, evolutional NFTs. The Apes are living on the blockchain and evolving as time passes. The NFT's image is dynamic and changes as the Ape evolves into a Punk. The price is also dynamic and with every mint call on the smart contract, the price is increasing by 10%. It is a self-contained mechanism for generating NFTs.",
        randomNum(361, block.difficulty, supply).toString(),
        randomNum(361, block.timestamp, supply).toString(),
        randomNum(361, block.difficulty, block.timestamp).toString(),
        randomNum(361, block.difficulty+10, supply).toString(),
        randomNum(361, block.timestamp, supply+20).toString(),
        randomNum(361, block.difficulty+30, block.timestamp).toString(),
        block.timestamp
        );
    
    if (msg.sender != owner()) {
      require(msg.value >= cost);
    }
    
    apes[supply + 1] = newApe;
    _safeMint(msg.sender, supply + 1);
    cost = (cost * 110) / 100;
  }

  function randomNum(uint256 _mod, uint256 _seed, uint _salt) public view returns(uint256) {
      uint256 num = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, _seed, _salt)));
      num = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, _seed, _salt, num))) % _mod;
      return num;
  }
  
  function buildImage(uint256 _tokenId, uint256 maturity) public view returns(string memory) {
      Ape memory currentApe = apes[_tokenId];
      bytes memory imagePart1;
      bytes memory imagePart2 = bytes(
            abi.encodePacked(
                '<defs>',
                '<linearGradient cx="0.25" cy="0.25" r="0.75" id="grad1" gradientTransform="rotate(45)">',
                '<stop offset="0%" stop-color="hsl(',currentApe.num4,', 20%, 15%)"/>',
                '<stop offset="50%" stop-color="hsl(',currentApe.num5,', 20%, 15%)"/>',
                '<stop offset="100%" stop-color="hsl(',currentApe.num6,', 20%, 15%)"/>',
                '</linearGradient>',
                '</defs>'
            )
        );
      bytes memory imagePart3;
      if(maturity == 0) {
        imagePart1 = bytes(
            abi.encodePacked(
                '<svg version="1.0" xmlns="http://www.w3.org/2000/svg" width="500pt" height="500pt" viewBox="0 0 250.000000 500.000000" preserveAspectRatio="xMidYMid meet">',
                '<g transform="translate(0.000000,610.000000) scale(0.100000,-0.100000)" fill="#000000" stroke="none">'
            )
        );
        
        imagePart3 = Apes1.Apes2String();
      }
      else if(maturity == 1) {
          imagePart1 = bytes(
            abi.encodePacked(
                '<svg version="1.0" xmlns="http://www.w3.org/2000/svg" width="500pt" height="500pt" viewBox="0 0 500.000000 500.000000" preserveAspectRatio="xMidYMid meet">',
                '<g transform="translate(-100.000000,630.000000) scale(0.100000,-0.100000)" fill="#000000" stroke="none">'
            )
        );
          imagePart3 = Apes2.Apes2String();
      }
      else if(maturity == 2) {
          imagePart1 = bytes(
            abi.encodePacked(
                '<svg version="1.0" xmlns="http://www.w3.org/2000/svg" width="500pt" height="500pt" viewBox="0 0 500.000000 500.000000" preserveAspectRatio="xMidYMid meet">',
                '<g transform="translate(-335.000000,660.000000) scale(0.100000,-0.100000)" fill="#000000" stroke="none">'
            )
        );
          imagePart3 = Apes3.Apes2String();
      }
      
      if(maturity == 3) {
            imagePart1 = bytes(
            abi.encodePacked(
                '<svg version="1.0" xmlns="http://www.w3.org/2000/svg" width="500pt" height="500pt" viewBox="0 0 500.000000 500.000000" preserveAspectRatio="xMidYMid meet">',
                '<g transform="translate(-565.000000,680.000000) scale(0.100000,-0.100000)" fill="#000000" stroke="none">'
            )
        );
          imagePart3 = Apes4.Apes2String();
      }
      else if(maturity == 4) {
        imagePart1 = bytes(
            abi.encodePacked(
                '<svg version="1.0" xmlns="http://www.w3.org/2000/svg" width="500pt" height="500pt" viewBox="0 0 500.000000 500.000000" preserveAspectRatio="xMidYMid meet">',
                '<g transform="translate(-825.000000,694.000000) scale(0.100000,-0.100000)" fill="#000000" stroke="none">'
            )
        );
          imagePart3 = Apes5.Apes2String();
      }
    
      imagePart1 = bytes(
            abi.encodePacked(
                imagePart1,
                '<defs>',
                '<linearGradient cx="0.25" cy="0.25" r="0.75" id="gradBackground" gradientTransform="rotate(45)">',
                '<stop offset="0%" stop-color="hsl(',currentApe.num1,', 100%, 90%)"/>',
                '<stop offset="50%" stop-color="hsl(',currentApe.num2,', 100%, 90%)"/>',
                '<stop offset="100%" stop-color="hsl(',currentApe.num3,', 100%, 90%)"/>',
                '</linearGradient>',
                '</defs>'
            )
        );
      string memory svg = Base64.encode(bytes(
          abi.encodePacked(
              imagePart1,
              imagePart2,
              imagePart3
          )
      ));
      return svg;
  }
  
  function buildMetadata(uint256 _tokenId, uint256 maturity) public view returns(string memory) {
      Ape memory currentImage = apes[_tokenId];
      return string(abi.encodePacked(
              'data:application/json;base64,', Base64.encode(bytes(abi.encodePacked(
                          '{"name":"', 
                          currentImage.name,
                          '", "description":"', 
                          currentImage.description,
                          '", "image": "', 
                          'data:image/svg+xml;base64,', 
                          buildImage(_tokenId, maturity),
                          '"}')))));
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId),"ERC721Metadata: URI query for nonexistent token");
    Ape memory currentEgg = apes[_tokenId];
    if (block.timestamp <= currentEgg.timestamp + 180 days) {
        return buildMetadata(_tokenId, 0);
    }
    else if (block.timestamp > currentEgg.timestamp + 180 days && block.timestamp <= apes[_tokenId].timestamp + 360 days){
        return buildMetadata(_tokenId, 1);
    }
    else if (block.timestamp > currentEgg.timestamp + 360 days && block.timestamp <= apes[_tokenId].timestamp + 540 days){
        return buildMetadata(_tokenId, 2);
    }
    else if (block.timestamp > currentEgg.timestamp + 540 days && block.timestamp <= apes[_tokenId].timestamp + 720 days){
        return buildMetadata(_tokenId, 3);
    }
    else if (block.timestamp > currentEgg.timestamp + 720 days && block.timestamp <= apes[_tokenId].timestamp + 900 days){
        return buildMetadata(_tokenId, 4);
    }
    return buildMetadata(_tokenId, 4);
  }

  function setCost(uint256 _newCost) public onlyOwner() {
    cost = _newCost;
  }

  function withdraw() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
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
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

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
        uint256 length = ERC721.balanceOf(to);
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
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)
            
            // prepare the lookup table
            let tablePtr := add(table, 1)
            
            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            
            // result ptr, jump over length
            let resultPtr := add(result, 32)
            
            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

library Apes5 {
    function Apes2String() public pure returns (bytes memory) {
        return bytes(
          abi.encodePacked(
              '<rect height="10000" width="18000" fill="url(#gradBackground)"/>',
              '<path fill="url(#grad1)" d="M10479 6908 c-13 -18 -29 -39 -36 -46 -7 -7 -13 -15 -13 -16 0 -13 -23 -123 -27 -130 -3 -4 -9 -2 -14 5 -6 10 -9 3 -9 -21 -1 -28 -3 -32 -11 -18 -5 10 -6 36 -2 60 5 33 8 38 12 21 5 -17 11 -5 27 47 12 38 17 67 13 64 -5 -3 -9 2 -9 10 0 27 -24 7 -52 -42 -30 -53 -44 -114 -31 -134 5 -9 10 0 14 27 4 26 5 18 3 -22 -3 -33 -1 -63 4 -65 12 -5 53 -119 56 -158 9 -110 31 -159 43 -99 l6 32 21 -39 c19 -37 21 -38 24 -14 4 23 5 24 13 5 6 -15 8 -11 9 20 2 41 4 40 15 -9 6 -30 20 -26 27 9 l4 20 11 -20 c8 -16 5 -33 -13 -80 -22 -58 -23 -59 -25 -25 -1 21 -3 27 -6 16 -4 -15 -7 -16 -14 -5 -7 12 -9 12 -9 -1 -1 -9 -6 -5 -15 10 l-14 25 -1 -28 c0 -16 5 -38 11 -49 6 -12 7 -23 2 -27 -5 -3 -10 -16 -10 -29 -2 -30 -42 -82 -95 -124 -71 -56 -108 -101 -119 -143 -6 -22 -14 -47 -17 -55 -11 -31 -13 18 -3 58 11 38 43 75 142 167 25 22 50 58 58 80 8 22 18 43 24 47 17 10 -12 95 -34 101 -12 3 -19 0 -19 -10 0 -9 6 -13 15 -9 27 10 29 -40 4 -102 -18 -44 -41 -74 -101 -131 -86 -82 -108 -119 -108 -183 -1 -36 -9 -53 -51 -108 -60 -78 -129 -217 -160 -320 -12 -41 -32 -89 -43 -106 -138 -203 -133 -186 -104 -354 23 -129 46 -355 54 -525 6 -125 4 -146 -14 -200 -11 -33 -26 -108 -33 -167 -15 -128 -11 -136 81 -191 66 -40 104 -42 115 -6 8 24 21 24 34 2 15 -27 30 -5 40 56 4 28 12 55 16 59 19 17 -7 -127 -49 -273 -48 -169 -66 -260 -66 -337 0 -50 -18 -79 -94 -148 -113 -101 -142 -158 -192 -365 -80 -333 -121 -428 -230 -538 -68 -68 -74 -78 -74 -115 0 -56 28 -84 125 -123 65 -26 91 -43 141 -95 55 -56 59 -63 40 -67 -11 -2 13 -5 54 -7 116 -4 153 -17 55 -20 -44 -1 -109 -6 -145 -10 -45 -6 -28 -6 56 -3 67 3 217 9 335 13 118 4 186 8 152 8 -35 1 -63 7 -63 12 0 6 -42 10 -107 10 -65 0 -103 4 -97 9 5 5 20 11 34 14 24 4 24 4 -2 6 -17 0 -28 7 -28 15 0 8 -15 17 -34 20 -59 11 -107 59 -149 149 -21 45 -39 96 -39 113 0 43 50 158 133 304 142 249 225 360 322 433 21 16 36 31 34 33 -8 8 -111 -67 -145 -104 -18 -20 -28 -28 -23 -17 17 32 43 59 88 89 40 27 53 49 53 94 0 13 4 21 8 18 5 -3 9 14 11 37 1 24 8 45 17 50 7 4 14 16 14 26 0 9 8 26 18 37 28 32 82 140 82 165 0 19 2 21 10 9 7 -11 10 -5 11 25 1 39 2 39 9 10 7 -27 8 -24 10 20 2 41 3 45 10 25 7 -22 8 -20 9 15 2 40 2 40 16 15 l14 -25 1 36 c0 20 7 42 15 49 8 7 15 27 15 44 1 30 1 30 16 11 10 -13 13 -31 10 -49 -9 -46 -77 -173 -149 -280 -37 -55 -67 -104 -67 -110 0 -5 13 10 28 35 16 24 52 75 81 112 28 38 68 104 89 148 20 43 39 79 42 79 3 -1 31 -36 63 -78 32 -42 93 -115 137 -161 93 -97 109 -136 91 -214 -6 -27 -13 -81 -16 -120 -5 -76 -5 -78 24 53 6 25 8 30 6 11 -3 -18 -6 -70 -6 -115 -1 -62 -3 -74 -10 -51 -5 21 -6 13 -2 -25 9 -95 57 -192 146 -298 43 -51 99 -165 142 -292 42 -121 49 -165 40 -251 l-7 -69 -37 -2 -36 -1 35 -4 c56 -7 70 -42 18 -45 -28 -1 -26 -2 11 -7 48 -7 66 -27 29 -33 -13 -2 38 -8 114 -12 75 -5 142 -6 150 -3 7 3 -7 6 -32 7 l-45 3 45 8 c25 4 84 8 133 8 52 1 87 5 87 11 0 12 -14 18 -50 22 -14 2 -30 7 -37 11 -6 4 -15 3 -18 -3 -5 -8 -11 -8 -20 0 -7 6 -15 7 -17 3 -3 -4 -3 -2 -2 4 2 7 -12 36 -32 65 -19 29 -37 61 -40 70 -3 10 -10 18 -15 18 -6 0 -7 -6 -3 -12 6 -10 4 -10 -7 0 -7 6 -22 12 -32 12 -17 0 -18 -2 -6 -17 13 -17 13 -17 -13 0 -16 10 -29 13 -33 7 -19 -31 -45 2 -56 70 -5 35 -21 82 -35 104 -20 32 -25 35 -21 16 3 -14 8 -43 11 -65 5 -32 2 -29 -13 20 -13 40 -20 52 -21 35 0 -16 -13 7 -35 65 -19 50 -34 94 -32 99 2 5 13 -20 26 -55 27 -76 46 -101 37 -49 -17 95 -26 120 -44 120 -12 0 -13 3 -4 12 9 9 7 14 -5 23 -14 10 -14 12 0 12 14 0 89 -155 147 -307 12 -30 26 -59 31 -65 11 -11 12 1 0 23 -4 9 -11 31 -14 47 -5 23 0 18 19 -20 29 -58 26 -34 -5 43 -12 29 -17 51 -12 48 5 -4 15 -23 21 -44 17 -52 30 -63 30 -25 0 17 -6 38 -13 45 -29 31 -51 75 -52 108 -3 75 -65 226 -77 189 -2 -7 -19 41 -36 107 -18 65 -44 147 -59 182 -21 53 -23 69 -14 89 6 13 16 21 22 17 7 -4 9 1 5 15 -3 11 -9 31 -12 42 -4 14 -2 19 5 15 14 -9 14 -13 -9 69 -11 38 -20 82 -20 97 0 15 -4 29 -9 33 -11 6 -42 65 -35 65 3 0 17 -13 31 -30 24 -29 63 -41 63 -20 0 6 5 10 10 10 6 0 10 -8 10 -18 0 -10 4 -22 9 -27 5 -6 23 -93 41 -195 43 -247 99 -477 168 -683 50 -151 60 -172 87 -189 61 -37 140 -60 220 -63 l80 -4 -63 9 c-79 11 -154 35 -208 66 -38 21 -44 31 -77 122 -53 148 -123 401 -151 547 -74 382 -81 425 -73 447 12 32 1 122 -23 193 -12 33 -37 119 -56 190 -69 254 -112 351 -238 540 -75 111 -86 134 -81 160 3 17 9 66 14 110 5 44 16 100 25 125 9 25 21 79 27 120 5 41 12 87 15 102 l6 28 46 -39 c26 -22 92 -71 147 -108 115 -79 136 -109 137 -188 1 -45 4 -56 20 -61 11 -3 22 -3 25 0 3 3 14 1 25 -5 13 -7 29 -7 47 -1 18 6 34 6 45 0 14 -8 16 -6 10 19 -18 81 -27 109 -39 123 -8 8 -14 18 -14 23 -1 4 -3 6 -4 5 -2 -2 -11 3 -19 10 -9 7 -22 10 -31 6 -20 -7 -28 -41 -12 -54 22 -18 27 -71 9 -92 -26 -27 -46 -24 -34 7 6 15 6 26 0 30 -6 4 -6 14 1 27 6 11 7 18 1 14 -5 -3 -17 12 -27 34 -10 22 -35 51 -56 66 -22 15 -37 29 -34 32 3 3 19 -4 35 -16 16 -12 34 -22 40 -22 12 0 14 50 3 77 -6 14 -9 11 -15 -17 -6 -30 -6 -28 -4 12 2 26 0 45 -5 42 -5 -3 -9 5 -10 18 -1 23 -1 23 -9 -2 -8 -24 -8 -24 -9 7 -1 17 -4 39 -7 48 -6 15 43 -28 188 -165 54 -51 59 -60 73 -125 22 -107 21 -121 -16 -134 -18 -6 -46 -11 -63 -12 -28 0 -29 -1 -9 -9 15 -6 39 -4 70 5 56 17 64 22 81 52 17 32 15 45 -14 84 -14 19 -34 52 -44 75 -12 28 -50 68 -121 130 -93 81 -114 106 -225 270 l-122 181 24 73 c13 40 24 79 24 86 0 7 11 30 25 51 23 33 25 44 20 93 -11 88 -33 165 -93 323 -38 100 -69 163 -93 192 -29 36 -36 52 -37 92 -1 26 2 64 6 83 7 33 10 34 47 32 22 -1 51 3 64 10 28 15 71 122 71 177 0 24 7 42 19 53 19 16 19 19 4 58 -14 35 -15 48 -4 90 8 32 10 72 6 113 -5 46 -3 71 6 88 7 13 14 26 14 29 1 3 5 18 10 33 6 21 3 33 -9 45 -16 16 -17 16 -10 0 3 -11 1 -18 -5 -18 -6 0 -11 -6 -11 -13 0 -7 -14 -21 -31 -31 -31 -18 -31 -18 -25 2 5 16 1 21 -26 27 l-33 8 45 7 c28 4 39 9 30 13 -30 13 -115 12 -106 -1 3 -5 -15 -6 -40 -2 -44 7 -44 7 -24 -12 25 -23 17 -40 -14 -32 -14 3 -32 -3 -51 -17 l-30 -23 30 33 c30 33 30 33 5 26 l-25 -7 24 17 c16 12 19 20 11 25 -17 11 -151 5 -182 -8 -28 -11 -65 -72 -79 -127 -7 -29 -7 -29 -8 9 -1 25 8 56 25 85 l25 46 -31 -35 c-32 -36 -50 -84 -50 -135 0 -33 -15 -63 -26 -53 -12 12 16 129 40 167 35 56 38 61 32 61 -2 0 -15 -15 -27 -32z m471 -101 c0 -14 4 -16 19 -8 17 9 20 5 30 -34 14 -55 14 -112 1 -120 -14 -9 -12 -73 4 -117 l13 -37 -33 1 c-21 1 -34 6 -34 15 0 7 5 13 10 13 6 0 10 5 10 10 0 6 -8 5 -20 -2 -29 -19 -27 -58 4 -58 23 0 36 -16 36 -46 0 -8 -8 -14 -18 -14 -11 0 -27 -9 -37 -20 -21 -23 -4 -28 19 -5 35 36 36 -1 0 -40 -18 -20 -22 -30 -14 -35 9 -6 9 -13 1 -29 -16 -29 -65 -24 -69 7 -2 12 1 22 7 22 6 0 7 7 4 17 -4 11 -3 14 5 9 8 -5 10 -2 5 9 -4 11 -8 13 -12 6 -5 -7 -15 -4 -29 9 -28 26 -39 25 -46 -5 -4 -14 -11 -23 -17 -19 -6 4 -4 14 6 27 9 12 18 30 22 40 4 14 8 15 21 5 14 -12 14 -10 3 11 -16 29 -21 71 -10 71 5 0 9 5 9 11 0 6 -8 9 -18 7 -12 -4 -18 1 -18 13 0 11 7 17 18 16 10 -1 18 -5 18 -9 0 -4 4 -8 9 -8 4 0 6 11 3 25 -2 14 -8 25 -12 25 -14 0 -4 49 13 68 13 14 31 18 73 17 62 -1 70 5 52 34 -14 23 -41 20 -97 -11 -27 -16 -36 -17 -42 -6 -11 17 -11 28 0 28 6 0 9 9 8 20 -1 11 -5 20 -10 20 -4 0 -5 5 -1 11 4 7 14 0 26 -18 19 -26 19 -21 1 25 -5 14 -4 15 8 5 11 -9 14 -7 16 14 1 20 -1 23 -9 12 -8 -11 -9 -10 -4 4 3 10 6 22 6 26 0 4 16 7 35 7 27 -1 35 -5 35 -19z m-164 -732 c-2 -6 11 -26 29 -43 28 -28 32 -39 30 -75 -2 -45 36 -147 54 -147 15 0 15 -1 -14 65 -14 32 -24 59 -22 61 9 9 55 -115 50 -134 -3 -13 3 -27 17 -39 33 -28 51 -68 71 -167 13 -65 15 -93 7 -103 -7 -9 -7 -17 1 -27 9 -11 7 -20 -13 -42 -32 -38 -41 -26 -27 32 10 39 9 53 -5 93 -10 25 -23 53 -31 62 -7 8 -13 22 -13 29 0 7 -3 11 -6 8 -5 -5 4 -47 22 -111 5 -15 0 -17 -29 -14 -32 4 -34 2 -34 -27 0 -17 6 -39 14 -48 8 -9 13 -25 10 -35 -4 -15 -6 -14 -13 6 -7 23 -8 24 -15 5 -6 -15 -8 -12 -8 14 -1 17 -5 32 -11 32 -5 0 -10 9 -10 20 0 11 -4 20 -9 20 -5 0 -13 14 -16 31 -5 23 -9 28 -16 18 -6 -10 -9 -4 -9 19 0 17 5 32 10 32 6 0 10 6 10 13 0 23 -121 257 -133 258 -7 0 -22 2 -35 3 -18 2 -21 -1 -16 -13 4 -9 8 -41 10 -71 3 -42 2 -50 -6 -32 -12 27 -40 29 -47 2 -3 -11 -9 -20 -13 -20 -5 0 -13 -14 -19 -31 -6 -17 -14 -28 -19 -25 -9 5 -42 -28 -42 -44 0 -5 -6 -7 -12 -5 -7 2 -20 -1 -29 -8 -19 -15 -58 -74 -43 -64 7 4 15 0 18 -9 3 -8 2 -12 -3 -9 -13 7 -20 -6 -25 -49 -3 -21 -10 -44 -17 -52 -6 -7 -9 -23 -6 -34 3 -11 -4 -31 -16 -47 -32 -43 -37 -48 -37 -36 0 7 11 24 24 38 20 22 23 31 16 56 -6 18 -5 41 1 56 13 34 3 63 -22 63 -21 0 -22 1 -13 24 3 9 10 13 15 10 5 -3 9 0 9 5 0 6 6 11 14 11 8 0 17 11 20 25 4 14 11 25 16 25 17 0 42 73 36 105 -4 22 -3 26 4 15 5 -8 10 -24 10 -35 1 -18 2 -18 11 3 11 29 0 110 -12 90 -5 -7 -9 -9 -9 -4 0 5 8 18 18 29 16 19 16 19 -8 13 l-25 -7 25 20 c14 11 33 27 42 35 9 8 19 12 21 9 3 -2 11 12 18 31 17 47 34 45 59 -4 16 -31 25 -39 43 -37 12 2 26 13 32 25 5 12 13 22 18 22 4 0 3 10 -4 21 -8 15 -8 19 0 15 6 -4 14 0 17 9 4 8 16 21 28 27 20 10 20 10 6 -7 -14 -17 -14 -17 7 -7 31 17 32 17 54 -33 11 -25 22 -45 24 -45 3 0 2 25 -4 63 0 4 -17 23 -36 43 -37 36 -50 70 -15 39 25 -22 26 -9 3 19 l-18 21 23 -19 c12 -11 21 -25 18 -31z m-546 -258 c0 -7 -18 -38 -41 -68 -57 -76 -115 -193 -144 -294 -18 -63 -37 -102 -68 -143 -54 -70 -67 -94 -67 -123 0 -28 -43 -69 -48 -45 -4 21 96 189 128 216 4 3 23 57 44 121 37 116 103 246 158 313 32 39 38 43 38 23z m62 -291 c-6 -13 -7 -29 -1 -37 17 -28 -21 -137 -68 -198 l-37 -46 37 34 c39 37 77 50 77 28 0 -8 -12 -24 -27 -38 -16 -13 -22 -17 -15 -9 6 8 12 22 12 32 0 13 -11 5 -40 -26 -22 -24 -40 -50 -40 -59 0 -9 -5 -19 -12 -23 -8 -5 -9 -2 -5 10 4 9 0 31 -9 48 -9 16 -11 27 -5 24 16 -10 14 -2 -11 40 -12 21 -17 34 -10 30 19 -12 14 3 -15 42 -20 26 -22 32 -7 19 11 -9 23 -14 26 -11 3 3 9 0 14 -7 4 -8 3 -10 -4 -5 -18 11 -14 -10 5 -25 15 -12 16 -12 10 4 -4 10 -2 17 6 17 9 0 9 2 -1 8 -7 5 -10 15 -7 23 3 9 -3 24 -15 34 -25 22 -27 9 -2 -19 l17 -21 -23 20 c-33 27 -46 54 -27 51 8 -1 21 -8 27 -14 17 -17 33 -15 18 3 -7 8 -10 21 -7 30 4 8 2 17 -3 20 -13 8 -13 35 0 35 6 0 10 -7 10 -15 0 -8 8 -23 18 -33 18 -18 19 -18 40 5 12 14 22 31 22 38 0 8 7 21 16 29 14 15 17 15 31 0 12 -12 13 -20 5 -38z m643 -199 c-5 -24 -4 -28 4 -17 6 8 11 10 11 5 0 -6 -5 -16 -10 -21 -6 -6 -17 -45 -25 -88 -8 -42 -19 -86 -25 -96 -5 -10 -10 -41 -10 -68 0 -81 -25 -206 -40 -197 -14 9 -23 -16 -11 -28 21 -21 11 -30 -11 -11 -21 18 -21 18 2 -16 l24 -35 -29 25 c-26 23 -27 24 -16 3 6 -12 16 -25 21 -28 6 -3 10 -11 10 -18 0 -6 -7 -1 -16 11 -8 12 -20 19 -26 16 -7 -5 -8 -2 -3 7 6 11 5 11 -5 2 -13 -12 -5 -37 10 -28 5 3 12 0 16 -6 5 -8 3 -9 -6 -4 -8 5 -11 3 -8 -6 3 -8 10 -14 15 -14 6 0 14 -3 18 -7 9 -9 -16 -5 -32 5 -7 5 -13 4 -13 0 0 -5 6 -15 13 -22 9 -11 9 -12 0 -7 -7 4 -18 16 -24 28 -8 15 -8 19 0 14 15 -10 14 7 -1 22 -16 16 -31 15 -22 0 23 -36 3 -62 -25 -35 -8 6 3 -14 24 -45 21 -32 41 -56 44 -53 4 2 8 -6 8 -17 2 -20 1 -20 -19 -2 -21 19 -21 19 -15 -14 l7 -32 -42 40 c-27 25 -45 37 -52 30 -6 -6 -4 -15 4 -25 7 -8 10 -18 7 -21 -3 -3 11 -38 30 -77 32 -64 40 -93 42 -148 1 -8 11 -26 24 -39 21 -23 40 -52 139 -215 63 -104 109 -222 157 -402 22 -81 49 -175 61 -208 21 -61 38 -175 26 -175 -3 0 -20 12 -37 28 -17 15 -32 25 -33 22 -1 -3 -10 3 -19 12 -14 13 -16 26 -11 58 5 30 9 38 16 28 7 -9 8 -8 4 5 -3 10 -6 23 -6 28 0 5 -5 9 -11 9 -6 0 -19 10 -28 22 -21 25 -56 34 -47 12 4 -9 2 -12 -5 -8 -8 4 -9 -1 -5 -17 6 -22 6 -23 -7 -6 -8 9 -19 17 -24 17 -6 0 -19 11 -29 25 -18 24 -20 24 -32 8 -12 -16 -12 -14 -6 12 6 29 6 29 -9 10 -10 -12 -16 -15 -17 -7 0 7 -4 10 -10 7 -6 -4 -6 3 0 21 8 21 7 31 -5 44 -22 25 -46 22 -39 -6 3 -12 1 -25 -4 -28 -7 -4 -9 11 -7 39 1 25 -1 48 -6 51 -5 3 -9 11 -9 19 0 14 24 15 37 0 5 -4 2 -5 -6 0 -11 6 -13 4 -8 -9 4 -10 7 -23 7 -30 0 -15 30 -17 46 -4 8 6 11 3 10 -9 0 -9 9 -22 22 -29 13 -6 35 -29 49 -50 32 -48 48 -65 40 -42 -4 13 -1 16 14 13 13 -3 19 0 16 8 -3 7 -9 11 -15 10 -7 -2 -9 4 -5 13 4 12 2 15 -8 12 -8 -3 -13 -11 -11 -17 1 -7 -2 -10 -7 -6 -6 3 -8 12 -5 19 3 8 1 17 -5 21 -6 3 -11 14 -11 23 0 9 -27 55 -60 101 -73 102 -69 99 -68 70 1 -21 31 -64 96 -141 13 -16 13 -18 -2 -18 -9 0 -21 12 -26 26 -6 14 -14 23 -19 19 -5 -3 -13 0 -17 6 -4 8 -3 9 4 5 7 -4 12 -3 12 2 0 13 -25 33 -33 27 -4 -3 -5 -2 -2 1 7 10 -15 45 -24 39 -5 -2 -15 3 -22 13 -13 15 -12 16 4 3 21 -16 23 1 2 19 -8 7 -15 9 -15 4 0 -4 -12 3 -26 17 l-26 24 7 -25 c10 -37 35 -71 45 -65 5 3 11 1 15 -5 4 -6 11 -7 17 -4 7 4 8 2 4 -5 -6 -9 -11 -9 -24 1 -13 11 -15 11 -10 -3 3 -9 2 -22 -4 -30 -8 -12 -10 -12 -15 0 -3 8 -16 24 -29 36 -28 26 -31 37 -6 28 15 -6 15 -5 3 10 -7 9 -17 15 -20 12 -4 -2 -8 2 -8 10 0 8 5 15 11 15 5 0 -3 15 -20 33 -16 17 -36 41 -44 53 -8 11 -3 7 12 -9 27 -30 27 -30 26 -6 -1 14 -22 45 -51 76 -28 29 -46 56 -42 62 4 7 1 20 -5 29 -7 9 6 -3 29 -28 53 -59 53 -42 0 22 -32 37 -44 46 -51 36 -7 -9 -8 -8 -4 6 4 10 1 26 -5 35 -7 9 11 -9 39 -39 28 -30 51 -50 52 -44 0 6 -12 21 -26 35 -30 28 -88 108 -82 114 2 3 22 -18 43 -45 22 -28 44 -50 49 -50 5 0 1 9 -9 20 -12 14 -14 20 -5 20 7 0 -8 22 -34 50 -54 57 -62 79 -11 30 47 -45 57 -30 15 23 -19 23 -24 33 -12 23 33 -29 26 -7 -10 33 -18 20 -23 27 -10 17 34 -29 26 -6 -13 39 -37 43 -41 55 -25 86 7 12 7 19 1 19 -14 0 -24 -38 -17 -68 6 -26 6 -26 -9 -8 -19 25 -19 29 5 76 22 44 25 54 10 45 -12 -7 -12 -3 -4 19 3 9 11 13 17 9 7 -4 8 0 4 13 -5 14 -2 12 13 -6 11 -14 20 -29 20 -34 0 -5 3 -7 6 -4 3 4 1 15 -4 25 -7 13 -6 22 4 31 8 7 14 10 14 6 0 -4 10 1 22 12 12 10 18 14 15 7 -10 -16 2 -43 19 -43 8 0 17 -6 20 -14 3 -8 12 -17 20 -20 12 -4 12 -2 4 14 -6 11 -14 20 -18 20 -12 0 -13 82 -1 96 6 7 7 19 3 26 -11 18 -12 48 -2 48 5 0 -7 19 -26 42 -20 23 -36 47 -36 54 0 7 -6 14 -12 17 -10 3 -10 8 -2 17 9 9 15 7 27 -10 14 -20 15 -20 19 -3 2 10 -12 39 -30 66 -32 45 -38 84 -10 75 6 -2 20 4 31 15 18 18 20 18 38 1 10 -9 19 -12 19 -6 0 6 -4 14 -10 17 -5 3 -10 11 -10 16 0 6 4 8 9 4 5 -3 16 1 24 9 8 8 17 12 21 9 3 -4 6 0 6 7 0 10 4 9 13 -3 9 -12 16 -14 27 -6 11 8 12 12 3 16 -22 8 -14 25 10 23 12 -1 24 -1 27 0 3 1 18 4 35 6 34 6 59 24 48 34 -23 21 -71 18 -106 -6 -56 -38 -92 -29 -45 12 19 15 20 16 9 2 -7 -10 -10 -18 -5 -18 10 1 54 36 54 43 0 8 -47 0 -68 -12 -15 -8 -22 -8 -25 2 -4 8 -12 4 -26 -13 -15 -18 -21 -21 -21 -9 0 8 5 20 12 27 8 8 8 12 1 12 -16 0 -31 -23 -28 -42 2 -11 -14 -30 -43 -51 -45 -33 -103 -56 -101 -40 1 5 1 10 -1 13 -7 19 -9 53 -2 42 6 -9 18 -7 51 9 24 11 41 22 38 25 -2 2 -17 -2 -33 -11 -33 -17 -48 -19 -40 -6 4 5 1 11 -6 13 -7 3 -5 7 6 11 11 4 15 3 10 -4 -11 -18 36 1 83 33 24 16 47 36 53 46 25 43 41 57 49 44 6 -10 10 -10 21 3 11 13 10 14 -5 9 -13 -5 -16 -4 -11 4 5 9 0 9 -21 1 -33 -12 -30 -9 22 27 32 21 36 22 21 5 -11 -11 -16 -21 -12 -21 13 0 56 37 50 43 -3 3 0 8 7 13 8 5 10 3 4 -6 -5 -8 -3 -11 6 -8 8 3 14 9 14 14 1 29 26 50 62 52 21 2 45 9 53 17 13 13 16 12 28 -11 8 -15 11 -38 7 -57z m-691 -189 c3 -29 8 -64 11 -78 3 -16 0 -12 -9 10 -8 19 -15 49 -15 67 -1 17 -5 35 -11 38 -19 12 -10 -57 20 -143 33 -97 35 -117 21 -322 -10 -150 -16 -175 -85 -335 -31 -72 -35 -167 -10 -203 9 -13 13 -30 10 -39 -10 -25 -16 -11 -37 84 -17 75 -18 99 -9 168 5 44 15 150 20 235 6 85 18 218 26 295 9 77 13 162 10 189 -4 38 -2 54 11 68 27 30 40 21 47 -34z m-134 -28 c0 13 1 13 10 0 13 -21 12 -39 -1 -20 -9 12 -10 11 -6 -8 3 -12 1 -20 -4 -16 -5 3 -9 1 -9 -5 0 -18 20 -23 26 -6 6 13 8 14 15 3 5 -7 9 -17 9 -23 0 -5 -5 -3 -10 5 -9 13 -10 13 -10 0 0 -8 5 -22 10 -30 8 -13 10 -12 11 5 1 11 2 28 1 38 -1 9 3 17 8 17 13 0 13 -21 -5 -170 -16 -141 -48 -524 -49 -585 0 -22 8 -78 18 -124 12 -56 16 -99 11 -130 -11 -73 -12 -85 -14 -103 0 -10 -6 -18 -12 -18 -10 0 -9 91 1 135 5 22 -12 53 -26 48 -8 -3 -21 0 -29 7 -8 6 -19 9 -25 5 -5 -3 -10 2 -10 12 0 15 -2 16 -10 3 -5 -8 -10 -10 -10 -5 0 24 21 33 47 20 58 -30 59 -19 23 250 -11 83 -20 151 -20 153 0 2 -4 1 -9 -2 -4 -3 -12 -34 -15 -68 -9 -76 -22 -62 -29 32 -2 36 -2 53 0 38 2 -16 8 -28 12 -28 4 0 4 26 -1 57 -5 31 -7 64 -5 72 3 9 5 2 6 -16 0 -17 5 -35 11 -38 6 -4 7 6 4 27 -5 27 -4 31 6 21 11 -10 17 -8 32 9 10 12 19 26 19 32 1 6 3 29 5 50 2 22 7 42 12 45 4 3 9 20 10 38 1 18 7 44 12 59 13 33 2 51 -16 27 -13 -17 -13 -17 -12 2 0 11 4 34 7 50 5 20 1 46 -11 78 -21 57 -23 71 -3 37 8 -14 14 -19 14 -10 0 8 -6 26 -14 40 -8 14 -14 30 -14 35 0 6 8 -6 19 -25 11 -19 19 -28 20 -20z m-145 -2217 c-36 -89 -111 -303 -105 -303 3 0 17 29 29 65 13 36 24 65 26 65 1 0 2 -13 0 -30 -1 -16 -37 -99 -80 -184 -84 -165 -96 -217 -63 -268 8 -13 25 -49 37 -80 16 -40 33 -64 55 -77 17 -11 42 -32 54 -46 17 -19 31 -26 47 -23 20 4 22 3 12 -14 -20 -30 -59 -18 -85 27 -6 11 -12 14 -12 7 0 -10 -4 -10 -16 2 -22 23 -37 20 -24 -3 14 -27 13 -31 -8 -31 -31 0 -64 43 -56 74 4 16 2 26 -5 26 -6 0 -11 14 -11 30 0 30 -14 41 -23 18 -3 -7 -6 -1 -6 13 -1 14 -4 29 -8 33 -5 4 -9 12 -9 17 -3 22 -7 22 -14 -1 -8 -25 -8 -25 -9 -2 -1 25 -25 55 -35 45 -3 -4 -6 2 -7 13 -1 15 -3 13 -9 -6 l-8 -25 -1 26 c-1 19 5 29 22 34 17 5 18 8 6 12 -29 7 -39 46 -22 81 9 18 22 32 29 32 8 0 14 8 14 18 0 14 -2 15 -10 2 -5 -8 -10 -10 -10 -4 0 18 12 24 26 13 11 -9 16 -5 24 17 22 61 33 85 36 81 2 -2 -5 -30 -16 -62 -35 -102 -20 -84 20 25 36 95 44 150 19 135 -5 -4 -9 -1 -9 4 0 6 4 11 8 11 5 0 16 15 25 33 15 27 17 28 13 7 -2 -14 -7 -36 -11 -50 -4 -14 18 25 49 85 67 132 66 125 -13 -69 -34 -82 -60 -153 -58 -159 2 -6 22 39 45 99 66 169 86 191 27 29 -19 -53 -30 -93 -26 -90 5 3 26 56 47 118 37 112 92 247 101 247 3 0 2 -8 -2 -17z m1246 -811 c0 -14 2 -14 8 2 5 14 10 16 15 8 4 -7 20 -12 37 -12 16 0 29 -5 29 -12 0 -10 3 -9 9 1 7 11 11 10 20 -5 6 -11 11 -15 11 -9 0 5 7 -1 16 -14 12 -17 19 -20 27 -12 9 9 17 5 30 -11 17 -21 18 -21 13 -3 -6 20 -6 20 9 1 19 -25 19 -13 0 24 -16 31 -32 42 -21 15 10 -27 -1 -16 -24 22 -12 20 -15 31 -7 25 7 -7 16 -10 19 -7 4 5 78 -98 78 -108 0 -2 -19 -9 -41 -16 -33 -10 -43 -10 -49 -1 -4 7 -13 9 -19 5 -7 -4 -18 -1 -26 5 -8 7 -21 10 -29 7 -10 -4 -12 1 -9 16 4 20 3 20 -12 -3 -15 -23 -15 -24 -10 -2 4 12 4 22 0 22 -3 0 -10 -10 -16 -22 -8 -20 -9 -19 -5 8 4 28 1 33 -25 45 -26 10 -32 10 -40 -2 -6 -10 -9 -2 -9 24 0 37 19 45 21 9z"/> <path d="M10860 4033 c0 -4 18 -33 40 -64 l40 -57 -31 -4 c-27 -4 -34 1 -61 39 -16 25 -32 42 -35 39 -3 -2 14 -29 36 -59 23 -29 41 -60 41 -68 1 -21 77 -122 95 -125 8 -1 15 0 15 3 0 4 -25 40 -56 80 -31 41 -53 77 -51 80 3 3 18 -14 33 -36 32 -49 55 -42 29 9 -31 59 4 20 42 -47 45 -81 55 -69 15 19 -42 92 -87 158 -122 179 -16 10 -30 16 -30 12z"/>',
              '</g>',
              '</svg>'
          ));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

library Apes4 {
    function Apes2String() public pure returns (bytes memory) {
        return bytes(
          abi.encodePacked(
              '<rect height="10000" width="12000" fill="url(#gradBackground)"/>',
              '<path fill="url(#grad1)" d="M8231 6596 c-8 -9 -26 -16 -41 -16 -17 0 -59 -23 -113 -60 -48 -33 -91 -60 -97 -60 -14 0 -57 -80 -64 -122 -4 -20 -11 -38 -15 -40 -13 -4 8 -110 26 -130 12 -13 14 -30 8 -75 -5 -51 -3 -64 20 -107 14 -26 35 -56 46 -65 18 -15 19 -20 9 -71 -7 -30 -14 -65 -16 -78 -6 -28 -52 -57 -126 -78 -32 -9 -55 -20 -53 -24 3 -5 -7 -19 -22 -32 -50 -42 -84 -102 -88 -154 -2 -27 -8 -60 -13 -75 -6 -15 -6 -31 -1 -41 7 -12 3 -24 -15 -42 -13 -14 -28 -26 -33 -26 -26 0 -115 -175 -157 -310 -25 -77 -38 -113 -90 -234 -15 -34 -15 -40 -2 -60 9 -11 39 -54 68 -95 29 -41 65 -82 80 -90 15 -9 37 -28 48 -43 12 -15 37 -35 56 -44 l35 -17 -7 -61 c-4 -38 -19 -88 -40 -132 -19 -39 -34 -78 -34 -86 0 -7 -8 -24 -17 -38 -10 -15 -17 -45 -18 -79 l-1 -56 -84 -28 c-47 -15 -139 -41 -204 -57 -66 -17 -124 -34 -130 -40 -5 -5 -20 -10 -33 -10 -29 0 -185 -51 -245 -81 -55 -27 -63 -45 -15 -34 17 4 48 11 67 15 48 10 217 58 457 128 185 54 203 58 216 43 40 -46 42 -59 37 -296 -2 -85 8 -171 35 -298 15 -75 15 -81 -2 -123 -13 -32 -25 -46 -43 -51 -14 -3 -36 -14 -50 -23 -14 -9 -37 -20 -52 -24 -46 -11 -132 -122 -188 -243 -10 -24 -23 -43 -28 -43 -4 0 -25 -34 -46 -76 -23 -47 -56 -93 -87 -121 -27 -26 -46 -49 -44 -52 3 -3 -14 -25 -37 -49 -28 -29 -36 -42 -23 -38 18 7 18 5 -3 -14 -12 -11 -29 -36 -37 -55 -7 -19 -28 -50 -45 -67 -16 -18 -28 -39 -25 -47 5 -11 3 -12 -10 -1 -8 7 -15 8 -15 3 0 -18 32 -54 62 -69 42 -22 71 -57 114 -139 20 -38 46 -80 57 -93 l20 -22 -59 1 c-44 1 -53 3 -34 9 14 4 -15 5 -65 3 -49 -3 -94 -9 -98 -13 -5 -4 139 -6 319 -4 322 3 447 12 223 16 l-114 2 85 6 85 6 -72 2 c-43 1 -73 7 -75 13 -3 9 -10 9 -26 0 -15 -8 -22 -8 -22 -1 0 6 7 13 15 16 25 10 17 24 -13 24 -34 0 -52 16 -52 46 0 12 -15 44 -34 71 -18 26 -36 58 -40 70 -9 28 25 107 53 125 12 7 21 18 21 25 0 11 69 81 127 128 44 36 79 70 89 86 13 21 136 119 151 119 6 0 31 23 54 50 24 29 45 46 49 40 4 -6 34 18 69 55 34 36 67 65 71 65 5 0 25 16 44 35 39 39 76 111 76 148 0 14 7 30 16 38 8 7 13 21 11 30 -3 10 1 20 8 23 11 4 19 29 32 101 10 56 53 175 63 175 4 0 12 -12 19 -27 9 -19 15 -23 20 -14 6 10 10 9 14 -4 4 -9 3 -13 -3 -10 -19 12 -10 -18 13 -40 74 -72 148 -156 157 -179 5 -15 7 -67 4 -124 -8 -128 -7 -159 4 -207 10 -40 10 -39 12 25 l3 65 7 -55 c3 -30 18 -78 32 -105 15 -28 36 -83 47 -124 11 -41 25 -78 31 -81 6 -4 14 -21 20 -38 14 -50 -16 -27 -45 34 l-24 49 6 -50 c3 -27 16 -70 28 -95 13 -25 26 -68 30 -95 4 -28 16 -78 27 -112 19 -57 20 -71 10 -150 -7 -49 -9 -98 -6 -110 l6 -23 -198 -2 -199 -2 210 -6 c175 -5 192 -6 100 -10 -155 -5 -154 -5 -161 -12 -3 -4 61 -4 143 -1 102 4 156 2 169 -5 15 -9 -9 -12 -106 -13 -332 -4 -338 -15 -10 -17 190 -1 451 -3 580 -6 129 -2 211 -2 181 1 -49 4 -52 5 -35 19 18 15 18 15 1 10 -28 -9 -492 -20 -513 -12 -16 6 -16 9 -4 17 9 6 65 8 145 4 106 -6 142 -4 187 10 66 19 82 33 70 65 -7 18 -17 23 -45 24 -32 1 -36 -2 -31 -18 4 -12 2 -16 -5 -12 -6 4 -11 2 -11 -4 0 -6 -4 -9 -9 -5 -5 3 -12 1 -16 -5 -9 -15 -21 -12 -41 7 -10 10 -20 18 -23 18 -3 1 -16 6 -27 13 -22 12 -34 7 -34 -12 0 -6 5 -4 10 4 7 11 10 11 10 2 0 -7 5 -10 11 -6 7 4 7 -2 -1 -17 -17 -33 -24 -38 -16 -12 5 16 3 21 -9 19 -9 -1 -20 -8 -24 -15 -11 -17 -32 43 -25 67 3 9 -2 6 -10 -8 -16 -27 -22 -55 -6 -30 6 9 10 10 10 3 0 -17 -14 -23 -29 -14 -10 7 -10 14 3 39 18 36 20 46 6 37 -5 -3 -10 0 -11 7 0 7 -9 -5 -19 -27 -10 -22 -19 -35 -19 -28 -1 7 4 24 11 38 9 19 9 28 0 37 -9 9 -15 3 -27 -23 -10 -22 -14 -25 -11 -10 3 13 -4 46 -15 74 -19 48 -18 77 1 47 7 -11 10 -12 10 -2 0 24 17 3 23 -28 10 -49 114 -105 232 -125 52 -9 39 4 -17 16 -24 6 -68 21 -98 35 -47 21 -59 32 -82 77 -17 34 -29 75 -32 117 -9 93 -12 240 -6 240 3 0 5 141 5 313 0 231 -3 318 -12 334 -7 12 -13 35 -13 51 0 45 -45 189 -80 257 -35 68 -34 31 1 -42 12 -24 19 -48 17 -55 -2 -6 -14 12 -27 42 -33 76 -48 50 -16 -28 14 -34 25 -70 25 -79 -1 -16 -2 -16 -17 2 -15 20 -15 20 -10 -3 4 -18 3 -21 -8 -12 -14 12 -26 70 -14 70 4 0 10 -6 12 -12 3 -8 6 -6 6 5 1 10 -6 20 -15 24 -8 3 -13 12 -10 19 11 29 -6 13 -19 -18 -8 -18 -14 -27 -15 -20 0 7 7 26 15 43 9 16 13 34 10 38 -3 5 0 11 7 13 9 3 5 20 -12 59 -24 55 -25 55 -42 35 -17 -21 -17 -21 -16 -1 0 11 -3 29 -7 39 -5 12 -5 17 1 13 6 -3 16 -1 24 4 13 9 13 10 0 6 -18 -5 -39 21 -40 48 0 18 -1 18 -16 -4 -13 -18 -18 -20 -25 -10 -12 20 -11 25 7 44 9 9 17 29 19 46 3 44 12 45 20 3 5 -28 9 -34 16 -23 5 8 9 9 9 3 0 -5 6 -19 14 -30 32 -42 10 33 -32 109 -23 42 -42 79 -42 83 0 10 -46 78 -88 131 -58 73 -52 80 132 136 l159 49 29 -29 c21 -21 31 -45 39 -90 12 -69 60 -146 85 -136 20 7 28 47 14 72 -18 35 -3 24 20 -15 18 -28 21 -46 18 -84 -3 -27 -1 -47 4 -44 4 3 8 0 8 -6 0 -6 11 -23 25 -37 l24 -27 12 30 c16 42 24 108 12 101 -6 -4 -13 -25 -16 -48 -3 -23 -11 -47 -17 -53 -16 -15 -3 93 14 113 8 11 8 15 -1 18 -7 3 -13 14 -13 26 0 12 -3 33 -7 46 -6 23 -7 23 -14 5 -6 -16 -8 -14 -10 11 -2 27 -3 26 -9 -10 l-7 -40 -2 42 c-1 44 -18 93 -33 93 -4 0 -8 9 -8 20 0 11 -4 20 -10 20 -5 0 -10 7 -10 16 0 8 -4 12 -10 9 -5 -3 -11 2 -12 12 0 10 -4 -4 -8 -32 l-8 -50 2 50 c1 42 4 50 21 53 24 3 80 -62 71 -83 -3 -9 9 -25 29 -41 24 -18 35 -34 35 -52 0 -16 10 -35 25 -47 28 -23 37 -95 17 -132 -7 -12 -12 -26 -12 -32 0 -21 15 -11 28 18 10 22 10 44 3 89 -12 72 -44 138 -110 226 -27 36 -47 67 -43 70 23 13 328 106 350 106 14 0 46 8 70 17 36 14 45 14 52 3 7 -11 12 -11 23 -2 7 6 56 35 108 63 84 45 90 50 54 45 -22 -3 -81 -11 -132 -18 -62 -7 -90 -15 -87 -23 7 -16 -35 -33 -112 -45 -35 -6 -82 -17 -102 -25 -20 -8 -66 -21 -102 -30 -36 -9 -85 -23 -108 -31 -42 -14 -45 -13 -68 8 -40 37 -114 135 -114 152 0 8 -38 55 -85 104 -47 49 -85 95 -85 102 0 9 3 10 14 1 11 -10 15 2 21 66 5 43 10 87 11 98 2 11 6 59 8 107 3 48 10 97 16 109 29 53 -17 263 -81 375 -16 28 -29 61 -29 74 0 23 -29 80 -41 80 -4 0 -10 12 -13 26 -5 17 -12 24 -21 20 -15 -6 -16 14 -1 25 4 4 1 17 -8 31 -10 16 -14 35 -10 58 l6 35 73 1 c58 0 78 5 99 22 44 34 65 67 72 111 5 34 4 41 -10 41 -9 0 -16 -7 -16 -15 0 -8 5 -15 10 -15 6 0 10 -4 10 -10 0 -5 -6 -10 -13 -10 -13 0 -45 76 -36 84 12 11 49 16 49 7 0 -6 5 -11 11 -11 8 0 10 12 6 34 -4 24 -1 39 9 47 12 10 11 16 -6 43 -29 47 -36 110 -16 140 18 29 12 56 -14 56 -21 0 -40 45 -41 99 -1 49 -29 94 -67 106 -18 6 -38 20 -47 30 -9 12 -14 15 -15 7 0 -8 -5 -10 -12 -5 -7 4 -35 11 -63 16 -27 4 -64 10 -81 13 -20 4 -34 1 -43 -10z m356 -336 c-1 -20 -7 -30 -18 -30 -24 0 -50 -61 -43 -99 4 -17 13 -31 21 -31 9 0 13 -8 11 -22 -2 -14 -10 -23 -20 -23 -9 0 -23 -8 -31 -19 -11 -16 -17 -17 -36 -6 -12 6 -29 9 -37 6 -8 -3 -14 -1 -14 5 0 9 20 19 65 34 17 5 15 10 -20 41 -35 31 -39 39 -39 84 0 57 3 61 42 66 15 2 39 8 52 13 14 5 35 10 47 10 19 1 22 -4 20 -29z m-517 -599 c0 -4 -9 -12 -20 -19 -21 -13 -28 -42 -10 -42 6 0 10 5 10 11 0 5 4 8 9 5 5 -3 7 -16 4 -29 -5 -18 -3 -20 8 -10 10 10 16 9 31 -4 10 -9 18 -23 18 -31 0 -8 6 -12 15 -8 12 4 15 -3 14 -37 -1 -25 -4 -32 -6 -18 l-5 23 -16 -23 c-11 -16 -12 -24 -4 -27 15 -5 16 -72 1 -72 -6 0 -9 9 -6 20 6 24 -5 26 -23 5 -7 -8 -18 -15 -24 -15 -6 0 -5 4 3 9 7 5 11 13 7 19 -3 6 0 16 7 24 22 22 39 58 27 58 -5 0 -10 -7 -10 -15 0 -9 -7 -18 -16 -22 -8 -3 -20 -16 -25 -29 -4 -13 -15 -24 -23 -24 -10 0 -13 6 -9 15 9 24 -17 14 -49 -20 l-29 -30 14 30 c17 34 67 84 67 67 0 -7 8 -5 20 5 11 10 20 24 19 33 0 10 -2 11 -6 3 -2 -7 -14 -13 -25 -13 -20 0 -20 1 -3 28 16 24 16 25 1 11 -10 -9 -19 -22 -20 -30 -5 -25 -18 -49 -26 -49 -4 0 -10 11 -12 25 -3 13 -1 23 5 22 5 -1 11 3 14 10 3 8 -3 11 -17 8 -18 -3 -20 -1 -14 18 4 12 10 23 14 25 4 1 5 15 3 30 -3 24 -2 25 7 7 8 -16 10 -13 6 17 -3 23 0 38 7 41 18 6 67 4 67 -2z m235 -82 c2 -35 9 -48 36 -70 19 -16 29 -29 23 -29 -18 0 -25 -27 -13 -52 9 -21 9 -21 4 4 -7 35 17 29 34 -8 13 -30 14 -37 2 -30 -13 8 12 -71 27 -86 16 -16 15 1 -3 32 -17 30 -21 65 -5 40 17 -27 12 9 -6 40 -14 22 -15 34 -6 66 l11 39 -5 -40 c-3 -24 -1 -35 4 -27 6 9 9 4 9 -15 0 -34 23 -85 41 -91 9 -3 11 9 7 49 -7 74 8 54 51 -67 35 -99 54 -227 34 -239 -13 -8 -25 16 -25 54 0 24 -7 38 -23 49 -23 15 -23 15 -17 -11 5 -20 3 -28 -9 -33 -9 -3 -16 -17 -16 -29 0 -28 19 -44 21 -18 1 17 2 17 6 1 2 -10 -5 -30 -16 -44 -12 -15 -21 -37 -21 -50 0 -12 -6 -35 -14 -51 -28 -54 -49 -113 -44 -119 6 -5 48 97 48 116 0 6 4 10 10 10 5 0 16 12 25 28 l16 27 -5 -40 -5 -40 14 30 c8 17 14 43 15 58 0 17 4 26 10 22 14 -9 7 -33 -35 -125 -19 -41 -37 -96 -40 -122 -3 -27 -11 -48 -16 -48 -6 0 -7 5 -4 10 3 6 -1 17 -9 26 -9 8 -16 12 -16 7 0 -9 -53 -43 -67 -43 -4 0 3 9 17 20 30 23 14 27 -18 4 -12 -8 -22 -11 -22 -6 0 5 14 15 30 22 17 7 30 17 30 22 0 5 -10 2 -22 -6 -28 -20 -42 -20 -35 -2 3 8 1 16 -5 18 -8 3 -6 17 6 47 9 24 15 46 12 49 -11 10 -29 -55 -30 -106 0 -38 -4 -51 -13 -47 -7 2 -13 -1 -13 -8 0 -7 -3 -23 -6 -37 -4 -20 -3 -22 5 -10 9 13 11 13 11 -1 0 -12 8 -16 31 -15 23 1 40 12 65 41 32 39 34 39 34 15 0 -15 -5 -31 -12 -38 -8 -8 -11 -45 -9 -111 1 -62 -2 -101 -8 -106 -6 -3 -11 -17 -11 -30 0 -17 -4 -23 -14 -19 -17 6 -31 -55 -16 -70 5 -5 10 -19 10 -29 0 -15 -3 -17 -14 -8 -11 9 -15 6 -19 -16 -3 -15 -1 -31 4 -34 5 -3 7 -13 3 -23 -6 -16 -8 -16 -25 0 -18 17 -19 15 -21 -37 l-1 -54 -7 60 -7 60 -1 -54 c-1 -30 -5 -51 -9 -47 -8 7 -6 73 3 120 5 21 3 27 -6 21 -10 -6 -11 -1 -5 21 5 16 9 54 10 84 2 76 9 92 54 117 45 26 62 16 37 -22 -17 -26 -21 -55 -8 -55 4 0 15 18 25 41 16 37 16 43 3 65 -10 14 -12 25 -6 29 11 7 14 48 4 58 -3 3 -17 2 -30 -3 -17 -7 -24 -6 -24 2 0 6 -10 2 -22 -9 -13 -11 -31 -23 -42 -27 -15 -5 -17 -2 -13 16 6 22 5 22 -8 5 -7 -11 -11 -25 -8 -33 3 -8 -1 -14 -9 -14 -23 0 -57 -47 -67 -91 -5 -23 -14 -46 -20 -52 -6 -6 -4 12 5 42 8 29 14 63 12 75 -2 21 23 58 37 56 4 -1 10 2 13 6 4 4 1 4 -5 0 -7 -4 -13 -3 -13 2 0 5 11 15 25 22 28 15 53 57 65 110 5 19 12 46 16 60 12 41 -9 13 -31 -42 -11 -29 -26 -53 -33 -56 -21 -7 -3 50 22 70 17 15 19 19 7 27 -10 6 -22 4 -38 -6 -27 -18 -28 -13 -7 33 9 19 23 34 30 34 8 0 14 2 14 4 0 2 2 11 5 18 3 8 -2 14 -14 15 -11 1 -21 -6 -24 -18 -3 -10 -10 -19 -16 -19 -14 0 -8 43 7 48 7 2 13 13 13 25 1 15 3 17 6 6 3 -13 11 -15 39 -9 30 7 34 5 34 -12 0 -11 4 -16 11 -12 6 3 8 17 5 30 -5 19 -2 24 14 24 11 0 20 4 20 10 0 5 7 7 15 4 8 -4 15 -1 15 5 0 6 9 11 20 11 25 0 26 16 1 29 -10 6 -22 18 -25 28 -6 16 -6 16 12 0 23 -21 39 -22 22 -2 -10 12 -10 15 1 15 10 1 9 4 -3 14 -10 7 -18 24 -18 37 0 18 -3 20 -12 11 -18 -18 -31 -15 -24 6 5 14 3 13 -10 -3 -16 -19 -16 -19 -11 10 4 17 4 24 1 18 -11 -25 -24 -13 -14 12 17 46 -4 175 -29 175 -5 0 -17 24 -26 53 -10 28 -22 57 -29 62 -6 6 -20 20 -30 33 -19 22 -19 23 0 40 18 16 70 19 60 4 -2 -4 2 -18 10 -32 8 -15 13 -19 14 -10 0 13 1 13 10 0 6 -10 7 3 3 40 -3 30 -2 52 2 48 4 -4 9 -26 10 -49z m100 -1149 c3 -5 12 -7 20 -3 23 8 46 -16 39 -42 -5 -20 1 -27 38 -46 64 -32 101 -60 91 -70 -12 -12 -185 -99 -197 -99 -24 0 -36 38 -27 84 5 25 6 57 4 71 -3 13 -2 45 1 70 7 43 18 56 31 35z m-474 -434 c-9 -11 -6 -13 14 -13 14 0 25 5 25 11 0 6 5 4 10 -4 9 -13 10 -13 10 0 0 13 1 13 10 0 5 -8 17 -15 27 -15 13 0 19 -12 25 -45 4 -25 6 -49 4 -55 -3 -5 -5 0 -5 13 -1 12 -7 22 -16 22 -8 0 -15 7 -15 15 0 8 -6 15 -14 15 -8 0 -17 8 -19 18 -3 12 -5 9 -6 -8 -2 -24 -2 -24 -13 -5 -11 19 -12 18 -19 -8 -4 -16 -4 -38 1 -50 5 -12 9 -17 9 -10 1 7 8 10 17 6 12 -4 14 -16 8 -59 -4 -37 -2 -59 6 -69 7 -8 9 -15 4 -15 -5 0 -3 -4 5 -9 10 -7 14 -30 14 -88 -1 -70 24 -234 26 -172 1 16 7 26 16 26 16 0 15 -21 -2 -81 -4 -14 -1 -18 11 -13 20 8 20 -4 2 -48 -17 -41 -31 -47 -22 -9 5 18 3 24 -5 18 -8 -4 -9 -3 -5 4 4 6 3 24 -1 39 -6 25 -8 22 -14 -26 -4 -29 -13 -58 -19 -65 -10 -8 -11 -5 -6 17 4 15 2 27 -3 27 -5 0 -13 20 -17 45 -3 25 -8 44 -11 41 -2 -2 -8 -35 -12 -73 l-8 -68 -2 62 c0 34 -5 64 -10 67 -5 3 -11 16 -14 28 -6 23 -6 23 9 3 13 -17 16 -18 24 -5 5 8 9 26 9 40 -1 23 -2 23 -9 -5 -4 -16 -8 -25 -9 -18 0 6 -4 18 -7 26 -3 8 1 21 9 28 22 23 30 69 12 69 -19 0 -19 9 2 32 20 23 30 23 36 1 3 -10 5 -1 6 20 1 49 -34 104 -55 86 -9 -8 -14 -8 -14 -1 0 6 5 14 10 17 6 4 8 11 5 16 -4 5 1 12 9 15 9 3 16 15 16 26 0 19 -1 19 -18 -3 -13 -15 -21 -19 -26 -11 -4 7 -2 12 4 12 9 0 9 20 -4 142 -1 10 -5 20 -8 24 -9 8 2 34 14 34 7 0 6 -5 -1 -14z m88 -128 c-4 -35 2 -68 14 -68 9 0 12 -23 12 -85 0 -47 2 -85 6 -85 14 0 17 27 9 71 -5 24 -6 69 -2 99 l6 55 7 -50 c4 -27 8 -72 8 -100 1 -34 4 -45 10 -36 5 8 7 30 4 50 -3 27 -2 32 6 21 9 -12 11 -10 11 10 1 18 5 13 17 -22 12 -36 13 -60 7 -105 l-9 -58 -3 60 -3 60 -21 -45 c-11 -25 -29 -57 -39 -72 -11 -14 -19 -34 -20 -45 -1 -10 -4 -4 -8 13 -5 17 -7 78 -5 135 1 57 -1 95 -5 84 -6 -15 -9 -11 -14 20 -10 59 -8 105 3 105 6 0 10 -6 9 -12z m-794 -1506 c-3 -3 -6 1 -6 9 -2 13 -9 -24 -25 -114 -4 -27 0 -51 15 -87 11 -27 21 -53 21 -59 0 -21 -18 -11 -27 14 -13 39 -38 15 -36 -34 1 -22 -2 -43 -7 -46 -5 -3 -8 3 -8 12 1 28 -22 142 -34 169 -8 18 -14 21 -20 12 -7 -13 -13 18 -9 50 1 8 -5 25 -14 39 -15 22 -15 26 0 49 8 13 20 24 26 24 5 0 3 -10 -5 -22 -25 -35 -19 -42 10 -11 18 20 23 22 16 8 -5 -11 -9 -34 -10 -52 -2 -31 -2 -32 27 -22 16 6 32 17 35 25 3 9 10 12 16 9 6 -3 10 5 10 19 0 13 3 32 7 42 6 15 7 14 15 -6 5 -13 6 -25 3 -28z"/>',
              '</g>',
              '</svg>'
          ));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

library Apes3 {
    function Apes2String() public pure returns (bytes memory) {
        return bytes(
          abi.encodePacked(
              '<rect x="-3000" height="10000" width="12000" fill="url(#gradBackground)"/>',
              '<path fill="url(#grad1)" d="M6005 6201 c-16 -5 -61 -23 -98 -40 -38 -17 -77 -31 -88 -31 -23 0 -89 -57 -89 -76 0 -8 -7 -26 -16 -39 -8 -13 -24 -62 -33 -110 -19 -89 -30 -116 -32 -74 -1 45 -49 -126 -49 -177 l0 -52 -97 -22 c-54 -13 -134 -36 -178 -51 -105 -37 -258 -65 -415 -75 -101 -6 -255 -40 -307 -68 -39 -20 -63 -52 -63 -85 0 -42 30 -108 54 -119 43 -19 133 -25 188 -11 29 7 60 13 68 14 18 1 133 46 140 54 10 11 56 30 90 37 19 3 55 16 80 27 90 39 341 129 346 124 2 -2 -21 -27 -51 -56 -30 -30 -55 -61 -55 -68 0 -8 -9 -28 -21 -44 -11 -16 -22 -41 -24 -54 -1 -14 -7 -30 -12 -37 -6 -7 -14 -31 -18 -53 -10 -53 -12 -344 -2 -348 4 -1 10 -67 13 -147 3 -80 12 -165 20 -189 7 -24 11 -47 9 -52 -3 -4 -9 -48 -14 -96 -6 -70 -14 -98 -37 -138 -17 -27 -38 -79 -48 -115 -10 -36 -22 -78 -27 -94 -18 -58 -9 -153 14 -139 6 3 7 1 3 -5 -4 -7 7 -25 24 -42 31 -31 32 -32 20 -81 -23 -94 -36 -238 -34 -360 3 -121 2 -123 -27 -166 -17 -23 -37 -43 -45 -43 -26 0 -104 -82 -171 -180 -36 -52 -68 -102 -71 -110 -3 -8 -18 -32 -34 -52 -16 -21 -27 -42 -24 -47 4 -5 -21 -45 -54 -88 -86 -112 -101 -129 -135 -146 -97 -49 -93 -151 7 -203 15 -8 29 -13 30 -12 8 7 49 -32 44 -41 -4 -6 2 -27 13 -48 10 -21 24 -57 31 -81 6 -24 13 -49 16 -57 4 -11 -7 -15 -48 -18 l-53 -3 57 -2 c56 -2 95 -22 42 -22 -15 0 -25 -2 -22 -5 11 -12 87 -16 318 -18 135 -1 214 1 175 4 -38 4 -105 7 -147 8 -111 2 -99 21 15 23 l92 2 -89 5 c-62 4 -91 10 -94 20 -3 10 14 12 91 10 52 -2 90 0 84 4 -7 4 -57 7 -112 5 -116 -3 -141 3 -149 37 -4 14 -13 25 -21 25 -9 0 -12 -6 -9 -15 4 -8 10 -15 15 -15 5 0 9 -4 9 -10 0 -5 -6 -10 -14 -10 -19 0 -32 60 -16 70 10 6 8 20 -6 61 -23 69 -23 150 1 186 28 43 117 133 125 128 4 -3 29 21 55 53 73 89 149 164 205 202 28 19 74 52 103 73 29 21 62 40 75 44 27 7 49 46 58 104 8 54 16 69 55 111 17 18 42 57 56 86 l25 54 29 -28 c16 -15 29 -24 29 -19 0 4 9 0 20 -10 11 -10 20 -24 20 -31 0 -17 48 -54 71 -54 32 0 69 -99 69 -185 0 -28 4 -55 9 -60 6 -6 12 -26 14 -45 5 -45 81 -218 118 -270 39 -54 104 -202 135 -309 29 -101 26 -180 -7 -188 -24 -7 -25 -20 -1 -26 9 -3 -21 -5 -68 -6 -47 -1 -90 -5 -97 -9 -6 -4 35 -6 92 -4 l104 4 7 -26 c3 -14 14 -27 23 -28 9 0 -4 -4 -29 -8 -40 -6 -37 -7 30 -8 41 -1 93 3 115 8 24 6 81 7 140 3 l100 -7 -125 -12 -125 -12 150 5 c83 3 152 10 153 14 2 5 21 9 42 9 45 0 90 18 90 36 0 8 30 14 98 19 53 3 102 8 107 11 6 2 -36 2 -92 -1 l-102 -6 -3 48 c-3 44 -5 48 -31 51 -16 2 -35 -2 -42 -8 -23 -19 -73 -4 -157 45 l-76 44 -35 88 c-61 153 -131 454 -157 673 -7 58 -19 115 -27 127 -9 14 -12 33 -8 56 7 34 -9 80 -40 117 -12 15 -28 73 -31 116 0 11 -8 31 -17 45 -9 13 -25 47 -36 75 -11 29 -36 77 -55 107 -20 31 -36 63 -36 72 0 20 -22 53 -83 130 -27 33 -55 76 -63 95 -8 19 -20 38 -27 42 -8 5 -7 8 6 8 9 0 17 -4 17 -9 0 -5 33 -30 73 -54 39 -25 84 -55 99 -66 14 -12 31 -21 36 -21 11 0 81 -83 97 -115 6 -11 16 -21 23 -21 47 -5 47 -5 24 -15 l-24 -9 26 -31 c14 -17 26 -37 26 -45 0 -8 5 -14 10 -14 6 0 10 3 10 6 0 12 -24 50 -38 60 -10 7 -11 13 -4 18 6 3 19 -5 30 -19 17 -21 22 -22 37 -11 17 12 17 14 0 39 -9 15 -15 33 -13 39 3 7 -4 21 -15 31 -18 19 -19 18 -12 -2 3 -12 2 -21 -3 -21 -13 0 -49 45 -57 71 -7 23 -6 23 7 5 9 -11 20 -16 27 -11 9 5 5 15 -15 36 -35 37 -20 38 20 2 20 -19 24 -20 12 -5 -11 12 -15 22 -10 22 17 -1 42 -25 46 -45 2 -13 11 -20 26 -19 15 0 22 -5 22 -17 0 -10 4 -20 9 -23 4 -3 6 -16 4 -30 -3 -13 0 -32 6 -43 9 -14 11 -8 7 32 -4 46 -3 48 10 30 9 -11 14 -34 12 -52 -5 -41 8 -43 15 -3 8 42 12 54 19 65 17 28 -81 166 -155 219 -58 41 -107 88 -102 96 3 5 -6 15 -20 24 -29 19 -39 20 -29 4 4 -7 -9 3 -29 21 -21 19 -37 37 -37 40 0 3 5 0 12 -7 7 -7 17 -12 22 -12 6 0 -21 31 -59 70 l-69 69 24 51 c13 28 26 46 30 40 6 -10 50 135 69 228 6 30 11 112 11 183 0 71 2 129 4 129 2 0 30 -12 62 -26 75 -33 234 -74 288 -74 51 0 103 31 112 66 10 40 -3 203 -18 222 -8 9 -8 13 -1 9 7 -5 9 0 6 13 -3 11 -9 17 -14 14 -5 -3 -6 2 -3 10 6 16 -9 50 -36 81 -10 11 -17 27 -17 35 0 8 -13 35 -29 59 -16 24 -47 72 -69 107 -22 34 -68 93 -103 129 -67 72 -68 82 -14 104 16 7 36 25 45 40 21 36 22 53 1 26 -13 -17 -16 -18 -25 -5 -8 12 -9 10 -4 -7 4 -14 2 -23 -4 -23 -6 0 -11 21 -10 48 0 76 -5 100 -24 112 -16 9 -19 8 -24 -9 -5 -21 -23 -30 -23 -12 0 27 16 42 51 47 60 10 68 27 32 72 -41 51 -53 76 -53 110 0 37 -22 57 -47 44 -10 -6 -35 -15 -56 -20 -36 -10 -41 -9 -63 15 l-24 26 6 -49 c9 -68 21 -80 50 -53 32 30 130 52 121 27 -2 -7 -10 -12 -16 -10 -6 1 -14 -5 -17 -13 -4 -8 -16 -15 -28 -15 -12 0 -31 -7 -42 -16 -16 -13 -16 -15 -1 -10 9 3 17 1 17 -4 0 -6 7 -10 15 -10 10 0 12 -6 8 -17 -6 -16 -5 -17 11 -3 18 14 18 13 11 -19 -5 -26 -4 -32 6 -29 8 3 14 16 15 29 1 13 2 26 3 29 2 3 4 15 5 27 3 27 17 43 23 26 2 -7 17 -31 33 -55 30 -45 30 -51 -7 -63 -19 -5 -23 -2 -23 15 0 12 5 18 10 15 6 -3 10 -1 10 4 0 6 -7 11 -15 11 -8 0 -15 -7 -15 -16 0 -9 -8 -22 -17 -29 -17 -13 -25 -65 -11 -75 10 -8 -2 -80 -13 -80 -5 0 -9 8 -10 18 -1 11 -4 9 -9 -8 -8 -25 -8 -25 -10 5 -3 28 -3 28 -8 5 -4 -23 -5 -24 -13 -5 -7 18 -8 17 -8 -7 -1 -15 -5 -29 -9 -32 -12 -7 -10 98 2 107 7 6 4 7 -6 3 -19 -6 -25 9 -8 19 13 8 4 41 -19 72 -19 27 -25 28 -44 9 -13 -13 -14 -6 -12 55 2 42 0 67 -6 63 -6 -3 -7 -15 -4 -27 2 -12 2 -16 -1 -9 -3 6 -10 9 -16 6 -11 -7 -11 -6 12 39 11 23 11 30 1 36 -9 6 -4 15 20 34 35 27 60 26 54 -3 -3 -17 22 -37 33 -25 3 3 0 5 -7 5 -9 0 -8 6 3 21 8 12 12 27 9 35 -7 19 27 31 38 13 4 -8 15 -23 24 -34 9 -11 7 -4 -4 15 -12 19 -28 52 -37 72 -12 26 -26 40 -48 47 -48 16 -108 21 -141 12z m-65 -848 c0 -5 -16 -25 -35 -46 -19 -21 -35 -43 -35 -48 0 -12 19 6 43 41 9 13 17 20 17 14 0 -6 -9 -23 -21 -38 -11 -14 -18 -26 -14 -26 3 0 -1 -11 -10 -23 -12 -19 -13 -33 -6 -63 5 -21 9 -31 10 -21 1 9 6 17 12 17 8 0 9 -15 4 -47 -4 -27 -9 -64 -10 -83 -1 -20 -8 -46 -15 -59 -22 -43 -51 -183 -43 -210 5 -14 6 -48 2 -76 -3 -27 -7 -42 -7 -32 -2 21 -22 23 -22 1 0 -8 -4 -13 -8 -10 -5 3 -10 26 -11 53 -1 26 -7 51 -14 55 -9 6 -8 8 3 8 21 0 46 68 31 83 -6 6 -7 17 -2 26 5 9 9 36 9 61 1 24 6 46 11 48 6 2 11 11 11 20 0 13 2 14 9 4 5 -9 11 13 15 58 8 79 4 94 -19 64 -12 -15 -14 -15 -9 -2 5 14 0 17 -27 15 -20 -1 -34 3 -37 12 -3 10 1 12 17 8 14 -3 21 -1 18 6 -2 7 -16 13 -30 15 -15 2 -25 7 -22 12 8 13 -21 67 -42 79 -10 6 -13 11 -6 11 6 0 24 -11 40 -24 30 -25 57 -22 58 6 1 7 6 12 13 11 17 -4 15 5 -9 38 -24 34 -9 39 20 7 18 -19 21 -19 27 -5 3 10 12 17 19 17 7 0 18 7 25 15 13 16 40 21 40 8z m69 -235 c1 -5 -6 -8 -14 -8 -8 0 -15 -5 -15 -11 0 -6 7 -9 15 -6 11 5 13 0 8 -26 -3 -18 -3 -29 1 -25 8 7 14 30 16 63 1 18 2 17 11 -4 6 -16 6 -28 -1 -35 -5 -5 -10 -17 -10 -25 1 -13 3 -12 15 3 13 18 15 18 21 2 5 -14 9 -15 15 -4 6 9 9 7 9 -9 0 -13 8 -24 20 -28 11 -3 20 -15 20 -26 0 -10 5 -19 11 -19 7 0 8 7 4 18 -13 31 -16 72 -7 72 6 0 13 -16 17 -36 10 -55 16 -34 9 30 -4 31 -9 54 -12 52 -6 -7 -42 39 -42 53 0 6 7 11 15 11 8 0 15 -7 15 -15 0 -8 4 -15 9 -15 13 0 31 -81 31 -137 0 -49 -32 -119 -49 -108 -5 3 -16 -2 -25 -11 -9 -8 -20 -12 -26 -9 -15 9 -12 25 5 25 13 0 14 2 3 14 -9 10 -17 11 -25 4 -10 -8 -13 -6 -13 6 0 21 -25 48 -35 38 -5 -4 -5 -1 0 7 4 7 3 16 -4 20 -6 4 -13 16 -15 27 -3 10 -16 42 -30 69 -27 53 -32 70 -17 61 5 -4 12 0 14 6 3 7 6 2 6 -11 1 -20 3 -21 16 -11 8 7 15 20 16 29 0 12 2 11 9 -4 5 -11 9 -23 9 -27z m97 -284 c-5 -12 -2 -15 10 -10 14 5 16 1 11 -29 -3 -19 -1 -37 4 -40 5 -4 9 -11 9 -16 0 -6 -4 -7 -10 -4 -6 4 -10 -5 -10 -20 0 -14 4 -24 8 -21 10 6 5 -51 -15 -151 -13 -67 -19 -81 -30 -72 -15 13 -18 53 -4 44 13 -7 22 49 18 100 -3 22 -5 46 -6 54 -1 11 -8 8 -23 -9 -20 -21 -23 -22 -26 -7 -2 9 -10 17 -18 17 -25 0 -7 17 25 23 33 7 49 36 26 49 -14 8 -14 11 0 24 19 20 19 54 0 54 -23 0 -18 18 8 23 12 2 24 5 26 6 2 0 0 -6 -3 -15z m-162 -594 c36 -39 78 -88 92 -110 15 -22 30 -40 34 -40 4 0 29 -28 56 -62 l49 -63 -54 47 c-30 26 -58 45 -63 42 -4 -3 -8 2 -8 12 0 12 -6 15 -25 12 -13 -3 -22 -1 -19 3 12 20 -9 30 -28 13 -19 -18 -19 -17 -9 8 8 22 7 26 -4 22 -8 -3 -21 6 -31 21 -9 14 -23 24 -30 21 -8 -3 -14 1 -14 8 0 7 -7 19 -15 26 -11 9 -12 15 -5 20 7 4 2 14 -11 26 -22 19 -22 19 -10 -3 9 -17 9 -23 0 -23 -8 0 -8 -4 1 -15 10 -12 9 -15 -5 -15 -15 0 -16 -2 -4 -17 9 -12 3 -10 -18 5 -18 13 -35 27 -38 32 -4 6 -11 10 -17 10 -6 0 -5 -7 3 -17 13 -16 12 -17 -4 -4 -9 8 -15 16 -12 19 3 3 -5 16 -17 29 -24 25 -20 43 5 19 8 -8 18 -12 22 -8 4 4 5 2 3 -4 -1 -6 12 -23 30 -38 24 -21 32 -24 32 -12 0 9 -4 16 -10 16 -5 0 -10 7 -10 16 0 8 5 12 10 9 6 -4 5 5 -2 19 -16 37 -3 43 33 17 29 -21 30 -22 20 -3 -30 56 -2 41 73 -38z m49 -508 c34 -57 62 -111 62 -121 0 -9 6 -16 12 -16 16 0 75 -92 98 -151 14 -36 15 -51 6 -71 -8 -18 -8 -22 0 -17 8 4 9 -1 5 -17 -6 -20 -5 -21 4 -6 6 9 8 22 5 27 -3 6 -2 10 3 10 4 0 16 -26 26 -57 10 -32 29 -75 42 -95 13 -21 25 -46 26 -55 3 -36 -2 -63 -12 -63 -5 0 -7 6 -5 13 3 6 -4 18 -15 25 -20 12 -20 11 -10 -7 9 -17 8 -20 -5 -15 -9 4 -25 24 -35 45 -24 46 -26 60 -5 33 15 -19 15 -19 8 1 -6 18 -5 18 10 6 21 -17 22 -2 2 25 -8 10 -15 27 -15 36 0 9 -5 20 -12 24 -7 5 -9 0 -6 -14 5 -18 3 -19 -16 -11 -25 12 -47 60 -41 91 4 21 -30 88 -44 88 -4 0 -13 12 -19 26 -7 14 -16 23 -21 20 -5 -3 -17 6 -26 20 l-17 27 -20 -32 c-20 -31 -21 -31 -41 -14 -19 18 -19 17 -12 -7 l8 -25 -21 25 c-13 16 -16 27 -10 31 6 4 8 14 5 24 -4 9 -12 13 -17 10 -11 -7 -65 43 -57 51 2 3 10 -2 16 -10 7 -8 20 -12 29 -9 15 4 15 3 2 -6 -15 -10 -13 -12 12 -15 7 0 17 -11 23 -22 15 -31 37 -55 43 -49 3 3 -3 14 -13 25 -10 11 -13 20 -7 20 6 0 16 -8 21 -17 6 -10 11 -14 11 -9 0 20 -52 96 -65 96 -8 0 -15 5 -15 10 0 20 -48 63 -64 57 -10 -4 -13 -1 -10 8 4 8 -8 29 -27 47 -18 18 -33 40 -34 48 0 8 -5 14 -10 13 -6 -1 -11 7 -11 18 0 24 16 9 43 -41 11 -19 24 -34 29 -33 5 1 17 -5 26 -14 32 -29 37 -8 8 34 -16 23 -25 45 -20 48 6 4 10 0 10 -8 0 -7 23 -38 50 -67 46 -49 65 -80 40 -65 -19 12 -10 -6 23 -45 17 -22 38 -40 45 -40 12 0 -42 86 -117 187 -13 17 -20 36 -17 42 11 16 26 13 20 -4 -4 -8 7 -27 25 -46 17 -17 31 -36 31 -43 0 -20 30 -56 47 -56 14 0 14 2 0 23 -9 12 -38 59 -66 105 -50 83 -44 93 11 18 37 -52 36 -36 -2 19 -16 24 -30 47 -30 51 0 21 48 -41 103 -134z m-1313 -1303 c0 -8 4 -8 14 0 10 8 16 9 21 1 3 -6 11 -7 17 -4 8 5 9 1 5 -10 -4 -11 -3 -15 4 -11 5 4 21 8 35 10 19 2 24 -1 20 -12 -10 -24 5 -36 20 -16 14 17 15 16 9 -7 -4 -18 0 -14 15 13 24 43 38 51 16 8 -17 -32 -16 -95 2 -113 9 -9 12 -8 12 4 0 9 7 31 15 49 l15 34 -5 -40 c-4 -30 -3 -35 4 -20 9 18 10 18 10 -7 1 -18 -5 -29 -19 -33 -31 -10 -24 -28 8 -21 25 7 26 6 7 -7 -11 -8 -31 -17 -43 -20 -22 -5 -23 -3 -17 21 4 15 3 24 0 20 -12 -12 -35 19 -36 49 -1 17 -3 21 -6 11 -2 -10 -9 -18 -15 -18 -6 0 -8 9 -5 20 3 11 1 20 -4 20 -5 0 -9 -9 -9 -21 0 -12 -4 -17 -11 -14 -6 4 -8 13 -5 21 3 8 1 14 -4 14 -6 0 -10 -8 -11 -17 -1 -12 -4 -9 -8 7 -4 14 -13 24 -19 23 -7 -2 -13 7 -14 20 0 12 -4 2 -8 -23 l-7 -45 -1 48 c-2 44 -22 70 -22 27 0 -11 -4 -20 -10 -20 -13 0 -13 13 2 45 11 26 28 34 28 14z m1750 -318 c24 -35 66 -40 48 -6 -10 18 -9 18 4 7 11 -9 18 -10 23 -2 10 17 25 11 18 -7 -6 -16 -5 -16 10 -4 11 9 17 10 17 2 0 -6 5 -11 11 -11 7 0 9 9 6 21 -4 16 -3 18 9 8 8 -6 14 -18 14 -25 0 -8 6 -11 15 -8 12 5 12 0 5 -28 -11 -35 -13 -54 -6 -47 2 2 5 8 5 12 0 4 7 15 16 23 8 9 13 19 10 24 -3 4 4 6 15 3 11 -3 20 -12 20 -19 0 -8 12 -19 26 -24 38 -15 48 -12 33 7 -12 14 -12 16 1 11 24 -8 66 -18 53 -12 -15 7 -17 33 -3 36 30 4 35 1 35 -24 1 -23 -3 -28 -25 -28 -18 0 -29 -9 -40 -33 -18 -38 -57 -44 -78 -12 -12 19 -13 19 -6 -4 4 -16 3 -21 -5 -17 -14 9 -14 49 -1 62 6 6 8 18 4 27 -12 33 -24 16 -24 -35 0 -49 -1 -51 -16 -32 -8 10 -13 12 -9 4 4 -8 0 -7 -9 4 -14 18 -15 17 -22 -9 l-7 -28 -13 24 c-9 16 -14 19 -14 9 -1 -10 -3 -11 -7 -2 -2 6 -9 12 -14 12 -4 0 -6 -7 -3 -15 8 -21 -8 -19 -33 5 -15 14 -23 16 -26 7 -3 -7 -6 -4 -6 6 -1 9 -8 17 -17 17 -11 0 -15 -6 -11 -20 3 -11 1 -18 -4 -14 -5 3 -9 14 -9 26 0 14 -5 18 -16 14 -9 -3 -18 -6 -20 -6 -2 0 -4 -7 -4 -16 0 -8 4 -13 9 -10 5 4 7 -3 4 -14 -5 -17 -7 -18 -20 -5 -8 9 -23 20 -34 25 -15 9 -19 7 -19 -5 0 -9 4 -14 9 -10 5 3 13 0 17 -6 4 -7 3 -9 -4 -5 -5 3 -12 0 -15 -6 -2 -7 -8 0 -12 15 -4 17 -13 26 -20 23 -19 -7 -35 15 -34 49 0 16 3 23 6 15 4 -8 12 -21 20 -28 11 -11 13 -10 14 10 1 23 1 23 9 -2 5 -17 8 -19 9 -7 1 20 17 23 24 5 4 -8 8 -5 12 9 7 22 36 22 31 0 -1 -7 -1 -9 1 -4 3 4 13 7 24 7 23 0 25 15 4 24 -8 3 -15 11 -14 18 0 10 2 10 6 1 6 -16 23 -17 23 -3 0 16 -31 24 -40 10 -5 -8 -9 -9 -14 -1 -4 6 -2 11 3 11 6 0 11 7 11 15 0 24 17 18 40 -14z"/>',
              '</g>',
              '</svg>'
          ));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

library Apes2 {
    function Apes2String() public pure returns (bytes memory) {
        return bytes(
          abi.encodePacked(
              '<rect x="-3000" height="10000" width="12000" fill="url(#gradBackground)"/>',
              '<path fill="url(#grad1)" d="M3741 5513 c-19 -4 -21 -7 -10 -14 10 -6 7 -9 -13 -9 -17 0 -33 -8 -40 -20 -7 -11 -20 -20 -30 -20 -9 0 -19 -4 -22 -9 -3 -4 -19 -11 -36 -15 -17 -3 -38 -12 -45 -20 -8 -8 -24 -12 -34 -9 -30 8 -76 -26 -181 -132 -52 -53 -125 -116 -162 -140 -42 -28 -75 -58 -89 -83 -15 -25 -37 -46 -63 -58 -35 -16 -48 -32 -86 -104 -25 -47 -51 -86 -57 -87 -18 -4 -16 12 2 27 8 7 13 16 10 20 -3 4 2 10 10 14 8 3 15 11 15 17 0 8 -7 6 -22 -3 -13 -9 -22 -19 -22 -24 1 -5 -11 -31 -26 -59 -15 -27 -36 -83 -45 -123 -10 -40 -19 -71 -21 -69 -7 7 16 125 32 163 15 36 15 37 -2 24 -29 -25 -56 -99 -66 -184 -15 -134 -20 -276 -8 -276 5 0 10 -7 10 -16 0 -8 -4 -13 -9 -10 -13 8 -21 -19 -21 -70 0 -24 -11 -87 -25 -140 -14 -53 -25 -112 -25 -131 0 -34 -20 -84 -47 -115 -9 -10 -16 -49 -20 -111 -5 -89 -4 -99 20 -145 14 -27 24 -52 21 -55 -9 -9 16 -47 31 -47 7 0 27 -18 44 -39 24 -30 31 -49 31 -83 0 -28 9 -62 24 -90 13 -24 27 -55 31 -69 17 -56 57 -128 68 -123 8 3 13 -9 13 -36 1 -22 8 -48 17 -58 30 -34 11 -78 -45 -104 -25 -12 -36 -22 -32 -32 3 -9 -4 -19 -18 -26 -36 -19 -148 -133 -148 -151 0 -9 -38 -51 -85 -94 -47 -42 -85 -82 -85 -89 0 -7 -15 -23 -33 -36 -17 -12 -42 -36 -55 -51 -14 -17 -33 -29 -47 -29 -53 0 -82 -87 -50 -150 15 -28 73 -80 91 -80 13 -1 64 -84 64 -104 0 -13 -13 -16 -67 -18 l-68 -2 75 -6 c59 -5 36 -7 -110 -10 l-185 -4 150 -6 150 -5 -110 -6 c-108 -5 -107 -5 48 -7 195 -3 212 -20 25 -25 l-133 -3 150 -2 c185 -3 185 -3 185 -14 0 -4 -73 -8 -162 -8 -109 0 -158 -4 -148 -10 17 -11 356 -11 525 0 l110 7 -77 3 c-43 1 -82 4 -88 5 -5 1 -15 3 -21 4 -5 0 -7 6 -4 11 4 6 -13 10 -44 10 -47 0 -50 2 -56 30 -4 16 -11 30 -16 30 -5 0 -9 6 -9 14 0 15 35 11 57 -6 6 -5 22 -8 35 -6 20 3 23 -1 20 -25 -3 -33 14 -29 28 7 9 21 9 21 9 -2 1 -20 5 -22 24 -16 12 4 40 11 62 15 l40 6 -51 2 c-32 1 -56 7 -64 16 -7 8 -16 13 -20 10 -5 -3 -11 -1 -15 5 -3 5 -23 10 -43 10 -46 0 -67 13 -59 35 4 9 12 13 18 9 9 -5 10 6 5 42 -6 45 -3 54 25 92 17 23 34 42 39 42 4 0 33 25 65 55 31 30 63 55 71 55 8 0 14 5 14 10 0 6 6 10 14 10 8 0 28 16 44 36 17 20 34 34 39 31 5 -3 22 7 37 24 15 16 35 29 45 29 9 0 30 14 47 31 16 17 69 49 117 71 51 24 83 44 76 48 -8 6 -8 9 0 14 6 4 15 5 20 2 10 -7 28 33 41 92 6 26 13 56 16 67 l6 20 -16 -20 c-8 -11 -16 -18 -17 -15 -1 8 -7 85 -13 185 -3 49 -9 91 -13 92 -5 2 -7 35 -5 74 3 45 1 69 -5 66 -12 -7 -63 14 -63 26 0 5 4 6 9 2 27 -16 38 73 16 128 -4 9 -3 17 2 17 9 0 26 -45 38 -102 6 -31 22 -37 27 -10 3 9 4 -33 5 -93 0 -61 5 -120 11 -131 6 -12 13 -34 16 -50 5 -32 80 -105 126 -124 15 -6 33 -22 40 -34 10 -20 9 -28 -5 -50 -15 -23 -16 -33 -7 -64 6 -20 18 -86 27 -147 9 -60 25 -128 35 -150 35 -79 61 -171 60 -212 0 -23 5 -51 12 -62 10 -16 10 -27 0 -54 -16 -44 -15 -57 5 -72 26 -19 6 -38 -33 -32 -19 3 -36 1 -39 -4 -4 -5 -41 -9 -83 -10 -42 0 -70 -3 -62 -6 8 -2 22 -7 30 -10 8 -3 56 -7 107 -7 51 -1 95 -5 99 -9 4 -4 -32 -7 -81 -7 -49 0 -86 -2 -83 -5 11 -11 1046 -20 1057 -9 2 2 -95 4 -216 4 -194 0 -222 2 -227 16 -5 12 -2 15 13 11 24 -6 259 18 269 28 4 4 -37 5 -90 3 -76 -3 -98 -1 -98 9 0 18 -7 16 -33 -7 -12 -11 -28 -18 -35 -15 -8 3 -20 1 -27 -5 -14 -12 -65 -3 -65 11 0 5 -5 9 -11 9 -7 0 -9 -10 -5 -26 l7 -25 -31 22 c-16 13 -30 25 -30 28 0 4 -10 12 -21 20 -19 11 -21 11 -16 -3 4 -9 2 -16 -3 -16 -6 0 -10 -7 -10 -15 0 -19 -19 -19 -26 0 -4 8 -10 15 -16 15 -13 0 -38 26 -38 39 0 16 15 13 30 -4 7 -8 17 -15 23 -15 5 0 2 10 -9 23 -10 12 -12 16 -4 10 20 -18 40 -16 41 5 0 10 3 12 6 5 2 -7 12 -13 21 -13 8 0 29 -5 46 -11 35 -13 121 4 110 22 -3 5 -13 7 -22 5 -24 -8 -133 38 -145 61 -5 10 -16 23 -24 29 -7 7 -15 27 -18 45 -2 19 -9 71 -15 117 -5 46 -10 107 -10 135 2 93 -8 323 -15 376 -7 52 -26 66 -52 40 -12 -12 -6 -42 6 -35 4 3 6 -8 5 -22 0 -15 -2 -55 -2 -89 -2 -72 -13 -81 -28 -23 -6 22 -7 37 -3 34 10 -6 12 39 3 49 -12 12 -33 -21 -28 -44 5 -19 4 -21 -5 -9 -6 8 -11 25 -11 37 0 12 -4 23 -10 25 -6 2 -6 14 -1 33 5 17 10 25 10 18 1 -7 8 -10 16 -7 10 4 15 0 15 -16 0 -11 4 -19 10 -15 6 4 6 15 0 30 -11 28 -3 58 14 52 16 -6 56 10 56 23 0 6 -4 8 -10 5 -5 -3 -10 3 -10 14 0 12 -5 21 -11 21 -13 0 -40 26 -34 32 3 3 -2 5 -10 5 -19 0 -19 -6 3 -31 17 -21 17 -21 -5 -3 -29 25 -37 57 -13 52 16 -3 17 0 8 26 -14 41 -4 47 18 10 10 -17 22 -31 26 -31 4 0 8 1 8 3 -3 19 -39 128 -39 119 -1 -7 -6 -10 -11 -7 -6 3 -7 17 -4 30 3 13 -1 38 -9 57 -9 18 -26 62 -38 98 -21 62 -50 113 -34 61 6 -18 4 -22 -6 -16 -11 6 -12 5 -1 -6 6 -7 12 -20 12 -28 0 -14 -1 -14 -10 -1 -8 12 -10 11 -10 -7 0 -34 11 -53 31 -53 10 0 19 -2 19 -4 0 -2 7 -21 15 -42 l16 -39 -20 23 c-11 12 -21 28 -24 35 -2 6 -7 9 -10 6 -4 -3 2 -23 13 -44 22 -44 27 -76 9 -58 -6 6 -17 10 -23 7 -7 -3 -12 12 -13 40 -1 24 -9 61 -17 81 -9 21 -16 48 -16 62 0 13 -7 26 -15 29 -24 10 -60 75 -64 117 -1 5 -5 6 -10 2 -5 -3 -13 0 -17 6 -5 8 -3 9 6 4 10 -6 12 -4 7 9 -4 10 -7 20 -7 22 0 2 -7 4 -15 4 -17 0 -20 -25 -5 -35 6 -4 22 -30 36 -58 25 -52 25 -52 1 -24 -35 42 -87 136 -77 142 4 3 11 -1 13 -7 4 -11 7 -10 14 0 13 17 40 -15 88 -101 20 -37 39 -66 42 -63 3 2 0 14 -7 25 -6 12 -8 26 -5 31 9 14 28 1 22 -14 -3 -7 1 -13 9 -13 15 0 13 4 -30 69 -17 26 -36 48 -42 48 -7 0 -15 7 -18 16 -6 15 -4 15 10 3 16 -13 16 -12 6 8 -7 12 -17 25 -22 28 -21 13 -7 41 34 68 24 15 54 27 67 26 l24 -1 -25 -8 c-23 -7 -22 -8 10 -9 47 -1 80 9 80 24 0 19 50 38 66 24 9 -7 77 -12 186 -14 95 -2 213 -9 262 -15 63 -8 92 -8 99 -1 14 14 62 14 106 1 31 -9 40 -6 85 23 44 28 59 32 117 31 65 0 67 0 77 30 6 17 13 51 17 75 4 24 21 72 37 108 34 72 34 119 -2 163 -38 47 -125 183 -122 192 3 13 -13 16 -121 22 -63 3 -96 2 -92 -4 3 -6 19 -10 34 -10 24 0 30 -6 41 -40 7 -22 17 -40 22 -40 4 0 8 -7 8 -15 0 -17 35 -21 45 -5 4 6 1 27 -5 46 -9 27 -15 33 -21 23 -7 -11 -9 -11 -9 -1 0 7 -4 11 -9 8 -5 -3 -11 0 -14 8 -5 11 5 14 46 13 l52 -2 -3 -43 c-3 -31 1 -44 13 -48 23 -9 28 1 14 28 -11 21 -11 22 4 9 10 -7 17 -22 17 -32 0 -11 3 -19 8 -19 13 0 102 -128 102 -148 0 -25 -35 -58 -45 -42 -4 7 -3 15 2 19 6 3 13 16 17 28 6 18 1 26 -25 42 -24 15 -35 17 -44 8 -7 -7 -10 -18 -7 -26 4 -10 1 -13 -11 -8 -8 3 -18 3 -20 -1 -2 -4 -2 -2 -1 5 2 7 -1 15 -5 18 -5 3 -9 20 -10 37 0 18 -9 60 -20 93 -22 70 -28 53 -6 -19 21 -69 20 -73 -20 -68 -19 2 -35 8 -35 13 0 5 -7 9 -15 9 -8 0 -15 8 -15 18 0 14 -2 15 -10 2 -7 -11 -10 -11 -10 -2 0 7 -4 11 -9 8 -5 -3 -12 6 -16 22 l-7 27 -10 -25 c-7 -20 -11 -22 -18 -10 -8 12 -10 11 -11 -5 -1 -11 -1 -26 0 -32 1 -7 -3 -13 -9 -13 -6 0 -8 5 -4 12 5 7 2 9 -9 5 -12 -4 -14 -2 -10 11 6 15 5 15 -10 3 -19 -15 -19 -15 -36 14 -11 19 -12 19 -6 -2 8 -29 -9 -30 -29 -2 -18 27 -40 20 -56 -18 -18 -39 -71 -75 -87 -58 -9 10 -9 15 0 24 9 9 8 10 -7 5 -14 -5 -17 -4 -11 5 4 8 -3 6 -18 -4 -15 -9 -31 -14 -37 -10 -6 4 -10 -5 -10 -23 0 -25 -3 -29 -20 -25 -11 3 -20 0 -20 -6 0 -6 -5 -11 -11 -11 -6 0 -9 9 -6 20 3 12 1 18 -5 14 -5 -3 -8 -14 -5 -24 2 -9 0 -24 -5 -33 -7 -13 -2 -18 24 -26 l33 -9 -32 -1 c-17 -1 -35 -5 -38 -11 -3 -5 -20 -10 -36 -10 -38 0 -34 24 4 28 60 7 21 17 -67 17 -52 0 -92 -3 -89 -7 2 -5 15 -8 29 -8 13 0 24 -4 24 -10 0 -5 -11 -10 -25 -10 -14 0 -25 -4 -25 -8 0 -11 -46 -32 -70 -32 -11 0 -20 -4 -20 -10 0 -5 -9 -10 -20 -10 -11 0 -20 -4 -20 -10 0 -5 5 -10 10 -10 6 0 10 -4 10 -10 0 -5 -9 -10 -21 -10 -15 0 -19 5 -15 15 3 8 0 15 -6 15 -7 0 -3 7 8 15 25 19 7 19 -46 0 -49 -17 -60 -18 -60 -6 0 5 14 12 30 16 17 4 30 11 30 16 0 6 -6 7 -12 4 -7 -4 -2 3 12 14 14 12 35 20 47 18 15 -3 20 0 16 10 -4 9 0 11 13 6 16 -6 15 -2 -5 30 -12 20 -20 37 -18 37 3 0 15 -15 26 -34 17 -27 19 -39 11 -61 -5 -14 -10 -27 -10 -29 0 -1 13 -1 30 2 16 2 27 8 24 13 -3 5 -9 7 -14 4 -5 -3 -11 -1 -15 5 -3 5 5 15 19 22 16 6 26 19 26 31 0 12 -25 73 -57 136 -31 64 -56 128 -56 143 0 23 -3 26 -15 16 -12 -10 -14 -9 -11 7 3 11 8 19 13 17 11 -4 36 44 36 69 0 10 7 44 15 76 10 37 12 59 5 61 -5 2 -10 25 -10 50 0 26 -7 72 -15 102 -9 30 -18 75 -20 99 -4 35 -2 42 10 37 8 -3 19 3 24 12 8 14 10 14 11 2 0 -19 101 -63 132 -58 l23 5 -25 11 c-24 10 -24 11 -3 11 12 1 28 4 37 7 10 4 16 1 16 -8 0 -13 7 -13 46 -3 25 6 50 18 55 26 5 8 9 10 9 5 0 -4 11 -1 25 8 13 9 31 16 39 16 9 0 47 30 86 66 62 59 70 70 70 104 0 29 -9 49 -41 89 -38 48 -40 54 -29 81 13 31 7 50 -15 50 -7 0 -27 12 -44 26 -17 14 -31 22 -31 17 1 -12 33 -48 54 -60 17 -9 17 -10 -4 -16 -17 -4 -26 1 -38 24 -17 29 -32 38 -32 18 0 -5 -5 -7 -10 -4 -8 5 -8 11 -1 19 6 7 8 15 5 19 -13 13 -74 -25 -74 -47 0 -6 5 -5 12 2 7 7 16 12 21 12 5 0 1 -7 -7 -16 -15 -15 -21 -34 -11 -34 3 0 14 5 24 12 15 9 23 9 35 -1 17 -14 22 -41 8 -41 -4 0 -8 -9 -8 -20 0 -11 4 -20 8 -20 4 0 8 4 8 8 0 5 7 17 15 28 14 17 14 16 1 -13 -21 -42 -36 -50 -53 -28 -12 17 -18 14 -14 -7 2 -15 -17 -8 -23 9 -6 15 -10 14 -30 -8 -13 -13 -21 -30 -18 -37 2 -7 -1 -18 -7 -26 -6 -7 -8 -15 -5 -19 3 -3 1 -14 -6 -24 -10 -16 -10 -15 -4 6 4 15 2 21 -4 17 -17 -10 -7 39 18 86 l22 43 -22 -20 -23 -20 12 23 c9 16 9 22 0 22 -9 0 -9 3 0 14 7 8 9 25 5 42 -5 18 -3 25 4 20 11 -6 72 48 90 81 9 16 12 15 31 -7 20 -25 20 -25 21 -3 0 25 -27 56 -41 47 -13 -8 -59 23 -59 39 0 13 -40 43 -53 39 -4 -1 -21 5 -37 13 -38 20 -60 19 -60 -2 -1 -17 -1 -17 -11 0 -10 17 -29 19 -78 10z m427 -342 c19 -29 30 -56 26 -65 -3 -9 -2 -16 4 -16 5 0 12 -9 15 -21 6 -21 -39 -81 -75 -100 -18 -10 -19 -8 -13 13 5 18 4 20 -4 8 -6 -8 -11 -22 -11 -31 0 -9 -7 -22 -15 -29 -13 -11 -14 -10 -9 5 5 13 4 16 -4 11 -8 -5 -10 -2 -6 8 3 9 9 16 13 16 4 0 13 12 20 28 10 23 10 25 -2 10 -8 -10 -19 -18 -24 -18 -6 0 -15 -10 -21 -22 -10 -22 -11 -21 -11 9 -1 17 -7 34 -13 36 -8 3 -6 6 5 6 9 1 17 8 17 17 0 8 -4 13 -9 10 -5 -3 -14 1 -21 9 -10 13 -9 19 5 35 10 11 13 20 7 20 -7 0 -12 4 -12 9 0 10 35 25 60 26 8 0 15 7 16 15 1 24 15 60 23 60 4 0 22 -22 39 -49z m-848 -586 c-9 -17 -10 -28 -3 -37 6 -7 16 -35 22 -62 7 -27 21 -67 32 -90 10 -22 19 -46 19 -53 0 -7 11 -13 24 -13 30 0 34 -6 41 -61 3 -24 12 -47 20 -51 20 -12 56 -114 60 -173 l4 -50 -19 54 c-11 29 -17 57 -15 61 8 12 -6 41 -16 34 -5 -3 -9 -17 -9 -32 -1 -29 -11 -18 -24 25 -6 19 -4 22 10 16 13 -5 15 -2 9 18 -11 35 -25 47 -25 20 0 -12 -4 -19 -10 -16 -5 3 -10 0 -11 -7 0 -10 -2 -10 -6 0 -2 6 -10 9 -15 6 -6 -4 -9 -3 -6 2 8 14 -10 56 -21 49 -6 -3 -15 3 -20 14 -14 25 -14 44 -1 36 6 -3 10 -1 10 5 0 6 -12 18 -28 27 -30 17 -72 96 -46 86 8 -3 14 -11 14 -18 0 -16 34 -55 49 -55 16 0 5 56 -16 85 -14 19 -15 19 -9 -5 4 -14 -5 -1 -19 29 -14 30 -23 56 -20 59 2 2 10 -7 16 -22 18 -38 32 -32 15 8 -22 53 -30 115 -16 132 19 22 25 8 10 -21z m1031 -515 c10 0 21 5 25 11 4 8 9 7 15 -2 4 -8 12 -14 16 -15 4 0 16 -4 25 -8 11 -5 27 -1 44 13 23 18 24 21 8 22 -18 0 -18 1 1 9 36 16 50 11 50 -15 0 -14 -2 -26 -5 -26 -3 -1 -15 -3 -27 -4 -28 -3 -55 -29 -48 -47 3 -8 14 -20 24 -28 16 -11 17 -18 10 -39 -8 -20 -7 -28 5 -37 18 -13 11 -24 -16 -24 -10 0 -18 -5 -18 -10 0 -11 55 -5 98 11 13 5 31 9 40 9 35 0 -23 -35 -62 -38 -22 -1 -47 -9 -56 -17 -9 -8 -24 -15 -34 -15 -9 0 -26 -5 -37 -11 -11 -5 -30 -9 -42 -7 -16 2 -8 9 33 26 51 21 45 23 -20 8 -14 -4 -18 -3 -10 0 8 4 28 19 43 34 21 20 25 30 16 35 -7 5 -17 1 -25 -9 -11 -15 -74 -33 -74 -20 0 2 18 12 39 21 35 15 39 20 34 45 -3 17 -1 28 6 28 6 0 11 4 11 10 0 5 -6 7 -14 4 -8 -3 -16 3 -19 15 -3 12 0 21 6 22 7 0 -12 9 -42 19 -46 15 -58 16 -73 5 -17 -11 -18 -13 -2 -19 26 -10 10 -18 -21 -10 -18 4 -23 9 -15 14 7 4 13 18 14 30 1 16 8 24 26 27 14 2 27 9 29 16 2 6 9 2 14 -11 6 -12 18 -22 28 -22z m-1866 -1854 c13 -13 29 -26 36 -28 9 -3 9 -9 0 -26 -10 -19 -8 -22 24 -28 30 -5 35 -10 35 -35 0 -15 -4 -30 -9 -33 -4 -3 -14 -26 -21 -51 -7 -25 -16 -48 -21 -51 -5 -2 -2 14 6 37 19 53 19 68 0 43 -15 -18 -16 -17 -10 16 5 34 5 34 -15 -10 -14 -31 -19 -36 -15 -17 3 17 2 26 -4 23 -10 -7 -24 22 -16 34 8 13 -26 91 -36 84 -5 -3 -6 3 -2 12 5 13 3 15 -7 9 -7 -5 -11 -4 -8 1 3 5 8 17 11 27 9 23 23 21 52 -7z"/>',
              '</g>',
              '</svg>'
          ));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

library Apes1 {
    function Apes2String() public pure returns (bytes memory) {
        return bytes(
          abi.encodePacked(
              '<rect x="-3000" height="10000" width="12000" fill="url(#gradBackground)"/>',
              '<path fill="url(#grad1)" d="M1710 4413 c-8 -3 -28 -15 -43 -25 -19 -13 -36 -18 -53 -14 -20 5 -32 0 -57 -26 -18 -18 -61 -52 -97 -76 -56 -38 -70 -43 -103 -39 -45 6 -134 -21 -174 -53 -18 -14 -35 -19 -52 -15 -14 3 -33 0 -41 -6 -12 -8 -8 -9 15 -5 l30 6 -25 -15 c-30 -17 -54 -19 -44 -4 3 6 -22 -4 -56 -23 -44 -23 -76 -51 -111 -95 -27 -34 -61 -69 -76 -77 -67 -34 -193 -192 -193 -241 0 -9 -7 -29 -15 -45 -8 -16 -16 -40 -17 -54 -1 -14 -7 -22 -15 -19 -20 8 -124 -97 -148 -150 -12 -26 -42 -65 -66 -86 -56 -49 -103 -133 -95 -167 4 -14 2 -24 -4 -24 -5 0 -10 7 -10 16 0 27 -23 1 -55 -61 -24 -49 -27 -63 -22 -118 12 -123 19 -141 63 -176 28 -22 50 -28 39 -11 -12 20 12 9 35 -15 13 -14 34 -25 47 -25 13 0 32 -9 44 -21 14 -14 30 -19 50 -17 23 2 35 -3 49 -22 16 -21 20 -22 36 -10 15 12 16 12 9 1 -5 -10 -4 -12 3 -7 7 4 22 0 34 -8 21 -15 20 -15 -23 -14 -27 0 -61 -8 -84 -20 -42 -21 -85 -57 -85 -71 0 -4 -11 -13 -26 -19 -14 -7 -31 -27 -39 -46 -8 -19 -29 -45 -46 -58 -17 -12 -43 -35 -58 -49 -14 -14 -36 -29 -48 -33 -12 -4 -41 -28 -64 -54 -34 -37 -40 -47 -27 -50 10 -2 15 -9 11 -18 -3 -9 2 -14 18 -16 13 0 30 -2 38 -2 8 -1 19 -10 25 -21 6 -10 19 -28 28 -39 13 -14 16 -31 13 -63 -2 -23 0 -43 6 -43 9 0 13 21 10 55 -1 15 1 17 10 8 7 -7 9 -21 3 -40 -4 -15 -8 -37 -8 -47 -1 -11 -7 -21 -15 -24 -9 -3 -11 1 -6 17 4 15 2 21 -9 21 -8 0 -21 10 -27 22 -7 13 -23 31 -36 41 -25 20 -30 46 -12 64 15 15 -2 45 -19 34 -7 -4 -14 -17 -15 -28 0 -13 -6 -19 -14 -16 -8 3 -13 -3 -13 -15 0 -11 6 -23 13 -25 9 -4 9 -6 0 -6 -13 -1 38 -85 59 -97 8 -5 5 -10 -8 -15 -18 -7 -17 -8 3 -8 22 -1 44 -21 23 -21 -8 0 -8 -4 0 -12 6 -7 16 -21 23 -30 7 -10 30 -20 56 -23 24 -3 53 -12 64 -20 16 -11 45 -15 107 -13 l85 1 -65 7 c-64 6 -63 9 5 23 18 4 18 5 -2 6 -13 0 -23 6 -23 12 0 11 11 10 103 -8 16 -3 27 -1 27 6 0 6 -18 11 -42 12 -24 1 -54 5 -68 9 l-25 8 25 2 c22 2 23 3 5 9 -11 4 -32 12 -47 19 -16 7 -38 16 -51 21 -16 6 -28 25 -41 66 l-18 57 24 25 c13 14 37 32 53 40 17 8 44 28 60 44 35 32 120 80 151 84 11 1 42 16 68 34 57 40 149 81 179 81 12 0 33 7 45 16 12 8 27 12 32 9 6 -3 10 1 10 10 0 9 5 13 10 10 16 -10 12 -45 -4 -39 -19 7 -41 -37 -50 -100 -3 -27 -13 -57 -22 -67 -11 -12 -13 -25 -8 -41 4 -13 6 -39 5 -59 -3 -40 9 -54 56 -63 23 -5 35 -16 44 -39 7 -18 14 -35 17 -39 2 -5 -25 -9 -60 -10 l-63 -2 58 -3 c48 -3 57 -7 57 -23 0 -17 -9 -20 -82 -23 l-83 -3 83 -2 c81 -2 112 -17 50 -25 l-33 -4 32 -1 c18 -1 49 -13 69 -27 20 -14 45 -25 55 -25 10 0 21 -4 24 -10 3 -5 2 -10 -3 -10 -5 0 -79 -3 -163 -7 -85 -3 -210 -6 -279 -6 -94 1 -109 -1 -62 -6 35 -3 352 -4 705 -1 353 3 644 2 647 -2 7 -9 286 -26 579 -34 146 -5 227 -11 219 -16 -8 -6 -1 -8 21 -4 18 3 48 6 65 7 29 1 28 2 -9 9 -22 4 -141 11 -265 14 -414 12 -610 24 -576 35 10 4 -158 6 -373 4 -240 -1 -393 2 -396 7 -4 6 29 11 82 11 48 1 122 5 163 9 l75 7 -60 2 -60 1 45 21 c29 13 61 19 92 18 26 -2 51 0 54 4 4 4 -20 7 -54 7 -48 0 -62 3 -62 15 0 13 23 15 138 17 l137 2 -135 3 c-74 2 -139 8 -143 12 -5 5 -24 3 -43 -5 -20 -9 -34 -10 -34 -4 0 5 -16 10 -35 10 -63 0 -114 28 -134 74 -28 61 -33 84 -21 91 5 3 8 18 5 33 -16 77 -20 120 -14 152 23 114 31 173 23 179 -33 24 -34 115 -1 184 51 111 67 148 83 197 l18 55 8 -31 c4 -18 15 -37 23 -44 8 -7 15 -23 15 -35 0 -12 17 -41 37 -65 20 -23 38 -51 40 -61 2 -11 12 -37 23 -59 11 -21 19 -56 19 -77 -1 -67 17 -187 34 -225 16 -34 16 -46 3 -134 -16 -107 -15 -114 38 -155 24 -19 36 -21 89 -16 70 7 97 15 97 29 0 6 -8 7 -17 3 -10 -3 -46 -9 -80 -12 l-63 -6 0 48 c0 53 6 57 13 10 3 -19 9 -29 18 -26 8 1 29 5 48 6 19 2 37 9 41 16 6 8 14 5 29 -10 11 -11 24 -21 29 -21 11 1 52 96 52 124 0 14 -4 28 -10 31 -6 3 -10 -4 -10 -18 0 -13 -9 -36 -20 -50 -11 -14 -20 -31 -20 -38 0 -7 -2 -10 -5 -7 -3 3 -3 25 1 49 6 34 9 39 15 24 4 -11 6 23 3 75 -3 54 -1 112 5 135 10 37 10 36 5 -22 -5 -64 2 -113 17 -113 5 0 9 12 9 26 0 14 -4 23 -10 19 -5 -3 -10 -1 -10 4 0 6 5 11 10 11 21 0 2 183 -21 204 -8 8 -10 -2 -5 -39 3 -27 3 -44 -1 -36 -4 10 -9 8 -20 -10 -14 -23 -14 -23 -10 11 7 54 -20 97 -57 91 -5 -1 -6 5 -2 14 3 9 6 20 6 23 0 4 5 0 10 -8 8 -13 10 -12 10 3 0 9 -5 17 -10 17 -16 0 -30 46 -33 105 -1 29 -5 51 -8 49 -8 -5 -44 87 -40 105 1 7 -2 10 -8 6 -6 -3 -11 -1 -11 4 0 6 -3 11 -8 11 -4 0 -6 -19 -5 -42 l3 -43 -15 40 c-10 25 -12 41 -5 43 13 5 13 32 0 32 -5 0 -10 12 -10 26 0 14 -4 23 -10 19 -6 -4 -10 7 -10 25 0 32 20 34 20 2 1 -18 30 -63 30 -45 0 6 -6 26 -14 44 -26 66 -28 74 -32 107 -2 17 1 32 6 32 6 0 10 -10 11 -22 1 -22 1 -22 8 2 4 14 3 39 -2 55 -9 30 -13 57 -15 109 -2 21 -6 27 -17 22 -9 -3 -15 0 -15 9 0 11 6 12 23 6 15 -6 24 -19 29 -47 6 -34 6 -32 4 14 -3 49 5 67 18 40 3 -7 4 23 0 67 -6 87 -32 160 -70 196 -26 24 -35 61 -10 40 11 -9 16 -6 25 16 18 42 65 93 91 98 12 2 31 12 40 20 15 14 54 23 160 39 9 1 20 5 25 8 6 3 30 4 55 2 52 -3 130 16 213 54 92 42 102 85 35 158 -31 34 -38 48 -30 56 18 18 14 42 -7 55 -11 7 -25 28 -32 48 -7 19 -16 35 -20 35 -11 0 7 -58 27 -88 12 -18 13 -27 6 -30 -20 -6 -13 -27 19 -58 27 -26 59 -73 59 -89 0 -3 -7 -5 -15 -5 -8 0 -15 -4 -15 -10 0 -5 5 -10 11 -10 23 0 -6 -22 -58 -46 -56 -24 -79 -31 -54 -15 12 8 12 13 -2 35 -9 14 -14 31 -11 39 3 8 -2 17 -10 20 -9 4 -16 11 -16 18 0 6 7 9 15 6 11 -5 12 -1 5 19 -13 33 -13 34 5 34 8 0 24 18 35 40 24 47 24 50 5 50 -9 0 -18 12 -21 29 -4 17 -11 28 -18 25 -14 -5 -37 -74 -25 -74 5 0 9 -7 9 -16 0 -8 4 -13 9 -10 5 3 11 -1 15 -9 8 -22 -7 -25 -42 -8 -32 15 -34 15 -48 -6 -19 -27 -39 -29 -24 -2 16 30 12 44 -10 38 -24 -6 -24 -6 -5 39 8 19 14 38 14 42 -3 19 2 23 15 13 11 -9 20 -6 44 14 17 14 47 29 67 32 19 3 35 8 35 12 0 3 -17 17 -37 31 -20 14 -57 44 -81 67 -24 23 -60 47 -80 53 -39 10 -127 12 -152 3z m-215 -387 c2 -18 12 -50 23 -70 26 -49 28 -145 4 -174 -9 -11 -22 -29 -29 -39 -9 -14 -10 -10 -3 22 6 28 5 42 -3 47 -9 6 -9 8 1 8 6 0 12 5 12 12 0 6 -9 3 -20 -7 -20 -19 -28 -41 -10 -30 15 9 12 -14 -4 -30 -25 -25 -26 52 -2 98 11 21 22 34 24 28 4 -12 32 -3 32 11 0 5 -4 7 -9 4 -5 -3 -16 12 -25 34 -19 47 -30 54 -14 9 12 -34 5 -51 -10 -22 -16 31 -24 75 -12 68 10 -6 15 13 12 48 -1 9 3 17 9 17 5 0 7 5 4 10 -4 6 -11 8 -16 5 -10 -7 -12 8 -2 18 10 11 35 -32 38 -67z m-45 -370 c0 -19 9 -43 20 -56 11 -13 20 -31 20 -42 0 -10 5 -18 10 -18 6 0 10 -8 10 -18 0 -11 7 -33 16 -51 9 -18 18 -51 21 -74 l4 -42 -17 27 c-16 25 -19 25 -41 11 -21 -14 -23 -14 -32 8 -4 13 -5 34 0 46 6 15 1 41 -16 84 -34 86 -31 107 4 34 16 -33 30 -56 30 -52 1 9 -21 63 -43 108 -14 28 -10 83 5 73 5 -3 9 -20 9 -38z"/>',
              '</g>',
              '</svg>'
          ));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
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
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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