// SPDX-License-Identifier: MIT
// Creator: 0xVinasaur
pragma solidity ^0.8.4;
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import "./Ownable.sol";

abstract contract ColorableSectionMapBase {
    // mapping of traitTypes, traitNames, and mapping of colorableSections for the trait
    mapping(string => mapping(string => mapping(uint256 => bool))) public colorableAreas;
    mapping(string => mapping(string => uint256)) public numColorableAreas;

    // pass in an array of arrays 
    function _setColorableAreas(string[] memory _traitTypes, string[] memory _traitNames, uint256[] memory _colorableAreas) internal virtual {
        require(_traitTypes.length == _traitNames.length && _traitNames.length == _colorableAreas.length, 
            "ColorableSectionMap#PARAM_LENGTH_MIS_MATCH");
        uint256 _loopThrough = _traitTypes.length;
        for (uint256 i = 0; i < _loopThrough; i++) {
            colorableAreas[_traitTypes[i]][_traitNames[i]][_colorableAreas[i]] = true;
            numColorableAreas[_traitTypes[i]][_traitNames[i]]++;
        }
    }

    function verifyColorMap(string[] memory traitTypes, string[] memory traitNames, uint256[] memory areasToColor) public view {
        require(traitTypes.length == traitNames.length && 
            traitNames.length == areasToColor.length, "ColorableSectionMap#colorInCanvas: COLORMAP_LENGTH_MISMATCH");
        uint256 _loopThrough = traitTypes.length;
        for (uint256 i = 0; i < _loopThrough; i++) {
            string memory _traitType = traitTypes[i];
            string memory _traitNames = traitNames[i];
            uint256 _areaToColor = areasToColor[i];
            bool _isColorableArea = colorableAreas[_traitType][_traitNames][_areaToColor];
            require(_isColorableArea, "verifyColorMap#colorInCanvas: AREA_NOT_COLORABLE");
        }
    }
}

contract ColorableSectionMap is ColorableSectionMapBase, Ownable {
    address public colorableCollection;
    string public name;

    constructor(address _collection, string memory _name) {
        colorableCollection = _collection;
        name = _name;
    }

    function setColorableAreas(string[] memory _traitTypes, string[] memory _traitNames, uint256[] memory _colorableAreas) public onlyOwner {
        _setColorableAreas(_traitTypes, _traitNames, _colorableAreas);
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
// Creator: 0xVinasaur
pragma solidity ^0.8.4;

abstract contract Ownable {
    address public owner;
    event OwnershipTransferred(
        address indexed oldOwner_,
        address indexed newOwner_
    );

    constructor() {
        owner = msg.sender;
    }

    function _onlyOwner() internal view {
      require(owner == msg.sender, "Ownable: caller is not the owner");
    }

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _transferOwnership(address newOwner_) internal virtual {
        address _oldOwner = owner;
        owner = newOwner_;
        emit OwnershipTransferred(_oldOwner, newOwner_);
    }

    function transferOwnership(address newOwner_) public virtual onlyOwner {
        require(
            newOwner_ != address(0x0),
            "Ownable: new owner is the zero address!"
        );
        _transferOwnership(newOwner_);
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0x0));
    }
}