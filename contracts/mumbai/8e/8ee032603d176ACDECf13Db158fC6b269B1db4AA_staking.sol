/**
 *Submitted for verification at polygonscan.com on 2022-05-27
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;


contract staking {

    mapping(address => uint) public spenders;
    address public host;
    uint public lowlimitCntrbtn;
    uint public timelimit;
    uint public goal;
    uint public raisedCntrbtn;
    uint public numSpender;


    struct Request {
        string description;
        address payable recipient;
        uint value;
        bool completed;
        uint numVoters;
        mapping(address => bool) voters;
    }

    mapping(uint => Request) requests;
    uint public numRequests;


    constructor() {
        host = msg.sender;
        goal = 30000;
        timelimit = block.timestamp + 3600; //1hour = 3600 sec
        lowlimitCntrbtn = 100 wei;
    }


    function sendAmnt() public payable {
        require(block.timestamp < timelimit, "You have crossed timelimit to spend");
        require(msg.value > lowlimitCntrbtn, " Please spend more amount than lowlimitCntrbtn ");

        if (spenders[msg.sender] == 0) {
            numSpender++;
        }
        spenders[msg.sender] += msg.value;
        raisedCntrbtn += msg.value;
    }

    function getContractBalance() public view returns(uint) {
        return address(this).balance;
    }

    function payback() public {
        require(block.timestamp > timelimit && goal > raisedCntrbtn, "Sorry you are not eligible");
        require(spenders[msg.sender] > 0);
        address payable user = payable(msg.sender);
        user.transfer(spenders[msg.sender]);
        spenders[msg.sender] = 0;
    }


    modifier onlyhost() {
        require(msg.sender == host, "Only host can call this");
        _;
    }

    function createRequests(string memory _description, address payable _recipient, uint _value) public onlyhost {
        Request storage newRequest = requests[numRequests];
        numRequests++;
        newRequest.description = _description;
        newRequest.recipient = _recipient;
        newRequest.value = _value;
        newRequest.completed = false;
        newRequest.numVoters = 0;
    }

    function voterRequest(uint _requestno) public {
        require(spenders[msg.sender] > 0, "you must be a spender first");
        Request storage thisRequest = requests[_requestno];
        require(thisRequest.voters[msg.sender] == false, "you have already voted");
        thisRequest.voters[msg.sender] = true;
        thisRequest.numVoters++;
    }

    function makePayment(uint _requestno) public onlyhost {
        require(raisedCntrbtn >= goal);
        Request storage thisRequest = requests[_requestno];
        require(thisRequest.completed == false, "The request have been completed");
        require(thisRequest.numVoters > numSpender / 2, "Majority have not supportecd this");
        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed = true;
    }


}