// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface WunderPool {
    function isMember(address maybeMember) external returns (bool);

    function governanceTokensOf(address user)
        external
        view
        returns (uint256 balance);

    function totalGovernanceTokens() external view returns (uint256 tokens);
}

contract WunderProposalDelta {
    enum VoteType {
        None,
        For,
        Against
    }

    struct Pool {
        mapping(uint256 => Proposal) proposals;
    }

    struct Proposal {
        string title;
        string description;
        address[] contractAddresses;
        string[] actions;
        bytes[] params;
        uint256[] transactionValues;
        uint256 deadline;
        address[] yesVoters;
        address[] noVoters;
        uint256 createdAt;
        bool executed;
        mapping(address => VoteType) hasVoted;
    }

    mapping(address => Pool) pools;

    function createProposal(
        address _creator,
        uint256 _proposalId,
        string memory _title,
        string memory _description,
        address[] memory _contractAddresses,
        string[] memory _actions,
        bytes[] memory _params,
        uint256[] memory _transactionValues,
        uint256 _deadline
    ) public {
        require(
            _contractAddresses.length == _actions.length &&
                _actions.length == _params.length &&
                _params.length == _transactionValues.length,
            "Inconsistent amount of transactions"
        );
        require(bytes(_title).length > 0, "Missing Title");
        require(_deadline > block.timestamp, "Invalid Deadline");

        for (uint256 index = 0; index < _contractAddresses.length; index++) {
            require(_contractAddresses[index] != address(0), "Missing Address");
            require(bytes(_actions[index]).length > 0, "Missing Action");
        }

        Proposal storage newProposal = pools[msg.sender].proposals[_proposalId];
        newProposal.title = _title;
        newProposal.description = _description;
        newProposal.contractAddresses = _contractAddresses;
        newProposal.actions = _actions;
        newProposal.params = _params;
        newProposal.transactionValues = _transactionValues;
        newProposal.deadline = _deadline;
        newProposal.yesVoters.push(_creator);
        newProposal.createdAt = block.timestamp;
        newProposal.executed = false;
        newProposal.hasVoted[_creator] = VoteType.For;
    }

    function hasVoted(
        address _pool,
        uint256 _proposalId,
        address _account
    ) public view returns (VoteType) {
        return pools[_pool].proposals[_proposalId].hasVoted[_account];
    }

    function vote(
        uint256 _proposalId,
        uint256 _mode,
        address _voter
    ) public {
        require(
            WunderPool(msg.sender).isMember(_voter),
            "Only Members can vote"
        );
        Proposal storage proposal = pools[msg.sender].proposals[_proposalId];
        require(proposal.actions.length > 0, "Proposal does not exist");
        require(
            block.timestamp <= proposal.deadline,
            "Voting period has ended"
        );
        require(
            hasVoted(msg.sender, _proposalId, _voter) == VoteType.None,
            "Member has voted"
        );

        if (_mode == uint8(VoteType.Against)) {
            proposal.hasVoted[_voter] = VoteType.Against;
            proposal.noVoters.push(_voter);
        } else if (_mode == uint8(VoteType.For)) {
            proposal.hasVoted[_voter] = VoteType.For;
            proposal.yesVoters.push(_voter);
        } else {
            revert("Invalid VoteType (1=YES, 2=NO)");
        }
    }

    function setProposalExecuted(uint256 _proposalId) public {
        pools[msg.sender].proposals[_proposalId].executed = true;
    }

    function calculateVotes(address _pool, uint256 _proposalId)
        public
        view
        returns (uint256 yesVotes, uint256 noVotes)
    {
        Proposal storage proposal = pools[_pool].proposals[_proposalId];
        uint256 yes;
        uint256 no;
        for (uint256 i = 0; i < proposal.noVoters.length; i++) {
            no += WunderPool(_pool).governanceTokensOf(proposal.noVoters[i]);
        }
        for (uint256 i = 0; i < proposal.yesVoters.length; i++) {
            yes += WunderPool(_pool).governanceTokensOf(proposal.yesVoters[i]);
        }
        return (yes, no);
    }

    function proposalExecutable(address _pool, uint256 _proposalId)
        public
        view
        returns (bool executable, string memory errorMessage)
    {
        Proposal storage proposal = pools[_pool].proposals[_proposalId];
        if (proposal.actions.length < 1) {
            return (false, "Proposal does not exist");
        }
        if (proposal.executed) {
            return (false, "Proposal already executed");
        }
        (uint256 yesVotes, uint256 noVotes) = calculateVotes(
            _pool,
            _proposalId
        );
        if ((noVotes * 2) >= WunderPool(_pool).totalGovernanceTokens()) {
            return (false, "Majority voted against execution");
        }
        if (
            (yesVotes * 2) < WunderPool(_pool).totalGovernanceTokens() &&
            proposal.deadline >= block.timestamp
        ) {
            return (false, "Voting still allowed");
        }

        uint256 transactionTotal = 0;
        for (
            uint256 index = 0;
            index < proposal.transactionValues.length;
            index++
        ) {
            transactionTotal += proposal.transactionValues[index];
        }

        if (transactionTotal > _pool.balance) {
            return (false, "Not enough funds");
        }

        return (true, "");
    }

    function getProposal(address _pool, uint256 _proposalId)
        public
        view
        returns (
            string memory title,
            string memory description,
            uint256 transactionCount,
            uint256 deadline,
            uint256 yesVotes,
            uint256 noVotes,
            uint256 totalVotes,
            uint256 createdAt,
            bool executed
        )
    {
        Proposal storage proposal = pools[_pool].proposals[_proposalId];
        (uint256 yes, uint256 no) = calculateVotes(_pool, _proposalId);
        uint256 total = WunderPool(_pool).totalGovernanceTokens();
        return (
            proposal.title,
            proposal.description,
            proposal.actions.length,
            proposal.deadline,
            yes,
            no,
            total,
            proposal.createdAt,
            proposal.executed
        );
    }

    function getProposalTransaction(
        address _pool,
        uint256 _proposalId,
        uint256 _transactionIndex
    )
        public
        view
        returns (
            string memory action,
            bytes memory param,
            uint256 transactionValue,
            address contractAddress
        )
    {
        Proposal storage proposal = pools[_pool].proposals[_proposalId];
        return (
            proposal.actions[_transactionIndex],
            proposal.params[_transactionIndex],
            proposal.transactionValues[_transactionIndex],
            proposal.contractAddresses[_transactionIndex]
        );
    }

    function getProposalTransactions(address _pool, uint256 _proposalId)
        public
        view
        returns (
            string[] memory actions,
            bytes[] memory params,
            uint256[] memory transactionValues,
            address[] memory contractAddresses
        )
    {
        Proposal storage proposal = pools[_pool].proposals[_proposalId];
        return (
            proposal.actions,
            proposal.params,
            proposal.transactionValues,
            proposal.contractAddresses
        );
    }
}