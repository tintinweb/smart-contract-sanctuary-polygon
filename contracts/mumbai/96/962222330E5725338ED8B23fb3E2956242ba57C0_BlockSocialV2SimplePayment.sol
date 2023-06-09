// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

contract BlockSocialV2SimplePayment {
    address public owner;

    mapping(address => bool) public locked;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner");
        _;
    }

    modifier onlyRich(uint256 value) {
        require(
            address(this).balance >= value,
            "We don't enough money for payments. At this moment, he knew he..."
        );
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function deposit() public payable {}

    function withdraw(
        uint256 amount,
        address payable payee
    ) public onlyOwner onlyRich(amount) {
        require(!locked[payee], "Withdraw is already in progress.");

        locked[payee] = true;

        payable(payee).transfer(amount);

        locked[payee] = false;
    }

    function totalMoney() public view returns (uint256) {
        return address(this).balance;
    }

    fallback() external payable {
        revert(
            "Direct transfers are not allowed. Please use the deposit() function."
        );
    }

    receive() external payable {
        revert(
            "Direct transfers are not allowed. Please use the deposit() function."
        );
    }
}