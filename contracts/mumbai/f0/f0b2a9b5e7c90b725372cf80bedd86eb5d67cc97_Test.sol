/**
 *Submitted for verification at polygonscan.com on 2023-05-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Test {

    address public owner;
    mapping (address => uint) public payments;

    constructor() {
        owner = msg.sender;
    }

    function payForItem() public payable {
        payments[msg.sender] = msg.value;
    } 

    function withdrawALL() public {
        address payable _to = payable(owner);
        address _thisContract = address(this); 
        _to.transfer(_thisContract.balance);
    }
}