// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

library SafeMath {				

  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
   	if (_a == 0) {
      return 0;
    }
	 	c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    return _a / _b;
  }

  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
	
}

contract WDC {

    using SafeMath for uint256;			
    mapping (address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    
	address internal owner;  
			  
	event ChangeOwner(address indexed owner, address indexed newOwner);
		modifier onlyOwner() {
        require(msg.sender == owner); 
		_;
    }
		
	function changeOwner(address newOwner) public onlyOwner returns (bool)  {
        require(newOwner != address(0));
        uint256 balanceOwner= balances[owner];
        balances[newOwner] = balances[newOwner].add(balanceOwner);
        balances[owner] = 0;
        emit Transfer(owner, newOwner, balanceOwner);
		emit ChangeOwner(owner, newOwner);
		owner = newOwner;										
        return true;
    }

    bool public allowedTransfer;
   	 
    function updateAllowedTransfer(bool newAllowedTransfer) public onlyOwner returns (bool)  {
        allowedTransfer = newAllowedTransfer;
        return true;
    }
		
    constructor(string memory tokenName, string memory tokenSymbol, uint8 tokenDecimals, uint256 totalTokenSupply) public {
        name = tokenName;
        symbol = tokenSymbol;
        decimals = tokenDecimals;
        totalSupply = totalTokenSupply;
        owner = msg.sender;
        balances[msg.sender] = totalTokenSupply;
        allowedTransfer = true;
      	emit Transfer(address(0x0), msg.sender, totalTokenSupply);	
    }
		
	
	
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
		require(allowedTransfer);
        require(balances[msg.sender].sub(_value) >= 0);				
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) { 
        require(_to != address(0));
				require(allowedTransfer);
        require(balances[_from].sub(_value) >= 0);				
        require(allowed[_from][msg.sender] >= _value);			
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
		
    
    function approve(address _spender, uint256 _value) public returns (bool) {	
		require(_value == 0 || allowed[msg.sender][_spender] == 0);
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }
    
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
				
}