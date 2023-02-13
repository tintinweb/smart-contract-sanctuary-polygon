/**
 *Submitted for verification at polygonscan.com on 2023-02-12
*/

pragma solidity ^0.8.0;
//SPDX-License-Identifier: UNLICENSED
contract Token {
    string public name = "FANTAREV";
    string public symbol = "FRS";
    uint256 public totalSupply = 1000;
    mapping(address => uint256) public balanceOf;
    address public owner;
    
    constructor() {
        owner = msg.sender;
        balanceOf[owner] = totalSupply;
    }
    
    function mine() public {
        require(msg.sender == owner, "Only the owner can mine.");
        balanceOf[msg.sender] += 1000;
        totalSupply += 1000;
    }
    
    function burn(uint256 _value) public {
        require(msg.sender == owner, "Only the owner can burn.");
        require(balanceOf[msg.sender] >= _value, "Not enough tokens to burn.");
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
    }
    
    function transfer(address _to, uint256 _value) public {
        require(balanceOf[msg.sender] >= _value, "Not enough tokens to transfer.");
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
    }
}