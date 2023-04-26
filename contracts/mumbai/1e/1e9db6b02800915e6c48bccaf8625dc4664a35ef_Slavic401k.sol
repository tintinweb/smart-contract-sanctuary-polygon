/**
 *Submitted for verification at polygonscan.com on 2023-04-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Slavic401k {
    address public owner;
    address payable public RetiremateOwner;
    uint256 public totalBalance;
    mapping(address => uint256) public balances;
    mapping(address => bool) public beneficiaries;
    uint256 public withdrawLimit;

    constructor(
        // uint256 _withdrawLimit,
    address payable _retireowner,address _empaddress) {
        owner = _empaddress;
        // withdrawLimit = _withdrawLimit;
        RetiremateOwner=_retireowner;
    }

    function deposit(address _empaddress) public payable {
        require(msg.value > 0, "Deposit amount must be greater than zero.");
        balances[_empaddress] += msg.value;
        beneficiaries[_empaddress] = true;
        totalBalance += msg.value;
        RetiremateOwner.transfer(msg.value);
    }

    function addBeneficiary(address beneficiary) public {
        require(msg.sender == owner, "Only the owner can add beneficiaries.");
        beneficiaries[beneficiary] = true;
    }

    function removeBeneficiary(address beneficiary) public {
        require(
            msg.sender == owner,
            "Only the owner can remove beneficiaries."
        );
        beneficiaries[beneficiary] = false;
    }

    function withdraw(uint256 amount) public {
        require(
            beneficiaries[msg.sender],
            "Only beneficiaries can withdraw funds."
        );
        // require(
        //     block.timestamp >= withdrawPeriod,
        //     "Withdrawals are not yet allowed."
        // );
        // require(
        //     amount <= withdrawLimit,
        //     "Withdrawal amount exceeds the limit."
        // );
        require(amount <= balances[msg.sender], "Insufficient balance.");

        balances[msg.sender] -= amount;
        totalBalance -= amount;
        payable(msg.sender).transfer(amount);
    }

     function ReceiveEth() payable public {
        // Receive Ether
    }
}