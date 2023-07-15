/**
 *Submitted for verification at polygonscan.com on 2023-07-14
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract SimpleBridge {
    event Deposit(address indexed _from, bytes32 indexed _id, uint _value);
    event Withdraw(address indexed _to, bytes32 indexed _id, uint _value);
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    mapping(bytes32 => uint) public deposits;

    function deposit(bytes32 seed) public payable {
        require(msg.value > 0, "Must send ether with transaction");
        deposits[seed] += msg.value;
        emit Deposit(msg.sender, seed, msg.value);
    }

    function withdrawAll() public {
        require(msg.sender == owner, "Only the contract owner can withdraw all funds");
        payable(owner).transfer(address(this).balance);
    }
}