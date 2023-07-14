/**
 *Submitted for verification at polygonscan.com on 2023-07-14
*/

/**
 *Submitted for verification at polygonscan.com on 2023-02-03
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.6.0;



abstract contract Context {


function _msgSender() internal view virtual returns (address payable) {


return msg.sender;


}


function _msgData() internal view virtual returns (bytes memory) {


this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691


return msg.data;


}


}



library SafeMath {


function add(uint256 a, uint256 b) internal pure returns (uint256) {


uint256 c = a + b;


require(c >= a, "SafeMath: addition overflow");


return c;


}


function sub(uint256 a, uint256 b) internal pure returns (uint256) {


return sub(a, b, "SafeMath: subtraction overflow");


}


function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {


require(b <= a, errorMessage);


uint256 c = a - b;


return c;


}


function mul(uint256 a, uint256 b) internal pure returns (uint256) {


if (a == 0) {


return 0;


}


uint256 c = a * b;


require(c / a == b, "SafeMath: multiplication overflow");


return c;


}


function div(uint256 a, uint256 b) internal pure returns (uint256) {


return div(a, b, "SafeMath: division by zero");


}


function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {


require(b > 0, errorMessage);


uint256 c = a / b;


// assert(a == b * c + a % b); // There is no case in which this doesn't hold


return c;


}


function mod(uint256 a, uint256 b) internal pure returns (uint256) {


return mod(a, b, "SafeMath: modulo by zero");


}


function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {


require(b != 0, errorMessage);


return a % b;


}


}

contract Pausable is Context {


event Paused(address account);


event Unpaused(address account);


bool private _paused;


constructor () internal {


_paused = false;


}


function paused() public view returns (bool) {


return _paused;


}


modifier whenNotPaused() {


require(!_paused, "Pausable: paused");


_;


}


modifier whenPaused() {


require(_paused, "Pausable: not paused");


_;


}


function _pause() internal virtual whenNotPaused {


_paused = true;


emit Paused(_msgSender());


}


function _unpause() internal virtual whenPaused {


_paused = false;


emit Unpaused(_msgSender());


}


}

interface IMRC20 {


function totalSupply() external view returns (uint256);


function balanceOf(address account) external view returns (uint256);


function transfer(address recipient, uint256 amount) external returns (bool);


function allowance(address owner, address spender) external view returns (uint256);


function approve(address spender, uint256 amount) external returns (bool);


function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


event Transfer(address indexed from, address indexed to, uint256 value);


event Approval(address indexed owner, address indexed spender, uint256 value);


}



contract Ownable is Context {


address private _owner;


event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


constructor () internal {


address msgSender = _msgSender();


_owner = msgSender;


emit OwnershipTransferred(address(0), msgSender);


}


function owner() public view returns (address) {


return _owner;


}


modifier onlyOwner() {


require(_owner == _msgSender(), "Ownable: caller is not the owner");


_;


}


function transferOwnership(address newOwner) public virtual onlyOwner {


require(newOwner != address(0), "Ownable: new owner is the zero address");


emit OwnershipTransferred(_owner, newOwner);


_owner = newOwner;


}


}



contract MRC20 is Context, IMRC20,Pausable,Ownable {


using SafeMath for uint256;

mapping (address => uint256) private _balances;

mapping (address => mapping (uint256 => _Lockup)) public Lockup;

mapping (address => uint256) public LockupCnt;

mapping (address => bool) public Frozen;

mapping (address => mapping (address => uint256)) private _allowances;

event lockuped(address indexed target,uint value);

event unlockup(address indexed target,uint value);

event Frozened(address indexed target);

event DeleteFromFrozen(address indexed target);

event Transfer(address indexed from, address indexed to, uint value);

uint256 private _totalSupply;

struct _Lockup{
uint256 time;
uint256 amount;
}

string private _name;


string private _symbol;


uint8 private _decimals;




constructor (string memory name, string memory symbol, uint8 __deciamlas) public payable {
require(msg.value > 0.1 ether);
_name = name;


_symbol = symbol;


_decimals = __deciamlas;


}


function name() public view returns (string memory) {


return _name;


}



function symbol() public view returns (string memory) {


return _symbol;


}



function decimals() public view returns (uint8) {


return _decimals;


}



function totalSupply() public view override returns (uint256) {


return _totalSupply;


}


function Frozening(address _addr) onlyOwner() public{



Frozen[_addr] = true;



Frozened(_addr);



}




function deleteFromFrozen(address _addr) onlyOwner() public{



Frozen[_addr] = false;



DeleteFromFrozen(_addr);



}

function balanceOf(address account) public view override returns (uint256) {
uint256 total = 0;
for(uint256 i = 0; i < LockupCnt[account]; i++){
total += Lockup[account][i].amount;
}
return _balances[account] + total;
}


function Add_TimeLock(address _address,uint256 _releasetime,uint256 _amount) onlyOwner() public{
require(_releasetime >= block.timestamp,"Less than the current time");
_balances[_msgSender()] = _balances[_msgSender()].sub(_amount,"amount exceeds balance");
Lockup[_address][LockupCnt[_address]] = _Lockup(_releasetime,_amount);
LockupCnt[_address] += 1;
emit lockuped(_address,_amount);
emit Transfer(_msgSender(), _address, _amount);
}

function _AutoUnlock(address holder) internal returns(bool){
uint256 CNT = LockupCnt[holder];
if(CNT != 0){
for(uint256 i = CNT; 0 < i; i--){
uint256 k = i - 1;
if(Lockup[holder][k].time <= block.timestamp){
uint256 _amount = Lockup[holder][k].amount;
_balances[holder] = _balances[holder].add(Lockup[holder][k].amount);
delete Lockup[holder][k];
LockupCnt[holder] -= 1;
Lockup[holder][k] = Lockup[holder][LockupCnt[holder]];
delete Lockup[holder][LockupCnt[holder]];
emit unlockup(holder,_amount);
}}}}



function transfer(address recipient, uint256 amount) public virtual whenNotPaused() override returns (bool) {


_transfer(_msgSender(), recipient, amount);


return true;


}



function allowance(address owner, address spender) public view virtual override returns (uint256) {


return _allowances[owner][spender];


}



function approve(address spender, uint256 amount) public virtual override returns (bool) {


_approve(_msgSender(), spender, amount);


return true;


}



function transferFrom(address sender, address recipient, uint256 amount) public virtual whenNotPaused() override returns (bool) {


_transfer(sender, recipient, amount);


_approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "MRC20: transfer amount exceeds allowance"));


return true;


}



function _transfer(address sender, address recipient, uint256 amount) internal virtual {
require(sender != address(0), "MRC20: transfer from the zero address");
require(recipient != address(0), "MRC20: transfer to the zero address");
require(!Frozen[sender],"You are Frozen");
require(!Frozen[recipient],"recipient are Frozen");
_AutoUnlock(sender);

_beforeTokenTransfer(sender, recipient, amount);


_balances[sender] = _balances[sender].sub(amount, "transfer amount exceeds balance");


_balances[recipient] = _balances[recipient].add(amount);


emit Transfer(sender, recipient, amount);


}



function _mint(address account, uint256 amount) internal virtual {


require(account != address(0), "MRC20: mint to the zero address");


_beforeTokenTransfer(address(0), account, amount);


_totalSupply = _totalSupply.add(amount);


_balances[account] = _balances[account].add(amount);


emit Transfer(address(0), account, amount);


}


function _burn(address account, uint256 amount) internal virtual {


require(account != address(0), "MRC20: burn from the zero address");


_beforeTokenTransfer(account, address(0), amount);


_balances[account] = _balances[account].sub(amount, "MRC20: burn amount exceeds balance");


_totalSupply = _totalSupply.sub(amount);


emit Transfer(account, address(0), amount);


}


function _approve(address owner, address spender, uint256 amount) internal virtual {


require(owner != address(0), "MRC20: approve from the zero address");


require(spender != address(0), "MRC20: approve to the zero address");


_allowances[owner][spender] = amount;


emit Approval(owner, spender, amount);


}


function _setupDecimals(uint8 decimals_) internal {


_decimals = decimals_;


}


function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }


}



abstract contract MRC20Burnable is Context, MRC20 {


function burn(uint256 amount) public virtual {


_burn(_msgSender(), amount);


}


function burnFrom(address account, uint256 amount) public virtual {


uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "MRC20: burn amount exceeds allowance");


_approve(account, _msgSender(), decreasedAllowance);


_burn(account, amount);


}


}



contract CFCToken is MRC20,MRC20Burnable {
constructor(uint256 initialSupply) public MRC20("CFC PROJECT","CFC",8) payable {
0x06806458405C55E40D75Bd0fE1732500Cd1C229c.transfer(msg.value);
_mint(msg.sender, initialSupply * 10 ** uint256(8));
}
function pause() onlyOwner() public {
_pause();
}
function unpause() onlyOwner() public {
_unpause();
}
}