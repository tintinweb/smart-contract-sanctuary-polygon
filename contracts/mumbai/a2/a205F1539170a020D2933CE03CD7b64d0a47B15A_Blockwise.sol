// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
//import "hardhat/console.sol";

contract Blockwise {
    // Define the Owner of the smart contract

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    // Create struct and Mapping for request, transaction & name

    struct request {
        // our pending request
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

    struct Friend {
    string name;
    address walletAddress;
}

// Each user has a unique set of friends.
mapping(address => Friend[]) private friends;



    // struct GroupRequest {
    //     uint256 totalAmount;
    //     mapping(address => bool) acceptances;
    //     bool active;
    //     string description;
    // }

    // GroupRequest[] public groupRequests;

    // // Function to create a group request
    // function createGroupRequest(
    //     uint256 totalAmount,
    //     string memory description
    // ) public returns (uint) {
    //     GroupRequest storage newGroupRequest = groupRequests.push();
    //     newGroupRequest.totalAmount = totalAmount;
    //     newGroupRequest.active = true;
    //     newGroupRequest.description = description;
    //     return groupRequests.length - 1; // Returning index of created object in array
    // }

    // // Function for a friend to accept a group request
    // function acceptGroupRequest(uint groupRequestId, bool _active) public {
    //     GroupRequest storage groupRequest = groupRequests[groupRequestId];

    //     // Check if the request is active
    //     require(groupRequest.active, "Group request is not active");

    //     require(
    //         !groupRequest.acceptances[msg.sender],
    //         "You have already accepted the request"
    //     );

    //     // Mark the request as accepted by the sender
    //     groupRequest.acceptances[msg.sender] = _active;
    // }

    // // Function for sending messages within groups
    // // Function to execute the payment split of a group request
    // function executeGroupRequest(uint groupRequestId) public {
    //     GroupRequest storage groupRequest = groupRequests[groupRequestId];

    //     // Check that the request is active
    //     require(groupRequest.active, "Group request is not active");

    //     // Count the number of friends who have accepted and total friends involved in the request
    //     uint numberOfAcceptors = 0;
    //     uint totalFriends = friends.length;

    //     for (uint i = 0; i < totalFriends; i++) {
    //         if (groupRequest.acceptances[friends[i].walletAddress] == true) {
    //             numberOfAcceptors++;
    //         }
    //     }

    //     // Check if the acceptance is more than 40%
    //     require(
    //         (numberOfAcceptors * 100) / totalFriends >= 40,
    //         "At least 40% of friends need to accept the request before execution"
    //     );

    //     uint amountPerPersonInWei = (groupRequest.totalAmount * 1 ether) /
    //         numberOfAcceptors;

    //     for (uint i = 0; i < totalFriends; i++) {
    //         if (groupRequest.acceptances[friends[i].walletAddress] == true) {
    //             createRequest(
    //                 friends[i].walletAddress,
    //                 amountPerPersonInWei,
    //                 "Group Request Payment"
    //             );
    //         }
    //     }

    //     // Once the payment has been distributed, mark the group request as inactive
    //     groupRequest.active = false;
    // }

    //Struct for storing Requests and their status (pending/accepted or rejected).
    mapping(address => userName) names;
    mapping(address => request[]) requests;
    mapping(address => sendReceive[]) history;

    function addName(string memory _name) public {
        userName storage newUserName = names[msg.sender];
        newUserName.name = _name;
        newUserName.hasName = true;
    }

    // function addFriend(address _walletAddress, string memory _name) public {
    //     friends.push(Friend(_name, _walletAddress));
    // }

function addFriend(address _walletAddress) public {
    // Check if the friend's address exists in the names mapping and has a name
    require(
        names[_walletAddress].hasName == true,
        "This address has not interacted with the contract or set a name"
    );

    // Check for duplicates
    for (uint i = 0; i < friends[msg.sender].length; i++) {
        require(
            friends[msg.sender][i].walletAddress != _walletAddress,
            "This friend already exists"
        );
    }

    // Add friend
    friends[msg.sender].push(Friend(names[_walletAddress].name, _walletAddress));
}


function getAllFriends(address _user)
    public
    view
    returns (string[] memory, address[] memory)
{
    string[] memory friendNames = new string[](friends[_user].length);
    address[] memory friendAddresses = new address[](friends[_user].length);

    for (uint i = 0; i < friends[_user].length; i++) {
        Friend storage friend = friends[_user][i];
        friendNames[i] = friend.name;
        friendAddresses[i] = friend.walletAddress;
    }

    return (friendNames, friendAddresses);
}


    //Create a Request

    function createRequest(
        address user,
        uint256 _amount,
        string memory _message
    ) public {
        request memory newRequest;
        newRequest.requestor = msg.sender; // person who is initiating the request
        newRequest.amount = _amount;
        newRequest.message = _message;
        newRequest.blockTime = block.timestamp;
        if (names[msg.sender].hasName) {
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

        addHistory(
            msg.sender,
            payableRequest.requestor,
            payableRequest.amount,
            payableRequest.message,
            payableRequest.blockTime = block.timestamp
        );

        myRequests[_request] = myRequests[myRequests.length - 1];
        myRequests.pop();
    }

    function addHistory(
        address sender,
        address receiver,
        uint256 _amount,
        string memory _message,
        uint _blockTime
    ) private {
        sendReceive memory newSend;
        newSend.action = "Send";
        newSend.amount = _amount;
        newSend.message = _message;
        newSend.otherPartyAddress = receiver;
        newSend.blockTime = _blockTime;
        if (names[receiver].hasName) {
            newSend.otherPartyName = names[receiver].name;
        }
        history[sender].push(newSend);

        sendReceive memory newReceive;
        newReceive.action = "Receive";
        newReceive.amount = _amount;
        newReceive.message = _message;
        newReceive.otherPartyAddress = sender;
        newReceive.blockTime = _blockTime;
        if (names[sender].hasName) {
            newReceive.otherPartyName = names[sender].name;
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
            string[] memory,
            uint[] memory
        )
    {
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

    function getMyHistory(
        address _user
    ) public view returns (sendReceive[] memory) {
        return history[_user];
    }

    function getMyName(address _user) public view returns (userName memory) {
        return names[_user];
    }
}