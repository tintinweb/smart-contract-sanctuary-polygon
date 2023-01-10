/**
 *Submitted for verification at polygonscan.com on 2023-01-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; 
        return msg.data;
    }
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
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

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
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
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner {
        require(isOwner(msg.sender));
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) internal onlyOwner {
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function isOwner(address addr) public view returns (bool) {
        return owner == addr;
    }
}

contract PredictPrice is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;    
 
    struct Order{
        uint256 orderId;
        address user;        
        address token;
        uint256 triggerTime;
        uint256 predictTime;
        uint256 amount;        
        uint256 totalFee;
        string detail;
        uint256 odds;
        address receiver;
        uint256 otherFee;
        uint256 timestamp;
    }
    Order[] public _orderList;
    mapping (uint256 => uint256) public _orderIndexes; //user/orderid/listIndex
    uint256 public _allCount = 0;
    address[] private _deputyList;

    event Predicted(uint256 orderId, address user, address token, uint256 triggerTime, uint256 predictTime, uint256 amount, uint256 totalFee, string detail, uint256 odds, address receiver, uint256 otherFee, uint256 timestamp);
    event Withdrawn(address sender, address to, uint256 amount);

	constructor(){
		transferOwnership(msg.sender);
	}

    function predictPrice(uint256 orderId, address token, uint256 triggerTime, uint256 predictTime, uint256 amount, uint256 totalFee, string memory detail, uint256 odds, address receiver, uint256 otherFee) public {
        require(_orderIndexes[orderId] == 0, "order exist");
        require(predictTime > triggerTime, "predictTime too small");
        require(triggerTime > block.timestamp - 300, "trigger time wrong.");
        require(amount > 0, "amount too small");
        require(totalFee > 0, "totalFee too small");

        uint256 balance = IERC20(token).balanceOf(msg.sender);
        require(balance >= totalFee, "insufficient balance.");
        IERC20(token).safeTransferFrom(msg.sender, address(this), totalFee);
        if(otherFee > 0){
            require(totalFee > otherFee, "totalFee less than otherFee.");
            IERC20(token).safeTransfer(receiver, otherFee);
        }

        _orderList.push(Order(orderId, msg.sender, token, triggerTime, predictTime, amount, totalFee, detail, odds, receiver, otherFee, block.timestamp));
        uint256 id = _orderList.length;
        _orderIndexes[orderId] = id;
        _allCount ++;
        emit Predicted(orderId, msg.sender, token, triggerTime, predictTime, amount, totalFee, detail, odds, receiver, otherFee, block.timestamp);
    }

    function predictPriceMatic(uint256 orderId, uint256 triggerTime, uint256 predictTime, uint256 amount, uint256 totalFee, string memory detail, uint256 odds, address receiver, uint256 otherFee) public payable {
        require(_orderIndexes[orderId] == 0, "order exist");
        require(predictTime > triggerTime, "predictTime too small");
        require(triggerTime > block.timestamp - 300, "trigger time wrong.");
        require(amount > 0, "amount too small");
        require(totalFee > 0, "totalFee too small");
        require(msg.value >= totalFee, "Insufficient matic.");

        if(otherFee > 0){
            require(totalFee > otherFee, "totalFee less than otherFee.");
            payable(receiver).transfer(otherFee);
        }

        _orderList.push(Order(orderId, msg.sender, address(0), triggerTime, predictTime, amount, totalFee, detail, odds, receiver, otherFee, block.timestamp));
        uint256 id = _orderList.length;
        _orderIndexes[orderId] = id;
        _allCount ++;
        emit Predicted(orderId, msg.sender, address(0), triggerTime, predictTime, amount, totalFee, detail, odds, receiver, otherFee, block.timestamp);
    }
    
    function getPredictInfo(uint256 orderId) public view returns(Order memory) {
        require(_orderIndexes[orderId] > 0, "order not exist");
        return _orderList[_orderIndexes[orderId] - 1];
    }
    
    function withdraw(address token, address to) public {
        require(isDeputy(msg.sender), "Only deputy can do this");
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(to, balance);
        emit Withdrawn(msg.sender, to, balance);
    }

    function withdrawMatic(address to) public payable {
        require(isDeputy(msg.sender), "Only deputy can do this");
        payable(to).transfer(address(this).balance);
        emit Withdrawn(msg.sender, to, address(this).balance);
    }

    function setDeputy(address deputy_) public onlyOwner{
        uint256 i = 0;
        bool isFind = false;
        for(; i < _deputyList.length; i++){
          if(_deputyList[i] == deputy_){
              isFind = true;
              break;
          }
        }
        require(!isFind, "this duputy already exist");        

        i = 0;
        isFind = false;
        for(; i < _deputyList.length; i++){
          if(_deputyList[i] == address(0)){
              isFind = true;
              break;
          }
        }
        if(isFind){
            _deputyList[i] = deputy_;
        }else{
            _deputyList.push(deputy_);
        }
    }
    
    function getAllDeputy() public view returns(address[] memory){
        return _deputyList;
    }

    function isDeputy(address deputy_) public view returns (bool) {
        bool isFind = false;
        for(uint i = 0; i< _deputyList.length; i++){
          if(_deputyList[i] == deputy_){
              isFind = true;
              break;
          }
        }
        return isFind;
    }

    function removeDeputy(address deputy_) public onlyOwner{
        uint256 i = 0;
        bool isFind = false;
        for(; i < _deputyList.length; i++){
          if(_deputyList[i] == deputy_){
              isFind = true;
              break;
          }
        }
        if(isFind){
            delete _deputyList[i];
        }
    }
}