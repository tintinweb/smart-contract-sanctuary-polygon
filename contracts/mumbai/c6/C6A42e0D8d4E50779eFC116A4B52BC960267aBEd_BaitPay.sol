// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract BaitPay {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    struct request {
        address requestor;
        uint amount;
        string message;
        string name;
    }
    struct sendReceive {
        string action;
        uint amount;
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

    function addName(string memory _name) public {
        userName storage newUserName = names[msg.sender];
        newUserName.name = _name;
        newUserName.hasName = true;
    }

    function createRequest(
        address user,
        uint _amount,
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

    function payRequest(uint _request) public payable {
        require(_request < requests[msg.sender].length, "No such a request");
        request[] storage myRequests = requests[msg.sender];
        request storage payableRequest = myRequests[_request];

        uint toPay = payableRequest.amount * 1000000000000000000;
        require(msg.value == toPay, "pay correct Amount");

        payable(payableRequest.requestor).transfer(msg.value);
        addHistory(msg.sender,payableRequest.requestor,payableRequest.amount,payableRequest.message);

        myRequests[_request] = myRequests[myRequests.length - 1];
        myRequests.pop;
    }

    function addHistory(address sender,address receiver,uint _amount,string memory _message) private {
        sendReceive memory newSend;
        newSend.action = "-";
        newSend.amount = _amount;
        newSend.message = _message;
        newSend.otherPartyAddress = receiver;
        if (names[receiver].hasName) {
            newSend.otherPartyName = names[receiver].name;
        }
        history[sender].push(newSend);

        sendReceive memory newReceive;
        newReceive.action = "-";
        newReceive.amount = _amount;
        newReceive.message = _message;
        newReceive.otherPartyAddress = sender;
        if (names[sender].hasName) {
            newSend.otherPartyName = names[sender].name;
        }
        history[receiver].push(newReceive);
    }

    function getMyRequest(
        address _user
    )
        public
        view
        returns (
            address[] memory,
            uint[] memory,
            string[] memory,
            string[] memory
        )
    {
        address[] memory addrs = new address[](requests[_user].length);
        uint[] memory amnt = new uint[](requests[_user].length);
        string[] memory msge = new string[](requests[_user].length);
        string[] memory nme = new string[](requests[_user].length);

        for (uint i = 0; i < requests[_user].length; i++) {
            request storage myRequests = requests[_user][i];
            addrs[i] = myRequests.requestor;
            amnt[i] = myRequests.amount;
            msge[i] = myRequests.message;
            nme[i] = myRequests.name;
        }
        return (addrs, amnt, msge, nme);
    }

    function getMyHistory(
        address _user
    ) public view returns (sendReceive[] memory) {
        return history[_user];
    }

    function getMyName(address _user) public view returns (userName memory) {
        return names[_user];
    }
}