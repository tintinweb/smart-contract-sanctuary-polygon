//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./Base64.sol";

library ItemLib {
    using Strings for uint256;

    function getMaterial(uint256 seed, string[16] calldata materials)
        public
        pure
        returns (string memory)
    {
        return pluck(seed, "MATERIAL", materials);
    }

    function getType(uint256 seed, string[16] calldata types)
        public
        pure
        returns (string memory)
    {
        return pluck(seed, "TYPE", types);
    }

    function getMajorModifier(uint256 seed, string[16] calldata majorModifiers)
        public
        pure
        returns (string memory)
    {
        return pluck(seed, "MAJORMOD", majorModifiers);
    }

    function getMinorModifier(uint256 seed, string[16] calldata minorModifiers)
        public
        pure
        returns (string memory)
    {
        return pluck(seed, "MINORMOD", minorModifiers);
    }

    function getRange(uint256 seed, string[16] calldata ranges)
        public
        pure
        returns (string memory)
    {
        return pluck(seed, "RANGE", ranges);
    }

    function getDecoration(uint256 seed, string[16] calldata decorations)
        public
        pure
        returns (string memory)
    {
        return pluck(seed, "DECORATION", decorations);
    }

    function getOrder(uint256 seed) public pure returns (string memory) {
        return
            pluck(
                seed,
                "ORDER",
                [
                    "Power",
                    "Giants",
                    "Titans",
                    "Skill",
                    "Perfection",
                    "Brilliance",
                    "Enlightenment",
                    "Protection",
                    "Anger",
                    "Rage",
                    "Fury",
                    "Vitriol",
                    "the Fox",
                    "Detection",
                    "Reflection",
                    "the Twins"
                ]
            );
    }

    function getName(
        string memory material,
        string memory range,
        string memory itemType,
        string memory order
    ) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    material,
                    " ",
                    range,
                    " ",
                    itemType,
                    " of ",
                    order
                )
            );
    }

    function _textElement(string memory y, string memory text)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '<text x="170" y="',
                    y,
                    '" class="base" text-anchor="middle">',
                    text,
                    "</text>"
                )
            );
    }

    function _styleTags(string memory color)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "<style>.base { fill: ",
                    color,
                    '; font-family: Luminari, serif; font-size: 16px; }</style><rect width="100%" height="100%" fill="rgb(253 240 221)" />'
                )
            );
    }

    function tokenSVG(
        string memory name,
        string memory majorModifier,
        string memory minorModifier,
        string memory decoration,
        string memory color,
        string memory svg
    ) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 400">',
                    _styleTags(color),
                    svg,
                    _textElement("300", name),
                    _textElement("325", majorModifier),
                    _textElement("350", minorModifier),
                    _textElement("375", decoration),
                    "</svg>"
                )
            );
    }

    function attributesJSON(
        string memory itemType,
        string memory range,
        string memory material,
        string memory majorModifier,
        string memory minorModifier,
        string memory decoration,
        string memory order
    ) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "[",
                    encodeAttribute("Type", itemType),
                    ",",
                    encodeAttribute("Range", range),
                    ",",
                    encodeAttribute("Material", material),
                    ",",
                    encodeAttribute("Major Modifier", majorModifier),
                    ",",
                    encodeAttribute("Minor Modifier", minorModifier),
                    ",",
                    encodeAttribute("Decoration", decoration),
                    ",",
                    encodeAttribute("Order", order),
                    "]"
                )
            );
    }

    function tokenJSON(
        uint256 tokenId,
        string memory name,
        string memory material,
        string memory itemType,
        string memory majorModifier,
        string memory minorModifier,
        string memory range,
        string memory decoration,
        string memory order,
        string memory svg
    ) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '{"name":"',
                    name,
                    " #",
                    tokenId.toString(),
                    '","description":"I hear that you and your bard have sold your lutes and bought flutes.","image":"data:image/svg+xml;base64,',
                    Base64.encode(bytes(svg)),
                    '","attributes":',
                    attributesJSON(
                        itemType,
                        range,
                        material,
                        majorModifier,
                        minorModifier,
                        decoration,
                        order
                    ),
                    "}"
                )
            );
    }

    function tokenURI(
        uint256 tokenId,
        string memory name,
        string memory material,
        string memory itemType,
        string memory majorModifier,
        string memory minorModifier,
        string memory range,
        string memory decoration,
        string memory order,
        string memory svg
    ) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            tokenJSON(
                                tokenId,
                                name,
                                material,
                                itemType,
                                majorModifier,
                                minorModifier,
                                range,
                                decoration,
                                order,
                                svg
                            )
                        )
                    )
                )
            );
    }

    function random(bytes memory seed) public pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(seed)));
    }

    function encodeAttribute(string memory attr, string memory value)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '{"trait_type":"',
                    attr,
                    '","value":"',
                    value,
                    '"}'
                )
            );
    }

    function pluck(
        uint256 seed,
        string memory keyPrefix,
        string[16] memory sourceArray
    ) internal pure returns (string memory) {
        uint256 rand = random(abi.encodePacked(keyPrefix, seed.toString()));
        string memory output = sourceArray[rand % sourceArray.length];
        return output;
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
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