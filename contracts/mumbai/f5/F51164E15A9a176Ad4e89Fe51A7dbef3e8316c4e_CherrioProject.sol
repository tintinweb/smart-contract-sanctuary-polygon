// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract CherrioProject {
    mapping(address => uint) public contributions;
    uint public totalContributors;
    uint public minimumContribution;
    uint public duration;
    uint public deadline;
    uint256 public goal;
    uint256 public raisedAmount = 0;
    address public admin;
    Stages public stage;

    struct Request {
        string description;
        uint value;
        address recipient;
        bool completed;
        uint numberOfVoters;
        mapping(address => bool) voters;
    }

    enum Stages {
        Pending,
        Active,
        Ended,
        Locked
    }

    uint numRequests;
    mapping(uint => Request) requests;

    constructor(uint _duration, uint256 _goal) {
        stage = Stages.Pending;
        minimumContribution = 0.001*(10**18);
        duration = _duration;
        goal = _goal;
        admin = 0xAAe3b0B628E1b8918a0F0C648f5FAc3cDFe61C9e;
    }

    modifier onlyAdmin {
        require(msg.sender == admin);
        _;
    }

    modifier atStage(Stages _expectedStage) {
        require(stage == _expectedStage);
        _;
    }

    event donations (
        uint contribution,
        address contributor
    );

    receive() external payable {
        contribute();
    }

    function contribute() public payable atStage(Stages.Active) {
        require(msg.value > minimumContribution);
        require(block.number < deadline);

        if (contributions[msg.sender] == 0) {
            totalContributors++;
        }

        contributions[msg.sender] += msg.value;
        raisedAmount += msg.value;

        if (raisedAmount >= goal) {
            stage = Stages.Ended;
        }

        emit donations(msg.value, msg.sender);
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getRefund() public {
        require(block.number > deadline);
        require(raisedAmount < goal);
        require(contributions[msg.sender] > 0);

        payable(msg.sender).transfer(contributions[msg.sender]);
        contributions[msg.sender] = 0;
    }

    function activate() external atStage(Stages.Pending) {
        stage = Stages.Active;
        deadline = block.number + duration;
    }

    function createSpendingRequest(string memory _description, address _recipient, uint _value) public onlyAdmin {
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
        require(thisRequest.numberOfVoters > totalContributors / 2);
        //more than 50% voted
        payable(thisRequest.recipient).transfer(thisRequest.value);
        thisRequest.completed = true;
    }
}