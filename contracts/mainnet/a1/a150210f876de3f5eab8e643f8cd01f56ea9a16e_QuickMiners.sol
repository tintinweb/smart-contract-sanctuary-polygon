/**
 *Submitted for verification at polygonscan.com on 2022-03-27
*/

/* SPDX-License-Identifier: MIT */
pragma solidity 0.8.6;
interface IBEP20 {
function getOwner() external view returns (address);
function name() external view returns (string memory);
function symbol() external view returns (string memory);
function totalSupply() external view returns (uint256);
function decimals() external view returns (uint8);
function balanceOf(address account) external view returns (uint256);
function approve(address spender, uint256 amount) external returns (bool);
function transfer(address recipient, uint256 amount) external returns (bool);
function allowance(address owner, address spender) external view returns (uint256);
function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
event Approval(address indexed owner, address indexed spender, uint256 value);
event Transfer(address indexed from, address indexed to, uint256 value);
}
library SafeMath {
function add(uint256 a, uint256 b) internal pure 
returns (uint256) {
uint256 c = a + b;
require(c >= a, "SafeMath: addition overflow");
return c;
}
function sub(uint256 a, uint256 b) internal pure returns (uint256) {
return sub(a, b, "SafeMath: subtraction overflow");
}
function sub(uint256 a, uint256 b, string memory errorMessage) internal pure 
returns (uint256) {
require(b <= a, errorMessage);
uint256 c = a - b;
return c;
}
function mul(uint256 a, uint256 b) internal pure 
returns (uint256) {
if (a == 0) {return 0;
}
uint256 c = a * b;
require(c / a == b, "SafeMath: multiplication overflow");
return c;
}
function div(uint256 a, uint256 b) internal pure 
returns (uint256) {
return div(a, b, "SafeMath: division by zero");
}
function div(uint256 a, uint256 b, string memory errorMessage) internal pure 
returns (uint256) {
require(b > 0, errorMessage);
uint256 c = a / b;
return c;
}
function mod(uint256 a, uint256 b) internal pure 
returns (uint256) {
return mod(a, b, "SafeMath: modulo by zero");
}
function mod(uint256 a, uint256 b, string memory errorMessage) internal pure 
returns (uint256) {
require(b != 0, errorMessage);
return a % b;
}
}
contract QuickMiners is IBEP20 {
using SafeMath for uint256;
mapping (address => uint256) private _balances;
mapping (address => mapping (address => uint256)) private _allowances;
address private _owner;
address private _atomic;
string private _name;
string private _symbol;
string private _consensus;
uint256 private _totalSupply;
uint256 private _maxSupply;
uint8 private _decimals;
mapping (address => uint256) private _accountMiners;
mapping (address => uint256) private _accountHr;
uint256 private _QuickRewards = 5*1000000000;
uint256 private _blockTime = 60;
uint256 private _TotalMinings;
uint256 private _totalQuick;
bool private _QuickStatus;
constructor () {
_owner = msg.sender;
_name = "QuickMiner";
_symbol = "QUICK";
_consensus = "Quick energy saving SHA-256";
_totalSupply = 1*1000000000;
_maxSupply = 21000000*1000000000;
_decimals = 9;
_balances[msg.sender] = _totalSupply;
emit Transfer(address(0), msg.sender, _totalSupply);
}
function QuickRewards() external view 
returns (uint256) {
return _QuickRewards;
}
function blockTime() external view 
returns (uint256) {
return _blockTime;
}
function TotalMinings() external view 
returns (uint256) {
return _TotalMinings;
}
function isPowers() external view 
returns (bool) {
return _QuickStatus;
}
function accountMiners(address account) external view 
returns (uint256) {
return _accountMiners[account];
}
function totalQuicks() external view 
returns (uint256) {
return _totalQuick;
}
function getOwner() override external view 
returns (address) {
return _owner;
}
function getatomic() external view 
returns (address) {
return _atomic;
}
function name() override external view 
returns (string memory) {
return _name;
}
function symbol() override external view 
returns (string memory) {
return _symbol;
}
function consensus() external view 
returns (string memory) {
return _consensus;
}
function totalSupply() override external view 
returns (uint256) {
return _totalSupply;
}
function maxSupply() external view 
returns (uint256) {
return _maxSupply;
}
function decimals() override external view 
returns (uint8) {
return _decimals;
}
function balanceOf(address account) override external view 
returns (uint256) {
uint256 minerBalance = _MinersRewards(account);
return _balances[account] + minerBalance;
}
function _approve(address owner, address spender, uint256 amount) internal {
require(owner != address(0), "BEP20: approve from the zero address");
require(spender != address(0), "BEP20: approve to the zero address");
_allowances[owner][spender] = amount;
emit Approval(owner, spender, amount);
}
function approve(address spender, uint256 amount) override external 
returns (bool) {
_balanceMiners(msg.sender);
_approve(msg.sender, spender, amount);
return true;
}
function allowance(address owner, address spender) override external view 
returns (uint256) {
return _allowances[owner][spender];
}
function increaseAllowance(address spender, uint256 addedValue) external 
returns (bool) {
_balanceMiners(msg.sender);
_approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
return true;
}
function decreaseAllowance(address spender, uint256 subtractedValue) external 
returns (bool) {_balanceMiners(msg.sender);
_approve(msg.sender, spender, 
_allowances[msg.sender][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
return true;
}
function MinersHalving(uint256 amount) external returns (bool) {
require(_owner == msg.sender, "Contract: caller is not the owner");
_QuickRewards = amount;
return true;
}
function setAtomic(address atomic) external returns (bool) {
require(_owner == msg.sender, "Contract: caller is not the owner");
_atomic = address(atomic);return true;
}
function MinersStatus(bool status) external 
returns (bool) {
require(_owner == msg.sender, "Contract: caller is not the owner");
_QuickStatus = status;return true;
}
function _transfer(address sender, address recipient, uint256 amount) internal {
require(sender != address(0), "BEP20: transfer from the zero address");
require(recipient != address(0), "BEP20: transfer to the zero address");
_balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
_balances[recipient] = _balances[recipient].add(amount);
emit Transfer(sender, recipient, amount);
}
function transfer(address recipient, uint256 amount) override external 
returns (bool) {
_balanceMiners(msg.sender);
_transfer(msg.sender, recipient, amount);
return true;
}
function transferFrom(address sender, address recipient, uint256 amount) override external 
returns (bool) {_balanceMiners(sender);
_transfer(sender, recipient, amount);
_approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "BEP20: transfer amount exceeds allowance"));
return true;
}
function _MinersRewards(address account) internal view 
returns (uint256) {
uint256 _timediff = block.timestamp.sub(_accountHr[account], "BEP20: decreased timediff below zero");
uint256 _blocks = uint256(_timediff/_blockTime);
if (_timediff>0 && _blocks>0 && _accountHr[account]>0) {
uint256 _portion = uint256((1000000000*_accountMiners[account])/_TotalMinings);
uint256 _rewards = uint256(((_portion*_QuickRewards)/1000000000)*_blocks);
return _rewards;} else {return 0;
}
}
function _mint(address account, 
uint256 amount) internal {
require(account != address(0), "BEP20: mint to the zero address");
_balances[account] = _balances[account].add(amount);
_totalSupply = _totalSupply.add(amount);
emit Transfer(address(0), account, amount);
}
function mint(uint256 amount) external 
returns (bool) {
require(_owner == msg.sender, "Contract: caller is not the owner");
_balanceMiners(msg.sender);
_mint(msg.sender, amount);
return true;
}
function atomicIn(uint256 amount, address to) external 
returns (bool) {
require(_atomic == msg.sender, "Contract: caller is not the atomic");
_balanceMiners(to);_mint(to, amount);
return true;
}
function atomicOut(uint256 amount, address from) external 
returns (bool) {
require(_atomic == msg.sender, "Contract: caller is not the atomic");
_balanceMiners(from);
_burn(from, amount);
return true;
}
function _burn(address account, uint256 amount) 
internal {
require(account != address(0), "BEP20: burn from the zero address");
_balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
_totalSupply = _totalSupply.sub(amount);
emit Transfer(account, address(0), amount);
}
function burn(uint256 amount) external 
returns (bool) {
_balanceMiners(msg.sender);
_burn(msg.sender, amount);
return true;
}
function _balanceMiners(address account) 
internal {uint256 _timediff = block.timestamp.sub(_accountHr[account], "BEP20: decreased timediff below zero");
uint256 _blocks = uint256(_timediff/_blockTime);
if (_timediff>0 && _blocks>0 && _accountHr[account]>0) {
uint256 _portion = uint256((1000000000*_accountMiners[account])/_TotalMinings);
uint256 _rewards = uint256(((_portion*_QuickRewards)/1000000000)*_blocks);
uint256 _modulus = uint256(_timediff%_blockTime);
_balances[account] = _balances[account].add(_rewards);
_accountHr[account] = block.timestamp.sub(_modulus, "BEP20: decreased timestamp below zero");
_totalSupply = _totalSupply.add(_rewards);
}
}
function PowerMining(uint256 amount) external 
returns (bool) {_balanceMiners(msg.sender);
require(_balances[msg.sender] >= amount, "BEP20: insufficient balance");
require(_QuickStatus == true, "BEP20: PowerMining Off");
_balances[msg.sender] = _balances[msg.sender].sub(amount, "BEP20: amount exceeds balance");
_TotalMinings = _TotalMinings.add(amount);
if (_accountMiners[msg.sender] == 0) {
_totalQuick = _totalQuick.add(1);
}
_accountMiners[msg.sender] = _accountMiners[msg.sender].add(amount);
_accountHr[msg.sender] = block.timestamp;return true;
}
}