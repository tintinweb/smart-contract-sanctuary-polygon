// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract Multisig {
    uint256 private _requiredSignatures;
    address[] private _owners;

    struct Transaction{
        address to;
        uint256 value;
        bytes data;
        bool executed;
        mapping(address=>bool) signatures;
    }

    Transaction[] private _transactions;

    event TransactionCreated(uint256 transactionId, address to, uint256 value, bytes data);
    event TransactionSigned(uint256 transactionId, address signer);
    event TransactionExecuted(uint256 transactionId, address executer);

    constructor(address[] memory owners, uint256 requiredSignatures){
        require(owners.length>0 ,"Atleast one owner is required!!!");
        require(requiredSignatures>0 && requiredSignatures<=owners.length,"Invalid number of owners!!");


        _owners = owners;
        _requiredSignatures = requiredSignatures;
    }

    function submitTransaction(address to, uint256 value ,bytes memory data) public{
        require(isOwner(msg.sender),"not owner!!");
        require(to !=address(0),"invalid destination!!");
        require(value>0,"invalid value!!");

        uint256 transactionId = _transactions.length;
        _transactions.push();
        Transaction storage transaction = _transactions[transactionId];
        transaction.to = to;
        transaction.value = value;
        transaction.data = data;
        transaction.executed = false;

        emit TransactionCreated(transactionId,to,value,data);
    }


    function signTransaction(uint256 transactionId) public{
        require(transactionId< _transactions.length,"invalid length");
        Transaction storage transaction = _transactions[transactionId];
        require(!transaction.executed,"already executed!!");
        require(isOwner(msg.sender),"invalid sender");
        require(!transaction.signatures[msg.sender],"already signed");

        transaction.signatures[msg.sender] = true;
        emit TransactionSigned(transactionId,msg.sender);
        if(countSignatures(transaction) == _requiredSignatures){
            executeTransaction(transactionId);
        }
    }


    function executeTransaction(uint256 transactionId) private {
           require(transactionId< _transactions.length,"invalid length");
           Transaction storage transaction = _transactions[transactionId];
           require(!transaction.executed,"already executed!!");
           require(countSignatures(transaction) >= _requiredSignatures,"insufficient signatures!!");

           transaction.executed = true;
           (bool success,) = transaction.to.call{value:transaction.value}(transaction.data);
           require(success,"failed!!");
           emit TransactionExecuted(transactionId,msg.sender);
    }

    //HELPERS--

    function isOwner(address account) public view returns (bool){
        for(uint256 i=0;i<_owners.length;i++){
            if(_owners[i] == account){
                return true;
            }
        }
        return false;
    }


    function countSignatures(Transaction storage transaction) private view returns (uint256){
        uint256 count =0;
        for(uint256 i=0;i<_owners.length;i++){
            if(transaction.signatures[_owners[i]]){
                count++;
            }
        }
        return count;
    }


    function getTransaction(uint256 transactionId) public view returns (address,uint256,bytes memory,bool , uint256){
        require(transactionId<_transactions.length,"invalid tranasaction!!");

        Transaction storage transaction = _transactions[transactionId];

        return(transaction.to,transaction.value,transaction.data,transaction.executed,countSignatures(transaction));
    }

    function getOwners() public view returns(address[] memory){
        return _owners;
    }

    function getRequiredSignatures() public view returns (uint256){
        return _requiredSignatures;
    }

    receive() external payable {}
}