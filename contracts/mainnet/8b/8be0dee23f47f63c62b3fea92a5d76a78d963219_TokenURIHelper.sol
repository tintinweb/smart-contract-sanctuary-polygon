/**
 *Submitted for verification at polygonscan.com on 2022-04-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes public constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

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
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
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

library TokenURIHelper {

    function intToString(uint256 value) public pure returns (string memory) {
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

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    function addressToString(address x) public pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(s);
    }

    function getTokenData(uint256 tokenId, string memory content, uint256 parentPostId, string memory basePostLink) public pure returns (string memory) {
        string[16] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 550 550"> <defs> <linearGradient id="Gradient1"> <stop class="stop1" offset="0%"/> <stop class="stop2" offset="50%"/> <stop class="stop3" offset="100%"/> </linearGradient> <linearGradient id="Gradient2" x1="" x2="1" y1="0" y2="1"> <stop offset="0%" stop-color="#833ab4"/> <stop offset="100%" stop-color="#1d85fd"/> </linearGradient> <style type="text/css"><![CDATA[ #rect1 { fill: url(#Gradient1); } .stop1 { stop-color: red; } .stop2 { stop-color: black; stop-opacity: 0; } .stop3 { stop-color: blue; } ]]></style><rect id="rect" x="25%" y="12%" width="50%" height="50%" rx="15"/><clipPath id="clip"><use href="#rect"/></clipPath></defs> <rect width="100%" height="100%" fill="url(#Gradient2)" /> <rect x="5%" y="5%" width="90%" height="85%" style="fill:#fff" rx="15" /> <text x="520" y="530" fill="#fff" text-anchor="end" font-size="1em">';
        parts[1] = 'View this post at ';
        parts[2] = basePostLink;
        parts[3] = intToString(tokenId);
        parts[4] = '</text>';
        parts[5] = '<foreignObject class="node" x="50" y="50" width="460" height="430" requiredFeatures="http://www.w3.org/TR/SVG11/feature#Extensibility">';

        if (parentPostId != 0) {
            parts[6] = '<div xmlns="http://www.w3.org/1999/xhtml" style="font-family: avenir; font-weight: bold; font-size: 14px; color: lightgrey; text-align: left; margin-bottom: 10px">';
            parts[7] = 'Reply to ';
            parts[8] = basePostLink;
            parts[9] = intToString(parentPostId);
            parts[10] = '</div>';
            parts[11] = '<div xmlns="http://www.w3.org/1999/xhtml" style="font-family: avenir; font-weight: bold; font-size: 25px; text-align: left;">';
            parts[12] = content;
            parts[13] = '</div>';
            parts[14] = '</foreignObject>';
            parts[15] = '</svg>';
        }
        else {
            parts[6] = '<div xmlns="http://www.w3.org/1999/xhtml" style="font-family: avenir; font-weight: bold; font-size: 25px; text-align: left;">';
            parts[7] = content;
            parts[8] = '</div>';
            parts[9] = '</foreignObject>';
            parts[10] = '</svg>';
        }

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6]));
        output = string(abi.encodePacked(output, parts[7], parts[8], parts[9], parts[10], parts[11], parts[12]));
        output = string(abi.encodePacked(output, parts[13], parts[14], parts[15]));

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "NFT Post. Id: ', intToString(tokenId), '", "description": "View at PostPlaza, a web3 social platform. ', basePostLink, intToString(tokenId), ' | ', content , '", "external_url": "', basePostLink, intToString(tokenId), '", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }
}