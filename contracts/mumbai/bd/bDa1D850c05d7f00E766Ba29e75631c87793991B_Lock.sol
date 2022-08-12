/**
 *Submitted for verification at polygonscan.com on 2022-08-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Lock {

    address public owner;

    constructor(){
        owner = msg.sender;
    }

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
    mapping(address  => request[]) requests;
    mapping(address  => sendReceive[]) history;

     function getMyRequests(address _user) public view returns(address[] memory, uint256[] memory, string[] memory, string[] memory){
        

        address[] memory addrs = new address[](requests[_user].length);
        uint256[] memory amnt = new uint256[](requests[_user].length);
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
    
    function getMyHistory(address _user) public view returns(
        string[] memory,
        uint256[] memory,
        string[] memory,
        address[] memory,
        string[] memory){

        string[] memory act = new string[](history[_user].length);
        uint256[] memory amnt = new uint256[](history[_user].length);
        string[] memory msge = new string[](history[_user].length);
        address[] memory addrs = new address[](history[_user].length);
        string[] memory nme = new string[](history[_user].length);
        
        for (uint i = 0; i < history[_user].length; i++) {
            sendReceive storage myHistorical = history[_user][i];
            act[i] = myHistorical.action;
            amnt[i] = myHistorical.amount;
            msge[i] = myHistorical.message;
            addrs[i] = myHistorical.otherPartyAddress;
            nme[i] = myHistorical.otherPartyName;
        }

        return(act, amnt, msge, addrs, nme);
    }

    function addName(string memory _name) public {
        userName storage newUserName = names[msg.sender];
        newUserName.name = _name;
        newUserName.hasName = true;
    }

    function createRequest(address user, uint256 _amount, string memory _message) public {
        request memory newRequest;
        newRequest.requestor = msg.sender;
        newRequest.amount = _amount;
        newRequest.message = _message;
        if(names[msg.sender].hasName){
            newRequest.name = names[msg.sender].name;
        }
        requests[user].push(newRequest);

    }

    function payRequest(uint256 _request) public payable {
        require(_request < requests[msg.sender].length, "No Such Request");
        request[] storage myRequests = requests[msg.sender];
        request storage payableRequest = myRequests[_request];
        
        uint256 toPay = payableRequest.amount * 1000000000000000000;
        require(msg.value == (toPay), "Pay Correct Amount");

        payable(payableRequest.requestor).transfer(msg.value);

        addHistory(msg.sender, payableRequest.requestor, payableRequest.amount, payableRequest.message);

        myRequests[_request] = myRequests[myRequests.length-1];
        myRequests.pop();
    }

    function addHistory(address sender, address receiver, uint256 _amount, string memory _message) private {
        sendReceive memory newSend;
        newSend.action = "Send";
        newSend.amount = _amount;
        newSend.message = _message;
        newSend.otherPartyAddress = receiver;
         if(names[receiver].hasName){
            newSend.otherPartyName = names[receiver].name;
        }
        history[sender].push(newSend);

        sendReceive memory newReceive;
        newReceive.action = "Receive";
        newReceive.amount = _amount;
        newReceive.message = _message;
        newReceive.otherPartyAddress = sender;
         if(names[sender].hasName){
            newSend.otherPartyName = names[sender].name;
        }
        history[receiver].push(newReceive);

    }

}