// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MonsterAssetData is Ownable
{
    using Strings for uint256;

    bool public isMonsterAssetData = true;

    struct ContentBounds {
    uint8 top;
    uint8 right;
    uint8 bottom;
    uint8 left;
  }

  struct Rect {
    uint8 length;
    uint8 colorIndex;
  }

  struct DecodedImage {
    uint8 paletteIndex;
    ContentBounds bounds;
    uint256 width;
    Rect[] rects;
  }

    mapping(uint256 => string[]) public palettes;
    bytes[] public bodyRLEDatas;
    bytes[] public glassesRLEDatas;
    bytes[] public headRLEDatas;

 
    function bodyCount() external view returns (uint256) {
        return bodyRLEDatas.length;
    }
    function glassesCount() external view returns (uint256) {
        return glassesRLEDatas.length;
    }
    function headCount() external view returns (uint256) {
        return headRLEDatas.length;
    }
    function addColorsToPalette(uint256 paletteIndex, string[] calldata _pallete) external onlyOwner
    {
        for (uint256 i = 0; i < _pallete.length; i++)
        {
            palettes[paletteIndex].push(_pallete[i]);
        }
    }

    function addBody(bytes calldata _body) external onlyOwner {
        bodyRLEDatas.push(_body);
    }

    function addGlasses(bytes calldata _glasses) external onlyOwner {
        glassesRLEDatas.push(_glasses);
    }

    function addHead(bytes calldata _head) external onlyOwner {
        headRLEDatas.push(_head);
    }

    function getPartsForGene(uint8[] memory _decodeGene) internal view returns (bytes[] memory) {
        bytes[] memory parts = new bytes[](3);
        parts[0] = bodyRLEDatas[_decodeGene[0] - 1];
        parts[1] = headRLEDatas[_decodeGene[4] - 1];
        parts[2] = glassesRLEDatas[_decodeGene[8] - 1];
        return parts;
    }

    function generateSVGImage(bytes[] memory parts)
        public
        view
        returns (string memory)
    {
        return Base64.encode(bytes(generateSVG(parts)));
    }

    function generateSVG(bytes[] memory parts)
        internal
        view
        returns (string memory svg)
    {
        return string(
            abi.encodePacked(
                '<svg width="320" height="320" viewBox="0 0 320 320" xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges">',
                '<rect width="100%" height="100%" fill="#ffffff" />',
                generateSVGRects(parts),
                '</svg>'
            )
        );
    }

    function getSVG(uint8[] memory _decodeGene) public view returns(string memory)
    {
        bytes[] memory parts = getPartsForGene(_decodeGene);
        return generateSVG(parts);
    }

    function constructTokenURI(uint8[] memory _decodeGene, uint256 _id) public view returns (string memory)
    {
        string memory name = string(abi.encodePacked("Monster #", _id.toString()));
        bytes[] memory parts = getPartsForGene(_decodeGene);
        string memory image = generateSVGImage(parts);
        // attributes handle
        string memory attribute ="[";
        attribute = string(abi.encodePacked(attribute,'{"BODY":"body', uint256(_decodeGene[0]).toString(), '"}',","));
        attribute = string(abi.encodePacked(attribute,'{"HEAD":"head', uint256(_decodeGene[4]).toString(), '"}',","));
        attribute = string(abi.encodePacked(attribute,'{"GLASSES":"glasses', uint256(_decodeGene[8]).toString(), '"}'));
        attribute = string(abi.encodePacked(attribute,"]"));

    return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    abi.encodePacked('{"name":"', name, '", "description":"', name, '", "image": "', 'data:image/svg+xml;base64,', image, '","attributes":"',attribute,'"}')
                )
            )
        );
    }

    function generateSVGRects(bytes[] memory parts)
        private
        view
        returns (string memory svg)
    {
        string[33] memory lookup = [
            "0", "10", "20", "30", "40", "50", "60", "70", 
            "80", "90", "100", "110", "120", "130", "140", "150", 
            "160", "170", "180", "190", "200", "210", "220", "230", 
            "240", "250", "260", "270", "280", "290", "300", "310",
            "320" 
        ];
        string memory rects ="";
        for (uint8 p = 0; p < parts.length; p++) 
        {
             DecodedImage memory image = decodeRLEImage(parts[p]);
            string[] storage palette = palettes[image.paletteIndex];
            uint256 currentX = image.bounds.left;
            uint256 currentY = image.bounds.top;
            string[4] memory buffer;
            string memory part;
            for (uint256 i = 0; i < image.rects.length; i++) {
                Rect memory rect = image.rects[i];
                if (rect.colorIndex != 0) {
                    buffer[0] = lookup[rect.length];      // width
                    buffer[1] = lookup[currentX];         // x
                    buffer[2] = lookup[currentY];         // y
                    buffer[3] = palette[rect.colorIndex - 1]; // color
                    part = string(abi.encodePacked(part, getChunk(buffer)));
                }

                currentX += rect.length;
                if (currentX - image.bounds.left > image.width) {
                    currentX = image.bounds.left;
                    currentY++;
                }
            }
            rects = string(abi.encodePacked(rects, part));
        }
       
        
        return rects;
    }

  function getChunk(string[4] memory buffer) private pure returns (string memory) {
            return string(
                abi.encodePacked(
                    '<rect width="', buffer[0], '" height="10" x="', buffer[1], '" y="', buffer[2], '" fill="#', buffer[3], '" />'
                )
            );       
    }

  function decodeRLEImage(bytes memory image) private pure returns (DecodedImage memory) {
    uint8 paletteIndex = uint8(image[0]);
    ContentBounds memory bounds = ContentBounds({
      top: uint8(image[1]),
      right: uint8(image[2]),
      bottom: uint8(image[3]),
      left: uint8(image[4])
    });
     uint256 width = bounds.right - bounds.left;

    uint256 cursor;
    Rect[] memory rects = new Rect[]((image.length - 5) / 2);
    for (uint256 i = 5; i < image.length; i += 2) {
      rects[cursor] = Rect({length: uint8(image[i+1]), colorIndex: uint8(image[i])});
      cursor++;
    }
    return DecodedImage({paletteIndex: paletteIndex, bounds: bounds, width: width,rects:rects});
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
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