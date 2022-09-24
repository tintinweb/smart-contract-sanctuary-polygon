/**
 *Submitted for verification at polygonscan.com on 2022-09-24
*/

//SPDX-License-Identifier: MIT

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
        // [address(this)] = this smart contract has 1000NFT
    }

    function getStock() public view returns (uint256) {
        // view = to save gas no transaction
        return nftBalances[address(this)];
    }

    function purchase(uint256 numberOfNFT) public payable {
        require(msg.value >= numberOfNFT * pricePerNFT, "Insufficient fund");
        require(getStock()>= numberOfNFT, "Insufficient stock");
        nftBalances[msg.sender] += numberOfNFT;
        nftBalances[address(this)] -= numberOfNFT;

    }

    function restock(uint256 numberOfNFT) public {
        // only owner who can retock
        require(msg.sender==owner, "Only owner can restock");
        nftBalances[address(this)] += numberOfNFT;
    }

    
}