// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./Authenticators.sol";

contract AuthVoting is Authenticators{
    struct Ballot {
        uint proposalIndex;
        uint votesFor;
        uint votesAgainst;
        uint totalVotes;
        address[] votersFor;
        address[] votersAgainst;
        // mapping(address => bool) voted; // mappings don't work in structs and arrays anymore!
        bool ballotVerdict;
    }

    Ballot[] public ballots;

    function createBallot(uint proposalIndex) public virtual{
            Ballot memory newBallot = Ballot({
            proposalIndex: proposalIndex,
            votesFor: 0,
            votesAgainst: 0,
            totalVotes: 0,
            votersFor: new address[](0),
            votersAgainst: new address[](0),
            ballotVerdict: false
        });

        ballots.push(newBallot);
        }

    function voteFor(address payable authenticator, uint index) public virtual{
        require(verifiedAuthenticator(authenticator));
        // require(ballots[index].voted[authenticator] != true, "You have already voted");
        Ballot storage ballot = ballots[index];

        ballot.votesFor++;
        ballot.votersFor.push(authenticator);
        // ballot.voted[authenticator] = true;

        if (ballot.totalVotes >= 2 && ballot.votesFor >= ballot.votesAgainst+1) {
            authenticate(index, false);
        }
    }

    function voteAgainst(address payable authenticator, uint index) public virtual{
        require(verifiedAuthenticator(authenticator));
        // require(ballots[index].voted[authenticator] != true, "You have already voted");
        Ballot storage ballot = ballots[index];

        ballot.votesAgainst++;
        ballot.votersAgainst.push(authenticator);
        // ballot.voted[authenticator] = true;

        if (ballot.totalVotes >= 2 && ballot.votesAgainst >= ballot.votesFor+1) {
            authenticate(index, false);
        }
    }

    function verifiedAuthenticator(address payable authenticator) public view virtual returns(bool){
        return isAuthenticator[authenticator];
    }

    // Only allow this statement to be carried out when there are enough votes in favor of 
    // authenticating. Can be called automatically when the condition is met. 
    function authenticate(uint index, bool verdict) public virtual{
        ballots[index].ballotVerdict = verdict;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


// Manages a directory of all authenticators 
// Also sets rules for adding and removing an authenticator
contract Authenticators {
    struct Authenticator {
        address authenticatorAddress;
        uint weight;
    }

    Authenticator[] public authenticators;
    mapping(address => bool) public isAuthenticator;

    function registerAuthenticator(address payable _authenticatorAddress) public {
        Authenticator memory newAuthenticator = Authenticator({
            authenticatorAddress: _authenticatorAddress,
            weight: 10
        });

        authenticators.push(newAuthenticator);
        isAuthenticator[_authenticatorAddress] = true;
    }

    function removeAuthenticator() public {
        // removes authenticators with weight less than 1
    }
}