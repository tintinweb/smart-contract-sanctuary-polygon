// Modified: https://gitlab.com/open0x-libraries/erc721/-/blob/main/ERC721I.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MetaID721 {
    string public name;
    string public symbol;
    string internal baseTokenURI;
    string internal baseTokenURI_EXT;

    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
    }

    uint256 public totalSupply;
    mapping(uint256 => address) public ownerOf;
    mapping(address => uint256) public balanceOf;

    mapping(uint256 => address) public getApproved;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    // Events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // // internal write functions
    // mint
    function _mint(address to_, uint256 tokenId_) internal virtual {
        require(to_ != address(0x0), "ERC721I: _mint() Mint to Zero Address");
        require(ownerOf[tokenId_] == address(0x0), "ERC721I: _mint() Token to Mint Already Exists!");

        balanceOf[to_]++;
        ownerOf[tokenId_] = to_;

        emit Transfer(address(0x0), to_, tokenId_);
    }

    // token uri
    function _setBaseTokenURI(string memory uri_) internal virtual {
        baseTokenURI = uri_;
    }

    function _setBaseTokenURI_EXT(string memory ext_) internal virtual {
        baseTokenURI_EXT = ext_;
    }

    // // Internal View Functions
    // Embedded Libraries
    function _toString(uint256 value_) internal pure returns (string memory) {
        if (value_ == 0) {
            return "0";
        }
        uint256 _iterate = value_;
        uint256 _digits;
        while (_iterate != 0) {
            _digits++;
            _iterate /= 10;
        } // get digits in value_
        bytes memory _buffer = new bytes(_digits);
        while (value_ != 0) {
            _digits--;
            _buffer[_digits] = bytes1(uint8(48 + uint256(value_ % 10)));
            value_ /= 10;
        } // create bytes of value_
        return string(_buffer); // return string converted bytes of value_
    }

    // Functional Views
    function _isApprovedOrOwner(address spender_, uint256 tokenId_) internal view virtual returns (bool) {
        require(ownerOf[tokenId_] != address(0x0), "ERC721I: _isApprovedOrOwner() Owner is Zero Address!");
        address _owner = ownerOf[tokenId_];
        return (spender_ == _owner || spender_ == getApproved[tokenId_] || isApprovedForAll[_owner][spender_]);
    }

    function _exists(uint256 tokenId_) internal view virtual returns (bool) {
        return ownerOf[tokenId_] != address(0x0);
    }

    // 0xInuarashi Custom Functions

    // OZ Standard Stuff
    function supportsInterface(bytes4 interfaceId_) public pure returns (bool) {
        return (interfaceId_ == 0x80ac58cd || interfaceId_ == 0x5b5e139f);
    }

    function tokenURI(uint256 tokenId_) public view virtual returns (string memory) {
        require(ownerOf[tokenId_] != address(0x0), "ERC721I: tokenURI() Token does not exist!");
        return string(abi.encodePacked(baseTokenURI, _toString(tokenId_), baseTokenURI_EXT));
    }

    // // public view functions
    // never use these for functions ever, they are expensive af and for view only
    function walletOfOwner(address address_) public view virtual returns (uint256[] memory) {
        uint256 _balance = balanceOf[address_];
        uint256[] memory _tokens = new uint256[](_balance);
        uint256 _index;
        uint256 _loopThrough = totalSupply;
        for (uint256 i = 0; i < _loopThrough; i++) {
            if (ownerOf[i] == address(0x0) && _tokens[_balance - 1] == 0) {
                _loopThrough++;
            }
            if (ownerOf[i] == address_) {
                _tokens[_index] = i;
                _index++;
            }
        }
        return _tokens;
    }

    // not sure when this will ever be needed but it conforms to erc721 enumerable
    function tokenOfOwnerByIndex(address address_, uint256 index_) public view virtual returns (uint256) {
        uint256[] memory _wallet = walletOfOwner(address_);
        return _wallet[index_];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

// Open0x Ownable (by 0xInuarashi)
abstract contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed oldOwner_, address indexed newOwner_);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function _transferOwnership(address newOwner_) internal virtual {
        address _oldOwner = owner;
        owner = newOwner_;
        emit OwnershipTransferred(_oldOwner, newOwner_);
    }

    function transferOwnership(address newOwner_) public virtual onlyOwner {
        require(newOwner_ != address(0x0), "Ownable: new owner is the zero address!");
        _transferOwnership(newOwner_);
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0x0));
    }
}

// SPDX-License-Identifier: Unlicense

pragma solidity >=0.8.2 <0.9.0;

import "./libs/Ownable.sol";
import "./libs/MetaID721.sol";

abstract contract Security {
    modifier onlySender() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }
}

contract MetaID is MetaID721, Security, Ownable {
    constructor() MetaID721("MetaID", "MID") {}

    mapping(address => bool) public hasId;

    function mintId(address _address) external onlyOwner {
        require(!hasId[_address], "The address has MetaID");
        uint256 currentToken = totalSupply + 1;
        _mint(_address, currentToken);
        hasId[_address] = true;
        totalSupply++;
    }

    function setBaseTokenURI(string memory baseURI) external onlyOwner {
        _setBaseTokenURI(baseURI);
    }
}