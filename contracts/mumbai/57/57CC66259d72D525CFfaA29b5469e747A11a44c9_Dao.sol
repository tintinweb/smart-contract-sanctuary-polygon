pragma solidity ^0.8.7;

interface whataContract {
  function balanceOf(address, uint256) external view returns (uint256);
  function maxSupply(uint256) external view returns (uint256);
}

contract Dao {

  address public owner;
  uint256 nextProposal;
  uint256[] public validTokens;
  whataContract daoContract;

  constructor(){
    owner = msg.sender;
    nextProposal = 1;
    daoContract = whataContract(0x2953399124F0cBB46d2CbACD8A89cF0599974963);
    validTokens = [58097402891580513947560728452193072169778608589196942986704705987598270595087];
  }

  struct Proposal {
    uint256 id;
    bool exists;
    string description;
    uint deadline;
    uint256 votesUp;
    uint256 votesDown;
    address[] canVote;
    uint256 maxVotes;
    mapping(address => bool) voteStatus;
    mapping(address => uint256) individualVotes;
    mapping(address => mapping(bool => uint256)) individualChoices;
    bool countConducted;
    bool passed;
    address proposedBy;
  }

  mapping(uint256 => Proposal) public proposalToId;
  Proposal[] proposals;

  event proposalCreated(
    uint256 id,
    string description,
    uint256 maxVotes,
    address proposer
  );

  event newVotes(
    uint256 votesUp,
    uint256 votesDown,
    address voter,
    uint256 proposal,
    bool votedFor
  );

  event proposalCount(
    uint256 id,
    bool passed
  );

    function _getElegibility(address _proposer) private view returns (uint256 _balance){
        uint256 balance = 0;
        for (uint i = 0; i < validTokens.length; i++){
            balance += daoContract.balanceOf(_proposer, validTokens[i]);
        }
        _balance = balance;
    }

    function _getVoteElegibility(uint256 _id, address _voter) private view returns (uint256 _voteBal){
        uint256 balance = 0;
        for (uint i = 0; i < proposals[_id].canVote.length; i++){
            if(proposals[_id].canVote[i] == _voter){
                balance ++;
            }
        }
        _voteBal = balance;
    }

    function viewVotingPower(address _member) public view returns (uint256 _votes){
      uint256 balance = 0;
        for (uint i = 0; i < validTokens.length; i++){
            balance += daoContract.balanceOf(_member, validTokens[i]);
        }
        _votes = balance;
    }
    
    function createProposal(string memory _description, address[] memory _canVote) public {
        uint256 balance = _getElegibility(msg.sender);
        require(balance > 0);

        uint256 _maxVotes = votePool();

        Proposal storage newProp = proposals[nextProposal];
        newProp.id = nextProposal;
        newProp.exists = true;
        newProp.description = _description;
        newProp.deadline = block.number + 100;
        newProp.votesUp = 0;
        newProp.votesDown = 0;
        newProp.canVote = _canVote;
        newProp.maxVotes= _maxVotes;
        newProp.countConducted = false;
        newProp.passed = false;
        newProp.proposedBy = msg.sender;

        emit proposalCreated(nextProposal, _description, _maxVotes, msg.sender);
        nextProposal++;
    }

    function votePool() public view returns (uint256 votes){
      uint256 _maxVotes = 0;
        for (uint i = 0; i < validTokens.length; i++){
          _maxVotes += daoContract.maxSupply(validTokens[i]);
        }
        votes = _maxVotes;
    }

    
        
    

    function voteOnProposal(uint256 _id, uint256 _votesUp, uint256 _votesDown) public {
        require(proposals[_id].exists, "This proposal does not exist");
        uint256 maxVotesAvailable = _checkVoteAvailability(_id, msg.sender);
        require(maxVotesAvailable > 0 && (_votesUp+_votesDown) <= maxVotesAvailable);
        require( (proposals[_id].individualVotes[msg.sender] += (_votesUp+_votesDown)) <= maxVotesAvailable );
        require(block.number <= proposals[_id].deadline, "The deadline has passed for this Proposal");

        _vote(_id, _votesUp, _votesDown, msg.sender, maxVotesAvailable);
        
    }

    function _vote(uint256 _id, uint256 _votesUp, uint256 _votesDown, address _voter, uint256 maxVotesAvailable) internal {
        proposals[_id].individualVotes[_voter] += (_votesUp+_votesDown);    
        proposals[_id].votesUp += _votesUp;
        proposals[_id].votesDown += _votesDown;
        proposals[_id].individualChoices[_voter][true] += _votesUp;
        proposals[_id].individualChoices[_voter][false] += _votesDown;
        if(proposals[_id].individualVotes[_voter] == maxVotesAvailable){
            proposals[_id].voteStatus[_voter] == true;
        }
        bool votedFor = (_votesUp > _votesDown);
        if ((proposals[_id].votesUp + proposals[_id].votesDown) == proposals[_id].maxVotes){
            _countVotes(_id);
        }
        
        emit newVotes(_votesUp, _votesDown, _voter, _id, votedFor);
    }

    function _checkVoteAvailability(uint256 _id, address _checkVoter) internal view returns (uint256 _votesAvailable){
        address[] memory _canVote = proposals[_id].canVote;
        uint256 voteCount = 0;
        for (uint i = 0; i < _canVote.length; i++){
            for (uint j = 0; j < validTokens.length; j++){
                if(_canVote[i] == _checkVoter){
                    voteCount += daoContract.balanceOf(_canVote[i], validTokens[j]);
                }
            }
        }
        _votesAvailable = voteCount;
    }


    function countVotes(uint256 _id) public {
        require(msg.sender == owner, "Only owner can count votes");
        require(proposals[_id].exists, "This proposal does not exist");
        require(block.number > proposals[_id].deadline, "Voting has not concluded");
        require(!proposals[_id].countConducted, 'Count already conducted');

        _countVotes(_id);
    }

    function _countVotes(uint256 _id) internal {
        if(proposals[_id].votesUp > proposals[_id].votesDown){
            proposals[_id].passed = true;
            proposals[_id].countConducted = true;
        } else if(proposals[_id].votesUp < proposals[_id].votesDown){
            proposals[_id].passed = false;
            proposals[_id].countConducted = true;
        } else {
            proposals[_id].passed = false;
            proposals[_id].countConducted = true;
        }
        emit proposalCount(_id, proposals[_id].passed);
    }

    function viewProposal(uint256 _id) public view returns (
    bool _exists,
    string memory _description,
    uint _deadline,
    uint256 _votesUp,
    uint256 _votesDown,
    address[] memory _canVote,
    uint256 _maxVotes,
    bool _voteStatus,
    uint256 _individualVotes,
    bool _countConducted,
    bool _passed,
    bool _active
    ){

    require(proposals[_id].exists, "This proposal does not exist");
   
    Proposal storage p = proposals[_id];

    _exists = p.exists;
    _description = p.description;
    _deadline = p.deadline;
    _votesUp = p.votesUp;
    _votesDown = p.votesDown;
    _canVote = p.canVote;
    _maxVotes = p.maxVotes;
    _voteStatus = p.voteStatus[msg.sender];
    _individualVotes = p.individualVotes[msg.sender];
    _countConducted = p.countConducted;
    _passed = p.passed;
    _active = (p.deadline > block.number);
    }

    function addTokenId(uint256 _tokenId) public {
      require(msg.sender == owner, 'Only Owner Can Add Tokens');

      validTokens.push(_tokenId);
    }
}