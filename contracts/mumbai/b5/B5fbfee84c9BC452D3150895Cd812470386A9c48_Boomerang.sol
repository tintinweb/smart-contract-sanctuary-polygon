/**
 *Submitted for verification at polygonscan.com on 2022-10-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title Boomerang
 * @dev Implements Expense Manager Card of an Employee
 */
contract Boomerang {
    address public employee_Address;
    mapping(address => uint256) public vendorsCosts; //Vendor > Cost
    uint256 public balance;
    address public owner;
    uint public expirationDate;

    constructor(address employee_Address_, uint expirationDate_ ) payable {
        employee_Address = employee_Address_;
        balance = msg.value;
        owner = payable(msg.sender);
        expirationDate = expirationDate_;
    }

    function addBalance() payable public{
        balance += msg.value;
    }

    function addVendor(address account_new_vendor, uint256 cost_new_service) public{
        require(msg.sender == owner);
        vendorsCosts[account_new_vendor] = cost_new_service;
    }

    function removeVendor(address account_vendor) public{
        require(msg.sender == owner);
        vendorsCosts[account_vendor] = 0;
    }

    function payVendor(address vendor_address) payable public {
        require(msg.value == vendorsCosts[vendor_address]);
        require(msg.sender == employee_Address);
        require(balance > vendorsCosts[vendor_address]);
        balance -= vendorsCosts[vendor_address];
        payable(vendor_address).transfer(vendorsCosts[vendor_address]);
    }

    function changeExpirationDate(uint new_date) public {
        expirationDate = new_date;
    } 

    function returnFunds() public {
        require(block.timestamp >= expirationDate, "TimeConditions: too early");
        require(balance > 0);
        require(msg.sender == owner);
        uint256 balance_temp = balance;
        balance = 0;
        payable(owner).transfer(balance_temp);
    }
}