/**
 *Submitted for verification at polygonscan.com on 2022-07-01
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.4 <0.7.0;
pragma experimental ABIEncoderV2;

/// @title <MultisigWallet.sol>
/// @author <IvanFitro>
/// @notice <Creation of an multising wallet>

contract Wallet{

    address[] owners;
    uint amount;
    mapping(address=>mapping(uint=>bool)) public Approvals; 
    uint limit;
    
    

    struct Transaction{
        address payable receiver;
        uint amount;
        uint approvals;
        bool hasBeenSent;
        uint id;
    }

    Transaction[] transactions;

    //Events
    event transactionRequestCreated(uint _id, uint amount, address _initiator, address _receiver);
    event ApprovalReceived(uint _id, uint _approvals, address _approver);
    event TransferApproved(uint _id);

    //Modifier to checks if the address is an owner of the wallet
   modifier onlyOwners(){
        bool owner = false;
        for(uint i=0; i<owners.length;i++) {
            if(owners[i] == msg.sender) {
                owner = true;
            }
        }
        require(owner == true, "You don't have this permision");
        _;
    }

    //Initialize the contract saving the owners and the approvals
    constructor(address[] memory _Owners, uint _limit) public {
        limit=_limit;
        owners=_Owners;
    }   

    //Function to get the owners
      function getOwners() public view returns(address[] memory) {
        return owners;
    }

    //Fucntions to allow deposits
    function addBalance() public payable {
        
    }

    //Function to get the total balance of contract
    function getBalance() view public returns(uint) {
        return address(this).balance;
    }

    //Function to create a transaction
    function submitTransaction(address payable _reciever, uint _amount) public onlyOwners {
        //Check the balance 
        require(address(this).balance >= _amount, "Balance not sufficient");               
        transactions.push(Transaction(_reciever,_amount,0,false,transactions.length)); 

        emit transactionRequestCreated(transactions.length, _amount, msg.sender, _reciever);
    }

    //Function to confirm a transaction
    function confrirmTransaction(uint _id) public onlyOwners{
        //All the owners that doesn'vote can vote, if the already vote they can't vote another time
        require(Approvals[msg.sender][_id] == false);
        require(transactions[_id].hasBeenSent == false); 

        Approvals[msg.sender][_id] = true;
        transactions[_id].approvals++;       

        emit ApprovalReceived(transactions.length, transactions[_id].approvals, msg.sender);

        //If the approvals reach the limit then the transaction can be done
        if(transactions[_id].approvals>=limit){
            transactions[_id].hasBeenSent=true;
            //Trasnfers the amount to the receiver
            transactions[_id].receiver.transfer(transactions[_id].amount);  
            emit TransferApproved(_id);
        }
    }

    //Should return all transfer requests
    function getTransferRequests() public view returns (Transaction[] memory){
        return transactions;
    }
    

   




    
}