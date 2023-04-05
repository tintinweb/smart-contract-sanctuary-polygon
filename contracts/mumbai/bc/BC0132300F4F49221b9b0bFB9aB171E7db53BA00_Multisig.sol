// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "./AccessControl.sol";

contract Multisig is AccessControl {
    struct Proposal {
        address recipient;
        uint256 value;
        string proposal;
        bool approved;
    }
    uint public proposalCount;
    uint public votesCount;
    mapping(uint256 => mapping(address => bool)) public hasVoted; //
    mapping(uint => Proposal) proposals; //0,1,2,3
    mapping(uint => uint) public votes;

    Proposal[] totalProposals;

    modifier onlyOwner(address _owner) {
        for (uint i = 0; i < owners.length; i++) {
            owners[i] == _owner;
            isOwner[_owner] = true;
        }
        require(isOwner[_owner] == true, "Only Owner can call this function");
        _;
    }

    modifier isApproved(uint _proposalCount) {
        require(
            totalProposals[_proposalCount].approved == false,
            "Already approved"
        );
        _;
    }

    modifier isVoted(uint _proposalCount, address _owner) {
        require(hasVoted[_proposalCount][_owner] == false, "Already Voted");
        _;
    }

    constructor(address[] memory _owners) AccessControl(_owners) {}

    fallback() external payable {
        if (msg.value > 0) {
            emit Donate(msg.sender, msg.value);
        }
    }

    receive() external payable {
        emit Donate(msg.sender, msg.value);
    }

    function createProposal(
        address _recipent,
        uint _value,
        string memory _proposal
    ) public notNull(_recipent) returns (uint256 _proposalCount) {
        proposals[_proposalCount] = Proposal({
            recipient: _recipent,
            value: _value,
            proposal: _proposal,
            approved: false
        });
        totalProposals.push(proposals[_proposalCount]);
        proposalCount++;
        emit CreatedProposal(proposalCount);
    }

    function approval(
        uint _proposalCount
    ) public isApproved(_proposalCount) onlyAdmin {
        totalProposals[_proposalCount].approved = true;
        emit Approval(_proposalCount);
    }

    function voting(
        uint _proposalCount,
        address _owner
    )
        public
        isVoted(_proposalCount, msg.sender)
        notNull(_owner)
        onlyOwner(msg.sender)
    {
        require(
            totalProposals[_proposalCount].approved == true,
            "Only approved proposals can be voted"
        );
        hasVoted[_proposalCount][_owner] = true;
        votes[_proposalCount]++;
        votesCount++;
        emit Voting(msg.sender, _proposalCount);
    }

    function execute() public onlyAdmin {
        uint winner = votes[0];
        uint winnerProposalCount = 0;
        //all owners should vote
        for (uint i = 0; i < owners.length; i++) {
            if (hasVoted[winnerProposalCount][owners[i]] == false) {
                emit ExecutionFailure(owners[i]);
                break;
            }
        }
        //winning proposal
        for (uint i = 0; i < proposalCount; i++) {
            if (votes[i] > winner) {
                winner = votes[i];
                winnerProposalCount = i;
            }
        }

        //51%
        uint num = votesCount * 51;
        uint quorum = num / 100;
        require(winner >= quorum, "Atleast 51% votes required to execute");

        //withdraw
        Proposal storage winningProposal = totalProposals[winnerProposalCount];
        require(winningProposal.approved == true, "Not approved by SuperAdmin");
        payable(winningProposal.recipient).transfer(address(this).balance);
        emit Execution(winnerProposalCount);
    }
}