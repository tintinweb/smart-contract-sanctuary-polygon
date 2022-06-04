/**
 *Submitted for verification at polygonscan.com on 2022-06-03
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Yagmi {
    uint256 public goalId = 0;

    struct Goal {
        uint256 goalId;
        string goalTitle;
        string goalDesc;
        uint createdAt;
        uint updatedAt;
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
        uint createdAt,
        uint updatedAt,
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
        uint createdAt,
        uint updatedAt,
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
        uint createdAt,
        uint updatedAt,
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
        uint createdAt,
        uint updatedAt,
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
        uint createdAt,
        uint updatedAt,
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
        uint createdAt,
        uint updatedAt,
        address setterAddr,
        address partnerAddr,
        uint amount,
        uint dueDate,
        string powUrl,
        string powStatus
    );

    event cannotClaim (
        uint256 goalId,
        string goalTitle,
        string goalDesc,
        uint createdAt,
        uint updatedAt,
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

        uint curTime = block.timestamp;

        // Set min goal amount
        // Detect min fee from amount
        // Add withdraw function

        Goal memory newGoal = Goal({
            goalId: goalId,
            goalTitle: _goalTitle,
            goalDesc: _goalTitle,
            createdAt: curTime,
            updatedAt: curTime,
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
            curTime,
            curTime,
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

        require(keccak256(abi.encodePacked(goal.powStatus)) == keccak256(abi.encodePacked("POW_SENT")) 
            || keccak256(abi.encodePacked(goal.powStatus)) == keccak256(abi.encodePacked("POW_PENDING")), 
            "The goal is already completed or POW is not submitted.");
        
        bytes memory powUrlBytes = bytes(_powUrl);
        require(powUrlBytes.length > 0, "Enter valid pow url.");

        uint curTime = block.timestamp;
        goals[_goalId].powUrl = _powUrl;
        goals[_goalId].powStatus = "POW_SENT";
        goals[_goalId].updatedAt = curTime;

        emit powUpdated(
            _goalId,
            goal.goalTitle,
            goal.goalDesc,
            goal.createdAt,
            curTime,
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

        // If user tries to approve/reject goal to get money which is already completed.
        require(keccak256(abi.encodePacked(goal.powStatus)) == keccak256(abi.encodePacked("POW_SENT")), "The goal is already completed or POW is not submitted.");
        
        if(block.timestamp <= (goal.dueDate * 1 days)) {

            if(_isPowApproved) {
                // valid case
                // Send money to goal setter

                uint curTime = block.timestamp;
                goals[_goalId].powStatus = "POW_APPROVED";
                goals[_goalId].updatedAt = curTime;

                goal.setterAddr.transfer(goal.amount);

                emit powApproved(
                    _goalId,
                    goal.goalTitle,
                    goal.goalDesc,
                    goal.createdAt,
                    curTime,
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

                uint curTime = block.timestamp;
                goals[_goalId].powStatus = "POW_REJECTED";
                goals[_goalId].updatedAt = curTime;

                goal.partnerAddr.transfer(goal.amount);

                emit powRejected(
                    _goalId,
                    goal.goalTitle,
                    goal.goalDesc,
                    goal.createdAt,
                    curTime,
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

            // POW is present
            if(keccak256(abi.encodePacked(goal.powStatus)) == keccak256(abi.encodePacked("POW_SENT"))) {
                // POW_NOT_ATTENDED
                // Transfer amount to setter

                require(msg.sender == goal.setterAddr, "[POW_NOT_ATTENDED] Only the goal setter can claim the amount.");

                uint curTime = block.timestamp;
                goals[_goalId].updatedAt = curTime;

                goal.setterAddr.transfer(goal.amount);

                emit powNotAttended(
                    _goalId,
                    goal.goalTitle,
                    goal.goalDesc,
                    goal.createdAt,
                    curTime,
                    goal.setterAddr,
                    goal.partnerAddr,
                    goal.amount,
                    goal.dueDate,
                    goal.powUrl,
                    "POW_NOT_ATTENDED"
                );

            } else if(keccak256(abi.encodePacked(goal.powStatus)) == keccak256(abi.encodePacked("POW_PENDING"))) {
                // POW_DUE
                // Transfer amount to partner

                require(msg.sender == goal.partnerAddr, "[POW_DUE] Only the accountability partner can claim the amount.");

                uint curTime = block.timestamp;
                goals[_goalId].updatedAt = curTime;

                goal.partnerAddr.transfer(goal.amount);

                emit powDue(
                    _goalId,
                    goal.goalTitle,
                    goal.goalDesc,
                    goal.createdAt,
                    curTime,
                    goal.setterAddr,
                    goal.partnerAddr,
                    goal.amount,
                    goal.dueDate,
                    goal.powUrl,
                    "POW_DUE"
                );
            }
        } else {
            emit cannotClaim(
                    _goalId,
                    goal.goalTitle,
                    goal.goalDesc,
                    goal.createdAt,
                    block.timestamp,
                    goal.setterAddr,
                    goal.partnerAddr,
                    goal.amount,
                    goal.dueDate,
                    goal.powUrl,
                    "CANNOT_CLAIM"
                );
        }
    }
}