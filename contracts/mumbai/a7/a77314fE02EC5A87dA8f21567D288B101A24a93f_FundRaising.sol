pragma solidity ^0.8.9;

contract FundRaising {

    mapping(address=>uint) public contributions;
    uint public totalContributors;
    uint public minimumContribution;
    uint public deadline;
    uint public goal;
    uint public raisedAmount = 0 ;
    address public admin;

    struct  Request  {
        string description;
        uint value;
        address recipient;
        bool completed;
        uint numberOfVoters;
        mapping(address=>bool) voters;
    }
//    Request[] public requests;
    uint numRequests;
    mapping (uint => Request) requests;

    constructor(uint _goal){
        minimumContribution = 1000000;
        deadline=block.number + 40320;
        goal=_goal;
        admin = msg.sender;
    }

    modifier onlyAdmin {
        require(msg.sender == admin);
        _;
    }
    event donations (
        uint contribution,
        address donator
    );

    function contribute() public payable {
        require(msg.value > minimumContribution);
        require(block.number < deadline);

        if(contributions[msg.sender] == 0)
        {
            totalContributors++;
        }

        contributions[msg.sender] += msg.value;
        raisedAmount+=msg.value;

        emit donations(msg.value, msg.sender);
    }

    function getBalance() public view returns(uint)
    {
        return address(this).balance;
    }

    function getRefund() public {
        require(block.number > deadline);
        require(raisedAmount < goal);
        require(contributions[msg.sender] > 0);


        payable(msg.sender).transfer(contributions[msg.sender]);
        contributions[msg.sender] = 0;

    }

    function createSpendingRequest(string memory _description, address _recipient, uint _value) public onlyAdmin{

        Request storage r = requests[numRequests++];
        r.description = _description;
        r.value = _value;
        r.recipient = _recipient;
        r.numberOfVoters = 0;
        r.completed = false;

    }

    function voteForRequest(uint index) public {
        Request storage thisRequest = requests[index];
        require(contributions[msg.sender] > 0);
        require(thisRequest.voters[msg.sender] == false);

        thisRequest.voters[msg.sender] = true;
        thisRequest.numberOfVoters++;
    }

    function makePayment(uint index) public onlyAdmin {
        Request storage thisRequest = requests[index];
        require(thisRequest.completed == false);
        require(thisRequest.numberOfVoters > totalContributors / 2);//more than 50% voted
        payable(thisRequest.recipient).transfer(thisRequest.value);
        thisRequest.completed = true;
    }
}