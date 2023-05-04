/**
 *Submitted for verification at polygonscan.com on 2023-05-04
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.0 <0.9.0;

contract Contract {
    address payable public owner; // owner of contract
    uint public sessionSize; //max amount of participants
    uint public registrations; // current participants
    enum Network { POLYGON, MUMBAI } //POLYGON = 0, MUMBAI = 1 when deploying
    Network network;
    uint public ECU;
    uint public showUpFee;

    constructor(uint _sessionSize, Network _network) {
        owner = payable(msg.sender);
        sessionSize = _sessionSize;
        network = _network;

        if(network == Network.POLYGON) {
            ECU = 1e18; //1 ECU = 1 MATIC
        } else if(network == Network.MUMBAI) {
            ECU = 1e9; //1 ECU = 1 Wei
        }
        
        showUpFee = ECU / 2; //0.5 ECU
    }

    enum Status { NONE, REGISTERED, COMPLETED, PAID, REFUSED }

    struct Data {
        Status status;
        uint encryptedDecision;
        uint decision;
        uint key;
    }

    mapping(address => Data) public registry;

    // check status of address
    function isRegistered() external view returns(Status){
        return registry[msg.sender].status;
    }

    // check if there's room left to participate
    function hasFreeParticipantsSlots() external view returns(bool) {
        return registrations < sessionSize;
    }
    
    function registration() external {
        require(registry[msg.sender].status == Status.NONE, "Encumbered wallet address.");
        require(registrations <= sessionSize, "Maximum number of participants reached.");
        registry[msg.sender].status = Status.REGISTERED;
        registrations++;
        //payable(msg.sender).transfer(showUpFeeInWei);
    }

    //Saves the decision of the participant
    function recordDecision(uint _encryptedDecision) external {
        //Check if the user is registered
        require(registry[msg.sender].status == Status.REGISTERED, "Not registered or ended the experiment.");
        //Check if the contract has enough funds (otherwise the experiment has ended)
        //require(address(this).balance >= maxUnitsPerResponse * unitInWei, "Experiment has ended!");
        registry[msg.sender].encryptedDecision = _encryptedDecision;
        //mark them as registered and decision recorded
        registry[msg.sender].status = Status.COMPLETED;
    }

    //Returns the payout for each player based on their decisions
    function getPayoff(uint decision1, uint decision2) public pure returns(uint payoff1, uint payoff2) {
        if(decision1 == 0) {
            if(decision2 == 0) {
                return (3, 3); //both defect
            } else {
                return (10, 0); //p1 defect, p2 coop
            }
        } else {
            if(decision2 == 0) {
                return (0, 10); //p1 coop, p2 defect
            } else {
                return (5, 5); //both coop
            }
        }
    }

    //Sends the funds to the participants
    function send_money(address payable player1, uint key1, address payable player2, uint key2) external payable {
        //Only owner
        require(msg.sender == owner, "only owner");
        //Check that only participants that are registered, have made a decision and have not been paid yet get paid
        require(registry[player1].status == Status.COMPLETED && registry[player2].status == Status.COMPLETED, "participant not correctly registered or already payed");
        //get the decisions of the randomly matched participants
        registry[player1].decision = registry[player1].encryptedDecision - key1;
        registry[player2].decision = registry[player2].encryptedDecision - key2;
        //store the keys in the registry
        registry[player1].key = key1;
        registry[player2].key = key2;
        //get the payout for each participant
        (uint payoff1, uint payoff2) = getPayoff(registry[player1].decision, registry[player2].decision); //payoff[0] => player1 and payoff[1] => player2
        //send the funds
        player1.transfer(showUpFee + payoff1 * ECU);
        player2.transfer(showUpFee + payoff2 * ECU);
        //mark them as paid
        registry[player1].status = Status.PAID;
        registry[player2].status = Status.PAID;
    }

    //collect all funds
    function endOfExperiment() external {
        require(msg.sender == owner, "only owner");
        selfdestruct(owner);
    }

    // Accept any incoming amount
    receive () external payable {}

    //function to increase the session size
    function increaseSessionSizeBy(uint n) external {
        require(msg.sender == owner, "only owner");
        sessionSize += n;
    }

    function refuseParticipant(address _participant) external {
        require(msg.sender == owner, "only owner");
        registry[_participant].status = Status.REFUSED;
        //increase the session size by 1
        sessionSize += 1;
    }
}