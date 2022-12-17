/**
 *Submitted for verification at polygonscan.com on 2022-12-16
*/

// SPDX-License-Identifier: MIT
// Tells the Solidity compiler to compile only from v0.8.13 to v0.9.0
pragma solidity ^0.8.13;

contract TestCoin
{

  string  public _name = "Test Token";
  string  public _symbol = "LIBERO";
  uint8  public _decimals = 2;
  uint256 _totalSupply = 500000;

  // Create a table so that we can map addresses
  // to the balances associated with them
  mapping(address => uint256) balances;

  // Create a table so that we can map
  // the addresses of contract owners to
  // those who are allowed to utilize the owner's contract
  mapping(address => mapping (address => uint256)) allowed;

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

  function transfer(address _to, uint256 _amount) public returns (bool success) {
    if (balances[msg.sender] >= _amount
        && _amount > 0
        && balances[_to] + _amount > balances[_to]) {
      balances[msg.sender] -= _amount;
      balances[_to] += _amount;
      emit Transfer(msg.sender, _to, _amount);
      return true;
    } else {
      return false;
    }
  }

  function approve(address _spender, uint256 _amount) public returns (bool success) {
    allowed[msg.sender][_spender] = _amount;
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {
    if (balances[_from] >= _amount
        && allowed[_from][msg.sender] >= _amount
        && _amount > 0
        && balances[_to] + _amount > balances[_to]) {
      balances[_from] -= _amount;
      balances[_to] += _amount;
      return true;
    } else {
      return false;
    }
  }

  constructor() {
    balances[msg.sender] = _totalSupply;
  }

  /**
   * @return the name of the token.
   */
  function name() public view returns(string memory) {
    return _name;
  }

  /**
   * @return the symbol of the token.
   */
  function symbol() public view returns(string memory) {
    return _symbol;
  }

  /**
   * @return the number of decimals of the token.
   */
  function decimals() public view returns(uint8) {
    return _decimals;
  }

  /**
   * Let's people know you are sending tokens
   */
  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );
}