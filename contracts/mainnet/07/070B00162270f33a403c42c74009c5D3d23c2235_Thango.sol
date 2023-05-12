// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Thango {
    string public name = "Thango";
    string public symbol = "TGOO";
    uint256 public decimals = 18;
    uint256 public totalSupply = 500000000000 * 10**decimals;
    uint256 public maxTransactionLimit = totalSupply / 100;
    address public devWallet;
    uint256 public devLockedAmount;
    uint256 public devLockedUntil;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        devWallet = 0xE7Dcd230B5A1647F1F68C0D48Bacf0FA8f184f90;
        uint256 devAmount = totalSupply / 20;
        balanceOf[devWallet] = devAmount;
        emit Transfer(address(0), devWallet, devAmount);
        devLockedAmount = devAmount;
        devLockedUntil = block.timestamp + 365 days;
        balanceOf[msg.sender] = totalSupply - devAmount;
        emit Transfer(address(0), msg.sender, totalSupply - devAmount);
    }

    function transfer(address _to, uint256 _value) external returns (bool success) {
        require(_to != address(0), "Cannot transfer to null address");
        require(_value <= balanceOf[msg.sender], "Insufficient balance");
        require(_value <= maxTransactionLimit, "Exceeds maximum transaction limit");
        uint256 fee = _value / 20;
        uint256 netValue = _value - fee;
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += netValue;
        balanceOf[address(0)] += fee;
        emit Transfer(msg.sender, _to, netValue);
        emit Transfer(msg.sender, address(0), fee);
        return true;
    }

    function approve(address _spender, uint256 _value) external returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success) {
        require(_to != address(0), "Cannot transfer to null address");
        require(_value <= balanceOf[_from], "Insufficient balance");
        require(_value <= maxTransactionLimit, "Exceeds maximum transaction limit");
        require(_value <= allowance[_from][msg.sender], "Insufficient allowance");
        uint256 fee = _value / 20;
        uint256 netValue = _value - fee;
        balanceOf[_from] -= _value;
        balanceOf[_to] += netValue;
        balanceOf[address(0)] += fee;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, netValue);
        emit Transfer(_from, address(0), fee);
        return true;
    }

    function withdrawDevLockedTokens() external {
        require(msg.sender == devWallet, "Only the dev wallet can call this function");
        require(block.timestamp >= devLockedUntil, "Locked tokens cannot be withdrawn yet");
        uint256 amount = devLockedAmount;
        devLockedAmount = 0;
        balanceOf[devWallet] += amount;
        emit Transfer(address(0), devWallet, amount);
    }
}