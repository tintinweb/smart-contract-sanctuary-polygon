pragma solidity ^0.8.20;

contract PolyLock {
    mapping(address => uint256) public balances;
    mapping(address => uint256) public lockTimestamp;
    uint256 public totalLocked;
    uint256 public treasury;

    event Locked(address indexed user, uint256 amount, uint256 lockTime);
    event Unlocked(address indexed user, uint256 amount);

    function lockTokens(uint256 amount, uint256 lockTime) external {
        require(amount > 0, "Amount must be greater than 0");
        require(lockTime > 0, "Lock time must be greater than 0");
        
        balances[msg.sender] += amount;
        lockTimestamp[msg.sender] = block.timestamp + lockTime;
        totalLocked += amount;
        
        treasury += (amount * lockTime) / 100;
        
        emit Locked(msg.sender, amount, lockTime);
    }

    function unlockTokens() external {
        require(block.timestamp >= lockTimestamp[msg.sender], "Tokens are locked");
        
        uint256 amount = balances[msg.sender];
        require(amount > 0, "No tokens to unlock");
        
        uint256 reward = (treasury * balances[msg.sender]) / totalLocked;
        treasury -= reward;
        
        balances[msg.sender] = 0;
        totalLocked -= amount;
        
        emit Unlocked(msg.sender, amount + reward);
    }
}