//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import {Base64} from './lib/Base64.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import '@divergencetech/ethier/contracts/utils/DynamicBuffer.sol';

import {OKPCArt} from './OKPCArt.sol';
import {OKPCParts} from './OKPCParts.sol';
import {IOKPCFont} from './interfaces/IOKPCFont.sol';
import {IOKPCMetadata} from './interfaces/IOKPCMetadata.sol';

contract OKPCMetadata is IOKPCMetadata, Ownable {
  using DynamicBuffer for bytes;

  OKPCParts private _parts;
  IOKPCFont private _font;

  constructor(address partsAddress, address fontAddress) {
    _parts = OKPCParts(partsAddress);
    _font = IOKPCFont(fontAddress);
  }

  // * ADMIN * //
  function setParts(address partsAddress) public onlyOwner {
    _parts = OKPCParts(partsAddress);
  }

  function setFont(address fontAddress) public onlyOwner {
    _font = IOKPCFont(fontAddress);
  }

  // * METADATA * //
  function tokenURI(
    uint256 tokenId,
    uint256 clockSpeed,
    uint256 artCollected,
    OKPCArt.Art memory art
  ) public view override returns (string memory) {
    bytes memory artData = abi.encodePacked(art.data1, art.data2);

    if (artData.length < 56) revert NotEnoughPixelData();
    Parts memory parts = getParts(tokenId);

    string memory json = Base64.encode(
      abi.encodePacked(
        '{"name": "OKPC #',
        toString(tokenId),
        '", "description": "Placeholder Description", "image": "data:image/svg+xml;base64,',
        _drawOKPC(clockSpeed, artData, parts),
        '", "attributes": ',
        _getAttributes(parts, clockSpeed, artCollected),
        '}'
      )
    );
    return string(abi.encodePacked('data:application/json;base64,', json));
  }

  function renderArt(bytes memory art, uint256 colorIndex)
    public
    view
    returns (string memory)
  {
    // get svg
    OKPCParts.Color memory color = _parts.getColor(colorIndex);

    return
      string(
        abi.encodePacked(
          '<svg viewBox="0 0 24 16" xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges" height="512" width="512" fill="#',
          color.dark,
          '"><rect width="24" height="16" fill="#',
          color.light,
          '"/>',
          _drawArt(art),
          '</svg>'
        )
      );
  }

  function getParts(uint256 tokenId)
    public
    view
    override
    returns (Parts memory)
  {
    if (tokenId < 1 || tokenId > 8192) revert InvalidTokenID();
    Parts memory parts;

    if (tokenId <= 128) {
      parts.color = _parts.getColor((tokenId - 1) % _parts.NUM_COLORS());
      parts.word = _parts.getWord(tokenId - 1);
    } else {
      parts.color = _parts.getColor(
        uint256(keccak256(abi.encodePacked('COLOR', tokenId))) %
          _parts.NUM_COLORS()
      );
      parts.word = _parts.getWord(
        uint256(keccak256(abi.encodePacked('WORD', tokenId))) %
          _parts.NUM_WORDS()
      );
    }

    parts.headband = _parts.getHeadband(
      uint256(keccak256(abi.encodePacked('HEADBAND', tokenId))) %
        _parts.NUM_HEADBANDS()
    );
    parts.rightSpeaker = _parts.getSpeaker(
      uint256(keccak256(abi.encodePacked('RIGHT SPEAKER', tokenId))) %
        _parts.NUM_SPEAKERS()
    );
    parts.leftSpeaker = _parts.getSpeaker(
      uint256(keccak256(abi.encodePacked('LEFT SPEAKER', tokenId))) %
        _parts.NUM_SPEAKERS()
    );

    return parts;
  }

  // * SVG RENDERING * //
  function _drawOKPC(
    uint256 speed,
    bytes memory art,
    Parts memory parts
  ) private view returns (string memory) {
    bytes memory svg = abi.encodePacked(
      abi.encodePacked(
        '<svg viewBox="0 0 32 32" xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges" fill="#',
        parts.color.dark,
        '" height="512"><rect width="32" height="32" fill="#',
        parts.color.regular,
        '"/><rect x="4" y="8" width="24" height="16" fill="#',
        parts.color.light,
        '"/><rect width="32" height="1" x="0" y="5" /><rect width="32" height="1" x="0" y="26" /><path transform="translate(1,1)" d="',
        parts.headband.data,
        '"/><path transform="translate(1, 8)" d="',
        parts.leftSpeaker.data,
        '"/><path transform="translate(31, 8) scale(-1,1)" d="',
        parts.rightSpeaker.data,
        '"/><g transform="translate(4, 8)" fill-rule="evenodd" clip-rule="evenodd">'
      ),
      _drawArt(art),
      '</g>',
      _drawWord(parts.word),
      '<g transform="translate(19, 28)">',
      _drawClockSpeed(speed, parts),
      '</g></svg>'
    );

    return Base64.encode(svg);
  }

  function _drawArt(bytes memory artData)
    internal
    pure
    returns (string memory)
  {
    bytes memory rects = DynamicBuffer.allocate(2**16); // Allocate 64KB of memory, we will not use this much, but it's safe.
    uint256 offset = 8;

    // render 8 pixels at a time
    for (uint256 pixelNum = 0; pixelNum < 384; pixelNum += 8) {
      uint8 workingByte = uint8(artData[offset + (pixelNum / 8)]);
      uint256 y = uint256(pixelNum / 24);
      uint256 x = uint256(pixelNum % 24);

      for (uint256 i = 0; i < 8; i++) {
        // if the pixel is a 1, draw it
        if ((workingByte >> (7 - i)) & 1 == 1) {
          rects.appendSafe(
            abi.encodePacked(
              '<rect width="1" height="1" x="',
              toString(x + i),
              '" y="',
              toString(y),
              '"/>'
            )
          );
        }
      }
    }

    return string(rects);
  }

  function _drawWord(string memory word) internal view returns (bytes memory) {
    bytes memory wordBytes = bytes(word);
    bytes memory path;

    for (uint256 i = 0; i < wordBytes.length; i++) {
      if (wordBytes[i] != 0x0) {
        path = abi.encodePacked(
          path,
          '<path clip-rule="evenodd" fill-rule="evenodd" transform="translate(',
          toString(2 + i * 4),
          ',28)" d="',
          _font.getChar(wordBytes[i]),
          '"/>'
        );
      } else {
        break;
      }
    }

    return path;
  }

  function _drawClockSpeed(uint256 speed, Parts memory parts)
    internal
    pure
    returns (bytes memory)
  {
    bytes memory clockSpeedPixels = DynamicBuffer.allocate(2**16); // Allocate 64KB of memory, we will not use this much, but it's safe.
    bytes6 color;

    for (uint256 i = 0; i < 12; i++) {
      uint256 x = 10 - ((i / 2) * 2);
      uint256 y = (i % 2 == 0) ? 2 : 0;
      if (i < speed / 8) color = parts.color.light;
      else color = parts.color.dark;

      clockSpeedPixels.appendSafe(
        abi.encodePacked(
          '<rect width="1" height="1" x="',
          toString(x),
          '" y="',
          toString(y),
          '" fill="#',
          color,
          '"/>'
        )
      );
    }

    return clockSpeedPixels;
  }

  function _getAttributes(
    Parts memory parts,
    uint256 speed,
    uint256 artCollected
  ) internal pure returns (bytes memory) {
    return
      abi.encodePacked(
        '[{"trait_type":"Art Collected", "value":"',
        toString(artCollected),
        '"}, {"trait_type":"Word", "value":"',
        parts.word,
        '"}, {"trait_type": "Color", "value": "',
        parts.color.name,
        abi.encodePacked(
          '"}, {"trait_type": "Headband", "value": "',
          parts.headband.name,
          '"}, {"trait_type": "Right Speaker", "value": "',
          parts.rightSpeaker.name,
          '"}, {"trait_type": "Left Speaker", "value": "',
          parts.leftSpeaker.name,
          '"}, {"trait_type": "Clock Speed", "value": "',
          toString(speed)
        ),
        '"}]'
      );
  }

  // * UTILITIES * //
  function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

    if (value == 0) {
      return '0';
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
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
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
// Copyright (c) 2021 the ethier authors (github.com/divergencetech/ethier)

pragma solidity >=0.8.0;

/// @title DynamicBuffer
/// @author David Huber (@cxkoda) and Simon Fremaux (@dievardump). See also
///         https://raw.githubusercontent.com/dievardump/solidity-dynamic-buffer
/// @notice This library is used to allocate a big amount of container memory
//          which will be subsequently filled without needing to reallocate
///         memory.
/// @dev First, allocate memory.
///      Then use `buffer.appendUnchecked(theBytes)` or `appendSafe()` if
///      bounds checking is required.
library DynamicBuffer {
    /// @notice Allocates container space for the DynamicBuffer
    /// @param capacity The intended max amount of bytes in the buffer
    /// @return buffer The memory location of the buffer
    /// @dev Allocates `capacity + 0x60` bytes of space
    ///      The buffer array starts at the first container data position,
    ///      (i.e. `buffer = container + 0x20`)
    function allocate(uint256 capacity)
        internal
        pure
        returns (bytes memory buffer)
    {
        assembly {
            // Get next-free memory address
            let container := mload(0x40)

            // Allocate memory by setting a new next-free address
            {
                // Add 2 x 32 bytes in size for the two length fields
                // Add 32 bytes safety space for 32B chunked copy
                let size := add(capacity, 0x60)
                let newNextFree := add(container, size)
                mstore(0x40, newNextFree)
            }

            // Set the correct container length
            {
                let length := add(capacity, 0x40)
                mstore(container, length)
            }

            // The buffer starts at idx 1 in the container (0 is length)
            buffer := add(container, 0x20)

            // Init content with length 0
            mstore(buffer, 0)
        }

        return buffer;
    }

    /// @notice Appends data to buffer, and update buffer length
    /// @param buffer the buffer to append the data to
    /// @param data the data to append
    /// @dev Does not perform out-of-bound checks (container capacity)
    ///      for efficiency.
    function appendUnchecked(bytes memory buffer, bytes memory data)
        internal
        pure
    {
        assembly {
            let length := mload(data)
            for {
                data := add(data, 0x20)
                let dataEnd := add(data, length)
                let copyTo := add(buffer, add(mload(buffer), 0x20))
            } lt(data, dataEnd) {
                data := add(data, 0x20)
                copyTo := add(copyTo, 0x20)
            } {
                // Copy 32B chunks from data to buffer.
                // This may read over data array boundaries and copy invalid
                // bytes, which doesn't matter in the end since we will
                // later set the correct buffer length, and have allocated an
                // additional word to avoid buffer overflow.
                mstore(copyTo, mload(data))
            }

            // Update buffer length
            mstore(buffer, add(mload(buffer), length))
        }
    }

    /// @notice Appends data to buffer, and update buffer length
    /// @param buffer the buffer to append the data to
    /// @param data the data to append
    /// @dev Performs out-of-bound checks and calls `appendUnchecked`.
    function appendSafe(bytes memory buffer, bytes memory data) internal pure {
        uint256 capacity;
        uint256 length;
        assembly {
            capacity := sub(mload(sub(buffer, 0x20)), 0x40)
            length := mload(buffer)
        }

        require(
            length + data.length <= capacity,
            "DynamicBuffer: Appending out of bounds."
        );
        appendUnchecked(buffer, data);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

abstract contract OKPCArt {
  // *** CONFIG *** //
  uint8 public constant MIN_ART = 128;
  uint8 public constant MAX_ART_PER_ARTIST = 8;
  uint16 public constant MAX_COLLECTIONS_PER_ART = 512;
  uint256 public constant COLLECT_PRICE = 0.02 ether;

  // *** STORAGE *** //
  struct Art {
    address artist;
    string title;
    uint256 data1;
    uint256 data2;
    uint256 collected;
  }
  uint256 public _artCount;
  mapping(uint256 => Art) public art;
  mapping(address => uint256) public artistArtCount;
  mapping(uint256 => uint256) public activeArtForOKPC;
  mapping(uint256 => mapping(uint256 => bool)) public artCollectedByOKPC;
  mapping(uint256 => uint256) public artCountForOKPC;
  mapping(bytes32 => bool) internal _artHashRegister;
  mapping(address => bool) internal _denyList;

  event ArtCreated(uint256 indexed artId, address artist);
  event ArtCollected(uint256 pcId, uint256 artId);
  event ArtChanged(uint256 pcId, uint256 artId);
  event ArtTransferred(uint256 fromOKPCId, uint256 toOKPCId, uint256 artId);

  error InvalidArtData();
  error ArtNotCollected();
  error ArtCannotBeActive();
  error ArtCollectedMaximumTimes();
  error ArtAlreadyCollected();
  error DuplicateArt();
  error MaxArtAlreadyCreated();
  error ArtNotFound();
  error IncorrectPaymentAmount();

  // *** MODIFIERS *** //
  modifier onlyWhenArtExists(uint256 artId) {
    if (art[artId].artist == address(0)) revert ArtNotFound();
    _;
  }
  modifier onlyOKPCArtCollectorOf(uint256 pcId, uint256 artId) {
    if (!artCollectedByOKPC[pcId][artId]) revert ArtNotCollected();
    _;
  }

  function _createArt(
    address artist,
    string memory title,
    uint256 data1,
    uint256 data2
  ) internal {
    // Validate art data
    if (bytes(title).length > 16) revert InvalidArtData();
    // if (data1 == 0 && data2 == 0) revert InvalidArtData();

    // Check if artist has already created the maximum number of artworks
    if (artistArtCount[artist] == MAX_ART_PER_ARTIST)
      revert MaxArtAlreadyCreated();

    // Check uniqueness
    bytes32 hash = keccak256(abi.encodePacked(data1, data2));
    if (_artHashRegister[hash]) revert DuplicateArt();

    // Create art
    _artCount++;
    art[_artCount] = Art(artist, title, data1, data2, 0);
    artistArtCount[artist]++;
    _artHashRegister[hash] = true;

    emit ArtCreated(_artCount, artist);
  }

  // *** COLLECTOR FUNCTIONS *** //

  function _collectInitialArt(uint256 pcId) internal {
    // Choose initial art sequentially based on pcId
    uint256 artId = ((pcId - 1) % 128) + 1;

    // Store art collection data and emit event
    artCountForOKPC[pcId] = 1;
    artCollectedByOKPC[pcId][artId] = true;
    emit OKPCArt.ArtCollected(pcId, artId);

    // Set active artwork and emit event
    activeArtForOKPC[pcId] = artId;
    emit ArtChanged(pcId, artId);
  }

  function _collectArt(uint256 pcId, uint256 artId) internal {
    Art memory _art = art[artId];
    if (artCollectedByOKPC[pcId][artId]) revert ArtAlreadyCollected();
    if (_art.collected >= MAX_COLLECTIONS_PER_ART)
      revert ArtCollectedMaximumTimes();

    _art.collected++;
    artCollectedByOKPC[pcId][artId] = true;
    artCountForOKPC[pcId]++;
    emit ArtCollected(pcId, artId);
  }

  function _setArt(uint256 pcId, uint256 artId) internal {
    activeArtForOKPC[pcId] = artId;
    emit ArtChanged(pcId, artId);
  }

  // *** EXPANSIONS *** //

  // Only available via OKPCExpansions Community
  function _deleteArt(uint256 artId, bool addToDenyList) internal {
    artistArtCount[art[artId].artist]--;
    if (addToDenyList) _denyList[art[artId].artist] = true;
    delete art[artId].title;
    delete art[artId].data1;
    delete art[artId].data2;
    delete art[artId].artist;
  }

  // Only available via OKPCExpansions Community
  function _replaceDeletedArt(uint256 artId, Art calldata artwork) internal {
    if (art[artId].artist != address(0)) revert InvalidArtData();
    if (artwork.data1 == 0 && artwork.data2 == 0) revert InvalidArtData();
    if (bytes(artwork.title).length > 16) revert InvalidArtData();
    if (artwork.artist == address(0)) revert InvalidArtData();
    bytes32 hash = keccak256(abi.encodePacked(artwork.data1, artwork.data2));
    if (_artHashRegister[hash]) revert DuplicateArt();
    if (artistArtCount[artwork.artist] >= MAX_ART_PER_ARTIST)
      revert MaxArtAlreadyCreated();
    art[artId].artist = artwork.artist;
    art[artId].title = artwork.title;
    art[artId].data1 = artwork.data1;
    art[artId].data2 = artwork.data2;
  }

  // Only available via OKPCExpansions Marketplace
  function _transferArt(
    uint256 fromOKPCId,
    uint256 toOKPCId,
    uint256 artId
  ) internal {
    // Ensure fromOKPCId owns the art being transferred
    if (!artCollectedByOKPC[fromOKPCId][artId]) revert ArtNotCollected();
    // Ensure toOKPCId doesn't already own this art
    if (artCollectedByOKPC[toOKPCId][artId]) revert ArtAlreadyCollected();
    // Ensure fromOKPCId doesn't have this artwork active currently
    if (activeArtForOKPC[fromOKPCId] == artId) revert ArtCannotBeActive();

    // Remove art from first OKPC
    artCollectedByOKPC[fromOKPCId][artId] = false;
    artCountForOKPC[fromOKPCId]--;

    // Add art to second OKPC
    artCollectedByOKPC[toOKPCId][artId] = true;
    artCountForOKPC[toOKPCId]++;

    emit ArtTransferred(fromOKPCId, toOKPCId, artId);
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import {IOKPCParts} from './interfaces/IOKPCParts.sol';

contract OKPCParts is IOKPCParts {
  // parts
  Color[6] public colors;
  Vector[8] public headbands;
  Vector[8] public speakers;
  bytes4[128] public words;

  uint256 public constant NUM_COLORS = 6;
  uint256 public constant NUM_SPEAKERS = 8;
  uint256 public constant NUM_HEADBANDS = 8;
  uint256 public constant NUM_WORDS = 128;

  constructor() {
    _initColors();
    _initHeadbands();
    _initSpeakers();
    _initWords();
  }

  function getColor(uint256 index) public view override returns (Color memory) {
    if (index > NUM_COLORS - 1) revert IndexOutOfBounds(index, NUM_COLORS - 1);
    return colors[index];
  }

  function getHeadband(uint256 index)
    public
    view
    override
    returns (Vector memory)
  {
    if (index > NUM_HEADBANDS - 1)
      revert IndexOutOfBounds(index, NUM_HEADBANDS - 1);
    return headbands[index];
  }

  function getSpeaker(uint256 index)
    public
    view
    override
    returns (Vector memory)
  {
    if (index > NUM_SPEAKERS - 1)
      revert IndexOutOfBounds(index, NUM_SPEAKERS - 1);
    return speakers[index];
  }

  function getWord(uint256 index) public view override returns (string memory) {
    if (index > NUM_WORDS - 1) revert IndexOutOfBounds(index, NUM_WORDS - 1);
    return _toString(words[index]);
  }

  function _initColors() internal {
    // gray
    colors[0] = Color(
      bytes6('CCCCCC'),
      bytes6('838383'),
      bytes6('4D4D4D'),
      'Gray'
    );
    // green
    colors[1] = Color(
      bytes6('54F8B5'),
      bytes6('00DC82'),
      bytes6('037245'),
      'Green'
    );
    // blue
    colors[2] = Color(
      bytes6('80B3FF'),
      bytes6('2E82FF'),
      bytes6('003D99'),
      'Blue'
    );
    // purple
    colors[3] = Color(
      bytes6('DF99FF'),
      bytes6('C13CFF'),
      bytes6('750DA5'),
      'Purple'
    );
    // yellow
    colors[4] = Color(
      bytes6('FBDA9D'),
      bytes6('F8B73E'),
      bytes6('795106'),
      'Yellow'
    );
    // pink
    colors[5] = Color(
      bytes6('FF99D8'),
      bytes6('FF44B7'),
      bytes6('99005E'),
      'Pink'
    );
  }

  function _initHeadbands() internal {
    headbands[0] = Vector(
      'M2 3H1V0H2V2H4V3H2ZM3 0H5H6V3H5V1H3V0ZM11 0H9V1H11V3H12V0H11ZM14 0H13V3H14H16H17V0H16V2H14V0ZM19 0H21V1H19V3H18V0H19ZM27 0H25H24V3H25V1H27V0ZM20 3V2H22V0H23V3H22H20ZM26 2V3H28H29V0H28V2H26ZM8 3H10V2H8V0H7V3H8Z',
      '0'
    );
    headbands[1] = Vector(
      'M11 1H12V0H11V1ZM11 2H10V1H11V2ZM13 2H11V3H13V2ZM14 1H13V2H14V1ZM16 1V0H14V1H16ZM17 2H16V1H17V2ZM19 2V3H17V2H19ZM19 1H20V2H19V1ZM19 1V0H18V1H19ZM0 1H1V2H0V1ZM1 2H2V3H1V2ZM3 1V0H1V1H3ZM4 2V1H3V2H4ZM5 2H4V3H5V2ZM6 1H5V2H6V1ZM8 1V0H6V1H8ZM8 2H9V1H8V2ZM8 2H7V3H8V2ZM24 1H25V2H24V1ZM22 1V0H24V1H22ZM22 2H21V1H22V2ZM22 2H23V3H22V2ZM26 2V3H25V2H26ZM27 1V2H26V1H27ZM29 1H27V0H29V1ZM29 2V1H30V2H29ZM29 2V3H28V2H29Z',
      '1'
    );
    headbands[2] = Vector(
      'M3 0H1V1H3V2H1V3H3V2H4V3H6V2H4V1H6V0H4V1H3V0ZM27 0H29V1H27V0ZM27 2V1H26V0H24V1H26V2H24V3H26V2H27ZM27 2H29V3H27V2ZM10 0H12V1H10V0ZM10 2V1H9V0H7V1H9V2H7V3H9V2H10ZM10 2H12V3H10V2ZM18 0H20V1H18V0ZM21 1H20V2H18V3H20V2H21V3H23V2H21V1ZM21 1V0H23V1H21ZM16 0H15V1H14V3H15V2H16V0Z',
      '2'
    );
    headbands[3] = Vector(
      'M1 3H2H3V2H2V1H4V3H5H7H8V1H10V3H11H14V2V1H16V2V3H19H20V1H22V3H23H25H26V1H28V2H27V3H28H29V0H28H26H25V2H23V0H22H20H19V2H17V1H18V0H12V1H13V2H11V0H10H8H7V2H5V0H4H2H1V3Z',
      '3'
    );
    headbands[4] = Vector(
      'M2 1H1V0H2V1ZM2 2V1H3V2H2ZM2 2V3H1V2H2ZM28 1H29V0H28V1ZM28 2V1H27V2H28ZM28 2H29V3H28V2ZM4 1H5V2H4V3H5V2H6V1H5V0H4V1ZM25 1H26V0H25V1ZM25 2V1H24V2H25ZM25 2H26V3H25V2ZM7 1H8V2H7V3H8V2H9V1H8V0H7V1ZM22 1H23V0H22V1ZM22 2V1H21V2H22ZM22 2H23V3H22V2ZM10 1H11V2H10V3H11V2H12V1H11V0H10V1ZM16 1H14V0H16V1ZM16 2V1H17V2H16ZM14 2H16V3H14V2ZM14 2V1H13V2H14ZM19 1H20V0H19V1ZM19 2V1H18V2H19ZM19 2H20V3H19V2Z',
      '4'
    );
    headbands[5] = Vector(
      'M1 1H10V0H1V1ZM12 1H13V2H14V3H16V2H17V1H18V0H16V1V2H14V1V0H12V1ZM11 3H1V2H11V3ZM29 1H20V0H29V1ZM19 3H29V2H19V3Z',
      '5'
    );
    headbands[6] = Vector(
      'M2 1H3V2H2V1ZM2 1H1V2H2V3H3V2H4V1H3V0H2V1ZM6 1H7V2H6V1ZM6 1H5V2H6V3H7V2H8V1H7V0H6V1ZM11 1H10V0H11V1ZM11 2V1H12V2H11ZM10 2H11V3H10V2ZM10 2V1H9V2H10ZM28 1H27V0H28V1ZM28 2V1H29V2H28ZM27 2H28V3H27V2ZM27 2V1H26V2H27ZM24 1H23V0H24V1ZM24 2V1H25V2H24ZM23 2H24V3H23V2ZM23 2V1H22V2H23ZM20 1H19V0H20V1ZM20 2V1H21V2H20ZM19 2H20V3H19V2ZM19 2V1H18V2H19ZM16 2H14V1H16V2ZM16 2V3H17V2H16ZM16 1V0H17V1H16ZM14 1H13V0H14V1ZM14 2V3H13V2H14Z',
      '6'
    );
    headbands[7] = Vector(
      'M10 0H14V1H13V2H17V1H16V0H20V1H18V2H19V3H11V2H12V1H10V0ZM3 2H5V3H1V2H2V1H1V0H9V1H8V2H10V3H6V2H7V1H3V2ZM25 2H27V1H23V2H24V3H20V2H22V1H21V0H29V1H28V2H29V3H25V2Z',
      '7'
    );
  }

  function _initSpeakers() internal {
    speakers[0] = Vector(
      'M1 1H0V2H1V3H2V2H1V1ZM1 5H0V6H1V7H2V6H1V5ZM0 9H1V10H0V9ZM1 10H2V11H1V10ZM1 13H0V14H1V15H2V14H1V13Z',
      '0'
    );
    speakers[1] = Vector(
      'M1 1L1 0H0V1H1ZM1 2H2V1H1V2ZM1 2H0V3H1V2ZM1 10L1 11H0V10H1ZM1 9H2V10H1L1 9ZM1 9H0V8H1L1 9ZM1 4L1 5H0V6H1L1 7H2L2 6H1L1 5H2L2 4H1ZM1 13L1 12H2L2 13H1ZM1 14L1 13H0V14H1ZM1 14H2L2 15H1L1 14Z',
      '1'
    );
    speakers[2] = Vector(
      'M0 2H1V3H2L2 1H1L1 0H0V2ZM1 5H2L2 7H1V6H0V4H1L1 5ZM2 14H1L1 15H0V13H1V12H2L2 14ZM2 10L2 8H1V9H0V11H1L1 10H2Z',
      '2'
    );
    speakers[3] = Vector(
      'M1 1L1 0H0V1H1ZM1 1H2V2V3H1H0V2H1V1ZM1 5L1 4H2V5H1ZM1 5L1 6H2V7H1H0V6V5H1ZM1 13H0V12H1H2V13V14H1L1 13ZM1 14L1 15H0V14H1ZM2 9V8H1H0V9V10H1V11H2V10H1V9H2Z',
      '3'
    );
    speakers[4] = Vector(
      'M2 0H1V1H0V2H1V3H2V0ZM2 5H1V4H0V7H1V6H2V5ZM2 9H1V8H0V11H1V10H2V9ZM0 13H1V12H2V15H1V14H0V13Z',
      '4'
    );
    speakers[5] = Vector(
      'M2 0V1V2V3H0V2H1V1V0H2ZM0 4V5V6V7H2V6H1L1 5H2V4H0ZM2 10V11H0V10H1V9H0V8H2V9V10ZM0 12V13H1V14V15H2V14L2 13V12H0Z',
      '5'
    );
    speakers[6] = Vector(
      'M0 0V1L2 1V0H0ZM1 3V2H2V3H1ZM2 5V4H0V5H2ZM1 11V10H2V11H1ZM2 13V12H0V13H2ZM2 15V14H1V15H2ZM2 7V6H1V7H2ZM0 8V9H2V8H0Z',
      '6'
    );
    speakers[7] = Vector(
      'M2 1V2V3H0V2L1 2V1H2ZM1 11V10H0V9H2L2 10V11H1ZM2 14V13H0V14H1V15H2V14ZM1 5V6H0V7H2L2 6V5H1Z',
      '7'
    );
  }

  function _initWords() internal {
    words[0] = bytes4('WAIT');
    words[1] = bytes4('OK');
    words[2] = bytes4('INFO');
    words[3] = bytes4('HELP');
    words[4] = bytes4('WARN');
    words[5] = bytes4('ERR');
    words[6] = bytes4('BAD');
    words[7] = bytes4('OKPC');
    words[8] = bytes4('RARE');
    words[9] = bytes4('200%');
    words[10] = bytes4('GATO');
    words[11] = bytes4('MAGE');
    words[12] = bytes4('OOF');
    words[13] = bytes4('FUN');
    words[14] = bytes4('OKPC');
    words[15] = bytes4('POLY');
    words[16] = bytes4('FANG');
    words[17] = bytes4('PAIN');
    words[18] = bytes4('BOOT');
    words[19] = bytes4('DRAW');
    words[20] = bytes4('MINT');
    words[21] = bytes4('WORM');
    words[22] = bytes4('OKPC');
    words[23] = bytes4('OKPC');
    words[24] = bytes4('OKPC');
    words[25] = bytes4('OKPC');
    words[26] = bytes4('BEAT');
    words[27] = bytes4('MIDI');
    words[28] = bytes4('UP');
    words[29] = bytes4('HUSH');
    words[30] = bytes4('ACK');
    words[31] = bytes4('MOON');
    words[32] = bytes4('OKPC');
    words[33] = bytes4('UFO');
    words[34] = bytes4('SEE');
    words[35] = bytes4('WHAT');
    words[36] = bytes4('TRIP');
    words[37] = bytes4('NICE');
    words[38] = bytes4('YUP');
    words[39] = bytes4('SEEN');
    words[40] = bytes4('CUTE');
    words[41] = bytes4('OHNO');
    words[42] = bytes4('GROW');
    words[43] = bytes4('SKY');
    words[44] = bytes4('OPEN');
    words[45] = bytes4('OKPC');
    words[46] = bytes4('OKPC');
    words[47] = bytes4('ESC');
    words[48] = bytes4('404');
    words[49] = bytes4('PSA');
    words[50] = bytes4('BGS');
    words[51] = bytes4('OKPC');
    words[52] = bytes4('OKPC');
    words[53] = bytes4('DEAD');
    words[54] = bytes4('SK8');
    words[55] = bytes4('OKPC');
    words[56] = bytes4('CT');
    words[57] = bytes4('3310');
    words[58] = bytes4('DAO');
    words[59] = bytes4('BRAP');
    words[60] = bytes4('OKPC');
    words[61] = bytes4('OKPC');
    words[62] = bytes4('LVL');
    words[63] = bytes4('GFX');
    words[64] = bytes4('5000');
    words[65] = bytes4('OKPC');
    words[66] = bytes4('OKPC');
    words[67] = bytes4('SWRD');
    words[68] = bytes4('MEME');
    words[69] = bytes4('OKPC');
    words[70] = bytes4('OKPC');
    words[71] = bytes4('LIFE');
    words[72] = bytes4('OKPC');
    words[73] = bytes4('OKPC');
    words[74] = bytes4('OKPC');
    words[75] = bytes4('OKPC');
    words[76] = bytes4('ROSE');
    words[77] = bytes4('ROBE');
    words[78] = bytes4('OKOK');
    words[79] = bytes4('MEOW');
    words[80] = bytes4('KING');
    words[81] = bytes4('WISE');
    words[82] = bytes4('ROZE');
    words[83] = bytes4('NOBU');
    words[84] = bytes4('OKPC');
    words[85] = bytes4('OKPC');
    words[86] = bytes4('OKPC');
    words[87] = bytes4('OKPC');
    words[88] = bytes4('SWIM');
    words[89] = bytes4('OKPC');
    words[90] = bytes4('OKPC');
    words[91] = bytes4('YUM');
    words[92] = bytes4('SNAP');
    words[93] = bytes4('SAND');
    words[94] = bytes4('FISH');
    words[95] = bytes4('CITY');
    words[96] = bytes4('VIBE');
    words[97] = bytes4('MAKE');
    words[98] = bytes4('OKPC');
    words[99] = bytes4('OKPC');
    words[100] = bytes4('OKPC');
    words[101] = bytes4('OKPC');
    words[102] = bytes4('OKPC');
    words[103] = bytes4('OKPC');
    words[104] = bytes4('OKPC');
    words[105] = bytes4('OKPC');
    words[106] = bytes4('OKPC');
    words[107] = bytes4('OKPC');
    words[108] = bytes4('LOUD');
    words[109] = bytes4('RISE');
    words[110] = bytes4('LOVE');
    words[111] = bytes4('OKPC');
    words[112] = bytes4('OKPC');
    words[113] = bytes4('OKPC');
    words[114] = bytes4('REKT');
    words[115] = bytes4('BEAR');
    words[116] = bytes4('CODA');
    words[117] = bytes4('OKPC');
    words[118] = bytes4('OKPC');
    words[119] = bytes4('FLY');
    words[120] = bytes4('ZKP');
    words[121] = bytes4('OKPC');
    words[122] = bytes4('OKPC');
    words[123] = bytes4('OKPC');
    words[124] = bytes4('OKPC');
    words[125] = bytes4('OKPC');
    words[126] = bytes4('OKPC');
    words[127] = bytes4('OKPC');
  }

  function _toString(bytes4 b) private pure returns (string memory) {
    uint256 numChars = 0;

    for (uint256 i = 0; i < 4; i++) {
      if (b[i] == bytes1(0)) break;
      numChars++;
    }

    bytes memory result = new bytes(numChars);
    for (uint256 i = 0; i < numChars; i++) result[i] = b[i];

    return string(abi.encodePacked(result));
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

interface IOKPCFont {
  error CharacterNotFound();
  error NotSingleCharacter();

  function getChar(string memory char) external view returns (string memory);

  function getChar(bytes1) external view returns (string memory);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import {OKPCArt} from '../OKPCArt.sol';
import {IOKPCParts} from './IOKPCParts.sol';

interface IOKPCMetadata {
  error InvalidTokenID();
  error NotEnoughPixelData();

  struct Parts {
    IOKPCParts.Vector headband;
    IOKPCParts.Vector rightSpeaker;
    IOKPCParts.Vector leftSpeaker;
    IOKPCParts.Color color;
    string word;
  }

  function tokenURI(
    uint256 tokenId,
    uint256 clockSpeed,
    uint256 artCollected,
    OKPCArt.Art memory art
  ) external view returns (string memory);

  function renderArt(bytes memory art, uint256 colorIndex)
    external
    view
    returns (string memory);

  function getParts(uint256 tokenId) external view returns (Parts memory);
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

// TODO: rename from parts to something else?
interface IOKPCParts {
  // errors
  error IndexOutOfBounds(uint256 index, uint256 maxIndex);

  // structures
  struct Color {
    bytes6 light;
    bytes6 regular;
    bytes6 dark;
    string name;
  }

  struct Vector {
    string data;
    string name;
  }

  // functions
  function getColor(uint256 index) external view returns (Color memory);

  function getHeadband(uint256 index) external view returns (Vector memory);

  function getSpeaker(uint256 index) external view returns (Vector memory);

  // TODO: rename from word to something else? The name of the OKPC?
  function getWord(uint256 index) external view returns (string memory);
}