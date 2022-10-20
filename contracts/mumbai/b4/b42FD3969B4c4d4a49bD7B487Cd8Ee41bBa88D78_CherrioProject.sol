// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ICherrioProjectActivator {
    function sendReward() external;
}

contract CherrioProject {
    address public admin;
    address public cherrioProjectActivator;
    uint256 public minimumDonation;
    uint256 public goal;
    uint256 public raisedAmount = 0;
    uint public totalDonors;
    uint public duration;
    uint public deadline;
    Stages public stage;
    uint numRequests;

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

    mapping(address => uint256) public donations;
    mapping(uint => Request) requests;

    modifier isAdmin {
        require(msg.sender == admin);
        _;
    }

    modifier atStage(Stages _expectedStage) {
        require(stage == _expectedStage);
        _;
    }

    modifier canActivate(address _address) {
        require(_address == admin || _address == cherrioProjectActivator);
        _;
    }

    event Donate(address donor, uint256 amount);

    constructor(uint _duration, uint256 _goal) {
        duration = _duration;
        goal = _goal;
        stage = Stages.Pending;
        minimumDonation = 0.001*(10**18);
        admin = 0xAAe3b0B628E1b8918a0F0C648f5FAc3cDFe61C9e;
        cherrioProjectActivator = 0x5Dc57570cB1DF81E4ecb6124FB9407C50625136D;
    }

    receive() external payable {
        donate();
    }

    function donate() public payable atStage(Stages.Active) {
        require(msg.value >= minimumDonation);
        require(block.number <= deadline);

        if (donations[msg.sender] == 0) {
            totalDonors++;
        }

        donations[msg.sender] += msg.value;
        raisedAmount += msg.value;

        if (raisedAmount >= goal) {
            stage = Stages.Ended;
            ICherrioProjectActivator(cherrioProjectActivator).sendReward();
        }

        emit Donate(msg.sender, msg.value);
    }

    function activate() external atStage(Stages.Pending) canActivate(msg.sender) {
        stage = Stages.Active;
        deadline = block.number + duration;
    }

    function getBlockNumber() public view returns(uint256){
        return block.number;
    }

    function getRefund() public {
        require(block.number > deadline);
        require(raisedAmount <= goal);
        require(donations[msg.sender] > 0);

        payable(msg.sender).transfer(donations[msg.sender]);
        donations[msg.sender] = 0;
    }

    function createSpendingRequest(string memory _description, address _recipient, uint _value) public isAdmin {
        Request storage r = requests[numRequests++];
        r.description = _description;
        r.value = _value;
        r.recipient = _recipient;
        r.numberOfVoters = 0;
        r.completed = false;
    }

    function voteForRequest(uint index) public {
        Request storage request = requests[index];
        require(donations[msg.sender] > 0);
        require(request.voters[msg.sender] == false);

        request.voters[msg.sender] = true;
        request.numberOfVoters++;
    }

    function makePayment(uint index) public isAdmin {
        Request storage request = requests[index];
        require(request.completed == false);
        require(request.numberOfVoters > totalDonors / 2);
        //more than 50% voted
        payable(request.recipient).transfer(request.value);
        request.completed = true;
    }
}