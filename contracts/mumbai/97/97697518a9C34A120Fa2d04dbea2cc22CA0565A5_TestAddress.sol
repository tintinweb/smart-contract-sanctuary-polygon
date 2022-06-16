/**
 *Submitted for verification at polygonscan.com on 2022-06-15
*/

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.14;

contract TestAddress {
    address public  constructAddress;
    constructor (address _addr){
        constructAddress = _addr;
    }
}