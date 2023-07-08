/**
 *Submitted for verification at polygonscan.com on 2023-07-08
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract AddressRecord {
    address public addr;

    function setAddress(address _addr) public {
        addr = _addr;
    }
}