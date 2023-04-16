// SPDX-License-Identifier: GPL-3.0

/// @title The Dafo NFT descriptor

// LICENSE
// DafoDescriptor.sol is a modified version of Nouns's NounDescriptor.sol:
// https://github.com/nounsDAO/nouns-monorepo/blob/1f1899c1602f04c7fca96458061a8baf3a6cc9ec/packages/nouns-contracts/contracts/NounsDescriptor.sol
//
// NounDescriptor.sol source code Copyright Nouns licensed under the GPL-3.0 license.
// With modifications by Dafounders DAO.

pragma solidity ^0.8.6;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';
import {IDafoDescriptor} from './interfaces/IDafoDescriptor.sol';
import {IDafoCustomizer} from './interfaces/IDafoCustomizer.sol';
import {NFTDescriptor} from './libs/NFTDescriptor.sol';
import {MultiPartSVGsToSVG} from './libs/MultiPartSVGsToSVG.sol';

contract DafoDescriptor is IDafoDescriptor, Ownable {
    using Strings for uint256;

    // prettier-ignore
    // https://creativecommons.org/publicdomain/zero/1.0/legalcode.txt
    bytes32 constant COPYRIGHT_CC0_1_0_UNIVERSAL_LICENSE = 0xa2010f343487d3f7618affe54f789f5487602331c0a8d03f49e9a7c547cf0499;

    // Whether or not new Dafo parts can be added
    bool public override arePartsLocked;

    // Whether or not `tokenURI` should be returned as a data URI (Default: true)
    bool public override isDataURIEnabled = true;

    // Base URI
    string public override baseURI;

    // Dafo Numbers (Custom SVG)
    mapping(uint8 => string) public digits;
    uint256 public override digitCount;

    // Dafo Roles (Custom SVG)
    mapping(uint8 => string) public roles;
    uint256 public override roleCount;

    // Dafo Backgrounds (Hex Colors)
    mapping(uint8 => Palette) public palettes;
    uint256 public override paletteCount;

    /**
     * @notice Require that the parts have not been locked.
     */
    modifier whenPartsNotLocked() {
        require(!arePartsLocked, 'Parts are locked');
        _;
    }

    /**
     * @notice Require that added part index is in bound.
     */
    modifier whenPartIndexIsInBound(uint256 index, uint256 count) {
        require(index <= count, 'index is out of bound');
        _;
    }

    /**
     * @notice Batch add Dafo digits.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyDigits(string[] calldata _digits) external override onlyOwner whenPartsNotLocked {
        for (uint8 i = 0; i < _digits.length; i++) {
            _addDigit(i, _digits[i]);
        }
        digitCount = _digits.length;
    }

    /**
     * @notice Batch add Dafo roles.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyRoles(string[] calldata _roles) external override onlyOwner whenPartsNotLocked {
        for (uint8 i = 0; i < _roles.length; i++) {
            _addRole(i, _roles[i]);
        }
        roleCount = _roles.length;
    }

    /**
     * @notice Batch add Dafo palettes.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyPalettes(Palette[] calldata _palettes) external override onlyOwner whenPartsNotLocked {
        for (uint8 i = 0; i < _palettes.length; i++) {
            _addPalette(i, _palettes[i]);
        }
        paletteCount = _palettes.length;
    }

    /**
     * @notice Add a Dafo digit.
     * @dev This function can only be called by the owner when not locked.
     */
    function addDigit(uint8 index, string calldata _digit)
        external
        override
        onlyOwner
        whenPartsNotLocked
        whenPartIndexIsInBound(index, digitCount)
    {
        _addDigit(index, _digit);
        if (index == digitCount) {
            ++digitCount;
        }
    }

    /**
     * @notice Add a Dafo role.
     * @dev This function can only be called by the owner when not locked.
     */
    function addRole(uint8 index, string calldata _roles)
        external
        override
        onlyOwner
        whenPartsNotLocked
        whenPartIndexIsInBound(index, roleCount)
    {
        _addRole(index, _roles);
        if (index == roleCount) {
            ++roleCount;
        }
    }

    /**
     * @notice Add a Dafo palette.
     * @dev This function can only be called by the owner when not locked.
     */
    function addPalette(uint8 index, Palette calldata _palette)
        external
        override
        onlyOwner
        whenPartsNotLocked
        whenPartIndexIsInBound(index, paletteCount)
    {
        _addPalette(index, _palette);
        if (index == paletteCount) {
            ++paletteCount;
        }
    }

    /**
     * @notice Lock all Dafo parts.
     * @dev This cannot be reversed and can only be called by the owner when not locked.
     */
    function lockParts() external override onlyOwner whenPartsNotLocked {
        arePartsLocked = true;

        emit PartsLocked();
    }

    /**
     * @notice Toggle a boolean value which determines if `tokenURI` returns a data URI
     * or an HTTP URL.
     * @dev This can only be called by the owner.
     */
    function toggleDataURIEnabled() external override onlyOwner {
        bool enabled = !isDataURIEnabled;

        isDataURIEnabled = enabled;
        emit DataURIToggled(enabled);
    }

    /**
     * @notice Set the base URI for all token IDs. It is automatically
     * added as a prefix to the value returned in {tokenURI}, or to the
     * token ID if {tokenURI} is empty.
     * @dev This can only be called by the owner.
     */
    function setBaseURI(string calldata _baseURI) external override onlyOwner {
        baseURI = _baseURI;

        emit BaseURIUpdated(_baseURI);
    }

    /**
     * @notice Given a token ID and customizerInfo, construct a token URI for an official Dafo DAO clubId.
     * @dev The returned value may be a base64 encoded data URI or an API URL.
     */
    function tokenURI(IDafoCustomizer.CustomInput memory customInput) external view override returns (string memory) {
        if (isDataURIEnabled) {
            return dataURI(customInput);
        }
        return string(abi.encodePacked(baseURI, customInput.tokenId.toString()));
    }

    /**
     * @notice Given a token ID and CustomInput, construct a base64 encoded data URI for an official Dafo DAO clubId.
     */
    function dataURI(IDafoCustomizer.CustomInput memory customInput) public view override returns (string memory) {
        string memory clubId = _getClubIdFromTokenId(customInput.tokenId);
        string memory name = string(abi.encodePacked('DAFO', clubId));
        string memory description = string(abi.encodePacked('Dafounder ', clubId, ' is a member of the DAFO DAO'));

        return genericDataURI(name, description, customInput);
    }

    /**
     * @notice Given a name, description, and customInput, construct a base64 encoded data URI.
     */
    function genericDataURI(
        string memory name,
        string memory description,
        IDafoCustomizer.CustomInput memory customInput
    ) public view override returns (string memory) {
        NFTDescriptor.TokenURIParams memory params = NFTDescriptor.TokenURIParams({
            name: name,
            description: description,
            parts: _getPartsForTokenId(customInput),
            role: roles[customInput.role],
            background: palettes[customInput.palette].background,
            fill: palettes[customInput.palette].fill,
            outline: customInput.outline
        });
        return NFTDescriptor.constructTokenURI(params);
    }

    /**
     * @notice Given a customInput, construct a base64 encoded SVG image.
     */
    function generateSVGImage(IDafoCustomizer.CustomInput memory customInput)
        external
        view
        override
        returns (string memory)
    {
        MultiPartSVGsToSVG.SVGParams memory params = MultiPartSVGsToSVG.SVGParams({
            parts: _getPartsForTokenId(customInput),
            role: roles[customInput.role],
            background: palettes[customInput.palette].background,
            fill: palettes[customInput.palette].fill,
            outline: customInput.outline
        });
        return NFTDescriptor.generateSVGImage(params);
    }

    /**
     * @notice Add a Dafo number.
     */
    function _addDigit(uint8 index, string calldata _digit) internal {
        digits[index] = _digit;
    }

    /**
     * @notice Add a Dafo role.
     */
    function _addRole(uint8 index, string calldata _role) internal {
        roles[index] = _role;
    }

    /**
     * @notice Add a Dafo palette.
     */
    function _addPalette(uint8 index, Palette calldata _palette) internal {
        palettes[index] = _palette;
    }

    /**
     * @notice Get all Dafo parts for the passed `customInput`.
     */
    function _getPartsForTokenId(IDafoCustomizer.CustomInput memory customInput)
        internal
        view
        returns (string[] memory)
    {
        uint8 numDigits = 4;

        if (customInput.tokenId == 10000) {
            numDigits = 5;
        }

        string[] memory _parts = new string[](numDigits);
        uint8 j = 0;

        for (uint8 i = numDigits; i > 0; i--) {
            uint8 digitIndex = uint8((customInput.tokenId / (10**j)) % 10);
            _parts[i - 1] = digits[digitIndex];
            j++;
        }

        return _parts;
    }

    /**
     * @notice Generate DAFO name.
     */
    function _getClubIdFromTokenId(uint256 tokenId) internal pure returns (string memory) {
        if (tokenId < 10) {
            return string(abi.encodePacked('000', tokenId.toString()));
        } else if (tokenId < 100) {
            return string(abi.encodePacked('00', tokenId.toString()));
        } else if (tokenId < 1000) {
            return string(abi.encodePacked('0', tokenId.toString()));
        } else {
            return string(abi.encodePacked(tokenId.toString()));
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for DafoCustomizer

pragma solidity ^0.8.6;

import {IDafoDescriptor} from './IDafoDescriptor.sol';

interface IDafoCustomizer {
    struct CustomInput {
        uint256 tokenId;
        uint8 role;
        uint8 palette;
        bool outline;
    }

    function generateInput(
        uint256 unavailableId,
        uint256 tokenMax,
        IDafoDescriptor descriptor
    ) external view returns (CustomInput memory);

    function create(
        uint256 tokenId,
        uint8 role,
        uint8 palette,
        bool outline
    ) external view returns (CustomInput memory);

    function isInBounds(IDafoDescriptor descriptor, IDafoCustomizer.CustomInput calldata _customInput) external view;
}

// SPDX-License-Identifier: GPL-3.0

/// @title A library used to convert multi-part RLE compressed images to SVG

pragma solidity ^0.8.6;

import '@openzeppelin/contracts/utils/Strings.sol';

library MultiPartSVGsToSVG {
    struct SVGParams {
        string[] parts;
        string role;
        string background;
        string fill;
        bool outline;
    }

    /**
     * @notice Given SVGs image parts and color palettes, merge to generate a single SVG image.
     */
    function generateSVG(SVGParams memory params) internal pure returns (string memory svg) {
        // prettier-ignore
        return
            string(
                abi.encodePacked(
                    '<svg viewBox="0 0 32 32" xmlns="http://www.w3.org/2000/svg">',
                    _generateOutline(params),
                    '<rect width="100%" height="100%" fill="#',
                    params.background,
                    '" />',
                    '<g fill="#',
                    params.fill,
                    '">',
                    params.role,
                    '</g>',
                    _generateSVGDigits(params),
                    '</svg>'
                )
            );
    }

    /**
     * @notice Given SVG of each digit, generate svg group of digits
     */
    // prettier-ignore
    function _generateSVGDigits(SVGParams memory params)
        private
        pure
        returns (string memory svg)
    {
        string memory digits;
        uint16 translateX = 1700;
        for (uint8 p = 0; p < params.parts.length; p++) {
            digits = string(abi.encodePacked(digits, '<g transform="scale(0.01) translate(', Strings.toString(translateX), ',2800)">', params.parts[p], ' fill="#', params.fill, '" /></g>'));
            translateX += 300;
        }
        return digits;
    }

    /**
     * @notice Given SVG of each digit, generate svg group of digits
     */
    // prettier-ignore
    function _generateOutline(SVGParams memory params)
        private
        pure
        returns (string memory svg)
    {
        if (params.outline) {
            return string(abi.encodePacked('<style>.outline{fill:none;stroke:#', params.fill, ';stroke-miterlimit:10;stroke-width:0.1px;}</style>'));
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

/// @title A library used to construct ERC721 token URIs and SVG images

pragma solidity ^0.8.6;

import {Base64} from 'base64-sol/base64.sol';
import {MultiPartSVGsToSVG} from './MultiPartSVGsToSVG.sol';

library NFTDescriptor {
    struct TokenURIParams {
        string name;
        string description;
        string[] parts;
        string role;
        string background;
        string fill;
        bool outline;
    }

    /**
     * @notice Construct an ERC721 token URI.
     */
    function constructTokenURI(TokenURIParams memory params) public pure returns (string memory) {
        string memory image = generateSVGImage(
            MultiPartSVGsToSVG.SVGParams({
                parts: params.parts,
                background: params.background,
                role: params.role,
                fill: params.fill,
                outline: params.outline
            })
        );

        // prettier-ignore
        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked('{"name":"', params.name, '", "description":"', params.description, '", "image": "', 'data:image/svg+xml;base64,', image, '"}')
                    )
                )
            )
        );
    }

    /**
     * @notice Generate an SVG image for use in the ERC721 token URI.
     */
    function generateSVGImage(MultiPartSVGsToSVG.SVGParams memory params) public pure returns (string memory svg) {
        return Base64.encode(bytes(MultiPartSVGsToSVG.generateSVG(params)));
    }
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for DafoDescriptor

pragma solidity ^0.8.6;

import {IDafoCustomizer} from './IDafoCustomizer.sol';

interface IDafoDescriptor {
    struct Palette {
        string background;
        string fill;
    }

    event PartsLocked();

    event DataURIToggled(bool enabled);

    event BaseURIUpdated(string baseURI);

    function arePartsLocked() external returns (bool);

    function isDataURIEnabled() external returns (bool);

    function baseURI() external returns (string memory);

    function paletteCount() external view returns (uint256);

    function digitCount() external view returns (uint256);

    function roleCount() external view returns (uint256);

    function addManyPalettes(Palette[] calldata _palettes) external;

    function addManyDigits(string[] calldata _digits) external;

    function addManyRoles(string[] calldata _roles) external;

    function addPalette(uint8 index, Palette calldata _palette) external;

    function addDigit(uint8 index, string calldata _digit) external;

    function addRole(uint8 index, string calldata _roles) external;

    function lockParts() external;

    function toggleDataURIEnabled() external;

    function setBaseURI(string calldata baseURI) external;

    function tokenURI(IDafoCustomizer.CustomInput memory customInput) external view returns (string memory);

    function dataURI(IDafoCustomizer.CustomInput memory customInput) external view returns (string memory);

    function genericDataURI(
        string calldata name,
        string calldata description,
        IDafoCustomizer.CustomInput memory customInput
    ) external view returns (string memory);

    function generateSVGImage(IDafoCustomizer.CustomInput memory customInput) external view returns (string memory);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}