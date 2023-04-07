/**
 *Submitted for verification at polygonscan.com on 2023-04-06
*/

//TransferCurrency.sol: Transfer currencies between associated.abi
//Just transfer the main currency of the network (e.g matic, eth)

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

//import "./UsersDefinition.sol";

// @audit-issue - No roles in this contract

contract TransferCurrency {


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

    //Add a name to wallet address to identify the transaction
    function addName(string memory _name) external {
        //remember to use storage if you want to store in de database
        userName storage newUserName = names[msg.sender];
        newUserName.name = _name;
        newUserName.hasName = true;
    }

    //Create a request to transfer currency
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

    function payRequest(uint _request) external payable {
        require(_request < requests[msg.sender].length, "No such Request");
        request[] storage myRequests = requests[msg.sender];
        request storage payableRequest = myRequests[_request];

        uint toPay = payableRequest.amount * 1000000000000000000;
        require(msg.value == (toPay), "Pay the correct amount");

        // @audit-issue - maybe change transfer for call
        payable(payableRequest.requestor).transfer(msg.value);

        // @audit-issue - Reentrancy alert: This maybe goes before the transfer

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
        uint _amount,
        string memory _message
    ) private {
        //The sender substract
        sendReceive memory newSend;
        newSend.action = "-";
        newSend.amount = _amount;
        newSend.message = _message;
        newSend.otherPartyAddress = receiver;
        if (names[receiver].hasName) {
            newSend.otherPartyName = names[receiver].name;
        }
        history[sender].push(newSend);

        //The receive add
        sendReceive memory newReceive;
        newReceive.action = "+";
        newReceive.amount = _amount;
        newReceive.message = _message;
        newReceive.otherPartyAddress = sender;
        if (names[sender].hasName) {
            newSend.otherPartyName = names[sender].name;
        }
        history[sender].push(newReceive);
    }

    function getMyRequets(
        address _user
    )
        external
        view
        returns (
            address[] memory,
            uint[] memory,
            string[] memory,
            string[] memory
        )
    {
        //We just need TEMPORARY variables
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