/**
 *Submitted for verification at polygonscan.com on 2023-03-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MultiAddress {
    address payable public mainAddress;
    mapping(uint256 => address) public receivingAddresses;
    uint256 public totalReceivingAddresses;

    constructor() {
        mainAddress = payable(msg.sender);
        totalReceivingAddresses = 0;
    }

    function addReceivingAddress() public {
        require(msg.sender == mainAddress, "Only the main address can add receiving addresses");
        address newAddress = address(new ReceivingAddress(msg.sender, address(this)));
        receivingAddresses[totalReceivingAddresses] = newAddress;
        totalReceivingAddresses++;
    }

    receive() external payable {
        mainAddress.transfer(msg.value);
    }
}

contract ReceivingAddress {
    address public owner;
    address public multiAddress;

    constructor(address _owner, address _multiAddress) {
        owner = _owner;
        multiAddress = _multiAddress;
    }

    receive() external payable {}
    
    function withdraw() public {
        require(msg.sender == owner, "Only the owner can withdraw from this address");
        uint256 balance = address(this).balance;
        (bool success, ) = payable(owner).call{value: balance}("");
        require(success, "Transfer failed.");
    }

    function transferToMain() public {
        require(msg.sender == owner, "Only the owner can transfer to main address");
        uint256 balance = address(this).balance;
        (bool success, ) = payable(multiAddress).call{value: balance}("");
        require(success, "Transfer failed.");
    }
}