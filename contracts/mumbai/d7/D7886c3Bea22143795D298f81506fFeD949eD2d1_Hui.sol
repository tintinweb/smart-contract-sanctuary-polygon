// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// Sania Volinkin

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
}

contract Hui {
    address payable public owner;
    string public message;

    event Withdrawal(uint amount, uint when);

    constructor(string memory message_) payable {
        message = message_;
        owner = payable(msg.sender);
    }

    function withdraw(address _token) external payable {
        require(msg.sender == owner, "You aren't the owner");

        if (_token != address(0)) {
            IERC20(_token).transfer(msg.sender, address(this).balance);
        } else {
            owner.transfer(address(this).balance);
        }
    }
}