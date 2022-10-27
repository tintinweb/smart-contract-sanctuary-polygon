/**
 *Submitted for verification at polygonscan.com on 2022-10-26
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; 
        return msg.data;
    }
}

library Address {
    
    function isContract(address account) internal view returns (bool) {
        
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

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

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = now + time;
        emit OwnershipTransferred(_previousOwner, address(0));
    }

    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(now > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
        _lockTime = 0;
    }
}
interface CrazyGamesToken {
    function transfer(address _to, uint256 _value) external;
}

contract CrazyGames is Context, IERC20, Ownable{
    using SafeMath for uint256;
    using Address for address;

    string public name;
    string public symbol;
    uint8   public decimals;
    uint256 public _totalSupply;


    mapping (address => uint256) private _balanceOf;
    mapping (address => mapping (address => uint256)) private _allowance;
    mapping (address => bool) public blacklist;
    mapping (address => bool) private _isExcludedFromFee;
    uint256 public _taxFee = 20;
    address public operatingWallet = 0x93E6738A7288caAf07622B6328a81a6D5c257020;
    address public marketingWallet ;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event SetBlacklist(address user,bool isBlacklist);

    constructor () public{
        _balanceOf[msg.sender] = 10000000000000000000;           
        _totalSupply =  1000000000000000000;                   
        name = 'CrazyGames';                                 
        symbol = 'CGS';                                   
        decimals = 8;                                     
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        emit Transfer(0x0000000000000000000000000000000000000000, msg.sender, _totalSupply);
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balanceOf[account];
    }
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowance[owner][spender];
    }

    function setMarketingWallet(address account) public onlyOwner() {
        marketingWallet = account;
    }

    function excludeFromFee(address account) public onlyOwner() {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner() {
        _isExcludedFromFee[account] = false;
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function transfer(address _to, uint256 _value) public override returns (bool success){
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public override returns (bool success) {
        _allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success) {
        require (_value <= _allowance[_from][msg.sender]) ;     
        _transfer(_from, _to, _value);
        _allowance[_from][msg.sender] = _allowance[_from][msg.sender].sub(_value);
        return true;
    }

    function _transfer(address _from, address _to, uint256 _value) private {
        require (_to != address(0x0) && !blacklist[_from]) ;                               
        require (_value >= 0) ;
        require (_balanceOf[_from] >= _value) ;                
        uint256 realValue = _value;
        if(_isExcludedFromFee[_from]){
            _balanceOf[_to] = _balanceOf[_to].add(_value);                             
        }else{
            uint256 feeValue = _value.mul(_taxFee).div(200);
            _balanceOf[operatingWallet] = _balanceOf[operatingWallet].add(feeValue);
            _balanceOf[marketingWallet] = _balanceOf[marketingWallet].add(feeValue);
            realValue = _value.sub(feeValue).sub(feeValue);
            _balanceOf[_to] = _balanceOf[_to].add(realValue);
            emit Transfer(_from, operatingWallet, feeValue);
            emit Transfer(_from, marketingWallet, feeValue);
        }
        _balanceOf[_from] = _balanceOf[_from].sub(_value);                          
        emit Transfer(_from, _to, realValue);
    }

    function burn(uint256 _value) public returns (bool success) {
        require (_balanceOf[msg.sender] >= _value) ;           
        require (_value > 0) ;
        _balanceOf[msg.sender] = _balanceOf[msg.sender].sub(_value);            
        _totalSupply = _totalSupply.sub(_value);                              
        emit Burn(msg.sender, _value);
        emit Transfer(msg.sender, address(0), _value);
        return true;
    }

    function setBlacklist(address _user,bool _isBlacklist) external onlyOwner(){
        blacklist[_user] = _isBlacklist;
        emit SetBlacklist(_user,_isBlacklist);
    }

    // transfer balance to owner
    function withdrawToken(address token, uint amount,address payable  toAdd) external onlyOwner(){
        if (token == address(0x0))
            toAdd.transfer(amount);
        else
            CrazyGamesToken(token).transfer(toAdd, amount);
    }

receive() external payable {}
}