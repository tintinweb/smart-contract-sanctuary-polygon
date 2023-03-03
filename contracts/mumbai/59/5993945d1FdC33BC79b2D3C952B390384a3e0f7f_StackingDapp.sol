// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StackingDapp {
    
    struct Stacker {
        uint256 amount;
        uint256 unlockTime;
        uint256 withdrawTime;
    }
    
    mapping(address => Stacker[]) public stackers;
    uint256 public totalStacked;
    uint256 public constant MINIMUM_STACK = 1 ether;
    uint256 public constant STACKING_PERIOD = 30 days;
    uint256 public constant STACKING_INTEREST_RATE = 5;
    
    function stack() external payable {
        require(msg.value >= MINIMUM_STACK, "Minimum stack not met");
        Stacker[] storage stakers = stackers[msg.sender];
        uint256 stakingAmount = msg.value;
        if (stakers.length > 0) {
            // If the user has staked before, add the amount to their latest stake
            Stacker storage lastStack = stakers[stakers.length - 1];
            require(block.timestamp >= lastStack.unlockTime, "Previous stack still locked");
            lastStack.amount += stakingAmount;
            stakingAmount = lastStack.amount;
        } else {
            // If the user is staking for the first time, create a new Stacker
            stakers.push( Stacker(stakingAmount, block.timestamp + STACKING_PERIOD, 0) );
        }
        totalStacked += stakingAmount;
    }
    
    function withdraw(uint256 index) external {
        Stacker[] storage stakers = stackers[msg.sender];
        require(index < stakers.length, "Invalid index");
        Stacker storage stack = stakers[index];
        require(block.timestamp < stack.unlockTime, "Stack is unlocked");
        uint256 amountToWithdraw = stack.amount;
        if (block.timestamp >= stack.withdrawTime) {
            amountToWithdraw = amountToWithdraw * (block.timestamp - stack.withdrawTime) / STACKING_PERIOD;
            stack.amount -= amountToWithdraw;
            stack.withdrawTime = block.timestamp;
        }
        totalStacked -= amountToWithdraw;
        payable(msg.sender).transfer(amountToWithdraw);
    }
    
    function unstake() external {
        Stacker[] storage stakers = stackers[msg.sender];
        require(stakers.length > 0, "No stack found");
        Stacker storage lastStack = stakers[stakers.length - 1];
        require(block.timestamp >= lastStack.unlockTime, "Stack still locked");
        uint256 interest = lastStack.amount * STACKING_INTEREST_RATE / 100;
        payable(msg.sender).transfer(lastStack.amount + interest);
        totalStacked -= lastStack.amount;
        stakers.pop();
    }
    
    function getStack(address stackerAddress, uint256 index) external view returns (uint256, uint256, uint256) {
        Stacker[] memory stakers = stackers[stackerAddress];
        require(index < stakers.length, "Invalid index");
        Stacker memory stack = stakers[index];
        return (stack.amount, stack.unlockTime, stack.withdrawTime);
    }
    
    function getTotalStacked() external view returns (uint256) {
        return totalStacked;
    }
}