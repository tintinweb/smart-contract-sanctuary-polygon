// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.11;

import "@openzeppelin/contracts/utils/Strings.sol";
import "base64-sol/base64.sol";
import "./ITraitBagsRenderer.sol";

contract TraitBagsRendererV1 is ITraitBagsRenderer {
    using Strings for uint256;

    function _wrapImage(string memory frameSVG, string memory imageSVG)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "<svg height='350' width='350' xmlns='http://www.w3.org/2000/svg' shape-rendering='crispEdges'>",
                    "<style>text {fill:white; font-family:monospace}</style>",
                    frameSVG,
                    "<g transform='translate(10, 10)'>",
                    imageSVG,
                    "</g></svg>"
                )
            );
    }

    function _splitLine(bytes memory line, uint256 lineLength, uint256 maxLineLength)
        internal
        pure
        returns (string memory, string memory)
    {
        // starting at the maxLineLength-th position (roughly half of max 140 chars per trait)
        // move backwards to find the last space char, with its position stored in lineBreakChar
        uint256 lineBreakChar;
        for (uint256 i = maxLineLength; i > 0; i--) {
            if (line[i] == " ") {
                lineBreakChar = i;
                break;
            }
        }
        // apply line breaks according to lineBreakChar position
        bytes memory lineOne = new bytes(lineBreakChar);
        bytes memory lineTwo = new bytes(lineLength - lineBreakChar);
        for (uint256 i = 0; i < lineLength; i++) {
            if (i < lineBreakChar) {
                lineOne[i] = line[i];
            } else {
                lineTwo[i - lineBreakChar] = line[i];
            }
        }
        return (string(lineOne), string(lineTwo));
    }

    function _stackTraits(string[] memory traits)
        internal
        pure
        returns (string memory)
    {
        bytes memory traitBytes;
        uint256 traitLength;
        string memory traitsStack;
        string memory lineOne;
        string memory lineTwo;
        uint256 maxLineLength = 68; // max number of chars per line
        uint256 position = 18; // starting vertical y-position, as a percentage
        uint256 offset = 7; // spacing between lines, as a percentage

        for (uint256 i = 0; i < traits.length; i++) {
            traitBytes = bytes(traits[i]);
            traitLength = traitBytes.length;

            if (traitLength > maxLineLength) {
                (lineOne, lineTwo) = _splitLine(
                    traitBytes,
                    traitLength,
                    maxLineLength
                );
                traitsStack = string(
                    abi.encodePacked(
                        traitsStack,
                        "</text><text font-size='7px' x='3%' y='",
                        (position).toString(),
                        "%'>",
                        (i + 1).toString(),
                        ". ",
                        lineOne,
                        "</text><text font-size='7px' x='3%' y='",
                        (position + offset / 2).toString(),
                        "%'>",
                        lineTwo
                    )
                );
                position += offset + offset / 2;
            } else {
                traitsStack = string(
                    abi.encodePacked(
                        traitsStack,
                        "</text><text font-size='7px' x='3%' y='",
                        (position).toString(),
                        "%'>",
                        (i + 1).toString(),
                        ". ",
                        traits[i]
                    )
                );
                position += offset;
            }
        }
        return traitsStack;
    }

    function _genAttributes(
        string memory generation,
        string memory world,
        string memory category,
        string[] memory traitTypes,
        string[] memory traits
    ) internal pure returns (string memory) {
        string memory typesAndTraitsStack;
        for (uint256 i = 0; i < traits.length; i++) {
            typesAndTraitsStack = string(
                abi.encodePacked(
                    typesAndTraitsStack,
                    '{"trait_type":"',
                    traitTypes[i],
                    '","value":"',
                    traits[i],
                    '"},'
                )
            );
        }

        return
            string(
                abi.encodePacked(
                    "[",
                    typesAndTraitsStack,
                    '{"trait_type":"Frame","value":"',
                    string(abi.encodePacked("Gen ", generation)),
                    '"},{"trait_type":"Generation","value":"',
                    generation,
                    '"},{"trait_type":"World","value":"',
                    world,
                    '"},{"trait_type":"Category","value":"',
                    category,
                    '"}]'
                )
            );
    }

    function tokenURI(
        uint256 tokenId,
        uint256 generation,
        string memory world,
        string memory category,
        string[] memory traitTypes,
        string[] memory traits,
        string memory frameColor
    ) external pure returns (string memory) {
        string memory tokenIdString = tokenId.toString();
        string memory frameSVG = string(
            abi.encodePacked(
                "<rect height='350' width='350' style='fill:#000; stroke-width:20; stroke:#",
                frameColor,
                "'/>"
            )
        );

        string memory traitsStack = _stackTraits(traits);
        string memory imageSVG = string(
            abi.encodePacked(
                "<text x='3%' y='10%' font-size='26'>",
                category,
                "</text><text x='90%' y='10%' font-size='16px' text-anchor='end'>",
                world,
                traitsStack,
                "</text>"
            )
        );

        string memory attributes = _genAttributes(
            generation.toString(),
            world,
            category,
            traitTypes,
            traits
        );
        string memory imageCard = _wrapImage(frameSVG, imageSVG);
        string memory dataURI = string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name": "Trait Bag #',
                            tokenIdString,
                            '","description":"A 100% on-chain Trait Bag"',
                            ', "image":"',
                            imageCard,
                            '","external_url":"https://app.supercool.xyz/trait-bags/',
                            tokenIdString,
                            '", "attributes":',
                            attributes,
                            "}"
                        )
                    )
                )
            )
        );
        return dataURI;
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

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
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.11;

interface ITraitBagsRenderer {
    function tokenURI(
        uint256 tokenId,
        uint256 generation,
        string memory world,
        string memory category,
        string[] memory traitTypes,
        string[] memory traits,
        string memory frameColor
    ) external pure returns (string memory);
}