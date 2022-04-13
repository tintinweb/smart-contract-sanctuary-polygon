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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

interface IRenderer {
    /**
     * @dev Returns the base64 encoded image data.
     */
    function render(bytes calldata seed)
        external
        view
        returns (string memory);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Base64.sol";

import "./IRenderer.sol";

contract RendererShields is IRenderer {
    function render(bytes calldata seed)
        external
        view
        override
        returns (string memory)
    {
        // TODO use the seed together with the Shields API to render a specific combination of elements
        return
            string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    Base64.encode(abi.encodePacked(_getSVG()))
                )
            );
    }

    function _getSVG() private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 220 264">',
                    '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#0000ff"/><path d="M110 132c-.576-2.671-1.152-5.341.827-7.716 3.958-4.749 10.922.34 14.88-4.409s-2.3-10.682 1.654-15.431c3.954-4.749 10.923.339 14.88-4.41 3.957-4.749-2.3-10.682 1.654-15.431 3.954-4.749 10.923.339 14.88-4.41A5.662 5.662 0 0 0 160 77.7v56.277a6.348 6.348 0 0 1-4.8 2.33c-6.182 0-6.732-8.608-12.913-8.608s-6.732 8.608-12.914 8.608c-6.182 0-6.731-8.608-12.914-8.608-3.093.001-4.776 2.149-6.459 4.301Zm-4.3-32.283c0-6.182 8.609-6.732 8.609-12.914 0-6.182-8.609-6.731-8.609-12.914a5.728 5.728 0 0 1 .314-1.889H60c3.068 0 5.765.192 7.84 2.682 3.957 4.749-2.3 10.683 1.653 15.432 3.953 4.749 10.923-.34 14.881 4.409s-2.3 10.683 1.653 15.432c3.953 4.749 10.923-.34 14.88 4.409 3.957 4.749-2.3 10.682 1.654 15.431 1.978 2.374 4.709 2.289 7.44 2.2-2.152-1.683-4.3-3.366-4.3-6.456 0-6.182 8.609-6.732 8.609-12.914 0-6.182-8.61-6.725-8.61-12.908Zm3.773 97.27c.177 0 .353.013.531.013a49.937 49.937 0 0 0 41.32-21.846 5.858 5.858 0 0 0-.812-1.268c-3.957-4.749-10.923.34-14.88-4.409-3.957-4.749 2.3-10.683-1.654-15.432-3.954-4.749-10.922.34-14.88-4.409s2.3-10.682-1.654-15.432c-1.979-2.374-4.709-2.289-7.44-2.2-1.683 2.152-3.366 4.3-6.456 4.3-6.182 0-6.731-8.608-12.913-8.608S83.9 136.3 77.717 136.3c-6.183 0-6.732-8.6-12.917-8.6a6.369 6.369 0 0 0-4.8 2.332V147a49.81 49.81 0 0 0 13.529 34.184 5.69 5.69 0 0 0 2.578-1.787c3.957-4.749-2.3-10.682 1.653-15.432s10.923.34 14.881-4.409-2.3-10.682 1.653-15.431c3.953-4.749 10.923.34 14.88-4.409 1.978-2.375 1.4-5.045.826-7.716 2.152 1.683 4.305 3.366 4.305 6.456 0 6.182-8.609 6.731-8.609 12.913s8.608 6.731 8.608 12.913-8.604 6.733-8.604 12.918 8.608 6.731 8.608 12.913c-.008 3.344-2.525 5.041-4.839 6.874h.004Z" fill="#000000"/>',
                    "</svg>"
                )
            );
    }
}