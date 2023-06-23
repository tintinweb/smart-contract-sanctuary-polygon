/**
 *Submitted for verification at polygonscan.com on 2023-06-23
*/

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

contract Args {
    mapping (address => uint) public myMap;

    function myFunc(address[] calldata _addresses) public {
        for (uint256 i = 0; i < _addresses.length; i++) {
            myMap[_addresses[i]]++;
        }
    }

}