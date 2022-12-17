// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract SportsChallenges {
    enum MatchStatus {
        PENDING,
        ACCEPTED,
        STARTED,
        ENDED
    }

    struct MatchChallenge {
        address team1;
        address team2;
        MatchStatus matchStatus;
        uint256 amount;
        address locationProvider;
    }

    // Match state variables
    MatchChallenge[] public matchChallenges; // Contiene el numero de desafios

    // EVENTS //
    // Evento que salta cuando el LocationProvider define el final
    event ChallengeResult(
        uint256 indexed MatchChallengeId,
        uint8 team1Result,
        uint8 team2Result
    );

    function createChallenge(address _team2, address _locationProvider)
        public
        payable
    {
        matchChallenges.push(
            MatchChallenge(
                msg.sender,
                _team2,
                MatchStatus.PENDING,
                msg.value,
                _locationProvider
            )
        );
    }

    // Acepta el desafio
    function acceptChallenge(uint256 _challengeId) public payable {
        require(
            msg.sender == matchChallenges[_challengeId].team2,
            "You're not the challenged team!"
        );
        require(
            msg.value >= matchChallenges[_challengeId].amount,
            "Haven't sent enough ETH!"
        );
        matchChallenges[_challengeId].matchStatus = MatchStatus.ACCEPTED;
    }

    function updateLocationProvider(
        uint256 _challengeId,
        address _newLocationProvider
    ) public {
        require(
            msg.sender == matchChallenges[_challengeId].team1 ||
                msg.sender == matchChallenges[_challengeId].team2,
            "You're not any of the teams!"
        );
        require(
            matchChallenges[_challengeId].matchStatus >= MatchStatus.STARTED,
            "Challenge has already been started!"
        );

        matchChallenges[_challengeId].locationProvider = _newLocationProvider;
    }

    function deleteChallenge(uint256 _challengeId) public {
        // Check
        require(
            matchChallenges[_challengeId].matchStatus < MatchStatus.STARTED,
            "Challenge has already been started or finished!"
        );
        require(
            msg.sender == matchChallenges[_challengeId].team1 ||
                msg.sender == matchChallenges[_challengeId].team2 ||
                msg.sender == matchChallenges[_challengeId].locationProvider,
            "You're not any of the teams nor the location provider!"
        );

        // Effect
        matchChallenges[_challengeId].matchStatus = MatchStatus.ENDED;
        // Interact
        (bool success, ) = payable(matchChallenges[_challengeId].team1).call{
            value: matchChallenges[_challengeId].amount
        }("");
        require(success == true, "ETH didn't send to team 1.");
        if (matchChallenges[_challengeId].matchStatus == MatchStatus.ACCEPTED) {
            (bool success2, ) = payable(matchChallenges[_challengeId].team2)
                .call{value: matchChallenges[_challengeId].amount}("");
            require(success2 == true, "ETH didn't send to team 2.");
        }
    }

    function startChallenge(uint256 _challengeId) public {
        // Check
        require(
            matchChallenges[_challengeId].matchStatus == MatchStatus.ACCEPTED,
            "Team2 hasn't accepted the challenge or it has already started!"
        );
        require(
            matchChallenges[_challengeId].locationProvider == msg.sender,
            "You're not the location provider!"
        );
        require(
            matchChallenges[_challengeId].team2 != address(0),
            "Lacking a team or match canceled"
        );

        // Effect
        matchChallenges[_challengeId].matchStatus = MatchStatus.ACCEPTED;
    }

    function completeChallenge(
        uint256 _challengeId,
        uint8 _team1Result,
        uint8 _team2Result
    ) public {
        // Check
        require(
            matchChallenges[_challengeId].matchStatus == MatchStatus.STARTED,
            "Challenge hasn't started!"
        );
        require(
            msg.sender == matchChallenges[_challengeId].locationProvider,
            "You must be the location provider to say who won"
        );
        // Effect
        matchChallenges[_challengeId].matchStatus = MatchStatus.ENDED;
        emit ChallengeResult(_challengeId, _team1Result, _team2Result);
        // Interact
        uint256 prizeMinusLocationFee = (matchChallenges[_challengeId].amount *
            2) - 0.002 ether;
        (bool successL, ) = payable(
            matchChallenges[_challengeId].locationProvider
        ).call{value: 0.0015 ether}("");
        require(successL == true, "ETH didn't send to location provider.");

        if (_team1Result > _team2Result) {
            (bool success, ) = payable(matchChallenges[_challengeId].team1)
                .call{value: prizeMinusLocationFee}("");
            require(success == true, "ETH didn't send to team 1.");
        }
        if (_team1Result < _team2Result) {
            (bool success, ) = payable(matchChallenges[_challengeId].team2)
                .call{value: prizeMinusLocationFee}("");
            require(success == true, "ETH didn't send to team 2.");
        }
        if (_team1Result == _team2Result) {
            (bool success, ) = payable(matchChallenges[_challengeId].team1)
                .call{value: (prizeMinusLocationFee / 2)}("");
            require(success == true, "ETH didn't send to team 1.");

            (bool success2, ) = payable(matchChallenges[_challengeId].team2)
                .call{value: (prizeMinusLocationFee / 2)}("");
            require(success2 == true, "ETH didn't send to team 2.");
        }
    }

    function viewMatchChallenge(uint256 _id)
        public
        view
        returns (address[3] memory)
    {
        address team1 = matchChallenges[_id].team1;
        address team2 = matchChallenges[_id].team2;
        address locationProvider = matchChallenges[_id].locationProvider;
        address[3] memory answer = [team1, team2, locationProvider];
        return answer;
    }

    function viewMatchStatus(uint256 _id) public view returns (MatchStatus) {
        return matchChallenges[_id].matchStatus;
    }

    function getAllMatches() public view returns (MatchChallenge[] memory) {
        return matchChallenges;
    }
}