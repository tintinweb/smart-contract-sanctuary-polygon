/**
 *Submitted for verification at polygonscan.com on 2022-07-21
*/

pragma solidity ^0.8.7;

contract MySkylerToken {
    string public name = "Skyler Token";
    uint8 public decimals = 1;
    string public symbol = "SKY";
    uint256 public totalSupply = 1000;

    mapping(address => uint256) public myBalances;

    constructor() {
        myBalances[msg.sender] = totalSupply;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return myBalances[owner];
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        require(myBalances[msg.sender] >= amount, 'caught you lacking u need more SKY bro');
        
        myBalances[msg.sender] -= amount;
        myBalances[to] += amount;

        return true;
    }

}