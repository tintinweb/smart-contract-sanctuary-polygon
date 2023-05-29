/**
 *Submitted for verification at polygonscan.com on 2023-05-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Kill4Money {
    string public name = "Kill 4 Money";
    string public symbol = "Kill4";
    uint8 public decimals = 4;
    uint256 public totalSupply;
    address private contractOwner;
    uint256 private constant TOKEN_RATIO = 10; // Mint 10 tokens for every 5 Polygon deposited
    uint256 private constant BURN_FEE = 1; // 1% burn fee
    uint256 private constant TRANSACTION_FEE = 1; // 0.0001 KILL4 tokens per transaction

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        contractOwner = msg.sender;
        totalSupply = 100000 * (10**uint256(decimals));
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(amount <= balances[msg.sender], "Insufficient balance");
        require(amount > 0, "Amount must be greater than zero");

        uint256 burnAmount = (amount * BURN_FEE) / 100;
        uint256 transferAmount = amount - burnAmount;
        balances[msg.sender] -= amount;
        balances[recipient] += transferAmount;
        balances[address(0)] += burnAmount;

        emit Transfer(msg.sender, recipient, transferAmount);
        emit Transfer(msg.sender, address(0), burnAmount);

        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        require(amount <= balances[sender], "Insufficient balance");
        require(amount <= allowances[sender][msg.sender], "Insufficient allowance");
        require(amount > 0, "Amount must be greater than zero");

        uint256 burnAmount = (amount * BURN_FEE) / 100;
        uint256 transferAmount = amount - burnAmount;
        balances[sender] -= amount;
        balances[recipient] += transferAmount;
        balances[address(0)] += burnAmount;
        allowances[sender][msg.sender] -= amount;

        emit Transfer(sender, recipient, transferAmount);
        emit Transfer(sender, address(0), burnAmount);

        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowances[owner][spender];
    }

    function mint(uint256 amount) public payable {
        require(amount > 0, "Amount must be greater than zero");
        require(msg.value >= (amount / TOKEN_RATIO), "Insufficient funds");

        balances[msg.sender] += amount;
        totalSupply += amount;

        emit Transfer(address(0), msg.sender, amount);
    }

    function burn(uint256 amount) public {
        require(amount <= balances[msg.sender], "Insufficient balance");
        require(amount > 0, "Amount must be greater than zero");

        balances[msg.sender] -= amount;
        totalSupply -= amount;

        emit Transfer(msg.sender, address(0), amount);
    }

    function deposit() external payable {
        // No additional logic required for deposit
    }

    function withdraw(uint256 amount) external {
        require(amount <= address(this).balance, "Insufficient contract balance");
        require(amount > 0, "Amount must be greater than zero");
        require(msg.sender == contractOwner, "Only the contract owner can withdraw funds");

        payable(contractOwner).transfer(amount);
    }

    receive() external payable {
        // Fallback function to receive ETH
    }
}