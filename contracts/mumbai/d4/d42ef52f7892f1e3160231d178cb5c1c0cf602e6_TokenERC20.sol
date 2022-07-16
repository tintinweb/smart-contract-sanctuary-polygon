/**
 *Submitted for verification at polygonscan.com on 2022-07-15
*/

/**
 *Submitted for verification at polygonscan.com on 2022-04-12
*/

pragma solidity 0.8.7;

contract TokenERC20 {
    
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public totalSupply;


    mapping (address => uint256) public balanceOf;   
   
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    
    event Burn(address indexed from, uint256 value);
    
    constructor(uint256 initialSupply, string memory tokenName, string memory tokenSymbol, uint256 _decimals) public {
        totalSupply = initialSupply * 10 ** uint256(_decimals); 

        balanceOf[msg.sender] = totalSupply;
        name = tokenName;
        symbol = tokenSymbol;
        decimals = _decimals;
    }
    
    function _transfer(address _from, address _to, uint _value) internal {
        
        require(balanceOf[_from] >= _value); 
        require(balanceOf[_to] + _value > balanceOf[_to]);

        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value); 
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value); 
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]); 
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }
}