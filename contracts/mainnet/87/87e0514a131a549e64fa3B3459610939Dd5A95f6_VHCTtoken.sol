/**
 *Submitted for verification at polygonscan.com on 2023-01-06
*/

pragma solidity ^0.4.24;
 
//Safe Math Interface
 
contract SafeMath {
 
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
 
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
 
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
 
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
    function uintToString(uint v) public pure returns (string str) {
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = byte(48 + remainder);
        }
        bytes memory s = new bytes(i + 1);
        for (uint j = 0; j <= i; j++) {
            s[j] = reversed[i - j];
        }
        str = string(s);
    }
}
 
 
//ERC Token Standard #20 Interface
 
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
 
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
 
 
//Contract function to receive approval and execute function in one call
 
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}
 
//Actual token contract
 
contract VHCTtoken is ERC20Interface, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    address public minter;
 
    mapping(address => uint) balances;
    mapping(address => uint) VNDs;
    mapping(address => uint) vouchers;
    mapping(address => mapping(address => uint)) allowed;

    event Supply(address from, address to, uint amount);
    event Getvoucher(address from, address to, uint amount);
    event GetVND(address from, address to, uint amount);

    constructor() public {
        symbol = "VCH";
        name = "Voucher Coin";
        decimals = 3;
        _totalSupply = 9000000*10**3;
        minter = 0xd5A3C18AeD22482C4B9e58df6FDC1d6F5041fE26;
        balances[minter] = _totalSupply;
        emit Transfer(address(0), minter, _totalSupply);
    }
 
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }
 
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }
 
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
 
    function approve(address spender, uint tokens) public returns (bool success) {
        if (balances[msg.sender] < tokens) return false;
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
 
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        if (balances[from] < tokens) return false;
        if (allowed[from][msg.sender]  < tokens) return false;
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
 
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
 
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }
    function supplyTo(address to, uint tokens) public returns (bool success) {
        if(minter != msg.sender) return false;
        if (balances[minter] < tokens) return false;
        balances[minter] = safeSub(balances[minter], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Supply(msg.sender, to, tokens);
        return true;

    }
    function getVouform(address form, uint tokens) public returns (bool success) {
        if(minter != msg.sender) return false;
        if (balances[form] < tokens) return false;
        balances[form] = safeSub(balances[form], tokens);
        balances[minter] = safeAdd(balances[minter], tokens);
	    vouchers[form] = safeAdd(vouchers[form] , tokens);
	    emit Getvoucher(form,minter,tokens);
        return true;
    }
    function getvndform(address form, uint tokens) public returns (bool success) {
        if(minter != msg.sender) return false;
        if (balances[form] < tokens) return false;
        balances[form] = safeSub(balances[form], tokens);
        balances[minter] = safeAdd(balances[minter], tokens);
	    VNDs[form] = safeAdd(VNDs[form],tokens);
	    emit GetVND(form,minter,tokens);
        return true;
    }
   function voucherOf(address tokenOwner) public constant returns (uint voucher) {
        return vouchers[tokenOwner];
    }
   function vndOf(address tokenOwner) public constant returns (uint vnd) {
        return VNDs[tokenOwner];
    }
    function () public payable {
        revert();
    }
}