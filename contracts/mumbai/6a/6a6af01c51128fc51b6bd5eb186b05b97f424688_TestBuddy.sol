/**
 *Submitted for verification at polygonscan.com on 2022-04-14
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

contract TestBuddy {
    address payable treasury;
    function initialize(address payable _treasury) public {
        treasury = _treasury;
    }

    function transferMatic() public payable {
        require(msg.value > 0, "Value must be greater than zero");
            treasury.transfer(msg.value);
    }

}