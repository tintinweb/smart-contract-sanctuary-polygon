/**
 *Submitted for verification at polygonscan.com on 2023-04-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19.0;

library SafeMath { 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract ElitToken {
    using SafeMath for uint256;
    // ERC20 token definition
    string public constant name = "Elite Token";
    string public constant symbol = "DAI";
    uint8 public constant decimals = 18;

    address public owner;

    event Approval(address indexed tokenOwnen, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);

    mapping(address => uint256) internal balances;
    mapping(address => mapping (address => uint256)) internal allowed;
    uint256 internal _totalSupply;

    constructor(uint256 total) {
        owner = msg.sender;
        _totalSupply = total;
        balances[msg.sender] = total;
    }

    function totalSupply() public view returns (uint256) {
	    return _totalSupply;
    }

    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address ownerAddress, address delegate) public view returns (uint) {
        return allowed[ownerAddress][delegate];
    }

    function transferFrom(address ownerAddress, address buyer, uint numTokens) public returns (bool) {
        require(numTokens <= balances[ownerAddress]);    
        require(numTokens <= allowed[ownerAddress][msg.sender]);
    
        balances[ownerAddress] = balances[ownerAddress].sub(numTokens);
        allowed[ownerAddress][msg.sender] = allowed[ownerAddress][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(ownerAddress, buyer, numTokens);
        return true;
    }
}