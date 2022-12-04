// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;
contract Habit {

    // Events that will be emitted on changes.
    event HabitCreated(address indexed user, uint256 habitId, uint256 startTime, uint256 totalAmount, uint256 totalReports, uint256 interval);

    event HabitReported(uint256 habitId, uint256 reportedAt, uint256 successCount, uint256 missedCount);

    struct HabitCore {
        address payable user;
        uint256 startTime;
        uint256 totalAmount;
        uint256 totalReports;
        uint256 interval;
        bool ended;
        uint256 successCount;
        uint256 missedCount;
        uint256 amountWithdrawn;
    }

    mapping(uint256 => HabitCore) private _habits;

    uint256 public totalDeposits;
    uint256 public totalWithdrawals;

    constructor(
       
    ) {
        
    }



    function createHabit(uint256 habitId, uint256 totalReports, uint256 interval) public payable{
        HabitCore storage habit = _habits[habitId];
        require(habit.totalAmount == 0, "Habit with this id already exists");
        require(totalReports > 0, "totalReports should be greater than 0");
        require(msg.value > totalReports, "Amount should be greater than total no. of reports");
        require(interval > 0, "Interval should be greater than 0");


        habit.user = payable(msg.sender);
        habit.startTime = block.timestamp;
        habit.totalAmount = msg.value;
        habit.totalReports = totalReports;
        habit.interval = interval;

        emit HabitCreated(habit.user, habitId, habit.startTime, msg.value, totalReports, interval);
    }

    function getHabit(uint256 habitId) external view returns (HabitCore memory habit){
        return _habits[habitId];
    }

    function report(uint256 habitId) public payable {
        HabitCore storage habit = _habits[habitId];
        require(habit.totalAmount != 0, "Habit with this id does not exists");
        require(habit.user == msg.sender, "Invalid user");
        require(habit.ended == false, "Habit is completed");

        // check if the user is doing it in the slot 
        uint timeDiff = block.timestamp - habit.startTime;
        uint numSlots = timeDiff/habit.interval;
        uint totalUpdatedCount = habit.successCount + habit.missedCount;
        require(totalUpdatedCount <= numSlots, "Already submitted report for this slot");
        if(numSlots >= habit.totalReports){
            habit.missedCount = habit.totalReports - habit.successCount;
        }
        else
        {
            if(numSlots > habit.successCount){
                habit.missedCount = numSlots - habit.successCount;
            }
            habit.successCount++;
        }
        
        if((habit.successCount + habit.missedCount) == habit.totalReports){
            habit.ended = true;
            uint amountToSend = (habit.totalAmount * habit.successCount)/habit.totalReports;
            if(amountToSend > 0)
            {
                habit.user.transfer(amountToSend);
            }
        }

        emit HabitReported(habitId,block.timestamp,habit.successCount, habit.missedCount);
    }

}