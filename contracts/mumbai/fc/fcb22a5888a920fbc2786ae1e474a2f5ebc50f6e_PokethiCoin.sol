/**
 *Submitted for verification at polygonscan.com on 2022-05-04
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

library SafeMath {
  //pure Functions: does not change or query any value on Blockchain, it's free of fees
  function add(uint a, uint b) internal pure returns(uint) {
    uint c = a + b;
    require(c >= a, "Add Overflow!");

    return c;
  }

  function sub(uint a, uint b) internal pure returns(uint) {
    require(b <= a, "Sub Underflow!");
    uint c = a - b;

    return c;
  }

  function mul(uint a, uint b) internal pure returns(uint) {
    if(a == 0){
      return 0;
    }

    uint c = a * b;
    require(c / a == b, "Mul Overflow");

    return c;
  }

  function div(uint a, uint b) internal pure returns(uint) {
    uint c = a / b;
    
    return c;
  }
}

contract Ownable {
  address payable internal owner;

  constructor(){
    owner = payable(msg.sender);
  }

  modifier onlyOwner(){
    require(msg.sender == owner, "Ops! Only the Contract Owner can access this.");
    _;
  }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is IERC20, Ownable {
  using SafeMath for uint256;

  uint256 internal _totalSupply;
  mapping(address => uint256) internal _balances;
  mapping(address => mapping(address => uint256)) internal _allowed;

  function totalSupply() public override view returns (uint256){
    return _totalSupply - _balances[address(0)];
  }

  function balanceOf(address account) public override view returns (uint256){
    return _balances[account];
  }

  function transfer(address recipient, uint256 amount) public override returns(bool){
    require(_balances[msg.sender] >= amount, "Insufficient funds.");

    _balances[msg.sender] = _balances[msg.sender].sub(amount);
    _balances[recipient] = _balances[recipient].add(amount);

    emit Transfer(msg.sender, recipient, amount);

    return true;
  }

  function approve(address spender, uint256 amount) public override returns (bool){
    _allowed[msg.sender][spender] = amount;

    emit Approval(msg.sender, spender, amount);

    return true;
  }

  function allowance(address owner, address spender) public override view returns (uint256){
    return _allowed[owner][spender];
  }

  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool){
    require(_allowed[sender][msg.sender] >= amount, "The sender didn't allowed you to transfer this amount.");
    require(_balances[sender] >= amount, "Insufficient sender funds.");

    _balances[sender] = _balances[sender].sub(amount);
    _allowed[sender][msg.sender] = _allowed[sender][msg.sender].sub(amount);
    _balances[recipient] = _balances[recipient].add(amount);

    emit Transfer(sender, recipient, amount);

    return true;
  }
}

contract MintableToken is BasicToken {
  using SafeMath for uint256;

  event Mint(address indexed recipient, uint256 amount);

  function mint(address recipient, uint256 amount) onlyOwner public{
    _balances[recipient] = _balances[recipient].add(amount);
    _totalSupply = _totalSupply.add(amount);

    emit Mint(recipient, amount);
  }

  function mintMyPKT() public{
    uint256 amount = 1e18;
    require(_balances[msg.sender] == 0, "Ops! You has already mint your PKT.");
    _balances[msg.sender] = _balances[msg.sender].add(amount);
    _totalSupply = _totalSupply.add(amount);

    emit Mint(msg.sender, amount);
  }
}

contract PokethiCoin is MintableToken {
  string public constant name = "PokethiCoin";
  string public constant symbol = "PKT";
  uint8 public constant decimals = 18;
}