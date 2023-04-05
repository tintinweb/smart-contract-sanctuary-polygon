// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract PaypalTransact {

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    // Struct and mapping
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
        address otherAddress;
        string otherName;
    }

    struct UserName {
        string name;
        bool hasName;
    }

    mapping(address => UserName) names;
    mapping(address => Request[]) requests;
    mapping(address => SendReceive[]) history;

    // Add new user name
    function addName(string memory _name) public {
        UserName storage newUserName = names[msg.sender];
        newUserName.name = _name;
        newUserName.hasName = true;
    }

    // Create new request
    function createRequest(address user, uint256 _amount, string memory message) public {
        Request memory newRequest;

        newRequest.requestor = msg.sender;
        newRequest.amount = _amount;
        newRequest.message = message;
        
        if (names[user].hasName) {
            newRequest.name = names[user].name;
        }

        requests[user].push(newRequest);
    }

    // Pay a request for user
    function payRequest(uint256 _request) public payable {
        require(_request < requests[msg.sender].length, "No such request");

        Request[] storage myRequests = requests[msg.sender];
        Request storage payableRequest = myRequests[_request];

        uint256 amountToPay = payableRequest.amount * 1000000000000000000;
        require(amountToPay == msg.value, "Pay correct amount");

        payable(payableRequest.requestor).transfer(amountToPay);

        myRequests[_request] = myRequests[myRequests.length - 1];
        myRequests.pop();
    }

    // Get all requests of a user
    function getRequests(address _user) public view returns (
        address[] memory _addrs,
        uint256[] memory _amounts,
        string[] memory _messages,
        string[] memory _names
    ) {
        uint length = requests[_user].length;
        _addrs = new address[](length);
        _amounts = new uint256[](length);
        _messages = new string[](length);
        _names = new string[](length);

        for (uint i = 0; i < length; i++) {
            Request storage _request = requests[_user][i];
            _addrs[i] = _request.requestor;
            _amounts[i] = _request.amount;
            _messages[i] = _request.message;
            _names[i] = _request.name;
        }
    }

    // Get history of specific user
    function getHistory(address _user) public view returns (SendReceive[] memory) {
        return history[_user];
    }

    // Get user name of a user
    function getName(address _user) public view returns (UserName memory) {
        return names[_user];
    }

}