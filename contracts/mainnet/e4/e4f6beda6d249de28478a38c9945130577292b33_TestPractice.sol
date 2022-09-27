/**
 *Submitted for verification at polygonscan.com on 2022-09-27
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract TestPractice {
    address[] publicList;

    function pushAddress(address _address) public {
        for ( uint i = 0; i < 1000; i++) {
            publicList.push(_address);
        }
    }

    function getAddresses() public view returns(address[] memory) {
        return publicList;
    }
}