// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
 
contract Paypal {

    //Define the owner of the contract
    address public owner;

    constructor() {
        owner = msg.sender;
    }
    //Create Struct and Mapping for request, transaction & name

    struct request{
        address requestor;
        uint256 amount;
        string message;
        string name;
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


    // Add a name to a wallet address

    function addName(string memory _name) public {
        userName storage newUserName = names[msg.sender]; // names[msg.sender] returns address i guess?
        newUserName.name = _name;
        newUserName.hasName = true;
    }

    // Create a request

    function createRequest(address user, uint256 _amount, string memory _message) public {
        request memory newRequest;
        newRequest.requestor = msg.sender;
        newRequest.amount = _amount;
        newRequest.message = _message;
        if (names[msg.sender].hasName){
            newRequest.name = names[msg.sender].name;
        }
        requests[user].push(newRequest);
    }

    // Pay a request

    function payRequest (uint256 _request) public payable {

        require(_request < requests[msg.sender].length, "No such request");
        request[] storage myRequests = requests[msg.sender];
        request storage payableRequest = myRequests[_request];

        uint256 toPay = payableRequest.amount * 1000000000000000000;
        require(msg.value == (toPay), "Pay Correct Amount");

        payable(payableRequest.requestor).transfer(msg.value);

        addHistory(payableRequest.requestor, msg.sender, payableRequest.amount, payableRequest.message); 

        myRequests[_request] = myRequests[myRequests.length-1];
        myRequests.pop();
    }

    function addHistory (address sender, address receiver, uint256 _amount, string memory _message) private {
        
        sendReceive memory newSend;
        newSend.action = "-";
        newSend.amount = _amount;
        newSend.message = _message;
        newSend.otherPartyAddress = receiver;
        if (names[receiver].hasName){
            newSend.otherPartyName = names[receiver].name;
        }
        history[sender].push(newSend);

        sendReceive memory newReceive;
        newReceive.action = "+";
        newReceive.amount = _amount;
        newReceive.message = _message;
        newReceive.otherPartyAddress = sender;
        if (names[sender].hasName){
            newReceive.otherPartyName = names[sender].name;
        }
        history[receiver].push(newReceive);
    }


    // Get all requests sent to a user (API ??) returns 

    function getMyRequests(address _user) public view returns(
        address[] memory,
        uint256[] memory,
        string[] memory,
        string[] memory
    ){
        address[] memory addrs = new address[](requests[_user].length);
        uint256[] memory amnts = new uint256[](requests[_user].length);
        string[] memory msges = new string[](requests[_user].length);
        string[] memory nmes = new string[](requests[_user].length);

        for (uint i = 0; i<requests[_user].length; i++){
            request storage myRequest = requests[_user][i];
            addrs[i] = myRequest.requestor;
            amnts[i] = myRequest.amount;
            msges[i] = myRequest.message;
            nmes[i] = myRequest.name;
        }

        return (addrs, amnts, msges, nmes);
    }

    function getMyHistory(address _user) public view returns(sendReceive[] memory){
        return history[_user];
    }

    function getMyName(address _user) public view returns(userName memory){
        return names[_user];
    }

     
}