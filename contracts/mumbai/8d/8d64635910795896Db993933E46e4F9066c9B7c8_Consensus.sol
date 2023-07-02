// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Statement.sol";
import "./ERC20.sol";

contract Consensus {
    address payable public owner;
    address public token;
    uint public costInWeiPerTokenUnit; // temp solution

    mapping(address => bool) users;
    mapping(address => uint) usersIndex; // default uint is 0, bug after deleting
    address[] public listOfUsers;

    mapping(address => uint) statementsIndex; // default uint is 0, bug after deleting
    address[] public statements;

    modifier isUser() {
        require(users[msg.sender], "You must be a user");
        _;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "You must be the owner");
        _;
    }
    modifier isVotable(address _address) {
        require(Statement(_address).active(), "Statement not active");
        _;
    }

    fallback() external payable {}

    receive() external payable {}

    // Setup
    constructor() {
        owner = payable(msg.sender);
        token = address(new ERC20("Consensus", "CST", 9, 100000000));
        ERC20(token).transfer(msg.sender, 500000 * 10**9);
        costInWeiPerTokenUnit = 250000;
        listOfUsers.push(address(0));
        statements.push(address(0));
    }

    // function init() external { // can this function be called more than once?
    //     owner = payable(msg.sender);
    //     token = address(new ERC20("Consensus", "CST", 9, 100000000));
    //     ERC20(token).transfer(msg.sender, 500000**9);
    //     costInWeiPerTokenUnit = 250000;
    //     listOfUsers.push(address(0));
    //     statements.push(address(0));
    // }
    function setTokenPrice(
        uint _newTokenPriceInWei
    ) external onlyOwner returns (bool) {
        costInWeiPerTokenUnit = _newTokenPriceInWei;
        return true;
    }

    // Sets new user
    function addUser(address _newUser) external onlyOwner returns (bool) {
        require(!users[_newUser]);

        users[_newUser] = true;
        listOfUsers.push(_newUser);
        usersIndex[_newUser] = listOfUsers.length - 1;
        return true;
    }

    function revokeUser(address _user) external onlyOwner returns (bool) {
        require(users[_user], "Not a user");

        users[_user] = false;
        uint index = usersIndex[_user]; // get index of user in listOfUsers array
        if (index == 0) revert("User already has index 0");
        usersIndex[_user] = 0; // delete user from userIndex mapping
        listOfUsers[index] = listOfUsers[listOfUsers.length - 1]; // replace user at index with last user
        listOfUsers.pop(); // pop last user

        return true;
    }

    // Creates new statement
    function createNewStatement(
        string memory _message,
        string[] memory _sources,
        uint _endTime,
        uint _reward
    ) external isUser returns (bool) {
        ERC20 TokenInstance = ERC20(token);
        require(
            TokenInstance.balanceOf(msg.sender) >= _reward,
            "Insufficient balance"
        );
        require(_endTime >= block.timestamp, "err endTime");

        address addr = address(
            new Statement(
                _message,
                _sources,
                _endTime,
                _reward,
                msg.sender,
                address(this),
                token
            )
        );

        TokenInstance.transfer(addr, _reward);
        TokenInstance.approve(address(this), _reward);
        statements.push(addr);
        statementsIndex[addr] = statements.length - 1;
        return true;
    }

    // Manages statement votes
    function vote(
        address _statement,
        bool _deleteVote,
        bool _newVote,
        uint8 _vote
    ) external isUser returns (bool) {
        if (_deleteVote) return Statement(_statement).deleteVote(msg.sender);
        require(_vote >= 0 && _vote <= 26, "Vote out of range");

        if (_newVote) return Statement(_statement).newVote(_vote, msg.sender);
        return Statement(_statement).changeVote(_vote, msg.sender);
    }

    function initPayout(address _statementAddress) external returns (bool) {
        Statement(_statementAddress).payout(msg.sender);
        return true;
    }

    function tokenPurchase(uint _amount) external payable returns (bool) {
        require(
            msg.value >= _amount * costInWeiPerTokenUnit,
            "Did not send enough ether"
        );
        ERC20(token).transferFrom(address(this), msg.sender, _amount);
        return true;
    }

    function withdrawFromContract() external onlyOwner returns (bool) {
        owner.transfer(address(this).balance);
        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract ERC20 is IERC20 {
    uint public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    string public name;
    string public symbol;
    uint public decimals;

    constructor(
        string memory _name,
        string memory _symbol,
        uint _decimals,
        uint _totalSupply
    ) {
        totalSupply = _totalSupply * 10 ** _decimals; // 100 million
        balanceOf[msg.sender] = totalSupply;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    function transfer(address recipient, uint amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool) {
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC20.sol";

contract Statement {
    address public consensus;
    address public token;
    address public owner;

    string public message;
    string[] public sources;
    uint8[26] public voteDistribution;
    uint immutable public startTime;
    uint public endTime;
    bool public active;
    uint public reward;
    bool public rewardsPaid;

    address[] public voterArr;
    mapping(address => bool) public hasVoted;
    mapping(address => uint8) public votes;
    mapping(address => bool) public votersWithReward;
    mapping(address => uint) public listOfVotersWithRewardIndex;
    address[] public listOfVotersWithReward;

    event Payout( uint numOfPayees, address initiator, uint reward );
    event VotingClosed( uint timeClosed );
    event NewVote(address voter, uint8 vote);
    event ChangedVote(address voter, uint8 vote_from, uint8 vote_to);
    event DeletedVote(address voter);
    constructor(
      string memory _message, 
      string[] memory _sources,  
      uint _endTime, 
      uint _reward,
      address _owner, 
      address _consensus,
      address _token
    ) {
        message = _message;
        sources = _sources;
        startTime = block.timestamp;
        endTime = _endTime;
        reward = _reward;
        owner = _owner;
        consensus = _consensus;
        token = _token;
        listOfVotersWithReward.push(address(0));
    }

    modifier goodOrigin {
      require(msg.sender == consensus);
      _;
    }
    modifier isVotable {
      require(active, "Voting is inactive");
      _;
    }
    modifier onlyOwner {
      require(msg.sender == owner, "Unauthorized");
      _;
    }

    function payout(address _initiator) public goodOrigin returns (bool){
      require( !rewardsPaid, "Rewards have already been paid" );
      require( block.timestamp >= endTime);

      ERC20 TokenInstance = ERC20( token );
      uint len = listOfVotersWithReward.length;
      uint remainder = reward % len;
      uint part = (reward-remainder) / len;

      for( uint i = 1; i < listOfVotersWithReward.length; i++){
        TokenInstance.transferFrom(address(this), listOfVotersWithReward[i], part);
      }

      emit Payout(listOfVotersWithReward.length, _initiator, reward-remainder );

      TokenInstance.transferFrom(address(this), owner, remainder);
      return true;
      // pays out list of users elidgable for rewards
    }
   
    function deleteVote(address _voter) external isVotable goodOrigin returns (bool success) {
        require(hasVoted[_voter],"Voter hasn't voted, nothing to delete");

        voteDistribution[votes[_voter]]--;
        delete votes[_voter];
        hasVoted[_voter] = false;

        emit DeletedVote(_voter);
        if(rewardsPaid) return true;
        
        // remove voter from votersWithReward, listOfVotersWithRewardIndex, listOfVotersWithReward
        votersWithReward[_voter] = false;
        uint index = listOfVotersWithRewardIndex[_voter];
        delete listOfVotersWithRewardIndex[_voter];
        listOfVotersWithReward[index] = listOfVotersWithReward[listOfVotersWithReward.length - 1];
        listOfVotersWithReward.pop();
        return true;
    }
    function newVote(uint8 _vote, address _voter) external isVotable goodOrigin returns (bool success) {
        require(!hasVoted[_voter],"Voter already voted, use changeVote");
        voteDistribution[_vote]++;
        votes[_voter] = _vote;
        hasVoted[_voter] = true;

        emit NewVote(_voter, _vote);
        if(rewardsPaid) return true;
        
        // add to list of votersWithReward, listOfVotersWithReward, listOfVotersWithRewardIndex
        listOfVotersWithReward.push(_voter);
        listOfVotersWithRewardIndex[_voter] = listOfVotersWithReward.length -1;
        votersWithReward[_voter] = true;
        return true;
    }
    function changeVote(uint8 _vote, address _voter) external isVotable goodOrigin returns (bool success) {
        require(hasVoted[_voter],"Voter hasn't voted, use newVote");
        uint8 from = voteDistribution[votes[_voter]];
        voteDistribution[votes[_voter]]--;
        voteDistribution[_vote]++;
        votes[_voter] = _vote;
        emit ChangedVote(_voter, from, _vote);
        return true;
    }
    function getVotes() public view returns ( uint8[26] memory){
      return voteDistribution;
    }
    function closeVoting() external onlyOwner returns (bool){
      active = false;
      emit VotingClosed(block.timestamp);
      return true;
    }

}