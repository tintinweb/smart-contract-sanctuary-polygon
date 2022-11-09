// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interface/IMetadataGenerated.sol";

contract MetadataGenerated is IMetadataGenerated {
    Parts parts;

    string public ipfs  = "https://ipfs.filebase.io/ipfs/";
    string public urlThumbnail="https://thumbnail-generator-production-189f.up.railway.app/";
    
    constructor(
        string[] memory _background,
        string[] memory _smoke,
        string[] memory _wings,
        string[] memory _base,
        string[] memory _jet,
        string[] memory _cockpit,
        string[] memory _description
    ) {
        addBackground(_background);
        addSmoke(_smoke);
        addWings(_wings);
        addBase(_base);
        addJet(_jet);
        addCockpit(_cockpit);
        addDescription(_description);
    }

    function addBackground(string[] memory _parts) public {
        Parts storage part = parts;
        for (uint256 i = 0; i < _parts.length; ) {
            part.background.push(_parts[i]);
            unchecked {
                ++i;
            }
        }
    }

    function addSmoke(string[] memory _parts) public {
        Parts storage part = parts;
        for (uint256 i = 0; i < _parts.length; ) {
            part.smoke.push(_parts[i]);
            unchecked {
                ++i;
            }
        }
    }

    function addWings(string[] memory _parts) public {
        Parts storage part = parts;
        for (uint256 i = 0; i < _parts.length; ) {
            part.wings.push(_parts[i]);
            unchecked {
                ++i;
            }
        }
    }

    function addBase(string[] memory _parts) public {
        Parts storage part = parts;
        for (uint256 i = 0; i < _parts.length; ) {
            part.base.push(_parts[i]);
            unchecked {
                ++i;
            }
        }
    }

    function addJet(string[] memory _parts) public {
        Parts storage part = parts;
        for (uint256 i = 0; i < _parts.length; ) {
            part.jet.push(_parts[i]);
            unchecked {
                ++i;
            }
        }
    }

    function addCockpit(string[] memory _parts) public {
        Parts storage part = parts;
        for (uint256 i = 0; i < _parts.length; ) {
            part.cockpit.push(_parts[i]);
            unchecked {
                ++i;
            }
        }
    }

    function addDescription(string[] memory _parts) public {
        Parts storage part = parts;
        for (uint256 i = 0; i < _parts.length; ) {
            part.description.push(_parts[i]);
            unchecked {
                ++i;
            }
        }
    }

    function generateSeed(uint256 _pilotId)
        public
        view
        override
        returns (Seed memory)
    {
        uint256 pseudorandomness = uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), _pilotId))
        );

        return
            Seed({
                background: uint48(
                    uint48(pseudorandomness) % parts.background.length
                ),
                smoke: uint48(
                    uint48(pseudorandomness >> 48) % parts.smoke.length
                ),
                wings: uint48(
                    uint48(pseudorandomness >> 96) % parts.wings.length
                ),
                base: uint48(
                    uint48(pseudorandomness >> 144) % parts.base.length
                ),
                jet: uint48(uint48(pseudorandomness >> 192) % parts.jet.length),
                cockpit: uint48(
                    uint48(pseudorandomness >> 240) % parts.cockpit.length
                ),
                description: uint48(
                    uint48(pseudorandomness >> 288) % parts.description.length
                )
            });
    }

    function svgGenerated(Seed calldata _seed)
        public
        view
        override
        returns (string memory)
    {
        string memory svg = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        "<svg xmlns='http://www.w3.org/2000/svg' width='350' height='350' viewbox='0 0 350 350' fill='none'><a href='https://rhizom.me/' target='_blank'>",
                        renderPart(parts.background[_seed.background]),
                        renderPart(parts.smoke[_seed.smoke]),
                        renderPart(parts.wings[_seed.wings]),
                        renderPart(parts.base[_seed.base]),
                        renderPart(parts.jet[_seed.jet]),
                        renderPart(parts.cockpit[_seed.cockpit]),
                        "</a></svg>"
                    )
                )
            )
        );

        return string(abi.encodePacked("data:image/svg+xml;base64,", svg));
    }

    function renderPart(string memory _parts) public view returns (string memory) {
        return string(abi.encodePacked("<image height='100%' width='100%'  href='",ipfs,_parts,"'/>"));
    }

    function tokenURI(uint256 _tokenId, Seed calldata _seed)
        public
        view
        override
        returns (string memory)
    {
       
        string memory image = svgGenerated(_seed);
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "pilot ',
                        Strings.toString(_tokenId),
                        '","image":"',thumbnailGenerator(_seed),
                        '", "description":"',parts.description[_seed.description],'", "animation_url": "',
                        image,
                        '"}'
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function thumbnailGenerator(Seed calldata _seed) public view returns(string memory){
         //0-0-0-0-0-0.png
        return string(abi.encodePacked(urlThumbnail,
        Strings.toString(_seed.background),"-",
        Strings.toString(_seed.smoke),"-",
        Strings.toString(_seed.wings),"-",
        Strings.toString(_seed.jet),"-",
        Strings.toString(_seed.base),"-",
        Strings.toString(_seed.cockpit),".png"));
    }

    function setIpfsUri(string memory _uri) external{
        ipfs=_uri;
    }

    function setUrlThumbnail(string memory _uri) external{
        urlThumbnail=_uri;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;



interface IMetadataGenerated {
    struct Seed {
          uint48 background;
          uint48 smoke;
          uint48 wings;
          uint48 base;
          uint48 jet;
          uint48 cockpit;
          uint48 description;
    }

    struct Parts {
        string[] background;
        string[] smoke;
        string[] wings;
        string[] base;
        string[] jet;
        string[] cockpit;
        string[] description;
    }
    
    function generateSeed(uint _pilotId) external view  returns(Seed memory);

    function svgGenerated(Seed calldata _seed) external view returns(string memory);

    function tokenURI(uint _tokenId,Seed calldata _seed) external view returns (string memory);
}