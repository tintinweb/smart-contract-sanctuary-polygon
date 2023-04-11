//SPDX-License-Identifier:MIT

pragma solidity ^0.8.7;

contract Mytoken{
    string public name;
    string public symbol;
    uint public decimals;
    uint public totalSupply;

    constructor(){
        name = "tamilndu";
        symbol = "TN";
        decimals = 10;
        totalSupply = 10000000000000;
        balanceOf[msg.sender] = totalSupply;
    }
    
    mapping(address => uint)public balanceOf;
    mapping(address => mapping(address => uint))public allowed;

    event Transfer(address indexed _from, address indexed _to, uint value);
    event Approved(address indexed _from, address indexed _to, uint value);

    function transfer(address _to, uint _value)external returns(bool){
        require(_to != address(0), "to address is invalid");
        require(_value <= balanceOf[msg.sender],"Insufficient ether");
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _to, uint _value)external {
        require(_to != address(0), "invalid address");
        allowed[msg.sender][_to] = _value;
        emit Approved(msg.sender, _to, _value);

    }

    function allowance(address _owner, address _Receiver)external view returns(uint){
        return allowed[_owner][_Receiver];
    }

    function transferFrom(address _from, address _to, uint _value)external returns(bool){
        require(_value <= balanceOf[_from], "Insufficient ether");
        require(allowed[_from][_to] <= _value,"Insufficient ether");
        balanceOf[_from] -= _value;
        allowed[_from][_to] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
}
contract Contract is Mytoken{
   
    struct Candidate {
        string name;
        uint voteCount;
    }
    
    mapping(address => bool) public voters;
    Candidate[] public candidates;
    uint public votingEndTime;
    address public owner;
    
    constructor() {
        owner = msg.sender;
        // for (uint i = 0; i < candidateNames.length; i++) {
        //     candidates.push(Candidate({
        //         name: candidateNames[i],
        //         voteCount: 0
        //     }));
        // }
        votingEndTime = block.timestamp + (10 * 1 minutes);
    }

    function register(string memory candidateName) public{
        candidates.push(Candidate({
                name: candidateName,
                voteCount: 0
            }));
    }
    
    function vote(uint candidateIndex) public {
        require(!voters[msg.sender], "Already voted");
        require(balanceOf[msg.sender]==1,"invlaid token");
        require(candidateIndex < candidates.length, "Invalid candidate index");
        require(block.timestamp < votingEndTime, "Voting has ended");
        candidates[candidateIndex].voteCount++;
        voters[msg.sender] = true;
        balanceOf[msg.sender]=0;
    }
    
    function getWinner() public view returns (string memory) {
        require(block.timestamp >= votingEndTime, "Voting has not ended yet");
        uint winningVoteCount = 0;
        uint winningCandidateIndex;
        for (uint i = 0; i < candidates.length; i++) {
            if (candidates[i].voteCount > winningVoteCount) {
                winningVoteCount = candidates[i].voteCount;
                winningCandidateIndex = i;
            }
           
        }
        return candidates[winningCandidateIndex].name;
    }
    
    function endVoting() public {
        require(msg.sender == owner, "Only the owner can end the voting");
        // require(block.timestamp >= votingEndTime, "Voting has not ended yet");
         votingEndTime=block.timestamp;
    }
    function getcanditates() public view returns(Candidate[] memory){
        return candidates;
    }
}