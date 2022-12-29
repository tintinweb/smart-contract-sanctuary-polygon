/**
 *Submitted for verification at polygonscan.com on 2022-12-28
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

/// @title habETH contract - Own your goal
/// @author Team Dazzle
/// @notice This contract allows users to create a committment/goal for self and report

contract Habit {
    /*Type declarations*/
    mapping(uint256 => HabitCore) private _habits;
    mapping(address => uint256[]) private _userHabits;

    struct HabitCore {
        address payable user;
        string title;
        string committment;
        uint256 startTime;
        uint256 totalAmount;
        uint256 totalReports;
        uint256 interval;
        bool ended;
        uint256 successCount;
        uint256 missedCount;
        uint256 amountWithdrawn;
    }

    /*State Variables */
    uint256 public totalAmountDeposited;
    uint256 public totalAmountWithdrawn;

    /*Events */
    /// @notice This event is emitted when a user creates a new Habit
    /// @dev emit from func createHabit
    /// @param user The habit creator's address
    /// @param habitId The hash of user address, goal title and habit committment
    /// @param startTime The timestamp when the habit was created
    /// @param totalAmount The value of the habit/committment for the user in MATIC
    /// @param totalReports The duration within which the user wants to achieve his/her committment
    /// @param interval The duration in which user wants to get notified
    event HabitCreated(
        address indexed user,
        uint256 indexed habitId,
        uint256 startTime,
        uint256 totalAmount,
        uint256 totalReports,
        uint256 interval
    );

    /// @notice This event is emitted when a user reports for his/her committment
    /// @dev emit from func report
    /// @param user The habit creator's address
    /// @param habitId The hash of user address, goal title and habit committment
    /// @param journalEntry The description of the report creadted by user
    /// @param proofUrl The IPFS url of the proof attached in the report
    /// @param reportedAt The timestamp when the report was made towards the committment
    /// @param successCount The count of the reports made by user within the committed time interval
    /// @param missedCount The count of the reports missed by user within the committed time interval

    event HabitReported(
        uint256 indexed habitId,
        address indexed user,
        string journalEntry,
        string proofUrl,
        uint256 reportedAt,
        uint256 successCount,
        uint256 missedCount
    );

    /// @notice This event is emitted when the committed duration is reached
    /// @dev emit from func report when the committed duration is completed
    /// @param startTime a parameter just like in doxygen (must be followed by parameter name)
    /// @param totalAmount The value of the habit/committment for the user in MATIC
    /// @param totalReports The duration within which the user wants to achieve his/her committment
    /// @param successCount The count of the reports made by user within the committed time interval
    /// @param missedCount The count of the reports missed by user within the committed time interval
    /// @param amountWithdrawn The amount sent by the contract to the user address after the committment  duration was completed

    event HabitCompleted(
        uint256 indexed habitId,
        address indexed user,
        uint256 startTime,
        uint256 totalAmount,
        uint256 totalReports,
        uint256 successCount,
        uint256 missedCount,
        uint256 amountWithdrawn
    );

    constructor() {}

    /// @notice This function gets the committment details
    /// @dev getter for habit structure data
    /// @param habitId The hash of user address, goal title and habit committment
    /// @return habit Committment details of the user
    function getHabit(uint256 habitId) external view returns (HabitCore memory habit) {
        return _habits[habitId];
    }

    /// @notice This function gets the committment details using user's address
    /// @dev getter for habit structure based on address
    /// @param user The habit creator's address
    /// @return userHabits the habits of the user
    function getUserHabits(address user) external view returns (uint256[] memory userHabits) {
        return _userHabits[user];
    }

    function getUserHabitNonce(address user) external view returns (uint256 userHabitLength) {
        return _userHabits[user].length + 1;
    }

    function hashHabit(
        address user,
        bytes32 titleHash,
        bytes32 committmentHash
    ) public pure virtual returns (uint256) {
        return uint256(keccak256(abi.encode(user, titleHash, committmentHash)));
    }

    function createHabit(
        string memory title,
        string memory committment,
        uint256 totalReports,
        uint256 interval
    ) public payable {
        uint habitId = hashHabit(
            msg.sender,
            keccak256(bytes(title)),
            keccak256(bytes(committment))
        );
        HabitCore storage habit = _habits[habitId];
        require(habit.totalAmount == 0, "Habit with this id already exists");
        require(totalReports > 0, "totalReports should be greater than 0");
        require(msg.value >= totalReports, "Amount should be greater than total no. of reports");
        require(interval > 0, "Interval should be greater than 0");

        habit.user = payable(msg.sender);
        habit.startTime = block.timestamp;
        habit.totalAmount = msg.value;
        habit.totalReports = totalReports;
        habit.interval = interval;
        habit.title = title;
        habit.committment = committment;

        _userHabits[habit.user].push(habitId);

        totalAmountDeposited += msg.value;

        emit HabitCreated(habit.user, habitId, habit.startTime, msg.value, totalReports, interval);
    }

    function report(
        uint256 habitId,
        string calldata journalEntry,
        string calldata proofUrl
    ) public payable {
        HabitCore storage habit = _habits[habitId];
        require(habit.totalAmount != 0, "Habit with this id does not exists");
        require(habit.user == msg.sender, "Invalid user");
        require(habit.ended == false, "Habit is completed");

        // check if the user is doing it in the slot
        uint timeDiff = block.timestamp - habit.startTime;
        uint numSlots = timeDiff / habit.interval;
        uint totalUpdatedCount = habit.successCount + habit.missedCount;
        require(totalUpdatedCount <= numSlots, "Already submitted report for this slot");
        if (numSlots >= habit.totalReports) {
            habit.missedCount = habit.totalReports - habit.successCount;
        } else {
            if (numSlots > habit.successCount) {
                habit.missedCount = numSlots - habit.successCount;
            }
            habit.successCount++;
        }

        if ((habit.successCount + habit.missedCount) == habit.totalReports) {
            habit.ended = true;
            uint amountToSend = (habit.totalAmount * habit.successCount) / habit.totalReports;
            if (amountToSend > 0) {
                habit.user.transfer(amountToSend);
                totalAmountWithdrawn += amountToSend;
                emit HabitCompleted(
                    habitId,
                    habit.user,
                    habit.startTime,
                    habit.totalAmount,
                    habit.totalReports,
                    habit.successCount,
                    habit.missedCount,
                    amountToSend
                );
            }
        }
        emit HabitReported(
            habitId,
            habit.user,
            journalEntry,
            proofUrl,
            block.timestamp,
            habit.successCount,
            habit.missedCount
        );
    }
}