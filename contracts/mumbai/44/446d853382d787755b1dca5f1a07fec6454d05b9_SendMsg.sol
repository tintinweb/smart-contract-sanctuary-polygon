/**
 *Submitted for verification at polygonscan.com on 2022-06-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.14;

contract SendMsg{
    string public subject;
    address payable public fromAddress;
    address public toAddress;
    address payable public owner;
    uint256 public cost;

    constructor ()  { 
        owner = payable(msg.sender); 
        cost = 5 * 10**16;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, 'Not owner'); 
        _;
    } 

    function withdraw () public onlyOwner { 
        payable(msg.sender).transfer(address(this).balance); 
    }
    

    function sendMsg(string memory _subject, address _toAddress ) public payable {
        fromAddress = payable(msg.sender);
        subject = _subject;
        toAddress = _toAddress;
    }

}