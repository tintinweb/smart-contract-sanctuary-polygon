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
pragma solidity ^0.8.18;
import "@openzeppelin/contracts/utils/Base64.sol";

library Gen3ImageLib2 {
    function generateCharacter(string memory _result, string memory _color1, string memory _color3, string memory _color4, string memory _color5, string memory _chromosome ) external pure returns(string memory){
        if (keccak256(abi.encodePacked(_chromosome)) == keccak256(abi.encodePacked("XX")) ){
            _chromosome = _color1;
        }else{
            _chromosome = _color3;
        }

        string memory result = _result;
        {
            result = string(abi.encodePacked(
                result,
                '<rect x="32" y="48" width="16" height="8" fill="',_color1,'"/>',
                '<rect x="48" y="48" width="32" height="8" fill="',_color3,'"/>',
                '<rect x="80" y="48" width="16" height="8" fill="',_color1,'"/>',
                '<rect x="96" y="48" width="8" height="8" fill="',_color3,'"/>',
                '<rect x="104" y="48" width="8" height="8" fill="',_color5,'"/>',
                '<rect x="112" y="48" width="16" height="8" fill="',_color4,'"/>',
                '<rect x="0" y="56" width="8" height="8" fill="',_color4,'"/>',
                '<rect x="8" y="56" width="8" height="8" fill="',_color5,'"/>',
                '<rect x="16" y="56" width="8" height="8" fill="',_color3,'"/>'
                
            ));
        }
        {
            result = string(abi.encodePacked(
              result,
              '<rect x="24" y="56" width="8" height="8" fill="',_color1,'"/>',
                '<rect x="32" y="56" width="8" height="8" fill="',_color5,'"/>',
                '<rect x="40" y="56" width="8" height="8" fill="',_color3,'"/>',
                '<rect x="48" y="56" width="8" height="8" fill="',_color4,'"/>',
                '<rect x="56" y="56" width="16" height="8" fill="',_color3,'"/>',
                '<rect x="72" y="56" width="8" height="8" fill="',_color4,'"/>',
                '<rect x="80" y="56" width="8" height="8" fill="',_color3,'"/>',
                '<rect x="88" y="56" width="8" height="8" fill="',_color5,'"/>'
                
            ));
        }
        {
            result = string(abi.encodePacked(
              result,
              '<rect x="96" y="56" width="8" height="8" fill="',_color1,'"/>',
                '<rect x="104" y="56" width="8" height="8" fill="',_color3,'"/>',
                '<rect x="112" y="56" width="8" height="8" fill="',_color5,'"/>',
                '<rect x="120" y="56" width="8" height="8" fill="',_color4,'"/>',
                '<rect x="0" y="64" width="8" height="8" fill="',_color4,'"/>',
                '<rect x="8" y="64" width="16" height="8" fill="',_chromosome,'"/>',
                '<rect x="24" y="64" width="8" height="8" fill="',_color1,'"/>',
                '<rect x="32" y="64" width="8" height="8" fill="',_color5,'"/>',
                '<rect x="40" y="64" width="8" height="8" fill="',_color3,'"/>',
                '<rect x="48" y="64" width="8" height="8" fill="',_color5,'"/>'
                
            ));
        }
        {
            result = string(abi.encodePacked(
              result,
              '<rect x="56" y="64" width="16" height="8" fill="',_color4,'"/>',
                '<rect x="72" y="64" width="8" height="8" fill="',_color5,'"/>',
                '<rect x="80" y="64" width="8" height="8" fill="',_color3,'"/>',
                '<rect x="88" y="64" width="8" height="8" fill="',_color5,'"/>',
                '<rect x="96" y="64" width="8" height="8" fill="',_color1,'"/>',
                '<rect x="104" y="64" width="16" height="8" fill="',_chromosome,'"/>',
                '<rect x="120" y="64" width="8" height="8" fill="',_color4,'"/>',
                '<rect x="8" y="72" width="8" height="8" fill="',_color5,'"/>',
                '<rect x="16" y="72" width="24" height="8" fill="',_color3,'"/>',
                '<rect x="40" y="72" width="48" height="8" fill="',_color5,'"/>'
                
                  
            ));
        }
        {
            result = string(abi.encodePacked(
                result,
                '<rect x="88" y="72" width="24" height="8" fill="',_color3,'"/>',
                '<rect x="112" y="72" width="8" height="8" fill="',_color5,'"/>',
                '<rect x="8" y="80" width="8" height="8" fill="',_color1,'"/>',
                '<rect x="16" y="80" width="96" height="8" fill="',_color5,'"/>',
                '<rect x="112" y="80" width="8" height="8" fill="',_color1,'"/>'                
            ));
        }
        {
            result = string(abi.encodePacked(
                result,
                '<rect x="0" y="88" width="8" height="8" fill="',_color1,'"/>',
                '<rect x="8" y="88" width="8" height="8" fill="',_color4,'"/>',
                '<rect x="16" y="88" width="16" height="8" fill="',_color1,'"/>',
                '<rect x="32" y="88" width="8" height="8" fill="',_color4,'"/>',
                '<rect x="40" y="88" width="8" height="8" fill="',_color5,'"/>',
                '<rect x="48" y="88" width="8" height="8" fill="',_color4,'"/>',
                '<rect x="56" y="88" width="8" height="8" fill="',_color5,'"/>',
                '<rect x="64" y="88" width="16" height="8" fill="',_color4,'"/>',
                '<rect x="80" y="88" width="8" height="8" fill="',_color5,'"/>',
                '<rect x="88" y="88" width="8" height="8" fill="',_color4,'"/>'
                
            ));
        }
        {
            result = string(abi.encodePacked(
                result,
                '<rect x="96" y="88" width="16" height="8" fill="',_color1,'"/>',
                '<rect x="112" y="88" width="8" height="8" fill="',_color4,'"/>',
                '<rect x="120" y="88" width="8" height="8" fill="',_color1,'"/>',
                '<rect x="0" y="96" width="8" height="8" fill="',_color1,'"/>',
                '<rect x="8" y="96" width="16" height="8" fill="',_color4,'"/>',
                '<rect x="24" y="96" width="8" height="8" fill="',_color3,'"/>',
                '<rect x="32" y="96" width="64" height="8" fill="',_color5,'"/>',
              '<rect x="96" y="96" width="8" height="8" fill="',_color3,'"/>',
                '<rect x="104" y="96" width="16" height="8" fill="',_color4,'"/>'
                
            ));
        }
        {
            result = string(abi.encodePacked(
              result,
              '<rect x="120" y="96" width="8" height="8" fill="',_color1,'"/>',
                '<rect x="8" y="104" width="16" height="8" fill="',_color1,'"/>',
                '<rect x="24" y="104" width="8" height="8" fill="',_color3,'"/>',
                '<rect x="32" y="104" width="16" height="8" fill="',_color4,'"/>',
                '<rect x="48" y="104" width="32" height="8" fill="',_color5,'"/>',
                '<rect x="80" y="104" width="16" height="8" fill="',_color4,'"/>',
                '<rect x="96" y="104" width="8" height="8" fill="',_color3,'"/>'
            ));
        }
        {
            result = string(abi.encodePacked(
                result,
                '<rect x="104" y="104" width="16" height="8" fill="',_color1,'"/>',
                '<rect x="0" y="112" width="24" height="8" fill="#0000006B"/>',
                '<rect x="24" y="112" width="8" height="8" fill="',_color1,'"/>',
                '<rect x="32" y="112" width="24" height="8" fill="',_color3,'"/>',
                '<rect x="56" y="112" width="16" height="8" fill="',_color1,'"/>',
                '<rect x="72" y="112" width="24" height="8" fill="',_color3,'"/>',
                '<rect x="96" y="112" width="8" height="8" fill="',_color1,'"/>',
                '<rect x="104" y="112" width="24" height="8" fill="#0000006B"/>'

            ));
        }
        {
            result = string(abi.encodePacked(
                result,
                '<rect x="8" y="120" width="24" height="8" fill="#0000006B"/>',
                '<rect x="32" y="120" width="24" height="8" fill="',_color1,'"/>',
                '<rect x="56" y="120" width="16" height="8" fill="#0000006B"/>',
                '<rect x="72" y="120" width="24" height="8" fill="',_color1,'"/>',
                '<rect x="96" y="120" width="24" height="8" fill="#0000006B"/>',
                '</svg>'
            ));
        }


        bytes memory svg = abi.encodePacked(result);
        return string(
            abi.encodePacked(
                "data:image/svg+xml;base64,",
                Base64.encode(svg)
            ));
    }
}