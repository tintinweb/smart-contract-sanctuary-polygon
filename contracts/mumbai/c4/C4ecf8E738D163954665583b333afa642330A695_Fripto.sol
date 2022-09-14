/**
 *Submitted for verification at polygonscan.com on 2022-09-13
*/

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.15;


contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); c = a - b; } function safeMul(uint a, uint b) public pure returns (uint c) { c = a * b; require(a == 0 || c / a == b); } function safeDiv(uint a, uint b) public pure returns (uint c) { require(b > 0);
        c = a / b;
    }
}

contract Fripto is  SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals; // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public _totalSupply;
    address payable public owner;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    
    modifier onlyOwner {
      require(msg.sender == owner);
      _;
   }

    constructor() public {
        name = "Fripto";
        symbol = "FRP";
        decimals = 18;
        _totalSupply = 0;
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
        owner= payable(msg.sender);
    }
    
    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }
    
    function mint(address owner, uint256 amount) public onlyOwner {
        mint(owner, amount);
    }


    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }
    
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function transfer(address to, uint tokens) public returns (bool success) {
        uint Tokens = tokens*(10**18);
        balances[msg.sender] = safeSub(balances[msg.sender], Tokens);
        balances[to] = safeAdd(balances[to], Tokens);
        emit Transfer(msg.sender, to, Tokens);
        return true;
    }
    
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function buy(address buyer, uint256 numTokens) public payable returns(bool) {
        require (msg.value == numTokens * 100 wei);
        // get the amount of Ether stored in this contract
        uint amount = address(this).balance;
        // send all Ether to owner
        // Owner can receive Ether since the address of owner is payable
        (bool success, ) = owner.call{value: amount}("");
        
        //require(success, "Failed to send Ether");
        require(numTokens <= balances[owner]);
       // require(numTokens <= allowed[owner][msg.sender]);

        balances[owner] = balances[owner]-numTokens;
        allowed[owner][msg.sender] = allowed[owner][msg.sender]+numTokens;
        balances[buyer] = balances[buyer]+numTokens;
        emit Transfer(owner, buyer, numTokens);
        return true;

    }

    function Sell(address payable seller, uint256 numTokens) public payable returns(bool) {
        require (msg.value == 1 ether);
        // get the amount of Ether stored in this contract
        uint amount = address(this).balance;
        // send all Ether to owner
        // Owner can receive Ether since the address of owner is payable
        (bool success, ) = seller.call{value: msg.value}("");
        
        //require(success, "Failed to send Ether");
        require(numTokens <= balances[seller]);
       // require(numTokens <= allowed[owner][msg.sender]);

        balances[seller] = balances[seller]-numTokens;
        allowed[seller][msg.sender] = allowed[seller][msg.sender]+numTokens;
        balances[owner] = balances[owner]+numTokens;
        emit Transfer(owner, seller, numTokens);
        return true;

    }

}