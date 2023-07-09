/**
 *Submitted for verification at polygonscan.com on 2023-07-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract Contacts {
    address immutable private MAIL_ADDRESS;
    mapping(uint256 => address) private users;
    mapping(address => uint256) private totalByUser;
    mapping(address => uint256) private removedByUser;
    mapping(address => mapping(string => string)) private addressesToNicknames;
    mapping(address => mapping(string => string)) private nicknamesToAddresses;
    uint256 private usersTotal;

    struct Contact{
        uint256 id;
        string symbol;
        string address_;
        string nickname;
    }
    mapping(address => mapping(uint256 => Contact)) private contacts;

    constructor(address mailAddress){
        MAIL_ADDRESS = mailAddress;
    }

    function addContact(address user, string[5] calldata args) external {
        require(msg.sender == MAIL_ADDRESS, "Inv. caller");
        require(bytes(addressesToNicknames[user][args[3]]).length == 0 && bytes(nicknamesToAddresses[user][args[4]]).length == 0,"Inv. args");

        if(totalByUser[user] == 0){
            users[usersTotal] = user;
            usersTotal = usersTotal + 1;
        }

        uint256 id = totalByUser[user];
        contacts[user][id] = Contact(id, args[0], args[1], args[2]);
        addressesToNicknames[user][args[3]] = args[2];
        nicknamesToAddresses[user][args[4]] = args[1];
        totalByUser[user] = id + 1;
    }

    function setContact(uint256 id, string[7] calldata args) external {
        require(totalByUser[msg.sender] > 0, "Inv. caller");

        Contact storage contact = contacts[msg.sender][id];
        require(keccak256(abi.encodePacked(addressesToNicknames[msg.sender][args[5]])) == keccak256(abi.encodePacked(contact.nickname)) &&
            keccak256(abi.encodePacked(nicknamesToAddresses[msg.sender][args[6]])) == keccak256(abi.encodePacked(contact.address_)), "Inv. args");
        addressesToNicknames[msg.sender][args[5]] = "";
        nicknamesToAddresses[msg.sender][args[6]] = "";
        contacts[msg.sender][id] = Contact(id, "", "", "");

        contacts[msg.sender][id] = Contact(id, args[0], args[1], args[2]);
        addressesToNicknames[msg.sender][args[3]] = args[2];
        nicknamesToAddresses[msg.sender][args[4]] = args[1];
    }

    function removeContacts(uint256[] calldata ids, string[] calldata args) external {
        require(totalByUser[msg.sender] > 0, "Inv. caller");

        uint256 length = ids.length;
        for(uint i;i<length;){
            uint256 id = ids[i];
            uint256 argId = i % 2 == 0 ? i : i + 1;
            string memory arg0 = args[argId];
            string memory arg1 = args[argId + 1];

            Contact storage contact = contacts[msg.sender][id];
            require(keccak256(abi.encodePacked(addressesToNicknames[msg.sender][arg0])) == keccak256(abi.encodePacked(contact.nickname)) &&
            keccak256(abi.encodePacked(nicknamesToAddresses[msg.sender][arg1])) == keccak256(abi.encodePacked(contact.address_)), "Inv. args");

            addressesToNicknames[msg.sender][arg0] = "";
            nicknamesToAddresses[msg.sender][arg1] = "";
            contacts[msg.sender][id] = Contact(id, "", "", "");

            unchecked{i++;}
        }

        removedByUser[msg.sender] = removedByUser[msg.sender] + length;
    }

    function getInfo(address user, uint256 id) external view returns (address, uint256, uint256, uint256, address) {
        return (users[id], totalByUser[user], removedByUser[user], usersTotal, MAIL_ADDRESS);
    }

    function getNicknameFromAddress(address user, string calldata addressToNickname) external view returns (string memory) {
        return addressesToNicknames[user][addressToNickname];
    }

    function getAddressFromNickname(address user, string calldata nicknameToAddress) external view returns (string memory) {
        return nicknamesToAddresses[user][nicknameToAddress];
    }

    function getContacts(address from, string calldata symbol, uint256 fromId, uint256 length) external view returns (Contact[] memory) {
        Contact[] memory contacts_ = new Contact[](length);
        uint256 userTotal_ = totalByUser[from];
        uint256 id;

        for(uint i=fromId;i<=userTotal_;){
            Contact storage contact = contacts[from][i];
            if((bytes(symbol).length > 0 && keccak256(abi.encodePacked(contact.symbol)) == keccak256(abi.encodePacked(symbol))) ||
                (bytes(contact.address_).length > 0)){
                contacts_[id] = contact;
                id++;

                if(id == length){
                    break;
                }
            }
            unchecked{i++;}
        }

        return contacts_;
    }
}