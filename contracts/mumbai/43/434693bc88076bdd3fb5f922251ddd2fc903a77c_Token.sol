/**
 *Submitted for verification at polygonscan.com on 2023-02-09
*/

pragma solidity ^0.8.0;

contract Token {
    string public name = "My Token";
    string public symbol = "MTK";
    uint8 public decimals = 18;
    uint256 public totalSupply = 1000000 * (10 ** uint256(decimals));

    mapping (address => uint256) public _balances;
    mapping (address => mapping (address => uint256)) public allowed;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor() public {
        _balances[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_balances[msg.sender] >= _value && _value > 0, "Insufficient balance");
        require(_to != address(0), "Transfer to address 0 is not allowed");
        _balances[msg.sender] -= _value;
        _balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_balances[_from] >= _value && _value > 0, "Insufficient balance");
        require(_to != address(0), "Transfer to address 0 is not allowed");
        require(allowed[_from][msg.sender] >= _value, "Not enough approved amount");
        _balances[_from] -= _value;
        _balances[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return _balances[_owner];
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }
}