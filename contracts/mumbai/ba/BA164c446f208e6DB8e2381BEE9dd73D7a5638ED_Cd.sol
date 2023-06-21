/**
 *Submitted for verification at polygonscan.com on 2023-06-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract Cd {
    uint sData;
    function set(uint a) public {
        sData =a;
    }
function get() public view returns (uint){
    return sData;
}
}