/**
 *Submitted for verification at polygonscan.com on 2022-02-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HangToken {

    mapping (address => uint256) public balanceOf;
    string public name = "Hang Token";
    string public symbol = "HNT";
    uint8 public decimals = 18;
    uint256 public totalSupply = 100000000 * (10 ** decimals);

    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor () {
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value, "Not enough tokens to transfer.");
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(allowance[_from][msg.sender] >= _value, "Not Approved To Transfer.");
        require(balanceOf[_from] >= _value, "Not Enough Tokens To Transfer");

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