// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract PayPal {

    //Define the owner of the smart contract
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    //Create Struct and Mapping for request, transaction & more

    struct request {
        address requestor;
        uint256 amount;
        string message;
        string requestorName;
    }

    struct sendReceive {
        string action;
        uint256 amount;
        string message;
        address otherPartyAddress;
        string otherPartyName;
    }

    struct userName {
        string name;
        bool hasName;
    }
    
    mapping(address => userName) names;
    mapping(address => request[]) requests;
    mapping(address => sendReceive[]) history;

    //Add a name to wallet request 1
    function addName1(string memory _name) public {
        names[msg.sender] = userName ({
            name: _name,
            hasName: true
        });
    }
    
    //Add a name to wallet request 2
    function addName2(string memory _name) public {
        userName storage newUserName = names[msg.sender];
        newUserName.name = _name;
        newUserName.hasName = true; 
    }
    
    //Create a request
    function createRequest(address user, uint256 _amount, string memory _message) public {
        request memory newRequest;
        newRequest.requestor = msg.sender;
        newRequest.amount = _amount;
        newRequest.message = _message;
        if(names[msg.sender].hasName) {
            newRequest.requestorName = names[msg.sender].name;
        }
        requests[user].push(newRequest);
    }

    //Pay a request. Takes _request which is the place in the array of the requests mapping that holds the requests array
    function payRequest(uint256 _request) public payable {
        require(_request < requests[msg.sender].length, "No such request exists");
        request[] storage myRequests = requests[msg.sender];
        request storage payableRequest = myRequests[_request];

        uint256 toPay = payableRequest.amount * 1000000000000000000;
        require(msg.value == (toPay), "Pay Correct Amount");

        //payable(payableRequest.requestor).transfer(msg.value)
        (bool success, ) = payable(payableRequest.requestor).call{value: msg.value}("");
        require (success, "Transfer Failed");

        addHistory(msg.sender, payableRequest.requestor, payableRequest.amount, payableRequest.message);

        myRequests[_request] = myRequests[myRequests.length - 1];
        myRequests.pop();
    }

    //AddHistory
    function addHistory(address sender, address receiver, uint256 _amount, string memory _message) private {
        sendReceive memory newReceive;
        newReceive.action = "+";
        newReceive.amount = _amount;
        newReceive.message = _message;
        newReceive.otherPartyAddress = sender;
        if (names[sender].hasName) {
            newReceive.otherPartyName = names[sender].name;
        }
        history[receiver].push(newReceive);
        
        sendReceive memory newSend;
        newSend.action = "-";
        newSend.amount = _amount;
        newSend.message = _message;
        newSend.otherPartyAddress = receiver;
        if(names[receiver].hasName) {
            newSend.otherPartyName = names[receiver].name;
        }
        history[sender].push(newSend);
    }
    
    //Get all requests sent to a user
    function getMyRequests(address _user) public view returns (
        address[] memory,
        uint256[] memory,
        string[] memory,
        string[] memory
    ) {
        address[] memory addrs = new address[](requests[_user].length);
        uint256[] memory amnt = new uint256[](requests[_user].length);
        string[] memory msge = new string[](requests[_user].length);
        string[] memory nme = new string[](requests[_user].length);

        for (uint i = 0; i < requests[_user].length; i++) {
            request storage myRequests = requests[_user][i];
            addrs[i] = myRequests.requestor;
            amnt[i] = myRequests.amount;
            msge[i] = myRequests.message;
            nme[i] = myRequests.requestorName;
        }

        return (addrs, amnt, msge, nme);

    }

    //Get all historical transactions user has been a part of

    function getMyHistory(address _user) public view returns (sendReceive[] memory) {
        return history[_user];
    }

    function getMyName(address _user) public view returns (userName memory) {
        return names[_user];
    }

}