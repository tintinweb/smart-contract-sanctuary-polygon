/**
 *Submitted for verification at polygonscan.com on 2022-03-14
*/

// Sources flattened with hardhat v2.8.3 https://hardhat.org

// File contracts/CryptoGummy.sol

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract CryptoGummy {
    event newPurchase(
        address buyer,
        string message,
        uint256 timestamp,
        uint256 value,
        string name
    );

    struct Purchase {
        address buyer;
        string message;
        uint256 timestamp;
        uint256 value;
        string name;
    }

    Purchase[] purchases;

    address payable private owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() payable {
        owner = payable(msg.sender);
    }

    function purchase(
        string memory _message,
        uint256 _timestamp,
        string memory _name
    ) public payable {
        purchases.push(
            Purchase(msg.sender, _message, _timestamp, msg.value, _name)
        );

        emit newPurchase(msg.sender, _message, _timestamp, msg.value, _name);
    }

    function getAllPurchases() public view returns (Purchase[] memory) {
        return purchases;
    }

    function withdrawAll() public onlyOwner {
        owner.transfer(address(this).balance);
    }

    function withdraw(uint256 amount) public onlyOwner {
        require(amount <= address(this).balance, "Amount exceeds balance");
        owner.transfer(amount);
    }

    function withdrawTo(uint256 amount, address payable to) public onlyOwner {
        require(amount <= address(this).balance, "Amount exceeds balance");
        to.transfer(amount);
    }
}