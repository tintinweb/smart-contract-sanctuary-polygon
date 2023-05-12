// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/**
* @title Challenge
* @dev Challenge for challengeproject
* @custom:dev-run-script scripts/deploy_with_ethers.ts
*/
contract Challenge {
    // Participant data
    struct Participant {
        address wallet;
        uint256 score;
    }

    // owner of this contract
    address private owner;
    uint256 private maxParticipants = 10;
    // entry fee to challenge
    uint256 private entryFee;
    // challenge state
    bool private isFinished = false;

    // store participant addresses 
    address[] private participantWallets;
    // store participants data
    mapping(address => Participant) private participants;

    event ParticipantJoined(address _wallet, uint _amount);
    event ChallengeFinished();
    event ParticipantScoreUpdated(address _wallet, uint _amount);

    // constructor is called during contract deployment 
    constructor(uint256 _entryFee, uint256 _maxParticipants) {
        // assign the address that created contract
        owner = payable(msg.sender);
        entryFee = _entryFee;
        maxParticipants = _maxParticipants;
    }

    //create a modifier that the msg.sender must be the owner modifier 
    modifier onlyOwner {
        require(msg.sender == owner, 'Only the owner can call this function.');
        _;
    }

    //create a modifier that check challenge is full
    modifier challengeMaxPartiicpants {
        require(participantWallets.length < maxParticipants, "Challenge is full.");
        _;
    }

    // create a modifier that checks if participant not joined to challenge
    modifier participantNotJoined {
        require(participants[msg.sender].wallet == address(0), 'Participant already joined');
        _;
    }

        // create a modifier that checks if participant already joined to challenge
    modifier participantJoined {
        require(participants[msg.sender].wallet != address(0), 'Participant not joined');
        _;
    }

    // create a modifier that checks if the challenge is finished
    modifier challengeIsActive {
        require(isFinished == false, "Challenge is finished.");
        _;
    }

        // create a modifier that checks if the challenge is finished
    modifier senderIsAddress {
        require(msg.sender != address(0), 'Invalid wallet address');
        _;
    }

    // join to challenge
    function join() public payable senderIsAddress challengeIsActive challengeMaxPartiicpants participantNotJoined {
        require(msg.value == 0.01 ether, "Invalid entry fee amount");
        participants[msg.sender].wallet = msg.sender;
        participants[msg.sender].score = 0;
        participantWallets.push(msg.sender);
        emit ParticipantJoined(msg.sender, msg.value);
    }

    // called at the end of the challenge
    function award() public senderIsAddress onlyOwner challengeIsActive {
        // create a temporary array to hold the participants and their scores
        Participant[] memory sortedParticipants = new Participant[](participantWallets.length);
        for (uint256 i = 0; i < participantWallets.length; i++) {
            address participantWallet = participantWallets[i];
            sortedParticipants[i] = Participant(participantWallet, participants[participantWallet].score);
        }

        // sort the array of participants based on their scores
        for (uint256 i = 0; i < sortedParticipants.length - 1; i++) {
            for (uint256 j = i + 1; j < sortedParticipants.length; j++) {
                if (sortedParticipants[i].score < sortedParticipants[j].score) {
                    Participant memory temp = sortedParticipants[i];
                    sortedParticipants[i] = sortedParticipants[j];
                    sortedParticipants[j] = temp;
                }
            }
        }

        // transfer rewards to the participants
        for (uint256 i = 0; i < sortedParticipants.length; i++) {
            (bool success, ) = payable(sortedParticipants[i].wallet).call{value: this.getReward()}("");
            require(success, "Failed to send rewards");
        }
        isFinished = true;
        emit ChallengeFinished();
    }

    // set score for participant
    function setScore(address _wallet, uint256 score) public senderIsAddress onlyOwner challengeIsActive participantJoined {
        require(_wallet != address(0), 'Invalid wallet address');
        participants[_wallet].score = score;
        emit ParticipantScoreUpdated(participants[_wallet].wallet, participants[_wallet].score);
    }

    // get max participants
    function getMaxParticipants() public view returns (uint256) {
        return maxParticipants;
    }

    // get entry fee
    function getEntryFee() public view returns (uint256) {
        return entryFee;
    }

    // get reward
    function getReward() public view returns (uint256) {
        return address(this).balance/participantWallets.length;
    }

    // get participant
    function getParticipant(address _wallet) public view senderIsAddress returns (Participant memory) {
        return participants[_wallet];
    }

    // get participants
    function getParticipants() public view returns (Participant[] memory) {
        Participant[] memory sortedParticipants = new Participant[](participantWallets.length);
        for (uint256 i = 0; i < participantWallets.length; i++) {
            address participantWallet = participantWallets[i];
            sortedParticipants[i] = Participant(participantWallet, participants[participantWallet].score);
        }
        return sortedParticipants;
    }

    // get wallets
    function getWallets() public view returns (address[] memory) {
        return participantWallets;
    }

    // get wallets
    function getChallengeIsCompleted() public view returns (bool) {
        return isFinished;
    }

    // get wallets
    function getOwner() public view returns (address) {
        return owner;
    }
}