/**
 *Submitted for verification at polygonscan.com on 2022-11-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title Owner
 * @dev Set & change owner
 */
contract Owner {
    address private owner;

    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);

    // modifier to check if caller is owner
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address
     * @return address of owner
     */
    function getOwner() public view returns (address) {
        return owner;
    }
}

interface ICherrioProjectActivator {
    function sendReward() external;
}

contract CherrioProject is Owner {
    address public admin;
    address public cherrioProjectActivator;
    uint256 public minimumDonation;
    uint256 public duration;
    uint256 public startedAt;
    uint256 public deadline;
    uint256 public endedAt;
    uint256 public goal;
    uint256 public raisedAmount;
    uint256 public numDonations;
    uint256 public numDonors;
    uint256 public numRequests;
    Stages public stage;

    struct Request {
        address recipient;
        string description;
        uint256 value;
        uint256 numVoters;
        bool completed;
        mapping(address => bool) voters;
    }

    enum Stages {
        Pending,
        Active,
        Ended,
        Locked
    }

    mapping(address => uint256) public donations;
    mapping(uint256 => Request) public requests;

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

    event Donation(address donor, uint256 value);
    event ProjectActivated(uint256 startedAt, uint256 deadline);
    event ProjectEnded();
    event CreateSpendingRequest(string description, address recipient, uint256 value);
    event VoteForRequest(uint256 index, uint256 numberOfVoters);
    event MakePayment(uint256 index, uint256 value);

    constructor(uint256 _goal, uint256 _duration) {
        goal = _goal;
        duration = _duration;
        stage = Stages.Pending;
        minimumDonation = 0.00001*(10**18);
        admin = 0x78b881eB26Db03B49239DB7cd7b2c92f95d9D63C;
        cherrioProjectActivator = 0x3E8CF19753673e86A8AEd6236638f7E37aCF6451;
    }

    receive() external payable {
        donate();
    }

    function donate() public payable atStage(Stages.Active) {
        require(msg.value >= minimumDonation);
        require(block.timestamp <= deadline);

        if (donations[msg.sender] == 0) {
            numDonors++;
        }

        donations[msg.sender] += msg.value;
        raisedAmount += msg.value;
        numDonations++;

        emit Donation(msg.sender, msg.value);

        if (raisedAmount >= goal) {
            stage = Stages.Ended;
            endedAt = block.timestamp;
            ICherrioProjectActivator(cherrioProjectActivator).sendReward();

            emit ProjectEnded();
        }
    }

    function activate() external atStage(Stages.Pending) canActivate(msg.sender) {
        stage = Stages.Active;
        startedAt = block.timestamp;
        deadline = startedAt + (duration * 1 days);

        emit ProjectActivated(startedAt, deadline);
    }

    function getCurrentTime() external view returns(uint256){
        return block.timestamp;
    }

    function getRefund() external {
        require(block.timestamp > endedAt);
        require(raisedAmount <= goal);
        require(donations[msg.sender] > 0);

        payable(msg.sender).transfer(donations[msg.sender]);
        donations[msg.sender] = 0;
    }

    function setMinimumDonation(uint256 _value) public isAdmin{
        minimumDonation = _value*(10**18);
    }

    function createSpendingRequest(string memory _description, address _recipient, uint256 _value) public isOwner {
        Request storage r = requests[numRequests++];
        r.description = _description;
        r.recipient = _recipient;
        r.value = _value;
        r.numVoters = 0;
        r.completed = false;

        emit CreateSpendingRequest(_description, _recipient, _value);
    }

    function voteForRequest(uint256 _index) external {
        Request storage request = requests[_index];
        require(donations[msg.sender] > 0);
        require(request.voters[msg.sender] == false);

        request.voters[msg.sender] = true;
        request.numVoters++;

        if (request.numVoters > numDonors / 2) {
            makePayment(_index);
        }

        emit VoteForRequest(_index, request.numVoters);
    }

    function getRequests() external view returns (string[] memory _descriptions, uint256[] memory _values, address[] memory _recipients, bool[] memory _completed, uint256[] memory _numVoters){
        string[] memory descriptions = new string[](numRequests);
        uint256[] memory values = new uint256[](numRequests);
        address[] memory recipients = new address[](numRequests);
        bool[] memory completed = new bool[](numRequests);
        uint256[] memory numVoters = new uint256[](numRequests);

        for (uint256 i = 0; i < numRequests; i++) {
            Request storage request = requests[i];
            descriptions[i] = request.description;
            values[i] = request.value;
            recipients[i] = request.recipient;
            completed[i] = request.completed;
            numVoters[i] = request.numVoters;
        }

        return (descriptions, values, recipients, completed, numVoters);
    }

    function getRequest(uint256 _index) external view returns (string memory _description, uint256 _value, address _recipient, bool _completed, uint256 _numVoters){
        return (requests[_index].description, requests[_index].value, requests[_index].recipient, requests[_index].completed, requests[_index].numVoters);
    }

    function getData() external view returns(address _owner, Stages _stage, uint256 _minimumDonation, uint256 _startedAt,  uint256 _deadline, uint256 _endedAt, uint256 _raisedAmount, uint256 _numDonations){
        return (getOwner(), stage, minimumDonation, startedAt, deadline, endedAt, raisedAmount, numDonations);
    }

    function getVotes(address _address) external view returns(bool[] memory _votes) {
        bool[] memory votes = new bool[](numRequests);

        for (uint256 i = 0; i < numRequests; i++) {
            votes[i] = requests[i].voters[_address];
        }

        return votes;
    }

    function makePayment(uint256 _index) internal {
        Request storage request = requests[_index];
        require(request.completed == false);
        //more or equal than 50% voted
        payable(request.recipient).transfer(request.value);
        request.completed = true;

        emit MakePayment(_index, request.value);
    }
}