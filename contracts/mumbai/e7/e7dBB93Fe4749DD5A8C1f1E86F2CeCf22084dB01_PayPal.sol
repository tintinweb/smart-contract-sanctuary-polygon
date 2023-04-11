// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract PayPal {
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
        string otherParyName;
        address otherParyAddress;
    }

    struct UserName {
        string name;
        bool hasName;
    }

    address public owner;

    mapping(address => UserName) names;
    mapping(address => Request[]) requests;
    mapping(address => SendReceive[]) history;

    constructor() {
        owner = msg.sender;
    }

    function addName(string memory _name) public {
        UserName storage newUserName = names[msg.sender];
        newUserName.name = _name;
        newUserName.hasName = true;
    }

    function createRequest(
        address user,
        uint256 _amount,
        string memory _message
    ) public {
        Request memory newRequest;
        newRequest.requestor = msg.sender;
        newRequest.message = _message;
        newRequest.amount = _amount;

        if (names[msg.sender].hasName) {
            newRequest.name = names[msg.sender].name;
        } else {
            newRequest.name = "NoName";
        }

        requests[user].push(newRequest);
    }

    function payRequest(uint256 _request) public payable {
        require(_request < requests[msg.sender].length, "No Such Request.");
        Request[] storage myRequests = requests[msg.sender];
        Request storage payableRequest = myRequests[_request];

        uint256 toPay = payableRequest.amount * 1000000000000000000;
        require(msg.value == (toPay), "Not Correct Amount.");

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
        SendReceive memory newSend;
        newSend.action = "-";
        newSend.amount = _amount;
        newSend.message = _message;
        newSend.otherParyAddress = receiver;

        if (names[receiver].hasName) {
            newSend.otherParyName = names[receiver].name;
        } else {
            newSend.otherParyName = "NoName";
        }

        history[sender].push(newSend);

        SendReceive memory newReceive;
        newReceive.action = "+";
        newReceive.amount = _amount;
        newReceive.message = _message;
        newReceive.otherParyAddress = sender;

        if (names[receiver].hasName) {
            newReceive.otherParyName = names[receiver].name;
        } else {
            newReceive.otherParyName = "NoName";
        }

        history[receiver].push(newReceive);
    }

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
        uint256[] memory amnt = new uint256[](requests[_user].length);
        string[] memory msgs = new string[](requests[_user].length);
        string[] memory nmes = new string[](requests[_user].length);

        for (uint i = 0; i < requests[_user].length; i++) {
            Request storage myRequests = requests[_user][i];

            addrs[i] = myRequests.requestor;
            amnt[i] = myRequests.amount;
            msgs[i] = myRequests.message;
            nmes[i] = myRequests.name;
        }

        return (addrs, amnt, msgs, nmes);
    }

    function getMyHistory(
        address _user
    ) public view returns (SendReceive[] memory) {
        return history[_user];
    }

    function getMyName(address _user) public view returns (UserName memory) {
        return names[_user];
    }
}