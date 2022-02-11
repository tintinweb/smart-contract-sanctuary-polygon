/**
 *Submitted for verification at polygonscan.com on 2022-02-02
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract MyCoin{

    uint256 public totalSupply;
    string public name;
    string public symbol;
    uint8 public decimals;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address _from, address _to, uint256 _value);
    event Approval(address _owner, address _spender, uint256 _value);

    constructor(uint256 _initialSupply, uint8 _decimals, string memory _name, string memory _symbol){
        name = _name;
        symbol = _symbol;
        totalSupply = _initialSupply;
        balanceOf[msg.sender] = _initialSupply;
        decimals = _decimals;
    }

    function transfer(address _to, uint256 _value) public returns(bool success) {

        require(balanceOf[msg.sender] >= _value);

        balanceOf[_to] += _value;

        balanceOf[msg.sender] -= _value;

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function approve(address _spender, uint256 _value) public returns(bool success){

        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){

        //check allowance
        require(allowance[_from][msg.sender] >= _value);

        //check enough tokens
        require(balanceOf[_from] >= _value);

        //transfer
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        //update allowance
        allowance[_from][msg.sender] = 0;

        //emit
        emit Transfer(_from, _to, _value);

        return true;
    }
}