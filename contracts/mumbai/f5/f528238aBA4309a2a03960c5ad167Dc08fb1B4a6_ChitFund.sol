// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract ChitFund {
    IERC20 private usdt;

    constructor(address _usdtAddress) {
        usdt = IERC20(_usdtAddress);
    }

    struct Participant {
        address payable wallet;
        bool paid;
    }

    struct Chit {
        address creator;
        string title;
        string description;
        uint256 totalAmount;
        uint256 installmentAmount;
        uint256 installmentPeriod;
        uint256 numberOfParticipants;
        uint256 currentInstallment;
        uint256 deadline;
        Participant[] participants;
    }

    mapping(uint256 => Chit) public chits;

    uint256 public numberOfChits = 0;

    function createChit(
        string memory _title,
        string memory _description,
        uint256 _totalAmount,
        uint256 _installmentAmount,
        uint256 _installmentPeriod,
        uint256 _numberOfParticipants,
        uint256 _deadline
    ) public returns (uint256) {
        Chit storage chit = chits[numberOfChits];

        require(
            _totalAmount % _numberOfParticipants == 0,
            "Total amount must be divisible by number of participants"
        );
        require(
            _installmentAmount % _numberOfParticipants == 0,
            "Installment amount must be divisible by number of participants"
        );
        require(_deadline > block.timestamp, "Deadline must be in the future");

        chit.creator = msg.sender;
        chit.title = _title;
        chit.description = _description;
        chit.totalAmount = _totalAmount;
        chit.installmentAmount = _installmentAmount;
        chit.installmentPeriod = _installmentPeriod;
        chit.numberOfParticipants = _numberOfParticipants;
        chit.currentInstallment = 1;
        chit.deadline = _deadline;
        chit.participants.push(Participant(payable(msg.sender), false));

        numberOfChits++;

        return numberOfChits - 1;
    }

    function joinChit(uint256 _id) public {
        Chit storage chit = chits[_id]; 

        require(chit.currentInstallment == 1, "Chit has already started");

        uint256 participantIndex = chit.participants.length;

        if (participantIndex == chit.numberOfParticipants) {
            chit.currentInstallment++;
        }

        require(participantIndex < chit.numberOfParticipants, "Chit is full");

        chit.participants.push(Participant(payable(msg.sender), false));

    }

    function payInstallment(uint256 _id) public payable {
        Chit storage chit = chits[_id];

        require(msg.value == chit.installmentAmount, "Not valid amount");

        require(chit.currentInstallment > 1, "Chit has not started yet");
        require(block.timestamp <= chit.deadline, "Deadline has passed");

        uint256 participantIndex = getParticipantIndex(chit);

        require(
            participantIndex != chit.numberOfParticipants,
            "You are not a participant"
        );
        require(
            !chit.participants[participantIndex].paid,
            "Installment already paid"
        );


        require(
            usdt.transferFrom(
                msg.sender,
                address(this),
                chit.installmentAmount
            ),
            "Failed to transfer USDT"
        );

        chit.participants[participantIndex].paid = true;

        if (chit.currentInstallment == chit.numberOfParticipants + 1) {
            chit.currentInstallment = 1;
            chit.deadline = block.timestamp + chit.installmentPeriod;
        } else {
            chit.currentInstallment++;
        }

        (bool sent, ) = chit.creator.call{value: chit.installmentAmount}("");
        require(sent, "Failed to send payment to chit creator");
    }

    function getParticipantIndex(
        Chit storage chit
    ) private view returns (uint256) {
        for (uint256 i = 0; i < chit.participants.length; i++) {
            if (chit.participants[i].wallet == msg.sender) {
                return i;
            }
        }
        return chit.numberOfParticipants;
    }

    function withdraw(uint256 _id) public {

        Chit storage chit = chits[_id];

        uint256 participantIndex = getParticipantIndex(chit);

        require(
            participantIndex != chit.numberOfParticipants,
            "You are not a participant"
        );
        require(chit.currentInstallment == 1, "Chit is not complete");

        chit.participants[participantIndex].wallet.transfer(
            chit.totalAmount
        );
        chit.participants[participantIndex].paid = false;
    }

    function getParticipants(uint256 _id)
        public
        view
        returns (Participant[] memory)
    {
        Chit storage chit = chits[_id];

        return chit.participants;
    }
}