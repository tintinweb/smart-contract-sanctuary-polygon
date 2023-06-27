// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
//0xF92970452FCd652fab37023C4fBf01D348EaCD40
// vicky.kumar


contract BusdToken {
    string  public name = "BUSD Token";
    string  public symbol = "BUSD";
    uint256 public totalSupply = 1000000000000000000000000; // 1 million tokens
    uint8   public decimals = 18;

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor() {
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import the ERC20 interface for BUSD token
import "./BusdToken.sol";

contract RewardContract {
    address public admin;
    uint256 public adminFee;
    uint256 public weeklyReward;
    uint256 public claimPeriod;
    uint256 public startTime;
    BusdToken public busdToken;
    
    mapping(address => uint256) public rewards;
    
    event RewardClaimed(address indexed user, uint256 amount);
    
    constructor(address _busdToken) {
        admin = msg.sender;
        adminFee = 10; // 10% admin fee
        weeklyReward = 1000; // Weekly reward amount in BUSD
        claimPeriod = 1 weeks; // Claim reward every week
        startTime = block.timestamp;
        busdToken = BusdToken(_busdToken);
    }
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function.");
        _;
    }
    
    function setAdminFee(uint256 _adminFee) external onlyAdmin {
        require(_adminFee <= 100, "Admin fee percentage must be between 0 and 100.");
        adminFee = _adminFee;
    }
    
    function claimReward() external {
        require(block.timestamp >= startTime, "Claim period has not started yet.");
        require(block.timestamp <= startTime + 52 * claimPeriod, "Claim period has ended.");
        
        uint256 lastClaimTime = rewards[msg.sender];
        require(block.timestamp >= lastClaimTime + claimPeriod, "You can claim rewards once per week.");
        
        uint256 rewardAmount = calculateReward(msg.sender);
        require(rewardAmount > 0, "No rewards available to claim.");
        
        rewards[msg.sender] = block.timestamp;
        
        uint256 adminFeeAmount = (rewardAmount * adminFee) / 100;
        uint256 userRewardAmount = rewardAmount - adminFeeAmount;
        
        busdToken.transfer(admin, adminFeeAmount);
        busdToken.transfer(msg.sender, userRewardAmount);
        
        emit RewardClaimed(msg.sender, userRewardAmount);
    }
    
    function calculateReward(address user) private view returns (uint256) {
        uint256 elapsedTime = block.timestamp - startTime;
        uint256 elapsedWeeks = elapsedTime / claimPeriod;
        
        uint256 totalReward = weeklyReward * elapsedWeeks;
        uint256 claimedReward = rewards[user];
        
        return totalReward - claimedReward;
    }
    
    // This function allows the admin to mint additional BUSD tokens to the contract
    function mintBUSD(uint256 amount) external onlyAdmin {
        busdToken.transferFrom(msg.sender, address(this), amount);
    }
}