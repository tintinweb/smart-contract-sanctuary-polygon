pragma solidity ^0.8.0;

contract BatchPayment {
    address payable public owner;

    constructor() {
        owner = payable(msg.sender);
    }

    function sendEther(address payable[] memory recipients, uint256[] memory amounts) external payable onlyOwner {
        require(recipients.length == amounts.length, "Invalid input length");
        require(msg.value > 0, "No Ether sent");

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }

        require(msg.value >= totalAmount * 1 ether, "Insufficient Ether sent");

        for (uint256 i = 0; i < recipients.length; i++) {
            recipients[i].transfer(amounts[i] * 1 ether);
        }
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }
}