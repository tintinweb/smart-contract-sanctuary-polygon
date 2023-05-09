// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Base64} from "./Base64.sol";
import {LibString} from "./LibString.sol";

/// @title NFTMeta
/// @author smarsx @_smarsx
/// @notice Provides functions for encoding html/svg in base64.
library NFTMeta {
    using LibString for uint32;

    enum TypeURI {
        SVG,
        HTML
    }

    struct MetaParams {
        TypeURI typeUri;
        string name;
        string description;
        string blob;
    }

    /// @notice Construct partial URI with no padding.
    /// @dev rest of URI will be added in render/renderWithTraits.
    /// we leave out the json closing bracket and use no padding to allow addition to json for traits
    function constructTokenURI(MetaParams memory params) public pure returns (bytes memory) {
        string memory blobHeader = params.typeUri == TypeURI.SVG
            ? '", "image": "data:image/svg+xml;base64,'
            : '", "animation_url": "data:text/html;base64,';

        string memory blob = Base64.encode(bytes(params.blob));

        return
            bytes(
                Base64.encode(
                    abi.encodePacked(
                        '{"name":"',
                        params.name,
                        '", "description":"',
                        params.description,
                        blobHeader,
                        blob,
                        '"'
                    ),
                    false,
                    // no-padding
                    true
                )
            );
    }

    /// @notice Render content with no added traits.
    /// @dev Decodes provided URI, appends a closing brace, re-encodes the concatenated result
    /// into base64. and prepends the data-uri prefix to form a valid data URI.
    function render(string memory uri) public pure returns (string memory) {
        bytes memory decodedUri = Base64.decode(uri);
        return
            string(
                abi.encodePacked(
                    bytes("data:application/json;base64,"),
                    Base64.encode(abi.encodePacked(decodedUri, bytes("}")))
                )
            );
    }

    /// @notice Render content with added traits.
    /// @dev Decode the given base64-encoded URI, concatenate it with the data-uri prefix
    /// and traits, and then re-encode the result into base64.
    function renderWithTraits(
        string memory uri,
        uint32 emissionMultiple,
        bool upgraded
    ) public pure returns (string memory) {
        string memory gold = upgraded ? ', {"value": "Gold"}' : "";
        return
            string(
                abi.encodePacked(
                    bytes("data:application/json;base64,"),
                    Base64.encode(
                        abi.encodePacked(
                            Base64.decode(uri),
                            abi.encodePacked(
                                ', "attributes": [{ "trait_type": "Emission Multiple", "value": "',
                                emissionMultiple.toString(),
                                '"}',
                                gold,
                                "]}"
                            )
                        )
                    )
                )
            );
    }

    /// @notice Construct Unrevealed URI.
    function constructBaseTokenURI(
        string memory name,
        uint56 prediction
    ) public pure returns (string memory) {
        string memory borderDescription = prediction == 1 ? "YES" : prediction == 2
            ? "NO"
            : prediction == 3
            ? "TIE"
            : "GG GL";
        string memory description = string.concat(
            "Unrevealed Memz. Prediction: ",
            borderDescription
        );
        string memory svg = Base64.encode(
            abi.encodePacked(
                generateSVGDefs(),
                generateSVGBorderText(name, borderDescription),
                "</svg>"
            )
        );
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            '{"name":"',
                            name,
                            '", "description":"',
                            description,
                            '", "image": "data:image/svg+xml;base64,',
                            svg,
                            '"}'
                        )
                    )
                )
            );
    }

    function generateSVGDefs() private pure returns (string memory svg) {
        string memory a = string.concat(
            '<svg width="290" height="500" viewBox="0 0 290 500" xmlns="http://www.w3.org/2000/svg"',
            " xmlns:xlink='http://www.w3.org/1999/xlink'>",
            "<defs>",
            '<filter id="f1"><feImage result="p0" xlink:href="data:image/svg+xml;base64,',
            Base64.encode(
                abi.encodePacked(
                    "<svg width='290' height='500' viewBox='0 0 290 500' xmlns='http://www.w3.org/2000/svg'><rect width='290px' height='500px' fill='#AC3969'/></svg>"
                )
            )
        );

        string memory b = string.concat(
            '"/><feImage result="p1" xlink:href="data:image/svg+xml;base64,',
            Base64.encode(
                abi.encodePacked(
                    "<svg width='290' height='500' viewBox='0 0 290 500' xmlns='http://www.w3.org/2000/svg'><circle cx='200'cy='100'r='120px'fill='#7B68EE'/></svg>"
                )
            ),
            '"/><feImage result="p2" xlink:href="data:image/svg+xml;base64,',
            Base64.encode(
                abi.encodePacked(
                    "<svg width='290' height='500' viewBox='0 0 290 500' xmlns='http://www.w3.org/2000/svg'><circle cx='150'cy='250'r='120px'fill='#FF00FF'/></svg>"
                )
            ),
            '" />',
            '<feImage result="p3" xlink:href="data:image/svg+xml;base64,',
            Base64.encode(
                abi.encodePacked(
                    "<svg width='290' height='500' viewBox='0 0 290 500' xmlns='http://www.w3.org/2000/svg'><circle cx='130'cy='470'r='150px'fill='#87CEFA'/></svg>"
                )
            )
        );

        string memory c = string.concat(
            '" /><feBlend mode="overlay" in="p0" in2="p1" /><feBlend mode="exclusion" in2="p2" /><feBlend mode="overlay" in2="p3" result="blendOut" /><feGaussianBlur ',
            'in="blendOut" stdDeviation="42" /></filter> <clipPath id="corners"><rect width="290" height="500" rx="42" ry="42" /></clipPath>',
            '<path id="text-path-a" d="M40 12 H250 A28 28 0 0 1 278 40 V460 A28 28 0 0 1 250 488 H40 A28 28 0 0 1 12 460 V40 A28 28 0 0 1 40 12 z" />',
            '<path id="minimap" d="M234 444C234 457.949 242.21 463 253 463" />',
            '<filter id="top-region-blur"><feGaussianBlur in="SourceGraphic" stdDeviation="24" /></filter>',
            '<linearGradient id="grad-up" x1="1" x2="0" y1="1" y2="0"><stop offset="0.0" stop-color="white" stop-opacity="1" />',
            '<stop offset=".9" stop-color="white" stop-opacity="0" /></linearGradient>',
            '<linearGradient id="grad-down" x1="0" x2="1" y1="0" y2="1"><stop offset="0.0" stop-color="white" stop-opacity="1" /><stop offset="0.9" stop-color="white" stop-opacity="0" /></linearGradient>',
            '<mask id="fade-up" maskContentUnits="objectBoundingBox"><rect width="1" height="1" fill="url(#grad-up)" /></mask>',
            '<mask id="fade-down" maskContentUnits="objectBoundingBox"><rect width="1" height="1" fill="url(#grad-down)" /></mask>',
            '<mask id="none" maskContentUnits="objectBoundingBox"><rect width="1" height="1" fill="white" /></mask>',
            '<linearGradient id="grad-symbol"><stop offset="0.7" stop-color="white" stop-opacity="1" /><stop offset=".95" stop-color="white" stop-opacity="0" /></linearGradient>',
            '<mask id="fade-symbol" maskContentUnits="userSpaceOnUse"><rect width="290px" height="200px" fill="url(#grad-symbol)" /></mask></defs>',
            '<g clip-path="url(#corners)">',
            '<rect fill="#AC3969" x="0px" y="0px" width="290px" height="500px" />',
            '<rect style="filter: url(#f1)" x="0px" y="0px" width="290px" height="500px" />',
            ' <g style="filter:url(#top-region-blur); transform:scale(1.5); transform-origin:center top;">',
            '<rect fill="none" x="0px" y="0px" width="290px" height="500px" />',
            '<ellipse cx="50%" cy="0px" rx="180px" ry="120px" fill="#000" opacity="0.85" /></g>',
            '<rect x="0" y="0" width="290" height="500" rx="42" ry="42" fill="rgba(0,0,0,0)" stroke="rgba(255,255,255,0.2)" /></g>',
            '<g mask="url(#fade-symbol)"><rect fill="none" x="0px" y="0px" width="290px" height="200px" />',
            '<text y="70px" x="32px" fill="white" font-family="\'Courier New\', monospace" font-weight="200" font-size="36px">MEMZ.eth</text>',
            '<text y="95px" x="36px" fill="white" font-family="\'Courier New\', monospace" font-style="italic" font-weight="100" font-size="12px">acta non verba</text></g>'
        );

        svg = string(abi.encodePacked(a, b, c));
    }

    function generateSVGBorderText(
        string memory name,
        string memory description
    ) private pure returns (string memory svg) {
        svg = string(
            abi.encodePacked(
                '<text text-rendering="optimizeSpeed">',
                '<textPath startOffset="-100%" fill="white" font-family="\'Courier New\', monospace" font-size="10px" xlink:href="#text-path-a">',
                name,
                unicode" • ",
                description,
                ' <animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite" />',
                '</textPath> <textPath startOffset="0%" fill="white" font-family="\'Courier New\', monospace" font-size="10px" xlink:href="#text-path-a">',
                name,
                unicode" • ",
                description,
                ' <animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite" /> </textPath></text>'
            )
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library to encode strings in Base64.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/Base64.sol)
library Base64 {
    /// @dev Encodes `data` using the base64 encoding described in RFC 4648.
    /// See: https://datatracker.ietf.org/doc/html/rfc4648
    /// @param fileSafe  Whether to replace '+' with '-' and '/' with '_'.
    /// @param noPadding Whether to strip away the padding.
    function encode(
        bytes memory data,
        bool fileSafe,
        bool noPadding
    ) internal pure returns (string memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            let dataLength := mload(data)

            if dataLength {
                // Multiply by 4/3 rounded up.
                // The `shl(2, ...)` is equivalent to multiplying by 4.
                let encodedLength := shl(2, div(add(dataLength, 2), 3))

                // Set `result` to point to the start of the free memory.
                result := mload(0x40)

                // Store the table into the scratch space.
                // Offsetted by -1 byte so that the `mload` will load the character.
                // We will rewrite the free memory pointer at `0x40` later with
                // the allocated size.
                // The magic constant 0x0230 will translate "-_" + "+/".
                mstore(0x1f, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdef")
                mstore(0x3f, sub("ghijklmnopqrstuvwxyz0123456789-_", mul(iszero(fileSafe), 0x0230)))

                // Skip the first slot, which stores the length.
                let ptr := add(result, 0x20)
                let end := add(ptr, encodedLength)

                // Run over the input, 3 bytes at a time.
                for {

                } 1 {

                } {
                    data := add(data, 3) // Advance 3 bytes.
                    let input := mload(data)

                    // Write 4 bytes. Optimized for fewer stack operations.
                    mstore8(0, mload(and(shr(18, input), 0x3F)))
                    mstore8(1, mload(and(shr(12, input), 0x3F)))
                    mstore8(2, mload(and(shr(6, input), 0x3F)))
                    mstore8(3, mload(and(input, 0x3F)))
                    mstore(ptr, mload(0x00))

                    ptr := add(ptr, 4) // Advance 4 bytes.

                    if iszero(lt(ptr, end)) {
                        break
                    }
                }

                // Allocate the memory for the string.
                // Add 31 and mask with `not(31)` to round the
                // free memory pointer up the next multiple of 32.
                mstore(0x40, and(add(end, 31), not(31)))

                // Equivalent to `o = [0, 2, 1][dataLength % 3]`.
                let o := div(2, mod(dataLength, 3))

                // Offset `ptr` and pad with '='. We can simply write over the end.
                mstore(sub(ptr, o), shl(240, 0x3d3d))
                // Set `o` to zero if there is padding.
                o := mul(iszero(iszero(noPadding)), o)
                // Zeroize the slot after the string.
                mstore(sub(ptr, o), 0)
                // Write the length of the string.
                mstore(result, sub(encodedLength, o))
            }
        }
    }

    /// @dev Encodes `data` using the base64 encoding described in RFC 4648.
    /// Equivalent to `encode(data, false, false)`.
    function encode(bytes memory data) internal pure returns (string memory result) {
        result = encode(data, false, false);
    }

    /// @dev Encodes base64 encoded `data`.
    ///
    /// Supports:
    /// - RFC 4648 (both standard and file-safe mode).
    /// - RFC 3501 (63: ',').
    ///
    /// Does not support:
    /// - Line breaks.
    ///
    /// Note: For performance reasons,
    /// this function will NOT revert on invalid `data` inputs.
    /// Outputs for invalid inputs will simply be undefined behaviour.
    /// It is the user's responsibility to ensure that the `data`
    /// is a valid base64 encoded string.
    function decode(string memory data) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            let dataLength := mload(data)

            if dataLength {
                let decodedLength := mul(shr(2, dataLength), 3)

                for {

                } 1 {

                } {
                    // If padded.
                    if iszero(and(dataLength, 3)) {
                        let t := xor(mload(add(data, dataLength)), 0x3d3d)
                        // forgefmt: disable-next-item
                        decodedLength := sub(
                            decodedLength,
                            add(iszero(byte(30, t)), iszero(byte(31, t)))
                        )
                        break
                    }

                    // If non-padded.
                    decodedLength := add(decodedLength, sub(and(dataLength, 3), 1))
                    break
                }
                result := mload(0x40)

                // Write the length of the bytes.
                mstore(result, decodedLength)

                // Skip the first slot, which stores the length.
                let ptr := add(result, 0x20)
                let end := add(ptr, decodedLength)

                // Load the table into the scratch space.
                // Constants are optimized for smaller bytecode with zero gas overhead.
                // `m` also doubles as the mask of the upper 6 bits.
                let m := 0xfc000000fc00686c7074787c8084888c9094989ca0a4a8acb0b4b8bcc0c4c8cc
                mstore(0x5b, m)
                mstore(0x3b, 0x04080c1014181c2024282c3034383c4044484c5054585c6064)
                mstore(0x1a, 0xf8fcf800fcd0d4d8dce0e4e8ecf0f4)

                for {

                } 1 {

                } {
                    // Read 4 bytes.
                    data := add(data, 4)
                    let input := mload(data)

                    // Write 3 bytes.
                    // forgefmt: disable-next-item
                    mstore(
                        ptr,
                        or(
                            and(m, mload(byte(28, input))),
                            shr(
                                6,
                                or(
                                    and(m, mload(byte(29, input))),
                                    shr(
                                        6,
                                        or(
                                            and(m, mload(byte(30, input))),
                                            shr(6, mload(byte(31, input)))
                                        )
                                    )
                                )
                            )
                        )
                    )

                    ptr := add(ptr, 3)

                    if iszero(lt(ptr, end)) {
                        break
                    }
                }

                // Allocate the memory for the string.
                // Add 31 and mask with `not(31)` to round the
                // free memory pointer up the next multiple of 32.
                mstore(0x40, and(add(end, 31), not(31)))
                // Zeroize the slot after the bytes.
                mstore(end, 0)
                // Restore the zero slot.
                mstore(0x60, 0)
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for converting numbers into strings and other string operations.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibString.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/LibString.sol)
library LibString {
    /// @dev Returns the base 10 decimal representation of `value`.
    function toString(uint256 value) internal pure returns (string memory str) {
        /// @solidity memory-safe-assembly
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
            // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 word for the trailing zeros padding, 1 word for the length,
            // and 3 words for a maximum of 78 digits.
            str := add(mload(0x40), 0x80)
            // Update the free memory pointer to allocate.
            mstore(0x40, add(str, 0x20))
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            let w := not(0) // Tsk.
            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            for {
                let temp := value
            } 1 {

            } {
                str := add(str, w) // `sub(str, 1)`.
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                if iszero(temp) {
                    break
                }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }
}