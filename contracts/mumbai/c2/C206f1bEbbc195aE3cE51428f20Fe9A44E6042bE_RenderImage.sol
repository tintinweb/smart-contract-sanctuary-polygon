/**
 *Submitted for verification at polygonscan.com on 2022-03-27
*/

// SPDX-License-Identifier: MIT LICENSE

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

// File: contracts/RenderImage.sol




contract RenderImage {

    mapping (address => uint256) private retiredBalanceOf;

    function updateRetiredAmount(address addr, uint256 amount) public {
        retiredBalanceOf[addr] += amount;
    }

    function genCert(address addr) public view returns (string memory) {

        return string(
            abi.encodePacked(
                '<svg class="svgBody" width="250" height="150" viewBox="0 0 300 200" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
                '<rect class="o" width="250" height="150"/>',
                '<rect class="n" x="2.48" y="2.26" width="245" height="145"/>',
                '<text class="h"><tspan x="18" y="30" class="med">X</tspan></text>',
                '<text class="i"><tspan class="med" x="32" y="30">CO2 Carbon Offset</tspan></text>',
                '<text x="15" y="57" class="b small">', Strings.toString(retiredBalanceOf[addr]), ' Tons Offset</text>',
                '<text x="15" y="75" class="b tiny">', addressToString(addr) ,'</text>',
                '<path class="o" d="M53.96,90.23l-7.43-2.53c-.09-.03-.21-.05-.33-.05s-.24,.02-.33,.05l-7.44,2.53c-.18,.06-.33,.27-.33,.46v10.55c0,.19,.13,.45,.28,.57l7.54,5.88c.07,.06,.18,.09,.28,.09s.2-.03,.28-.09l7.54-5.88c.15-.12,.28-.37,.28-.57v-10.55c0-.19-.14-.4-.33-.46Zm-3.77,3.74l-4.65,6.4c-.11,.16-.33,.19-.49,.07-.03-.02-.06-.05-.07-.07l-2.76-3.81c-.08-.11,0-.28,.14-.28h1.21c.11,0,.22,.06,.28,.15l1.42,1.95,3.3-4.55c.07-.09,.17-.15,.28-.15h1.21c.14,0,.22,.17,.14,.28Z"/>',
                '<text class="j sm gr"><tspan x="60" y="102">Blockchain Certified</tspan></text>',
                '<text class="j jf" transform="translate(14.68 120.15)">',
                '<tspan x="0" y="0">This image is rendered directly from the blockchain</tspan>',
                '<tspan x="0" y="10.34">to serve as cryptographic proof of carbon offset for</tspan>',
                '<tspan x="0" y="20.67">the listed wallet address from retired XCO2 tokens.</tspan>',
                '<style>.svgBody {font-family: "Courier New" } .tiny {font-size:8.8px; } .small {font-size: 14px;} .med{font-size:22px;} .sm {font-size:15px;} .gr{fill:#157e23}.h,.i,.j{font-family:Montserrat-Regular, Montserrat, "Courier New";}.i,.jf{fill:#6d6e71;}.n{fill:#fff;}.o,.h{fill:#39b54a;}.h{font-size:21.36px;}.jf{font-size:8.61px;}</style>',
                '</svg>'
            ));

        // string memory image = string(abi.encodePacked("data:image/svg+xml;base64,",base64(svgData)));

        // return svgData;
    }

    // THIS RETURNS ADDRESS IN LOWER CASE
    function addressToString(address addr) internal pure returns (string memory){
        // Cast Address to byte array
        bytes memory addressBytes = abi.encodePacked(addr);

        // Byte array for the new string
        bytes memory stringBytes = new bytes(42);

        // Assign firs two bytes to '0x'
        stringBytes[0] = '0';
        stringBytes[1] = 'x';

        // Iterate over every byte in the array
        // Each byte contains two hex digits that gets individually converted
        // into their ASCII representation and add to the string
        for (uint256 i = 0; i < 20; i++) {
            // Convert hex to decimal values
            uint8 leftValue = uint8(addressBytes[i]) / 16;
            uint8 rightValue = uint8(addressBytes[i]) - 16 * leftValue;

            // Convert decimals to ASCII Values
            bytes1 leftChar = leftValue < 10 ? bytes1(leftValue + 48) : bytes1(leftValue + 87);
            bytes1 rightChar = rightValue < 10 ? bytes1(rightValue + 48) : bytes1(rightValue + 87);

            // Add ASCII values to the string byte array
            stringBytes[2 * i + 3] = rightChar;
            stringBytes[2 * i + 2] = leftChar;
        }

        // Cast byte array to string and return
        return string(stringBytes);
    }

    /** BASE 64 - Written by Brech Devos */

    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function base64(bytes memory data) internal pure returns (string memory) {
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