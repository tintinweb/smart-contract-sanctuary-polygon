// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

contract AssignNamesToAddresses {
    struct Details {
        string name;
        address from;
    }
    Details[] details;

    address public admin;
    uint public nameCount;

    constructor() {
        admin = msg.sender;
    }

    function setName(string memory name) public payable {
        require(msg.value > 0, "please pay greater than 0 ether");
        // Check if user has already set their name
        for (uint i = 0; i < details.length; i++) {
            if (details[i].from == msg.sender) {
                revert("Name already set");
            }
        }

        payable(msg.sender).transfer(msg.value);
        details.push(Details(name, msg.sender));
        nameCount++;
    }

    function getCurrentName() public view returns (string memory) {
        address currentAddress = msg.sender;
        for (uint i = 0; i < details.length; i++) {
            if (details[i].from == currentAddress) {
                return details[i].name;
            }
        }
        return "";
    }

    function getAllName() public view returns (Details[] memory) {
        require(msg.sender == admin);
        return details;
    }

    function getNameByAddress(
        address _address
    ) public view returns (string memory) {
        require(msg.sender == admin);
        for (uint i = 0; i < details.length; i++) {
            if (details[i].from == _address) {
                return details[i].name;
            }
        }
        return "";
    }
}