/**
 *Submitted for verification at polygonscan.com on 2023-07-05
*/

pragma solidity ^0.8.0;

contract PolyINU {
    string public constant name = "PolyINU";
    string public constant symbol = "PINU";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed burner, uint256 value);

    constructor(uint256 initialSupply) {
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balances[msg.sender] = totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0), "Invalid recipient address");
        require(_value <= balances[msg.sender], "Insufficient balance");

        uint256 burnAmount1 = (_value * 2) / 100; // Calculate 2% to burnAddress1
        uint256 burnAmount2 = (_value * 3) / 100; // Calculate 3% to burnAddress2

        uint256 transferAmount = _value - (burnAmount1 + burnAmount2); // Calculate the transfer amount

        balances[msg.sender] -= _value;
        balances[_to] += transferAmount;
        balances[burnAddress1] += burnAmount1;
        balances[burnAddress2] += burnAmount2;

        emit Transfer(msg.sender, _to, transferAmount);
        emit Transfer(msg.sender, burnAddress1, burnAmount1);
        emit Transfer(msg.sender, burnAddress2, burnAmount2);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0), "Invalid recipient address");
        require(_value <= balances[_from], "Insufficient balance");
        require(_value <= allowed[_from][msg.sender], "Insufficient allowance");

        uint256 burnAmount1 = (_value * 2) / 100; // Calculate 2% to burnAddress1
        uint256 burnAmount2 = (_value * 3) / 100; // Calculate 3% to burnAddress2

        uint256 transferAmount = _value - (burnAmount1 + burnAmount2); // Calculate the transfer amount

        balances[_from] -= _value;
        balances[_to] += transferAmount;
        balances[burnAddress1] += burnAmount1;
        balances[burnAddress2] += burnAmount2;

        allowed[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, transferAmount);
        emit Transfer(_from, burnAddress1, burnAmount1);
        emit Transfer(_from, burnAddress2, burnAmount2);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    // Additional burn functions for specific addresses
    address public burnAddress1 = 0x000000000000000000000000000000000000dEaD;
    address public burnAddress2 = 0x0000000000000000000000000000000000001010;

    function burn(uint256 _value) public returns (bool) {
        require(_value <= balances[msg.sender], "Insufficient balance");

        balances[msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(msg.sender, _value);
        return true;
    }
}