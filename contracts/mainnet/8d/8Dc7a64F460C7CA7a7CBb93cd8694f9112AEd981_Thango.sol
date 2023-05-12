// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Thango {
    string public name = "Thango";
    string public symbol = "THGG";
    uint8 public decimals = 18;
    uint256 public totalSupply = 500000000000000000000000000; // Max supply of 500 billion (18 decimals)
    
    uint256 public maxSellLimit = totalSupply / 100; // 1% of total supply
    uint256 public devWithdrawalLockEnd;
    
    address payable public devWallet;
    address public nullAddress = address(0);
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor() {
        devWallet = payable(msg.sender);
        uint256 devInitialBalance = totalSupply / 20; // 5% of total supply to dev wallet
        balanceOf[devWallet] = devInitialBalance;
        balanceOf[address(this)] = totalSupply - devInitialBalance;
        devWithdrawalLockEnd = block.timestamp + 365 days;
        emit Transfer(nullAddress, devWallet, devInitialBalance);
        emit Transfer(nullAddress, address(this), totalSupply - devInitialBalance);
    }
    
    modifier onlyDev() {
        require(msg.sender == devWallet, "Unauthorized");
        _;
    }
    
    modifier devWithdrawalAllowed() {
        require(block.timestamp >= devWithdrawalLockEnd, "Withdrawal locked");
        _;
    }
    
    function transfer(address to, uint256 value) public returns (bool success) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool success) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require(value <= allowance[from][msg.sender], "Insufficient allowance");
        allowance[from][msg.sender] -= value;
        _transfer(from, to, value);
        return true;
    }
    
    function _transfer(address from, address to, uint256 value) internal {
        require(from != nullAddress, "Invalid sender");
        require(to != nullAddress, "Invalid recipient");
        require(value > 0, "Invalid transfer amount");
        require(balanceOf[from] >= value, "Insufficient balance");
        require(balanceOf[to] + value > balanceOf[to], "Balance overflow");
        require(value <= maxSellLimit || from == devWallet, "Sell limit exceeded");
        
        uint256 fee = value / 20; // 5% transaction fee
        balanceOf[from] -= value;
        balanceOf[nullAddress] += fee;
        balanceOf[to] += value - fee;
        
        emit Transfer(from, to, value);
        if (fee > 0) {
            emit Transfer(from, nullAddress, fee);
        }
    }
    
    function withdrawDevBalance() public onlyDev devWithdrawalAllowed {
        uint256 devBalance = balanceOf[devWallet];
        require(devBalance > 0, "No balance to withdraw");
        balanceOf[devWallet] = 0;
        devWallet.transfer(devBalance);
        emit Transfer(devWallet, nullAddress, devBalance);
    }
}