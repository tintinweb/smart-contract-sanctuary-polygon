// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./EpigeonInterfaces_080.sol";

//----------------------------------------------------------------------------------------------------
contract Chat{

    address epigeonAddress;
    mapping (address => bool) EnabledPigeonAddress;
    uint256 public price;
    address private _owner;

    struct chatmessage {
        address sender;
        string message;
        uint256 timestamp;
        string url;
        string imgUrl;
        string iV;
    }
    
    constructor (address epigeon){
        epigeonAddress = epigeon;
        _owner = msg.sender;
    }
        
    mapping(bytes32 => chatmessage[]) allMessages;
    mapping(address => address[]) internal addressToContact;
    mapping(address => mapping(address => uint256)) internal contactToAddressIndex;
    mapping(address => mapping(address => bool)) isContactOfAddress;

    function addContact(address contact) external{
        require(!isContactOfAddress[msg.sender][contact], "Already contact");
        addressToContact[msg.sender].push(contact);
        contactToAddressIndex[contact][msg.sender] = addressToContact[msg.sender].length-1;
        isContactOfAddress[msg.sender][contact] = true;
    }
    
    function isContact(address address1, address contact) external view returns(bool){
        return isContactOfAddress[address1][contact];
    }
    
    function addContactByPigeon(address sender, address contact) external{
        require(_isPigeon(msg.sender), "Available only for Epigeon's pigeon contracts");
        require(!isContactOfAddress[msg.sender][contact], "Already contact");
        addressToContact[sender].push(contact);
        contactToAddressIndex[contact][sender] = addressToContact[sender].length-1;
        isContactOfAddress[sender][contact] = true;
    }

    function _getChatCode(address sender, address recipient) internal pure returns(bytes32) {
        if(sender < recipient)
            return keccak256(abi.encodePacked(sender, recipient));
        else
            return keccak256(abi.encodePacked(recipient, sender));
    }
    
    function sendMessage(address recipient, string calldata _msg, string calldata _url, string calldata _imgurl, string calldata _iv) external payable {
        require(msg.value >= price, "Not enough value");
        require(addressToContact[recipient][contactToAddressIndex[msg.sender][recipient]] == msg.sender, "You are not a contact of the recipient");
        if(addressToContact[msg.sender][contactToAddressIndex[recipient][msg.sender]] != recipient){
            addressToContact[msg.sender].push(recipient);
            contactToAddressIndex[recipient][msg.sender] = addressToContact[msg.sender].length-1;
        }
        bytes32 chatCode = _getChatCode(msg.sender, recipient);
        chatmessage memory newMsg = chatmessage(msg.sender, _msg, block.timestamp, _url, _imgurl, _iv);
        allMessages[chatCode].push(newMsg);
        payable(_owner).transfer(address(this).balance);
    }
    
    function deleteMessage(address recipient, uint256 index) external {
        require(addressToContact[recipient][contactToAddressIndex[msg.sender][recipient]] == msg.sender, "You are not a contact of the recipient");
        bytes32 chatCode = _getChatCode(msg.sender, recipient);
        require(allMessages[chatCode][index].sender == msg.sender, "You are not the sender of the message");
        delete allMessages[chatCode][index].message;
        delete allMessages[chatCode][index].url;
        delete allMessages[chatCode][index].imgUrl;
    }
    
    function removeContact(address contact) external {
        require(addressToContact[msg.sender][contactToAddressIndex[contact][msg.sender]] == contact, "Not your contact");
        uint256 contactToRemoveIndex = contactToAddressIndex[contact][msg.sender];
        uint256 lastIdIndex = addressToContact[msg.sender].length - 1;
        if (addressToContact[msg.sender][lastIdIndex] != contact)
        {
          address lastContact = addressToContact[msg.sender][lastIdIndex];
          addressToContact[msg.sender][contactToAddressIndex[contact][msg.sender]] = lastContact;
          contactToAddressIndex[lastContact][msg.sender] = contactToRemoveIndex;
        }
        delete addressToContact[msg.sender][lastIdIndex];
        addressToContact[msg.sender].pop();
        isContactOfAddress[msg.sender][contact] = false;
    }
    
    function readMessages(address account, address partner) external view returns(chatmessage[] memory) {
        bytes32 chatCode = _getChatCode(account, partner);
        return allMessages[chatCode];
    }
    
    function readMessageByIndex(address account, address recipient, uint256 index) external view returns(chatmessage memory) {
        bytes32 chatCode = _getChatCode(account, recipient);
        return allMessages[chatCode][index];
    }
    
    function readMessageSendeByIndex(address account, address recipient, uint256 index) external view returns(address) {
        bytes32 chatCode = _getChatCode(account, recipient);
        return allMessages[chatCode][index].sender;
    }

    function readMessageMsgByIndex(address account, address recipient, uint256 index) external view returns(string memory) {
        bytes32 chatCode = _getChatCode(account, recipient);
        return allMessages[chatCode][index].message;
    }

    function readMessageTimeStampByIndex(address account, address recipient, uint256 index) external view returns(uint256 ) {
        bytes32 chatCode = _getChatCode(account, recipient);
        return allMessages[chatCode][index].timestamp;
    }
    
    function readMessageUrlByIndex(address account, address recipient, uint256 index) external view returns(string memory) {
        bytes32 chatCode = _getChatCode(account, recipient);
        return allMessages[chatCode][index].url;
    }

    function readMessageImgUrlByIndex(address account, address recipient, uint256 index) external view returns(string memory) {
        bytes32 chatCode = _getChatCode(account, recipient);
        return allMessages[chatCode][index].imgUrl;
    }

    function readMessageIvByIndex(address account, address recipient, uint256 index) external view returns(string memory) {
        bytes32 chatCode = _getChatCode(account, recipient);
        return allMessages[chatCode][index].iV;
    }
    
    function getMessageCount(address account, address recipient) external view returns(uint256){
        bytes32 chatCode = _getChatCode(account, recipient);
        return allMessages[chatCode].length;
    }
    
    function getContactByIndex(address account, uint256 index) external view returns(address) {
        return addressToContact[account][index];
    }
    
    function getContactCount(address account) external view returns(uint256){
        return addressToContact[account].length;
    }

    function enabledPigeon(address pigeon) external{
        require(_owner == msg.sender, "Only _owner");
        EnabledPigeonAddress[pigeon] = true;
    }

    function disablePigeon(address pigeon) external{
        require(_owner == msg.sender, "Only _owner");
        EnabledPigeonAddress[pigeon] = false;
    }
    
    function _isPigeon (address sender) internal view returns (bool indeed){
        ICryptoPigeon pigeon = ICryptoPigeon(sender);
        return (EnabledPigeonAddress[sender] || IEpigeon(epigeonAddress).validPigeon(sender, pigeon.owner()));
    }
    
    function setPrice(uint256 _price) external {
        require(msg.sender == _owner, "Only owner");
        price = _price;
    }
    
    function transferOwnership(address newOwner) external {    
        require(_owner == msg.sender, "Only _owner");
        require(newOwner != address(0), "Zero address");
        payable(newOwner).transfer(address(this).balance);
        _owner = newOwner;
    }
}