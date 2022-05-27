// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;
import "@openzeppelin/contracts/utils/Strings.sol";

contract OpenSeaTestToken  {
    string tokenRevealURI = "https://heroku.ether.cards/card/";

    using Strings for uint256;


    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Token name
    string private _name = "OS Test";
    // Token symbol
    string private _symbol = "OST";

    uint256 supply = 0;


    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    constructor() {
        emit Transfer(address(0), address(this), 1);
        emit Transfer(address(0), address(this), 2);
        emit Transfer(address(0), address(this), 3);
        emit Transfer(address(0), address(this), 4);
        emit Transfer(address(0), address(this), 5);
    }

    function _mint(address to, uint256 tokenId) public {
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
        supply++;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        string memory folder = (_tokenId % 100).toString(); 
        string memory file = _tokenId.toString();
        string memory slash = "/";
        return string(abi.encodePacked(tokenRevealURI, folder, slash, file, ".json"));
    }

    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return true;
    }
    

    function totalSupply() public view returns (uint256) {
        return supply;
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