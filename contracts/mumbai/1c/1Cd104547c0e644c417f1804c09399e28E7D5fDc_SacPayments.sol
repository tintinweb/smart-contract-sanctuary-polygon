// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;



/* Errors */

error Payments_AmntLessMin();

contract SacPayments {

    mapping(address => mapping(address => uint256)) public profiles;

    mapping(address => uint256) public totalReceived;
    mapping(address => uint256) public totalDonated;

    function tip(address payable tipAddress) public payable {

        profiles[tipAddress][msg.sender] = msg.value;


        totalReceived[tipAddress] += msg.value;
        totalDonated[msg.sender] += msg.value;
        tipAddress.transfer(msg.value);

    }

}