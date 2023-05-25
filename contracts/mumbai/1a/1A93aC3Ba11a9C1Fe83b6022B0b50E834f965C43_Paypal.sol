// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Paypal {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    struct Request {
        address requestor;
        uint256 amount;
        string message;
        string name;
    }

    struct SendReceive {
        string action;
        uint256 amount;
        string message;
        address otherPartyAddress;
        string otherPartyName;
    }

    struct UserName {
        string name;
        bool hasName;
    }

    mapping (address=> UserName) names;
    mapping (address=> Request[]) requests;
    mapping (address=> SendReceive[]) history;

    function addName(string memory _name) public {
        UserName storage newUserName = names[msg.sender];
        newUserName.name = _name;
        newUserName.hasName = true;
        
    }

    function createRequest(address _user, uint256 _amount, string memory _message) public {
        Request memory newRequest;
        newRequest.requestor = msg.sender;
        newRequest.amount = _amount;
        newRequest.message = _message;
        if (names[msg.sender].hasName) {
            newRequest.name = names[msg.sender].name;
        }
        requests[_user].push(newRequest);
    }

    function payRequest(uint256 _request) public payable {
        require(_request < requests[msg.sender].length, "No Such Request");
        Request[] storage myRequests = requests[msg.sender];
        Request storage payableRequest = myRequests[_request];

        uint256 toPay = payableRequest.amount * 1000000000000000000;
        require(msg.value == toPay, "Pay Correct Amount");
        
        addHistory(msg.sender, payableRequest.requestor, 
            payableRequest.amount, payableRequest.message);

        myRequests[_request] = myRequests[myRequests.length - 1];
        myRequests.pop();
    }

    function addHistory(address _sender, address _receiver, 
        uint256 _amount, string memory _message) private 
    {
        //Sending Transaction
        SendReceive memory newSend;
        newSend.action = "-";
        newSend.amount = _amount;
        newSend.message = _message;
        newSend.otherPartyAddress = _receiver;
        if (names[_receiver].hasName){
            newSend.otherPartyName = names[_receiver].name;
        }
        history[_sender].push(newSend);

        //Receiving Transaction
        SendReceive memory newReceive;
        newReceive.action = "+";
        newReceive.amount = _amount;
        newReceive.message = _message;
        newReceive.otherPartyAddress = _sender;
        if (names[_sender].hasName){
            newReceive.otherPartyName = names[_sender].name;
        }
        history[_receiver].push(newReceive);

    }

    function getMyRequests(address _user) public view returns 
    ( address[] memory, uint256[] memory, string[] memory, string[] memory) 
    {
        address[] memory addres = new address[](requests[_user].length);    
        uint256[] memory amount = new uint256[](requests[_user].length);    
        string[] memory message = new string[](requests[_user].length);    
        string[] memory name = new string[](requests[_user].length);

        for (uint256 i = 0; i < requests[_user].length; i++) {
            Request storage myRequests = requests[_user][i];
            addres[i] = myRequests.requestor;
            amount[i] = myRequests.amount;
            message[i] = myRequests.message;
            name[i] = myRequests.name; 
        }    
        return (addres, amount, message, name);
    }

    function getMyHistory(address _user) public view returns (SendReceive[] memory){
        return history[_user];
    }

    function getMyName(address _user) public view returns (UserName memory){
        return names[_user];
    }

}