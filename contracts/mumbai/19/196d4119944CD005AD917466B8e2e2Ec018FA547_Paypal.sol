// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Paypal{
    address public owner;
    constructor(){
        owner = msg.sender;
    }

    struct request{
        address requestor;
        uint256 amount;
        string message;
        string name;
    }

    struct sendRecieve{
        string action;
        uint256 amount;
        string message;
        address otherPartyAddress;
        string otherPartyName;
    }
    struct userName{
        string name;
        bool hasName;
    }
    
    mapping(address => userName) names;
    mapping(address => request[]) requests;
    mapping(address => sendRecieve[]) history;

    //Adding User

    function addName(string memory _name) public{
        userName storage newUserName = names[msg.sender];
        newUserName.name = _name;
        newUserName.hasName = true;
    }   

    //Creating request

    function createRequest( address user , uint256 _amount , string memory _message) public {
        request memory newRequest;
        newRequest.requestor = msg.sender;
        newRequest.amount = _amount;
        newRequest.message = _message;
        if(names[msg.sender].hasName){
            newRequest.name = names[msg.sender].name;
        }
        requests[user].push(newRequest);
    }

    //Pay a request

    function payRequest(uint256 _request) payable public{
        require(_request < requests[msg.sender].length , "No Such Request Available");
        request[] storage myRequests = requests[msg.sender];
        request storage payableRequest = myRequests[_request];
        uint256 amount = payableRequest.amount * 1 ether;
        require(msg.value == amount , "Pay Correct Amount");
        payable(payableRequest.requestor).transfer(msg.value);

        addHistory(msg.sender, payableRequest.requestor, payableRequest.amount, payableRequest.message);
        //swapping last element to current and pop
        myRequests[_request] = myRequests[myRequests.length - 1];
        myRequests.pop();
    }

    function addHistory(address sender,address reciever , uint256 _amount ,string memory _message) private{
        sendRecieve memory newSend;
        newSend.action = "-";
        newSend.amount = _amount;
        newSend.message = _message;
        newSend.otherPartyAddress = reciever;
        if(names[reciever].hasName){
            newSend.otherPartyName = names[reciever].name;
        }
        history[sender].push(newSend);

        sendRecieve memory newRecieve;
        newRecieve.action = "+";
        newRecieve.amount = _amount;
        newRecieve.message = _message;
        newRecieve.otherPartyAddress = sender;
        if(names[sender].hasName){
            newRecieve.otherPartyName = names[sender].name;
        }
        history[reciever].push(newRecieve);
    }

    //getting requests 
    function getMyRequests(address _user) public view returns(address[] memory , uint256[] memory , string[] memory , string[] memory){
        uint noOfRequests = requests[_user].length;
        address[] memory addrs = new address[](noOfRequests);
        uint256[] memory amnt = new uint256[](noOfRequests);
        string[] memory mssg = new string[](noOfRequests);
        string[] memory nme = new string[](noOfRequests);

        for(uint i =0 ; i < noOfRequests ; i++){
            request storage myRequests = requests[_user][i];
            addrs[i] = myRequests.requestor;
            amnt[i] = myRequests.amount;
            mssg[i] = myRequests.message;
            nme[i] = myRequests.name;
        }
        return(
            addrs , amnt , mssg , nme
        );
    }

    function getMyHistory(address _user) public view returns(sendRecieve[] memory){
        return history[_user];
    }

    function getMyName(address _user) public view returns(userName memory){
        return names[_user];
    }
}