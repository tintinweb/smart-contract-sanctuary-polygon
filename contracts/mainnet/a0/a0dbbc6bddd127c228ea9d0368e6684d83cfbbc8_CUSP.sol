/**
 *Submitted for verification at polygonscan.com on 2022-03-22
*/

// SPDX-License-Identifier: GPL-3.0
/**
 *Submitted for verification at Etherscan.io on 2018-04-06
*/
pragma solidity 0.8.7;
/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
interface ERC20Basic {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
/**
 * @title CUSP token
 * @dev Basic version of CUSP, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;
  mapping(address => uint256) balances;
  uint256 totalSupply_ = 0;
  function totalSupply() public override view returns (uint256) {
    return totalSupply_.sub(balances[address(0)]);
  }
  function transfer(address _to, uint256 _value) public override returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }
  function balanceOf(address _owner) public override view returns (uint256 ) {
    return balances[_owner];
  }
}
library SafeMath {
  /**
   * @dev Multiplies two numbers, throws on overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }
  /**
   * @dev Integer division of two numbers, truncating the quotient.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }
  /**
   * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  /**
   * @dev Adds two numbers, throws on overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface ERC20 is ERC20Basic {
  function allowance(address owner, address spender) external view returns (uint256);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract CUSP is ERC20, BasicToken {
  using SafeMath for uint256;
  // Name of the token
  string constant public name = "CUSP";
  // Token abbreviation
  string constant public symbol = "CUSP";
  // Decimal places
  uint8 constant public decimals = 18;
  // Zeros after the point
  uint256 constant public DECIMAL_ZEROS = 1000000000000000000;
  uint256 constant max_supply = 1000000000000000000000000000;
                                
  mapping (address => mapping (address => uint256)) internal allowed;
  address[] public treasury;
  address public owner;
  event LogChangeAccount(address _from,address _to);
  event LogAddTreasury(address _from);

  uint256[] private schedule_d = [20,19,18,17,16,15,14,13,12,11];
  uint256 schedule_n = 10;
 
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            emit LogChangeAccount(owner,newOwner);
            owner = newOwner;
        }
       

    }
  constructor(address _owner)  {
    require(_owner != address(0));
    owner = _owner;
  }

  function divider(
        uint256 numerator,
        uint256 denominator,
        uint256 precision
    ) public pure returns (uint256) {
        uint256 val =  (numerator * (uint256(10)**uint256(precision))) / denominator;
        // val = val.div(1000);
        return val;
    }
  
  function mint(address _address, uint256 _value,uint256 depreciation_index) public onlyOwner returns (bool)  {
    require(_address != address(0),"Not a valid address");
    require(depreciation_index >=0,"Depreciation Index not in range");
    require(depreciation_index<10, "Depreciation Index not in range"); 
    
    
    uint256 _scheduledValue = divider(schedule_d[depreciation_index],schedule_n,3).mul(_value).div(1000);

    totalSupply_ = totalSupply_.add(_scheduledValue);
    require(totalSupply_ < max_supply);
    balances[_address] = balances[_address].add(_scheduledValue);
    
    emit Transfer(address(0), _address, _scheduledValue);
    return true;
  }
  function multiMint(address[] memory _address, uint256[] memory _value, uint _index, uint256 _treasuryValue,uint256 depreciation_index ) public onlyOwner returns (bool )  {
    require(_address.length == _value.length);
    require(_address.length <= 20);
    require(treasury.length > _index, "Treasury Index is not correct");
    require(depreciation_index >=0,"Depreciation Index not in range");
    require(depreciation_index<10, "Depreciation Index not in range"); 

        // divider(schedule_d[depreciation_index],schedule_n,3).mul(_value).div(1000);
    uint256  _scheduledFactor  = divider(schedule_d[depreciation_index],schedule_n,3);
    uint256  _scheduledValue =0;
    for(uint i=0;i<_address.length;i++){
        require(_address[i] !=address(0),"Not a valid address");
        
        _scheduledValue = _value[i].mul(_scheduledFactor).div(1000);

        totalSupply_ = totalSupply_.add(_scheduledValue);
        require(totalSupply_ < max_supply);
        balances[_address[i]] = balances[_address[i]].add(_scheduledValue);
        emit Transfer(address(0), _address[i], _scheduledValue);
    }
    uint256 _finalTreasuryValue = _treasuryValue.mul(_scheduledFactor).div(1000);
    totalSupply_ = totalSupply_.add(_finalTreasuryValue);
    require(totalSupply_ < max_supply);

    balances[treasury[_index]] = balances[treasury[_index]].add(_finalTreasuryValue);
    emit Transfer(address(0), treasury[_index], _finalTreasuryValue);
    return true;
  }
  function addTreasuryAddress(address _address) public onlyOwner returns (bool)  {
    for(uint i=0;i<treasury.length;i++){
        if (treasury[i]==_address) return false;
    }
    treasury.push(_address);
    emit LogAddTreasury(_address);
    return true;
  }
  function getTreasuryList() public  view returns (address[] memory) {
    return treasury;
  }
  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public override returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }
  function approve(address _spender, uint256 _value) public override returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }
  function allowance(address _owner, address _spender) public override view returns (uint256) {
    return allowed[_owner][_spender];
  }
  function increaseApproval(address _spender, uint _addedValue) public  returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
  function decreaseApproval(address _spender, uint _subtractedValue) public  returns (bool) {
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