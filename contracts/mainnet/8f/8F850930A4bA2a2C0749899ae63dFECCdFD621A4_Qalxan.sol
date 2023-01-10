/**
 *Submitted for verification at polygonscan.com on 2023-01-10
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;


contract Qalxan {

    string public constant name = "Qalxan";
    string public constant symbol ="QXR";
    uint8 public constant decimals = 18;

    event Transfer(address indexed from, address indexed to, uint tokens);
    event approval(address indexed tokenOwner, address indexed spender, uint tokens);

    uint256 totalsupply_;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    constructor() {
        totalsupply_ =865000000 * 10 ** decimals;
        balances[msg.sender] = totalsupply_; 
    } 

    function totalsupply() public view returns (uint256) {
        return totalsupply_;
    }
    
    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }
    
   
    function transfer(address receiver, uint numTokens) public returns(bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender] - numTokens;
        balances[receiver] = balances[receiver] + numTokens;
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint numtokens) public returns (bool) {
        allowed[msg.sender][delegate] =numtokens;
        emit approval(msg.sender, delegate, numtokens);
        return true;
    }

    function allowance(address owner, address delegate) public view returns(uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint numToken) public returns (bool) {
        require(numToken <= balances[owner]); 
        require(numToken <= allowed[owner][msg.sender]);
        balances[owner] = balances[owner] - numToken;
        allowed[owner][msg.sender] = allowed[owner][msg.sender] - numToken;
        balances[buyer] = balances[buyer] + numToken;
        emit Transfer(owner, buyer, numToken);
        return true;
    }
}