/**
 *Submitted for verification at polygonscan.com on 2023-06-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ChibariHillsToken {
    uint256 _totalSupply;
    mapping(address => uint256) balances;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    string _name = "Chibari Hills Token";
    string _symbol = "CHIT";

    constructor(uint256 _initialSupply) {
        _totalSupply = _initialSupply;
        balances[msg.sender] = _initialSupply;
    }

    // what's the name and symbol of the token?
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    // how to display the token amount human-readable
    function decimals() public pure returns (uint8) {
        return 18;
    }

    // how many tokens exist?
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    // who owns tokens? and how many per person?
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    // how to transfer tokens to a new owner?
    function transfer(address _to, uint256 _value) public returns (bool success) {
        // check if the sender has enough tokens
        require(balances[msg.sender] >= _value, "insufficient balance");
        // substract from the sender
        balances[msg.sender] -= _value;

        // add to the recipient
        balances[_to] += _value;

        // log the transfer event
        emit Transfer(msg.sender, _to, _value);

        // return a boolean indicating success
        return true;
    }
}