// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract FungibleToken {
    
    string private name;
    string private symbol;
    uint256 private tokenTotalSupply;

    mapping(address => mapping(address => uint256)) private allowances;
    mapping(address => uint256) private balances;

    event Transfer(address from, address to, uint256 amount);
    event Approve(address owner, address spender, uint256 amount);
    event Deposit(address minter, uint256 amount); 

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function _name() external view returns(string memory) {
        return name;
    }

    function _symbol() external view returns(string memory) {
        return symbol;
    }

    function totalSupply() external view returns(uint256) {
        return tokenTotalSupply;
    }

    function decimals() public pure returns(uint256) {
        return 8;
    }

    function balanceOf(address account) external view returns(uint256) {
        return balances[account];
    }

    function allowance(address owner, address spender) external view returns(uint256) {
        return allowances[owner][spender];
    }

    function mint() public payable {
        uint256 amount = msg.value;
        tokenTotalSupply += amount;
        balances[msg.sender] += amount;
        emit Deposit(msg.sender, msg.value);
        emit Transfer(address(this), msg.sender, amount);
    }

    function transfer(address to, uint256 amount) public {
        require(balances[msg.sender] >= amount, "Insufficient balance!");
        balances[msg.sender] -= amount;
        balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
    }

    function approve(address spender, uint256 amount) external {
        require(spender != address(0), "Spender can not be address zero!");
        require(balances[msg.sender] >= amount, "Can't approve more than your balance!");
        allowances[msg.sender][spender] += amount;
        emit Approve(msg.sender, spender, amount);
    }

    function disapprove(address spender, uint256 amount) external {
        require(allowances[msg.sender][spender] >= amount, "Can't disapprove more than the allowance!");
        allowances[msg.sender][spender] -= amount;
    }

    function transferFrom(address from, address to, uint256 amount) external {
        require(allowances[from][msg.sender] >= amount, "Amount can not be more than allowance!");
        require(balances[from] >= amount, "Not enough tokens!");
        allowances[from][msg.sender] -= amount;
        balances[from] -= amount;
        balances[to] += amount;
        emit Transfer(from, to, amount);
    }
    
}