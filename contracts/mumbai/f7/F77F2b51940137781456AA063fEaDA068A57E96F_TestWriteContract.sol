// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity 0.8.7;


contract TestWriteContract  {
    address public myAddress;
    function setAddress(address addressParam) public payable {
        myAddress =  addressParam;
    }
}