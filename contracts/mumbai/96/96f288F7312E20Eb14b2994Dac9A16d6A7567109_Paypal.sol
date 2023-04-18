// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Paypal {

//Define the Owenship of the contract

address public owner;

constructor() {
    owner = msg.sender;
}

//Create Sruct and Mapping for request, transaction and name

struct request {
    address requestor;
    uint256 amount;
    string message;
    string name;
}

struct sendReceive {
    address otherPartyAddress;
    uint256 amount;
    string message;    
    string action;
    string otherPartyName;
}

struct userName {
    string name;
    bool hasName;
}

mapping(address => userName) names;
mapping(address => request[]) requests;
mapping(address => sendReceive[]) history;


//Add a name to wallet address

function addName(string memory _name) public {

    userName storage newUserName = names[msg.sender];
    names[msg.sender].name = _name;
    names[msg.sender].hasName = true;
}


//Create a request for payment

function createRequest(address user, uint256 _amount, string memory _message) public {

    request memory newRequest;
    newRequest.requestor = msg.sender;
    newRequest.amount = _amount;
    newRequest.message = _message;
    if(names[msg.sender].hasName){
        newRequest.name = names[msg.sender].name;
    } 
    requests[user].push(newRequest);

}

//Pay a request

function payRequest(uint256 _request) public payable {

    require(_request < requests[msg.sender].length, "Request does not exist");
    request[] storage myRequests = requests[msg.sender];
    request storage payableRequest = myRequests[_request];

    uint256 toPay = payableRequest.amount * 1000000000000000000;
    
    payable(payableRequest.requestor).transfer(msg.value);

    addHistory(msg.sender, payableRequest.requestor, payableRequest.amount, payableRequest.message);
    myRequests[_request] = myRequests[myRequests.length - 1];
    myRequests.pop();
    
}

function addHistory(address sender, address receiver, uint256 _amount, string memory _message) private {

    sendReceive memory newSend;
    newSend.action = "-";
    newSend.amount = _amount;
    newSend.message = _message;
    newSend.otherPartyAddress = receiver;
    if(names[receiver].hasName){
        newSend.otherPartyName = names[receiver].name;
    }
    history[sender].push(newSend);

    sendReceive memory newReceive;
    newReceive.action = "+";
    newReceive.amount = _amount;
    newReceive.message = _message;
    newReceive.otherPartyAddress = sender;
    if(names[sender].hasName){
        newReceive.otherPartyName = names[sender].name;
    }
}

//Get all requests to a name

function getMyRequests(address _user) public view returns(
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
        addrs[i] = requests[_user][i].requestor;
        amnt[i] = requests[_user][i].amount;
        msge[i] = requests[_user][i].message;
        nme[i] = requests[_user][i].name;
    }

    return (addrs, amnt, msge, nme);
}

//Get all the historic transactions user has been apart of

function getMyHistory(address _user) public view returns(sendReceive[] memory){
    return history[_user];
}

function getMyName(address _user) public view returns(string memory) {
    return names[_user].name;
}

}