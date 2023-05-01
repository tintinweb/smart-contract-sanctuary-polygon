// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Paypal {
    // Define the owner of the contract
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    // Create struct and mapping for requests, transactions and name.

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

    // Add a name to the wallet address
    function addName(string memory _name) public {
        userName storage newUserName = names[msg.sender];
        newUserName.name = _name;
        newUserName.hasName = true;
    }

    // Create a request
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
        } else {
            newRequest.name = "Anonymous";
        }

        requests[user].push(newRequest);
    }

    // pay a request
    function payRequest(uint256 _request) public payable {
        require(_request < requests[msg.sender].length, "Invalid request");
        request[] storage myRequests = requests[msg.sender];
        request storage payableRequest = myRequests[_request];

        uint256 toPay = payableRequest.amount * 1000000000000000000;
        require(msg.value == (toPay), "Invalid amount");

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

    // Add history
    function addHistory(
        address sender,
        address receiver,
        uint256 _amount,
        string memory _message
    ) private {
        sendReceive memory newSend;
        newSend.action = "-";
        newSend.message = _message;
        newSend.amount = _amount;
        newSend.otherPartyAddress = receiver;
        if (names[receiver].hasName) {
            newSend.otherPartyName = names[receiver].name;
        }

        history[sender].push(newSend);

        sendReceive memory newReceive;
        newReceive.action = "+";
        newReceive.message = _message;
        newReceive.amount = _amount;
        newReceive.otherPartyAddress = sender;
        if (names[sender].hasName) {
            newReceive.otherPartyName = names[sender].name;
        }

        history[receiver].push(newReceive);
    }

    // Get all requests for a user
    function getMyRequest(
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
        request[] memory myRequests = requests[_user];
        address[] memory requestors = new address[](myRequests.length);
        uint256[] memory amounts = new uint256[](myRequests.length);
        string[] memory messages = new string[](myRequests.length);
        string[] memory nms = new string[](myRequests.length);

        for (uint256 i = 0; i < myRequests.length; i++) {
            requestors[i] = myRequests[i].requestor;
            amounts[i] = myRequests[i].amount;
            messages[i] = myRequests[i].message;
            nms[i] = myRequests[i].name;
        }

        return (requestors, amounts, messages, nms);
    }

    // Get all history for a user
    function getMyHistory(
        address _user
    ) public view returns (sendReceive[] memory) {
        return history[_user];
    }

    // Get the names for a user
    function getNames(address _user) public view returns (userName memory) {
        return names[_user];
    }
}