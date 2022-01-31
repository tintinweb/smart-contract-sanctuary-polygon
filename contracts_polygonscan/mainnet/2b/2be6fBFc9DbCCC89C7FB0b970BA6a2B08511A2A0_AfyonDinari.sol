/**
 *Submitted for verification at polygonscan.com on 2021-12-11
*/

// SPDX-License-Identifier: NONE
pragma solidity ^0.8.0;

/*
* This token is created to be used in my Dungeons and Dragons games only.
* There is no real value of this token.
* If someone tries to sell you this token, please report him/her/they.
*/

contract AfyonDinari {
    mapping (address => uint256) public balanceOf;
    string public name = "Afyon Dinari";
    string public symbol = "AFYON";
    uint8 public decimals = 18;
    uint256 public totalSupply = 100000000 * (10 ** decimals);

    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer (address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor() {
        balanceOf[msg.sender] = totalSupply;

        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value, "Not enough resource to transfer.");
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require (allowance[_from][msg.sender] >= _value, "Not approved to transfer.");
        require(balanceOf[_from] >= _value, "Not enough resources to transfer.");

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);

        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
}