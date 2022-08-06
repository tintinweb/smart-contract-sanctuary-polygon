/**
 *Submitted for verification at polygonscan.com on 2022-08-05
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;

contract EmailService {
    // Event for send email function
    event Send(address sender,address reciever,string subject,string body,uint256 timestamp, string ipfsHash,string Filename
    );

    // Event for report spam function
    event report(address _spamAddress);

    //event for removing from spam list
    event RemovedfromSpam(address _spamAddress);

    // Structure of an email
    struct Email{
        address sender; // Address of the current user's wallet
        address receiver; // Address of receiver's walley
        string subject; // Subject of the email
        string body; // Body of the email
        uint256 timestamp; // current block timestamp as seconds since unix epoch
        string ipfsHash; // CID (Content Identifier) of Attached files
        string Filename;
    }

    Email[] emails;

    mapping(address => Email[]) public inbox;
    mapping(address => Email[]) public sent;
    mapping(address => address[]) public spam_list;

    
    // Send Email function
    function sendEmail(address _reciever, string memory subject, string memory body, uint256 timestamp, string memory ipfsHash, string memory Filename) public {
        require(msg.sender.balance > 0 , "You may not have enough funds.");
        require(msg.sender != _reciever, "Sender and reciever address cannot be same.");

        inbox[_reciever].push(Email(msg.sender, _reciever, subject, body, timestamp, ipfsHash,Filename));
        sent[msg.sender].push(Email(msg.sender, _reciever, subject, body, timestamp, ipfsHash,Filename));

        emit Send(msg.sender, _reciever, subject, body, timestamp, ipfsHash,Filename);
    }

    // Fetch All Emails of the current user who is connected with the smart contract
   function getInboxEmails() public view returns(Email[] memory) {
       return inbox[msg.sender];
   }

    // Fetch Sent Emails of the current user who is connected with the smart contract
   function getSentEmails() public view returns(Email[] memory) {
       return sent[msg.sender];
   }

    // Fetch current user's wallet balance
   function currentBalance() public view returns(uint256) {
       return msg.sender.balance;
   }


   function reportSpam(address _spamAddress) public {
       spam_list[msg.sender].push(_spamAddress);
       emit report(_spamAddress);
   }
    
    function removeFromSpam(address _spamAddress) public {
       for(uint i = 0; i < spam_list[msg.sender].length-1; i++) {
           if(spam_list[msg.sender][i] == _spamAddress) {
               spam_list[msg.sender][i] = spam_list[msg.sender][i+1];
           }
       }
       spam_list[msg.sender].pop();
       emit RemovedfromSpam(_spamAddress);
   }

   function get_Spam_list() public view returns(address[] memory) {
       return spam_list[msg.sender];
   }

}