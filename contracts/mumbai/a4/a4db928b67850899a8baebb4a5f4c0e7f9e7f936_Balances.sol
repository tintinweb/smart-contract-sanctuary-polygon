/**
 *Submitted for verification at polygonscan.com on 2022-10-23
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Balances {

    function balanceAddress(address _address) public view returns(uint) {
        return _address.balance;
    }

}