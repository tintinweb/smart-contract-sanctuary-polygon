// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Strings.sol";

contract PostChainSvg {
    using Strings for uint256;

    string private i_sunglassesSVG;
    string private i_hatSVG;

    constructor(string memory sunglassesSVG, string memory hatSVG) {
        i_sunglassesSVG = sunglassesSVG;
        i_hatSVG = hatSVG;
    }

    function generateSVG(
        uint256 tokenId,
        address creator,
        string memory post,
        uint256 totalComments
    ) internal view returns (string memory) {
        uint256 postId = tokenId;
        string memory creatorAddress = Strings.toHexString(uint256(uint160(creator)), 20);
        string memory creatorPost = post;
        string memory accessory;
        if (totalComments >= 5) {
            accessory = i_sunglassesSVG;
        }
        if (totalComments >= 10) {
            accessory = i_hatSVG;
        }

        string memory svg = string(
            abi.encodePacked(
                '<svg width="400" height="150" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
                "<defs>",
                '<path id="path1" d="M10,65 H290 M10,80 H270 M15,96 H270 M20,115"></path>'
                "</defs>",
                '<rect width="300" height="150" style="fill:Lavender;stroke-width:1;stroke:black"/>',
                '<circle cx="40" cy="40" fill="yellow" r="25" stroke="black" stroke-width="2"/>',
                accessory,
                '<g class="eyes">',
                '<circle cx="35" cy="37" r="5"/>',
                '<circle cx="49" cy="37" r="5"/>',
                "</g>",
                '<path d="M 32 48 q 10 10 20 0" style="fill:none; stroke: black; stroke-width: 2;" />',
                '<use xlink:href="#path1" x="0" y="50" />',
                '<text transform="translate(0,21)" font-size="15">',
                '<textPath  xlink:href="#path1">',
                creatorPost,
                "</textPath>",
                "</text>",
                '<text x="200" y="32" style="fill:rgb(110, 118, 125)" font-size="14">',
                "postchain:",
                postId.toString(),
                "</text>",
                '<text x="5" y="140" style="fill:rgb(110, 118, 125)" font-size="12">',
                "@",
                creatorAddress,
                "</text>",
                "</svg>"
            )
        );

        return svg;
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