//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract BettingGame {
    struct ProposedBet {
        address sideA; //the address that proposes the bet
        uint value; //the size of the bet in Wei, the smallest denomination of Ether
        uint placeBet; //the timestamp of the proposal
        bool accepted; //whether the proposal has been accepted
    }

    struct AcceptedBet {
        address sideB;
        uint acceptedAt;
        uint randomB;
    } // struct AcceptedBet

    mapping(uint => ProposedBet) public proposedBet;
    mapping(uint => AcceptedBet) public acceptedBet;

    //event to be emitted when the proposal is proposed
    event betProposed(
        uint indexed _commitment, //the index of the proposed bet
        uint value //the value of the proposed bet
    );

    //event to be emitted when the proposal is accepted
    event acceptedBetProposed(
        uint indexed _commitment, //the index of the accepted bet
        address indexed sideA //address of sideA
    );

    //event to be emitted when the bet is settled.
    event BetSettled(
        uint indexed _commitment,
        address winner,
        address loser,
        uint value
    );

    /* function to propose bet, external payable */
    // Called by sideA to start the process
    function proposeBet(uint _commitment) external payable {
        require(
            proposedBet[_commitment].value == 0,
            "there is already a bet on that commitment"
        ); //check if the bet is already in the process
        require(
            msg.value > 0,
            "you need to bet at least something in the process"
        );

        proposedBet[_commitment].sideA = msg.sender;
        proposedBet[_commitment].placeBet = block.timestamp;
        proposedBet[_commitment].value = msg.value;
        proposedBet[_commitment].accepted = false;

        emit betProposed(_commitment, msg.value);
    }

    /* function to accpete bet, external payable */
    function acceptBet(uint _commitment, uint random) external payable {
        //check if the bet is already accpeted
        require(
            !proposedBet[_commitment].accepted,
            "Bet has already been accepted"
        );

        //check sideA address is not equal to NULL, else message this is bet is not exist
        require(
            proposedBet[_commitment].sideA != address(0),
            "Bet doesn't exist"
        );

        //check if the attach token is equal to the prooposed Bet value
        require(
            proposedBet[_commitment].value == msg.value,
            "Need to bet the same amount as sideA"
        );

        //update the struct of accpetedBet
        acceptedBet[_commitment].sideB = msg.sender;
        acceptedBet[_commitment].acceptedAt = block.timestamp;
        acceptedBet[_commitment].randomB = random;
        proposedBet[_commitment].accepted = true;

        emit acceptedBetProposed(_commitment, msg.sender);
    }

    /* function to reveal random number, called by owner of proposed bet*/
    function reveal(uint _commitment, uint _random) external {
        //uint _commitment = uint256(keccak256(abi.encodePacked(_random)));
        address payable side_A = payable(msg.sender); //make the address able to receive eth
        address payable side_B = payable(acceptedBet[_commitment].sideB);

        uint _agreedRandom = _random ^ acceptedBet[_commitment].randomB;    //any number xor itself is zero

        uint value = proposedBet[_commitment].value;

        //valide the owner of the bet
        require(
            proposedBet[_commitment].sideA == msg.sender,
            "This is not the bet you placed!"
        );

        //validate wheather the bet has already been accepted
        // require(
        //     proposedBet[_commitment].accepted == true,
        //     "Bet has not been accepted yet!!"
        // );

        // Pay and emit an event
        if (_agreedRandom % 2 == 0) {   //any number xor itself is zero
            //sideA win
            side_A.transfer(2 * value);
            emit BetSettled(_commitment, side_A, side_B, value);
        } else {
            side_B.transfer(2 * value);
            emit BetSettled(_commitment, side_B, side_A, value);
        }

        // Cleanup
        delete proposedBet[_commitment];
        delete acceptedBet[_commitment];

    }
}