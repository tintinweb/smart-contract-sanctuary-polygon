// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Strings.sol";

contract ClassCorsair {
    using Strings for string;
    uint64 internal constant CLASS_ID = 1;
    string internal constant className = "Corsair";
    string internal URI =
        "https://ipfs.io/ipfs/QmaqnVYQJNeAzwAKRn6YKMt1RYx1kRmtFbFyvx4FwYhV9f?filename=corsair.json";
    address internal owner;

    mapping(uint256 => Attribut) internal attributs;
    struct Attribut {
        uint32 Minboarding;
        uint32 Maxboarding;
        uint32 Minsailing;
        uint32 Maxsailing;
        uint32 Mincharisma;
        uint32 Maxcharisma;
        uint64 classId;
    }

    constructor() {
        owner = msg.sender;
        _setAttribute();
    }

    function _setAttribute() internal {
        attributs[CLASS_ID].Minboarding = 60;
        attributs[CLASS_ID].Maxboarding =
            100 -
            (attributs[CLASS_ID].Minboarding - 1);
        attributs[CLASS_ID].Minsailing = 30;
        attributs[CLASS_ID].Maxsailing =
            40 -
            (attributs[CLASS_ID].Minsailing - 1);
        attributs[CLASS_ID].Mincharisma = 80;
        attributs[CLASS_ID].Maxcharisma =
            120 -
            (attributs[CLASS_ID].Mincharisma - 1);
        attributs[CLASS_ID].classId = CLASS_ID;
    }

    function setURI(string memory _uri) external onlyOwner {
        URI = _uri;
    }

    function getClassURI() external view returns (string memory) {
        return URI;
    }

    function getClassName() external pure returns (string memory) {
        return className;
    }

    function getClassIF() external pure returns (uint256) {
        return CLASS_ID;
    }

    function mintClass() external view returns (Attribut memory attributs_) {
        return (attributs[CLASS_ID]);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
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