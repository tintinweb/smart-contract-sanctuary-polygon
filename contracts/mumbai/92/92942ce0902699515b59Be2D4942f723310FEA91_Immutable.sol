// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
contract Immutable{
    //coding convention to uppercase constant variables
    address public immutable MY_ADDRESS;
    uint public immutable MY_UINT;
    constructor(uint _myUINT){
        MY_ADDRESS = msg.sender;
        MY_UINT = _myUINT;

    }
}