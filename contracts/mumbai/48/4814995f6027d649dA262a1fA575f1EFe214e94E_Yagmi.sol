/**
 *Submitted for verification at polygonscan.com on 2022-06-02
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Yagmi {
    uint256 public goalId = 0;

    struct Goal {
        uint256 goalId;
        string goalTitle;
        string goalDesc;
        address payable setterAddr;
        address payable partnerAddr;
        uint256 amount;
        uint dueDate;
        string powUrl;
        string powStatus;
    }

    mapping(uint256 => Goal) private goals;

    event goalCreated (
        uint256 goalId,
        string goalTitle,
        string goalDesc,
        address setterAddr,
        address partnerAddr,
        uint amount,
        uint dueDate,
        string powUrl,
        string powStatus
    );

    event powUpdated (
        uint256 goalId,
        string goalTitle,
        string goalDesc,
        address setterAddr,
        address partnerAddr,
        uint amount,
        uint dueDate,
        string powUrl,
        string powStatus
    );

    event powApproved (
        uint256 goalId,
        string goalTitle,
        string goalDesc,
        address setterAddr,
        address partnerAddr,
        uint amount,
        uint dueDate,
        string powUrl,
        string powStatus
    );

    event powRejected (
        uint256 goalId,
        string goalTitle,
        string goalDesc,
        address setterAddr,
        address partnerAddr,
        uint amount,
        uint dueDate,
        string powUrl,
        string powStatus
    );

    event powNotAttended (
        uint256 goalId,
        string goalTitle,
        string goalDesc,
        address setterAddr,
        address partnerAddr,
        uint amount,
        uint dueDate,
        string powUrl,
        string powStatus
    );

    event powDue (
        uint256 goalId,
        string goalTitle,
        string goalDesc,
        address setterAddr,
        address partnerAddr,
        uint amount,
        uint dueDate,
        string powUrl,
        string powStatus
    );

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getGoal(uint256 _goalId) public view returns (Goal memory) {
        return goals[_goalId];
    }

    function addGoal (
        string memory _goalTitle,
        string memory _goalDesc,
        address payable _setterAddr,
        address payable _partnerAddr,
        uint _amount,
        uint _dueDate
        ) public payable {

        Goal memory newGoal = Goal({
            goalId: goalId,
            goalTitle: _goalTitle,
            goalDesc: _goalTitle,
            setterAddr: _setterAddr,
            partnerAddr: _partnerAddr,
            amount: _amount,
            dueDate: _dueDate,
            powUrl: "",
            powStatus: "POW_PENDING"
        });

        goals[goalId] = newGoal;

        emit goalCreated(
            goalId,
            _goalTitle,
            _goalDesc,
            _setterAddr,
            _partnerAddr,
            _amount,
            _dueDate,
            "",
            "POW_PENDING"
        );
        // This means goal is in POW_PENDING state

        goalId++;
    }

    function updatePow (uint256 _goalId, string memory _powUrl) public {
        Goal memory goal = goals[_goalId];

        require(msg.sender == goal.setterAddr, "Only the goal setter can update the POW.");

        goals[_goalId].powUrl = _powUrl;

        emit powUpdated(
            _goalId,
            goal.goalTitle,
            goal.goalDesc,
            goal.setterAddr,
            goal.partnerAddr,
            goal.amount,
            goal.dueDate,
            _powUrl,
            "POW_SENT"
        );
        // This means goal is in POW_SENT state
    }

    function validateGoal (uint256 _goalId, bool _isPowApproved) public {

        // POW status       -   Condition               -   Amount status
        // ------------------------------------------------------------------------------------------
        // POW_PENDING      -   !pow && now <= due      -   on hold             (Based on setter action)
        // POW_SENT         -   pow && now <= due       -   on hold             (Based on setter action)

        // POW_APPROVED     -   pow && now <= due       -   to setter           (Based on partner action)
        // POW_REJECTED     -   pow && now <= due       -   to partner          (Based on partner action)

        // POW_DUE          -   !pow && now > due       -   to partner          (Determinded automatically)
        // POW_NOT_ATTENDED -   pow && now > due        -   to setter           (Determinded automatically)


        // if(pow && now <= dueDate) {
        //     if(_isPowApproved)
        //     // Partner approved the pow
        //     // Send money to goal setter
            
        //     else
        //     // Partner rejected the pow
        //     // Send money to partner
        // }

        Goal memory goal = goals[_goalId];

        require(msg.sender == goal.partnerAddr, "Only the accountability partner can accept/reject POW.");

        bytes memory powUrlBytes = bytes(goal.powUrl);
        if(powUrlBytes.length > 0 && block.timestamp <= (goal.dueDate * 1 days)) {

            if(_isPowApproved) {
                // valid case
                // Send money to goal setter

                goals[_goalId].powStatus = "POW_APPROVED";
                goal.setterAddr.transfer(goal.amount);

                emit powApproved(
                    _goalId,
                    goal.goalTitle,
                    goal.goalDesc,
                    goal.setterAddr,
                    goal.partnerAddr,
                    goal.amount,
                    goal.dueDate,
                    goal.powUrl,
                    "POW_APPROVED"
                );
            } else {
                // valid case
                // Send money to goal creator

                goals[_goalId].powStatus = "POW_REJECTED";
                goal.partnerAddr.transfer(goal.amount);

                emit powRejected(
                    _goalId,
                    goal.goalTitle,
                    goal.goalDesc,
                    goal.setterAddr,
                    goal.partnerAddr,
                    goal.amount,
                    goal.dueDate,
                    goal.powUrl,
                    "POW_REJECTED"
                );
            }
        }
    }

    function claimAmount (uint256 _goalId) public {

        Goal memory goal = goals[_goalId];

        // Due date has passed
        if(block.timestamp > (goal.dueDate * 1 days)) {
            bytes memory powUrlBytes = bytes(goal.powUrl);

            // POW is present
            if(powUrlBytes.length > 0) {
                // POW_NOT_ATTENDED
                // Transfer amount to setter

                require(msg.sender == goal.setterAddr, "[POW_NOT_ATTENDED] Only the goal setter can claim the amount.");

                goal.setterAddr.transfer(goal.amount);

                emit powNotAttended(
                    _goalId,
                    goal.goalTitle,
                    goal.goalDesc,
                    goal.setterAddr,
                    goal.partnerAddr,
                    goal.amount,
                    goal.dueDate,
                    goal.powUrl,
                    "POW_NOT_ATTENDED"
                );

            } else {
                // POW_DUE
                // Transfer amount to setter

                require(msg.sender == goal.partnerAddr, "[POW_DUE] Only the accountability partner can claim the amount.");

                goal.partnerAddr.transfer(goal.amount);

                emit powDue(
                    _goalId,
                    goal.goalTitle,
                    goal.goalDesc,
                    goal.setterAddr,
                    goal.partnerAddr,
                    goal.amount,
                    goal.dueDate,
                    goal.powUrl,
                    "POW_DUE"
                );
            }
        }
    }
}