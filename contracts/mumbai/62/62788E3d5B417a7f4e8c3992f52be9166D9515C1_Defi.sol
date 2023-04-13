// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Defi{

    //Define the owner of the Smartcontract
    //who actually deployed this contract can actually see the contract
    address public owner;

    constructor(){
        owner = msg.sender;
    }

    //create Struct and Mapping for request, transaction & name
    struct request{
        address requestor;
        uint256 amount;
        string message;
        string name;   //name of the requestor
    }

    struct sendReceive{
        string action;  //send or recieve action
        uint256 amount;
        string message;
        address otherPartyAddress;
        string otherPartyName;
    }

    struct userName{
        string name;   //By default name is empty string and bool is false
        bool hasName; //whether they actually have the name
    }

    mapping(address => userName) names; //only readable from Smart contracts 
    mapping(address => request[]) requests;
    mapping(address => sendReceive[]) history;

    

    //Add a name to wallet Address
    function addName(string memory _name) public{
        userName storage newUserName = names[msg.sender]; //struct(datatype)-userName storage save the variable in smartcontract - storing -  whoever calls the function they're changing their ownname in the mapping
        newUserName.name = _name;
        newUserName.hasName = true;
    }

    // Create a Request 
    function createRequest(address user, uint256 _amount, string memory _message) public{
            request memory newRequest; 
            newRequest.requestor = msg.sender;  //function caller as the requestor
            newRequest.amount = _amount;
            newRequest.message = _message;
            if(names[msg.sender].hasName){   // To figure out  if this wallet address who's sending the create request has a name we can write a little conditional over here so we can check the names mapping for the message sender and we check the boolean whether they have set a name for themselves
                newRequest.name = names[msg.sender].name;
            } 
            requests[user].push(newRequest);  //we get the requests for the user that we're sending the request to and then we push this new request struct into that array of requests
    }
    //Pay a request
    function payRequest(uint256 _request) public payable{
        require(_request < requests[msg.sender].length, "No such Request");   //It checks the statement if passes it continues or it excecutes the string
        request[] storage myRequests = requests[msg.sender];
        request storage payableRequest = myRequests[_request];

        uint256 toPay = payableRequest.amount * 1000000000000000000;
        require(msg.value == (toPay), "Pay Correct Amount");  //how much currency you send with the transaction == is same as the topay amount

        payable (payableRequest.requestor).transfer(msg.value); //here it is paying the amount which have requested from the user 

        addHistory(msg.sender, payableRequest.requestor,payableRequest.amount,payableRequest.message);
        //call befor the we pop the request from our requests so that we know taht transaction is paid so
        //we add a function call to addHistory over pop
        myRequests[_request] = myRequests[myRequests.length-1];    //take last request in the array and pop out since the request already satisfied
        myRequests.pop();
    }
//Now to check the history whether our transacation has been done for that proof create another function
//private becuse should be call within the function , will put a little function call within the payrequest function that allows us to call the history
//this allow us to call that history and allows us to avoid anyone in the public and adding transactions that didnt actually occur
function addHistory(address sender, address reciever,uint256 _amount, string memory _message) private{
    sendReceive memory newSend;    //sendRecieve is a struct datatype
    newSend.action =" - ";    //-ve Symbol because the user is loosing funds
    newSend.amount = _amount;
    newSend.message =_message;
    newSend.otherPartyAddress = reciever;
    //If the reciever Address has a name in the mapping we take that name and set it as other party name
    //otherwise leave it as a empty string
    if(names[reciever].hasName){
        newSend.otherPartyName = names[reciever].name;
    }
    history[sender].push(newSend); //from history mapping get the sender address and push newsend struct into mapping 

    sendReceive memory newRecieve;    //sendRecieve is a struct datatype
    newRecieve.action =" + ";    //+ve Symbol because the user is  Gaining funds
    newRecieve.amount = _amount;
    newRecieve.message =_message;
    newRecieve.otherPartyAddress = sender;
    //If the reciever Address has a name in the mapping we take that name and set it as other party name
    //otherwise leave it as a empty string
    if(names[reciever].hasName){
        newRecieve.otherPartyName = names[sender].name;
    }
    history[reciever].push(newRecieve); // we're pushing  into reciever history mapping
}
    //Get all requests sent to a user
    function getMyRequests(address _user) public view returns(
        address[] memory,
        uint256[] memory,
        string[] memory,
        string[] memory
    ){
        address[] memory addrs = new address[](requests[_user].length);  // requests mapping
        uint256[] memory amnt = new uint256[](requests[_user].length);
        string[] memory msge = new string[](requests[_user].length);
        string[] memory nme = new string[](requests[_user].length);

        for(uint i=0;i< requests[_user].length;i++){
            request storage myRequests = requests[_user][i];
            addrs[i] = myRequests.requestor;
            amnt[i] = myRequests.amount;
            msge[i] = myRequests.message;
            nme[i] = myRequests.name;

        }
        return (addrs,amnt,msge,nme);  //return array of addrs,amnt ...
    }

    //Get all historic transactions user has been apart of
function getMyHistory(address _user) public view returns(sendReceive[] memory){
    return history[_user];
}
 //Retrive only user name
function getMyName(address _user) public view returns (userName memory){
    return names[_user];
}
}