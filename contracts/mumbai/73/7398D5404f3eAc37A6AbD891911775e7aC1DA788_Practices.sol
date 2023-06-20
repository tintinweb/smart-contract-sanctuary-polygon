// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.18;
contract Practices{
    address public owner;
    constructor(){
        owner = msg.sender;
    }
    uint public userId;
    bool public learnings = true;
    bytes3 public constant name ="sai";
    string[] public imptopics = ["solidity","hardhat","ethers"];
    struct Bankoperation{
        uint userId ;
        uint balance;
        bool taskdone;
    }

    mapping(address=>string[]) public userOperations;
    mapping(address=>uint) public userBalance;
    mapping(address =>mapping(string=>Bankoperation[])) public customerLog;
    enum Transaction{
        Deposit,Withdraw,Transfer
    }
    Transaction public transaction;

    event  receiveCalled(address sender,uint value);
    
    modifier onlyOwner{
        require(msg.sender==owner,"You're not the owner");
        _;
    }

    function setTransaction(Transaction _trans) private{ 
        transaction = _trans;
    }

    function Deposit() external payable {
        userId  = userId>0?((userOperations[msg.sender]).length>0?userId:userId+=1):userId+=1;
        require(msg.value>0 && msg.sender!=address(0));
        setTransaction(Transaction.Deposit);
        userOperations[msg.sender].push("Deposit");
        userBalance[msg.sender]+=msg.value;
        Bankoperation memory Operation = Bankoperation({
            userId:userId,
            balance:msg.value,
            taskdone:true
        });
        customerLog[msg.sender]["Deposit"].push(Operation);
    }

    function Withdraw(uint _amount) external payable {
        require(_amount>0 && msg.sender!=address(0) &&_amount<=userBalance[msg.sender]);
        setTransaction(Transaction.Withdraw);
        userOperations[msg.sender].push("Withdraw");
        userBalance[msg.sender]-=_amount;
        Bankoperation memory Operation = Bankoperation({
            userId:userId,
            balance:_amount,
            taskdone:true
        });
        customerLog[msg.sender]["Withdraw"].push(Operation);
        payable(msg.sender).transfer(_amount);
    }

    function Checkbalance() external view returns(uint){
        return userBalance[msg.sender];
    }


    function  Bankbalance() external view onlyOwner returns(uint){
        return address(this).balance;
    }


    function arrfunctions() external virtual{
        imptopics.push("React");
        imptopics.push("Next");
        imptopics.pop();
        imptopics.push("Nodejs");
    }
    receive() payable external{
// // //It acts a replacement for fallback for above 0.6.0 before we have fallback
// //fallback happens when unexpected ether transaction or function call not exists in contract
    emit receiveCalled(msg.sender,msg.value);
}
fallback() payable external{

}
}