/**
 *Submitted for verification at polygonscan.com on 2022-03-09
*/

pragma solidity 0.4.24;

/*
The MIT License (MIT)

Copyright (c) 2016-2020 zOS Global Limited

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
    function toAscii(address account) internal pure returns (string) {
        bytes32 value = bytes32(uint256(account));
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(42);
        str[0] = '0';
        str[1] = 'x';
        for (uint i = 0; i < 20; i++) {
            str[2+i*2] = alphabet[uint(uint8(value[i + 12] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(value[i + 12] & 0x0f))];
        }
        return string(str);
    }
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

contract ERC165 is IERC165 {
    bytes4 private constant _InterfaceId_ERC165 = 0x01ffc9a7;
    mapping(bytes4 => bool) internal _supportedInterfaces;
    constructor() public {
        _registerInterface(_InterfaceId_ERC165);
    }
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff);        
        _supportedInterfaces[interfaceId] = true;
    }
}

contract IERC721 is IERC165 {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
    function balanceOf(address owner) public view returns (uint256 balance);
    function ownerOf(uint256 tokenId) public view returns (address owner);
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);
    function transferFrom(address from, address to, uint256 tokenId) public;
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes data) public;
}

contract IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes data) public returns(bytes4);
}

contract ERC721 is ERC165, IERC721 {
    using SafeMath for uint256;
    using Address for address;
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
    mapping (uint256 => address) private _tokenOwner;
    mapping (uint256 => address) private _tokenApprovals;
    mapping (address => uint256) private _ownedTokensCount;
    mapping (address => mapping (address => bool)) private _operatorApprovals;
    bytes4 private constant _InterfaceId_ERC721 = 0x80ac58cd;
    constructor() public {
        _registerInterface(_InterfaceId_ERC721);
    }
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0));
        return _ownedTokensCount[owner];
    }
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0));
        return owner;
    }
    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender));
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId));
        return _tokenApprovals[tokenId];
    }
    function setApprovalForAll(address to, bool approved) public {
        require(to != msg.sender);
        _operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }
    function transferFrom(address from, address to, uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId));
        require(to != address(0));
        _clearApproval(from, tokenId);
        _removeTokenFrom(from, tokenId);
        _addTokenTo(to, tokenId);
        emit Transfer(from, to, tokenId);
    }
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes _data) public {
        transferFrom(from, to, tokenId);
        require(_checkAndCallSafeTransfer(from, to, tokenId, _data));
    }
    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0));
        _addTokenTo(to, tokenId);
        emit Transfer(address(0), to, tokenId);
    }
    function _burn(address owner, uint256 tokenId) internal {
        _clearApproval(owner, tokenId);
        _removeTokenFrom(owner, tokenId);
        emit Transfer(owner, address(0), tokenId);
    }
    function _clearApproval(address owner, uint256 tokenId) internal {
        require(ownerOf(tokenId) == owner);
            if (_tokenApprovals[tokenId] != address(0)) {
                _tokenApprovals[tokenId] = address(0);
            }
    }
    function _addTokenTo(address to, uint256 tokenId) internal {
        require(_tokenOwner[tokenId] == address(0));
        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to] = _ownedTokensCount[to].add(1);
    }
    function _removeTokenFrom(address from, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from);
        _ownedTokensCount[from] = _ownedTokensCount[from].sub(1);
        _tokenOwner[tokenId] = address(0);
    }
    function _checkAndCallSafeTransfer(address from, address to, uint256 tokenId, bytes _data) internal returns (bool) {
        if (!to.isContract()) {
            return true;
        }
        bytes4 retval = IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data);
        return (retval == _ERC721_RECEIVED);
    }
}

contract IERC721Enumerable is IERC721 {
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId);
    function tokenByIndex(uint256 index) public view returns (uint256);
}

contract ERC721Enumerable is ERC165, ERC721, IERC721Enumerable {
    mapping(address => uint256[]) private _ownedTokens;
    mapping(uint256 => uint256) private _ownedTokensIndex;
    uint256[] private _allTokens;
    mapping(uint256 => uint256) private _allTokensIndex;
    bytes4 private constant _InterfaceId_ERC721Enumerable = 0x780e9d63;
    constructor() public {
        _registerInterface(_InterfaceId_ERC721Enumerable);
    }
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < balanceOf(owner));
        return _ownedTokens[owner][index];
    }
    function totalSupply() public view returns (uint256) {
        return _allTokens.length;
    }
    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < totalSupply());
        return _allTokens[index];
    }
    function _addTokenTo(address to, uint256 tokenId) internal {
        super._addTokenTo(to, tokenId);
        uint256 length = _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);
        _ownedTokensIndex[tokenId] = length;
    }
    function _removeTokenFrom(address from, uint256 tokenId) internal {
        super._removeTokenFrom(from, tokenId);
        uint256 tokenIndex = _ownedTokensIndex[tokenId];
        uint256 lastTokenIndex = _ownedTokens[from].length.sub(1);
        uint256 lastToken = _ownedTokens[from][lastTokenIndex];
        _ownedTokens[from][tokenIndex] = lastToken;
        _ownedTokens[from].length--;
        _ownedTokensIndex[tokenId] = 0;
        _ownedTokensIndex[lastToken] = tokenIndex;
    }
    function _mint(address to, uint256 tokenId) internal {
        super._mint(to, tokenId);
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }
    function _burn(address owner, uint256 tokenId) internal {
        super._burn(owner, tokenId);
        uint256 tokenIndex = _allTokensIndex[tokenId];
        uint256 lastTokenIndex = _allTokens.length.sub(1);
        uint256 lastToken = _allTokens[lastTokenIndex];
        _allTokens[tokenIndex] = lastToken;
        _allTokens[lastTokenIndex] = 0;
        _allTokens.length--;
        _allTokensIndex[tokenId] = 0;
        _allTokensIndex[lastToken] = tokenIndex;
    }
}

contract IERC721Metadata is IERC721 {
    function name() external view returns (string);
    function symbol() external view returns (string);
    function tokenURI(uint256 tokenId) public view returns (string);
}

contract ERC721Metadata is ERC165, ERC721, IERC721Metadata {
    string internal _name;
    string internal _symbol;
    mapping(uint256 => string) private _tokenURIs;
    bytes4 private constant InterfaceId_ERC721Metadata = 0x5b5e139f;
    constructor(string name, string symbol) public {
        _name = name;
        _symbol = symbol;
        _registerInterface(InterfaceId_ERC721Metadata);
    }
    function name() external view returns (string) {
        return _name;
    }
    function symbol() external view returns (string) {
        return _symbol;
    }
    function tokenURI(uint256 tokenId) public view returns (string) {
        require(_exists(tokenId));
        return _tokenURIs[tokenId];
    }
    function _setTokenURI(uint256 tokenId, string uri) internal {
        require(_exists(tokenId));
        _tokenURIs[tokenId] = uri;
    }
    function _burn(address owner, uint256 tokenId) internal {
        super._burn(owner, tokenId);
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

contract ERC721Full is ERC721, ERC721Enumerable, ERC721Metadata {
    constructor(string name, string symbol) ERC721Metadata(name, symbol) public {
    }
}

contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() public {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

contract Pausable is Ownable {
    event Paused();
    event Unpaused();
    bool private _paused = false;
    function paused() public view returns(bool) {
        return _paused;
    }
    modifier whenNotPaused() {
        require(!_paused);
        _;
    }
    modifier whenPaused() {
        require(_paused);
        _;
    }
    function pause() public onlyOwner whenNotPaused {
        _paused = true;
        emit Paused();
    }
    function unpause() public onlyOwner whenPaused {
        _paused = false;
        emit Unpaused();
    }
}

contract ERC721Pausable is ERC721, Pausable {
    function approve(address to, uint256 tokenId) public whenNotPaused {
        super.approve(to, tokenId);
    }
    function setApprovalForAll(address to, bool approved) public whenNotPaused {
        super.setApprovalForAll(to, approved);
    }
    function transferFrom(address from, address to, uint256 tokenId) public whenNotPaused {
        super.transferFrom(from, to, tokenId);
    }
}

contract CaptainAsset is ERC721Full, ERC721Pausable {
    string public tokenURIPrefix = "https://aquariumy.net/api/";
    string public query = ".php?id=";
    constructor() public ERC721Full("HarborBcg:CaptainP", "HBGC") {
    }
    function setTokenURIPrefix(string _tokenURIPrefix) external onlyOwner {
        tokenURIPrefix = _tokenURIPrefix;
    }
    function setQuery(string _query) external onlyOwner {
        query = _query;
    }
    function mintAsset(address _to, uint256 _tokenId) public onlyOwner {
        _mint(_to, _tokenId);
    }
    function tokenURI(uint256 _tokenId) public view returns (string) {
        bytes32 tokenIdBytes32;
        uint256 idLen = 0;
        if (_tokenId == 0) {
            tokenIdBytes32 = "0";
        } else {
            uint256 value = _tokenId;
            while (value > 0) {
                tokenIdBytes32 = bytes32(uint256(tokenIdBytes32) / (2 ** 8));
                tokenIdBytes32 |= bytes32(((value % 10) + 48) * 2 ** (8 * 31));
                value /= 10;
                idLen++;
            }
        }
        bytes memory prefixBytes = bytes(tokenURIPrefix);
        bytes memory thisAddressBytes = bytes(address(this).toAscii());
        bytes memory queryBytes = bytes(query);
        bytes memory tokenURIBytes = new bytes(prefixBytes.length + thisAddressBytes.length + queryBytes.length + idLen);
        uint256 i;
        uint256 index = 0;
        for (i = 0; i < prefixBytes.length; i++) {
            tokenURIBytes[index] = prefixBytes[i];
            index++;
        }
        for (i = 0; i < thisAddressBytes.length; i++) {
            tokenURIBytes[index] = thisAddressBytes[i];
            index++;
        }
        for (i = 0; i < queryBytes.length; i++) {
            tokenURIBytes[index] = queryBytes[i];
            index++;
        }
        for (i = 0; i < idLen; i++) {
            tokenURIBytes[index] = tokenIdBytes32[i];
            index++;
        }
        return string(tokenURIBytes);
    }
}