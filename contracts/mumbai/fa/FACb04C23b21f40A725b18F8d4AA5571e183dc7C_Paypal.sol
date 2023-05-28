// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Paypal {
    // Define the owner of the smart contract
    address public immutable i_owner;

    constructor() {
        i_owner = msg.sender;
    }

    // Create Struct and Mapping for request, transaction & name
    struct request {
        address requestor;
        uint256 amount;
        string message;
        string requestor_name;
    }

    struct send_receive {
        string action; // can be receiving or sending
        uint256 amount;
        string message;
        address otherPartyAddress;
        string otherPartyName;
    }

    struct user_name {
        string name;
        bool hasName;
    }

    mapping(address => user_name) names;
    mapping(address => request[]) requests;
    mapping(address => send_receive[]) history;

    // Add a name to wallet address
    function addName(string memory _name) public {
        user_name storage newUserName = names[msg.sender];
        newUserName.name = _name;
        newUserName.hasName = true;
    }

    // Create a request
    function createRequest(
        address _otherPartyAddress,
        uint256 _amount,
        string memory _message
    ) public {
        request memory newRequest;

        newRequest.requestor = msg.sender;
        newRequest.amount = _amount;
        newRequest.message = _message;
        if (names[msg.sender].hasName) {
            newRequest.requestor_name = names[msg.sender].name;
        }

        requests[_otherPartyAddress].push(newRequest);
    }

    // Pay a request

    function payRequest(uint256 _request_index) public payable {
        require(
            _request_index < requests[msg.sender].length,
            "Invalid request"
        );

        request[] storage myRequests = requests[msg.sender];
        request storage payableRequest = myRequests[_request_index];

        uint256 toPay = payableRequest.amount * 1000000000000000; // upto 3 decimal places
        require(msg.value == toPay, "pay correct amount");
        
        addHistory(
            msg.sender,
            payableRequest.requestor,
            payableRequest.amount,
            payableRequest.message
        );

        myRequests[_request_index] = myRequests[myRequests.length-1];
        myRequests.pop();
        
        payable(payableRequest.requestor).transfer(msg.value);
    }

    function addHistory(
        address _sender_address,
        address _receiver_address,
        uint256 _amount,
        string memory _message
    ) private {
        send_receive memory newSend;
        newSend.amount = _amount;
        newSend.action = "-";
        newSend.message = _message;
        newSend.otherPartyAddress = _receiver_address;
        if (names[_receiver_address].hasName) {
            newSend.otherPartyName = names[_receiver_address].name;
        }
        history[_sender_address].push(newSend);

        send_receive memory newReceive;
        newReceive.amount = _amount;
        newReceive.action = "+";
        newReceive.message = _message;
        newReceive.otherPartyAddress = _receiver_address;
        if (names[_sender_address].hasName) {
            newReceive.otherPartyName = names[_sender_address].name;
        }
        history[_receiver_address].push(newReceive);
    }

    // Get all requests sent to a user
    function getAllRequests(
        address _user_address
    )
        public
        view
        returns (
            address[] memory, // for address
            uint256[] memory, // for amount
            string[] memory, // for msgs
            string[] memory // for names
        )
    {
        uint256 total_requests = requests[_user_address].length;
        address[] memory all_address = new address[](total_requests); // can not use arr.push for memory array
        uint256[] memory all_amounts = new uint256[](total_requests);
        string[] memory all_msgs = new string[](total_requests);
        string[] memory all_names = new string[](total_requests); 

        for (uint i = 0; i < total_requests; i++) {
            request storage myRequest = requests[_user_address][i];
            all_address[i] = myRequest.requestor;
            all_amounts[i] = myRequest.amount;
            all_msgs[i] = myRequest.message;
            all_names[i] = myRequest.requestor_name;
        }

        // not passing struct array bcoz thats hard to read on node side
        return (all_address, all_amounts, all_msgs, all_names);
    }

    // Get all historic transactions user has been part of
    function getMyHistory(
        address _user_address
    ) public view returns (send_receive[] memory) {
        return history[_user_address];
    }

    function getMyName(
        address _user_address
    ) public view returns (user_name memory) {
        return names[_user_address];
    }
}