/**
 *Submitted for verification at polygonscan.com on 2022-12-07
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DudeCoin {
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 private totalsupply;
    address private _owner;

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    

    mapping(address => mapping(address => uint256)) allowed;
    mapping(address => uint256) Balances;
    // mapping(address => bool) Freezelist;
    
    constructor() {
        name = "DudeCoin";
        symbol = "Atxm";
        decimals = 18;
        totalsupply = 50000 * 10 ** decimals;
        Balances[msg.sender] = totalsupply;
        _owner = msg.sender;
    }
    
    modifier isOwner() {
        require(msg.sender == _owner, 'Your are not Authorized user');
        _;
    }

 

    function getOwner() public view returns(address) {
        return _owner;
    }

    function chnageOwner(address newOwner) isOwner() external {
        _owner = newOwner;
    }

    

   function totalSupply() public view returns(uint256) {
        return totalsupply;
    }

    function balanceOf(address tokenOwner) public view returns(uint balance) {
        return Balances[tokenOwner];
    }

    function allowance(address from, address who)  public view returns(uint remaining) {
        return allowed[from][who];
    }

    function transfer(address to, uint tokens) public returns(bool success) {
        Balances[msg.sender] -= tokens;
        Balances[to] +=  tokens;
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address to, uint tokens)  public returns(bool success) {
        allowed[msg.sender][to] = tokens;
        emit Approval(msg.sender, to, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens)  public returns(bool success) {
        require(allowed[from][msg.sender] >= tokens, "Not sufficient allowance");
        Balances[from] -=  tokens;
        allowed[from][msg.sender] -= tokens;
        Balances[to] +=  tokens;
        emit Transfer(from, to, tokens);
        return true;
    }

}