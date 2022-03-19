/**
 *Submitted for verification at polygonscan.com on 2022-03-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract MetaCoinToken {

    string public name;
    string public symbol;
    uint256 private price = 100;
    uint256 public totalSupply;
    uint256 public decimals;


    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public balanceOf;
    
    
    constructor() {
        name = "MetaCoinToken";
        symbol = "MST";
        totalSupply = 1000000 * 10 ** 18;
        decimals = 18;    
        balanceOf[msg.sender] = totalSupply;
    }
 
    function transfer(address _to, uint256 _value) external returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0));
        balanceOf[_from] = balanceOf[_from] - (_value);
        balanceOf[_to] = balanceOf[_to] + (_value);
        emit Transfer(_from, _to, _value);
    }

    function buyToken(address _reciever, uint256 _value) external payable returns (bool success) {
        require(balanceOf[msg.sender] >= _value*price);
        balanceOf[_reciever] = balanceOf[_reciever] + (_value*price);
        _transfer(msg.sender, _reciever, _value*price);
        return true;
    }    
}