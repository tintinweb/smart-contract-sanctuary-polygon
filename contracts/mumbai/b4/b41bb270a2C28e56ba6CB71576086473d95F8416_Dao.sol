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
        for (uint i = 0; i < proposalToId[_id].canVote.length; i++){
            if(proposalToId[_id].canVote[i] == _voter){
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

        Proposal storage newProp = proposalToId[nextProposal];
        
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

        Proposal storage p = proposalToId[_id];
        
        if (!(p.individualChoices[msg.sender][true] > 0)){
          p.individualChoices[msg.sender][true] = 0;
        }
        if (!(p.individualChoices[msg.sender][false] > 0)){
          p.individualChoices[msg.sender][false] = 0;
        }

        (uint256 votesRemaining, uint256 totalAvailableVotes) = checkVoteAvailability(_id, msg.sender);

        require((_votesUp + _votesDown) <= votesRemaining, 'You have cast too many votes than you are allotted');
        
        p.individualVotes[msg.sender] += (_votesUp+_votesDown);    
        p.votesUp += _votesUp;
        p.votesDown += _votesDown;
        p.individualChoices[msg.sender][true] += _votesUp;
        p.individualChoices[msg.sender][false] += _votesDown;

        require((p.individualVotes[msg.sender] <= totalAvailableVotes), 'Something went wrong');

        if(p.individualVotes[msg.sender] == totalAvailableVotes){
            p.voteStatus[msg.sender] == true;
        }
        
        bool votedFor = (_votesUp > _votesDown);
        emit newVotes(_votesUp, _votesDown, msg.sender, _id, votedFor);
        
        if ((p.votesUp + p.votesDown) == p.maxVotes){
            _countVotes(_id);
        }
        
    }

    function checkVoteAvailability(uint256 _id, address _checkVoter) public view returns (uint256 _votesRemaining, uint256 _totalAvailableVotes){
        Proposal storage p = proposalToId[_id];
        require(p.exists, "This proposal does not exist");
        require(block.number <= p.deadline, "The deadline has passed for this Proposal");
        address[] memory _canVote = p.canVote;
        uint256 voteCount = 0;
        for (uint i = 0; i < _canVote.length; i++){
            for (uint j = 0; j < validTokens.length; j++){
                if(_canVote[i] == _checkVoter){
                    voteCount += daoContract.balanceOf(_canVote[i], validTokens[j]);
                }
            }
        }
        

        _totalAvailableVotes = voteCount;
        _votesRemaining = (voteCount - (p.individualChoices[_checkVoter][true] + p.individualChoices[_checkVoter][false]));
    }


    function countVotes(uint256 _id) public {
        require(msg.sender == owner, "Only owner can count votes");
        require(proposalToId[_id].exists, "This proposal does not exist");
        require(block.number > proposalToId[_id].deadline, "Voting has not concluded");
        require(!proposalToId[_id].countConducted, 'Count already conducted');

        _countVotes(_id);
    }

    function _countVotes(uint256 _id) internal {
        if(proposalToId[_id].votesUp > proposalToId[_id].votesDown){
            proposalToId[_id].passed = true;
            proposalToId[_id].countConducted = true;
        } else {
            proposalToId[_id].passed = false;
            proposalToId[_id].countConducted = true;
        }
        emit proposalCount(_id, proposalToId[_id].passed);
    }

    function addTokenId(uint256 _tokenId) public {
      require(msg.sender == owner, 'Only Owner Can Add Tokens');

      validTokens.push(_tokenId);
    }
}