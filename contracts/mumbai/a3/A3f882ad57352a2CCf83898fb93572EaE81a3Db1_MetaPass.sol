/**
 *Submitted for verification at polygonscan.com on 2022-04-02
*/

// File: @openzeppelin/contracts/utils/Strings.sol


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

// File: contracts/SoulboundERC721.sol


pragma solidity ^0.8.13;

abstract contract SoulboundERC721 {

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    string public name;
    string public symbol;

    mapping(address => uint256) public balanceOf;
    mapping(uint256 => address) public ownerOf;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /* PRIVATE FUNCTIONS */

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");
        require(ownerOf[id] == address(0), "ALREADY_MINTED");

        unchecked {
            balanceOf[to]++;
        }

        ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    /* PUBLIC GETTERS */

    function getApproved(uint256) pure public returns (address) {
        return address(0);
    }

    function isApprovedForAll(address, address) pure public returns (bool) {
        return false;
    }

    function tokenURI(uint256 id) public view virtual returns (string memory);

    fallback() external {
        revert("SOULBOUND");
    }

    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /* PRIVATE GETTERS */

    function _exists(uint256 tokenId) internal view returns (bool) {
        return ownerOf[tokenId] != address(0);
    }
}
// File: contracts/NFT.sol


pragma solidity ^0.8.13;



contract MetaPass is SoulboundERC721 {
    using Strings for uint;

    uint private _counter;

    string public baseExtension = ".json";
    string private _baseuri = "https://novaguild.io/";
    
    address private _admin;

    constructor() SoulboundERC721("METAS","ULTIMATE META WORDS") {
        _admin = msg.sender;
    }

    /* PUBLIC FUNCTIONS */

    function mintToken() public {
        _counter++;
        _mint(msg.sender, _counter);
    }

    function setNewBaseURI(string memory _newuri) public {
        require(_admin == msg.sender);
        _baseuri = _newuri;
    }

    /* PUBLIC GETTERS */

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension)): "";
    }

    /* PRIVATE GETTERS */

    function _baseURI() internal view returns (string memory) {
        return _baseuri;
    }
}