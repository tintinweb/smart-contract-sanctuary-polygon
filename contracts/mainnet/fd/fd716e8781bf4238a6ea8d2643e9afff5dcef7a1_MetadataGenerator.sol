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

// SPDX-License-Identifier: MIT
// Copyright (c) 2022 Upshot Technologies Inc. All Rights Reserved
pragma solidity 0.8.x;

import {SoLaLa} from "./SoLaLa.sol";
import {Base64} from "./Base64.sol";
import {Strings} from "../../../lib/openzeppelin-contracts/contracts/utils/Strings.sol";

contract MetadataGenerator {

    string[] _topRight;
    
    string[] _topLeft;
    string[] _topLeftRare;
    string[] _bottomRight;
    string[] _bottomRightRare;

    string _topRightRare;
    string _bottomLeftRare;

    string[] _color;

    constructor() {
        _color.push("#ff00cd"); //pink 
        _color.push("#ff4300"); //orange
        _color.push("#0091ff"); //blue 
    }

    /**
     */
    function _getRandomNumber(uint256 max) public view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.difficulty,
                        msg.sender
                    )
                )
            ) % max;
    }

    function _getRandomNumbers(string memory seed, uint256 upperBound) public view returns (uint256[3] memory) {
        uint256 randomKeccak = uint256(keccak256(abi.encodePacked(seed, block.difficulty, block.timestamp, block.number)));
        return [
        randomKeccak % upperBound,
        randomKeccak / upperBound % upperBound,
        randomKeccak / upperBound / upperBound % upperBound
        ];
    }

    /**
     * plants
     */
    function setTopRight(string memory svg_) external {
        _topRight.push(svg_);
    }

    //string _topRightRare;
    function setTopRightRare(string memory svg_) external {
        _topRightRare = svg_;
    }

    /**
     * squiggle
     */
    function setTopLeft(string memory svg_) public {
        _topLeft.push(svg_);
    }

    //string[] _topLeftRare;
    function setTopLeftRare(string memory svg_) public {
        _topLeftRare.push(svg_);
    }

    /**
     * spaceship
     */
    function setBottomRight(string memory svg_) public {
        _bottomRight.push(svg_);
    }

    //string[] _bottomRightRare;
    function setBottomRightRare(string memory svg_) public {
        _bottomRightRare.push(svg_);
    }

    /**
     * mountain (rare)
     */

    //string _bottomLeftRare; 
    function setBottomLeftRare(string memory svg_) public {
        _bottomLeftRare = svg_;
    }

    /**
     * pink - #ff00cd
     * 
     * orange - #ff4300
     * 
     * blue - #0091ff
     */
    function _getComponent00() public view returns (string memory) {
        uint[3] memory randomNumbers = _getRandomNumbers(Strings.toHexString(uint256(uint160(msg.sender)), 20), 3);
        string memory color00 = _color[randomNumbers[0]];
        string memory color01 = _color[randomNumbers[1]];
        string memory color02 = _color[randomNumbers[2]];
        string memory svg00 = string(abi.encodePacked(
            '<defs>'
                '<style>'
                    '.color00 {',
                        bytes.concat(bytes('fill: '),bytes(color00),bytes(';')), 
                    '}'
                    '.color01 {',
                        bytes.concat(bytes('fill: '),bytes(color01),bytes(';')), 
                    '}'
                    '.color02 {',
                        bytes.concat(bytes('fill: '),bytes(color02),bytes(';')), 
                    '}'
                '</style>'
            '</defs>'
        ));
        return svg00;
    }

    /**
     * planet and addresses, curved text
     */
    function _getComponent01(bool rare, string memory admin, string memory pool) public view returns (string memory) {
        string memory svg00 = string(abi.encodePacked(
            rare ? _topRightRare : _topRight[_getRandomNumber(3)],
            '<path id="curve00" fill="transparent" d="M625.6,103.9c-45.4,97.4-50.2,212.3-3.9,324.8,80,194.3,288.1,321.2,503.4,323.5"/>'
            '<text font-family="monospace" font-size="1.75em">'
            '<textPath xlink:href="#curve00" fill="white">',
            string(abi.encodePacked('admin: ', admin)),
            '</textPath>'
            '</text>'
            '<path id="curve01" fill="transparent" d="M701,53.3c-61,88-72.5,242.4-30.6,344,72.3,175.5,260.2,290.1,454.7,292.2"/>'
            '<text font-family="monospace" font-size="1.75em">'
            '<textPath xlink:href="#curve01" class="color02">',
            string(abi.encodePacked('pool: ', pool)),
            '</textPath>'
            '</text>'));
        return svg00;
    }

    function _getComponent02(string memory curve, string memory delta, string memory fee, string memory nft) public pure returns (string memory) {
        string memory svg01 = string(abi.encodePacked(
            '<path class="color01" d="m177.47,584.01h-41.4v-41.5h41.4v41.5Zm-39.4-2h37.4v-37.5h-37.4v37.5Z" transform="translate(-90,0)"/>'
            '<path class="color01" d="m176.37,543.41c0,8.8,0,28.9-20.6,36.4-2.7,1-5.7,1.7-9.2,2.2-2.9.4-6.1.6-9.6.6v.2h39.5l-.1-39.4h0Z" transform="translate(-90,0)"/>'
            '<text x="95" y="575" font-family="monospace" font-size="1.75em" fill="white">',
            curve,
            '</text>'
            '<polygon class="color01" points="176.47 631.72 137.07 631.72 156.77 592.31 176.47 631.72" transform="translate(-90,5)"/>'
            '<text x="95" y="629" font-family="monospace" font-size="1.75em" fill="white">',
            delta,
            '</text>'
            '<ellipse class="color01" cx="67" cy="656.82" rx="19.75" ry="5.61"/>'
            '<path class="color01" transform="translate(-90,10)" d="m137.07,650.34v24.77c0,3.1,8.84,5.61,19.75,5.61s19.75-2.51,19.75-5.61v-24.77c-4.09,3.14-13.56,4.09-19.75,4.09s-15.66-.94-19.75-4.09Z"/>'
            '<text x="95" y="683" font-family="monospace" font-size="1.75em" fill="white"> ',
            fee,
            '</text>'
            '<rect class="color01" x="47" y="732.51" width="39.5" height="39.5"/>'
            '<text x="95" y="763" font-family="monospace" font-size="1.75em" fill="white">',
            nft,
            '</text>'
            ));
        return svg01;
    }

    function _getComponent03(bool rare, string memory xymbol) public view returns (string memory) {
        string memory svg02 = string(abi.encodePacked(
            '<path class="color01" d="m156.77,784.22h0c10.9,0,19.7,8.8,19.7,19.7h0c0,10.9-8.8,19.7-19.7,19.7h0c-10.9,0-19.7-8.8-19.7-19.7h0c0-10.9,8.8-19.7,19.7-19.7Z" transform="translate(-90,0)"/>'
            '<text x="95" y="816" font-family="monospace" font-size="1.75em" fill="white">',
            xymbol,
            '</text>',
            rare ? _topLeftRare[_getRandomNumber(3)] : _topLeft[_getRandomNumber(4)], //_topLeft[_getRandomNumber(4)],
            '<path d="M1087 779.7H602.3a37.3 37.3 0 0 1-37.3-37.3v-705A37.3 37.3 0 0 1 602.3 0H565V0h-42.3A37.3 37.3 0 0 1 560 37.4v271h-.3a37.3 37.3 0 0 1-37.3 37.3S0 345.6 0 345.6v5h522.5a37.3 37.3 0 0 1 37.2 37.3h.3v699.9a37.3 37.3 0 0 1-37.3 37.2h79.5a37.3 37.3 0 0 1-37.2-37.3V822a37.3 37.3 0 0 1 37.3-37.3h485.4A37.3 37.3 0 0 1 1125 822v-79.6a37.3 37.3 0 0 1-37.3 37.3Z" fill="white"/>',
            rare ? _bottomRightRare[_getRandomNumber(3)] : _bottomRight[_getRandomNumber(6)] , //_bottomRight[_getRandomNumber(6)],
            '<path d="M664.1 576.7c0-49.6-35.7-91-82.8-99.8A37.3 37.3 0 0 1 565 446h-5c0 12.7-6.5 24-16.3 30.7a101.8 101.8 0 0 0-20 193.8h-1 1c6 2.5 12.4 4.4 18.9 5.7A37.3 37.3 0 0 1 560 708h5c0-13.3 7-25 17.4-31.6 6.6-1.3 12.8-3.2 18.8-5.7h1-.9a101.8 101.8 0 0 0 62.8-93.9Zm-78.9 93.9h-45.4a96.8 96.8 0 0 1-2-187.3h49.5c41.3 11 71.8 48.7 71.8 93.4s-31.5 83.7-73.9 93.9Z" fill="white"/>'
            '<circle cx="50%" cy="51.26%" r="99" fill="', 
            rare ? "#083cfc" : "black", 
            '"/>'
            '<circle cx="50%" cy="51.26%" r="65" class="color00"/>'
            '<path d="M590.2 532.7c-2.8-2.4.4-6.7 3.5-4.8a53 53 0 0 1 16 16.3c8.6 13.5 9 30.7 3.2 30.7-4.6 0-8.6-1-8.6-15.1a36 36 0 0 0-14.1-27.1ZM571.4 520.7c4-.5 8 0 11.7 1.7 1.4.6 2.8 1.4 3.2 2.8a4 4 0 0 1-.4 2.7c-.2.3-.4.7-.7.8-.4.2-.7.2-1.1 0-1.4-.3-2.8-1-4-1.8a25 25 0 0 0-8.5-2.7c-.7 0-1.4-.2-1.8-.6-.6-.5-.5-1.5-.2-2.1.5-.8 1.5-1.3 1.7-.8ZM504.7 583a45.6 45.6 0 0 0 30.9 31.7c11.6 2.8 17-7.2 8.6-10.1-6-2.1-8.8 2-20.8-2.9-8-3.1-12.6-8.2-18.7-18.6ZM519 613.6a60.6 60.6 0 0 0 51.9 23.2 43 43 0 0 1-1.5-7c-1.5.5-3.1.6-4.7.6a71.4 71.4 0 0 1-45.7-16.8ZM572.1 629.9c.9 2 1.6 4 2 6.1 4.6-.8 9.1-2.2 13.2-4.2a20.5 20.5 0 0 1-2.5-7c-4 1.9-8.3 3.5-12.7 5Z" fill="white"/>'
            '<path d="M596 585c0 18.7-11 30-31.4 30-6.1 0-11.5-1-16-3 10.3-4.5 15.8-14 15.8-27v-5.6c0-.6-.6-1.1-1.2-1.1h-30.6v-36.8h4.5c1.6 3.2 4 5.7 6.8 7.6 2.2-3.4 5.3-6 9.4-7.6h.2c1.6 3.2 4 5.7 6.8 7.6 2.1-3.2 5-5.7 8.7-7.3 4.1.4 7.9 1.3 11.1 2.7-10.2 4.5-15.7 14-15.7 27v5c0 .9.8 1.7 1.8 1.7h30l-.1 6.7Z"/>'
            ));
        return svg02;
    }

    /**
     * 
     */
    function generateImage(string memory curve_,
                           string memory delta_,
                           string memory fee_,
                           string memory nft_,
                           string memory xymbol_,
                           string memory admin_, 
                           string memory pool_
    ) view internal returns (string memory) {
        //bool rare = _getRandomNumber(100) == 1 ? true : false;
        bool rare = _getRandomNumber(2) == 1 ? true : false;

        string memory colorRare = "#083cfc";
        string memory svg = string(abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 1125 1125">',
            _getComponent00(),
            rare ? string(abi.encodePacked('<rect width="100%" height="100%" fill="', colorRare, '"/>')) : '<rect width="100%" height="100%" fill="black"/>',
            _getComponent01(rare, admin_, pool_),
            _getComponent02(curve_, delta_, fee_, nft_),
            rare ? _bottomLeftRare : '', //montains
            _getComponent03(rare, xymbol_),
            '</svg>'));
        return svg;
    }

    /**
     * 
     */
    function _payloadTokenUri(SoLaLa memory input, uint256 tokenId_) view public returns (string memory) {
        string memory description = 'Upshot Swap is an NFT AMM that allows for autonomously providing liquidity and trading NFTs completely on-chain, without an off-chain orderbook. '
                                    'Liquidity providers deposit NFTs into Upshot Swap pools and are given NFT LP tokens to track their ownership of that liquidity. '
                                    'These NFT LP tokens represent liquidity in the AMM. '
                                    'When withdrawing liquidity, liquidity providers burn their NFT LP token(s) and are sent back the corresponding liquidity from the pool.';
        
        return
            string(abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(bytes(abi.encodePacked(
                        '{"name":"',
                            string(abi.encodePacked('Upshot Swap #', Strings.toString(tokenId_))),
                        '", "description":"',
                            description,
                        '", "image": "',
                            'data:image/svg+xml;base64,',
                            Base64.encode(bytes(generateImage(input.curve, input.delta, input.fee, input.nft, input.xymbol, input.admin, input.pool))),
                        '"}'
                    )))
            ));
    }




}

// SPDX-License-Identifier: MIT
// Copyright (c) 2022 Upshot Technologies Inc. All Rights Reserved
pragma solidity 0.8.x;

struct SoLaLa {
    string curve;
    string delta;
    string fee;
    string nft;
    string xymbol;
    string admin; 
    string pool; 
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}