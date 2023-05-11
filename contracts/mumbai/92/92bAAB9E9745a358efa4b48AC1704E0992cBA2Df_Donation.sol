// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Donation {
    string public repository;
    address public owner;
    address payable public paidTo;

    event Withdrawal(uint amount, uint when);

    constructor(string memory _repository) payable {
        repository = _repository;
    }

    function withdraw(address payable _to) external {
        require(paidTo == address(0), "This donation has already been paid out");

        paidTo = _to;
        emit Withdrawal(address(this).balance, block.timestamp);

        _to.transfer(address(this).balance);
    }
}