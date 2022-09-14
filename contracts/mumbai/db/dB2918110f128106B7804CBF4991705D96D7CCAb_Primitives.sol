/**
 *Submitted for verification at polygonscan.com on 2022-09-13
*/

// SPDX-License-Identifier: MIT

// File: contracts/data_type.sol


pragma solidity ^0.8.13;
contract Primitives{
    
    //Boolean data type
    bool public boo = true;
    bool public noo = false;

   // unsigned integer data type
    uint public u8 =1;
    uint public u256 = 456;     
    uint public u = 120;

    //signed integer data type

    int8 public i8 = -1;
    int public i256 = -259;
    int public i = -430;


    //Minimum and maximum values
    int public minInt = type(int).min;
    int public maxInt = type(int).max;

    //data type of Address
    address public addr =  0x5665CfC89Ee8Bd503C690844C1B69554AfAE8AeA;

 /*
    In Solidity, the data type byte represent a sequence of bytes. 
    Solidity presents two type of bytes types :

     - fixed-sized byte arrays
     - dynamically-sized byte arrays.
     
     The term bytes in Solidity represents a dynamic array of bytes. 
     It’s a shorthand for byte[] .
    */
    bytes1 a = 0xb5; //  [10110101]
    bytes1 b = 0x56; //  [01010110]


    //default address

    bool public defaultBoo;
    uint public defaultUint;
    int public defaultInt;
    address public defaultAddr;

}