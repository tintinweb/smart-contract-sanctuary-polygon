/**
 *Submitted for verification at polygonscan.com on 2023-07-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SendEther {
    address public admin;

    constructor() {
        admin = msg.sender;
    }

    function sendMultiple(address payable[] memory _addresses, uint[] memory _amounts) public payable {
        require(msg.sender == admin, "Only the admin can send Ether");
        require(_addresses.length == _amounts.length, "The length of addresses array and amounts array must be the same");

        for(uint i = 0; i < _addresses.length; i++) {
            _addresses[i].transfer(_amounts[i]);
        }
    }

    function withdraw() public {
        require(msg.sender == admin, "Only the admin can withdraw Ether");
        payable(admin).transfer(address(this).balance);
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}