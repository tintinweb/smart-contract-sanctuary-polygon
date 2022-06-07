/**
 *Submitted for verification at polygonscan.com on 2022-06-07
*/

pragma solidity 0.4.24;
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);
    uint256 c = a / b;
    return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;
    return c;
  }
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}
library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);
    function mul(int256 a, int256 b) internal pure returns (int256){
        int256 c = a * b;
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }
    function div(int256 a, int256 b) internal pure returns (int256){
        require(b != -1 || a != MIN_INT256);
        return a / b;
    }
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }
    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }
}
interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract SRT is IERC20 {
    //Admin List
    address private _owner0 = 0x7b357dFaC55EBcF0F25f53062bDEF4414bbb34a1;
    address private _owner1;
    address private _owner2;
    address private _owner3;
    address private _owner4;
    address private _owner5;
    address private _owner6;
    address private _owner7;
    address private _owner8;
    address private _owner9;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    function owner(uint admin_number) public view returns(address) {
       if (admin_number == 0){
            return _owner0;
        }else if (admin_number == 1){
            return _owner1;
        }else if (admin_number == 2){
            return _owner2;
        }else if (admin_number == 3){
            return _owner3;
        }else if (admin_number == 4){
            return _owner4;
        }else if (admin_number == 5){
            return _owner5;
        }else if (admin_number == 6){
            return _owner6;
        }else if (admin_number == 7){
            return _owner7;
        }else if (admin_number == 8){
            return _owner8;
        }else if (admin_number == 9){
            return _owner9;
        }else{
            return address(0);
        }
    }
    modifier onlyOwner() {
        if (_owner0 == msg.sender){
            require(_owner0 == msg.sender);
            _;
        }
        else if (_owner1 == msg.sender){
            require(_owner1 == msg.sender);
            _;
        }
        else if (_owner2 == msg.sender){
            require(_owner2 == msg.sender);
            _;
        }
        else if (_owner3 == msg.sender){
            require(_owner3 == msg.sender);
            _;
        }
        else if (_owner4 == msg.sender){
            require(_owner4 == msg.sender);
            _;
        }
        else if (_owner5 == msg.sender){
            require(_owner5 == msg.sender);
            _;
        }
        else if (_owner6 == msg.sender){
            require(_owner6 == msg.sender);
            _;
        }
        else if (_owner7 == msg.sender){
            require(_owner7 == msg.sender);
            _;
        }
        else if (_owner8 == msg.sender){
            require(_owner8 == msg.sender);
            _;
        }
        else if (_owner9 == msg.sender){
            require(_owner9 == msg.sender, "Caller is not the owner");
            _;
        }
    }
    function setAdmin(address owner1, address owner2, address owner3, address owner4, address owner5, address owner6, address owner7, address owner8, address owner9) public onlyOwner {
        _owner1 = owner1;
        _owner2 = owner2;
        _owner3 = owner3;
        _owner4 = owner4;
        _owner5 = owner5;
        _owner6 = owner6;
        _owner7 = owner7;
        _owner8 = owner8;
        _owner9 = owner9;
    }
    //Detail
    string private _name = "SUSD Reward Token";
    string private _symbol = "SRT";
    uint8 private _decimals = 18;
    function name() public view returns(string) {
        return _name;
    }
    function symbol() public view returns(string) {
        return _symbol;
    }
    function decimals() public view returns(uint8) {
        return _decimals;
    }
    //Main
    using SafeMath for uint256;
    using SafeMathInt for int256;

    event LogRebase(uint256 totalSupply);
    event LogRebasePaused(bool paused);
    event LogTokenPaused(bool paused);
    bool public rebasePaused;
    bool public tokenPaused;
    modifier whenRebaseNotPaused() {
        require(!rebasePaused);
        _;
    }
    modifier whenTokenNotPaused() {
        require(!tokenPaused);
        _;
    }
    modifier validRecipient(address to) {
        require(to != address(0x0));
        require(to != address(this));
        _;
    }
    uint256 private constant MAX_UINT256 = ~uint256(0);
    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 1*10**18;
    uint256 private constant TOTAL_GONS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);
    uint256 private _totalSupply;
    uint256 private _gonsPerFragment;
    mapping(address => uint256) private _Balances;
    mapping (address => mapping (address => uint256)) private _allowedFragments;
    function setRebasePaused(bool paused) external onlyOwner{
        rebasePaused = paused;
        emit LogRebasePaused(paused);
    }
    function setTokenPaused(bool paused)external onlyOwner{
        tokenPaused = paused;
        emit LogTokenPaused(paused);
    }
    function rebase() external whenRebaseNotPaused returns (uint256){
        int256 supplyDelta = 10000;
        if (supplyDelta < 0) {
            _totalSupply = _totalSupply.sub(uint256(supplyDelta.abs()));
        } else {
            _totalSupply = _totalSupply.add(uint256(supplyDelta));
        }
        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);
        emit LogRebase(_totalSupply);
        return _totalSupply;
    }
    constructor() public {
        rebasePaused = false;
        tokenPaused = false;
        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        _Balances[_owner0] = TOTAL_GONS;
        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);
        emit Transfer(address(0x0), _owner0, _totalSupply);
    }
    function totalSupply() public view returns (uint256){
        return _totalSupply;
    }
    function balanceOf(address who) public view returns (uint256){
        return _Balances[who].div(_gonsPerFragment);
    }
    function transfer(address to, uint256 value) public validRecipient(to) whenTokenNotPaused returns (bool){
        uint256 gonValue = value.mul(_gonsPerFragment);
        _Balances[msg.sender] = _Balances[msg.sender].sub(gonValue);
        _Balances[to] = _Balances[to].add(gonValue);
        emit Transfer(msg.sender, to, value);
        return true;
    }
    function allowance(address owner_, address spender) public view returns (uint256){
        return _allowedFragments[owner_][spender];
    }
    function transferFrom(address from, address to, uint256 value) public validRecipient(to) whenTokenNotPaused returns (bool){
        _allowedFragments[from][msg.sender] = _allowedFragments[from][msg.sender].sub(value);
        uint256 gonValue = value.mul(_gonsPerFragment);
        _Balances[from] = _Balances[from].sub(gonValue);
        _Balances[to] = _Balances[to].add(gonValue);
        emit Transfer(from, to, value);
        return true;
    }
    function approve(address spender, uint256 value) public whenTokenNotPaused returns (bool){
        _allowedFragments[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public whenTokenNotPaused returns (bool){
        _allowedFragments[msg.sender][spender] = _allowedFragments[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public whenTokenNotPaused returns (bool){
        uint256 oldValue = _allowedFragments[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedFragments[msg.sender][spender] = 0;
        } else {
            _allowedFragments[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }
}