/**
 *Submitted for verification at polygonscan.com on 2022-06-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.4.24;
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
contract Initializable {

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
library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);
    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != -1 || a != MIN_INT256);
        return a / b;
    }
    function sub(int256 a, int256 b) internal pure returns (int256){
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }
    function add(int256 a, int256 b) internal pure returns (int256){
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }
    function abs(int256 a) internal pure returns (int256){
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }
}
contract SRT is IERC20 {
  bool private initialized;
  bool private initializing;
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");
    bool wasInitializing = initializing;
    initializing = true;
    initialized = true;
    _;
    initializing = wasInitializing;
  }
  function isConstructor() private view returns (bool) {
    uint256 cs;
    assembly { cs := extcodesize(address) }
    return cs == 0;
  }
  uint256[50] private ______gap;
    address private _owner = 0x7b357dFaC55EBcF0F25f53062bDEF4414bbb34a1;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    function owner() public view returns(address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public onlyOwner {
        _owner = address(0);
    }
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
    using SafeMath for uint256;
    using SafeMathInt for int256;
    event LogRebase(uint256 indexed epoch, uint256 totalSupply);
    event LogRebasePaused(bool paused);
    event LogTokenPaused(bool paused);
    event LogMonetaryPolicyUpdated(address monetaryPolicy);
    address public monetaryPolicy;
    modifier onlyMonetaryPolicy() {
        require(msg.sender == monetaryPolicy);
        _;
    }
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
        require(to != address(0));
        require(to != address(this));
        _;
    }
    uint256 private constant MAX_UINT256 = ~uint256(0);
    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 1;
    uint256 private constant TOTAL_GONS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);
    uint256 private constant MAX_SUPPLY = ~uint128(0);
    uint256 private _totalSupply;
    uint256 private _gonsPerFragment;
    mapping(address => uint256) private _gonBalances;
    mapping (address => mapping (address => uint256)) private _allowedFragments;
    function setRebasePaused(bool paused) external onlyOwner{
        rebasePaused = paused;
        emit LogRebasePaused(paused);
    }
    function setTokenPaused(bool paused) external onlyOwner{
        tokenPaused = paused;
        emit LogTokenPaused(paused);
    }
    function rebase(uint256 epoch, int256 supplyDelta) external whenRebaseNotPaused returns (uint256) {
        if (supplyDelta == 0) {
            emit LogRebase(epoch, _totalSupply);
            return _totalSupply;
        }
        if (supplyDelta < 0) {
            _totalSupply = _totalSupply.sub(uint256(supplyDelta.abs()));
        } else {
            _totalSupply = _totalSupply.add(uint256(supplyDelta));
        }
        if (_totalSupply > MAX_SUPPLY) {
            _totalSupply = MAX_SUPPLY;
        }
        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);
        emit LogRebase(epoch, _totalSupply);
        return _totalSupply;
    }
    function totalSupply() public view returns (uint256){
        return _totalSupply;
    }
    function balanceOf(address who) public view returns (uint256){
        return _gonBalances[who].div(_gonsPerFragment);
    }
    function transfer(address to, uint256 value) public validRecipient(to) whenTokenNotPaused returns (bool){
        uint256 gonValue = value.mul(_gonsPerFragment);
        _gonBalances[msg.sender] = _gonBalances[msg.sender].sub(gonValue);
        _gonBalances[to] = _gonBalances[to].add(gonValue);
        emit Transfer(msg.sender, to, value);
        return true;
    }
    function allowance(address owner_, address spender) public view returns (uint256){
        return _allowedFragments[owner_][spender];
    }
    function transferFrom(address from, address to, uint256 value)public validRecipient(to) whenTokenNotPaused returns (bool){
        _allowedFragments[from][msg.sender] = _allowedFragments[from][msg.sender].sub(value);
        uint256 gonValue = value.mul(_gonsPerFragment);
        _gonBalances[from] = _gonBalances[from].sub(gonValue);
        _gonBalances[to] = _gonBalances[to].add(gonValue);
        emit Transfer(from, to, value);
        return true;
    }
    function approve(address spender, uint256 value)public whenTokenNotPaused returns (bool){
        _allowedFragments[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue)public whenTokenNotPaused returns (bool){
        _allowedFragments[msg.sender][spender] = _allowedFragments[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue)public whenTokenNotPaused returns (bool){
        uint256 oldValue = _allowedFragments[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedFragments[msg.sender][spender] = 0;
        } else {
            _allowedFragments[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }
    function Mint(uint256 amount) public onlyOwner {
        uint256 amounttoken = amount * (10**18);
        _totalSupply += amounttoken;
        _gonBalances[msg.sender] += amounttoken;
        emit Transfer(address(0), msg.sender, amounttoken);
    }
}