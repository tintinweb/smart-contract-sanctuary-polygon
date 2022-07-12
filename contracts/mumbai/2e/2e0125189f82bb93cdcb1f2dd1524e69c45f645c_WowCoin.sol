/**
 *Submitted for verification at polygonscan.com on 2022-07-11
*/

//SPDX-License-Identifier: MIT
pragma solidity > 0.5.0 < 0.9.0;


contract WowCoin {
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 private totalsupply;
    address private _owner;


    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event AddToFreezelist(address _Freezelisted);
    event RemoveFromFreezelist(address _whitelisted);

    mapping(address => mapping(address => uint256)) allowed;
    mapping(address => uint256) Balances;
    mapping(address => bool) Freezelist;
    


    constructor() {
        name = "WowCoin";
        symbol = "WOW";
        decimals = 18;
        totalsupply = 1000000000 * 10 ** decimals;
        Balances[msg.sender] = totalsupply;
        _owner = msg.sender;
    }


    //Owner//
    modifier isOwner() {
        require(msg.sender == _owner, 'Your are not Authorized user');
        _;
    }

    modifier isFreezelisted(address holder) {
        require(Freezelist[holder] == false, "You are Freezelisted");
        _;
    }

    function getOwner() public view returns(address) {
        return _owner;
    }

    function chnageOwner(address newOwner) isOwner() external {
        _owner = newOwner;
    }

    function addtoFreezelist(address Freezelistaddress) isOwner() public {
        Freezelist[Freezelistaddress] = true;
        emit AddToFreezelist(Freezelistaddress);
    }

    function removefromFreezelist(address whitelistaddress) isOwner() public {
        Freezelist[whitelistaddress] = false;
        emit RemoveFromFreezelist(whitelistaddress);
    }

    function showstateofuser(address _address) public view returns(bool) {
        return Freezelist[_address];
    }


    //SafeMath//
    function safeAdd(uint a, uint b) internal pure returns(uint c) {
        c = a + b;
        require(c >= a);
    }

    function safeSub(uint a, uint b) internal pure returns(uint c) {
        require(b <= a);
        c = a - b;
    }

    function safeMul(uint a, uint b) internal pure returns(uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function safeDiv(uint a, uint b) internal pure returns(uint c) {
        require(b > 0);
        c = a / b;
    }


    //ERC20//
    function totalSupply() public view returns(uint256) {
        return totalsupply;
    }

    function balanceOf(address tokenOwner) public view returns(uint balance) {
        return Balances[tokenOwner];
    }

    function allowance(address from, address who) isFreezelisted(from) public view returns(uint remaining) {
        return allowed[from][who];
    }

    function transfer(address to, uint tokens) isFreezelisted(msg.sender) public returns(bool success) {
        Balances[msg.sender] = safeSub(Balances[msg.sender], tokens);
        Balances[to] = safeAdd(Balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address to, uint tokens) isFreezelisted(msg.sender) public returns(bool success) {
        allowed[msg.sender][to] = tokens;
        emit Approval(msg.sender, to, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) isFreezelisted(from) public returns(bool success) {
        require(allowed[from][msg.sender] >= tokens, "Not sufficient allowance");
        Balances[from] = safeSub(Balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        Balances[to] = safeAdd(Balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

}