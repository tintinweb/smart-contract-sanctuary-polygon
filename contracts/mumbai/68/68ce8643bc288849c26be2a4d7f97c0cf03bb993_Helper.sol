/**
 *Submitted for verification at polygonscan.com on 2023-07-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Helper{
  
    function addrToByte(address a) pure public returns (bytes memory addr){

        addr = abi.encode(a);
    }

    function strToByte(string memory _str) pure public returns (bytes memory _string){

        _string = abi.encode(_str);
    }

    function uintArray(uint[] memory a) pure public returns (bytes memory _uintarr){

        _uintarr = abi.encode(a);
    }

    function addrUintArray(address[] memory a,uint[] memory b) pure public returns (bytes memory arrays){

        arrays = abi.encode(a,b);
    }

    function uint_(uint a) pure public returns (bytes memory _uint){

        _uint = abi.encode(a);
    }

    function addrUint(address a,uint b) pure public returns (bytes memory arrays){

        arrays = abi.encode(a,b);
    }

    function uints(uint a,uint b, uint8 c) pure public returns (bytes memory _uint){

        _uint = abi.encode(a,b,c);
    }

    function strUint(string memory a, uint8 b) pure public returns (bytes memory _uint){

        _uint = abi.encode(a,b);
    }

    function strUint8(string memory a, uint8 b) pure public returns (bytes memory _uint){

        _uint = abi.encode(a,b);
    }

   
}