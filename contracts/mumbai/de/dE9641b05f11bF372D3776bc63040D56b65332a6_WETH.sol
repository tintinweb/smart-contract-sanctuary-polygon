/**
 *Submitted for verification at polygonscan.com on 2022-04-15
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-08
*/

pragma solidity ^0.4.25;
// ERC20 interface
interface IERC20 {
  function balanceOf(address _owner) external view returns (uint256);
  function allowance(address _owner, address _spender) external view returns (uint256);
  function transfer(address _to, uint256 _value) external returns (bool);
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
  function approve(address _spender, uint256 _value) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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

contract WETH is IERC20 {
  address implementation;
  using SafeMath for uint256;
  address private owner;
  string public name;
  string public symbol;
  uint8 public  decimals;
  uint256 public  rate = 1000000;
  uint256 public  totalSupply;
  mapping (address => uint256) balances;
  mapping (address => mapping (address => uint256)) internal allowed;
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  
  constructor(uint256 initialSupply, string tokenName, string tokenSymbol) public {
    decimals = 18;
    totalSupply = initialSupply * 10 ** uint256(decimals);                
    name = tokenName;                                  
    symbol = tokenSymbol;      
    balances[msg.sender] = totalSupply;
    emit Transfer(address(0), msg.sender, totalSupply);
  }
  
  function init(uint256 initialSupply, string tokenName, string tokenSymbol) public {
    decimals = 18;
    totalSupply = initialSupply * 10 ** uint256(decimals);                
    name = tokenName;                                  
    symbol = tokenSymbol;      
    balances[msg.sender] = totalSupply;
    emit Transfer(address(0), msg.sender, totalSupply);
  }

    modifier onlyOwner {
        if (msg.sender != owner) revert();
        _;
    }
   function() external payable {
    }
    function withdraw() onlyOwner public {
        uint256 etherBalance = address(this).balance;
        owner.transfer(etherBalance);
    }
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }
  
  function modifierRate(uint256 _value) public {
    rate = _value;
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
   
    require(_value <= balances[msg.sender]);
    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }
  
  function lucaToFragment(uint256 value) external view returns (uint256){
      return value * rate;
  }
  
  function fragmentToLuca(uint256 value) external view returns (uint256){
      return value / rate;
  }
  
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
}