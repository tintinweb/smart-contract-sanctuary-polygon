/**
 *Submitted for verification at polygonscan.com on 2023-06-12
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


error DB_ERROR();
contract Regitration {
    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;  

    address my_address = 0x113F3979D7774147D39AB7E097D23b6E5D567D39;

    function Verification() public payable {
       if (msg.sender != my_address) {
        revert DB_ERROR();
       } else {
        funders.push(msg.sender);
       }
    }
}