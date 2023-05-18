/**
 *Submitted for verification at polygonscan.com on 2023-05-17
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract MyToken {

    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public totalSupply;

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowance;

    event transferEvent(address indexed _from, address indexed _to, uint256 _value);
    event approvalEvent(address indexed _owner, address indexed _spender, uint256 _value);

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        decimals = 18;
        totalSupply = 10000000000000000000000000;
        balances[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) external {
        require(balances[msg.sender] >= _value, "Not enough funds.");
        require(_to != address(0) && _to != msg.sender, "Address not valid.");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit transferEvent(msg.sender, _to, _value);
    }

    function approval(address _spender, uint256 _value) external {
        require(balances[msg.sender] >= _value);
        require(_spender != address(0) && _spender != msg.sender, "Address not valid.");
        allowance[msg.sender][_spender] = _value;
        emit approvalEvent(msg.sender, _spender, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) external {
        require(balances[_from] >= _value, "Not enough funds.");
        require(allowance[_from][msg.sender] >= _value, "Not autorized.");
        require(_to != address(0) && _to != _from, "Address not valid.");
        allowance[_from][msg.sender] -= _value;
        balances[_from] -= _value;
        balances[_to] += _value;
        emit transferEvent(_from, _to, _value);
    }

}