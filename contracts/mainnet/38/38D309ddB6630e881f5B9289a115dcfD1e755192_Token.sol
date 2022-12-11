/**
 *Submitted for verification at polygonscan.com on 2022-12-11
*/

// File: WEZY.SOL
// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;


contract Token {
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    string public constant name = "WEZYDESIGNS";
    string public constant symbol = "WZYD";
    uint8 public constant decimals = 18;

    uint256 public immutable totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) private _allowance;

    constructor() {
        totalSupply = 1000000 ether;
        balanceOf[msg.sender] = 1000000  ether;
        emit Transfer(address(0), msg.sender, 1000000  ether);
    }

    function transfer(address _to, uint256 _value) external returns (bool) {
        balanceOf[msg.sender] -= _value;
        unchecked { balanceOf[_to] += _value; }
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool){
        _allowance[_from][msg.sender] -= _value;
        balanceOf[_from] -= _value;
        unchecked { balanceOf[_to] += _value; }
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool){
        _allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) external  view returns (uint256) {
        return _allowance[_owner][_spender];
    }

}