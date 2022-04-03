/**
 *Submitted for verification at polygonscan.com on 2022-04-03
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

// File: contracts/METAPASSERC721.sol


pragma solidity ^0.8.13;

abstract contract METAPASSERC721 {

    event Mint(address indexed _minter, uint _id);
    event Transfer(address indexed _from, address indexed _to, uint indexed _id);
    event Approval(address indexed _owner, address indexed _approved, uint indexed _id);

    string private _name;
    string private _symbol;

    bool private _status;

    mapping(address => bool) private _isOwner;
    mapping(uint => address) private _ownerOf;
    mapping(uint => address) private _tokenApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /* PUBLIC FUNCTIONS */

    function safeTransferFrom(address _from, address _to, uint256 _id) external {
        _transfer(_from, _to, _id);
    }

    // В стандарте ERC721 есть три функции для отправки токена, думаю, если нагромождать контракт
    // тремя функциями которые делают одно и тоже то план хуйня, по этому сейчас оставил только эту.
    //
    // function TransferFrom(address _from, address _to, uint256 _id) external {
    //     _transfer(_from, _to, _id);
    // }


    /* PRIVATE FUNCTIONS */

    function _mint(address _to, uint256 _id) internal virtual {
        require(_to != address(0));
        require(_ownerOf[_id] == address(0), "TOKEN MINTED");
        require(_isOwner[_to] == false);
        _isOwner[_to] = true;
        _ownerOf[_id] = _to;

        emit Mint(msg.sender, _id);
    }

    function _approve(address _to, uint _id) internal {
        require(_to != address(0));
        require(_ownerOf[_id] == msg.sender);
        _tokenApprovals[_id] = _to;
        emit Approval(msg.sender, _to, _id);
    }

    function _transfer(address _from, address _to, uint _id) internal {
        require(_to != address(0) || _isOwner[_to] == false);
        require(_ownerOf[_id] == _from || _status == true);
        require(_isApprovedOrOwner(msg.sender, _id) == true);
        _isOwner[_from] = false;
        _isOwner[_to] = true;
        _ownerOf[_id] = _to;
        emit Transfer(_from, _to, _id);
    }

    function _statusOn() internal {
        _status = true;
    }

    /* PUBLIC GETTERS */

    function getApproved(uint256 _id) public view returns (address) {
        return _tokenApprovals[_id];
    }

    function isApprovedForAll(address, address) pure public returns (bool) {
        return false;
    }

    function balanceOf(address _owner) public view returns (uint) {
        if (_isOwner[_owner] == true) {
            return 1;
        } else {
            return 0;
        }
    }

    function ownerOf(uint _id) public view returns (address) {
        address _owner = _ownerOf[_id];
        require(_owner != address(0), "ERC721: owner query for nonexistent token");
        return _owner;
    }

    function tokenURI(uint256 _id) public view virtual returns (string memory);

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    fallback() external {
        revert("MetaPass");
    }

    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /* PRIVATE GETTERS */

    function _exists(uint256 _tokenId) internal view returns (bool) {
        return _ownerOf[_tokenId] != address(0);
    }

    function _isApprovedOrOwner(address _spender, uint _id) private view returns (bool) {
        require(_exists(_id), "ERC721: operator query for nonexistent token");
        address _owner = ownerOf(_id);
        return (_spender == _owner || getApproved(_id) == _spender);
    }
}
// File: contracts/MetaPassPlayer.sol


pragma solidity ^0.8.13;



contract MetaPass is METAPASSERC721 {
    using Strings for uint;

    uint private _counter;

    string public baseExtension = ".json";
    string private _baseuri = "https://novaguild.io/";
    
    address private _admin;

    constructor() METAPASSERC721("NOVAULTIMATENFT","AHAHANFTLOLLOLOLOLOL") {
        _admin = msg.sender;
    }

    modifier OnlyAdmin {
        require(_admin == msg.sender);
        _;
    }

    /* PUBLIC FUNCTIONS */

    function mintToken() public {
        _counter++;
        _mint(msg.sender, _counter);
    }

    function setNewBaseURI(string memory _newuri) external OnlyAdmin {
        _baseuri = _newuri;
    }

    function setStatus() external OnlyAdmin {
        _statusOn();
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