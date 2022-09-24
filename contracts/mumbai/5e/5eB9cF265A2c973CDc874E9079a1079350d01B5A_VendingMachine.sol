/**
 *Submitted for verification at polygonscan.com on 2022-09-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
//this line is to compile this contract with solidity version 0.8.x

contract VendingMachine {
    mapping (address => uint256) public nftBalances;
    address public owner;
    uint256 public pricePerNFT = 2 ether;
    
    // 1. set the owner as the address that deploys this
    // 2. stock up the NFT

    constructor () {
        owner = msg.sender; //owner to be the address deploying the contract
        nftBalances[address(this)] = 1000; //that means this contract has 1000 NFT to begin with


    } 

    //view function collects no gas fee!!! use view to save gas fee
    //note one return with s and the other one without
    function getStock() public view returns (uint256) {
        return nftBalances[address(this)];
    }

    //we can use getStock to check the balance of the NFT stock
    //or we can copy and paste the contract address in the function nftBalances to get the NFT stocks balance

    //payable function allows payment of money with the transactions
    function purchase(uint256 numberOfNFT) public payable {
        require(msg.value >= numberOfNFT * pricePerNFT, "Insufficient fund"); //length of error counts into cost of deployment 
        require(getStock() >= numberOfNFT, "Insufficient stock"); 

        nftBalances[msg.sender] += numberOfNFT;
        nftBalances[address(this)] -= numberOfNFT;
    }

    function restock(uint256 numberOfNFT) public {
        require(msg.sender==owner, "Only owner is allowed to restock");
        nftBalances[address(this)] += numberOfNFT;
    }

}