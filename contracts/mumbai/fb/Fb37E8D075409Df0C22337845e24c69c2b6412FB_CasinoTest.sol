//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract CasinoTest {
    struct betProposed {
        address sideA;
        uint256 value;
        uint256 placedAt;
        bool accepted;
        bool settled;
        string name;
        uint256 id;
        uint256 commitment;
    }

    struct betAccepted {
        address sideB;
        uint256 acceptedAt;
        uint256 randomB;
        uint256 id;
        uint256 value;
        string name;
        bool settled;
    }

    struct settledBet {
        uint256 _commitment;
        address winner;
        address loser;
        uint256 value;
        string name;
    }


    uint256 proposeId;
    uint256 acceptId;
    uint256 settledId;

    constructor(){
        proposeId=0;
        acceptId=0;
        settledId=0;
    }

    betProposed[] proposedArray;
    betAccepted[] acceptedArray;
    settledBet[] settledArray;
    // Proposed bets, keyed by the commitment value
    mapping(uint256 => betProposed) public proposedBet;
    // Accepted bets, also keyed by commitment value
    mapping(uint256 => betAccepted) public acceptedBet;

    event BetProposed(uint256 indexed _commitment, uint256 value, string name);
    event BetAccepted(uint256 indexed _commitment, address indexed _sideA);

    // mapping (uint256 => betProposed[]) public proposedArray;
    event BetSettled(
        uint256 indexed _commitment,
        address winner,
        address loser,
        uint256 value
    );

    
    function getProposedBets() public view returns (betProposed[] memory) {
        return proposedArray;
    }


    function getMyProposedBets() public view returns (betProposed[] memory){
        uint256 userBets = 0;
        for (uint i = 0; i < proposeId; i++){
            if(proposedArray[i].sideA == msg.sender){
                userBets += 1;
            }
        }
        betProposed[] memory myBets = new betProposed[](userBets);
        uint myBetsIndex = 0;
        for (uint i = 0; i < proposeId; i++){
            if(proposedArray[i].sideA == msg.sender){
                myBets[myBetsIndex] = proposedArray[i];
                myBetsIndex += 1;
            }
        }
        return myBets;
    }

    function getMyAcceptedBets() public view returns(betAccepted[] memory){
        uint256 userBets = 0;
        for (uint i = 0; i < acceptId; i++){
            if(acceptedArray[i].sideB == msg.sender){
                userBets += 1;
            }
        }
        betAccepted[] memory myBets = new betAccepted[](userBets);
        uint myBetsIndex = 0;
        for (uint i = 0; i < acceptId; i++){
            if(acceptedArray[i].sideB == msg.sender){
                myBets[myBetsIndex] = acceptedArray[i];
                myBetsIndex += 1;
            }
        }
        return myBets;
    }

    function getMySettedBets() public view returns(settledBet[] memory){
        uint256 userBets = 0;
        for (uint i = 0; i < settledId; i++){
             if(settledArray[i].winner == msg.sender || settledArray[i].loser == msg.sender){
                userBets += 1;
            }
        }
        settledBet[] memory myBets = new settledBet[](userBets);
        uint myBetsIndex = 0;
        for (uint i = 0; i < settledId; i++){
             if(settledArray[i].winner == msg.sender || settledArray[i].loser == msg.sender){
                myBets[myBetsIndex] = settledArray[i];
                myBetsIndex += 1;
            }
        }
        return myBets;
    }

    function ProposedBet(uint256 _commitment, string memory name) external {
        proposedBet[_commitment].sideA = msg.sender;
        proposedBet[_commitment].value = 1;
        proposedBet[_commitment].placedAt = block.timestamp;
        proposedBet[_commitment].name = name;
        proposedBet[_commitment].id = proposeId;

        proposedArray.push(betProposed(
            msg.sender,
            1,
            block.timestamp,
            false,
            false,
            name,
            proposeId,
            _commitment
        ));
        proposeId = proposeId + 1;

        emit BetProposed(_commitment, 1, name);
    }

    function AccetedBet(uint256 _commitment, uint256 _random) external {
        acceptedBet[_commitment].sideB = msg.sender;
        acceptedBet[_commitment].acceptedAt = block.timestamp;
        acceptedBet[_commitment].randomB = _random;
        proposedBet[_commitment].accepted = true;
        acceptedBet[_commitment].value = proposedBet[_commitment].value;
        acceptedBet[_commitment].name = proposedBet[_commitment].name;
        acceptedBet[_commitment].id = acceptId;
        acceptedBet[_commitment].settled = false;
        uint256 position = proposedBet[_commitment].id;
        proposedArray[position].accepted = true;
        acceptedArray.push(betAccepted(
            msg.sender,
            block.timestamp,
            _random,
            acceptId,
            proposedBet[_commitment].value,
            proposedBet[_commitment].name,
            false
        ));
        
        // acceptedArray[]
        emit BetAccepted(_commitment, proposedBet[_commitment].sideA);
    }

    // Called by sideA to reveal their random value and conclude the bet
    function reveal(uint256 _random) external returns (address winner){
        
        uint256 _commitment = uint256(keccak256(abi.encodePacked(_random)));
        require(
            proposedBet[_commitment].sideA == msg.sender,
            "Not a bet you placed or wrong value"
        );
        require(
            proposedBet[_commitment].accepted,
            "Bet has not been accepted yet"
        );
        //To reduce the risk of accidentally sending ETH to addresses where it will get stuck,
        //Solidity only permits us to send it to addresses of the type address payable
        address payable _sideA = payable(msg.sender);
        address payable _sideB = payable(acceptedBet[_commitment].sideB);

        uint256 _agreedRandom = _random ^ acceptedBet[_commitment].randomB;
        uint256 _value = proposedBet[_commitment].value;
        string memory name = proposedBet[_commitment].name;
        uint256 purposeIndex = proposedBet[_commitment].id;
        uint256 acceptIndex = acceptedBet[_commitment].id;
        proposedArray[purposeIndex].settled = true;
        acceptedArray[acceptIndex].settled = true;


        
        delete proposedBet[_commitment];
        delete acceptedBet[_commitment];

        if (_agreedRandom % 2 == 0) {
            _sideA.transfer(2 * _value);
            emit BetSettled(_commitment, _sideA, _sideB, _value);
            settledArray.push(settledBet(
                _commitment,
                _sideA,
                _sideB,
                _value,
                name
            ));
            settledId+=1;
            return _sideA; 
        } else {
            _sideB.transfer(2 * _value);
            emit BetSettled(_commitment, _sideB, _sideA, _value);
            settledArray.push(settledBet(
                _commitment,
                _sideB,
                _sideA,
                _value,
                name
            ));
            settledId+=1;
            return _sideB; 
        }
        
       
    }
}