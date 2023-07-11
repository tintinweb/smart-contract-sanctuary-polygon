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
        address payable requestor;
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

    struct GroupRequest {
        uint256 totalAmount;
        mapping(address => bool) acceptances;
        uint256 numberOfAcceptances;
        bool active;
        string description;
        address[] participants;
        address requestor;
    }

    mapping(address => uint) public numGroupRequests;
    mapping(address => mapping(uint => GroupRequest)) public userGroupRequests;

    event GroupRequestCreated(address creator, uint256 index);

    function createGroupRequest(
        uint256 totalAmount,
        string memory description,
        address[] memory participants
    ) public returns (uint) {
        uint requestIndex = numGroupRequests[msg.sender]++;

        GroupRequest storage newGroupRequest = userGroupRequests[msg.sender][
            requestIndex
        ];
        newGroupRequest.totalAmount = totalAmount;
        newGroupRequest.description = description;
        newGroupRequest.participants = participants;
        newGroupRequest.requestor = msg.sender;
        newGroupRequest.active = true;

        for (uint i = 0; i < participants.length; i++) {
            newGroupRequest.acceptances[participants[i]] = false;
        }

        emit GroupRequestCreated(msg.sender, requestIndex);

        return requestIndex;
    }

    function acceptGroupRequest(address creator, uint groupRequestId) public {
        // Fetch the groupRequest using the ID
        GroupRequest storage groupRequest = userGroupRequests[creator][
            groupRequestId
        ];

        // check  owner cannot acceptGroupRequest 
        require(groupRequest.requestor == msg.sender,"Creator cannot accept the request");

        // Check if the group request is active
        require(groupRequest.active, "Group request is not active");

        // Check if groupRequest has already been accepted by the current user
        require(
            !groupRequest.acceptances[msg.sender],
            "You have already accepted this request"
        );

        // Increment the numberOfAcceptances by 1
        groupRequest.numberOfAcceptances += 1;

        // Mark the current user's acceptance as true
        groupRequest.acceptances[msg.sender] = true;
    }


    function executeGroupRequest(address creator, uint groupRequestId) public {
        // Fetch the groupRequest using the ID
        GroupRequest storage groupRequest = userGroupRequests[creator][groupRequestId];

        // check if owner can of executeGroupRequest
        require(groupRequest.requestor == msg.sender,"Only Creator can execute Request");


        // Check if the group request is active
        require(groupRequest.active, "Group request is not active");

        // Check if numberOfAcceptances is more than 40%
        
        require(groupRequest.numberOfAcceptances > 0, "Not enough acceptances");

        // Split the total amount amongst all participants and convert to wei
        uint256 individualAmount = (groupRequest.totalAmount) / (groupRequest.participants.length + 1);

        // Create a request for each participant
        for (uint i = 0; i < groupRequest.participants.length; i++) {
            // Using createRequest() function to create a payment request for each participant
            createRequest(groupRequest.participants[i], individualAmount, "Group request payment");
        }

        // Mark the groupRequest as inactive
        groupRequest.active = false;
}




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

        require(msg.sender != _walletAddress,"Cannot add your address to friends list");

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
        friends[msg.sender].push(
            Friend(names[_walletAddress].name, _walletAddress)
        );
    }

    function getAllFriends(
        address _user
    ) public view returns (string[] memory, address[] memory) {
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
        // TODO: change 
        request memory newRequest;
        newRequest.requestor = payable(msg.sender); // person who is initiating the request
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

        payableRequest.requestor.transfer(toPay);

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