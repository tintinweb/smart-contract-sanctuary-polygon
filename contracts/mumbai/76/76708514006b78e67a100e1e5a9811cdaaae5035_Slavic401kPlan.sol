/**
 *Submitted for verification at polygonscan.com on 2023-05-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Slavic401kPlan {
    // Declare the owner of the contract
    address public owner;

    // Declare the monthly premium amount in wei (1 ether = 10^18 wei)
    uint256 public monthlyPremium = 0.1 ether;

    // Declare the total balance of the 401k plan
    uint256 public balance = 0;

    // Declare the date of the last payment for each participant
    mapping(address => uint256) public lastPaymentDate;

    // Declare the vesting period for the 401k plan (in seconds)
    uint256 public vestingPeriod = 365 days;

    // Declare the list of participants in the 401k plan
    address[] public participants;

    // Declare the constructor
    constructor() {
        owner = msg.sender;
    }

    // Declare the function to enroll in the 401k plan
    function enroll(address _address) public {
        require(
            msg.sender == owner,
            "Only the owner can remove beneficiaries."
        );
        require(!isParticipant(_address), "Participant is already enrolled");
        participants.push(_address);
    }

    // Declare the function to check if an address is a participant
    function isParticipant(address _address) public view returns (bool) {
        for (uint i = 0; i < participants.length; i++) {
            if (participants[i] == _address) {
                return true;
            }
        }
        return false;
    }

    // Declare the function to make a monthly premium payment
    function makeMonthlyPayment() public payable {
        require(
            isParticipant(msg.sender),
            "Only participants can make payments"
        );
        require(msg.value == monthlyPremium, "Incorrect payment amount");
        require(
            block.timestamp >= lastPaymentDate[msg.sender] + 30 days,
            "Payment already made this month"
        );
        lastPaymentDate[msg.sender] = block.timestamp;
        balance += msg.value;
    }

    // Declare the function to check the balance of the 401k plan
    function getBalance() public view returns (uint256) {
        return balance;
    }

    // Declare the function to withdraw the vested amount from the 401k plan
    function withdraw() public {
        require(isParticipant(msg.sender), "Only participants can withdraw");
        require(
            block.timestamp >= lastPaymentDate[msg.sender] + vestingPeriod,
            "Vesting period not over yet"
        );
        uint256 vestedAmount = balance / participants.length;
        balance -= vestedAmount;
        payable(msg.sender).transfer(vestedAmount);
    }

    // Declare the function to check the balance of a participant
    function getParticipantBalance(
        address _participant
    ) public view returns (uint256) {
        require(isParticipant(_participant), "Address is not a participant");
        uint256 participantBalance = balance / participants.length;
        uint256 vestedAmount = 0;
        if (block.timestamp >= lastPaymentDate[_participant] + vestingPeriod) {
            vestedAmount = participantBalance;
        } else {
            uint256 elapsedTime = block.timestamp -
                lastPaymentDate[_participant];
            uint256 vestingPercentage = (elapsedTime * 100) / vestingPeriod;
            vestedAmount = (participantBalance * vestingPercentage) / 100;
        }
        return vestedAmount;
    }
}