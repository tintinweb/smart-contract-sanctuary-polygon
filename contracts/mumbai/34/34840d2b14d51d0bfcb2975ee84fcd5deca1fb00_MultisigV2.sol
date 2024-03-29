/**
 *Submitted for verification at polygonscan.com on 2023-05-21
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

contract MultisigV2 {
    address president = 0xb6BF6382C40730ea325aA36B8142Ecf203E7A402;
    address vicepresident = 0x7b2ecbA6c77FB9EA2e6EAa8c38EeBFCF68336Aef;
    address electrician = 0x0ad3318734CF4805EF4581bcb3949Cf9588Ac014;
    bool public isApprovedByPresident = false;
    bool public isApprovedByVicePresident = false;
    bool isSent = false;

    address public owner;

    modifier onlyPresidentAndVicePresident() {
        require(msg.sender == president && msg.sender == vicepresident,  "Sorry! You are not allowed");
        _;
    }

    function inject() external payable onlyPresidentAndVicePresident {
        require(msg.value == 0.001 ether, "Sorry! You have to pay 0.001 Matic");
    }

    function sendToElectrician() external {
        require(isApprovedByPresident == true && isApprovedByVicePresident == true && isSent == false, "Sorry! The transaction is not approved by president and vicepresident");
        payable(electrician).transfer(0.0002 ether);
        isSent = true;
    }

    function approve() external view onlyPresidentAndVicePresident {
        require(msg.sender == president || msg.sender == vicepresident, "Sorry! You are not allowed");
    }
}