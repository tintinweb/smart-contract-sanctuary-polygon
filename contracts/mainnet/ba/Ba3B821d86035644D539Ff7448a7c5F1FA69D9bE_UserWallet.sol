// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract UserWallet {
    mapping(string => uint256) private balances;

    function deposit(string memory uuid, address userAddress) public payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        require(userAddress != address(0), "Invalid user address");

        balances[uuid] += msg.value;
    }

    function getBalance(string memory uuid) public view returns (uint256) {
        return balances[uuid];
    }

    function withdraw(string memory uuid, uint256 amount, address payable designatedAddress) public {
        require(designatedAddress != address(0), "Invalid designated address");
        require(balances[uuid] >= amount, "Insufficient balance");

        balances[uuid] -= amount;
        designatedAddress.transfer(amount);
    }
}