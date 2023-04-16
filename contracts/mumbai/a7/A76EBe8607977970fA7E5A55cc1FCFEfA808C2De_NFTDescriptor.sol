// SPDX-License-Identifier: GPL-3.0

/// @title A library used to construct ERC721 token URIs and SVG images

pragma solidity ^0.8.6;

import {Base64} from 'base64-sol/base64.sol';
import {MultiPartSVGsToSVG} from './MultiPartSVGsToSVG.sol';

library NFTDescriptor {
    struct TokenURIParams {
        string name;
        string description;
        string[] parts;
        string role;
        string background;
        string fill;
        bool outline;
    }

    /**
     * @notice Construct an ERC721 token URI.
     */
    function constructTokenURI(TokenURIParams memory params) public pure returns (string memory) {
        string memory image = generateSVGImage(
            MultiPartSVGsToSVG.SVGParams({
                parts: params.parts,
                background: params.background,
                role: params.role,
                fill: params.fill,
                outline: params.outline
            })
        );

        // prettier-ignore
        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked('{"name":"', params.name, '", "description":"', params.description, '", "image": "', 'data:image/svg+xml;base64,', image, '"}')
                    )
                )
            )
        );
    }

    /**
     * @notice Generate an SVG image for use in the ERC721 token URI.
     */
    function generateSVGImage(MultiPartSVGsToSVG.SVGParams memory params) public pure returns (string memory svg) {
        return Base64.encode(bytes(MultiPartSVGsToSVG.generateSVG(params)));
    }
}

// SPDX-License-Identifier: GPL-3.0

/// @title A library used to convert multi-part RLE compressed images to SVG

pragma solidity ^0.8.6;

import '@openzeppelin/contracts/utils/Strings.sol';

library MultiPartSVGsToSVG {
    struct SVGParams {
        string[] parts;
        string role;
        string background;
        string fill;
        bool outline;
    }

    /**
     * @notice Given SVGs image parts and color palettes, merge to generate a single SVG image.
     */
    function generateSVG(SVGParams memory params) internal pure returns (string memory svg) {
        // prettier-ignore
        return
            string(
                abi.encodePacked(
                    '<svg viewBox="0 0 32 32" xmlns="http://www.w3.org/2000/svg">',
                    _generateOutline(params),
                    '<rect width="100%" height="100%" fill="#',
                    params.background,
                    '" />',
                    '<g fill="#',
                    params.fill,
                    '">',
                    params.role,
                    '</g>',
                    _generateSVGDigits(params),
                    '</svg>'
                )
            );
    }

    /**
     * @notice Given SVG of each digit, generate svg group of digits
     */
    // prettier-ignore
    function _generateSVGDigits(SVGParams memory params)
        private
        pure
        returns (string memory svg)
    {
        string memory digits;
        uint16 translateX = 1700;
        for (uint8 p = 0; p < params.parts.length; p++) {
            digits = string(abi.encodePacked(digits, '<g transform="scale(0.01) translate(', Strings.toString(translateX), ',2800)">', params.parts[p], ' fill="#', params.fill, '" /></g>'));
            translateX += 300;
        }
        return digits;
    }

    /**
     * @notice Given SVG of each digit, generate svg group of digits
     */
    // prettier-ignore
    function _generateOutline(SVGParams memory params)
        private
        pure
        returns (string memory svg)
    {
        if (params.outline) {
            return string(abi.encodePacked('<style>.outline{fill:none;stroke:#', params.fill, ';stroke-miterlimit:10;stroke-width:0.1px;}</style>'));
        }
    }
}

// SPDX-License-Identifier: MIT

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