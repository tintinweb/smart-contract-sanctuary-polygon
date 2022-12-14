// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Token{
    //Storing My token Details;
    string name;
    string symbol;
    uint totalSupply;

    //assigning Balance to token holder
    mapping(address =>uint) public balanceOf;


    mapping(address => mapping(address => uint)) public allowance;

    constructor(string memory _name, string memory _symbol, uint _totalSupply) public {
    name = _name;
    symbol = _symbol;
    totalSupply = _totalSupply;
    balanceOf[msg.sender] = totalSupply;
  }
  function transfer(address _to, uint _value) public returns (bool) {
    require(balanceOf[msg.sender] >= _value, "Insufficient balance.");
    balanceOf[msg.sender] -= _value;
    balanceOf[_to] += _value;
    return true;
  }
  function approve(address _spender, uint _value) public returns (bool) {
    allowance[msg.sender][_spender] = _value;
    return true;
  }

  function transferFrom(address _from, address _to, uint _value) public returns (bool) {
    require(balanceOf[_from] >= _value, "Insufficient balance.");
    require(allowance[_from][msg.sender] >= _value, "Insufficient allowance.");
    balanceOf[_from] -= _value;
    balanceOf[_to] += _value;
    allowance[_from][msg.sender] -= _value;
    return true;
  }


}