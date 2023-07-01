// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
//import "hardhat/console.sol";

contract Blockwise {

// Define the Owner of the smart contract

address public owner;

constructor(){
    owner = msg.sender;
}

// Create struct and Mapping for request, transaction & name

struct request{ // our pending request
    address requestor;
    uint256 amount;
    string message;
    string name;
    uint blockTime;
}

struct sendReceive {
    string action;
    uint256 amount;
    string message;
    address otherPartyAddress;
    string otherPartyName;   
    uint blockTime;
}

struct userName {
    string name;
    bool hasName;
}

mapping(address => userName) names;
mapping(address => request[]) requests;
mapping(address => sendReceive[]) history;

function addName(string memory _name) public {
    
    userName storage newUserName = names[msg.sender];
    newUserName.name = _name;
    newUserName.hasName = true;

}

 //Create a Request

function createRequest(address user, uint256 _amount, string memory _message) public {
        
    request memory newRequest;
    newRequest.requestor = msg.sender; // person who is initiating the request
    newRequest.amount = _amount;
    newRequest.message = _message;
    newRequest.blockTime = block.timestamp;
    if(names[msg.sender].hasName){
        newRequest.name = names[msg.sender].name;
    }
    requests[user].push(newRequest); // pushing it to other person's requests

}

//Pay a Request

function payRequest(uint256 _request) public payable {
    
    require(_request < requests[msg.sender].length, "No Such Request");
    request[] storage myRequests = requests[msg.sender];
    request storage payableRequest = myRequests[_request];
        
    uint256 toPay = payableRequest.amount * 1000000000000000000;
    require(msg.value == (toPay), "Pay Correct Amount");

    payable(payableRequest.requestor).transfer(msg.value);

    addHistory(msg.sender, payableRequest.requestor, payableRequest.amount, payableRequest.message, payableRequest.blockTime);

    myRequests[_request] = myRequests[myRequests.length-1];
    myRequests.pop();

}

function addHistory(address sender, address receiver, uint256 _amount, string memory _message, uint _blockTime) private {
        
    sendReceive memory newSend;
    newSend.action = "Send";
    newSend.amount = _amount;
    newSend.message = _message;
    newSend.otherPartyAddress = receiver;
    newSend.blockTime = _blockTime;
    if(names[receiver].hasName){
        newSend.otherPartyName = names[receiver].name;
    }
    history[sender].push(newSend);

    sendReceive memory newReceive;
    newReceive.action = "Receive";
    newReceive.amount = _amount;
    newReceive.message = _message;
    newReceive.otherPartyAddress = sender;
    newReceive.blockTime = _blockTime;
    if(names[sender].hasName){
        newReceive.otherPartyName = names[sender].name;
    }
    history[receiver].push(newReceive);
}

  function getMyRequests(address _user) public view returns(
         address[] memory, 
         uint256[] memory, 
         string[] memory, 
         string[] memory,
         uint[] memory
){

        address[] memory addrs = new address[](requests[_user].length);
        uint256[] memory amnt = new uint256[](requests[_user].length);
        string[] memory msge = new string[](requests[_user].length);
        string[] memory nme = new string[](requests[_user].length);
        uint[] memory time = new uint[](requests[_user].length);
        
        for (uint i = 0; i < requests[_user].length; i++) {
            request storage myRequests = requests[_user][i];
            addrs[i] = myRequests.requestor;
            amnt[i] = myRequests.amount;
            msge[i] = myRequests.message;
            nme[i] = myRequests.name;
            time[i] = myRequests.blockTime;
        }
        
        return (addrs, amnt, msge, nme, time);        
         

}


//Get all historic transactions user has been apart of


function getMyHistory(address _user) public view returns(sendReceive[] memory){
        return history[_user];
}

function getMyName(address _user) public view returns(userName memory){
        return names[_user];
}

}