// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Lock {
    uint public priceTon = 1;
    address public owner;

    constructor () {
        owner = msg.sender;
    }

    modifier onlyOwner () {
        require(msg.sender == owner, "not owner");
        _;

    }

    function writePrice (uint price) external onlyOwner {
        priceTon = price;
    }

    function getPrice () public view returns(uint, uint, string memory) {
        uint priceUSDT = 1 / priceTon;
        string memory nameCoin = "USDT/TON";
        return (priceTon, priceUSDT, nameCoin);
    }
}