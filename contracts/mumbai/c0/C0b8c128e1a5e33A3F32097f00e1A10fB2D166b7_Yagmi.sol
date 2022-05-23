/**
 *Submitted for verification at polygonscan.com on 2022-05-22
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Yagmi {
    uint256 public goalId = 0;

    struct Goal {
        uint256 goalId;
        string goalTitle;
        string goalDesc;
        address setterAddr;
        address partnerAddr;
        uint256 amount;
        uint dueDate;
        string powUrl;
        string powStatus;
    }

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

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function addGoal (
        string memory _goalTitle,
        string memory _goalDesc,
        address _setterAddr,
        address _partnerAddr,
        uint _amount,
        uint _dueDate
        ) public payable {

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

    function updatePow (
        uint256 _goalId,
        string memory _goalTitle,
        string memory _goalDesc,
        address _setterAddr,
        address _partnerAddr,
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
        address payable _setterAddr,
        address payable _partnerAddr,
        uint _amount,
        uint _dueDate,
        string memory _powUrl,
        bool _isPowApproved
        ) public {

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
            if(powUrlBytes.length > 0 && block.timestamp <= (_dueDate * 1 days)) { 
                // valid case
                // Send money to goal setter

                _setterAddr.transfer(_amount);

                emit powApproved(
                    _goalId,
                    _goalTitle,
                    _goalDesc,
                    _setterAddr,
                    _partnerAddr,
                    _amount,
                    _dueDate,
                    _powUrl,
                    "POW_APPROVED"
                );
            } else {
                // invalid case
            }
        } else {
            if(powUrlBytes.length > 0 && block.timestamp <= (_dueDate * 1 days)) { 
                // valid case
                // Send money to goal setter

                _partnerAddr.transfer(_amount);

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