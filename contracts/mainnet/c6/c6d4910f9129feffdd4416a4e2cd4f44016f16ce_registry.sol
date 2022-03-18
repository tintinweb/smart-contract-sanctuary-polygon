/**
 *Submitted for verification at polygonscan.com on 2022-03-17
*/

pragma solidity 0.8.7;

// SPDX-License-Identifier: MIT

contract registry {

    uint public totalsupply = 1;

    mapping(address => uint) public id;
    mapping(uint => address) public addr;

    function set() external {
        require(id[msg.sender] == 0, "already exist");
        id[msg.sender] = totalsupply;
        addr[totalsupply] = msg.sender;
        totalsupply++;
    }
}