// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

contract Escrow {
    uint256 public contractActivatedTime;
    uint256 public timeToRaiseDispute;
    address public payer;
    address public payee;
    address public arbitrator;
    uint256 public amountPayable;
    uint256 public amountInEscrow;
    uint256 public arbitrationFee;
    bool public activatedByPayee = false;
    bool public activatedByPayer = false;
    bool public contractActivated = false;
    bool public disputeRaised = false;
    bool public contractSettled = false;
    string public contractLink = "";

    function init(
        address _payer,
        address _payee,
        address _arbitrator,
        uint256 _amountPayable,
        uint256 _arbitrationFee,
        uint256 _timeToRaiseDispute
    ) public {
        payee = _payee;
        payer = _payer;
        arbitrator = _arbitrator;
        amountPayable = _amountPayable;
        arbitrationFee = _arbitrationFee;
        timeToRaiseDispute = _timeToRaiseDispute;
    }

    function paymentByPayer() public payable {
        //check if amount paid is not less than amount payable
        require(
            msg.value >= (amountPayable + arbitrationFee) &&
                !contractActivated &&
                msg.sender == payer
        );
        uint256 amountPaid = msg.value;
        uint256 amountPayableByPayer = amountPayable + arbitrationFee;
        amountInEscrow = amountPaid;

        //if paid extra, return that amount
        if (amountPayableByPayer != amountPaid) {
            uint256 amountToReturn = amountPaid - amountPayableByPayer;
            payable(msg.sender).transfer(amountToReturn);
        }
        activatedByPayer = true;

        //if contract is activated by both, start the timer and activate the contract
        if (activatedByPayee == true) {
            contractActivatedTime = block.timestamp;
            contractActivated = true;
        }
    }

    function paymentByPayee() public payable {
        require(
            msg.value >= arbitrationFee &&
                !contractActivated &&
                msg.sender == payee
        );
        uint256 amountPaid = msg.value;

        //if paid extra, return that amount
        if (arbitrationFee != amountPaid) {
            uint256 amountToReturn = amountPaid - arbitrationFee;
            payable(msg.sender).transfer(amountToReturn);
        }
        activatedByPayee = true;

        //if contract is activated by both, start the timer and activate the contract
        if (activatedByPayer == true) {
            contractActivatedTime = block.timestamp;
            contractActivated = true;
        }
    }

    //withdraw money if other party is taking too much time or any other reason
    function withdrawByPayer() public {
        require(
            activatedByPayer &&
                contractActivated == false &&
                msg.sender == payer
        );
        activatedByPayer = true;
        uint256 amountPayableByPayer = amountPayable + arbitrationFee;
        payable(payer).transfer(amountPayableByPayer);
    }

    //withdraw money if other party is taking too much time or any other reason
    function withdrawByPayee() public {
        require(
            activatedByPayee &&
                contractActivated == false &&
                msg.sender == payer
        );
        activatedByPayee = true;
        payable(payer).transfer(arbitrationFee);
    }

    //called by payee if transaction occured successfully
    function settle() public {
        require(msg.sender == payer);
        payable(payer).transfer(arbitrationFee);
        uint256 amountPayableToPayee = arbitrationFee + amountPayable;
        payable(payee).transfer(amountPayableToPayee);
        contractSettled = true;
    }

    //called by anyone(generally payee if timeToRaiseDispute is passed
    function forceSettle() public {
        require(block.timestamp > (timeToRaiseDispute + contractActivatedTime));
        payable(payer).transfer(arbitrationFee);
        uint256 amountPayableToPayee = arbitrationFee + amountPayable;
        payable(payee).transfer(amountPayableToPayee);
        contractSettled = true;
    }

    function raiseDispute() public {
        require(msg.sender == payer);
        disputeRaised = true;
    }

    function payToPayee() public {
        require(msg.sender == arbitrator && disputeRaised == true);
        payable(arbitrator).transfer(arbitrationFee);
        uint256 amountPayableToPayee = arbitrationFee + amountPayable;
        payable(payee).transfer(amountPayableToPayee);
        contractSettled = true;
    }

    function payToPayer() public {
        require(msg.sender == arbitrator && disputeRaised == true);
        payable(arbitrator).transfer(arbitrationFee);
        uint256 amountPayableToPayer = arbitrationFee + amountPayable;
        payable(payer).transfer(amountPayableToPayer);
        contractSettled = true;
    }
}