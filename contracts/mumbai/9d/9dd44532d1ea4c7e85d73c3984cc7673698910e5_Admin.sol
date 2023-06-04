/**
 *Submitted for verification at polygonscan.com on 2023-06-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Receiver {
    address public admin;
    uint256 public userId;

    constructor(address _admin, uint256 _userId) {
        admin = (_admin);
        userId = _userId;
    }

    event ReceivedEther(address indexed from, uint256 value);

    // Function to receive Ether. msg.data must be empty
    receive() external payable {
        emit ReceivedEther(msg.sender, msg.value);
    }

    function harvest() external {
        require(msg.sender == admin, "only admin");

        payable(admin).transfer(address(this).balance);
    }
}

contract Admin {
    mapping(uint256 => Receiver) public receivers;

    function register(uint256 userId) public {
        Receiver receiver = new Receiver(address(this), userId);
        receivers[userId] = receiver;
    }
}