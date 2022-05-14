/**
 *Submitted for verification at polygonscan.com on 2022-05-13
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Yagmi {
    uint256 public goalId = 1;

    struct Goal {
        uint256 goalId;
        string goalTitle;
        string goalDesc;
        string setterAddr;
        string partnerAddr;
        uint256 amount;
        uint dueDate;
        string powUrl;
        string powStatus;
    }

    event goalCreated (
        uint256 goalId,
        string goalTitle,
        string goalDesc,
        string setterAddr,
        string partnerAddr,
        uint amount,
        uint dueDate,
        string powUrl,
        string powStatus
    );

    event powUpdated (
        uint256 goalId,
        string goalTitle,
        string goalDesc,
        string setterAddr,
        string partnerAddr,
        uint amount,
        uint dueDate,
        string powUrl,
        string powStatus
    );

    event powApproved (
        uint256 goalId,
        string goalTitle,
        string goalDesc,
        string setterAddr,
        string partnerAddr,
        uint amount,
        uint dueDate,
        string powUrl,
        string powStatus
    );

    event powRejected (
        uint256 goalId,
        string goalTitle,
        string goalDesc,
        string setterAddr,
        string partnerAddr,
        uint amount,
        uint dueDate,
        string powUrl,
        string powStatus
    );

    function getName() public pure returns (string memory) {
        string memory name = "";
        return name;
    }

    function addGoal (
        uint256 _goalId,
        string memory _goalTitle,
        string memory _goalDesc,
        string memory _setterAddr,
        string memory _partnerAddr,
        uint _amount,
        uint _dueDate,
        string memory _powUrl
        ) public {

        emit goalCreated(
            _goalId,
            _goalTitle,
            _goalDesc,
            _setterAddr,
            _partnerAddr,
            _amount,
            _dueDate,
            _powUrl,
            "POW_PENDING"
        );
        // This means goal is in POW_PENDING state

        goalId++;
    }

    function updatePow (
        uint256 _goalId,
        string memory _goalTitle,
        string memory _goalDesc,
        string memory _setterAddr,
        string memory _partnerAddr,
        uint _amount,
        uint _dueDate,
        string memory _powUrl
        ) public {

        emit powUpdated(
            _goalId,
            _goalTitle,
            _goalDesc,
            _setterAddr,
            _partnerAddr,
            _amount,
            _dueDate,
            _powUrl,
            "POW_SENT"
        );
        // This means goal is in POW_SENT state
    }

    function validateGoal (
        uint256 _goalId,
        string memory _goalTitle,
        string memory _goalDesc,
        string memory _setterAddr,
        string memory _partnerAddr,
        uint _amount,
        uint _dueDate,
        string memory _powUrl,
        bool _isPowApproved
        ) public payable {

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

        bytes memory powUrlBytes = bytes(_powUrl);
        // Partner approved the pow
        if(_isPowApproved) {
            if(powUrlBytes.length == 0 && block.timestamp <= (_dueDate * 1 days)) { 
                // valid case
                // Send money to goal setter
                emit powApproved(
                    _goalId,
                    _goalTitle,
                    _goalDesc,
                    _setterAddr,
                    _partnerAddr,
                    _amount,
                    _dueDate,
                    _powUrl,
                    "POW_APPORVED"
                );
            } else {
                // invalid case
            }
        } else {
            if(powUrlBytes.length == 0 && block.timestamp <= (_dueDate * 1 days)) { 
                // valid case
                // Send money to goal setter
                emit powRejected(
                    _goalId,
                    _goalTitle,
                    _goalDesc,
                    _setterAddr,
                    _partnerAddr,
                    _amount,
                    _dueDate,
                    _powUrl,
                    "POW_REJECTED"
                );
            } else {
                // invalid case
            }
        }

        // How to handle POW_DUE and POW_NOT_ATTENDED
    }
}