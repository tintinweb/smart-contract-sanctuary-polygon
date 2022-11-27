/**
 *Submitted for verification at polygonscan.com on 2022-11-26
*/

pragma solidity ^0.5.0;

contract ERC20Interface {
    function mint(address to, uint amount) public returns (bool success);
    function burn(address to, uint amount) public returns (bool success);
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}



contract Yunnanilus is ERC20Interface {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public _totalSupply;
    uint256 public _maxSupply;
    address public admin;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor() public {
        name = "Yunnanilus";
        symbol = "YNL";
        decimals = 0;
        _maxSupply = 1000000;
        _totalSupply = 0;
        admin = msg.sender;
    }

    function mint(address to, uint256 amount) public returns (bool success) {
        require(to != address(0), "Kann nicht zu null address minten");
        require(msg.sender == admin, "NICHT ADMIN");
        require(_totalSupply + amount <= _maxSupply, "Minting überstiegt maxSupply");

        _totalSupply += amount;

        balances[to] += amount;

        emit Transfer(address(0), to, amount);
        return true;
    }



    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
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
        require(balances[msg.sender] >= tokens, "Transfervolumen übersteigt balance");
        balances[msg.sender] -=  tokens;
        balances[to] +=  tokens;
        emit Transfer(msg.sender, to, tokens);
        return true;
    }



    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        require(allowed[from][msg.sender] >= tokens, "Transfervolumen übersteigt allowance");
        balances[from] -= tokens;
        allowed[from][msg.sender] -= tokens;
        balances[to] += tokens;
        emit Transfer(from, to, tokens);
        return true;
    }


    function burn(address to, uint256 amount) public returns (bool success) {
        require(to != address(0), "Kann nicht Tokens der null Adresse verbrennen");
        require(msg.sender == admin, "NICHT ADMIN");
        require(balances[to] - amount >= 0, "Wallet besitzt nicht genug Tokens");

        _totalSupply -= amount;

        balances[to] -= amount;

        emit Transfer(to, address(0), amount);
        return true;
    }
}