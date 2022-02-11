// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.4;

import '../interfaces/ISvgGenerator.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

contract SvgGenerator is ISvgGenerator {
    uint256 immutable MAX_HUE = 360;

    address public outerRingsSvgGenerator;
    address public middleRingsSvgGenerator;
    address public innerRingsSvgGenerator;

    /// @dev Instantiate an SVG generator with the given secondary generators.
    /// @param outerRingsSvgGeneratorContract Address of the SVG generator for the outer rings.
    /// @param middleRingsSvgGeneratorContract Address of the SVG generator for the middle rings.
    /// @param innerRingsSvgGeneratorContract Address of the SVG generator for the inner rings.
    constructor(
        address outerRingsSvgGeneratorContract,
        address middleRingsSvgGeneratorContract,
        address innerRingsSvgGeneratorContract
    ) {
        outerRingsSvgGenerator = outerRingsSvgGeneratorContract;
        middleRingsSvgGenerator = middleRingsSvgGeneratorContract;
        innerRingsSvgGenerator = innerRingsSvgGeneratorContract;
    }

    /// @inheritdoc ISvgGenerator
    function generateSvg(
        uint256 tokenId,
        address minter,
        string calldata category,
        string calldata name,
        uint256 availabilityFrom,
        uint256 availabilityTo,
        uint256 duration,
        bool redeemed,
        bool forSale
    ) external view override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    _getInitialPart(forSale),
                    _getMiddlePart(
                        tokenId,
                        minter,
                        category,
                        availabilityFrom,
                        availabilityTo,
                        duration
                    ),
                    _getLastPart(
                        tokenId,
                        minter,
                        category,
                        name,
                        availabilityFrom,
                        availabilityTo,
                        duration,
                        redeemed,
                        forSale
                    )
                )
            );
    }

    /// @dev Generates the first part of the SVG.
    /// @param rotateNewt A boolean indicating if the newt should be rotating or not.
    /// @return Bytes representing the first part of the SVG.
    function _getInitialPart(bool rotateNewt) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 414.68 414.68"> <defs> <style> @keyframes clockwise-rotation { from { transform: rotate(0deg); } to { transform: rotate(360deg); } } @keyframes counter-clockwise-rotation { from { transform: rotate(360deg); } to { transform: rotate(0deg); } }',
                rotateNewt
                    ? '.rotation-newt { animation: clockwise-rotation 20s linear infinite; transform-box: fill-box; transform-origin: center; } '
                    : ' '
            );
    }

    /// @dev Generates the middle part of the SVG.
    /// @param tokenId The ID of the token for which the SVG will be generated.
    /// @param minter The minter of the token.
    /// @param category Type or category label that represents the activity for what the time was tokenized.
    /// @param availabilityFrom Unix timestamp indicating start of availability. Zero if does not have lower bound.
    /// @param availabilityTo Unix timestamp indicating end of availability. Zero if does not have upper bound.
    /// @param duration The actual quantity of time you are tokenizing inside availability range. Measured in seconds.
    /// @return Bytes representing the middle part of the SVG.
    function _getMiddlePart(
        uint256 tokenId,
        address minter,
        string calldata category,
        uint256 availabilityFrom,
        uint256 availabilityTo,
        uint256 duration
    ) internal pure returns (bytes memory) {
        uint256 categoryAsInt = uint256(keccak256(bytes(category)));
        return
            abi.encodePacked(
                _rotationClass('.rotation-1', availabilityFrom + tokenId, 8, 20),
                _rotationClass('.rotation-2', uint160(minter) + tokenId, 6, 20),
                _rotationClass('.rotation-3', categoryAsInt, 6, 20),
                _rotationClass('.rotation-4', duration + tokenId, 3, 10),
                _rotationClass('.rotation-5', categoryAsInt + tokenId, 4, 10),
                _rotationClass('.rotation-6', availabilityTo + tokenId, 5, 10),
                '.cls-1, .cls-15, .cls-20, .cls-3, .cls-5, .cls-5-2 { fill: none; } .cls-17, .cls-2 { fill: hsla(',
                Strings.toString(_intToInterval(categoryAsInt, 0, MAX_HUE)),
                ', 100%, 93%, 1); } .cls-15, .cls-2, .cls-3, .cls-5, .cls-5-2 { stroke: #9a7ac6; } .cls-16, .cls-17, .cls-18, .cls-19, .cls-2, .cls-3 { stroke-miterlimit: 10; } .cls-2, .cls-3 { stroke-width: 3px; } .cls-4 { clip-path: url(#clip-path); } .cls-15, .cls-20, .cls-5, .cls-5-2 { stroke-linecap: round; stroke-linejoin: round; } .cls-5 { stroke-width: 3px; } .cls-5-2 { stroke-width: 2px; } .cls-6 { clip-path: url(#clip-path-2); } .cls-7 { clip-path: url(#clip-path-3); } .cls-8 { clip-path: url(#clip-path-4); } .cls-9 { clip-path: url(#clip-path-5); } .cls-10 { clip-path: url(#clip-path-6); } .cls-11 { clip-path: url(#clip-path-7); } .cls-12 { clip-path: url(#clip-path-8); } .cls-13 { clip-path: url(#clip-path-9); } .cls-14 { clip-path: url(#clip-path-10); } .cls-15 { stroke-width: 3px; } .cls-16, .cls-18 { fill: #9a7ac6; } .cls-16, .cls-17 { stroke: #8c6bb4; } .cls-18, .cls-19, .cls-20 { stroke: #9a7ac6; } .cls-19 { fill: #fffeff; } </style> <clipPath id="clip-path" transform="translate(-120.62 -118.82)"> <rect class="cls-1" x="387.39" y="151.38" width="18.18" height="30"/> </clipPath> <clipPath id="clip-path-2" transform="translate(-120.62 -118.82)"> <rect class="cls-1" x="255.95" y="151.38" width="18.18" height="30"/> </clipPath> <clipPath id="clip-path-3" transform="translate(-120.62 -118.82)"> <rect class="cls-1" x="385.78" y="470.94" width="18.18" height="30"/> </clipPath> <clipPath id="clip-path-4" transform="translate(-120.62 -118.82)"> <rect class="cls-1" x="254.34" y="470.94" width="18.18" height="30"/> </clipPath> <clipPath id="clip-path-5" transform="translate(-120.62 -118.82)"> <rect class="cls-1" x="153.65" y="383.1" width="30" height="18.18"/> </clipPath> <clipPath id="clip-path-6" transform="translate(-120.62 -118.82)"> <rect class="cls-1" x="153.65" y="251.66" width="30" height="18.18"/> </clipPath> <clipPath id="clip-path-7" transform="translate(-120.62 -118.82)"> <rect class="cls-1" x="472.19" y="379.79" width="30" height="18.18"/> </clipPath> <clipPath id="clip-path-8" transform="translate(-120.62 -118.82)"> <rect class="cls-1" x="472.19" y="248.35" width="30" height="18.18"/> </clipPath> <clipPath id="clip-path-9" transform="translate(-120.62 -118.82)"> <rect class="cls-1" x="391.89" y="293.49" width="34.18" height="65.04"/> </clipPath> <clipPath id="clip-path-10" transform="translate(-120.62 -118.82)"> <rect class="cls-1" x="228.75" y="293.49" width="34.18" height="65.04"/> </clipPath> </defs>'
            );
    }

    /// @dev Generates the last part of the SVG.
    /// @param tokenId The ID of the token for which the SVG will be generated.
    /// @param minter The minter of the token.
    /// @param category Type or category label that represents the activity for what the time was tokenized.
    /// @param name Name of the NFT.
    /// @param availabilityFrom Unix timestamp indicating start of availability. Zero if does not have lower bound.
    /// @param availabilityTo Unix timestamp indicating end of availability. Zero if does not have upper bound.
    /// @param duration The actual quantity of time you are tokenizing inside availability range. Measured in seconds.
    /// @param redeemed A boolean representing if the token was already redeemed or not.
    /// @param forSale A boolean representing if the token is for sale or not.
    /// @return Bytes representing the last part of the SVG.
    function _getLastPart(
        uint256 tokenId,
        address minter,
        string calldata category,
        string calldata name,
        uint256 availabilityFrom,
        uint256 availabilityTo,
        uint256 duration,
        bool redeemed,
        bool forSale
    ) internal view returns (bytes memory) {
        return
            abi.encodePacked(
                ISvgGenerator(outerRingsSvgGenerator).generateSvg(
                    tokenId,
                    minter,
                    category,
                    name,
                    availabilityFrom,
                    availabilityTo,
                    duration,
                    redeemed,
                    forSale
                ),
                ISvgGenerator(middleRingsSvgGenerator).generateSvg(
                    tokenId,
                    minter,
                    category,
                    name,
                    availabilityFrom,
                    availabilityTo,
                    duration,
                    redeemed,
                    forSale
                ),
                ISvgGenerator(innerRingsSvgGenerator).generateSvg(
                    tokenId,
                    minter,
                    category,
                    name,
                    availabilityFrom,
                    availabilityTo,
                    duration,
                    redeemed,
                    forSale
                )
            );
    }

    /// @dev Maps the given integer into other inside a given interval.
    /// @param value The integer to map.
    /// @param start An integer representing the start of the output interval.
    /// @param end An integer representing the end of the output interval.
    /// @return An integer inside the given interval.
    function _intToInterval(
        uint256 value,
        uint256 start,
        uint256 end
    ) internal pure returns (uint256) {
        uint256 intervalLength = end - start + 1;
        return (value % intervalLength) + start;
    }

    /// @dev Generates a rotation animation css class.
    /// @param className The class name including the initial dot used in css syntax for class definitions.
    /// @param value An integer value used to derive the rotation orientation.
    /// @param slowestSpeed An integer representing the minimum rotation speed allowed, measured in seconds.
    /// @param fastestSpeed An integer representing the maximum rotation speed allowed, measured in seconds.
    /// @return Bytes representing the class css code.
    function _rotationClass(
        string memory className,
        uint256 value,
        uint256 slowestSpeed,
        uint256 fastestSpeed
    ) internal pure returns (bytes memory) {
        uint256 rotationSpeed = _intToInterval(value, slowestSpeed, fastestSpeed);
        return
            abi.encodePacked(
                className,
                ' { animation: ',
                value % 2 == 0 ? 'clockwise-rotation ' : 'counter-clockwise-rotation ',
                Strings.toString(rotationSpeed),
                's linear infinite; transform-box: fill-box; transform-origin: center; } '
            );
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.4;

interface ISvgGenerator {
    /// @dev Generates an SVG from the given data.
    /// @param tokenId The ID of the token for which the SVG will be generated.
    /// @param minter The minter of the token.
    /// @param category Type or category label that represents the activity for what the time was tokenized.
    /// @param name Name of the NFT.
    /// @param availabilityFrom Unix timestamp indicating start of availability. Zero if does not have lower bound.
    /// @param availabilityTo Unix timestamp indicating end of availability. Zero if does not have upper bound.
    /// @param duration The actual quantity of time you are tokenizing inside availability range. Measured in seconds.
    /// @param redeemed A boolean representing if the token was already redeemed or not.
    /// @param forSale A boolean representing if the token is for sale or not.
    /// @return A string representing the generated SVG.
    function generateSvg(
        uint256 tokenId,
        address minter,
        string calldata category,
        string calldata name,
        uint256 availabilityFrom,
        uint256 availabilityTo,
        uint256 duration,
        bool redeemed,
        bool forSale
    ) external view returns (string memory);
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