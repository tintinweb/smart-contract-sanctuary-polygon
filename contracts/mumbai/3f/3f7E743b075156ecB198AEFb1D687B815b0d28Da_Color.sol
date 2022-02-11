/**
 *Submitted for verification at polygonscan.com on 2022-02-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Color {
    string _name;
    string _symbol;
    mapping(address => uint256) _balances;
    mapping(uint256 => address) _tokens;
    uint256 _counter = 0;
    uint256 tokenPrice = uint256( 5 * 10**16);

    constructor(string memory name, string memory symbol) {
        _name = name;
        _symbol = symbol;
    }

    function __name() public view returns (string memory) {
        return _name;
    }

    function __symbol() public view returns (string memory) {
        return _symbol;
    }

    function totalSupply() public view returns (uint256) {
        return _counter;
    }

    function balanceOf(address userAddress) public view returns (uint256) {
        return _balances[userAddress];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        return _tokens[tokenId];
    }

    function mint(uint256 _num) public payable {
        require(msg.value >= _num * tokenPrice, "Insufficient amount provided!");
        _counter = _counter + 1;
        _tokens[_counter] = msg.sender;
        _balances[msg.sender]++;
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable {
        require(tokenId <= _counter, "Token id does not exist!");
        require(_tokens[tokenId] == from, "Token isnot owned by given address!");
        require(from != to, "Both address cannot be same!");
        _tokens[tokenId] = to;
        _balances[from]--;
        _balances[to]++;
    }
}