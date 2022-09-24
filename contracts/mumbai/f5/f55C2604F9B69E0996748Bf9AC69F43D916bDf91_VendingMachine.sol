/**
 *Submitted for verification at polygonscan.com on 2022-09-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract VendingMachine {
    mapping (address => uint256) public nftBalances;
    address public owner;
    uint256 public pricePerNFT = 2 ether;

    // 1. set the owner as the address that deploys this
    // 2. stock up the NFT
    constructor () {
        owner = msg.sender;
        nftBalances[address(this)] = 1000;
    }

    function getStock() public view returns (uint256) {
        return nftBalances[address(this)];
    }

    function purchase(uint256 numberOfNFT) public payable {
        require(msg.value >= numberOfNFT * pricePerNFT, "Insufficient fund");
        require(getStock() >= numberOfNFT, "Insufficient stock");
        nftBalances[msg.sender] += numberOfNFT;
        nftBalances[address(this)] -= numberOfNFT;
    }

    function restock(uint256 numberOfNFT) public {
        require(msg.sender == owner, "Only owner can restock vending machine");
        nftBalances[address(this)] += numberOfNFT;
    }
}