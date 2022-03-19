/**
 *Submitted for verification at polygonscan.com on 2022-03-18
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
 
 
contract MetaNFT{
    string public name;
    string public symbol;

    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _owners;
    

    constructor() {
        name = "Meta";
        symbol = "MNF";
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}


    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0));
        return owner;
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0));
        return _balances[owner];
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);


    function mint(address _to, uint256 _tokenId) external {
    _mint(_to, _tokenId);
    }


    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0));

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }   
}