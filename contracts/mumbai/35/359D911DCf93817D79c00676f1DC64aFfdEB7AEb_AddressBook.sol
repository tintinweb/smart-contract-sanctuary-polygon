// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

contract AddressBook {
    mapping(address => mapping(string => address)) addresBook;

    event ContactSaved(
        address indexed sender,
        string name,
        address indexed addr
    );
    event ContactDeleted(address indexed sender, string name);

    function saveContact(string memory _name, address _address) public {
        require(
            bytes(_name).length > 0,
            "Name must be at least 1 character long"
        );
        addresBook[msg.sender][_name] = _address;
        emit ContactSaved(msg.sender, _name, _address);
    }

    function deleteContact(string memory _name) public {
        delete addresBook[msg.sender][_name];
        emit ContactDeleted(msg.sender, _name);
    }

    function getContact(string memory _name) public view returns (address) {
        return addresBook[msg.sender][_name];
    }
}