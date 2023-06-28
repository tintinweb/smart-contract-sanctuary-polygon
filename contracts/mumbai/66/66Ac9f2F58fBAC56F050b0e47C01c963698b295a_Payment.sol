// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Payment {

    address public owner;

    constructor(){
        owner = msg.sender; // here we declare owner
    }


//here we define the strucct and mapping for sending ,receving functions and get username of acoount
    struct requesting{
        address requestor;
        uint256 amount;
        string messages;
        string name;
    }

    struct sender {
        string action;
        uint256 amount;
        string messages;
        address otherAccount;
        string otherAccName;
    }

    struct userName{
        string name;
        bool haveName;
    }

    mapping (address => userName) names;
    
    mapping (address => requesting[]) requests;
    
    mapping (address => sender[]) history;


    function addName(string memory _name) public{ // this function we use to declare or add the name of wallet
        userName storage newUser = names[msg.sender];
        newUser.name=_name;
        newUser.haveName = true;

    }

//requesting for payments
    function createRequest(address  user, uint256 _amount,string memory _message) public{
        requesting memory newRequest;
        newRequest.requestor = msg.sender;
        newRequest.amount = _amount;
        newRequest.messages =_message;
        if(names[msg.sender].haveName){
            newRequest.name=names[msg.sender].name;
        }
            requests[user].push(newRequest);
    }

    function payRequest(uint256 _request)public payable{

        require(_request < requests[msg.sender].length,"No such request");
        requesting[] storage myRequests = requests[msg.sender];
        requesting storage payableRequest = myRequests[_request];

        uint256 toPay = payableRequest.amount*1000000000000000000;
        require(msg.value ==(toPay),"Correct amount");
       
        payable (payableRequest.requestor).transfer(msg.value);

        addHistory(msg.sender, payableRequest.requestor, payableRequest.amount, payableRequest.messages);

myRequests[_request] = myRequests[myRequests.length-1];
myRequests.pop();
    

    }

    function addHistory (address senders , address receiver ,uint256 _amount, string memory _message) private{
        sender memory newSend;
        newSend.action="-";
        newSend.amount =_amount;
        newSend.messages=_message;
        newSend.otherAccount = receiver;
        if(names[receiver].haveName){
            newSend.otherAccName =names[receiver].name;
        }
        history[senders].push(newSend);


         sender memory newReceive;
        newReceive.action="+";
        newReceive.amount =_amount;
        newReceive.messages=_message;
        newReceive.otherAccount = receiver;
        if(names[senders].haveName){
            newReceive.otherAccName =names[senders].name;
        }
        history[receiver].push(newReceive);

    }

    //get request send to user

    function getMyRequest(address _user) public view returns(
        address[] memory,
        uint256[] memory ,
        string [] memory,
        string[] memory
    ){
        address[] memory addrs = new address[](requests[_user].length);
        uint256[] memory amnt = new uint256[](requests[_user].length);
        string[]  memory msge = new string[](requests[_user].length);
        string[]  memory nme = new string[](requests[_user].length);

        for(uint i =0;i<requests[_user].length;i++){
            requesting storage myRequests = requests[_user][i];
            addrs[i]=myRequests.requestor;
            amnt[i] =myRequests.amount;
            msge[i] = myRequests.messages;
            nme[i] =myRequests.name;
        }
        return(addrs,amnt,msge,nme);
    }

    //get all historic transacions

    function getMyHistory( address _user) public view returns(sender[] memory){
        return history[_user];
    }

    function getMyName(address _user) public view returns(userName memory){
        return names[_user];
    }
}