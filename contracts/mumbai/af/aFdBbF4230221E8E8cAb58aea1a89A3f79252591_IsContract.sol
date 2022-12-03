// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;


contract IsContract {

    constructor() { }

    function verify() 
        public view
    {
        address sender = msg.sender;
        uint size;
        assembly {
            size := extcodesize(sender)
        }
        require(size == 0);
    }
}