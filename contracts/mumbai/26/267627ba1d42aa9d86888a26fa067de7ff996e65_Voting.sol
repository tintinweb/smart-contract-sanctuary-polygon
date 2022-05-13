// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Voting {

    enum Gender {
        MALE,
        FEMALE,
        OTHER
    }

    enum PoliticalAffiliation {
        DEMOCRAT,
        REPUBLICAN,
        INDEPENDENT
    }

    enum Age {
        YOUNG,
        EIGHTEENPLUS,
        THIRTYPLUS,
        FIFTYPLUS,
        SEVENTYPLUS
    }

    enum ParentalStatus {
        KIDS,
        NOKIDS
    }

    mapping(Age => uint) private _agePoints;
    mapping(Gender => uint) private _genderPoints;
    mapping(ParentalStatus => uint) private _parentalStatusPoints;
    mapping(PoliticalAffiliation => uint) private _politicalAffiliationPoints;
    mapping(address => Voter) private _voters;

    uint[] public counterArray = new uint[](180);

    constructor() {
        _genderPoints[Gender.MALE] = 0;
        _genderPoints[Gender.FEMALE] = 3;
        _genderPoints[Gender.OTHER] = 6;

        _politicalAffiliationPoints[PoliticalAffiliation.DEMOCRAT] = 0;
        _politicalAffiliationPoints[PoliticalAffiliation.REPUBLICAN] = 1;
        _politicalAffiliationPoints[PoliticalAffiliation.INDEPENDENT] = 2;

        _parentalStatusPoints[ParentalStatus.KIDS] = 0;
        _parentalStatusPoints[ParentalStatus.NOKIDS] = 45;

        _agePoints[Age.YOUNG] = 0;
        _agePoints[Age.EIGHTEENPLUS] = 9;
        _agePoints[Age.THIRTYPLUS] = 18;
        _agePoints[Age.FIFTYPLUS] = 27;
        _agePoints[Age.SEVENTYPLUS] = 36;
    }

    struct Voter {
        address walletAddress;
        Gender gender;
        ParentalStatus parentalStatus;
        Age ageGroup;
        PoliticalAffiliation politicalAffiliation;
        uint index;
    }

    function recordVoter(Voter calldata voter) external {
        _voters[msg.sender] = voter;
    }

    function calculateIndex(Voter memory voter) internal view returns (uint) {
        uint index = 0;

        index += _genderPoints[voter.gender];
        index += _agePoints[voter.ageGroup];
        index += _parentalStatusPoints[voter.parentalStatus];
        index += _politicalAffiliationPoints[voter.politicalAffiliation];

        return index;
    }

    function castVote(Voter calldata newVoter, bool support) external {

        Voter memory voter = _voters[msg.sender];
        require(voter.walletAddress == address(0), "Already voted");
        
        uint index = calculateIndex(newVoter);
        if(support) {
            index += 90;
        }

        _voters[msg.sender] = newVoter;
        _voters[msg.sender].index = index;
        _voters[msg.sender].walletAddress = msg.sender;

        counterArray[index]++;
    }

    function getVoter(address wallet) external view returns (Voter memory) {
        return _voters[wallet];
    }
}