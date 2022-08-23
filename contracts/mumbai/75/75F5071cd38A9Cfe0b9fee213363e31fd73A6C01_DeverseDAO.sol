// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract DeverseDAO {
    uint256 public currentDAOId;

    struct DAO {
        uint256 id;
        string name;
        string description;
        string website;
        string slug;
        bool isExists;
        address createdBy;
    }

    struct Proposal {
        uint256 id;
        uint256 daoId;
        string title;
        string description;
        string category;
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 votesYes;
        uint256 votesNo;
        address createdBy;
        bool isExecuted;
        bool isPassed;
    }

    struct Vote {
        uint256 id;
        uint256 daoId;
        uint256 proposalId;
        address voter;
        uint256 votingPower;
        bool support;
    }

    mapping(uint256 => DAO) public daos;
    mapping(uint256 => mapping(address => bool)) public isMemberofDAO;
    mapping(string => bool) public isSlugTaken;
    mapping(address => bool) hasDAO;
    mapping(uint256 => mapping(uint256 => Proposal)) public proposals;
    mapping(uint256 => mapping(uint256 => mapping(uint256 => Vote)))
        public votes;
    mapping(uint256 => mapping(uint256 => mapping(address => bool)))
        public isMemberVoted;
    mapping(uint256 => uint256) public daoProposalCount;
    mapping(uint256 => mapping(uint256 => uint256)) public daoProposalVoteCount;

    event DAOCreated(
        uint256 id,
        string name,
        string description,
        string website,
        string slug,
        address[] members,
        address createdBy
    );

    event MemberAdded(uint256 daoId, address addedMember);
    event MemberRemoved(uint256 daoId, address removedMember);
    event ProposalCreated(
        uint256 proposalId,
        uint256 daoId,
        string title,
        string description,
        string category,
        uint256 startTimestamp,
        uint256 endTimestamp,
        address createdBy
    );
    event VoteCasted(
        uint256 voteId,
        uint256 daoId,
        uint256 proposalId,
        address voter,
        bool support
    );
    event ProposalExecuted(uint256 proposalId, uint256 daoId, bool isPassed);

    modifier onlyDAOAdmin(uint256 _daoId) {
        require(daos[_daoId].isExists, "DAO does not exist");
        require(
            daos[_daoId].createdBy == msg.sender,
            "Only DAO admin can perform this action"
        );
        _;
    }

    modifier onlyDAOMember(uint256 _daoId) {
        require(daos[_daoId].isExists, "DAO does not exist");
        require(
            isMemberofDAO[_daoId][msg.sender],
            "Only DAO member can perform this action"
        );
        _;
    }

    modifier onlyDAOProposalCreator(uint256 _daoId, uint256 _proposalId) {
        require(daos[_daoId].isExists, "DAO does not exist");
        require(
            proposals[_daoId][_proposalId].createdBy == msg.sender,
            "Only DAO proposal creator can perform this action"
        );
        _;
    }

    function createDAO(
        string memory _name,
        string memory _description,
        string memory _website,
        string memory _slug,
        address[] memory _members
    ) public {
        require(
            bytes(_slug).length > 4,
            "Slug must be at least 5 characters long"
        );
        require(!isSlugTaken[_slug], "Slug is already taken");
        require(!hasDAO[msg.sender], "You already have a DAO");
        require(_members.length <= 5, "Upto 5 members can be added at a time");

        daos[currentDAOId] = DAO(
            currentDAOId,
            _name,
            _description,
            _website,
            _slug,
            true,
            msg.sender
        );

        isSlugTaken[_slug] = true;
        hasDAO[msg.sender] = true;
        isMemberofDAO[currentDAOId][msg.sender] = true;

        for (uint256 i = 0; i < _members.length; i++) {
            isMemberofDAO[currentDAOId][_members[i]] = true;
        }

        emit DAOCreated(
            currentDAOId,
            _name,
            _description,
            _website,
            _slug,
            _members,
            msg.sender
        );
        currentDAOId++;
    }

    function addMemberToDAO(uint256 _daoId, address _memberToAdd)
        public
        onlyDAOAdmin(_daoId)
    {
        require(
            !isMemberofDAO[_daoId][_memberToAdd],
            "Address is already a member of this DAO"
        );
        isMemberofDAO[_daoId][_memberToAdd] = true;
        emit MemberAdded(_daoId, _memberToAdd);
    }

    function removeMemberFromDAO(uint256 _daoId, address _memberToRemove)
        public
        onlyDAOAdmin(_daoId)
    {
        require(
            isMemberofDAO[_daoId][_memberToRemove],
            "Address is not a member of this DAO"
        );

        isMemberofDAO[_daoId][_memberToRemove] = false;
        emit MemberRemoved(_daoId, _memberToRemove);
    }

    function createProposal(
        uint256 _daoId,
        string memory _title,
        string memory _description,
        string memory _category,
        uint256 _startTimestamp,
        uint256 _endTimestamp
    ) public onlyDAOMember(_daoId) {
        // title and description should not be empty
        require(
            bytes(_title).length > 0 && bytes(_description).length > 0,
            "Title and description should not be empty"
        );
        require(
            _startTimestamp > block.timestamp,
            "Start timestamp should be greater than current timestamp"
        );
        require(
            _endTimestamp > block.timestamp,
            "End timestamp should be greater than current timestamp"
        );
        require(
            _endTimestamp - _startTimestamp >= 86400,
            "Proposal duration should be greater than 1 day"
        );

        uint256 proposalId = daoProposalCount[_daoId];
        proposals[_daoId][proposalId] = Proposal(
            proposalId,
            _daoId,
            _title,
            _description,
            _category,
            _startTimestamp,
            _endTimestamp,
            0,
            0,
            msg.sender,
            false,
            false
        );

        emit ProposalCreated(
            proposalId,
            _daoId,
            _title,
            _description,
            _category,
            _startTimestamp,
            _endTimestamp,
            msg.sender
        );
        daoProposalCount[_daoId]++;
    }

    function castVote(
        uint256 _daoId,
        uint256 _proposalId,
        uint256 _votingPower,
        bool _support
    ) public onlyDAOMember(_daoId) {
        require(
            !isMemberVoted[_daoId][_proposalId][msg.sender],
            "You have already voted on this proposal"
        );
        require(
            proposals[_daoId][_proposalId].endTimestamp > block.timestamp,
            "Proposal has already ended/does not exist"
        );
        require(
            proposals[_daoId][_proposalId].startTimestamp < block.timestamp,
            "Proposal is not active yet"
        );
        require(
            !proposals[_daoId][_proposalId].isExecuted,
            "Proposal has already been executed"
        );

        uint256 voteId = daoProposalVoteCount[_daoId][_proposalId];

        votes[_daoId][_proposalId][voteId] = Vote(
            voteId,
            _daoId,
            _proposalId,
            msg.sender,
            _votingPower,
            _support
        );

        if (_support) {
            proposals[_daoId][_proposalId].votesYes++;
        } else {
            proposals[_daoId][_proposalId].votesNo++;
        }
        isMemberVoted[_daoId][_proposalId][msg.sender] = true;

        emit VoteCasted(voteId, _daoId, _proposalId, msg.sender, _support);
        daoProposalVoteCount[_daoId][_proposalId]++;
    }

    function executeProposal(uint256 _daoId, uint256 _proposalId)
        public
        onlyDAOProposalCreator(_daoId, _proposalId)
    {
        require(
            proposals[_daoId][_proposalId].endTimestamp > 0,
            "Proposal does not exist"
        );
        require(
            !proposals[_daoId][_proposalId].isExecuted,
            "Proposal has already been executed"
        );
        require(
            proposals[_daoId][_proposalId].endTimestamp < block.timestamp,
            "Proposal voting period is not over"
        );

        if (
            proposals[_daoId][_proposalId].votesYes >
            proposals[_daoId][_proposalId].votesNo
        ) {
            proposals[_daoId][_proposalId].isPassed = true;
        }

        proposals[_daoId][_proposalId].isExecuted = true;

        emit ProposalExecuted(
            _proposalId,
            _daoId,
            proposals[_daoId][_proposalId].isPassed
        );
    }
}