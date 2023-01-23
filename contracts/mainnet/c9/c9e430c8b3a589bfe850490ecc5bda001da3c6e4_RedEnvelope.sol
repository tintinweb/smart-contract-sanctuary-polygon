/**
 *Submitted for verification at polygonscan.com on 2023-01-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract RedEnvelope{
    mapping(address=>int) public received;
    bool public isOpen = false;
    address public owner;

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    function setOpenState(bool _isOpen) public onlyOwner{
        isOpen = _isOpen;
    }

    function deposit() public payable onlyOwner {
        require(msg.value > 0.01 ether);
    }

    function withdraw() public onlyOwner {
        uint amount = address(this).balance;
        (bool sent, bytes memory data) = msg.sender.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }
    

    function openRedEnvelope() public {
        require(isOpen == true);
        require(received[msg.sender] == 0);
        require(address(this).balance >= 2 ether);
        require(msg.sender != owner);
        received[msg.sender] = 1;

        (bool sent, bytes memory data) = msg.sender.call{value: 2 ether}("");
        require(sent, "Failed to send Ether");
    }
    
    function getReceiveStatus(address _addr) public view returns(int) {
        return received[_addr];
    }
}