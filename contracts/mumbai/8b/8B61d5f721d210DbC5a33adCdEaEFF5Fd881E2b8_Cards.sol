// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Cards {
    mapping(address => string) public ipfsHash;
    mapping(address => address[]) public contacts;


    function setIPFSHash(string memory _ipfsHash) public {
        ipfsHash[msg.sender] = _ipfsHash;
    }

    function addContact(address _contact) public {
        contacts[msg.sender].push(_contact);
    }

    function removeContact(address _contact) public {
        address[] storage contactList = contacts[msg.sender];
        for (uint i = 0; i < contactList.length; i++) {
            if (contactList[i] == _contact) {
                contactList[i] = contactList[contactList.length - 1];
                contactList.pop();
                break;
            }
        }
    }

    function getContacts(address user) public view returns (address[] memory) {
        return contacts[user];
    }

    function isContact(address _user, address _contact) public view returns (bool) {
        address[] memory contactList = contacts[_user];
        for (uint i = 0; i < contactList.length; i++) {
            if (contactList[i] == _contact) {
                return true;
            }
        }
        return false;
    }
}