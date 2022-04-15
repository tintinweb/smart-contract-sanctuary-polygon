/**
 *Submitted for verification at polygonscan.com on 2022-04-14
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

contract TestBuddy {
    address payable to;
    function initialize() public {
        to = 0x325bE92739624dcECd4C97112DF3Ab22259b7B2c;
    }

    function transferMatic() public payable {
        require(msg.value>=0, "Value must be greater than zero");
        to.transfer(msg.value);
    }

}