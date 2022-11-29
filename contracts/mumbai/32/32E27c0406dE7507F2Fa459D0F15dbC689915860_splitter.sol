/**
 *Submitted for verification at polygonscan.com on 2022-11-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract splitter {

    address payable[] addresses;
    uint256 private numOfAddy;
    address Owner;


    constructor() {
        Owner = msg.sender;
    }
     
    //Events to log
    event Transfer(address from, uint256 _to, uint etherd, uint256 timestamp);
    event fundWallet(address from, uint256 value);


    //Trnasfer structure 
    struct Transaction {
        address from;
        uint256 numOfAddy;
        uint256 amount;
        string description;
        uint256 time;
    }


    //Instanciate Our transfer struct
    Transaction[] transactions;

    //Batch send fixed eth amount from sender
    function multiSendFixedEth(address payable[] memory recipients, uint256 amount,string memory description) public payable {
        
        require(recipients.length > 0," Please input an Address ");
        require(amount > 0, " Amount Must Be Greater Than 0 ");
        require(Owner == msg.sender, " You are not authorised to call this function ");
        
        uint256 length = recipients.length;
        
        for(uint256 i=0;i<length;i++) {
            recipients[i].transfer(amount);
            addresses.push(recipients[i]); 
        }

        numOfAddy = addresses.length;

        transactions.push(Transaction(msg.sender, numOfAddy , amount , description, block.timestamp));

        emit Transfer(msg.sender, numOfAddy , amount , block.timestamp);
    }  


    //Allow Our Smart Contract to be able to receive and store ethers 
    function allowEther() external payable {
        emit fundWallet(msg.sender,msg.value);
        require(Owner == msg.sender, " You are not authorised to call this function ");
    }

    // Function to get all the transaction
    function getAllTransaction() public view returns(Transaction[] memory) {
        return transactions;
    }


}