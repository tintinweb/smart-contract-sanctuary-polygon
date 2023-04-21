// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Ishyura {
    // Owner of the contract 

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    // All necessary structs and mappings 

    struct request {
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

    // Function to add name to wallet address 

    function addNameToAddress(string memory _name) public {
        userName storage newUserName = names[msg.sender];
        newUserName.name = _name;
        newUserName.hasName = true;
    }

    // Function to create a request 

    function createRequest(
        address user,
        uint256 _amount,
        string memory _message
    ) public {
        request memory newRequest;
        newRequest.requestor = msg.sender;
        newRequest.amount = _amount;
        newRequest.message = _message;
        if (names[msg.sender].hasName) {
            newRequest.name = names[msg.sender].name;
        }
        requests[user].push(newRequest);
    }

    // Function to pay a request 

    function payRequest(uint256 _request) public payable {
        require(_request < requests[msg.sender].length, "No such request.");
        request[] storage myRequests = requests[msg.sender];
        request storage payableRequest = myRequests[_request];

        uint256 toPay = payableRequest.amount * 1000000000000000000;
        require(msg.value == (toPay), "Pay correct amount.");

        payable(payableRequest.requestor).transfer(msg.value);
        addHistory(
            msg.sender,
            payableRequest.requestor,
            payableRequest.amount,
            payableRequest.message
        );

        myRequests[_request] = myRequests[myRequests.length - 1];
        myRequests.pop();
    }

    function addHistory(
        address sender,
        address receiver,
        uint256 _amount,
        string memory _message
    ) private {
        sendReceive memory newSend;
        newSend.action = "-";
        newSend.amount = _amount;
        newSend.message = _message;
        newSend.otherPartyAddress = receiver;
        if (names[receiver].hasName) {
            newSend.otherPartyName = names[receiver].name;
        }
        history[sender].push(newSend);

        sendReceive memory newRecieve;
        newRecieve.action = "+";
        newRecieve.amount = _amount;
        newRecieve.message = _message;
        newRecieve.otherPartyAddress = sender;
        if (names[sender].hasName) {
            newRecieve.otherPartyName = names[sender].name;
        }
        history[receiver].push(newRecieve);
    }

    // Function to get all requests sent by a user

    function getMyRequests(
        address _user
    )
        public
        view
        returns (
            address[] memory,
            uint256[] memory,
            string[] memory,
            string[] memory
        )
    {
        address[] memory addrs = new address[](requests[_user].length);
        uint256[] memory amount = new uint256[](requests[_user].length);
        string[] memory message = new string[](requests[_user].length);
        string[] memory name = new string[](requests[_user].length);

        for (uint i = 0; i < requests[_user].length; i++) {
            request storage myRequests = requests[_user][i];
            addrs[i] = myRequests.requestor;
            amount[i] = myRequests.amount;
            message[i] = myRequests.message;
            name[i] = myRequests.name;
        }

        return (addrs, amount, message, name);
    }
    // Function to get all historic transactions a user has been part of  

    function getHistory (address _user) public view returns (sendReceive[] memory){
        return history[_user];
    }
    
    function getName (address _user) public view returns (userName memory){
        return names[_user];
    }
}