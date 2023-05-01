// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract UserWallet {
    mapping(bytes32 => uint256) private balances;

    event Deposit(bytes32 indexed uuid, address indexed sender, uint256 amount);
    event Withdraw(bytes32 indexed uuid, address indexed receiver, uint256 amount);

    function deposit(bytes32 uuid, address userAddress) public payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        require(userAddress != address(0), "Invalid user address");

        balances[uuid] += msg.value;
        emit Deposit(uuid, msg.sender, msg.value);
    }

    function getBalance(bytes32 uuid) public view returns (uint256) {
        return balances[uuid];
    }

    function withdraw(bytes32 uuid, uint256 amount, address payable designatedAddress) public {
        require(designatedAddress != address(0), "Invalid designated address");
        require(balances[uuid] >= amount, "Insufficient balance");

        balances[uuid] -= amount;
        designatedAddress.transfer(amount);

        emit Withdraw(uuid, designatedAddress, amount);
    }
}