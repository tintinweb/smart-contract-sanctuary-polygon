/**
 *Submitted for verification at polygonscan.com on 2023-06-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyToken {
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public totalSupply;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Mint(address indexed to, uint256 value);

    constructor(){
        name="MinerFee";
        symbol="MNF";
        decimals=18;
        totalSupply=1000000000*10**18;
        balances[msg.sender]=totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns(bool){
        require(_value <= balances[msg.sender], "Insufficient balance");
        require(_to != address(0), "Invalid address");

        balances[msg.sender]-=_value;
        balances[_to]+=_value;

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_value <= balances[_from], "Insufficient balance");
        require(_value <= allowed[_from][msg.sender], "Insufficient allowance");
        require(_to != address(0), "Invalid address");

        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_spender != address(0), "Invalid address");

        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function mint(address _to, uint256 _value) public returns (bool){
        require(_value > 0, "Insufficient value");
        require(_to != address(0), "Invalid address");

        totalSupply+=_value;
        balances[_to]+=_value;

        emit Mint(_to, _value);
        emit Transfer(address(0), _to, _value);
        return true;
    }

     function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }
}