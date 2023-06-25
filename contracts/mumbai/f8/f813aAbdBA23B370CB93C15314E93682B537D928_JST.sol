/**
 *Submitted for verification at polygonscan.com on 2023-06-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract JST {

  string public name = 'JST';
  string public symbol = 'JST';
  uint256 public decimals = 18;
  uint256 public totalSupply = 0;
  
  mapping (address => bool) public minters;
  mapping (address => bool) public admins;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  mapping (address => uint256) balances;
  mapping (address => mapping (address => uint256)) internal allowed;

  modifier onlyMinter() {
    require(minters[msg.sender], "JST: insufficient minter privilege");
    _;
  }

  modifier onlyAdmin() {
    require(admins[msg.sender], "JST: insufficient admin privilege");
    _;
  }

  constructor() {
    minters[msg.sender] = true;
    admins[msg.sender] = true;
  }
  
  function addMinter(address _minter) external onlyMinter returns (bool) {
    minters[_minter] = true;
    return true;
  }

  function removeMinter(address _minter) external onlyMinter returns (bool) {
    minters[_minter] = false;
    return true;
  }

  function addAdmin(address _admin) external onlyAdmin returns (bool) {
    admins[_admin] = true;
    return true;
  }

  function removeAdmin(address _admin) external onlyAdmin returns (bool) {
    admins[_admin] = false;
    return true;
  }

  function transfer(address _to, uint256 _value) external returns (bool) {
    require(_to != address(0), "JET: can't mit to zero address");
    require(_value <= balances[msg.sender], "JET: insufficient fund");

    balances[msg.sender] = balances[msg.sender] - _value;
    balances[_to] = balances[_to] + _value;
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function balanceOf(address _owner) external view returns (uint256 balance) {
    return balances[_owner];
  }

  function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
    require(_to != address(0), "JET: can't mit to zero address");
    require(_value <= balances[_from], "JET: insufficient fund");
    require(_value <= allowed[_from][msg.sender], "JET: insufficient allowance");

    balances[_from] = balances[_from] - _value;
    balances[_to] = balances[_to] + _value;
    allowed[_from][msg.sender] = allowed[_from][msg.sender] - _value;
    emit Transfer(_from, _to, _value);
    return true;
  }

  function transferByAdmin(address _from, address _to, uint256 _value) external onlyAdmin returns (bool) {
    require(_to != address(0), "JET: can't mit to zero address");
    require(_value <= balances[_from], "JET: insufficient fund");

    balances[_from] = balances[_from] - _value;
    balances[_to] = balances[_to] + _value;
    allowed[_from][msg.sender] = allowed[_from][msg.sender] - _value;
    emit Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) external returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) external view returns (uint256) {
    return allowed[_owner][_spender];
  }
  
  function mint(address _to, uint256 _amount) external onlyMinter returns (bool) {
    balances[_to] = balances[_to] + _amount;
    totalSupply = totalSupply + _amount;
    emit Transfer(address(0), _to, _amount);
    return true;
  }
  
  function burn(uint256 _amount) external returns (bool) {
    balances[msg.sender] = balances[msg.sender] - _amount;
    totalSupply = totalSupply - _amount;
    emit Transfer(msg.sender, address(0), _amount);
    return true;
  }
}