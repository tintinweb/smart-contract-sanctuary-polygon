/**
 *Submitted for verification at polygonscan.com on 2022-07-15
*/

pragma solidity ^0.5.16;

// SPDX-License-Identifier: MIT

contract VotingContract {
    address owner;

    uint256 candidateCount = 0;

    uint256 voterCount = 0;

    bool start;

    string pollName;

    // Counter for total votes
    uint256 votesCasted = 0;

    // Counter for rejects
    uint256 rejectCount = 0;

    // Counter for abstains
    uint256 abstainCount = 0;

    // rejected string
    string rejected = "Candidates rejected";

    // Struct of a voter
    struct Voter {
        string name;
        string voterId; // Roll number or any other number
        address voterAddress; // Wallet address
        bool hasVoted;
    }

    mapping(address => Voter) public voterAddresses;

    // Struct of a candidate
    struct Candidate {
        uint256 candidateId;
        string name;
        string details; // manifesto or any other description
        uint256 voteCount; // the number of votes he got
    }

    mapping(uint256 => Candidate) public candidateDetails;

    uint256[] private candidateVote;

    // Modifier for letting only the owner to add candidates
    modifier onlyOwner() {
        require(msg.sender == owner, "only Owner");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    // function to add a new candidate
    function addCandidate(string memory _name, string memory _details)
        public
        onlyOwner
    {
        Candidate memory newCandidate = Candidate({
            candidateId: candidateCount,
            name: _name,
            details: _details,
            voteCount: 0
        });

        candidateDetails[candidateCount] = newCandidate;

        candidateCount += 1;
    }

    // function to add voter
    // only suitable for a local blockchain
    function manualAddVoter(
        string memory _name,
        string memory _voterId,
        address _voterAddress
    ) public onlyOwner {
        Voter memory newVoter = Voter({
            name: _name,
            voterId: _voterId,
            voterAddress: _voterAddress,
            hasVoted: false
        });

        voterAddresses[_voterAddress] = newVoter;

        voterCount += 1;
    }

    // A voting 'event' for logging the vote of the voter
    event Vote(uint256 indexed candidateId);

    // the actual voting
    // Take uint256 _candidateId as an array, where each index of the array would point to each post that is being put up
    // This would mean that candidateId in itself has to be a two dimensional array (of some type)
    // This way we can also build an array of some sort (obviously not manually) which will assign
    // each voter to the number and specific posts for which he/she can vote.
    // This will also create fluidity for the number of posts, i.e., we can have n number of posts
    // (Haven't thought about gas price yet)
    function vote(uint256 _candidateId) public {
        require(
            voterAddresses[msg.sender].voterAddress != address(0),
            "voter does not exist"
        );
        require(
            voterAddresses[msg.sender].hasVoted == false,
            "has already voted"
        );
        require(start == true, "not started");
        candidateDetails[_candidateId].voteCount += 1;
        voterAddresses[msg.sender].hasVoted = true;
        emit Vote(_candidateId);
        votesCasted += 1;
    }

    // event for emitting abstain
    event Abstain(string indexed abstain);

    // event for emitting reject
    event Reject(string indexed reject);

    // function for abstain
    function abstain() public {
        require(
            voterAddresses[msg.sender].voterAddress != address(0),
            "voter does not exist"
        );
        require(
            voterAddresses[msg.sender].hasVoted == false,
            "has already voted"
        );
        require(start == true, "not started");
        abstainCount += 1;
        voterAddresses[msg.sender].hasVoted = true;
        emit Abstain("Abstained");
        votesCasted += 1;
    }

    // function for reject
    function reject() public {
        require(
            voterAddresses[msg.sender].voterAddress != address(0),
            "voter does not exist"
        );
        require(
            voterAddresses[msg.sender].hasVoted == false,
            "has already voted"
        );
        require(start == true, "not started");
        rejectCount += 1;
        voterAddresses[msg.sender].hasVoted = true;
        emit Reject("Rejected");
        votesCasted += 1;
    }

    //voting function for meta transaction
    // function voteMeta(
    //     uint256 _candidateId,
    //     address userAddress,
    //     bytes32 r,
    //     bytes32 s,
    //     uint8 v
    // ) public {
    //     MetaTransaction memory metaTx = MetaTransaction({
    //         nonce: nonces[userAddress],
    //         from: userAddress
    //     });

    //     bytes32 digest = keccak256(
    //         abi.encodePacked(
    //             "\x19\x01",
    //             DOMAIN_SEPARATOR,
    //             keccak256(
    //                 abi.encode(
    //                     META_TRANSACTION_TYPEHASH,
    //                     metaTx.nonce,
    //                     metaTx.from
    //                 )
    //             )
    //         )
    //     );

    //     require(userAddress != address(0), "invalid-address-0");
    //     require(
    //         userAddress == ecrecover(digest, v, r, s),
    //         "invalid-signatures"
    //     );
    //     require(voterAddresses[userAddress].hasVoted == false);
    //     require(start == true);
    //     candidateDetails[_candidateId].voteCount += 1;
    //     voterAddresses[userAddress].hasVoted = true;
    //     nonces[userAddress]++;
    // }

    // onlyOwner function for starting the election
    function startElection() public onlyOwner {
        start = true;
    }

    // onlyOwner function to end election
    function endElection() public onlyOwner {
        start = false;
    }

    // public function to view election status (use this in dashboard)
    function electionStatus() public view returns (bool) {
        return (start);
    }

    // event for emitting election results
    // event Results(uint256 indexed candidateId);

    // function to view election results
    function electionResults() public returns (uint256) {
        require(start == false);
        uint256 winner = 0;
        if (rejectCount > (votesCasted - abstainCount) / 2) {
            winner = candidateCount + 1;
        } else {
            for (uint256 i = 0; i < candidateCount; i++) {
                candidateVote.push(candidateDetails[i].voteCount);
            }
            for (uint256 i = 1; i < candidateCount; i++) {
                if (candidateVote[i] > candidateVote[winner]) {
                    winner = i;
                }
            }
        }
        return winner;
        // emit Results(winner);
    }

    // event for emitting winner
    // event Winner(string indexed winner);

    function viewWinner() public returns (string memory) {
        uint256 winner = electionResults();
        if (winner == candidateCount + 1) {
            return rejected;
            // emit Winner(rejected);
        } else {
            return candidateDetails[winner].name;
            // emit Winner(candidateDetails[winner].name);
        }
    }

    // get total number of voters
    function getVoterCount() public view returns (uint256) {
        return voterCount;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function getCandidateCount() public view returns (uint256) {
        return candidateCount;
    }

    function totalVotesCasted() public view returns (uint256) {
        return votesCasted;
    }

    function totalAbstain() public view returns (uint256) {
        return abstainCount;
    }

    function totalReject() public view returns (uint256) {
        return rejectCount;
    }
}