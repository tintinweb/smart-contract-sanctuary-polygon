/**
 *Submitted for verification at polygonscan.com on 2022-02-21
*/

// File: Lottery/Tether.sol


pragma solidity >=0.4.22 <0.9.0;

contract Tether {
    string  public name = "Mock Tether Token";
    string  public symbol = "mUSDT";
    uint256 public totalSupply = 10000000000000000000000000; // 1 million tokens
    uint8   public decimals = 18;

    event Transfer(
        address indexed _from,
        address indexed _to, 
        uint _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender, 
        uint _value
    );

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    constructor() {
        balanceOf[0xd31B829e3B5665C2806343030394cA838FA52dAA] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        // require that the value is greater or equal for transfer
        require(balanceOf[msg.sender] >= _value);
         // transfer the amount and subtract the balance
        balanceOf[msg.sender] -= _value;
        // add the balance
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
        //2000000000
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from], "Low Balance");
        require(_value <= allowance[_from][msg.sender], "Low o.O");
        // add the balance for transferFrom
        balanceOf[_to] += _value;
        // subtract the balance for transferFrom
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
}