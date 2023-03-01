// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.7.0;

contract CryptologicHackable {
    // Balance of each user
    mapping(address => uint256) public userBalances;
    address payable public owner;

    // Create a constructor to have an owner
    constructor() public {
        owner = payable(msg.sender);
    }

    // Deposit ether into the contract
    function deposit() public payable {
        userBalances[msg.sender] += msg.value;
    }

    // Withdraw ether from the contract
    function withdrawBalance() public {
        uint256 amountToWithdraw = userBalances[msg.sender];

        // Can't use EIP-1559 transaction type
        (bool success, ) = msg.sender.call.value(amountToWithdraw)("");
        require(success);
        userBalances[msg.sender] = 0;
    }

    // Owner function to withdraw all ether from the contract
    function withdrawAll() public {
        require(msg.sender == owner);
        (bool success, ) = owner.call.value(address(this).balance)("");
        require(success);
    }
}