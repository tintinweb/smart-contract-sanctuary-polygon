/**
 *Submitted for verification at polygonscan.com on 2023-06-21
*/

pragma solidity ^0.8.0;

interface LQTYToken {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract VestingContract {
    address public owner;
    uint256 public totalReward;
    uint256 public rewardPerBlock;
    uint256 public lastBlockNumber;
    uint256 public totalPending;
    LQTYToken private lqtyToken;

    constructor(address _beneficiary ,uint256 _totalReward, uint256 _rewardPerBlock, address _lqtyToken) {
        owner = _beneficiary;
        totalReward = _totalReward;
        lqtyToken = LQTYToken(_lqtyToken);
        totalPending = _totalReward;
        rewardPerBlock = _rewardPerBlock;
        lastBlockNumber = block.number;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can perform this action");
        _;
    }

    function claimReward() external  onlyOwner {
        
        uint256 pendingReward = calculatePendingReward();
        require(pendingReward > 0, "No pending reward to claim");

        // Transfer the reward tokens to the user
        // Replace `transfer` with your token transfer function;
        lastBlockNumber = block.number;
        totalPending =totalPending - pendingReward;
        lqtyToken.transfer(owner, pendingReward);
        
    }

    function calculatePendingReward() public view returns (uint256) {
        uint256 currentBlockNumber = block.number;
        uint256 blocksElapsed = currentBlockNumber - lastBlockNumber;
        uint256 pendingReward = blocksElapsed * rewardPerBlock;
        uint claimableAmount = pendingReward > totalPending ?  totalPending : pendingReward;    
        return claimableAmount;
    }

}