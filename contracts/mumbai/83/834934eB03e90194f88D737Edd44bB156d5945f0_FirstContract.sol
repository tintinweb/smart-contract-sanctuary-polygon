/**
 *Submitted for verification at polygonscan.com on 2022-10-23
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


contract FirstContract {
    address myaddress = 0xA9ff4017F09b35F3F6c5554Aec0E20E91cFcDA5a;

    function knowOwner() public view returns (address) {
        return myaddress;
    }

    //comment example

}