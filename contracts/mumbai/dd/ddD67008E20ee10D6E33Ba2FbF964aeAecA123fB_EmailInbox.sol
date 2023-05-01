/**
 *Submitted for verification at polygonscan.com on 2023-04-29
*/

pragma solidity ^0.8.0;

contract EmailInbox {
    struct Email {
        address sender;
        string subject;
        string message;
        uint256 timestamp;
    }
    
    Email[] public emails;
    mapping(address => uint256[]) private userInbox;
    
    event NewEmail(address indexed sender, string subject, string message, uint256 timestamp);
    
    function sendEmail(address _receiver, string memory _subject, string memory _message) public {
        require(_receiver != address(0), "Invalid receiver address");
        require(msg.sender != _receiver, "Cannot send email to yourself");
        
        Email memory newEmail = Email({
            sender: msg.sender,
            subject: _subject,
            message: _message,
            timestamp: block.timestamp
        });
        emails.push(newEmail);
        userInbox[_receiver].push(emails.length - 1);
        
        emit NewEmail(msg.sender, _subject, _message, block.timestamp);
    }
    
    function getEmailCount() public view returns (uint256) {
        return emails.length;
    }
    
    function getEmailAtIndex(uint256 _index) public view returns (address, string memory, string memory, uint256) {
        require(_index < emails.length, "Invalid email index");
        
        Email memory email = emails[_index];
        return (email.sender, email.subject, email.message, email.timestamp);
    }
    
    function getUserEmailCount(address _user) public view returns (uint256) {
        return userInbox[_user].length;
    }
    
    function getUserEmailAtIndex(address _user, uint256 _index) public view returns (address, string memory, string memory, uint256) {
        require(_index < userInbox[_user].length, "Invalid email index");
        
        uint256 emailIndex = userInbox[_user][_index];
        Email memory email = emails[emailIndex];
        return (email.sender, email.subject, email.message, email.timestamp);
    }
}