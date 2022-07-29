/**
 *Submitted for verification at polygonscan.com on 2022-07-29
*/

// File: arla_wallet.sol


pragma solidity ^0.8.13;

contract ArlaWallet {
    address payable public owner;

    constructor() {
        owner = payable(msg.sender);
    }

    receive() external payable {}

    function withdraw(uint _amount) external {
        require(msg.sender == owner, "caller is not owner");
        payable(msg.sender).transfer(_amount);
    }

    function getBalance() external view returns (uint) {
        return address(this).balance;
    }
}