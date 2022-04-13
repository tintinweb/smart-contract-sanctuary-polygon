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
import "./Utils.sol";
import "./SVG.sol";

contract RendererBonfire is IRenderer {
    function render(bytes calldata seed)
        external
        view
        override
        returns (string memory)
    {
        uint256 byteIdx = 0;

        // First byte in seed is the uint8 for SVG selection
        uint8 svgIdx = _getNumber(seed, byteIdx);
        byteIdx++;

        // 3 x 3 bytes for the colors
        string[] memory colors = new string[](4);
        colors[0] = _getColor(seed, byteIdx);
        byteIdx += 3;
        colors[1] = _getColor(seed, byteIdx);
        byteIdx += 3;
        colors[2] = _getColor(seed, byteIdx);
        byteIdx += 3;
        colors[3] = _getColor(seed, byteIdx);
        byteIdx += 3;

        // Next byte indicates whether this is two-line text
        bool isTwoLine = _getBool(seed, byteIdx);
        byteIdx++;

        string[] memory lines = new string[](2);

        if (isTwoLine) {
            // One byte for line1 length
            uint8 lineByteLength = _getNumber(seed, byteIdx);
            byteIdx++;

            string memory line = string(
                utils.sub(seed, byteIdx, byteIdx + lineByteLength)
            );
            byteIdx += lineByteLength;
            lines[0] = line;

            // One byte for line2 length
            lineByteLength = _getNumber(seed, byteIdx);
            byteIdx++;

            line = string(utils.sub(seed, byteIdx, byteIdx + lineByteLength));
            byteIdx += lineByteLength;
            lines[1] = line;
        } else {
            // Any subsequent bytes are text
            string memory text = string(utils.sub(seed, 14, seed.length));
            lines[0] = text;
            lines[1] = utils.NULL;
        }

        return
            string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    Base64.encode(
                        abi.encodePacked(_getSVG(svgIdx, lines, colors))
                    )
                )
            );
    }

    function _getSVG(
        uint8 idx,
        string[] memory lines,
        string[] memory colors
    ) private pure returns (string memory) {
        // TODO use idx to render other SVGs

        // Render SVG based on idx & colors
        string memory svgString = _renderFlameSVG(colors);

        // Render text
        string memory text;
        if (utils.stringsEqual(lines[1], utils.NULL)) {
            // Single-line
            text = _renderText(lines[0], colors[1], "10");
        } else {
            // Multi-line
            text = string.concat(
                _renderText(lines[0], colors[1], "0"),
                _renderText(lines[1], colors[1], "15")
            );
        }

        return
            string(
                abi.encodePacked(
                    '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 100 100">',
                    svgString,
                    text,
                    "<style>@font-face {font-family: 'Roboto Condensed';font-style: normal;font-weight: 700;src: url(https://fonts.gstatic.com/s/robotocondensed/v24/ieVi2ZhZI2eCN5jzbjEETS9weq8-32meGCQYbw.woff2) format('woff2');unicode-range: U+0000-00FF, U+0131, U+0152-0153, U+02BB-02BC, U+02C6, U+02DA, U+02DC, U+2000-206F, U+2074, U+20AC, U+2122, U+2191, U+2193, U+2212, U+2215, U+FEFF, U+FFFD;}</style>",
                    "</svg>"
                )
            );
    }

    function _renderFlameSVG(string[] memory colors)
        private
        pure
        returns (string memory)
    {
        return
            string.concat(
                svg.path(
                    string.concat(
                        svg.prop(
                            "d",
                            "M20.6241 29.2703C4.45881 45.436 4.45881 71.6452 20.6241 87.811C36.7898 103.976 62.9993 103.976 79.1646 87.811C95.3301 71.6452 95.3301 45.436 79.1646 29.2703L49.8943 0L20.6241 29.2703V29.2703Z"
                        ),
                        svg.prop("fill", "url(#paint0)")
                    ),
                    utils.NULL
                ),
                svg.path(
                    string.concat(
                        svg.prop(
                            "d",
                            "M26.4782 43.4032C13.546 56.3357 13.546 77.3035 26.4782 90.2357C39.4105 103.168 60.3782 103.168 73.3107 90.2357C86.243 77.3032 86.243 56.3357 73.3107 43.4032L49.8945 19.987L26.4782 43.4032V43.4032Z"
                        ),
                        svg.prop("fill", "url(#paint1)")
                    ),
                    utils.NULL
                ),
                svg.path(
                    string.concat(
                        svg.prop(
                            "d",
                            "M32.3323 57.5362C22.633 67.2357 22.633 82.9612 32.3323 92.6607C42.0318 102.36 57.7573 102.36 67.4568 92.6607C77.156 82.9612 77.156 67.2357 67.4568 57.5362L49.8945 39.974L32.3323 57.5362V57.5362Z"
                        ),
                        svg.prop("fill", "url(#paint2)")
                    ),
                    utils.NULL
                ),
                svg.path(
                    string.concat(
                        svg.prop(
                            "d",
                            "M38.1865 71.6692C31.7202 78.1355 31.7202 88.6192 38.1865 95.0855C44.6522 101.551 55.1365 101.551 61.6022 95.0855C68.0687 88.6192 68.0687 78.1355 61.6022 71.6692L49.8942 59.961L38.1865 71.6692Z"
                        ),
                        svg.prop("fill", "url(#paint3)")
                    ),
                    utils.NULL
                ),
                svg.path(
                    string.concat(
                        svg.prop(
                            "d",
                            "M44.0402 85.8023C40.8072 89.0353 40.8072 94.277 44.0402 97.5102C47.2735 100.743 52.515 100.743 55.7485 97.5102C58.9815 94.277 58.9815 89.0353 55.7485 85.8023L49.8942 79.948L44.0402 85.8023V85.8023Z"
                        ),
                        svg.prop("fill", "url(#paint4)")
                    ),
                    utils.NULL
                ),
                svg.el(
                    "defs",
                    utils.NULL,
                    string.concat(
                        _renderFlameSVGGradient(0, colors),
                        _renderFlameSVGGradient(1, colors),
                        _renderFlameSVGGradient(2, colors),
                        _renderFlameSVGGradient(3, colors),
                        _renderFlameSVGGradient(4, colors)
                    )
                )
            );
    }

    function _renderFlameSVGGradient(uint8 id, string[] memory colors)
        private
        pure
        returns (string memory)
    {
        return
            svg.linearGradient(
                string.concat(
                    svg.prop("id", string.concat("paint", utils.uint2str(id))),
                    svg.prop("x1", "50"),
                    svg.prop("y1", "100"),
                    svg.prop("x2", "50"),
                    svg.prop("y2", utils.uint2str(id * 20)),
                    svg.prop("gradientUnits", "userSpaceOnUse")
                ),
                string.concat(
                    svg.gradientStop(0, colors[0], utils.NULL),
                    svg.gradientStop(5, colors[1], utils.NULL),
                    svg.gradientStop(68, colors[2], utils.NULL),
                    svg.gradientStop(100, colors[3], utils.NULL)
                )
            );
    }

    function _renderText(
        string memory text,
        string memory strokeColor,
        string memory yOffset
    ) private pure returns (string memory) {
        return
            svg.g(
                string.concat(
                    svg.prop(
                        "transform",
                        string.concat(
                            "translate(",
                            utils.uint2str(50),
                            " ",
                            utils.uint2str(50),
                            ")"
                        )
                    ),
                    svg.prop("font-size", "12"),
                    svg.prop("font-family", "'Roboto Condensed', sans-serif"),
                    svg.prop("font-weight", "700")
                ),
                string.concat(
                    svg.text(
                        string.concat(
                            svg.prop("text-anchor", "middle"),
                            svg.prop("x", "0"),
                            svg.prop("y", yOffset),
                            svg.prop("fill", "white"),
                            svg.prop("stroke", strokeColor)
                        ),
                        string.concat("<![CDATA[", text, "]]>")
                    ),
                    svg.text(
                        string.concat(
                            svg.prop("text-anchor", "middle"),
                            svg.prop("x", "0"),
                            svg.prop("y", yOffset),
                            svg.prop("fill", "white")
                        ),
                        string.concat("<![CDATA[", text, "]]>")
                    )
                )
            );
    }

    function _getColor(bytes calldata seed, uint256 startIndex)
        private
        pure
        returns (string memory)
    {
        uint256 endIndex = startIndex + 3;
        bytes memory result = new bytes(3);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = seed[i];
        }
        return string.concat("#", utils.bytes3tohexstr(bytes3(result)));
    }

    function _getNumber(bytes calldata seed, uint256 atIdx)
        private
        pure
        returns (uint8)
    {
        bytes memory sub = utils.sub(seed, atIdx, atIdx + 1);
        return uint8(bytes1(sub));
    }

    function _getBool(bytes calldata seed, uint256 atIdx)
        private
        pure
        returns (bool)
    {
        uint8 num = _getNumber(seed, atIdx);
        return num != 0;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "./Utils.sol";

// Core SVG utilitiy library which helps us construct
// onchain SVG's with a simple, web-like API.
library svg {
    /* MAIN ELEMENTS */
    function g(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("g", _props, _children);
    }

    function path(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("path", _props, _children);
    }

    function text(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("text", _props, _children);
    }

    function line(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("line", _props, _children);
    }

    function circle(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("circle", _props, _children);
    }

    function rect(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("rect", _props, _children);
    }

    function filter(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("filter", _props, _children);
    }

    /* GRADIENTS */
    function radialGradient(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("radialGradient", _props, _children);
    }

    function linearGradient(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("linearGradient", _props, _children);
    }

    function gradientStop(
        uint256 offset,
        string memory stopColor,
        string memory _props
    ) internal pure returns (string memory) {
        return
            el(
                "stop",
                string.concat(
                    prop("stop-color", stopColor),
                    " ",
                    prop("offset", string.concat(utils.uint2str(offset), "%")),
                    " ",
                    _props
                ),
                utils.NULL
            );
    }

    function animateTransform(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el("animateTransform", _props, utils.NULL);
    }

    /* COMMON */
    // A generic element, can be used to construct any SVG (or HTML) element
    function el(
        string memory _tag,
        string memory _props,
        string memory _children
    ) internal pure returns (string memory) {
        return
            string.concat(
                "<",
                _tag,
                " ",
                _props,
                ">",
                _children,
                "</",
                _tag,
                ">"
            );
    }

    // an SVG attribute
    function prop(string memory _key, string memory _val)
        internal
        pure
        returns (string memory)
    {
        return string.concat(_key, "=", '"', _val, '" ');
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

// Core utils used extensively to format CSS and numbers.
library utils {
    // used to simulate empty strings
    string internal constant NULL = "";

    // formats a CSS variable line. includes a semicolon for formatting.
    function setCssVar(string memory _key, string memory _val)
        internal
        pure
        returns (string memory)
    {
        return string.concat("--", _key, ":", _val, ";");
    }

    // formats getting a css variable
    function getCssVar(string memory _key)
        internal
        pure
        returns (string memory)
    {
        return string.concat("var(--", _key, ")");
    }

    // formats getting a def URL
    function getDefURL(string memory _id)
        internal
        pure
        returns (string memory)
    {
        return string.concat("url(#", _id, ")");
    }

    // formats rgba white with a specified opacity / alpha
    function white_a(uint256 _a) internal pure returns (string memory) {
        return rgba(255, 255, 255, _a);
    }

    // formats rgba black with a specified opacity / alpha
    function black_a(uint256 _a) internal pure returns (string memory) {
        return rgba(0, 0, 0, _a);
    }

    // formats generic rgba color in css
    function rgba(
        uint256 _r,
        uint256 _g,
        uint256 _b,
        uint256 _a
    ) internal pure returns (string memory) {
        string memory formattedA = _a < 100
            ? string.concat("0.", utils.uint2str(_a))
            : "1";
        return
            string.concat(
                "rgba(",
                utils.uint2str(_r),
                ",",
                utils.uint2str(_g),
                ",",
                utils.uint2str(_b),
                ",",
                formattedA,
                ")"
            );
    }

    // checks if two strings are equal
    function stringsEqual(string memory _a, string memory _b)
        internal
        pure
        returns (bool)
    {
        return
            keccak256(abi.encodePacked(_a)) == keccak256(abi.encodePacked(_b));
    }

    // returns the length of a string in characters
    function utfStringLength(string memory _str)
        internal
        pure
        returns (uint256 length)
    {
        uint256 i = 0;
        bytes memory string_rep = bytes(_str);

        while (i < string_rep.length) {
            if (string_rep[i] >> 7 == 0) i += 1;
            else if (string_rep[i] >> 5 == bytes1(uint8(0x6))) i += 2;
            else if (string_rep[i] >> 4 == bytes1(uint8(0xE))) i += 3;
            else if (string_rep[i] >> 3 == bytes1(uint8(0x1E)))
                i += 4;
                //For safety
            else i += 1;

            length++;
        }
    }

    // converts an unsigned integer to a string
    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function uint8tohexchar(uint8 i) internal pure returns (uint8) {
        return
            (i > 9)
                ? (i + 87) // ascii a-f
                : (i + 48); // ascii 0-9
    }

    function uint24tohexstr(uint24 i) internal pure returns (string memory) {
        bytes memory o = new bytes(6);
        uint24 mask = 0x00000f;
        o[5] = bytes1(uint8tohexchar(uint8(i & mask)));
        i = i >> 4;
        o[4] = bytes1(uint8tohexchar(uint8(i & mask)));
        i = i >> 4;
        o[3] = bytes1(uint8tohexchar(uint8(i & mask)));
        i = i >> 4;
        o[2] = bytes1(uint8tohexchar(uint8(i & mask)));
        i = i >> 4;
        o[1] = bytes1(uint8tohexchar(uint8(i & mask)));
        i = i >> 4;
        o[0] = bytes1(uint8tohexchar(uint8(i & mask)));
        return string(o);
    }

    function bytes3tohexstr(bytes3 i) internal pure returns (string memory) {
        uint24 n = uint24(i);
        return uint24tohexstr(n);
    }

    function sub(
        bytes calldata data,
        uint256 startIndex,
        uint256 endIndex
    ) internal pure returns (bytes memory) {
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = data[i];
        }
        return result;
    }
}