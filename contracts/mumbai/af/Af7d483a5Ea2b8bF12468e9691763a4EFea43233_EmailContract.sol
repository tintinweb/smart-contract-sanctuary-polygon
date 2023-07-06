// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract EmailContract {
    struct Email {
        address sender;
        string recipient;
        string content;
        uint256 timestamp;
    }
    
    mapping(address => Email[]) private inbox;
    mapping(address => Email[]) private outbox;
    
    event EmailSent(address indexed sender, string recipient, string content);
    
    function sendEmail(string memory recipient, string memory content) external {
        Email memory newEmail = Email({
            sender: msg.sender,
            recipient: recipient,
            content: content,
            timestamp: block.timestamp
        });
        
        inbox[_toAddress(recipient)].push(newEmail);
        outbox[msg.sender].push(newEmail);
        
        emit EmailSent(msg.sender, recipient, content);
    }
    
    function retrieveInbox() external view returns (Email[] memory) {
        return inbox[msg.sender];
    }
    
    function retrieveOutbox() external view returns (Email[] memory) {
        return outbox[msg.sender];
    }
    
    function _toAddress(string memory recipient) private pure returns (address) {
        return bytesToAddress(bytes(recipient));
    }
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}