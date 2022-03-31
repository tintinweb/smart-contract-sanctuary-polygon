// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./IPresentation.sol";

contract PseudoCodePresentation is IPresentation {
    string private name = "pseudo code";
    string private description = "presented in pseudo code";

    function getFontSource() private pure returns (string memory) {
        return
            "src:url(data:application/font-woff2;charset=utf-8;base64,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)format('woff2');";
    }

    function getBase64Svg(
        uint256 tokenId,
        string memory day,
        string memory morning,
        string memory afternoon,
        string memory night
    ) private pure returns (string memory) {
        string memory tokenIdString = toHexStringUpperCase(
            Strings.toHexString(tokenId, 8)
        );
        bytes memory svg = abi.encodePacked(
            "<svg width='1000' height='1000' viewBox='0 0 1000 1000' xmlns='http://www.w3.org/2000/svg'><style>@font-face{font-family:'j';",
            getFontSource(),
            "font-weight:700;font-style:normal}tspan{fill:#fff;font-family:'j',monospace;font-size:30px}</style><rect width='100%' height='100%'/><text><tspan x='60' y='350'>PROGRAM aDayOfAJacky",
            day
        );

        svg = abi.encodePacked(
            svg,
            "</tspan><tspan x='96' dy='1em'>GET secret</tspan><tspan x='96' dy='1em'>IV = ",
            tokenIdString,
            "</tspan><tspan x='96' dy='1em'>morning = ",
            morning,
            "</tspan><tspan x='96' dy='1em'>afternoon = ",
            afternoon,
            "</tspan><tspan x='96' dy='1em'>night = ",
            night,
            "</tspan><tspan x='96' dy='1em'>IF decrypting morning by AES256 succeeds</tspan><tspan x='132' dy='1em'>PRINT decrypted morning</tspan><tspan x='96' dy='1em'>IF decrypting afternoon by AES256 succeeds</tspan><tspan x='132' dy='1em'>PRINT decrypted afternoon</tspan><tspan x='96' dy='1em'>IF decrypting night by AES256 succeeds</tspan><tspan x='132' dy='1em'>PRINT decrypted night</tspan></text></svg>"
        );
        return Base64.encode(svg);
    }

    function metadata(
        uint256 tokenId,
        string memory day,
        string memory timestamp,
        string memory passwordRecoveryQuestion,
        string memory morning,
        string memory afternoon,
        string memory night
    ) external view override returns (string memory) {
        bytes memory metadataJson = abi.encodePacked(
            '{"name":"',
            name,
            '","description":"',
            description,
            '","image":"data:image/svg+xml;base64,',
            getBase64Svg(tokenId, day, morning, afternoon, night),
            '","attributes":[{"display_type":"date","trait_type":"day","value":',
            timestamp,
            '},{"trait_type":"password recovery question","value":"',
            passwordRecoveryQuestion
        );

        metadataJson = abi.encodePacked(
            metadataJson,
            '"},{"trait_type":"morning","value":"',
            morning,
            '"},{"trait_type":"afternoon","value":"',
            afternoon,
            '"},{"trait_type":"night","value":"',
            night,
            '"}]}'
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(metadataJson)
                )
            );
    }

    function toHexStringUpperCase(string memory value)
        private
        pure
        returns (string memory)
    {
        bytes memory valueBytes = bytes(value);
        bytes memory upperValueBytes = new bytes(valueBytes.length);
        for (uint256 i = 0; i < valueBytes.length; i++) {
            bytes1 char = valueBytes[i];
            if (i != 0 && i != 1 && char >= 0x61 && char <= 0x7A) {
                upperValueBytes[i] = bytes1(uint8(char) - 32);
            } else {
                upperValueBytes[i] = char;
            }
        }
        return string(upperValueBytes);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Base64.sol)

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
pragma solidity ^0.8.13;

interface IPresentation {
    function metadata(
        uint256 tokenId,
        string memory day,
        string memory timestamp,
        string memory passwordRecoveryQuestion,
        string memory morning,
        string memory afternoon,
        string memory night
    ) external view returns (string memory);
}