/**
 *Submitted for verification at polygonscan.com on 2023-06-16
*/

/*
SPDX-License-Identifier: GPL-3.0
*/
pragma solidity 0.8.8;

contract aaa{
string public _name = "a";
string public _symbol = "b";
uint256 public _totalSupply = 100 *10**18;
uint8 public _decimals = 18;
event Transfer(address indexed from, address indexed to, uint256 value);
event Approval(address indexed owner, address indexed spender, uint256 value);
mapping (address => uint256) private _balances;
mapping (address => mapping (address => uint256)) private _allowances;
receive() external payable { }constructor()
{
_balances[msg.sender] = _totalSupply;
emit Transfer(address(0), msg.sender, _totalSupply);
}

function decimals() external view returns (uint8) {return _decimals;}
function symbol() external view returns (string memory) {return _symbol;}
function name() external view returns (string memory) {return _name;}
function totalSupply() external view returns (uint256) {return _totalSupply;}
function balanceOf(address account) external view returns (uint256) {return _balances[account];}

function transfer(address recipient, uint256 amount) external returns (bool) {
_transfer(msg.sender, recipient, amount);
return true;
}
function allowance(address owner, address spender) external view returns (uint256) {
return _allowances[owner][spender];
}
function approve(address spender, uint256 amount) external returns (bool) {
_approve(msg.sender, spender, amount);
return true;
}
function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
_transfer(sender, recipient, amount);
_approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
return true;
}
function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
_approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
return true;
}
function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
_approve(msg.sender, spender, _allowances[msg.sender][spender] - subtractedValue);
return true;
}
function _transfer(address sender, address recipient, uint256 amount) internal {
_balances[sender] -= amount;
_balances[sender] += amount;
emit Transfer(sender, recipient, amount);
}
function _approve(address owner, address spender, uint256 amount) internal {
_allowances[owner][spender] = amount;
emit Approval(owner, spender, amount);
}
}