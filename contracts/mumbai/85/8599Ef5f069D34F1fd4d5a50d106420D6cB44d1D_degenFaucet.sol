// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract degenFaucet {
    uint256 public limit;
    address owner;
    uint256 public balance;
    mapping(address => uint256) addressToBalance;

    constructor(uint256 _limit) {
        limit = _limit;
        owner = payable(msg.sender);
    }

    event fundsAdded(address investor, uint256 amount);
    event fundsClaimed(address investor, uint256 amount);

    function Addfund() public payable {
        balance += msg.value;
        emit fundsAdded(msg.sender, msg.value);
    }

    function changeLimit(uint256 _limit) public {
        require(msg.sender == owner, "Only owner can call this");
        limit = _limit;
    }

    function withdraw() public payable {
        require(msg.sender == owner, "Only owner can call this function");

        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success, "");
    }

    function claimMatic() public payable {
        require(
            addressToBalance[msg.sender] == 0 ether,
            "You have claimed the amount"
        );

        payable(msg.sender).transfer(limit);
        addressToBalance[msg.sender] = limit;

        emit fundsClaimed(msg.sender, limit);
    }

    fallback() external payable {}

    receive() external payable {
        // custom function code
    }
}