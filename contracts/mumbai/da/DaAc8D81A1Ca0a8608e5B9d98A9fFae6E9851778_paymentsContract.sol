/**
 *Submitted for verification at polygonscan.com on 2022-06-12
*/

pragma solidity ^0.8.4;

contract paymentsContract{

    struct transaction{
        uint amount;
        address from;
        address to;
        string timestamp; 
        address transactionAddress;
    }

    mapping(address => transaction) public Transactions;

    function savePaymentsDetails(uint _amount, address _to, string memory _timestamp, address _transactionAddress) external{
            transaction memory newTransactions;
            newTransactions.amount = _amount;
            newTransactions.to = _to;
            newTransactions.timestamp = _timestamp;

            newTransactions.from  = msg.sender;
            Transactions[_transactionAddress] =  newTransactions;
    }

    function getPaymentsDetails(address _transactionAddress) public view returns(transaction memory){
        return Transactions[_transactionAddress];
    }

}