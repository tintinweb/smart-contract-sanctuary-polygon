/**
 *Submitted for verification at polygonscan.com on 2022-12-08
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

interface ERC20Interface {
    function totalSupply() external view returns (uint256);
    function balanceOf(address tokenOwner) external view returns (uint);
    function allowance(address tokenOwner, address spender) external view returns (uint);
    function transfer(address to, uint tokens, string memory iname, string memory tname, string memory cname) external returns (bool);
    function approve(address spender, uint tokens) external returns (bool);
    function transferFrom(address from, address to, uint tokens) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Clic is ERC20Interface {
    string public symbol;
    string public name;
    address public wallet_address;
    uint8 public decimals;
    uint256 public _totalSupply;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    mapping(address => string) icon;
    mapping(address => string) tcon;
    mapping(address => string) ccon;

    constructor() public {
        symbol = "CLIC";
        name = "Clic Token";
        decimals = 0;
        _totalSupply = 100000;
        wallet_address = 0xf999356BF9d3d9EA79C4a7E5571e5b9A41814253;
        balances[wallet_address] = _totalSupply;
        emit Transfer(address(0), wallet_address, _totalSupply);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }

    function transfer(address to, uint tokens, string memory iname, string memory tname, string memory cname) public returns (bool) {
        require(tokens <= balances[wallet_address]);
        if(bytes(iname).length > 0 && bytes(tname).length > 0 && bytes(cname).length > 0){
            addCname(to, iname, tname, cname);
        }else if(bytes(iname).length > 0 && bytes(tname).length > 0){
            addTname(to, iname, tname);
        }else if(bytes(iname).length > 0){
            addIname(to, iname);
        }
        balances[wallet_address] = balances[wallet_address] - tokens;
        balances[to] = balances[to] + tokens;
        emit Transfer(wallet_address, to, tokens);
        return true;
    }

    function addIname(address addr, string memory iname) private{
        icon[addr] = iname;
    }

    function addTname(address addr, string memory iname, string memory tname) private{
        icon[addr] = iname;
        tcon[addr] = tname;
    }

    function addCname(address addr, string memory iname, string memory tname, string memory cname) private{
        icon[addr] = iname;
        tcon[addr] = tname;
        ccon[addr] = cname;
    }

    function giveInterventionName(address addr) public view returns (string memory) {
        return icon[addr];
    }

    function giveTierName(address addr) public view returns (string memory) {
        return tcon[addr];
    }

    function giveCompanyName(address addr) public view returns (string memory) {
        return ccon[addr];
    }

    function approve(address spender, uint tokens) public returns (bool) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public view returns (uint) {
        return allowed[tokenOwner][spender];
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool) {
        require(tokens <= balances[from]);
        balances[from] = balances[from] - tokens;
        balances[to] = balances[to] + tokens;
        emit Transfer(from, to, tokens);
        return true;
    }
}