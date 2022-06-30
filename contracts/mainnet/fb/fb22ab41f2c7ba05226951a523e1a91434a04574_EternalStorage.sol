/**
 *Submitted for verification at polygonscan.com on 2022-06-29
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;


    contract EternalStorage {

        mapping (bytes32 => uint) UIntstorage;

        function getUIntValue(bytes32 record) public view returns (uint){
            return UIntstorage[record];
        }

        function setUIntValue(bytes32 record, uint value) public
        {
            UIntstorage[record] = value;
        }


        mapping (bytes32 => bool) BooleanStorage;

        function getBooleanValue(bytes32 record) public view returns (bool){
            return BooleanStorage[record];
        }

        function setBooleanValue(bytes32 record, bool value) public
        {
            BooleanStorage[record] =value;
        }

}