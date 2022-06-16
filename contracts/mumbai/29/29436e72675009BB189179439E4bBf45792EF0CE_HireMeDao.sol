//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IopenSeaContract {
    function balanceOf(address, uint256) external view returns (uint256);
}

contract HireMeDao {
    address public owner;
    uint256 nextPollId;
    uint256[] public votingTokenIds;
    IopenSeaContract openSeaContract;

    constructor() {
        owner = msg.sender;
        nextPollId = 1;
        openSeaContract = IopenSeaContract(
            0x2953399124F0cBB46d2CbACD8A89cF0599974963
        );
        votingTokenIds = [
            71876655463953535015688948417827604262466894376888337717173686516607765970945
        ];
    }

    struct poll {
        uint256 id;
        string description;
        uint256 deadline;
        uint256 votesFor;
        uint256 votesAgainst;
        address[] voters;
        uint256 maxVotes;
        mapping(address => bool) hasVoted;
        bool exists;
        bool countConducted;
        bool passed;
    }

    mapping(uint256 => poll) public Polls;

    event pollCreated(
        uint256 id,
        string description,
        uint256 maxVotes,
        address proposer
    );

    event newVote(
        uint256 votesUp,
        uint256 votesDown,
        address voter,
        uint256 proposal,
        bool votedFor
    );

    event proposalCount(uint256 id, bool passed);

    function createProposal(
        string memory _description,
        address[] memory _voters
    ) public canCreatePoll(msg.sender) {
        poll storage newPoll = Polls[nextPollId];
        newPoll.id = nextPollId;
        newPoll.exists = true;
        newPoll.description = _description;
        newPoll.deadline = block.number + 100;
        newPoll.voters = _voters;
        newPoll.maxVotes = _voters.length;

        emit pollCreated(nextPollId, _description, _voters.length, msg.sender);
        nextPollId++;
    }

    function voteOnPoll(uint256 _id, bool _vote)
        public
        canVote(_id, msg.sender)
    {
        require(Polls[_id].exists, "This Poll does not exist");
        require(!Polls[_id].hasVoted[msg.sender], "You already voted");
        require(
            block.number <= Polls[_id].deadline,
            "The deadline has passed for this Poll"
        );

        poll storage p = Polls[_id];

        if (_vote) {
            p.votesFor++;
        } else {
            p.votesAgainst++;
        }

        p.hasVoted[msg.sender] = true;

        emit newVote(p.votesFor, p.votesAgainst, msg.sender, _id, _vote);
    }

    function countVotes(uint256 _id) public onlyOwner {
        require(Polls[_id].exists, "This Proposal does not exist");
        require(block.number > Polls[_id].deadline, "Voting has not concluded");
        require(!Polls[_id].countConducted, "Count already conducted");

        poll storage p = Polls[_id];

        if (Polls[_id].votesAgainst < Polls[_id].votesFor) {
            p.passed = true;
        }

        p.countConducted = true;

        emit proposalCount(_id, p.passed);
    }

    function addVotingToken(uint256 _tokenId) public onlyOwner {
        votingTokenIds.push(_tokenId);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner Can Do This");
        _;
    }

    // maybe make this a modifier
    modifier canCreatePoll(address _proposer) {
        bool canCreate = false;
        for (uint256 i = 0; i < votingTokenIds.length; i++) {
            if (openSeaContract.balanceOf(_proposer, votingTokenIds[i]) >= 1) {
                canCreate = true;
            }
        }
        require(canCreate == true, "You Can Not Create Poll");
        _;
    }

    //maybe make this a modifier and just update hasVoted
    modifier canVote(uint256 _id, address _voter) {
        bool isVoter = false;
        for (uint256 i = 0; i < Polls[_id].voters.length; i++) {
            if (Polls[_id].voters[i] == _voter) {
                isVoter = true;
            }
        }
        require(isVoter == true, "You Can Not Vote");
        _;
    }
}